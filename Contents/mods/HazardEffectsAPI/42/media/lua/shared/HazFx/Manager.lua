require("HazFx/HazardEffects");

HazardEffects.Manager = HazardEffects.Manager or {};
HazardEffects.Manager.__index = HazardEffects.Manager;

local instances = {};

local Manager = HazardEffects.Manager;

function Manager.getInstanceForPlayer(player, playerNum, playerOnlineID)

    local instanceID = playerNum;

    if(isMultiplayer()) then

        if(playerOnlineID == nil) then return; end
        instanceID = playerOnlineID;
        player = player or getPlayerByOnlineID(playerOnlineID);

    else

        player = player or getSpecificPlayer(playerNum or 0);
        playerNum = playerNum or player:getPlayerNum();

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
    
	self.player = player;
	self.playerNum = playerNum;
	self.playerOnlineID = playerOnlineID;
    self.effects = {};

    self.modData = self.player:getModData();

end

function Manager:deactivate(effect)

    if(effect == nil) then
        for _, fxInstance in pairs(self.effects) do
            if(fxInstance.isActive) then
                fxInstance:deactivate();
            end
        end
        return true;
    elseif(self.effects[effect]) then
        self.effects[effect]:deactivate();
        return true;
    else
        print(string.format("[WARN] HazardEffectsAPI:deactivate(): the effect \"%s\" not exists!", effect));
        return false;
    end

end

function Manager:update()
    
    if(self.player:isGodMode()) then
        self:deactivate();
    end
	
end

function Manager:updateFixed()
    
	

end

Events.OnTick.Add(function()

    for _, instance in pairs(instances) do
        if(instance.isActive) then
            instance:update();
        end
    end

end);

Events.EveryOneMinute.Add(function()

    -- Check if the player is still online.
    if(isMultiplayer()) then

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
        if(instance.isActive) then
            instance:updateFixed();
        end
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