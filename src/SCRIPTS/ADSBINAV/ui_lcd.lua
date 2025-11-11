local screen = adsbinav.executeScript("LCD/screen")
local mspAdsbList = adsbinav.useApi("mspAdsbList")

local init
local lastRunTS
local uiStatus =
{
    init     = 1,
    mainPage = 2,
}

local uiData =
{
    ADSBMessagesCount = 0,
    apiAdsbData = nil
}

local uiState = uiStatus.init

local function fetchAdsbData()
    if not lastRunTS or lastRunTS + 2 < adsbinav.clock() then
        mspAdsbList.read(function(_, adsbData) uiData.apiAdsbData = adsbData end)
        lastRunTS = adsbinav.clock()
    end

    if adsbinav.mspQueue:isProcessed() and uiData.apiAdsbData then
        uiData.ADSBMessagesCount = uiData.ADSBMessagesCount + 1
    end
end

local function run_ui(event)
    if uiState == uiStatus.init then
        init = init or adsbinav.executeScript("ui_init")
        screen.drawScreenInit(uiData, init.t)
        if not init.f() then
            return 0
        end
        init = nil
        uiState = uiStatus.mainPage
    elseif uiState == uiStatus.mainPage then

        adsbinav.mspQueue:processQueue()

        ----------------------------------------------------------------
        -- No telemetry
        ----------------------------------------------------------------
        if getRSSI() == 0 then
            --[[adsbinav.print("No telemetry")]]
            screen.drawScreenWarning(uiData, "(waiting for connection)", event)
            return 0
        end
        ----------------------------------------------------------------

        ----------------------------------------------------------------
        -- Vehicle is armed, stop refreshing
        ----------------------------------------------------------------
        local flightMode = getValue("FM")
        if flightMode ~= 'WAIT' and flightMode ~= 'OK' and flightMode ~= "!ERR" then
            --[[adsbinav.print("Vehicle is armed, stop refreshing")]]
            screen.drawScreenWarning(uiData, "(Vehicle is armed, stop refreshing)", event)
            return 0
        end
        ----------------------------------------------------------------

        ----------------------------------------------------------------
        -- Fetch data from ADSB, show update table
        ----------------------------------------------------------------
        fetchAdsbData()
        screen.drawScreenRunning(uiData, event)
        ----------------------------------------------------------------

    end
    return 0
end
return run_ui
