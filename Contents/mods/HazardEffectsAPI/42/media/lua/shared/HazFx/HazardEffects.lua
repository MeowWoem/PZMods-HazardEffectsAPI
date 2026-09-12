HazardEffects = HazardEffects or {};

HazardEffects.__index = HazardEffects;

HazardEffects.MOD_DATA_KEY = "HazardEffectsAPI";

function HazardEffects.getModData(isoObj)
    local md = isoObj:getModData();
    md[HazardEffects.MOD_DATA_KEY] = md[HazardEffects.MOD_DATA_KEY] or {};
    return md[HazardEffects.MOD_DATA_KEY];
end

function HazardEffects.debug(...)
    if(isDebugEnabled()) then
        print("HazFX", ...);
    end
end
function HazardEffects.warn(...)
    print("[WARN] HazFX", ...);
end
function HazardEffects.err(...)
    error(table.concat({"[ERR] HazFX", ...}, ' '));
end

hazlog = HazardEffects.debug;
hazwarn = HazardEffects.warn;
hazerr = HazardEffects.err;

return HazardEffects;