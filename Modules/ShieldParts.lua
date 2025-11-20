--[[
════════════════════════════════════════════════════════════════════════════════
Module: ShieldParts
Location: ReplicatedStorage/Modules/
Description: Defines all shield part manufacturers and their stat modifiers.
             4 part types (Capacitor, Generator, Regulator, Projector)
             7 manufacturers per part type
Version: 1.0
Last Updated: 2025-11-20
════════════════════════════════════════════════════════════════════════════════

Shield Stats:
- Capacity: Total shield HP
- RechargeRate: HP restored per second
- RechargeDelay: Seconds before recharge starts after damage
- BreakEffectChance: % chance for special effect when shield breaks

Part Roles:
- Capacitor: Primary capacity modifier
- Generator: Primary recharge rate modifier
- Regulator: Primary recharge delay modifier
- Projector: Special effects and secondary stats
--]]

local ShieldParts = {}

-- ════════════════════════════════════════════════════════════════════════════
-- CAPACITOR MANUFACTURERS (Shield Capacity Focus)
-- ════════════════════════════════════════════════════════════════════════════

ShieldParts.Capacitor = {
	{
		Name = "Aegis",
		Color = Color3.fromRGB(70, 120, 200),
		Material = Enum.Material.SmoothPlastic,
		BaseCapacity = 100,
		CapacityMult = 1.3,
		RechargeRateMult = 0.9,
		RechargeDelayMult = 1.0,
		BreakEffectChance = 0.05,
		Description = "High capacity, slightly slower recharge"
	},
	{
		Name = "Titan",
		Color = Color3.fromRGB(90, 90, 90),
		Material = Enum.Material.Metal,
		BaseCapacity = 120,
		CapacityMult = 1.5,
		RechargeRateMult = 0.7,
		RechargeDelayMult = 1.2,
		BreakEffectChance = 0.08,
		Description = "Massive capacity, slow recharge"
	},
	{
		Name = "Quicksilver",
		Color = Color3.fromRGB(200, 200, 220),
		Material = Enum.Material.Glass,
		BaseCapacity = 60,
		CapacityMult = 0.8,
		RechargeRateMult = 1.4,
		RechargeDelayMult = 0.7,
		BreakEffectChance = 0.03,
		Description = "Low capacity, fast recharge"
	},
	{
		Name = "Fortress",
		Color = Color3.fromRGB(100, 80, 60),
		Material = Enum.Material.Concrete,
		BaseCapacity = 110,
		CapacityMult = 1.4,
		RechargeRateMult = 0.8,
		RechargeDelayMult = 1.1,
		BreakEffectChance = 0.10,
		Description = "Very high capacity, slow recharge, high break effect chance"
	},
	{
		Name = "Tempest",
		Color = Color3.fromRGB(150, 100, 200),
		Material = Enum.Material.Neon,
		BaseCapacity = 80,
		CapacityMult = 1.0,
		RechargeRateMult = 1.2,
		RechargeDelayMult = 0.9,
		BreakEffectChance = 0.15,
		Description = "Balanced capacity, high break effect chance"
	},
	{
		Name = "Phantom",
		Color = Color3.fromRGB(50, 50, 80),
		Material = Enum.Material.ForceField,
		BaseCapacity = 70,
		CapacityMult = 0.9,
		RechargeRateMult = 1.1,
		RechargeDelayMult = 0.8,
		BreakEffectChance = 0.20,
		Description = "Low capacity, fast recharge start, very high break effect"
	},
	{
		Name = "Bastion",
		Color = Color3.fromRGB(180, 160, 120),
		Material = Enum.Material.Wood,
		BaseCapacity = 90,
		CapacityMult = 1.1,
		RechargeRateMult = 1.0,
		RechargeDelayMult = 1.0,
		BreakEffectChance = 0.05,
		Description = "Balanced all-rounder"
	}
}

-- ════════════════════════════════════════════════════════════════════════════
-- GENERATOR MANUFACTURERS (Recharge Rate Focus)
-- ════════════════════════════════════════════════════════════════════════════

