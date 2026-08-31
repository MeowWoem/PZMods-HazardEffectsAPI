HazardEffects = HazardEffects or {};

HazardEffects.__index = HazardEffects;

function HazardEffects.debug(...)
    if(isDebugEnabled()) then
        print("HazFX", ...);
    end
end
function HazardEffects.warn(...)
    print("[WARN] HazFX", ...);
end
function HazardEffects.err(...)
    print("[ERR] HazFX", ...);
end

hazlog = HazardEffects.debug;
hazwarn = HazardEffects.warn;
hazerr = HazardEffects.err;