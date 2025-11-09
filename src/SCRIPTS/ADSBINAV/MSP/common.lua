-- MSP Runtime for EdgeTX
-- Compatible with both MSP v1 and v2

local MSPV_DEFAULT = 2
local MSPV = MSPV_DEFAULT

local function VERSION_FLAG()
    if MSPV == 2 then
        return bit32.lshift(1, 6)
    else
        return bit32.lshift(1, 5)
    end
end

local MSP_STARTFLAG = bit32.lshift(1, 4)

local mspSeq = 0
local mspRemoteSeq = 0
local mspRxBuf = {}
local mspRxError = false
local mspRxSize = 0
local mspRxCRC = 0
local mspRxReq = 0
local mspStarted = false
local mspLastReq = 0
local mspTxBuf = {}
local mspTxIdx = 1
local mspTxCRC = 0

---------------------------------------------------
-- EDGE-TX INTERFACE INIT
---------------------------------------------------
local protocolScript = "MSP/" .. adsbinav.executeScript("protocols")
local mspSend, mspPoll, telemetryPush, maxTxBufferSize, maxRxBufferSize = adsbinav.executeScript(protocolScript)


function setMSPVersion(v)
    if v == 1 or v == 2 then
        MSPV = v
    end
end

function getMSPVersion()
    return MSPV
end

---------------------------------------------------
-- MSP TRANSMIT PROCESSING
---------------------------------------------------
local function mspProcessTxQ()
    if (#mspTxBuf == 0) then
        return false
    end

    if not telemetryPush() then
        return true
    end

    local payload = {}
    payload[1] = mspSeq + VERSION_FLAG()
    mspSeq = bit32.band(mspSeq + 1, 0x0F)

    if mspTxIdx == 1 then
        payload[1] = payload[1] + MSP_STARTFLAG
    end

    local i = 2
    while (i <= maxTxBufferSize) and (mspTxIdx <= #mspTxBuf) do
        payload[i] = mspTxBuf[mspTxIdx]
        mspTxIdx = mspTxIdx + 1
        if MSPV ~= 2 then
            mspTxCRC = bit32.bxor(mspTxCRC, payload[i])
        end
        i = i + 1
    end

    if i <= maxTxBufferSize then
        if MSPV ~= 2 then
            payload[i] = mspTxCRC
        end
        mspSend(payload)
        mspTxBuf = {}
        mspTxIdx = 1
        mspTxCRC = 0
        return false
    end
    mspSend(payload)
    return true
end

---------------------------------------------------
-- MSP SEND REQUEST
---------------------------------------------------
function mspSendRequest(cmd, payload)
    if (#mspTxBuf ~= 0) or not cmd or type(payload) ~= "table" then
        return nil
    end

    mspTxBuf = {}
    mspTxIdx = 1
    mspTxCRC = 0

    local len = #(payload)

    if MSPV == 2 then
        -- MSPv2 format
        mspTxBuf[1] = 0 -- flags
        mspTxBuf[2] = bit32.band(cmd, 0xFF)
        mspTxBuf[3] = bit32.band(bit32.rshift(cmd, 8), 0xFF)
        mspTxBuf[4] = bit32.band(len, 0xFF)
        mspTxBuf[5] = bit32.band(bit32.rshift(len, 8), 0xFF)
        for i = 1, len do
            mspTxBuf[5 + i] = bit32.band(payload[i] or 0, 0xFF)
        end
    else
        adsbinav.print("MSP1")
        -- MSPv1 format
        mspTxBuf[1] = bit32.band(len, 0xFF)
        mspTxBuf[2] = bit32.band(cmd, 0xFF)
        mspTxCRC = bit32.bxor(mspTxBuf[1], mspTxBuf[2])
        for i = 1, len do
            local b = bit32.band(payload[i] or 0, 0xFF)
            mspTxBuf[2 + i] = b
            mspTxCRC = bit32.bxor(mspTxCRC, b)
        end
        mspTxBuf[#mspTxBuf + 1] = mspTxCRC
    end

    mspLastReq = cmd
    return mspProcessTxQ()
end

---------------------------------------------------
-- MSP REPLY PARSING
---------------------------------------------------
local function mspReceivedReply(payload)
    local idx = 1
    local status = payload[idx]
    local version = bit32.rshift(bit32.band(status, 0x60), 5)
    local start = bit32.btest(status, 0x10)
    local seq = bit32.band(status, 0x0F)
    local err = bit32.btest(status, 0x80)
    idx = idx + 1

    if start then
        mspRxBuf = {}
        mspRxError = err

        if version == 2 then
            local _flags = payload[idx]; idx = idx + 1
            local cmdLo = payload[idx]; idx = idx + 1
            local cmdHi = payload[idx]; idx = idx + 1
            local lenLo = payload[idx]; idx = idx + 1
            local lenHi = payload[idx]; idx = idx + 1
            mspRxReq = bit32.bor(bit32.lshift(cmdHi, 8), cmdLo)
            mspRxSize = bit32.bor(bit32.lshift(lenHi, 8), lenLo)
            mspRxCRC = 0
        else
            mspRxSize = payload[idx]; idx = idx + 1
            mspRxReq = mspLastReq
            if version == 1 then
                mspRxReq = payload[idx]; idx = idx + 1
            end
            mspRxCRC = bit32.bxor(mspRxSize, mspRxReq)
        end

        if mspRxReq == mspLastReq then
            mspStarted = true
        end
    elseif not mspStarted then
        return nil
    elseif bit32.band(mspRemoteSeq + 1, 0x0F) ~= seq then
        mspStarted = false
        return nil
    end

    while (idx <= maxRxBufferSize) and (#mspRxBuf < mspRxSize) do
        mspRxBuf[#mspRxBuf + 1] = payload[idx]
        if version ~= 2 then
            mspRxCRC = bit32.bxor(mspRxCRC, payload[idx])
        end
        idx = idx + 1
    end

    if idx > maxRxBufferSize then
        mspRemoteSeq = seq
        return false
    end

    mspStarted = false

    if version ~= 2 and mspRxCRC ~= payload[idx] then
        return nil
    end

    return true
end

---------------------------------------------------
-- MSP POLL
---------------------------------------------------
function mspPollReply()
    local startTime = adsbinav.clock()
    while (adsbinav.clock() - startTime < 0.05) do
        local mspData = mspPoll()
        if mspData ~= nil and mspReceivedReply(mspData) then
            mspLastReq = 0
            return mspRxReq, mspRxBuf, mspRxError
        end
    end
end

function mspClearTxBuf()
    mspTxBuf = {}
    mspTxIdx = 1
    mspTxCRC = 0
end

return mspSendRequest, mspProcessTxQ, mspPollReply, mspClearTxBuf
