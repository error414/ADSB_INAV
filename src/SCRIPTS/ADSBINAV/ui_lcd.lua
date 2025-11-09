local lcdShared = adsbinav.executeScript("LCD/shared")
local table = adsbinav.executeScript("LCD/table_basic")
local adsbIcon = adsbinav.executeScript("ICONS/icon")

local mspAdsbList = adsbinav.useApi("mspAdsbList")

local init
local apiAdsbData
local lastRunTS
local uiStatus =
{
    init     = 1,
    mainPage = 2,
}

local ADSBMessages = 0
local lastTableData = nill

local headers = {"Emitter", "Callsign", "ICAO",  "GPS lat/lon", "Alt m", "Heading", "TSLC", "TTL"}
local colWidths = {15, 17, 13, 15, 10, 10, 10, 10}
local mainIconName = "adsbinav.png"


local uiState = uiStatus.init

local function run_ui(event)

    if uiState == uiStatus.init then

        lcd.clear()

        init = init or adsbinav.executeScript("ui_init")
        lcdShared.drawScreenTitle(mainIconName, "ADSB INAV " .. adsbinav.luaVersion .. "  " .. init.t)
        if not init.f() then
            return 0
        end
        init = nil
        uiState = uiStatus.mainPage
    elseif uiState == uiStatus.mainPage then

        local flightMode = getValue("FM")

        if flightMode == 'WAIT' or flightMode == 'OK' then

            if not apiVersion and (not lastRunTS or lastRunTS + 2 < adsbinav.clock()) then
                mspAdsbList.read(function(_, adsbData) apiAdsbData = adsbData end)
                lastRunTS = adsbinav.clock()
            end

            adsbinav.mspQueue:processQueue()

            if adsbinav.mspQueue:isProcessed() and apiAdsbData then
                lcd.clear()
                lcdShared.drawScreenTitle(mainIconName, "ADSB INAV " .. adsbinav.luaVersion, ADSBMessages)
                local tableData = {}
                --create data for table

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

                ADSBMessages = ADSBMessages + 1;
                lastTableData = tableData
                apiAdsbData = nil
            elseif apiAdsbData == nil then
                lcd.clear()
                lcdShared.drawScreenTitle(mainIconName, "ADSB INAV " .. adsbinav.luaVersion, ADSBMessages)
            end
        else
            lcd.clear()
            lcdShared.drawScreenTitle(mainIconName, "ADSB INAV " .. adsbinav.luaVersion .. "  (vehicle is armed)", ADSBMessages)
        end

        if(lastTableData) then
            table.drawTable(45, headers, lastTableData, event, colWidths)
        end
    end
    return 0
end

return run_ui
