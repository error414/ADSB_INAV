-- Usage: local mspSend, mspPoll, maxTxBufferSize, maxRxBufferSize = adsbinav.executeScript("MSP/csrf")

-- CRSF Devices
local CRSF_ADDRESS_BETAFLIGHT          = 0xC8
local CRSF_ADDRESS_RADIO_TRANSMITTER   = 0xEA

local function mspSend(payload)
    local payloadOut = { CRSF_ADDRESS_BETAFLIGHT, CRSF_ADDRESS_RADIO_TRANSMITTER }
    for i = 1, #(payload) do
        payloadOut[i+2] = payload[i]
    end
    local CRSF_FRAMETYPE_MSP_WRITE = 0x7C      -- write with 60 byte chunked binary

    --[[adsbinav.print("-----")
    adsbinav.print("TX (%d B)", #payloadOut)
    for i = 1,#payloadOut do
        adsbinav.print("  ["..string.format("%u", i).."]:  0x"..string.format("%X", payloadOut[i]))
    end
    adsbinav.print("-----")]]

    return crossfireTelemetryPush(CRSF_FRAMETYPE_MSP_WRITE, payloadOut)
end

local function mspPoll()
    while true do
        local cmd, data = crossfireTelemetryPop()
        local CRSF_FRAMETYPE_MSP_RESP = 0x7B      -- reply with 60 byte chunked binary
        if cmd == CRSF_FRAMETYPE_MSP_RESP and data[1] == CRSF_ADDRESS_RADIO_TRANSMITTER and data[2] == CRSF_ADDRESS_BETAFLIGHT then

            --[[adsbinav.print("-----")
            adsbinav.print("RX (%d B)", #data)
            for i = 1,#data do
                adsbinav.print("  ["..string.format("%u", i).."]:  0x"..string.format("%X", data[i]))
            end
            adsbinav.print("-----")]]

            local mspData = {}
            for i = 3, #data do
                mspData[i - 2] = data[i]
            end
            return mspData
        elseif cmd == nil then
            return nil
        end
    end
end

local maxTxBufferSize = 8
local maxRxBufferSize = 58
return mspSend, mspPoll, crossfireTelemetryPush, maxTxBufferSize, maxRxBufferSize
