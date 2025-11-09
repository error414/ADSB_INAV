chdir("/SCRIPTS/ADSBINAV")

local run = nil
local scriptsCompiled = assert(loadScript("COMPILE/scripts_compiled.lua"))()

if scriptsCompiled then
    assert(loadScript("adsbinav.lua"))()
    adsbinav.radio = adsbinav.executeScript("radios").msp
    adsbinav.mspQueue = adsbinav.executeScript("MSP/mspQueue")
    adsbinav.mspQueue.maxRetries = 3
    adsbinav.mspHelper = adsbinav.executeScript("MSP/mspHelper")

    run = adsbinav.executeScript("ui_lcd")

else
    run = assert(loadScript("COMPILE/compile.lua"))()
    collectgarbage()
end

return { run = run}
