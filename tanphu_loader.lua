--==================================================
-- TanPhu Finder Premium Loader (Key + HWID + Kick)
--==================================================

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- KEY được set từ snippet trong Discord:
-- getgenv().TANPHU_KEY = "TP-XXXX..."
local KEY = getgenv().TANPHU_KEY

if not KEY or KEY == "" then
    warn("[TanPhu] ❌ Chưa set key (getgenv().TANPHU_KEY).")
    pcall(function()
        LocalPlayer:Kick("TanPhu | Chưa set key, hãy lấy script lại từ Discord.")
    end)
    return
end

-- URL API check_key (ngrok của m)
local AUTH_URL = "https://reparative-mira-dominatingly.ngrok-free.dev/check_key"
local PRODUCT  = "TanPhuFinder"

--========================
-- HTTP helper
--========================
local http_request_impl =
    (typeof(syn) == "table" and typeof(syn.request) == "function" and syn.request)
    or (typeof(http_request) == "function" and http_request)
    or (typeof(request) == "function" and request)
    or (typeof(http) == "table" and typeof(http.request) == "function" and http.request)

local function safeRequest(opts)
    if not http_request_impl then
        return nil, "no_http"
    end
    local ok, res = pcall(http_request_impl, opts)
    if not ok then
        return nil, res
    end
    return res, nil
end

local function hardKick(msg)
    msg = msg or "TanPhu | Authentication failed."
    warn("[TanPhu][KICK]", msg)
    pcall(function()
        LocalPlayer:Kick(msg)
    end)
end

--========================
-- HWID helper
--========================
local function getHWID()
    -- ưu tiên gethwid của executor
    if typeof(gethwid) == "function" then
        local ok, v = pcall(gethwid)
        if ok and v then
            return tostring(v)
        end
    end

    -- fallback: ClientId Roblox (vẫn là 1 dạng HWID)
    local ok, cid = pcall(function()
        return game:GetService("RbxAnalyticsService"):GetClientId()
    end)
    if ok and cid then
        return tostring(cid)
    end

    -- nếu tới đây vẫn không có → coi như không có HWID, kick luôn
    return nil
end

--========================
-- CALL API /check_key
--========================
local function checkKeyAndLoad()
    local hwid = getHWID()
    if not hwid then
        hardKick("TanPhu | Executor không hỗ trợ HWID, không thể dùng premium.")
        return
    end

    local payload = {
        key     = KEY,
        hwid    = hwid,
        product = PRODUCT,
    }

    local body = HttpService:JSONEncode(payload)

    local res, err = safeRequest({
        Url = AUTH_URL,
        Method = "POST",
        Headers = {
            ["Content-Type"] = "application/json"
        },
        Body = body
    })

    if not res then
        hardKick("TanPhu | Không kết nối được auth server (" .. tostring(err) .. ").")
        return
    end

    if res.StatusCode ~= 200 then
        hardKick("TanPhu | HTTP " .. tostring(res.StatusCode) .. " từ auth server.")
        return
    end

    local ok, data = pcall(function()
        return HttpService:JSONDecode(res.Body)
    end)
    if not ok or type(data) ~= "table" then
        hardKick("TanPhu | Lỗi đọc dữ liệu từ auth server.")
        return
    end

    if not data.ok then
        local reason = tostring(data.reason or "unknown")
        if reason == "key_not_found" then
            hardKick("TanPhu | Key không tồn tại.")
        elseif reason == "expired" then
            hardKick("TanPhu | Key đã hết hạn.")
        elseif reason == "not_redeemed" then
            hardKick("TanPhu | Key chưa được redeem trong Discord.")
        elseif reason == "hwid_mismatch" then
            hardKick("TanPhu | HWID không khớp. Liên hệ owner để reset HWID.")
        elseif reason == "wrong_product" then
            hardKick("TanPhu | Key không thuộc TanPhu Finder.")
        elseif reason == "missing_key_or_hwid" then
            hardKick("TanPhu | Thiếu key hoặc HWID.")
        else
            hardKick("TanPhu | Key lỗi: " .. reason)
        end
        return
    end

    local script_url = data.script_url
        or "https://raw.githubusercontent.com/LVTP1312/tanphupremium/main/tanphu_premium_main.lua"

    warn("[TanPhu] ✅ Key OK, loading premium script...")
    local ok2, err2 = pcall(function()
        loadstring(game:HttpGet(script_url))()
    end)
    if not ok2 then
        hardKick("TanPhu | Lỗi load premium script: " .. tostring(err2))
    end
end

checkKeyAndLoad()
