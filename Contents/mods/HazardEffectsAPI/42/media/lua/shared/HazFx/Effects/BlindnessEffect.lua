local EffectRegistry = require("HazFx/EffectRegistry");
local BaseEffect = require("HazFx/Effects/BaseEffect");
local Utils = require("HazFx/Utils");

HazardEffects.Effects.BlindnessEffect = HazardEffects.Effects.BlindnessEffect or BaseEffect:derive("BlindnessEffect");


---@class BlindnessEffect : BaseEffect
local BlindnessEffect = HazardEffects.Effects.BlindnessEffect;

function BlindnessEffect:new(player, playerNum, playerOnlineID)
    return BaseEffect.new(self, player, playerNum, playerOnlineID);
end

function BlindnessEffect:initialize()
    self:definePersistant("radius", 0);
    self:definePersistant("isIlliterate", self.player:hasTrait(CharacterTrait.ILLITERATE));

    self.fxData = {
        blur = 1,
        desat = 10,
        darkness = 1,
        gw = 4
    };

    self:initSearchManager();

end

function BlindnessEffect:initSearchManager()
    if(self._searchManager == nil and Utils.isClient()) then
        local sm = getSearchMode();
        if(sm) then
            self._searchManager = sm:getSearchModeForPlayer(self.playerNum);
            self._searchMode = sm;
        end
    end
    return self._searchManager;
end

function BlindnessEffect:getSearchManager()
    return self:initSearchManager();
end

function BlindnessEffect:deactivate()
    BaseEffect.deactivate(self);
    self._searchMode:setEnabled(self.playerNum, false);
end

function BlindnessEffect:activate(duration, radius)
    self.radius = radius;
    BaseEffect.activate(self, duration);
end

function BlindnessEffect:render()
    BaseEffect.render(self);
    if not self.isActive then return; end
    local radius = PZMath.lerp(self.radius, 25, self.timeElapsed / self.duration);
    self._searchManager:getRadius():setTargets(radius, radius);
    self._searchManager:getBlur():setTargets(self.fxData.blur, self.fxData.blur);
    self._searchManager:getDesat():setTargets(self.fxData.desat, self.fxData.desat);
    self._searchManager:getDarkness():setTargets(self.fxData.darkness, self.fxData.darkness);
    self._searchManager:getGradientWidth():setTargets(self.fxData.gw, self.fxData.gw);
    self._searchMode:setEnabled(self.playerNum, true);
end

function BlindnessEffect:everyOneMinute()
    BaseEffect.everyOneMinute(self);
    if not self.isActive then return; end
    
end

EffectRegistry.getInstance():register(BlindnessEffect);