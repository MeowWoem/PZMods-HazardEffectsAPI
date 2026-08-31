require("HazFx/HazardEffects");
require("HazFx/EffectRegistry");

HazardEffects.Manager = HazardEffects.Manager or {};
HazardEffects.Manager.__index = HazardEffects.Manager;

local TICKS_PER_TICK_UPDATE = 20;
local TICKS_PER_PLAYER_UPDATE = 20;

local __ttu = 0;

local instances = {};

local Manager = HazardEffects.Manager;

function _split (inputstr, sep)
   if sep == nil then sep = '%s'; end
   local t={};
   for str in string.gmatch(inputstr, '([^'..sep..']+)') do table.insert(t, str); end
   return t;
end

function Manager:_callFx(method, ...)
    for _, fxInstance in pairs(self.effects) do
        --if(fxInstance.isActive) then
            fxInstance[method](fxInstance, ...);
        --end
    end
end


function Manager.getInstanceForPlayer(player, playerNum, playerOnlineID)

    local instanceID = playerNum;

    if(isMultiplayer() and isServer()) then

        if(playerOnlineID == nil) then return; end
        instanceID = playerOnlineID;
        player = player or getPlayerByOnlineID(playerOnlineID);

    elseif(not isMultiplayer()) then

        player = player or getSpecificPlayer(playerNum or 0);
        playerNum = playerNum or player:getPlayerNum();
        instanceID = playerNum;

    end

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

    self.modData = self.player:getModData();

    for k, v in pairs(HazardEffects.EffectRegistry.getInstance().effects) do
        self.effects[k] = v:new(player, playerNum, playerOnlineID);
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

function Manager:deactivate(effect)
    
    hazlog("Manager:deactivate", tostring(effect));

    if(effect == nil) then
        Manager._callFx(self, "deactivate");
        return true;
    elseif(self.effects[effect] and self.effects[effect].isActive) then
        self.effects[effect]:deactivate();
        return true;
    else
        hazwarn("Manager:deactivate", string.format("the effect \"%s\" not exists!", effect));
        return false;
    end

end

function Manager:tick()
    
    if(self.player:isGodMod()) then
        --self:deactivate();
    end
	
end

function Manager:everyOneMinute()
    Manager._callFx(self, "everyOneMinute");
end

function Manager:onPlayerUpdate()
    if(self.__tpu >= TICKS_PER_PLAYER_UPDATE) then
        Manager._callFx(self, "onPlayerUpdate");
        self.__tpu = 0;
    else
        self.__tpu = self.__tpu + 1;
    end
end


---------------------------------------
-- EVENTS
---------------------------------------
Events.OnTick.Add(function()
    if(__ttu >= TICKS_PER_TICK_UPDATE) then
        for _, instance in pairs(instances) do
            instance:tick();
        end
        __ttu = 0;
    else
        __ttu = __ttu + 1;
    end
end);

Events.OnPlayerUpdate.Add(function(player)
    local instance = Manager.getInstanceForPlayer(player);
    if(instance) then
        instance:onPlayerUpdate();
    end
end);

Events.EveryOneMinute.Add(function()

    -- Check if the player is still online.
    if(isMultiplayer() and isServer()) then

        local onlineIDs = {};
        local players = getOnlinePlayers();

        for i = 0, players:size() - 1 do

            local p = players:get(i);
            onlineIDs[p:getOnlineID()] = true;
            Manager.getInstanceForPlayer(p, p:getPlayerNum(), p:getOnlineID());

        end

        for id, instance in pairs(instances) do
            -- Destroy the instance if the player is no longer logged
            if not onlineIDs[id] then instances[id] = nil; end
        end

    end

    -- Update the manager
    for _, instance in pairs(instances) do
        instance:everyOneMinute();
    end

end);

Events.OnCharacterDeath.Add(function(character)
    if not instanceof(character, "IsoPlayer") then return; end

    local instanceID = character:getPlayerNum();
    if(isMultiplayer()) then
        instanceID = character:getOnlineID();
    end

    instances[instanceID] = nil;
end);

Events.OnServerCommand.Add(function(module, command, args)
    if(module ~= "HazFx") then return; end
    command = _split(command, ":");
    if(command[1] ~= "manager") then return; end

    local player = getPlayerByOnlineID(args.playerOnlineID);
    if(not player or not player:isLocalPlayer()) then return; end
    local playerNum = player:getPlayerNum();

    local instance = Manager.getInstanceForPlayer(nil, playerNum);
    if(command[2] == "init") then
        if(isDebugEnabled()) then
            if(isDebugEnabled()) then
                print("CLIENT: onServerCommand:manager:init");
                print("        playerNum: " .. args.playerNum);
                print("        playerOnlineID: " .. args.playerOnlineID);
            end
        end
    end
end);


if(isDebugEnabled()) then
    function a()
        Manager.getInstanceForPlayer(nil, 0);
    end
    
end