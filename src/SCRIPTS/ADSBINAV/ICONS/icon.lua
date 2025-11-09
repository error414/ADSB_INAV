local ADSB_VEHICLE_TYPE = {
    [0]  = { icon = "adsb_14.png", name = "No info" },
    [1]  = { icon = "adsb_1.png",  name = "Light" },
    [2]  = { icon = "adsb_1.png",  name = "Small" },
    [3]  = { icon = "adsb_2.png",  name = "Large" },
    [4]  = { icon = "adsb_14.png", name = "High vortex large" },
    [5]  = { icon = "adsb_5.png",  name = "Heavy" },
    [6]  = { icon = "adsb_14.png", name = "Manuv" },
    [7]  = { icon = "adsb_13.png", name = "Rotorcraft" },
    [8]  = { icon = "adsb_14.png", name = "Unassigned" },
    [9]  = { icon = "adsb_6.png",  name = "Glider" },
    [10] = { icon = "adsb_7.png",  name = "Lighter air" },
    [11] = { icon = "adsb_15.png", name = "Parachute" },
    [12] = { icon = "adsb_1.png",  name = "Ultra light" },
    [13] = { icon = "adsb_14.png", name = "Unassigned 2" },
    [14] = { icon = "adsb_8.png",  name = "UAV" },
    [15] = { icon = "adsb_14.png", name = "Space" },
    [16] = { icon = "adsb_14.png", name = "Unassigned 3" },
    [17] = { icon = "adsb_9.png",  name = "Surface" },
    [18] = { icon = "adsb_10.png", name = "Service surface" },
    [19] = { icon = "adsb_12.png", name = "Point obstacle" }
}

local function getADSBIcon(emitterType)
    local entry = ADSB_VEHICLE_TYPE[emitterType]
    if entry then
        return entry.icon, entry.name
    else
        return "adsb_14.png", "Unknown"
    end
end

return {getADSBIcon = getADSBIcon}