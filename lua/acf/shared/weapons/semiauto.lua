ACF.RegisterWeaponClass("SA", {
	Name		  = "Semiautomatic Cannon",
	Description	  = "Semiautomatic cannons offer light weight, small size, and high rates of fire at the cost of often reloading and low accuracy.",
	MuzzleFlash	  = "semi_muzzleflash_noscale",
	Spread		  = 0.12,
	Sound		  = "acf_base/weapons/sa_fire1.mp3",
	IsBoxed		  = true,
	Caliber	= {
		Min = 20,
		Max = 76,
	},
})

ACF.RegisterWeapon("25mmSA", "SA", {
	Name		= "25mm Semiautomatic Cannon",
	Description	= "The 25mm semiauto can quickly put five rounds downrange, being lethal, yet light.",
	Model		= "models/autocannon/semiautocannon_25mm.mdl",
	Caliber		= 25,
	Mass		= 250,
	Year		= 1935,
	MagSize		= 5,
	MagReload	= 2.5,
	Cyclic		= 300,
	Round = {
		MaxLength = 39,
		PropMass  = 0.5,
	}
})

ACF.RegisterWeapon("37mmSA", "SA", {
	Name		= "37mm Semiautomatic Cannon",
	Description	= "The 37mm is surprisingly powerful, its five-round clips boasting a respectable payload and a high muzzle velocity.",
	Model		= "models/autocannon/semiautocannon_37mm.mdl",
	Caliber		= 37,
	Mass		= 500,
	Year		= 1940,
	MagSize		= 5,
	MagReload	= 3.7,
	Cyclic		= 250,
	Round = {
		MaxLength = 42,
		PropMass  = 1.125,
	}
})

ACF.RegisterWeapon("45mmSA", "SA", {
	Name		= "45mm Semiautomatic Cannon",
	Description	= "The 45mm can easily shred light armor, with a respectable rate of fire, but its armor penetration pales in comparison to regular cannons.",
	Model		= "models/autocannon/semiautocannon_45mm.mdl",
	Caliber		= 45,
	Mass		= 750,
	Year		= 1965,
	MagSize		= 5,
	MagReload	= 4.5,
	Cyclic		= 225,
	Round = {
		MaxLength = 52,
		PropMass  = 1.8,
	}
})

ACF.RegisterWeapon("57mmSA", "SA", {
	Name		= "57mm Semiautomatic Cannon",
	Description	= "The 57mm is a respectable light armament, offering considerable penetration and moderate fire rate.",
	Model		= "models/autocannon/semiautocannon_57mm.mdl",
	Caliber		= 57,
	Mass		= 1000,
	Year		= 1965,
	MagSize		= 5,
	MagReload	= 5.7,
	Cyclic		= 200,
	Round = {
		MaxLength = 62,
		PropMass  = 2,
	}
})

ACF.RegisterWeapon("76mmSA", "SA", {
	Name		= "76mm Semiautomatic Cannon",
	Description	= "The 76mm semiauto is a fearsome weapon, able to put five 76mm rounds downrange in 8 seconds.",
	Model		= "models/autocannon/semiautocannon_76mm.mdl",
	Caliber		= 76.2,
	Mass		= 2000,
	Year		= 1984,
	MagSize		= 5,
	MagReload	= 7.6,
	Cyclic		= 150,
	Round = {
		MaxLength = 70,
		PropMass  = 4.75,
	}
})

ACF.SetCustomAttachment("models/autocannon/semiautocannon_25mm.mdl", "muzzle", Vector(44), Angle(0, 0, 180))
ACF.SetCustomAttachment("models/autocannon/semiautocannon_37mm.mdl", "muzzle", Vector(65.12), Angle(0, 0, 180))
ACF.SetCustomAttachment("models/autocannon/semiautocannon_45mm.mdl", "muzzle", Vector(79.2), Angle(0, 0, 180))
ACF.SetCustomAttachment("models/autocannon/semiautocannon_57mm.mdl", "muzzle", Vector(109.12), Angle(0, 0, 180))
ACF.SetCustomAttachment("models/autocannon/semiautocannon_76mm.mdl", "muzzle", Vector(167.2), Angle(0, 0, 180))