ShieldParts.Generator = {
	{
		Name = "Flux",
		Color = Color3.fromRGB(100, 200, 250),
		Material = Enum.Material.Neon,
		BaseRechargeRate = 15,
		CapacityMult = 0.9,
		RechargeRateMult = 1.5,
		RechargeDelayMult = 1.0,
		BreakEffectChance = 0.05,
		Description = "Very fast recharge rate"
	},
	{
		Name = "Surge",
		Color = Color3.fromRGB(255, 200, 0),
		Material = Enum.Material.Neon,
		BaseRechargeRate = 18,
		CapacityMult = 0.8,
		RechargeRateMult = 1.8,
		RechargeDelayMult = 1.2,
		BreakEffectChance = 0.08,
		Description = "Extreme recharge rate, reduced capacity"
	},
	{
		Name = "Steady",
		Color = Color3.fromRGB(100, 150, 100),
		Material = Enum.Material.SmoothPlastic,
		BaseRechargeRate = 10,
		CapacityMult = 1.1,
		RechargeRateMult = 1.0,
		RechargeDelayMult = 0.9,
		BreakEffectChance = 0.03,
		Description = "Balanced recharge, slightly higher capacity"
	},
	{
		Name = "Pulse",
		Color = Color3.fromRGB(200, 100, 200),
		Material = Enum.Material.Neon,
		BaseRechargeRate = 12,
		CapacityMult = 1.0,
		RechargeRateMult = 1.3,
		RechargeDelayMult = 0.8,
		BreakEffectChance = 0.10,
		Description = "Good recharge, fast recharge start"
	},
	{
		Name = "Reactor",
		Color = Color3.fromRGB(255, 100, 100),
		Material = Enum.Material.Neon,
		BaseRechargeRate = 20,
		CapacityMult = 0.7,
		RechargeRateMult = 2.0,
		RechargeDelayMult = 1.5,
		BreakEffectChance = 0.12,
		Description = "Maximum recharge rate, very low capacity, long delay"
	},
	{
		Name = "Trickle",
		Color = Color3.fromRGB(150, 150, 200),
		Material = Enum.Material.Glass,
		BaseRechargeRate = 8,
		CapacityMult = 1.3,
		RechargeRateMult = 0.8,
		RechargeDelayMult = 0.7,
		BreakEffectChance = 0.04,
		Description = "Slow recharge, high capacity, fast start"
	},
	{
		Name = "Dynamo",
		Color = Color3.fromRGB(180, 180, 50),
		Material = Enum.Material.Metal,
		BaseRechargeRate = 12,
		CapacityMult = 1.0,
		RechargeRateMult = 1.2,
		RechargeDelayMult = 1.0,
		BreakEffectChance = 0.06,
		Description = "Balanced generator"
	}
}

-- ════════════════════════════════════════════════════════════════════════════
-- REGULATOR MANUFACTURERS (Recharge Delay Focus)
-- ════════════════════════════════════════════════════════════════════════════

ShieldParts.Regulator = {
	{
		Name = "Instant",
		Color = Color3.fromRGB(255, 255, 100),
		Material = Enum.Material.Neon,
		BaseRechargeDelay = 1.0,
		CapacityMult = 0.8,
		RechargeRateMult = 1.0,
		RechargeDelayMult = 0.5,
		BreakEffectChance = 0.05,
		Description = "Extremely fast recharge start, low capacity"
	},
	{
		Name = "Rapid",
		Color = Color3.fromRGB(100, 255, 100),
		Material = Enum.Material.Neon,
		BaseRechargeDelay = 1.5,
		CapacityMult = 0.9,
		RechargeRateMult = 1.1,
		RechargeDelayMult = 0.7,
		BreakEffectChance = 0.06,
		Description = "Fast recharge start"
	},
	{
		Name = "Standard",
		Color = Color3.fromRGB(150, 150, 150),
		Material = Enum.Material.SmoothPlastic,
		BaseRechargeDelay = 2.0,
		CapacityMult = 1.0,
		RechargeRateMult = 1.0,
		RechargeDelayMult = 1.0,
		BreakEffectChance = 0.05,
		Description = "Balanced delay"
	},
	{
		Name = "Delayed",
		Color = Color3.fromRGB(200, 100, 100),
		Material = Enum.Material.Metal,
		BaseRechargeDelay = 3.0,
		CapacityMult = 1.3,
		RechargeRateMult = 1.2,
		RechargeDelayMult = 1.5,
		BreakEffectChance = 0.08,
		Description = "Slow start, high capacity and recharge rate"
	},
	{
		Name = "Adaptive",
		Color = Color3.fromRGB(100, 200, 200),
		Material = Enum.Material.Glass,
		BaseRechargeDelay = 1.8,
		CapacityMult = 1.1,
		RechargeRateMult = 1.1,
		RechargeDelayMult = 0.8,
		BreakEffectChance = 0.10,
		Description = "Good all-around performance"
	},
	{
		Name = "Resilient",
		Color = Color3.fromRGB(120, 100, 80),
		Material = Enum.Material.Concrete,
		BaseRechargeDelay = 2.5,
		CapacityMult = 1.4,
		RechargeRateMult = 0.9,
		RechargeDelayMult = 1.3,
		BreakEffectChance = 0.15,
		Description = "High capacity, slow start, high break effect"
	},
	{
		Name = "Nimble",
		Color = Color3.fromRGB(200, 200, 255),
		Material = Enum.Material.ForceField,
		BaseRechargeDelay = 1.2,
		CapacityMult = 0.85,
		RechargeRateMult = 1.2,
		RechargeDelayMult = 0.6,
		BreakEffectChance = 0.07,
		Description = "Very fast start, decent recharge"
	}
}

