AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include("shared.lua")

-- Local Vars -----------------------------------

local ACF          = ACF
local ACF_RECOIL   = GetConVar("acf_recoilpush")
local UnlinkSound  = "physics/metal/metal_box_impact_bullet%s.wav"
local CheckLegal   = ACF_CheckLegal
local Shove        = ACF.KEShove
local Overpressure = ACF.Overpressure
local Weapons	   = ACF.Classes.Weapons
local AmmoTypes    = ACF.Classes.AmmoTypes
local TraceRes     = {} -- Output for traces
local TraceData    = {start = true, endpos = true, filter = true, mask = MASK_SOLID, output = TraceRes}
local Trace        = util.TraceLine
local TimerCreate  = timer.Create
local HookRun      = hook.Run
local EMPTY        = { Type = "Empty", PropMass = 0, ProjMass = 0, Tracer = 0 }

-- Replace with CFrame as soon as it's available
local function UpdateTotalAmmo(Entity)
	local Total = 0

	for Crate in pairs(Entity.Crates) do
		if Crate:CanConsume() then
			Total = Total + Crate.Ammo
		end
	end

	WireLib.TriggerOutput(Entity, "Total Ammo", Total)
end

do -- Spawn and Update functions --------------------------------
	local Updated = {
		["20mmHRAC"] = "20mmRAC",
		["30mmHRAC"] = "30mmRAC",
		["40mmCL"] = "40mmGL",
	}

	local function VerifyData(Data)
		if not Data.Weapon then
			Data.Weapon = Data.Id or "50mmC"
		end

		local Class = ACF.GetClassGroup(Weapons, Data.Weapon)

		if not Class then
			Data.Weapon = Data.Weapon and Updated[Data.Weapon] or "50mmC"

			Class = ACF.GetClassGroup(Weapons, Data.Weapon)
		end

		do -- External verifications
			if Class.VerifyData then
				Class.VerifyData(Data, Class)
			end

			HookRun("ACF_VerifyData", "acf_gun", Data, Class)
		end
	end

	local function CreateInputs(Entity, Data, Class, Weapon)
		local List = { "Fire", "Unload", "Reload" }

		if Class.SetupInputs then
			Class.SetupInputs(List, Entity, Data, Class, Weapon)
		end

		HookRun("ACF_OnSetupInputs", "acf_gun", List, Entity, Data, Class, Weapon)

		if Entity.Inputs then
			Entity.Inputs = WireLib.AdjustInputs(Entity, List)
		else
			Entity.Inputs = WireLib.CreateInputs(Entity, List)
		end
	end

	local function CreateOutputs(Entity, Data, Class, Weapon)
		local List = { "Ready", "Status [STRING]", "Total Ammo", "Entity [ENTITY]", "Shots Left", "Rate of Fire", "Reload Time", "Projectile Mass", "Muzzle Velocity" }

		if Class.SetupOutputs then
			Class.SetupOutputs(List, Entity, Data, Class, Weapon)
		end

		HookRun("ACF_OnSetupOutputs", "acf_gun", List, Entity, Data, Class, Weapon)

		if Entity.Outputs then
			Entity.Outputs = WireLib.AdjustOutputs(Entity, List)
		else
			Entity.Outputs = WireLib.CreateOutputs(Entity, List)
		end
	end

	local function UpdateWeapon(Entity, Data, Class, Weapon)
		Entity:SetModel(Weapon.Model)

		Entity:PhysicsInit(SOLID_VPHYSICS)
		Entity:SetMoveType(MOVETYPE_VPHYSICS)

		-- Storing all the relevant information on the entity for duping
		for _, V in ipairs(Entity.DataStore) do
			Entity[V] = Data[V]
		end

		Entity.Name           = Weapon.Name
		Entity.ShortName      = Weapon.ID
		Entity.EntType        = Class.Name
		Entity.ClassData      = Class
		Entity.WeaponData     = Weapon
		Entity.Class          = Class.ID -- Needed for custom killicons
		Entity.Caliber        = Weapon.Caliber
		Entity.MagReload      = Weapon.MagReload
		Entity.MagSize        = Weapon.MagSize or 1
		Entity.Cyclic         = Weapon.Cyclic and 60 / Weapon.Cyclic
		Entity.ReloadTime     = Entity.Cyclic or 1
		Entity.Spread         = Class.Spread
		Entity.HitBoxes       = ACF.HitBoxes[Weapon.Model]
		Entity.Long           = Class.LongBarrel
		Entity.NormalMuzzle   = Entity:WorldToLocal(Entity:GetAttachment(Entity:LookupAttachment("muzzle")).Pos)
		Entity.Muzzle         = Entity.NormalMuzzle

		CreateInputs(Entity, Data, Class, Weapon)
		CreateOutputs(Entity, Data, Class, Weapon)

		-- Set NWvars
		Entity:SetNWString("WireName", "ACF " .. Weapon.Name)
		Entity:SetNWString("Class", Entity.Class)
		Entity:SetNWString("ID", Entity.Weapon)

		-- Adjustable barrel length
		if Entity.Long then
			local Attachment = Entity:GetAttachment(Entity:LookupAttachment(Entity.Long.NewPos))

			Entity.LongMuzzle = Attachment and Entity:WorldToLocal(Attachment.Pos)
		end

		if Entity.Cyclic then -- Automatics don't change their rate of fire
			WireLib.TriggerOutput(Entity, "Reload Time", Entity.Cyclic)
			WireLib.TriggerOutput(Entity, "Rate of Fire", 60 / Entity.Cyclic)
		end

		ACF.Activate(Entity, true)

		Entity.ACF.LegalMass	= Weapon.Mass
		Entity.ACF.Model		= Weapon.Model

		local Phys = Entity:GetPhysicsObject()
		if IsValid(Phys) then Phys:SetMass(Weapon.Mass) end
	end

	hook.Add("ACF_OnSetupInputs", "ACF Weapon Fuze", function(Class, List, Entity)
		if Class ~= "acf_gun" then return end
		if Entity.Caliber <= ACF.MinFuzeCaliber then return end

		List[#List + 1] = "Fuze"
	end)

	-------------------------------------------------------------------------------

	function MakeACF_Weapon(Player, Pos, Angle, Data)
		VerifyData(Data)

		local Class = ACF.GetClassGroup(Weapons, Data.Weapon)
		local Weapon = Class.Lookup[Data.Weapon]
		local Limit = Class.LimitConVar.Name

		if not Player:CheckLimit(Limit) then return false end -- Check gun spawn limits

		local Gun = ents.Create("acf_gun")

		if not IsValid(Gun) then return end

		Player:AddCleanup(Class.Cleanup, Gun)
		Player:AddCount(Limit, Gun)

		Gun:SetPlayer(Player)
		Gun:SetAngles(Angle)
		Gun:SetPos(Pos)
		Gun:Spawn()

		Gun.Owner        = Player -- MUST be stored on ent for PP
		Gun.SoundPath    = Class.Sound
		Gun.DefaultSound = Class.Sound
		Gun.BarrelFilter = { Gun }
		Gun.State        = "Empty"
		Gun.Crates       = {}
		Gun.CurrentShot  = 0
		Gun.BulletData   = { Type = "Empty", PropMass = 0, ProjMass = 0, Tracer = 0 }
		Gun.DataStore    = ACF.GetEntityArguments("acf_gun")

		Gun:SetNWString("Sound", Class.Sound)

		UpdateWeapon(Gun, Data, Class, Weapon)

		WireLib.TriggerOutput(Gun, "Status", "Empty")
		WireLib.TriggerOutput(Gun, "Entity", Gun)
		WireLib.TriggerOutput(Gun, "Projectile Mass", 1000)
		WireLib.TriggerOutput(Gun, "Muzzle Velocity", 1000)

		if Class.OnSpawn then
			Class.OnSpawn(Gun, Data, Class, Weapon)
		end

		HookRun("ACF_OnEntitySpawn", "acf_gun", Gun, Data, Class, Weapon)

		Gun:UpdateOverlay(true)

		do -- Mass entity mod removal
			local EntMods = Data and Data.EntityMods

			if EntMods and EntMods.mass then
				EntMods.mass = nil
			end
		end

		TimerCreate("ACF Ammo Left " .. Gun:EntIndex(), 1, 0, function()
			if not IsValid(Gun) then return end

			UpdateTotalAmmo(Gun)
		end)

		CheckLegal(Gun)

		return Gun
	end

	ACF.RegisterEntityClass("acf_gun", MakeACF_Weapon, "Weapon")
	ACF.RegisterLinkSource("acf_gun", "Crates")

	------------------- Updating ---------------------

	function ENT:Update(Data)
		if self.Firing then return false, "Stop firing before updating the weapon!" end

		VerifyData(Data)

		local Class    = ACF.GetClassGroup(Weapons, Data.Weapon)
		local Weapon   = Class.Lookup[Data.Weapon]
		local OldClass = self.ClassData

		if self.State ~= "Empty" then
			self:Unload()
		end

		if OldClass.OnLast then
			OldClass.OnLast(self, OldClass)
		end

		HookRun("ACF_OnEntityLast", "acf_gun", self, OldClass)

		ACF.SaveEntity(self)

		UpdateWeapon(self, Data, Class, Weapon)

		ACF.RestoreEntity(self)

		if Class.OnUpdate then
			Class.OnUpdate(self, Data, Class, Weapon)
		end

		HookRun("ACF_OnEntityUpdate", "acf_gun", self, Data, Class, Weapon)

		if next(self.Crates) then
			for Crate in pairs(self.Crates) do
				self:Unlink(Crate)
			end
		end

		self:UpdateOverlay(true)

		net.Start("ACF_UpdateEntity")
			net.WriteEntity(self)
		net.Broadcast()

		return true, "Weapon updated successfully!"
	end
end ---------------------------------------------

do -- Metamethods --------------------------------
	do -- Inputs/Outputs/Linking ----------------
		WireLib.AddOutputAlias("AmmoCount", "Total Ammo")
		WireLib.AddOutputAlias("Muzzle Weight", "Projectile Mass")

		ACF.RegisterClassLink("acf_gun", "acf_ammo", function(This, Crate)
			if This.Crates[Crate] then return false, "This weapon is already linked to this crate." end
			if Crate.Weapons[This] then return false, "This weapon is already linked to this crate." end
			if Crate.IsRefill then return false, "Refill crates cannot be linked to weapons." end
			if This.Weapon ~= Crate.Weapon then return false, "Wrong ammo type for this weapon." end

			local Blacklist = Crate.RoundData.Blacklist

			if Blacklist[This.Class] then
				return false, "The ammo type in this crate cannot be used for this weapon."
			end

			This.Crates[Crate]  = true
			Crate.Weapons[This] = true

			This:UpdateOverlay(true)
			Crate:UpdateOverlay(true)

			if This.State == "Empty" then -- When linked to an empty weapon, attempt to load it
				timer.Simple(0.5, function() -- Delay by 500ms just in case the wiring isn't applied at the same time or whatever weird dupe shit happens
					if IsValid(This) and IsValid(Crate) and This.State == "Empty" and Crate:CanConsume() then
						This:Load()
					end
				end)
			end

			return true, "Weapon linked successfully."
		end)

		ACF.RegisterClassUnlink("acf_gun", "acf_ammo", function(This, Crate)
			if This.Crates[Crate] or Crate.Weapons[This] then
				if This.CurrentCrate == Crate then
					This.CurrentCrate = next(This.Crates, Crate)
				end

				This.Crates[Crate]  = nil
				Crate.Weapons[This] = nil

				This:UpdateOverlay(true)
				Crate:UpdateOverlay(true)

				return true, "Weapon unlinked successfully."
			end

			return false, "This weapon is not linked to this crate."
		end)

		ACF.AddInputAction("acf_gun", "Fire", function(Entity, Value)
			local Bool = tobool(Value)

			Entity.Firing = Bool

			if Bool and Entity:CanFire() then
				Entity:Shoot()
			end
		end)

		ACF.AddInputAction("acf_gun", "Unload", function(Entity, Value)
			if tobool(Value) and Entity.State == "Loaded" then
				Entity:Unload()
			end
		end)

		ACF.AddInputAction("acf_gun", "Reload", function(Entity, Value)
			if tobool(Value) then
				if Entity.State == "Loaded" then
					Entity:Unload(true) -- Unload, then reload
				elseif Entity.State == "Empty" then
					Entity:Load()
				end
			end
		end)

		ACF.AddInputAction("acf_gun", "Fuze", function(Entity, Value)
			Entity.SetFuze = tobool(Value) and math.abs(Value)
		end)
	end -----------------------------------------

	do -- Shooting ------------------------------
		function ENT:BarrelCheck(Offset)
			TraceData.start	 = self:LocalToWorld(Vector()) + Offset
			TraceData.endpos = self:LocalToWorld(self.Muzzle) + Offset
			TraceData.filter = self.BarrelFilter

			Trace(TraceData)

			if TraceRes.Hit then
				local Entity = TraceRes.Entity

				if Entity == self.CurrentUser or Entity:CPPIGetOwner() == self.Owner then
					self.BarrelFilter[#self.BarrelFilter + 1] = Entity

					return self:BarrelCheck(Offset)
				end
			end

			return TraceRes.HitPos
		end

		function ENT:CanFire()
			if not self.Firing then return false end -- Nobody is holding the trigger
			if self.Disabled then return false end -- Disabled
			if self.State ~= "Loaded" then -- Weapon is not loaded
				if self.State == "Empty" and not self.Retry then
					if not self:Load() then
						self:EmitSound("weapons/pistol/pistol_empty.wav", 500, 100) -- Click!
					end

					self.Retry = true

					timer.Simple(1, function() -- Try again after a second
						if IsValid(self) then
							self.Retry = nil

							if self:CanFire() then
								self:Shoot()
							end
						end
					end)
				end

				return false
			end
			if HookRun("ACF_FireShell", self) == false then return false end -- Something hooked into ACF_FireShell said no

			return true
		end

		function ENT:GetSpread()
			local SpreadScale = ACF.SpreadScale
			local IaccMult    = math.Clamp(((1 - SpreadScale) / 0.5) * ((self.ACF.Health / self.ACF.MaxHealth) - 1) + 1, 1, SpreadScale)

			return self.Spread * ACF.GunInaccuracyScale * IaccMult
		end

		function ENT:Shoot()
			local Cone = math.tan(math.rad(self:GetSpread()))
			local randUnitSquare = (self:GetUp() * (2 * math.random() - 1) + self:GetRight() * (2 * math.random() - 1))
			local Spread = randUnitSquare:GetNormalized() * Cone * (math.random() ^ (1 / ACF.GunInaccuracyBias))
			local Dir = (self:GetForward() + Spread):GetNormalized()
			local Velocity = ACF_GetAncestor(self):GetVelocity()

			if self.BulletData.CanFuze and self.SetFuze then
				local Variance = math.Rand(-0.015, 0.015) * math.max(0, 203 - self.Caliber) * 0.01

				self.Fuze = math.max(self.SetFuze, 0.02) + Variance -- If possible, we're gonna update the fuze time
			else
				self.Fuze = nil
			end

			self.CurrentUser = self:GetUser(self.Inputs.Fire.Src) -- Must be updated on every shot

			self.BulletData.Owner  = self.CurrentUser
			self.BulletData.Gun	   = self -- because other guns share this table
			self.BulletData.Pos    = self:BarrelCheck(Velocity * engine.TickInterval())
			self.BulletData.Flight = Dir * self.BulletData.MuzzleVel * 39.37 + Velocity
			self.BulletData.Fuze   = self.Fuze -- Must be set when firing as the table is shared
			self.BulletData.Filter = self.BarrelFilter

			AmmoTypes[self.BulletData.Type]:Create(self, self.BulletData) -- Spawn projectile

			self:MuzzleEffect()
			self:Recoil()

			local Energy = ACF_Kinetic(self.BulletData.MuzzleVel * 39.37, self.BulletData.ProjMass).Kinetic

			if Energy > 50 then -- Why yes, this is completely arbitrary! 20mm AC AP puts out about 115, 40mm GL HE puts out about 20
				Overpressure(self:LocalToWorld(self.Muzzle) - self:GetForward() * 5, Energy, self.BulletData.Owner, self, self:GetForward(), 30)
			end

			if self.MagSize then -- Mag-fed/Automatically loaded
				self.CurrentShot = self.CurrentShot - 1

				if self.CurrentShot > 0 then -- Not empty
					self:Chamber(self.Cyclic)
				else -- Reload the magazine
					self:Load()
				end
			else -- Single-shot/Manually loaded
				self.CurrentShot = 0 -- We only have one shot, so shooting means we're at 0
				self:Chamber()
			end
		end

		function ENT:MuzzleEffect()
			local Effect = EffectData()
				Effect:SetEntity(self)
				Effect:SetScale(self.BulletData.PropMass)
				Effect:SetMagnitude(self.ReloadTime)

			util.Effect("ACF_Muzzle_Flash", Effect, true, true)
		end

		function ENT:ReloadEffect(Time)
			local Effect = EffectData()
				Effect:SetEntity(self)
				Effect:SetScale(0)
				Effect:SetMagnitude(Time)

			util.Effect("ACF_Muzzle_Flash", Effect, true, true)
		end

		function ENT:Recoil()
			if not ACF_RECOIL:GetBool() then return end

			local Phys = self:GetPhysicsObject()
			if not IsValid(Phys) then return end
			local MassCenter = self:LocalToWorld(Phys:GetMassCenter())
			local Energy = self.BulletData.ProjMass * self.BulletData.MuzzleVel * 39.37 + self.BulletData.PropMass * 3000 * 39.37

			Shove(self, MassCenter, -self:GetForward(), Energy)
		end
	end -----------------------------------------

	do -- Loading -------------------------------
		local function FindNextCrate(Gun)
			if not next(Gun.Crates) then return end

			-- Find the next available crate to pull ammo from --
			local Select = next(Gun.Crates, Gun.CurrentCrate) or next(Gun.Crates)
			local Start  = Select

			repeat
				if Select:CanConsume() then return Select end -- Return select

				Select = next(Gun.Crates, Select) or next(Gun.Crates)
			until
				Select == Start

			return Select:CanConsume() and Select or nil
		end

		function ENT:Unload(Reload)
			if self.Disabled then return end
			if IsValid(self.CurrentCrate) then self.CurrentCrate:Consume(-1) end -- Put a shell back in the crate, if possible

			local Time = self.MagReload or self.ReloadTime

			self:ReloadEffect(Reload and Time * 2 or Time)
			self:SetState("Unloading")
			self:EmitSound("weapons/357/357_reload4.wav", 500, 100)
			self.CurrentShot = 0
			self.BulletData  = EMPTY

			WireLib.TriggerOutput(self, "Shots Left", 0)

			timer.Simple(Time, function()
				if IsValid(self) then
					if Reload then
						self:Load()
					else
						self:SetState("Empty")
					end
				end
			end)
		end

		function ENT:Chamber(TimeOverride)
			if self.Disabled then return end

			local Crate = FindNextCrate(self)

			if IsValid(Crate) then -- Have a crate, start loading
				self:SetState("Loading") -- Set our state to loading
				Crate:Consume() -- Take one round of ammo out of the current crate (Must be called *after* setting the state to loading)

				local BulletData = Crate.BulletData
				local Time		 = TimeOverride or (ACF.BaseReload + (BulletData.CartMass * ACF.MassToTime * 0.666) + (BulletData.ProjLength * ACF.LengthToTime * 0.333)) -- Mass contributes 2/3 of the reload time with length contributing 1/3

				self.CurrentCrate = Crate
				self.ReloadTime   = Time
				self.BulletData   = BulletData
				self.NextFire 	  = ACF.CurTime + Time

				if not TimeOverride then -- Mag-fed weapons don't change rate of fire
					WireLib.TriggerOutput(self, "Reload Time", self.ReloadTime)
					WireLib.TriggerOutput(self, "Rate of Fire", 60 / self.ReloadTime)
				end

				WireLib.TriggerOutput(self, "Shots Left", self.CurrentShot)

				timer.Simple(Time, function()
					if IsValid(self) then
						self:SetState("Loaded")
						self.NextFire = nil

						if self.CurrentShot == 0 then
							self.CurrentShot = self.MagSize
						end

						WireLib.TriggerOutput(self, "Shots Left", self.CurrentShot)
						WireLib.TriggerOutput(self, "Projectile Mass", math.Round(self.BulletData.ProjMass * 1000, 2))
						WireLib.TriggerOutput(self, "Muzzle Velocity", math.Round(self.BulletData.MuzzleVel * ACF.Scale, 2))

						if self:CanFire() then self:Shoot() end
					end
				end)
			else -- No available crate to pull ammo from, out of ammo!				
				self:SetState("Empty")

				self.CurrentShot = 0
				self.BulletData  = EMPTY

				WireLib.TriggerOutput(self, "Shots Left", 0)
			end
		end

		function ENT:Load()
			if self.Disabled then return false end
			if not FindNextCrate(self) then -- Can't load without having ammo being provided
				self:SetState("Empty")

				self.CurrentShot = 0
				self.BulletData  = EMPTY

				WireLib.TriggerOutput(self, "Shots Left", 0)

				return false
			end

			self:SetState("Loading")

			if self.MagReload then -- Mag-fed/Automatically loaded
				self:EmitSound("weapons/357/357_reload4.wav", 500, 100)

				self.NextFire = ACF.CurTime + self.MagReload

				WireLib.TriggerOutput(self, "Shots Left", self.CurrentShot)

				timer.Simple(self.MagReload, function() -- Reload timer
					if IsValid(self) then
						self:Chamber(self.Cyclic) -- One last timer to chamber the round
					end
				end)
			else -- Single-shot/Manually loaded
				self:Chamber()
			end

			return true
		end
	end -----------------------------------------

	do -- Duplicator Support --------------------
		function ENT:PreEntityCopy()
			if next(self.Crates) then
				local Entities = {}

				for Crate in pairs(self.Crates) do
					Entities[#Entities + 1] = Crate:EntIndex()
				end

				duplicator.StoreEntityModifier(self, "ACFCrates", Entities)
			end

			-- Wire dupe info
			self.BaseClass.PreEntityCopy(self)
		end

		function ENT:PostEntityPaste(Player, Ent, CreatedEntities)
			local EntMods = Ent.EntityMods

			-- Backwards compatibility
			if EntMods.ACFAmmoLink then
				local Entities = EntMods.ACFAmmoLink.entities

				for _, EntID in ipairs(Entities) do
					self:Link(CreatedEntities[EntID])
				end

				EntMods.ACFAmmoLink = nil
			end

			if EntMods.ACFCrates then
				for _, EntID in pairs(EntMods.ACFCrates) do
					self:Link(CreatedEntities[EntID])
				end

				EntMods.ACFCrates = nil
			end

			self.BaseClass.PostEntityPaste(self, Player, Ent, CreatedEntities)
		end
	end -----------------------------------------

	do -- Overlay -------------------------------
		local Text = "%s\n\nRate of Fire: %s rpm\nShots Left: %s\nAmmo Available: %s"

		function ENT:UpdateOverlayText()
			local AmmoType  = self.BulletData.Type .. (self.BulletData.Tracer ~= 0 and "-T" or "")
			local Firerate  = math.floor(60 / self.ReloadTime)
			local CrateAmmo = 0
			local Status

			if not next(self.Crates) then
				Status = "Not linked to an ammo crate!"
			else
				Status = self.State == "Loaded" and "Loaded with " .. AmmoType or self.State
			end

			for Crate in pairs(self.Crates) do -- Tally up the amount of ammo being provided by active crates
				if Crate:CanConsume() then
					CrateAmmo = CrateAmmo + Crate.Ammo
				end
			end

			return Text:format(Status, Firerate, self.CurrentShot, CrateAmmo)
		end
	end -----------------------------------------

	do -- Misc ----------------------------------
		function ENT:ACF_Activate(Recalc)
			local PhysObj = self.ACF.PhysObj

			if not self.ACF.Area then
				self.ACF.Area = PhysObj:GetSurfaceArea() * 6.45
			end

			local Volume = PhysObj:GetVolume() * 2

			local Armour = self.Caliber
			local Health = Volume / ACF.Threshold --Setting the threshold of the prop Area gone
			local Percent = 1

			if Recalc and self.ACF.Health and self.ACF.MaxHealth then
				Percent = self.ACF.Health / self.ACF.MaxHealth
			end

			self.ACF.Health = Health * Percent
			self.ACF.MaxHealth = Health
			self.ACF.Armour = Armour * (0.5 + Percent * 0.5)
			self.ACF.MaxArmour = Armour
			self.ACF.Type = "Prop"
		end

		function ENT:SetState(State)
			self.State = State

			self:UpdateOverlay()

			WireLib.TriggerOutput(self, "Status", State)
			WireLib.TriggerOutput(self, "Ready", State == "Loaded" and 1 or 0)

			UpdateTotalAmmo(self)
		end

		function ENT:Think()
			if next(self.Crates) then
				local Pos = self:GetPos()

				for Crate in pairs(self.Crates) do
					if Crate:GetPos():DistToSqr(Pos) > 62500 then -- 250 unit radius
						self:Unlink(Crate)

						self:EmitSound(UnlinkSound:format(math.random(1, 3)), 500, 100)
						Crate:EmitSound(UnlinkSound:format(math.random(1, 3)), 500, 100)
					end
				end
			end

			self:NextThink(ACF.CurTime + 1)

			return true
		end

		function ENT:Enable()
			self:UpdateOverlay()
		end

		function ENT:Disable()
			self.Firing   = false -- Stop firing

			self:Unload() -- Unload the gun for being a big baddie
			self:UpdateOverlay()
		end

		function ENT:CanProperty(_, Property)
			if self.Long and Property == "bodygroups" then
				timer.Simple(0, function()
					if not IsValid(self) then return end

					local Long = self.Long
					local IsLong = self:GetBodygroup(Long.Index) == Long.Submodel

					self.Muzzle = IsLong and self.LongMuzzle or self.NormalMuzzle
				end)
			end

			return true
		end

		function ENT:OnRemove()
			local Class = self.ClassData

			if Class.OnLast then
				Class.OnLast(self, Class)
			end

			HookRun("ACF_OnEntityLast", "acf_gun", self, Class)

			for Crate in pairs(self.Crates) do
				self:Unlink(Crate)
			end

			timer.Remove("ACF Ammo Left " .. self:EntIndex())

			WireLib.Remove(self)
		end
	end -----------------------------------------
end
