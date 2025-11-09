local i = 1
local scripts = assert(loadScript("COMPILE/scripts.lua"))
collectgarbage()

local function deleteOrTruncateFile(filepath)
    local file = io.open(filepath, "r")
    if file then
        io.close(file)
        if del then
            -- EdgeTX 2.9+: delete file
            del(filepath)
            return
        end
        -- Older EdgeTX/OpenTX: truncate file
        file = io.open(filepath, "w")
        io.close(file)
    end
end


local function compile()
    local script = scripts(i)
    i = i + 1
    if script then
        lcd.clear()
        lcd.drawText(2, 2, "Compiling...", SMLSIZE)
        lcd.drawText(2, 58, script, SMLSIZE)
        collectgarbage()
        assert(loadScript(script, 'cd')) -- The 'd' flags gets removed in by minimize.lua
        return 0
    end
    local file = io.open("COMPILE/scripts_compiled.lua", 'w')
    io.write(file, "return true")
    io.close(file)
    assert(loadScript("COMPILE/scripts_compiled.lua", 'c'))
    return 1
end

return compile
