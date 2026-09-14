local Manager = require("HazFx/Manager");

local Utils = require("HazFx/Utils");

local TICKS_PER_TICK_UPDATE = 20;

local __ttu = 0;

local function onTick()
    
    if(__ttu >= TICKS_PER_TICK_UPDATE) then
        for _, instance in pairs(Manager.instances) do
            instance:tick();
        end
        __ttu = 0;
    else
        __ttu = __ttu + 1;
    end
end

local function onPlayerUpdate(player)
    local instance = Manager.getInstanceForPlayer(player);
    if(instance) then
        instance:onPlayerUpdate();
    end
end

local function everyOneMinute()

    -- Check if the player is still online.
    if(isMultiplayer() and isServer()) then

        local onlineIDs = {};
        local players = getOnlinePlayers();

        for i = 0, players:size() - 1 do

            local p = players:get(i);
            onlineIDs[p:getOnlineID()] = true;
            Manager.getInstanceForPlayer(p, p:getPlayerNum(), p:getOnlineID());

        end

        for id, instance in pairs(Manager.instances) do
            -- Destroy the instance if the player is no longer logged
            if not onlineIDs[id] then Manager.instances[id] = nil; end
        end

    end

    -- Update the manager
    for _, instance in pairs(Manager.instances) do
        instance:everyOneMinute();
    end

end

local function onCharacterDeath(character)
    if not instanceof(character, "IsoPlayer") then return; end

    local instanceID = character:getPlayerNum();
    if(isMultiplayer()) then
        instanceID = character:getOnlineID();
    end

    Manager.instances[instanceID] = nil;
end

local function onServerCommand(module, command, args)
    if(module ~= "HazFx") then return; end
    command = Utils.split(command, ":");
    if(command[1] ~= "manager") then return; end

    local player = getPlayerByOnlineID(args.playerOnlineID);
    if(not player or not player:isLocalPlayer()) then return; end
    local playerNum = player:getPlayerNum();

    local instance = Manager.getInstanceForPlayer(nil, playerNum);
    if(command[2] == "init") then

        hazlog("Manager:init", table.concat({
            "SERVER: onServerCommand:manager:init",
            string.format("        playerNum: %s", tostring(args.playerNum)),
            string.format("        playerOnlineID: %s", tostring(args.playerOnlineID)),
        }, "\n"));
    elseif(command[2] == "activate") then
        instance:activate(args.effect, args.duration, args.options);
    elseif(command[2] == "deactivate") then
        instance:deactivate(args.effect);
    end
end

---------------------------------------
-- EVENTS
---------------------------------------
Events.OnTick.Add(onTick);

Events.OnPlayerUpdate.Add(onPlayerUpdate);

Events.EveryOneMinute.Add(everyOneMinute);

Events.OnCharacterDeath.Add(onCharacterDeath);

Events.OnServerCommand.Add(onServerCommand);