
require("ISBaseObject");
local Utils = require("HazFx/Utils");

HazardEffects = HazardEffects or {};
HazardEffects.Effects = HazardEffects.Effects or {};
HazardEffects.Effects.BaseEffect = HazardEffects.Effects.BaseEffect or ISBaseObject:derive("BaseEffect");

local DEFAULT_HEAL_RATE = 1;

---@class BaseEffect : ISBaseObject @Base class representing a custom effect applied to a player character.
---@field public stack integer The number of times this effect has been stacked or applied.
---@field public isActive boolean Whether the effect is currently active.
---@field public duration number The total duration of the effect in in-game minutes.
---@field public timeElapsed number The amount of in-game minutes that have elapsed since the effect was activated.
---@field public player "IsoPlayer" The player character instance targeted by this effect.
---@field public playerNum integer The local player index (client-only).
---@field public playerOnlineID integer The network multiplayer online ID of the player (multiplayer-only).
---@field public modData table The dedicated modData table for this effect, stored within the player's modData.
---@field public persistants table A table containing the names of member fields that should be persisted and saved to modData.
---@field public healRate number The base healing rate for the effect (default: 1).
---@field public fastHealerMultiplier number The multiplier applied to the healing rate when the player has the "Fast Healer" trait (default: 2).
---@field public slowHealerMultiplier number The multiplier applied to the healing rate when the player has the "Slow Healer" trait (default: 0.5).
local BaseEffect = HazardEffects.Effects.BaseEffect;


--- Effect class constructor.
---@param player "IsoPlayer" The player object instance targeted by this effect.
---@param playerNum integer the player num (client-only).
---@param playerOnlineID integer the player online ID (multiplayer-only)
---@return BaseEffect the initialized effect instance.
function BaseEffect:new(player, playerNum, playerOnlineID)
    local o = ISBaseObject.new(self);

    o:preinit(player, playerNum, playerOnlineID);

    o.persistants = {
        stack = 0,
        isActive = false,
        duration = 0,
        timeElapsed = 0,
    };

    o:initialize();

    for field, defaultValue in pairs(o.persistants) do
        if o[field] == nil then
            o[field] = defaultValue;
        end
    end

    o:initModData();
    o:loadFromModData();

    o:postinit();
    o:initialized();

    return o;
end

--- Defines a member field to be registered and saved within modData.
---@param field string Name of the member field.
---@param defaultValue any value assigned if no existing data is found.
function BaseEffect:definePersistant(field, defaultValue)
    self[field] = defaultValue;
    self:setPersistant(field, defaultValue);
end

---Registers a property in the persistants list.
---@param field string Name of the member field.
---@param defaultValue any|nil Optional default value fallback
function BaseEffect:setPersistant(field, defaultValue)
   if defaultValue ~= nil then
        self.persistants[field] = defaultValue;
    else
        self.persistants[field] = self[field];
    end
end

---Pre-initialization phase called before setting up persistent properties.
---@param player "IsoPlayer" The targeted IsoPlayer instance.
---@param playerNum number Local player index.
---@param playerOnlineID number|string Network multiplayer online ID.
function BaseEffect:preinit(player, playerNum, playerOnlineID)
    self.player = player;
    self.playerNum = playerNum;
    self.playerOnlineID = playerOnlineID;

    self.fastHealerMultiplier = 2;
    self.slowHealerMultiplier = 0.5;

    self:updateHealRate();
  
end

---Post-initialization phase executed immediately after setup.
function BaseEffect:postinit()
    self:saveToModData();
end

---Update the heal rate based on the player's traits.
function BaseEffect:updateHealRate()
    self.healRate = DEFAULT_HEAL_RATE;
    if(self.player:hasTrait(CharacterTrait.FAST_HEALER) and not self.player:hasTrait(CharacterTrait.SLOW_HEALER)) then
        self.healRate = self.healRate * self.fastHealerMultiplier;
    elseif(not self.player:hasTrait(CharacterTrait.FAST_HEALER) and self.player:hasTrait(CharacterTrait.SLOW_HEALER)) then
        self.healRate = self.healRate * self.slowHealerMultiplier;
    end
end

---Virtual method to be overridden by child classes to register custom properties.
function BaseEffect:initialize() end;

---Virtual method executed once object construction is completely finished.
function BaseEffect:initialized() end;

---Initializes the player's modData table reserved for this specific effect.
---@return table|nil The dedicated effect modData table, or nil if an error occurs.
function BaseEffect:initModData()

    if(self.modData ~= nil) then return; end
    if not self.Type then
        hazerr("BaseEffect Error: 'Type' field is not defined on child class!");
        return;
    end

    local playerMD = HazardEffects.getModData(self.player);

    playerMD.effects = playerMD.effects or {};
    playerMD.effects[self.Type] = playerMD.effects[self.Type] or {};

    local effectMD = playerMD.effects[self.Type];

    for field, defaultValue in pairs(self.persistants) do
        if effectMD[field] == nil then effectMD[field] = defaultValue; end
    end

    self.modData = effectMD;
    
    return effectMD;
end

---Loads all registered persistent fields from the player's modData table.
function BaseEffect:loadFromModData()
    for field, defaultValue in pairs(self.persistants) do
        if self.modData[field] ~= nil then
            self[field] = self.modData[field];
        else
            self[field] = defaultValue;
        end
    end
end

---Saves current persistent field values to the player's modData table.
---@param transmit boolean|nil Whether to broadcast updated modData over the network (defaults to false).
function BaseEffect:saveToModData(transmit)
    if transmit == nil then transmit = false; end

    for field, defaultValue in pairs(self.persistants) do
        if self[field] ~= nil then
            self.modData[field] = self[field];
        else
            self.modData[field] = defaultValue;
        end
    end

    if transmit then
        self:transmitModData();
    end
end

---Retrieves the dedicated modData table for this effect.
---@return table The effects modData table.
function BaseEffect:getModData()
    return self.modData;
end

---Transmits the player's modData over the network when executed by the server.
function BaseEffect:transmitModData()
    if (isMultiplayer() and isServer() and self.player) then
        self.player:transmitModData();
    end
end

---Activates or stack the effect for a given duration.
---@param duration number Duration in in-game minutes (0 for infinite/indefinite).
function BaseEffect:activate(duration, options)
    self.duration = duration;
    if(self.isActive) then 
        self.stack = self.stack + 1;
    else
        self.isActive = true;
    end
    self:saveToModData();
end

---Deactivates the effect and resets time counters and stack.
function BaseEffect:deactivate()
    if(Utils.isServer()) then
        self.duration = 0;
        self.stack = 0;
        self.timeElapsed = 0;
        self.isActive = false;
        self:saveToModData();
    end
end

---Hook function executed every engine tick.
function BaseEffect:tick() end

---Hook function dedicated to visual and UI rendering on client side.
function BaseEffect:render() end;

---Hook function executed every in-game minute.
function BaseEffect:everyOneMinute()
    if(self.isActive) then  
        self:updateHealRate();
        self.timeElapsed = self.timeElapsed + self.healRate;
        if(self.timeElapsed >= self.duration) then
            self:deactivate();
        end
    else
        
    end
end;

---Hook function triggered on player update.
---On client side, reloads synced server modData and updates rendering.
function BaseEffect:onPlayerUpdate()
    if(not Utils.isClient()) then
        return;
    elseif(isMultiplayer() and isClient()) then
        self:loadFromModData();
    end
    self:render();
end;

return BaseEffect;