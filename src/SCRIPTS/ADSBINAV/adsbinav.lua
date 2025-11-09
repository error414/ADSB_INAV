adsbinav = {
    luaVersion = "0.0.1",
    baseDir = "/SCRIPTS/ADSBINAV/",
    runningInSimulator = string.sub(select(2, getVersion()), -4) == "simu",

    units = {
        percentage = "%",
        degrees = del and "°" or "@", -- OpenTX uses @
        degreesPerSecond = (del and "°" or "@") .. "/s",
        herz = " Hz",
        seconds = " s",
        milliseconds = " ms",
        volt = "V",
        celsius = " C",
        rpm = " RPM",
        meters = " m"
    },

    loadScript = function(script)
        local startsWith = function(str, prefix)
            return string.sub(str, 1, #prefix) == prefix
        end
        local endsWith = function(str, suffix)
            return suffix == "" or string.sub(str, -#suffix) == suffix
        end
        if not startsWith(script, adsbinav.baseDir) then
            script = adsbinav.baseDir .. script
        end
        if not endsWith(script, ".lua") then
            script = script .. ".lua"
        end
        collectgarbage()
        return loadScript(script)
    end,

    executeScript = function(scriptName, ...)
        return assert(adsbinav.loadScript(scriptName))(...)
    end,

    useApi = function(apiName)
        return adsbinav.executeScript("MSP/" .. apiName)
    end,

    loadSettings = function()
        return adsbinav.executeScript("PAGES/helpers/settingsHelper").loadSettings();
    end,

    clock = function()
        return getTime() / 100
    end,

    apiVersion = nil,

    --[NIR
    print = function(format, ...)
        local str = string.format("ADSB_INAV: " .. format, ...)
        if adsbinav.runningInSimulator then
            print(str)
        else
            serialWrite(str .. "\r\n") -- 115200 bps
            --adsbinav.log(str)
        end
    end,

    log = function(str)
        if adsbinav.runningInSimulator then
            adsbinav.print(tostring(str))
        else
            if not adsbinav.logfile then
                adsbinav.logfile = io.open("/LOGS/adsbinav.log", "a")
            end
            io.write(adsbinav.logfile, string.format("%.2f ", adsbinav.clock()) .. tostring(str) .. "\n")
        end
    end,

    showMemoryUsage = function(remark)
        if not adsbinav.oldMemoryUsage then
            collectgarbage()
            adsbinav.oldMemoryUsage = collectgarbage("count")
            adsbinav.print(string.format("MEM %s: %d", remark, adsbinav.oldMemoryUsage*1024))
            return
        end
        collectgarbage()
        local currentMemoryUsage = collectgarbage("count")
        local increment = currentMemoryUsage - adsbinav.oldMemoryUsage
        if increment ~= 0 then
            adsbinav.print(string.format("MEM %s: %d (+%d)", remark, currentMemoryUsage*1024, increment*1024))
        end
        adsbinav.oldMemoryUsage = currentMemoryUsage
    end,

    dumpTable = function(table, maxDepth)
        local seen = {}
        maxDepth = maxDepth or 2

        local function dumpTableInternal(tbl, indent, depth)
            if seen[tbl] or depth > maxDepth then
                adsbinav.print(indent .. "*already visited or max depth*")
                return
            end
            seen[tbl] = true

            for k, v in pairs(tbl) do
                local keyStr = tostring(k)
                local vType = type(v)
                if vType == "table" then
                    adsbinav.print(indent .. keyStr .. " = {")
                    dumpTableInternal(v, indent .. "  ", depth + 1)
                    adsbinav.print(indent .. "}")
                else
                    adsbinav.print(indent .. keyStr .. " = " .. tostring(v))
                end
            end
        end

        dumpTableInternal(table, "", 0)
    end,

    printGlobals = function(maxDepth)
        adsbinav.dumpTable(_G, maxDepth)
    end,

    isInteger = function(n)
        return type(n) == "number" and n == math.floor(n)
    end,
    --]]
}
