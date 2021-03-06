ACF.RegisterWeaponClass("MG", {
	Name		  = "Machinegun",
	Description	  = "Machineguns are light guns that fire equally light bullets at a fast rate.",
	MuzzleFlash	  = "mg_muzzleflash_noscale",
	Spread		  = 0.16,
	Sound		  = "acf_base/weapons/mg_fire4.mp3",
	IsBoxed		  = true,
	Caliber	= {
		Min = 5.56,
		Max = 20,
	},
})

ACF.RegisterWeapon("7.62mmMG", "MG", {
	Name		= "7.62mm Machinegun",
	Description	= "The 7.62mm is effective against infantry, but its usefulness against armor is laughable at best.",
	Model		= "models/machinegun/machinegun_762mm.mdl",
	Caliber		= 7.62,
	Mass		= 15,
	Year		= 1930,
	MagSize		= 250,
	MagReload	= 5,
	Cyclic		= 700, -- Rounds per minute
	Round = {
		MaxLength = 13,
		PropMass  = 0.04,
	}
})

ACF.RegisterWeapon("12.7mmMG", "MG", {
	Name		= "12.7mm Machinegun",
	Description	= "The 12.7mm MG is still light, finding its way into a lot of mountings, including on top of tanks.",
	Model		= "models/machinegun/machinegun_127mm.mdl",
	Caliber		= 12.7,
	Mass		= 30,
	Year		= 1910,
	MagSize		= 150,
	MagReload	= 6,
	Cyclic		= 600,
	Round = {
		MaxLength = 15.8,
		PropMass  = 0.03,
	}
})

ACF.RegisterWeapon("14.5mmMG", "MG", {
	Name		= "14.5mm Machinegun",
	Description	= "The 14.5mm MG trades its smaller stablemates' rate of fire for more armor penetration and damage.",
	Model		= "models/machinegun/machinegun_145mm.mdl",
	Caliber		= 14.5,
	Mass		= 45,
	Year		= 1932,
	MagSize		= 90,
	MagReload	= 7,
	Cyclic		= 500,
	Round = {
		MaxLength = 19.5,
		PropMass  = 0.04,
	}
})

ACF.RegisterWeapon("20mmMG", "MG", {
	Name		= "20mm Machinegun",
	Description	= "The 20mm MG is practically a cannon in its own right; the weight and recoil made it difficult to mount on light land vehicles, though it was adapted for use on both aircraft and ships.",
	Model		= "models/machinegun/machinegun_20mm.mdl",
	Caliber		= 20,
	Mass		= 95,
	Year		= 1935,
	MagSize		= 200,
	MagReload	= 8,
	Cyclic		= 400,
	Round = {
		MaxLength = 22,
		PropMass  = 0.09,
	}
})

ACF.SetCustomAttachment("models/machinegun/machinegun_762mm.mdl", "muzzle", Vector(26.53, 0, -0.05), Angle(0, 0, 90))
ACF.SetCustomAttachment("models/machinegun/machinegun_127mm.mdl", "muzzle", Vector(37.14, 0, -0.07), Angle(0, 0, 90))
ACF.SetCustomAttachment("models/machinegun/machinegun_145mm.mdl", "muzzle", Vector(39.79, 0, -0.08), Angle(0, 0, 90))
ACF.SetCustomAttachment("models/machinegun/machinegun_20mm.mdl", "muzzle", Vector(53.05, 0, -0.11), Angle(0, 0, 90))
