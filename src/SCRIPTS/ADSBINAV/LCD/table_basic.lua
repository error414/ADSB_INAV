--[[
 Helper for EdgeTX Lua scripts:
 Draws a scrollable table with blue header, grey alternating rows,
 cell borders, and horizontal scrollbar fixed at bottom of display.
 Column widths can be set in percentages of LCD width.
 Supports Bitmap objects directly inside cells.
]]

local TABLE_FONT = SMLSIZE
local ROW_HEIGHT_BASE = 20
local TEXT_PADDING = 2

local LCD_W = LCD_W
local LCD_H = LCD_H

local function getThemeColors()
    local darkMode = lcd.themeColor and (lcd.themeColor(lcd.COLOR_BG_DEFAULT) == lcd.RGB(30,30,30))

    if darkMode then
        return {
            HEADER = lcd.RGB(0, 150, 255),
            GRID   = lcd.RGB(60, 60, 60),
            ROW    = lcd.RGB(200, 200, 200),
            BG     = lcd.RGB(30, 30, 30)
        }
    else
        return {
            HEADER = lcd.RGB(0, 120, 255),
            GRID   = lcd.RGB(200, 200, 200),
            ROW    = lcd.RGB(20, 20, 20),
            BG     = lcd.RGB(245, 245, 245)
        }
    end
end

local COLORS = getThemeColors()
local state = { page = 1 }

-- Simple word wrap (approximation)
local function wrapText(text, colWidth)
    local lines = {}
    local current = ""
    for word in string.gmatch(text, "%S+") do
        local test = (current == "") and word or (current .. " " .. word)
        if #test * 6 > colWidth and current ~= "" then
            table.insert(lines, current)
            current = word
        else
            current = test
        end
    end
    if current ~= "" then table.insert(lines, current) end
    return lines
end

local function drawCellBorder(x, y, w, h)
    if lcd.setColor then lcd.setColor(CUSTOM_COLOR, COLORS.GRID) end
    lcd.drawLine(x, y, x + w, y, SOLID, CUSTOM_COLOR)
    lcd.drawLine(x, y + h, x + w, y + h, SOLID, CUSTOM_COLOR)
    lcd.drawLine(x, y, x, y + h, SOLID, CUSTOM_COLOR)
    lcd.drawLine(x + w, y, x + w, y + h, SOLID, CUSTOM_COLOR)
end

-- Compute row height based on text lines or bitmap height
local function computeRowHeight(row, widths)
    local maxHeight = ROW_HEIGHT_BASE
    for c = 1, #row do
        local val = row[c]
        if type(val) == "userdata" then
            local w, h = Bitmap.getSize(val)
            maxHeight = math.max(maxHeight, h + 4) -- padding
        else
            local lines = wrapText(tostring(val), widths[c] - 2*TEXT_PADDING)
            maxHeight = math.max(maxHeight, #lines * ROW_HEIGHT_BASE)
        end
    end
    return maxHeight
end

-- Main drawTable function
local function drawTable(yStart, headers, data, event, colWidthsPercent)
    local numCols = #headers
    local widths = {}

    -- Convert percentages to pixel widths
    if colWidthsPercent and #colWidthsPercent == numCols then
        for i = 1, numCols do
            widths[i] = math.floor(LCD_W * colWidthsPercent[i] / 100)
        end
    else
        local colWidth = math.floor(LCD_W / numCols)
        for i = 1, numCols do widths[i] = colWidth end
    end

    -- Handle paging
    local totalRows = #data
    if event == EVT_VIRTUAL_NEXT_PAGE then
        state.page = state.page + 1
    elseif event == EVT_VIRTUAL_PREV_PAGE then
        state.page = math.max(1, state.page - 1)
    end

    -- Pagination calculation
    local totalHeight = yStart + ROW_HEIGHT_BASE
    local startIdx = 1
    local pages = {}
    for i = 1, totalRows do
        local row = data[i]
        local rowHeight = computeRowHeight(row, widths)
        if totalHeight + rowHeight > LCD_H - ROW_HEIGHT_BASE - 10 then
            table.insert(pages, {startIdx = startIdx, endIdx = i - 1})
            startIdx = i
            totalHeight = yStart + ROW_HEIGHT_BASE
        end
        totalHeight = totalHeight + rowHeight
    end
    table.insert(pages, {startIdx = startIdx, endIdx = totalRows})

    if state.page > #pages then state.page = #pages end
    local page = pages[state.page]

    -- Clear table area
    if lcd.setColor then lcd.setColor(CUSTOM_COLOR, COLORS.BG) end
    lcd.drawFilledRectangle(0, yStart, LCD_W, LCD_H - yStart, CUSTOM_COLOR)

    -- Header
    if lcd.setColor then
        lcd.setColor(CUSTOM_COLOR, COLORS.HEADER)
        lcd.drawFilledRectangle(0, yStart, LCD_W, ROW_HEIGHT_BASE, CUSTOM_COLOR)
    end
    local x = 0
    for c = 1, numCols do
        lcd.drawText(x + widths[c]/2, yStart + 2, headers[c], TABLE_FONT + CENTER + WHITE)
        x = x + widths[c]
    end

    local y = yStart + ROW_HEIGHT_BASE

    -- Rows
    for i = page.startIdx, page.endIdx do
        local row = data[i]
        local rowHeight = computeRowHeight(row, widths)
        local yRowStart = y

        -- Alternating row background
        if i % 2 == 0 and lcd.setColor then
            lcd.setColor(CUSTOM_COLOR, lcd.RGB(240,240,240))
            lcd.drawFilledRectangle(0, y, LCD_W, rowHeight, CUSTOM_COLOR)
        end

        x = 0
        for c = 1, numCols do
            local val = row[c]
            local cellX = x
            local cellY = y
            local cellW = widths[c]

            if type(val) == "userdata" then
                local w, h = Bitmap.getSize(val)
                lcd.drawBitmap(val, cellX + (cellW - w)/2, cellY + (rowHeight - h)/2)
            else
                local lines = wrapText(tostring(val), cellW - 2*TEXT_PADDING)
                for lineIdx = 1, #lines do
                    lcd.drawText(cellX + cellW/2, cellY + (lineIdx-1)*ROW_HEIGHT_BASE, lines[lineIdx], TABLE_FONT + CENTER)
                end
            end

            drawCellBorder(cellX, cellY, cellW, rowHeight)
            x = x + cellW
        end

        y = y + rowHeight
    end

    -- Horizontal scrollbar at bottom
    local scrollbarHeight = 3
    local scrollbarY = LCD_H - scrollbarHeight
    local scrollbarWidth = LCD_W
    local barWidth = math.floor(scrollbarWidth / #pages)
    local barX = math.floor((state.page - 1) * barWidth)

    if lcd.setColor then
        lcd.setColor(CUSTOM_COLOR, lcd.RGB(200, 200, 200))
        lcd.drawFilledRectangle(0, scrollbarY, scrollbarWidth, scrollbarHeight, CUSTOM_COLOR)
        lcd.setColor(CUSTOM_COLOR, COLORS.HEADER)
        lcd.drawFilledRectangle(barX, scrollbarY, barWidth, scrollbarHeight, CUSTOM_COLOR)
    end
end

return {
    drawTable = drawTable
}
