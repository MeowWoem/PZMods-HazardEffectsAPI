if getActivatedMods():contains("MoodleFramework") == true then
    require "MF_ISMoodle";
    MF.createMoodle("BlindnessEffect");
end