require("ISBaseObject");

HazardEffects = HazardEffects or {};
HazardEffects.Effects = HazardEffects.Effects or {};
HazardEffects.Effects.BaseEffect = HazardEffects.Effects.BaseEffect or ISBaseObject:derive("BaseEffect");

local BaseEffect = HazardEffects.Effects.BaseEffect;

function BaseEffect:new(player, playerNum, playerOnlineID)
    local o = {};
    setmetatable(o, self);
    self.__index = self;

    o:preinit(player, playerNum, playerOnlineID);
    o:init();
    o:postinit();

    return o;
end

function BaseEffect:preinit(player, playerNum, playerOnlineID)
    self.player = player;
    self.playerNum = playerNum;
    self.playerOnlineID = playerOnlineID;

    local playerMD = self.player:getModData();
    playerMD.HazardEffectsAPI = playerMD.HazardEffectsAPI or {};

    local md = playerMD.HazardEffectsAPI;
    md[self.Type] = md[self.Type] or {
        isActive = false,
        duration = 0,
        timeElapsed = 0,
    };

    self.modData = md[self.Type];

    self.isActive = self.modData.isActive;
    self.duration = self.modData.duration;
    self.timeElapsed = self.modData.timeElapsed;

    self.healRate = 1;
    self.fastHealerMultiplier = 2;
    self.slowHealerMultiplier = 0.5;
end

function BaseEffect:postinit()
    self:transmitModData();
end

function BaseEffect:getModData()
    return self.modData;
end

function BaseEffect:transmitModData()
    self.player:transmitModData();
end

function BaseEffect:init() end;
function BaseEffect:activate(duration) end;
function BaseEffect:deactivate() end;
function BaseEffect:tick() end;
function BaseEffect:everyOneMinute() end;
function BaseEffect:onPlayerUpdate() end;