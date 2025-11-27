-- TanPhu Finder Loader v1
--  • Mỗi user có 1 key riêng (TP-xxxx)
--  • Loader gọi API /check_license -> trả về script_url chính
--  • Nếu ok: loadscript, nếu fail: báo lỗi

local API_BASE = "https://reparative-mira-dominatingly.ngrok-free.dev"

local Players     = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local StarterGui  = game:GetService("StarterGui")
local LocalPlayer = Players.LocalPlayer

--   >>> KEY sẽ được set từ ngoài:
--   getgenv().TANPHU_KEY = "TP-XXXXX"
local KEY = getgenv().TANPHU_KEY

------------------------------------------------
-- ✨ HWID
------------------------------------------------
local function getHWID()
    if typeof(gethwid) == "function" then
        return gethwid()
    end

    local ok, clientId = pcall(function()
        return game:GetService("RbxAnalyticsService"):GetClientId()
    end)
    if ok and clientId then
        return "RbxClient:" .. clientId
    end

    return "UserId:" .. tostring(LocalPlayer.UserId)
end

------------------------------------------------
-- ✨ http_request / syn.request / request
------------------------------------------------
local http_request_impl =
    (typeof(syn) == "table" and typeof(syn.request) == "function" and syn.request)
    or (typeof(http_request) == "function" and http_request)
    or (typeof(request) == "function" and request)
    or (typeof(http) == "table" and typeof(http.request) == "function" and http.request)

local function notify(msg, dur)
    dur = dur or 10
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = "TanPhu Finder",
            Text = tostring(msg),
            Duration = dur
        })
    end)
    print("[TanPhuFinder] " .. tostring(msg))
end

if not http_request_impl then
    notify("Executor không hỗ trợ http_request (syn/request/http).", 12)
    return
end

if not KEY or KEY == "" then
    notify("Chưa set getgenv().TANPHU_KEY, vui lòng copy script đúng từ Discord.", 12)
    return
end

------------------------------------------------
-- ✨ Gửi POST JSON
------------------------------------------------
local function post_json(path, tbl)
    local body = HttpService:JSONEncode(tbl or {})
    local ok, res = pcall(http_request_impl, {
        Url = API_BASE .. path,
        Method = "POST",
        Headers = {
            ["Content-Type"] = "application/json"
        },
        Body = body
    })
    if not ok then
        return nil, "http_error: " .. tostring(res)
    end
    if not res or res.StatusCode ~= 200 then
        local code = res and res.StatusCode or "nil"
        local text = res and res.Body or ""
        return nil, "status_" .. tostring(code) .. " / " .. tostring(text)
    end
    local ok2, data = pcall(function()
        return HttpService:JSONDecode(res.Body)
    end)
    if not ok2 or type(data) ~= "table" then
        return nil, "json_decode_error"
    end
    return data, nil
end

------------------------------------------------
-- ✨ MAIN FLOW
------------------------------------------------
notify("Đang kiểm tra key...", 5)

local hwid = getHWID()
local data, err = post_json("/check_license", {
    key  = KEY,
    hwid = hwid,
})

if not data then
    notify("Không kết nối được server key: " .. tostring(err), 12)
    return
end

if not data.ok then
    notify("Key lỗi: " .. tostring(data.message or data.error_code or "unknown"), 12)
    return
end

local left_days = tonumber(data.left_days or 0) or 0
notify("Key OK! Còn ~" .. tostring(left_days) .. " ngày. Đang load script...", 8)

local mainUrl = data.script_url
if type(mainUrl) ~= "string" or mainUrl == "" then
    notify("Server không trả về script_url.", 10)
    return
end

local ok, err2 = pcall(function()
    loadstring(game:HttpGet(mainUrl))()
end)
if not ok then
    notify("Lỗi khi chạy script chính: " .. tostring(err2), 12)
end
