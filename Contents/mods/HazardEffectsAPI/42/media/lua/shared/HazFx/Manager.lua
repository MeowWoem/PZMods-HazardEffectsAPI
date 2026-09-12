require("HazFx/HazardEffects");
require("HazFx/EffectRegistry");

HazardEffects.Manager = HazardEffects.Manager or {};
HazardEffects.Manager.__index = HazardEffects.Manager;

local TICKS_PER_PLAYER_UPDATE = 20;

local instances = {};

local Manager = HazardEffects.Manager;

function Manager:_callFx(method, ...)
    for _, fxInstance in pairs(self.effects) do
        if fxInstance[method] then
            fxInstance[method](fxInstance, ...);
        end
    end
end

Manager.instances = instances;

function Manager.getInstanceForPlayer(player, playerNum, playerOnlineID)

    local instanceID = playerNum;

    if(isMultiplayer() and isServer()) then

        if(playerOnlineID == nil) then return; end
        instanceID = playerOnlineID;
        player = player or getPlayerByOnlineID(playerOnlineID);
        if(not player) then return nil; end

    else

        player = player or getSpecificPlayer(playerNum or 0);
        if(not player) then return nil; end
        playerNum = player:getPlayerNum();
        instanceID = playerNum;

    end

    -- Ensure that playerNum is always defined. In singleplayer, playerNum is always 0. In multiplayer, playerNum is the local player's index, and playerOnlineID is the unique online ID of the player.
    -- @TODO: Change -1 to 0. -1 is used for debugging purposes only. 0 is the default playerNum for singleplayer.
    playerNum = playerNum or -1;

	if not instances[instanceID] or instances[instanceID].player ~= player then
		instances[instanceID] = Manager.new(player, playerNum, playerOnlineID);
	end

	return instances[instanceID];
end

function Manager.new(player, playerNum, playerOnlineID)
	local o = {};
	setmetatable(o, Manager);
	o:init(player, playerNum, playerOnlineID);
	return o;
end

function Manager:init(player, playerNum, playerOnlineID)
    
    self.__tpu = 0;
	self.player = player;
	self.playerNum = playerNum;
	self.playerOnlineID = playerOnlineID;
    self.effects = {};

    local playerMD = HazardEffects.getModData(self.player);
    playerMD.effects = playerMD.effects or {};

    self.modData = playerMD.effects;

    -- Loop through "HazFx/Effects/BaseEffect" objects in the effects registry and create an instance of each of them.
    for k, v in pairs(HazardEffects.EffectRegistry.getInstance().effects) do
        self.effects[k] = v:new(player, playerNum, playerOnlineID);
    end

    if isMultiplayer() and isServer() then
        self.player:transmitModData();
    end

    if(isMultiplayer() and isServer()) then

        hazlog("Manager:init", table.concat({
            "SERVER: sendServerCommand:manager:init",
            string.format("        playerNum: %s", tostring(self.playerNum)),
            string.format("        playerOnlineID: %s", tostring(self.playerOnlineID)),
        }, "\n"));
        
        sendServerCommand("HazFx", "manager:init", {
            playerNum   = self.playerNum,
            playerOnlineID   = self.playerOnlineID
        });
    else
        hazlog("Manager:init", string.format("Initialzed for player %d", playerNum));
    end
end

function Manager:activate(effect, duration, ...)
    
    hazlog("Manager:activate", tostring(effect));

    if(self.effects[effect]) then
        self.effects[effect]:activate(duration, ...);
        if(isMultiplayer() and isServer()) then
            self.player:transmitModData();
        end
        return true;
    else
        hazwarn("Manager:activate", string.format("the effect \"%s\" not exists!", effect));
        return false;
    end

end

function Manager:deactivate(effect)
    
    hazlog("Manager:deactivate", tostring(effect));

    if(effect == nil) then
        self:_callFx("deactivate");
    elseif(self.effects[effect] and self.effects[effect].isActive) then
        self.effects[effect]:deactivate();
    else
        hazwarn("Manager:deactivate", string.format("the effect \"%s\" not exists!", effect));
        return false;
    end

    if(isMultiplayer() and isServer()) then
        self.player:transmitModData();
    end
    
    return true;

end

function Manager:tick()
    
    if(self.player:isGodMod()) then
        --self:deactivate();
    end
    self:_callFx("tick");
	
end

function Manager:everyOneMinute()
    self:_callFx("everyOneMinute");
    if(isMultiplayer() and isServer()) then
        self.player:transmitModData();
    end
end

function Manager:onPlayerUpdate()
    
    if(self.__tpu >= TICKS_PER_PLAYER_UPDATE) then
        self:_callFx("onPlayerUpdate");
        self.__tpu = 0;
    else
        self.__tpu = self.__tpu + 1;
    end
end

if(isDebugEnabled()) then
    function a()
        local instance = Manager.getInstanceForPlayer(nil, 0);
        instance:activate("BlindnessEffect", 60);
    end
    
end

return Manager;