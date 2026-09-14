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

    if getActivatedMods():contains("MoodleFramework") == true then
        self.moodle = MF.getMoodle("BlindnessEffect", self.playerNum);
    end

    self.fxData = {
        radius = 1,
        blur = 1,
        desat = 10,
        darkness = 1,
        gw = 4,
        pain = 100,
    };

    self:initSearchManager();

    self.transitionTick = 0;
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
    self.transitionTick = 0;
    BaseEffect.deactivate(self);
    self._searchMode:setEnabled(self.playerNum, false);

    if(not self.isIlliterate) then
        self.player:getCharacterTraits():remove(CharacterTrait.ILLITERATE);
    end

    if(self.moodle) then
        self.moodle:setValue(0.5);
    end
end

function BlindnessEffect:activate(duration, options)

    options = options or {
        radius = 1
    };

    self.transitionTick = 0;
    self.radius = options.radius or 1;
    BaseEffect.activate(self, duration);
    
    local bodyDamage = self.player:getBodyDamage();
    local head = bodyDamage:getBodyPart(BodyPartType.Head);
    head:setAdditionalPain(head:getAdditionalPain() + self.duration);
    syncBodyPart(head, 0x400000);

    if(not self.isIlliterate) then
        self.player:getCharacterTraits():add(CharacterTrait.ILLITERATE);
    end

    if(self.moodle) then
        self.moodle:setValue(0);
    end
end

function BlindnessEffect:render()
    
    BaseEffect.render(self);
    if not self.isActive then return; end
    
    if(self.duration - self.timeElapsed > 1) then
        local radius = PZMath.lerp(self.radius, 25, self.timeElapsed / self.duration);
        self._searchManager:getRadius():setTargets(radius, radius);
        self._searchManager:getBlur():setTargets(self.fxData.blur, self.fxData.blur);
        self._searchManager:getDesat():setTargets(self.fxData.desat, self.fxData.desat);
        self._searchManager:getDarkness():setTargets(self.fxData.darkness, self.fxData.darkness);
        self._searchManager:getGradientWidth():setTargets(self.fxData.gw, self.fxData.gw);
    else
        local radius = PZMath.lerp(self.radius, 25, self.timeElapsed / self.duration) + self.transitionTick;
        local blur = Math.max(0, self.fxData.blur - (self.transitionTick / 10));
        local desat = Math.max(0, self.fxData.desat - (self.transitionTick / 10));
        local dark = Math.max(0, self.fxData.darkness - (self.transitionTick / 100));
        self._searchManager:getRadius():setTargets(radius, radius);
        self._searchManager:getBlur():setTargets(blur, blur);
        self._searchManager:getDesat():setTargets(desat, desat);
        self._searchManager:getDarkness():setTargets(dark, dark);
        self._searchManager:getGradientWidth():setTargets(self.fxData.gw, self.fxData.gw);
        self.transitionTick = self.transitionTick + 1;
    end
    self._searchMode:setEnabled(self.playerNum, true);
end

function BlindnessEffect:everyOneMinute()
    BaseEffect.everyOneMinute(self);
    if not self.isActive then return; end

    
    if(self.moodle) then
        self.moodle:setValue(PZMath.lerp(0, 0.39, self.timeElapsed / self.duration));
    end
end

EffectRegistry.getInstance():register(BlindnessEffect);