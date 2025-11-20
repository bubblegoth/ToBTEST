--[[
	Stocks.lua
	Stock parts - affects recoil, stability, and aim speed
]]

local Stocks = {
	{
		Id = "STOCK_NONE",
		Name = "No Stock",
		StatModifiers = {
			RecoilControl = 0.7,
			Accuracy = 0.85,
			AimSpeed = 1.3,
			MovementSpeed = 1.15
		},
		MinLevel = 1,
		Description = "No stock, maximum mobility"
	},
	{
		Id = "STOCK_FOLDING_RAVEN",
		Name = "Raven Folding Stock",
		StatModifiers = {
			RecoilControl = 0.9,
			Accuracy = 0.95,
			AimSpeed = 1.15,
			MovementSpeed = 1.05
		},
		MinLevel = 1,
		Description = "Collapsible stock with raven motifs"
	},
	{
		Id = "STOCK_FIXED_CATHEDRAL",
		Name = "Cathedral Fixed Stock",
		StatModifiers = {
			RecoilControl = 1.15,
			Accuracy = 1.1,
			AimSpeed = 0.95,
			MovementSpeed = 0.95
		},
		MinLevel = 5,
		Description = "Solid stock carved with holy architecture"
	},
	{
		Id = "STOCK_HEAVY_TOMBSTONE",
		Name = "Tombstone Heavy Stock",
		StatModifiers = {
			RecoilControl = 1.35,
			Accuracy = 1.2,
			AimSpeed = 0.8,
			MovementSpeed = 0.85,
			Damage = 1.05
		},
		MinLevel = 10,
		Description = "Weighted with tombstone marble, very stable"
	},
	{
		Id = "STOCK_SKELETAL",
		Name = "Skeletal Stock",
		StatModifiers = {
			RecoilControl = 1.05,
			Accuracy = 1.05,
			AimSpeed = 1.1,
			MovementSpeed = 1.1,
			ReloadTime = 0.95
		},
		MinLevel = 12,
		Description = "Lightweight bone framework"
	},
	{
		Id = "STOCK_PRECISION_SAINT",
		Name = "Saint's Precision Stock",
		StatModifiers = {
			RecoilControl = 1.25,
			Accuracy = 1.3,
			AimSpeed = 0.9,
			MovementSpeed = 0.9,
			CritDamage = 0.1
		},
		MinLevel = 15,
		Description = "Blessed stock for righteous accuracy"
	},
	{
		Id = "STOCK_DAMNED_COMPOSITE",
		Name = "Damned Composite Stock",
		StatModifiers = {
			RecoilControl = 1.1,
			Accuracy = 1.15,
			AimSpeed = 1.05,
			MovementSpeed = 1.05,
			FireRate = 1.05
		},
		MinLevel = 18,
		Description = "Composite materials from the damned"
	}
}

return Stocks
