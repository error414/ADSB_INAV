local mspApiVersion = adsbinav.useApi("mspApiVersion")
local returnTable = { f = nil, t = "" }
local apiVersion
local lastRunTS

local function init()
    if getRSSI() == 0 and not adsbinav.runningInSimulator then
        returnTable.t = "Waiting for connection"
        return false
    end

    if not apiVersion and (not lastRunTS or lastRunTS + 2 < adsbinav.clock()) then
        returnTable.t = "Waiting for API version"
        mspApiVersion.getApiVersion(function(_, version) apiVersion = version end)
        lastRunTS = adsbinav.clock()
    end

    adsbinav.mspQueue:processQueue()

    if adsbinav.mspQueue:isProcessed() and apiVersion then
        local apiVersionAsString = string.format("%.2f", apiVersion)
        if apiVersion < 2.05 then
            returnTable.t = "This version of the Lua\nscripts can't be used\nwith the selected model\nwhich has version "..apiVersionAsString.."."
        else
            -- received correct API version, proceed
            adsbinav.apiVersion = apiVersion
            adsbinav.print("got version %s", adsbinav.apiVersion)
            collectgarbage()
            return true
        end
    end

    return false
end

returnTable.f = init

return returnTable