-- ════════════════════════════════════════════════════════════════════════════
-- PROJECTOR MANUFACTURERS (Special Effects Focus)
-- ════════════════════════════════════════════════════════════════════════════

ShieldParts.Projector = {
	{
		Name = "Nova",
		Color = Color3.fromRGB(255, 200, 100),
		Material = Enum.Material.Neon,
		BreakEffect = "ExplosivePush",
		BreakEffectRadius = 15,
		BreakEffectDamage = 30,
		CapacityMult = 1.0,
		RechargeRateMult = 1.0,
		RechargeDelayMult = 1.0,
		BreakEffectChance = 0.30,
		Description = "Explosive push on shield break"
	},
	{
		Name = "Spike",
		Color = Color3.fromRGB(200, 50, 50),
		Material = Enum.Material.Metal,
		BreakEffect = "DamageReflect",
		BreakEffectRadius = 10,
		BreakEffectDamage = 50,
		CapacityMult = 0.9,
		RechargeRateMult = 1.0,
		RechargeDelayMult = 1.0,
		BreakEffectChance = 0.40,
		Description = "Reflects damage to attacker on break"
	},
	{
		Name = "Frost",
		Color = Color3.fromRGB(150, 200, 255),
		Material = Enum.Material.Ice,
		BreakEffect = "SlowAura",
		BreakEffectRadius = 20,
		BreakEffectDamage = 0,
		BreakEffectDuration = 3.0,
		CapacityMult = 1.1,
		RechargeRateMult = 0.9,
		RechargeDelayMult = 1.0,
		BreakEffectChance = 0.50,
		Description = "Slows nearby enemies on break"
	},
	{
		Name = "Blaze",
		Color = Color3.fromRGB(255, 100, 0),
		Material = Enum.Material.Neon,
		BreakEffect = "FireDOT",
		BreakEffectRadius = 12,
		BreakEffectDamage = 10,
		BreakEffectDuration = 5.0,
		CapacityMult = 1.0,
		RechargeRateMult = 1.1,
		RechargeDelayMult = 1.0,
		BreakEffectChance = 0.35,
		Description = "Burns nearby enemies over time on break"
	},
	{
		Name = "Void",
		Color = Color3.fromRGB(50, 0, 100),
		Material = Enum.Material.ForceField,
		BreakEffect = "Teleport",
		BreakEffectRadius = 30,
		BreakEffectDamage = 0,
		CapacityMult = 0.8,
		RechargeRateMult = 1.2,
		RechargeDelayMult = 0.8,
		BreakEffectChance = 0.60,
		Description = "Teleports player short distance on break"
	},
	{
		Name = "Absorb",
		Color = Color3.fromRGB(100, 255, 100),
		Material = Enum.Material.Neon,
		BreakEffect = "HealBurst",
		BreakEffectRadius = 0,
		BreakEffectDamage = -20, -- Negative = heal
		CapacityMult = 1.2,
		RechargeRateMult = 0.8,
		RechargeDelayMult = 1.1,
		BreakEffectChance = 0.25,
		Description = "Heals player on break"
	},
	{
		Name = "Standard",
		Color = Color3.fromRGB(150, 150, 200),
		Material = Enum.Material.SmoothPlastic,
		BreakEffect = "None",
		BreakEffectRadius = 0,
		BreakEffectDamage = 0,
		CapacityMult = 1.1,
		RechargeRateMult = 1.1,
		RechargeDelayMult = 0.9,
		BreakEffectChance = 0.00,
		Description = "No special effect, better stats"
	}
}

-- ════════════════════════════════════════════════════════════════════════════
-- UTILITY FUNCTIONS
-- ════════════════════════════════════════════════════════════════════════════

function ShieldParts.GetRandomPart(partType)
	local parts = ShieldParts[partType]
	if not parts then
		warn("[ShieldParts] Invalid part type:", partType)
		return nil
	end
	return parts[math.random(1, #parts)]
end

function ShieldParts.GetPartByName(partType, name)
	local parts = ShieldParts[partType]
	if not parts then return nil end

	for _, part in ipairs(parts) do
		if part.Name == name then
			return part
		end
	end

	return nil
end

function ShieldParts.GetAllPartTypes()
	return {"Capacitor", "Generator", "Regulator", "Projector"}
end

function ShieldParts.GetPartCount(partType)
	local parts = ShieldParts[partType]
	return parts and #parts or 0
end

return ShieldParts
