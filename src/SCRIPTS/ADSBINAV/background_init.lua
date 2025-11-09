local initializationDone = false
local crsfCustomTelemetryEnabled = false
local crsfCustomTelemetrySensors = nil


local function setTimer(index, paramValue)
    model.resetTimer(index)
    local timer = model.getTimer(index)
    timer.value = paramValue
    model.setTimer(index, timer)
end

local sensorsDiscoveredTimeout = 0
local hasSensor = adsbinav.executeScript("F/hasSensor")
local function waitForCrsfSensorsDiscovery()
    if not crossfireTelemetryPush() or adsbinav.runningInSimulator then
        -- Model does not use CRSF/ELRS
        return 0
    end

    local sensorsDiscovered = hasSensor("TPWR")
    if not sensorsDiscovered then
        -- Wait 2 secs to discover all CRSF sensors before continuing.
        sensorsDiscoveredTimeout = adsbinav.clock() + 2
    end

    if sensorsDiscoveredTimeout ~= 0 then
        if adsbinav.clock() < sensorsDiscoveredTimeout then
            return 1 -- wait for sensors to be discovered
        end
        sensorsDiscoveredTimeout = 0
    end

    --rf2.print("Sensors already discovered")
    return 0
end

local queueInitialized = false
local function initializeQueue()
    --rf2.print("Initializing MSP queue")

    adsbinav.mspQueue.maxRetries = -1       -- retry indefinitely

    adsbinav.useApi("mspApiVersion").getApiVersion(
        function(_, version)
            adsbinav.apiVersion = version
        end)
end

local function initialize(modelIsConnected)
    local sensorsDiscoveryWaitState = waitForCrsfSensorsDiscovery()

    if sensorsDiscoveryWaitState == 1 then
        return false
    end

    if not modelIsConnected then
        return false
    end

    if not queueInitialized then
        initializeQueue()
        queueInitialized = true
    end

    rf2.mspQueue:processQueue()

    return initializationDone
end

local function run(modelIsConnected)
    return
    {
        isInitialized = initialize(modelIsConnected),
        crsfCustomTelemetryEnabled = crsfCustomTelemetryEnabled,
        crsfCustomTelemetrySensors = crsfCustomTelemetrySensors
    }
end

local function reset()
    adsbinav.mspQueue:clear()
    adsbinav.apiVersion = nil
end

return { run = run, reset = reset }
