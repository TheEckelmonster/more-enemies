local mods = mods

-- require("libs.log.log-settings")
require("settings.nauvis.nauvis")
require("settings.global")

if (mods) then
    if (mods["space-age"]) then require("settings.gleba.gleba") end
    if (mods["ArmouredBiters"]) then require("settings.mods.armoured-biters") end
    if (mods["Cold_biters"]) then require("settings.mods.cold-biters") end
    if (mods["Explosive_biters"]) then require("settings.mods.explosive-biters") end
    if (mods["old_biters_remastered"]) then require("settings.mods.proto-biters") end
    if (mods["Toxic_biters"]) then require("settings.mods.toxic-biters") end
end

require("settings.runtime-global.runtime-global-settings")