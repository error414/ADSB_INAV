local lcdShared = adsbinav.executeScript("LCD/shared")
local table = adsbinav.executeScript("LCD/table_basic")
local adsbIcon = adsbinav.executeScript("ICONS/icon")

local mainIconName = "adsbinav.png"
local headers = {"Emitter", "Callsign", "ICAO",  "GPS lat/lon", "Alt m", "Heading", "TSLC", "TTL"}
local colWidths = {15, 17, 13, 15, 10, 10, 10, 10}
local tableData = {}

local function drawTable(uiData, event)
    local apiAdsbData = uiData.apiAdsbData
    if apiAdsbData then
        for i = 1, #apiAdsbData.vehicles do
            tableData[i] = {
                Bitmap.open(adsbinav.baseDir .. "ICONS/" .. adsbIcon.getADSBIcon(apiAdsbData.vehicles[i].emitterType)),
                string.format("%s", apiAdsbData.vehicles[i].callsign),
                string.format("%X", apiAdsbData.vehicles[i].icao),
                string.format("%.5f \n %.5f", apiAdsbData.vehicles[i].lat  / 10000000, apiAdsbData.vehicles[i].lon / 10000000),
                string.format("%.0f", apiAdsbData.vehicles[i].alt),
                string.format("%.0f", apiAdsbData.vehicles[i].heading),
                apiAdsbData.vehicles[i].tslc,
                apiAdsbData.vehicles[i].ttl
            }
        end

        uiData.apiAdsbData = nil
    end

    table.drawTable(45, headers, tableData, event, colWidths)
end

local function drawScreenInit(uiData, statusMessage)
    lcd.clear()
    lcdShared.drawScreenTitle(mainIconName, "ADSB INAV " .. adsbinav.luaVersion, statusMessage, uiData.ADSBMessagesCount)
end

local function drawScreenWarning(uiData, statusMessage, event)
    lcd.clear()
    lcdShared.drawScreenTitle(mainIconName, "ADSB INAV " .. adsbinav.luaVersion, statusMessage, uiData.ADSBMessagesCount)
    drawTable(uiData, event)
end

local function drawScreenRunning(uiData, event)
    lcd.clear()
    lcdShared.drawScreenTitle(mainIconName, "ADSB INAV " .. adsbinav.luaVersion, nil, uiData.ADSBMessagesCount)
    drawTable(uiData, event)
end

return {drawScreenInit = drawScreenInit, drawScreenWarning = drawScreenWarning, drawScreenRunning = drawScreenRunning}