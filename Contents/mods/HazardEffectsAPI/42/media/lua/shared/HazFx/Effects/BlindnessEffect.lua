require("HazFx/EffectRegistry");
require("HazFx/Effects/BaseEffect");

local BaseEffect = HazardEffects.Effects.BaseEffect;

HazardEffects.Effects.BlindnessEffect = HazardEffects.Effects.BlindnessEffect
    or BaseEffect:derive("BlindnessEffect");

local BlindnessEffect = HazardEffects.Effects.BlindnessEffect;

function BlindnessEffect:new(player, playerNum, playerOnlineID)
    local o = BaseEffect.new(self, player, playerNum, playerOnlineID);
    return o;
end

function BlindnessEffect:init()
    local md = self:getModData();

    md.radius = md.radius or 0;
    md.isIlliterate = md.isIlliterate or self.player:hasTrait(CharacterTrait.ILLITERATE);

    self.radius = md.radius;
    self.isIlliterate = md.isIlliterate;

end

function BlindnessEffect:activate(duration)
    self.modData.isActive = true;
    self.isActive = true;
end

function BlindnessEffect:deactivate()
    self.modData.isActive = false;
    self.isActive = false;
end

function BlindnessEffect:onPlayerUpdate()
    if not self.isActive then return; end
    
end

function BlindnessEffect:everyOneMinute()
    if not self.isActive then return; end
    
end

HazardEffects.EffectRegistry.getInstance():register(BlindnessEffect);