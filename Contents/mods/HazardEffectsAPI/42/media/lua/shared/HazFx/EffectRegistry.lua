require("HazFx/HazardEffects");

HazardEffects.EffectRegistry = HazardEffects.EffectRegistry or {};
HazardEffects.EffectRegistry.__index = HazardEffects.EffectRegistry;

local EffectRegistry = HazardEffects.EffectRegistry;

local instance = nil;

function EffectRegistry.new()
	local o = {};
	setmetatable(o, EffectRegistry);
	o:init();
	return o;
end

function EffectRegistry.getInstance()

    if(not instance) then
        instance = EffectRegistry.new();
    end

	return instance;
end

function EffectRegistry:init()
	self.effects = {};
end

function EffectRegistry:register(effect)
	self.effects[effect.Type] = effect;
end

instance = EffectRegistry.new();