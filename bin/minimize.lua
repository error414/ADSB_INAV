print("Minimizing script memory usage...")

-- Step 1:
-- - Remove 'id = "xxx"' entries from fields table in the page files.
-- - Remove 'simulatorResponse = {...}' entries in MSP files.
-- - Remove double spaces in ui.lua to make it compile on some b&w radios.

local genericReplacements = {
    {
        -- Replace --[NIR with --[[ to comment out debug code that should not be in a release
        files = "/SCRIPTS/ADSBINAV/",
        match = "--%[NIR",
        replace = "--%[NIR",
        replacement = "--[["
    },
    {
        -- Remove simulatorResponse = {...} from MSP APIs, since they are not used outside the simulator.
        files = "/SCRIPTS/ADSBINAV/MSP/",
        match = "simulatorResponse = {(.-)}",
        replace = "simulatorResponse = {(.-)},?",
        replacement = ""
    },
    {
        -- Remove debug info from release builds.
        files = "/SCRIPTS/ADSBINAV/COMPILE/compile.lua",
        match = "loadScript%(script, %'cd%'%)",
        replace = "loadScript%(script, %'cd%'%)",
        replacement = "loadScript(script, 'c')"
    }
}

local function processFile(filename, genericReplacement)
    local input_file = io.open(filename, "r")
    if input_file then
        local temp_file = io.open(filename .. ".tmp", "w") -- Temporary file to store changes

        for line in input_file:lines() do
            local new_line = line
            if string.match(new_line, genericReplacement.match) then
                --print("Found '" .. genericReplacement.match .. "'")
                new_line = string.gsub(new_line, genericReplacement.replace, genericReplacement.replacement)
            end
            temp_file:write(new_line .. "\n")
        end

        input_file:close()
        temp_file:close()

        -- Replace original file with the updated file
        os.remove(filename)
        os.rename(filename .. ".tmp", filename)

        print("Updated " .. filename)
    else
        print("Could not open " .. filename)
    end
end

local function processGenericReplacements()
    local files = assert(loadfile("./SCRIPTS/ADSBINAV/COMPILE/scripts.lua"))
    local i = 1
    while true do
        local script = files(i)
        i = i + 1
        if script == nil then break end
        for _, genericReplacement in ipairs(genericReplacements) do
            if type(genericReplacement.files) == "table" then
                for _, partialFileName in ipairs(genericReplacement.files) do
                    if string.match(script, partialFileName) then
                        processFile("." .. script, genericReplacement)
                    end
                end
            elseif string.match(script, genericReplacement.files) then
                processFile("." .. script, genericReplacement)
            end
        end
    end
end

processGenericReplacements()


local function replace(r)
    for _, filename in ipairs(r.files) do
        --print("Opening " .. filename)
        local input_file = io.open(filename, "r")
        if input_file then
            local temp_file = io.open(filename .. ".tmp", "w") -- Temporary file to store changes

            for line in input_file:lines() do
                local new_line = line
                for _, v in ipairs(r) do
                    new_line = string.gsub(new_line, v[1], v[2])
                end
                temp_file:write(new_line .. "\n")
            end

            input_file:close()
            temp_file:close()

            -- Replace original file with the updated file
            os.remove(filename)
            os.rename(filename .. ".tmp", filename)

            print("Updated " .. filename)
        else
            print("Could not open " .. filename)
        end
    end
end

replace(mspRcTuningReplacements)
replace(mspPidTuningReplacements)
replace(mspPidProfileReplacements)
