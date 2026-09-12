local function split (inputstr, sep)
   if sep == nil then sep = '%s'; end
   local t={};
   for str in string.gmatch(inputstr, '([^'..sep..']+)') do table.insert(t, str); end
   return t;
end

local function _isClient()
    return (isMultiplayer() and isClient()) or not isMultiplayer();
end

local function _isServer()
    return (isMultiplayer() and isServer()) or not isMultiplayer();
end

return {
    split = split,
    isClient = _isClient,
    isServer = _isServer,
};