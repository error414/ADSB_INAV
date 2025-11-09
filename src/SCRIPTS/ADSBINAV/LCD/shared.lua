local COLOR_HEADER_BG      = lcd.RGB(0, 90, 200)   -- blue (similar to EdgeTX UI)
local COLOR_HEADER_TEXT    = WHITE                 -- white text
local COLOR_SIDE_SHAPE     = lcd.RGB(0, 70, 160)   -- darker blue for polygon
local COLOR_COUNTER_TEXT   = WHITE
local COLOR_WARNING_TEXT   = lcd.RGB(0xFF, 0xBD, 0xBC)

local function getLineSpacing()
    if adsbinav.radio.highRes then
        return 25
    end
    return 10
end

local function drawTextMultiline(x, y, text, options)
    for str in string.gmatch(text, "([^\n]+)") do
        lcd.drawText(x, y, str, options)
        y = y + getLineSpacing()
    end
end

local function clipValue(val, min, max)
    if val < min then
        val = min
    elseif val > max then
        val = max
    end
    return val
end

local function drawScreenTitle(icon, screenTitle, statusText, counter)
    local headerHeight = 45

    ----------------------------------------------------------------
    -- Draw header background
    lcd.drawFilledRectangle(0, 0, LCD_W, headerHeight, COLOR_HEADER_BG)

    ----------------------------------------------------------------
    -- Draw irregular pentagon shape on the left
    lcd.drawFilledRectangle(0, 0, 45, headerHeight, COLOR_SIDE_SHAPE) -- base rectangle

    local startX = 45
    local tipX   = 52
    for x = startX, tipX do
        local rel = (x - startX) / (tipX - startX)
        local top = headerHeight * rel / 2
        local bottom = headerHeight - top
        lcd.drawFilledRectangle(x, top, 1, bottom - top, COLOR_SIDE_SHAPE)
    end

    ----------------------------------------------------------------
    -- Icon (moved slightly lower vertically to be centered)
    ----------------------------------------------------------------
    if type(icon) == "string" then
        local bmp = Bitmap.open(icon)
        if bmp then
            lcd.drawBitmap(bmp, 8, 5)
        else
            lcd.drawText(10, 8, "?", COLOR_HEADER_TEXT)
        end
    elseif type(icon) == "table" and icon.bitmap then
        lcd.drawBitmap(icon.bitmap, 8, 8)
    end

    ----------------------------------------------------------------
    -- Draw screen title
    ----------------------------------------------------------------
    lcd.drawText(60, 3, screenTitle, COLOR_HEADER_TEXT)

    ----------------------------------------------------------------
    -- Draw status
    ----------------------------------------------------------------
    if statusText then
        local textWidth = #screenTitle * 8
        lcd.drawText(60 + textWidth + 8, 3, statusText, COLOR_WARNING_TEXT + SMLSIZE)
    end

    ----------------------------------------------------------------
    -- Draw message counter on the right
    ----------------------------------------------------------------
    if counter then
        local counterText = string.format("%d", counter or 0)
        local textWidth = #counterText * 8
        lcd.drawText(LCD_W - textWidth - 8, 3, counterText, COLOR_COUNTER_TEXT)
    end
end

return {
    getLineSpacing = getLineSpacing,
    drawTextMultiline = drawTextMultiline,
    clipValue = clipValue,
    textOptions = TEXT_COLOR or 0,
    foregroundColor = LINE_COLOR or SOLID,
    drawScreenTitle = drawScreenTitle,
}