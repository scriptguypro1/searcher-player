loadstring([=[
local p, hs, uis, ts, ms, ltg, tws, sts, rs =
	game:GetService("Players"),
	game:GetService("HttpService"),
	game:GetService("UserInputService"),
	game:GetService("TeleportService"),
	game:GetService("MarketplaceService"),
	game:GetService("Lighting"),
	game:GetService("TweenService"),
	game:GetService("Stats"),
	game:GetService("RunService")

local l = p.LocalPlayer
if not l then
	p:GetPropertyChangedSignal("LocalPlayer"):Wait()
	l = p.LocalPlayer
end

local function getUiParent()
	if type(gethui) == "function" then
		local ok, hui = pcall(gethui)
		if ok and hui then
			return hui
		end
	end
	return l:FindFirstChildOfClass("PlayerGui") or l:WaitForChild("PlayerGui", 10)
end

local g = getUiParent()
if not g then return end

if getgenv and type(getgenv) == "function" then
	local env = getgenv()
	if type(env.__VlexHubCleanup) == "function" then
		pcall(env.__VlexHubCleanup)
	end
end

pcall(function()
	local old = g:FindFirstChild("VlexPlayerJoinerGui")
	if old then old:Destroy() end
	local oldNs = g:FindFirstChild("NS")
	if oldNs then oldNs:Destroy() end
	local oldBlur = ltg:FindFirstChild("VlexIntroBlur")
	if oldBlur then oldBlur:Destroy() end
end)

local activeConnections = {}
local function trackConn(conn)
	if conn then
		table.insert(activeConnections, conn)
	end
	return conn
end

local function trimStr(s)
	return string.match(tostring(s or ""), "^%s*(.-)%s*$") or ""
end

local function sanitizeJobId(raw)
	local s = trimStr(raw)
	s = string.gsub(s, "^ID:%s*", "")
	s = string.gsub(s, "^[\"']+", "")
	s = string.gsub(s, "[\"']+$", "")
	return trimStr(s)
end

local function isLikelyValidJobId(jid)
	if type(jid) ~= "string" then return false end
	if #jid < 8 or #jid > 128 then return false end
	return string.find(jid, "^[%w%-]+$") ~= nil
end

local function copyText(txt)
	local copyFn = setclipboard or toclipboard or set_clipboard
	if type(copyFn) == "function" then
		local ok = pcall(copyFn, tostring(txt))
		if ok then return true end
	end
	return false
end

local function bindTap(button, callback)
	local lastFire = 0
	local connected = false

	local function fire()
		local now = os.clock()
		if now - lastFire < 0.16 then return end
		lastFire = now
		task.spawn(function()
			pcall(callback)
		end)
	end

	if pcall(function()
		trackConn(button.Activated:Connect(fire))
		connected = true
	end) and connected then
		return
	end

	trackConn(button.MouseButton1Click:Connect(fire))
end

local function prepInput(tb)
	tb.ClearTextOnFocus = false
	tb.TextEditable = true
	return tb
end

-- 10-Pack Registry (101 - 1,100)
local PACK_CATALOG = {
	{ id = "P1", code = "INTEL", range = "101-200", enabled = true },
	{ id = "P2", code = "SNIPE", range = "201-300", enabled = true },
	{ id = "P3", code = "HOP",   range = "301-400", enabled = true },
	{ id = "P4", code = "RADAR", range = "401-500", enabled = true },
	{ id = "P5", code = "ESP",   range = "501-600", enabled = true },
	{ id = "P6", code = "FMT",   range = "601-700", enabled = true },
	{ id = "P7", code = "LISTS", range = "701-800", enabled = true },
	{ id = "P8", code = "LOGS",  range = "801-900", enabled = true },
	{ id = "P9", code = "UI",    range = "901-1000", enabled = true },
	{ id = "P10",code = "GUARD", range = "1001-1100", enabled = true },
}

local function isPackEnabled(code)
	for _, pk in ipairs(PACK_CATALOG) do
		if pk.code == code then
			return pk.enabled
		end
	end
	return true
end

local themes = {
	{ name = "CYAN", accent = Color3.fromRGB(95, 195, 255), btn = Color3.fromRGB(38, 96, 150) },
	{ name = "EMERALD", accent = Color3.fromRGB(80, 235, 165), btn = Color3.fromRGB(32, 118, 84) },
	{ name = "VIOLET", accent = Color3.fromRGB(185, 130, 255), btn = Color3.fromRGB(88, 52, 150) },
	{ name = "AMBER", accent = Color3.fromRGB(255, 190, 80), btn = Color3.fromRGB(155, 98, 26) },
}
local themeIdx = 1
local copyModes = { "MULTI", "COMPACT", "JSON", "DISCORD" }
local copyModeIdx = 1
local tallCardMode = false

local gui = Instance.new("ScreenGui")
gui.Name = "VlexPlayerJoinerGui"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 140
gui.Parent = g

local introOverlay = Instance.new("Frame")
introOverlay.Name = "IntroOverlay"
introOverlay.Size = UDim2.fromScale(1, 1)
introOverlay.BackgroundColor3 = Color3.fromRGB(10, 12, 20)
introOverlay.BackgroundTransparency = 0.25
introOverlay.BorderSizePixel = 0
introOverlay.ZIndex = 200
introOverlay.Parent = gui

local introTitle = Instance.new("TextLabel")
introTitle.Size = UDim2.new(0.9, 0, 0, 44)
introTitle.Position = UDim2.new(0.05, 0, 0.5, -28)
introTitle.BackgroundTransparency = 1
introTitle.Text = "Welcome"
introTitle.TextColor3 = Color3.fromRGB(245, 250, 255)
introTitle.TextTransparency = 1
introTitle.TextWrapped = true
introTitle.TextScaled = false
introTitle.TextSize = 26
introTitle.Font = Enum.Font.GothamBold
introTitle.ZIndex = 201
introTitle.Parent = introOverlay

local introSub = Instance.new("TextLabel")
introSub.Size = UDim2.new(0.9, 0, 0, 22)
introSub.Position = UDim2.new(0.05, 0, 0.5, 16)
introSub.BackgroundTransparency = 1
introSub.Text = "Loading modules..."
introSub.TextColor3 = Color3.fromRGB(165, 195, 235)
introSub.TextTransparency = 1
introSub.TextWrapped = true
introSub.TextSize = 13
introSub.Font = Enum.Font.GothamSemibold
introSub.ZIndex = 201
introSub.Parent = introOverlay

local introBlur = Instance.new("BlurEffect")
introBlur.Name = "VlexIntroBlur"
introBlur.Size = 0
pcall(function() introBlur.Parent = ltg end)

local DEFAULT_CARD_POS = UDim2.fromOffset(14, 62)
local CARD_WIDTH = 290
local BASE_CARD_HEIGHT = 386
local TALL_CARD_HEIGHT = 436

local card = Instance.new("Frame")
card.Name = "JoinerCard"
card.Position = DEFAULT_CARD_POS
card.Size = UDim2.fromOffset(CARD_WIDTH, BASE_CARD_HEIGHT)
card.BackgroundColor3 = Color3.fromRGB(15, 18, 26)
card.BackgroundTransparency = 0.05
card.BorderSizePixel = 0
card.ClipsDescendants = true
card.Active = true
card.Visible = false
card.ZIndex = 15
card.Parent = gui
Instance.new("UICorner", card).CornerRadius = UDim.new(0, 9)

local stroke = Instance.new("UIStroke")
stroke.Color = themes[1].accent
stroke.Thickness = 1.3
stroke.Parent = card

local header = Instance.new("Frame")
header.Size = UDim2.new(1, -12, 0, 20)
header.Position = UDim2.fromOffset(6, 5)
header.BackgroundTransparency = 1
header.Active = true
header.ZIndex = 16
header.Parent = card

local titleLbl = Instance.new("TextLabel")
titleLbl.Size = UDim2.new(1, -168, 1, 0)
titleLbl.BackgroundTransparency = 1
titleLbl.Text = "SEARCH HUB 1.1K"
titleLbl.TextColor3 = Color3.fromRGB(235, 246, 255)
titleLbl.TextXAlignment = Enum.TextXAlignment.Left
titleLbl.Font = Enum.Font.GothamBlack
titleLbl.TextSize = 9.2
titleLbl.ZIndex = 16
titleLbl.Parent = header

local function makeHdrBtn(txt, w, xOff, bg)
	local b = Instance.new("TextButton")
	b.Size = UDim2.fromOffset(w, 18)
	b.Position = UDim2.new(1, xOff, 0, 1)
	b.BackgroundColor3 = bg
	b.Text = txt
	b.TextColor3 = Color3.fromRGB(235, 246, 255)
	b.Font = Enum.Font.GothamBold
	b.TextSize = 6.8
	b.ZIndex = 17
	b.Parent = header
	Instance.new("UICorner", b).CornerRadius = UDim.new(0, 4)
	return b
end

local panicBtn = makeHdrBtn("PANIC", 34, -170, Color3.fromRGB(125, 28, 36))
local snapBtn  = makeHdrBtn("SNAP", 28, -133, Color3.fromRGB(30, 38, 52))
local themeBtn = makeHdrBtn("THM", 26, -102, Color3.fromRGB(34, 42, 62))
local optBtn   = makeHdrBtn("TALL", 28, -73, Color3.fromRGB(30, 46, 42))
local minBtn   = makeHdrBtn("-", 20, -43, Color3.fromRGB(28, 33, 45))
minBtn.TextSize = 12
local closeBtn = makeHdrBtn("X", 20, -21, Color3.fromRGB(52, 26, 32))
closeBtn.TextColor3 = Color3.fromRGB(255, 145, 145)

local restoreBtn = Instance.new("TextButton")
restoreBtn.Size = UDim2.fromOffset(68, 32)
restoreBtn.Position = UDim2.fromOffset(14, 62)
restoreBtn.BackgroundColor3 = Color3.fromRGB(20, 24, 34)
restoreBtn.Text = "JOINER +"
restoreBtn.TextColor3 = themes[1].accent
restoreBtn.Font = Enum.Font.GothamBold
restoreBtn.TextSize = 9
restoreBtn.Active = true
restoreBtn.Visible = false
restoreBtn.ZIndex = 16
restoreBtn.Parent = gui
Instance.new("UICorner", restoreBtn).CornerRadius = UDim.new(0, 8)

local resStroke = Instance.new("UIStroke")
resStroke.Color = themes[1].accent
resStroke.Thickness = 1.2
resStroke.Parent = restoreBtn

local statusHistory = {}
local statusHistoryIdx = 0
local logEntries = {}
local logFilterMode = "ALL"
local refreshLogTab = nil
local footerLbl = nil
local statusCard = nil
local cardStroke = nil
local retryJoinActive = false
local retryBtn = nil

local function pushLog(tag, msg)
	if not isPackEnabled("LOGS") then return end
	local stamp = os.date("%H:%M:%S")
	table.insert(logEntries, 1, {
		tag = tostring(tag or "INFO"),
		line = string.format("[%s][%s] %s", stamp, tostring(tag or "INFO"), tostring(msg)),
	})
	if #logEntries > 160 then
		table.remove(logEntries)
	end
	if type(refreshLogTab) == "function" then
		pcall(refreshLogTab)
	end
end

local function setFooter(msg, col)
	local textVal = tostring(msg or "")
	if footerLbl and footerLbl.Parent then
		footerLbl.Text = textVal
		footerLbl.TextColor3 = col or Color3.fromRGB(155, 175, 200)
	end
	if textVal ~= "" then
		table.insert(statusHistory, 1, { text = textVal, color = col or Color3.fromRGB(155, 175, 200) })
		if #statusHistory > 30 then table.remove(statusHistory) end
		statusHistoryIdx = 1
	end
end

local function flashStatusCard(col)
	if cardStroke and cardStroke.Parent then
		local orig = themes[themeIdx].accent
		cardStroke.Color = col
		task.delay(0.65, function()
			if cardStroke and cardStroke.Parent then
				cardStroke.Color = orig
			end
		end)
	end
end

local function copyWithFallback(txt, label)
	local ok = copyText(txt)
	if ok then
		pushLog("COPY", "Copied " .. (label or "text"))
		return true
	end
	setFooter("Clipboard N/A: " .. string.sub(tostring(txt), 1, 72), Color3.fromRGB(255, 195, 110))
	pushLog("ERR", "Clipboard fallback: " .. tostring(txt))
	return false
end

local spectatingTarget = nil
local specButtonsByPlayer = {}
local followTarget = nil
local followButtonsByPlayer = {}
local espEnabledByPlayer = {}
local espHighlights = {}

local function clearEspForPlayer(plr)
	local hl = espHighlights[plr]
	if hl then
		pcall(function() hl:Destroy() end)
		espHighlights[plr] = nil
	end
end

local function syncSpectateButtons()
	for plr, btn in pairs(specButtonsByPlayer) do
		if btn and btn.Parent then
			btn.Text = (spectatingTarget == plr) and "UNSPEC" or "SPEC"
		end
	end
end

local function syncFollowButtons()
	for plr, btn in pairs(followButtonsByPlayer) do
		if btn and btn.Parent then
			btn.Text = (followTarget == plr) and "UNFLW" or "FLW"
		end
	end
end

local function stopSpectate()
	spectatingTarget = nil
	syncSpectateButtons()
	local cam = workspace.CurrentCamera
	local hum = l.Character and l.Character:FindFirstChildOfClass("Humanoid")
	if cam then
		cam.CameraType = Enum.CameraType.Custom
		if hum then
			cam.CameraSubject = hum
		end
	end
end

local function panicStopAll()
	retryJoinActive = false
	if retryBtn then
		retryBtn.Text = "RETRY JOIN: OFF"
		retryBtn.BackgroundColor3 = Color3.fromRGB(48, 76, 112)
	end
	stopSpectate()
	followTarget = nil
	syncFollowButtons()
	for plr in pairs(espHighlights) do
		clearEspForPlayer(plr)
		espEnabledByPlayer[plr] = false
	end
	setFooter("PANIC STOP: All loops, spectate, follow & ESP cleared.", Color3.fromRGB(255, 130, 120))
	pushLog("GUARD", "Panic stop triggered")
end

bindTap(panicBtn, panicStopAll)

local function startSpectatePlayer(plr)
	local cam = workspace.CurrentCamera
	local hum = plr and plr.Character and plr.Character:FindFirstChildOfClass("Humanoid")
	if cam and hum and hum.Health > 0 then
		spectatingTarget = plr
		cam.CameraType = Enum.CameraType.Custom
		cam.CameraSubject = hum
		syncSpectateButtons()
		setFooter("Spectating " .. plr.Name, Color3.fromRGB(210, 185, 255))
		pushLog("SRCH", "Spectating @" .. plr.Name)
		return true
	end
	return false
end

local function cycleSpectate(dir)
	local list = p:GetPlayers()
	if #list == 0 then return end
	local idx = 1
	if spectatingTarget then
		for i, pl in ipairs(list) do
			if pl == spectatingTarget then
				idx = i
				break
			end
		end
		idx = ((idx - 1 + dir) % #list) + 1
	end
	for attempt = 0, #list - 1 do
		local cand = list[((idx - 1 + attempt) % #list) + 1]
		if startSpectatePlayer(cand) then
			return
		end
	end
	setFooter("No loaded character to spectate.", Color3.fromRGB(255, 165, 130))
end

local function cleanupAll()
	panicStopAll()
	for _, conn in ipairs(activeConnections) do
		pcall(function() conn:Disconnect() end)
	end
	table.clear(activeConnections)
	pcall(function() introBlur:Destroy() end)
	pcall(function() gui:Destroy() end)
end

if getgenv and type(getgenv) == "function" then
	getgenv().__VlexHubCleanup = cleanupAll
end

bindTap(closeBtn, cleanupAll)
bindTap(minBtn, function()
	card.Visible = false
	restoreBtn.Visible = true
end)
bindTap(restoreBtn, function()
	restoreBtn.Visible = false
	card.Visible = true
end)

local function applyTheme()
	local th = themes[themeIdx]
	stroke.Color = th.accent
	resStroke.Color = th.accent
	restoreBtn.TextColor3 = th.accent
	if cardStroke then cardStroke.Color = th.accent end
	titleLbl.Text = "SEARCH HUB [" .. th.name .. "]"
end

bindTap(themeBtn, function()
	if not isPackEnabled("UI") then return end
	themeIdx = (themeIdx % #themes) + 1
	applyTheme()
	setFooter("Theme: " .. themes[themeIdx].name, themes[themeIdx].accent)
end)

local function applyCardHeight()
	local h = tallCardMode and TALL_CARD_HEIGHT or BASE_CARD_HEIGHT
	card.Size = UDim2.fromOffset(CARD_WIDTH, h)
	if statusCard then
		statusCard.Size = UDim2.new(1, -12, 0, h - 242)
	end
	if footerLbl then
		footerLbl.Position = UDim2.fromOffset(6, h - 18)
	end
	optBtn.Text = tallCardMode and "COMP" or "TALL"
end

bindTap(optBtn, function()
	if not isPackEnabled("UI") then return end
	tallCardMode = not tallCardMode
	applyCardHeight()
	setFooter(tallCardMode and "Tall layout active." or "Compact layout active.", Color3.fromRGB(165, 215, 255))
end)

-- 10-Pack Toggle Bar (P1 - P10)
local packBar = Instance.new("ScrollingFrame")
packBar.Name = "PackBar"
packBar.Size = UDim2.new(1, -12, 0, 16)
packBar.Position = UDim2.fromOffset(6, 26)
packBar.BackgroundColor3 = Color3.fromRGB(18, 22, 32)
packBar.BorderSizePixel = 0
packBar.ScrollBarThickness = 1
packBar.ScrollingDirection = Enum.ScrollingDirection.X
packBar.AutomaticCanvasSize = Enum.AutomaticSize.X
packBar.CanvasSize = UDim2.new(0, 0, 0, 0)
packBar.ZIndex = 16
packBar.Parent = card
Instance.new("UICorner", packBar).CornerRadius = UDim.new(0, 4)

local packLayout = Instance.new("UIListLayout", packBar)
packLayout.FillDirection = Enum.FillDirection.Horizontal
packLayout.Padding = UDim.new(0, 3)
packLayout.VerticalAlignment = Enum.VerticalAlignment.Center

for _, pk in ipairs(PACK_CATALOG) do
	local pb = Instance.new("TextButton")
	pb.Size = UDim2.fromOffset(42, 13)
	pb.BackgroundColor3 = pk.enabled and Color3.fromRGB(36, 78, 118) or Color3.fromRGB(38, 30, 36)
	pb.Text = pk.id .. ":" .. pk.code
	pb.TextColor3 = pk.enabled and Color3.fromRGB(235, 248, 255) or Color3.fromRGB(160, 145, 155)
	pb.Font = Enum.Font.GothamBold
	pb.TextSize = 5.8
	pb.ZIndex = 17
	pb.Parent = packBar
	Instance.new("UICorner", pb).CornerRadius = UDim.new(0, 3)
	bindTap(pb, function()
		pk.enabled = not pk.enabled
		pb.BackgroundColor3 = pk.enabled and Color3.fromRGB(36, 78, 118) or Color3.fromRGB(38, 30, 36)
		pb.TextColor3 = pk.enabled and Color3.fromRGB(235, 248, 255) or Color3.fromRGB(160, 145, 155)
		setFooter(string.format("%s (%s) %s", pk.id, pk.range, pk.enabled and "ENABLED" or "DISABLED"), Color3.fromRGB(165, 215, 255))
	end)
end

-- Row 1: Username/ID/Batch + SEARCH + CLR RES
local inp = prepInput(Instance.new("TextBox"))
inp.Size = UDim2.fromOffset(176, 19)
inp.Position = UDim2.fromOffset(6, 45)
inp.BackgroundColor3 = Color3.fromRGB(23, 28, 38)
inp.PlaceholderText = "User, ID, or user1, user2..."
inp.PlaceholderColor3 = Color3.fromRGB(130, 148, 172)
inp.Text = ""
inp.TextColor3 = Color3.fromRGB(240, 248, 255)
inp.Font = Enum.Font.GothamSemibold
inp.TextSize = 7.4
inp.ZIndex = 16
inp.Parent = card
Instance.new("UICorner", inp).CornerRadius = UDim.new(0, 6)

local sBtn = Instance.new("TextButton")
sBtn.Size = UDim2.fromOffset(52, 19)
sBtn.Position = UDim2.fromOffset(186, 45)
sBtn.BackgroundColor3 = Color3.fromRGB(38, 96, 150)
sBtn.Text = "SEARCH"
sBtn.TextColor3 = Color3.fromRGB(245, 252, 255)
sBtn.Font = Enum.Font.GothamBold
sBtn.TextSize = 7.4
sBtn.ZIndex = 16
sBtn.Parent = card
Instance.new("UICorner", sBtn).CornerRadius = UDim.new(0, 6)

local clrResultsBtn = Instance.new("TextButton")
clrResultsBtn.Size = UDim2.fromOffset(42, 19)
clrResultsBtn.Position = UDim2.fromOffset(242, 45)
clrResultsBtn.BackgroundColor3 = Color3.fromRGB(66, 34, 42)
clrResultsBtn.Text = "CLR RES"
clrResultsBtn.TextColor3 = Color3.fromRGB(255, 215, 220)
clrResultsBtn.Font = Enum.Font.GothamBold
clrResultsBtn.TextSize = 6.6
clrResultsBtn.ZIndex = 16
clrResultsBtn.Parent = card
Instance.new("UICorner", clrResultsBtn).CornerRadius = UDim.new(0, 6)

-- Row 2: JobId Input + JOIN JOB + CLR
local jobInp = prepInput(Instance.new("TextBox"))
jobInp.Size = UDim2.fromOffset(176, 19)
jobInp.Position = UDim2.fromOffset(6, 67)
jobInp.BackgroundColor3 = Color3.fromRGB(23, 28, 38)
jobInp.PlaceholderText = "Paste JobId to join..."
jobInp.PlaceholderColor3 = Color3.fromRGB(130, 148, 172)
jobInp.Text = ""
jobInp.TextColor3 = Color3.fromRGB(220, 232, 248)
jobInp.Font = Enum.Font.GothamSemibold
jobInp.TextSize = 7.2
jobInp.ZIndex = 16
jobInp.Parent = card
Instance.new("UICorner", jobInp).CornerRadius = UDim.new(0, 6)

local joinJobBtn = Instance.new("TextButton")
joinJobBtn.Size = UDim2.fromOffset(66, 19)
joinJobBtn.Position = UDim2.fromOffset(186, 67)
joinJobBtn.BackgroundColor3 = Color3.fromRGB(45, 142, 92)
joinJobBtn.Text = "JOIN JOB"
joinJobBtn.TextColor3 = Color3.fromRGB(245, 255, 250)
joinJobBtn.Font = Enum.Font.GothamBold
joinJobBtn.TextSize = 7.2
joinJobBtn.ZIndex = 16
joinJobBtn.Parent = card
Instance.new("UICorner", joinJobBtn).CornerRadius = UDim.new(0, 5)

local clrBtn = Instance.new("TextButton")
clrBtn.Size = UDim2.fromOffset(28, 19)
clrBtn.Position = UDim2.fromOffset(256, 67)
clrBtn.BackgroundColor3 = Color3.fromRGB(36, 42, 54)
clrBtn.Text = "CLR"
clrBtn.TextColor3 = Color3.fromRGB(225, 235, 248)
clrBtn.Font = Enum.Font.GothamBold
clrBtn.TextSize = 7.0
clrBtn.ZIndex = 16
clrBtn.Parent = card
Instance.new("UICorner", clrBtn).CornerRadius = UDim.new(0, 5)

-- Row 3: PlaceId + JOBID + HOP + REJOIN
local placeInp = prepInput(Instance.new("TextBox"))
placeInp.Size = UDim2.fromOffset(112, 19)
placeInp.Position = UDim2.fromOffset(6, 89)
placeInp.BackgroundColor3 = Color3.fromRGB(23, 28, 38)
placeInp.PlaceholderText = "PlaceId (opt)"
placeInp.PlaceholderColor3 = Color3.fromRGB(130, 148, 172)
placeInp.Text = ""
placeInp.TextColor3 = Color3.fromRGB(220, 232, 248)
placeInp.Font = Enum.Font.GothamSemibold
placeInp.TextSize = 7.2
placeInp.ZIndex = 16
placeInp.Parent = card
Instance.new("UICorner", placeInp).CornerRadius = UDim.new(0, 6)

local cpBtn = Instance.new("TextButton")
cpBtn.Size = UDim2.fromOffset(46, 19)
cpBtn.Position = UDim2.fromOffset(122, 89)
cpBtn.BackgroundColor3 = Color3.fromRGB(34, 88, 68)
cpBtn.Text = "JOBID"
cpBtn.TextColor3 = Color3.fromRGB(235, 252, 242)
cpBtn.Font = Enum.Font.GothamBold
cpBtn.TextSize = 7.0
cpBtn.ZIndex = 16
cpBtn.Parent = card
Instance.new("UICorner", cpBtn).CornerRadius = UDim.new(0, 5)

local hopBtn = Instance.new("TextButton")
hopBtn.Size = UDim2.fromOffset(44, 19)
hopBtn.Position = UDim2.fromOffset(172, 89)
hopBtn.BackgroundColor3 = Color3.fromRGB(82, 56, 128)
hopBtn.Text = "HOP"
hopBtn.TextColor3 = Color3.fromRGB(245, 238, 255)
hopBtn.Font = Enum.Font.GothamBold
hopBtn.TextSize = 7.0
hopBtn.ZIndex = 16
hopBtn.Parent = card
Instance.new("UICorner", hopBtn).CornerRadius = UDim.new(0, 5)

local rejoinBtn = Instance.new("TextButton")
rejoinBtn.Size = UDim2.fromOffset(64, 19)
rejoinBtn.Position = UDim2.fromOffset(220, 89)
rejoinBtn.BackgroundColor3 = Color3.fromRGB(54, 44, 112)
rejoinBtn.Text = "REJOIN"
rejoinBtn.TextColor3 = Color3.fromRGB(238, 235, 255)
rejoinBtn.Font = Enum.Font.GothamBold
rejoinBtn.TextSize = 7.0
rejoinBtn.ZIndex = 16
rejoinBtn.Parent = card
Instance.new("UICorner", rejoinBtn).CornerRadius = UDim.new(0, 5)

-- Row 3B: Auto-Retry + Random Server + Copy Mode
retryBtn = Instance.new("TextButton")
retryBtn.Size = UDim2.fromOffset(94, 18)
retryBtn.Position = UDim2.fromOffset(6, 111)
retryBtn.BackgroundColor3 = Color3.fromRGB(48, 76, 112)
retryBtn.Text = "RETRY JOIN: OFF"
retryBtn.TextColor3 = Color3.fromRGB(235, 245, 255)
retryBtn.Font = Enum.Font.GothamBold
retryBtn.TextSize = 6.6
retryBtn.ZIndex = 16
retryBtn.Parent = card
Instance.new("UICorner", retryBtn).CornerRadius = UDim.new(0, 4)

local randSrvBtn = Instance.new("TextButton")
randSrvBtn.Size = UDim2.fromOffset(86, 18)
randSrvBtn.Position = UDim2.fromOffset(104, 111)
randSrvBtn.BackgroundColor3 = Color3.fromRGB(68, 46, 118)
randSrvBtn.Text = "RAND SERVER"
randSrvBtn.TextColor3 = Color3.fromRGB(240, 236, 255)
randSrvBtn.Font = Enum.Font.GothamBold
randSrvBtn.TextSize = 6.6
randSrvBtn.ZIndex = 16
randSrvBtn.Parent = card
Instance.new("UICorner", randSrvBtn).CornerRadius = UDim.new(0, 4)

local fmtBtn = Instance.new("TextButton")
fmtBtn.Size = UDim2.fromOffset(90, 18)
fmtBtn.Position = UDim2.fromOffset(194, 111)
fmtBtn.BackgroundColor3 = Color3.fromRGB(36, 62, 78)
fmtBtn.Text = "FMT: MULTI"
fmtBtn.TextColor3 = Color3.fromRGB(220, 245, 255)
fmtBtn.Font = Enum.Font.GothamBold
fmtBtn.TextSize = 6.6
fmtBtn.ZIndex = 16
fmtBtn.Parent = card
Instance.new("UICorner", fmtBtn).CornerRadius = UDim.new(0, 4)

-- Row 4: History Strip + EXP / CLR
local histScroll = Instance.new("ScrollingFrame")
histScroll.Name = "HistoryStrip"
histScroll.Size = UDim2.new(1, -94, 0, 18)
histScroll.Position = UDim2.fromOffset(6, 132)
histScroll.BackgroundColor3 = Color3.fromRGB(19, 23, 33)
histScroll.BorderSizePixel = 0
histScroll.ScrollBarThickness = 1
histScroll.ScrollingDirection = Enum.ScrollingDirection.X
histScroll.AutomaticCanvasSize = Enum.AutomaticSize.X
histScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
histScroll.ZIndex = 16
histScroll.Parent = card
Instance.new("UICorner", histScroll).CornerRadius = UDim.new(0, 5)

local histLayout = Instance.new("UIListLayout", histScroll)
histLayout.FillDirection = Enum.FillDirection.Horizontal
histLayout.Padding = UDim.new(0, 4)
histLayout.VerticalAlignment = Enum.VerticalAlignment.Center

local expHistBtn = Instance.new("TextButton")
expHistBtn.Size = UDim2.fromOffset(40, 18)
expHistBtn.Position = UDim2.new(1, -84, 0, 132)
expHistBtn.BackgroundColor3 = Color3.fromRGB(32, 56, 76)
expHistBtn.Text = "EXP H"
expHistBtn.TextColor3 = Color3.fromRGB(220, 240, 255)
expHistBtn.Font = Enum.Font.GothamBold
expHistBtn.TextSize = 6.6
expHistBtn.ZIndex = 16
expHistBtn.Parent = card
Instance.new("UICorner", expHistBtn).CornerRadius = UDim.new(0, 4)

local clrHistBtn = Instance.new("TextButton")
clrHistBtn.Size = UDim2.fromOffset(38, 18)
clrHistBtn.Position = UDim2.new(1, -42, 0, 132)
clrHistBtn.BackgroundColor3 = Color3.fromRGB(64, 34, 42)
clrHistBtn.Text = "CLR H"
clrHistBtn.TextColor3 = Color3.fromRGB(255, 215, 220)
clrHistBtn.Font = Enum.Font.GothamBold
clrHistBtn.TextSize = 6.6
clrHistBtn.ZIndex = 16
clrHistBtn.Parent = card
Instance.new("UICorner", clrHistBtn).CornerRadius = UDim.new(0, 4)

local historyEntries = {}
local visitedServers = {}
if game.JobId ~= "" then visitedServers[game.JobId] = true end

local function pushHistory(kind, value)
	if not isPackEnabled("LISTS") then return end
	local clean = trimStr(value)
	if clean == "" then return end
	for i = #historyEntries, 1, -1 do
		if historyEntries[i].value == clean then
			table.remove(historyEntries, i)
		end
	end
	table.insert(historyEntries, 1, { kind = kind, value = clean })
	if #historyEntries > 25 then
		table.remove(historyEntries)
	end

	for _, child in ipairs(histScroll:GetChildren()) do
		if child:IsA("TextButton") then
			child:Destroy()
		end
	end

	for _, item in ipairs(historyEntries) do
		local chip = Instance.new("TextButton")
		chip.Size = UDim2.fromOffset(76, 14)
		chip.BackgroundColor3 = item.kind == "JOB" and Color3.fromRGB(42, 34, 86) or Color3.fromRGB(30, 44, 66)
		chip.Text = (item.kind == "JOB" and "J: " or "@") .. item.value
		chip.TextColor3 = Color3.fromRGB(225, 238, 255)
		chip.TextTruncate = Enum.TextTruncate.AtEnd
		chip.Font = Enum.Font.GothamBold
		chip.TextSize = 6.6
		chip.ZIndex = 17
		chip.Parent = histScroll
		Instance.new("UICorner", chip).CornerRadius = UDim.new(0, 4)
		bindTap(chip, function()
			if item.kind == "JOB" then
				jobInp.Text = item.value
			else
				inp.Text = item.value
			end
			setFooter("Loaded history item: " .. item.value, Color3.fromRGB(165, 215, 255))
		end)
	end
end

bindTap(clrHistBtn, function()
	table.clear(historyEntries)
	for _, child in ipairs(histScroll:GetChildren()) do
		if child:IsA("TextButton") then child:Destroy() end
	end
	setFooter("Cleared search/JobId history.", Color3.fromRGB(165, 210, 255))
end)

bindTap(expHistBtn, function()
	if #historyEntries == 0 then
		setFooter("History is empty.", Color3.fromRGB(255, 165, 130))
		return
	end
	local lines = {}
	for _, it in ipairs(historyEntries) do
		table.insert(lines, (it.kind == "JOB" and "JobId: " or "User: ") .. it.value)
	end
	copyWithFallback(table.concat(lines, "\n"), "history")
	setFooter("Copied " .. tostring(#historyEntries) .. " history items.", Color3.fromRGB(135, 245, 185))
end)

-- Live Server Snapshot Card
local srvCard = Instance.new("Frame")
srvCard.Name = "ServerCard"
srvCard.Size = UDim2.new(1, -12, 0, 62)
srvCard.Position = UDim2.fromOffset(6, 154)
srvCard.BackgroundColor3 = Color3.fromRGB(48, 24, 126)
srvCard.BorderSizePixel = 0
srvCard.ZIndex = 16
srvCard.Parent = card
Instance.new("UICorner", srvCard).CornerRadius = UDim.new(0, 7)

local srvCapLbl = Instance.new("TextLabel")
srvCapLbl.Size = UDim2.new(1, -68, 0, 13)
srvCapLbl.Position = UDim2.fromOffset(5, 2)
srvCapLbl.BackgroundTransparency = 1
srvCapLbl.Text = "Live Server Sync"
srvCapLbl.TextColor3 = Color3.fromRGB(248, 246, 255)
srvCapLbl.TextXAlignment = Enum.TextXAlignment.Left
srvCapLbl.Font = Enum.Font.GothamBold
srvCapLbl.TextSize = 7.4
srvCapLbl.ZIndex = 17
srvCapLbl.Parent = srvCard

local copySrvInfoBtn = Instance.new("TextButton")
copySrvInfoBtn.Size = UDim2.fromOffset(56, 12)
copySrvInfoBtn.Position = UDim2.new(1, -61, 0, 2)
copySrvInfoBtn.BackgroundColor3 = Color3.fromRGB(25, 12, 70)
copySrvInfoBtn.Text = "CPY SRV"
copySrvInfoBtn.TextColor3 = Color3.fromRGB(235, 232, 255)
copySrvInfoBtn.Font = Enum.Font.GothamBold
copySrvInfoBtn.TextSize = 6.4
copySrvInfoBtn.ZIndex = 18
copySrvInfoBtn.Parent = srvCard
Instance.new("UICorner", copySrvInfoBtn).CornerRadius = UDim.new(0, 3)

local capTrack = Instance.new("Frame")
capTrack.Size = UDim2.new(1, -10, 0, 4)
capTrack.Position = UDim2.fromOffset(5, 16)
capTrack.BackgroundColor3 = Color3.fromRGB(25, 12, 70)
capTrack.BorderSizePixel = 0
capTrack.ZIndex = 17
capTrack.Parent = srvCard
Instance.new("UICorner", capTrack).CornerRadius = UDim.new(1, 0)

local capFill = Instance.new("Frame")
capFill.Size = UDim2.new(0.1, 0, 1, 0)
capFill.BackgroundColor3 = Color3.fromRGB(225, 222, 255)
capFill.BorderSizePixel = 0
capFill.ZIndex = 18
capFill.Parent = capTrack
Instance.new("UICorner", capFill).CornerRadius = UDim.new(1, 0)

local srvStatsLbl = Instance.new("TextLabel")
srvStatsLbl.Size = UDim2.new(1, -10, 0, 26)
srvStatsLbl.Position = UDim2.fromOffset(5, 21)
srvStatsLbl.BackgroundTransparency = 1
srvStatsLbl.Text = "Ping: -- ms  |  FPS: --  |  Mem: -- MB"
srvStatsLbl.TextColor3 = Color3.fromRGB(238, 236, 255)
srvStatsLbl.TextXAlignment = Enum.TextXAlignment.Left
srvStatsLbl.TextYAlignment = Enum.TextYAlignment.Top
srvStatsLbl.TextWrapped = true
srvStatsLbl.Font = Enum.Font.GothamSemibold
srvStatsLbl.TextSize = 6.6
srvStatsLbl.ZIndex = 17
srvStatsLbl.Parent = srvCard

local srvIdLbl = Instance.new("TextLabel")
srvIdLbl.Size = UDim2.new(1, -10, 0, 11)
srvIdLbl.Position = UDim2.fromOffset(5, 49)
srvIdLbl.BackgroundTransparency = 1
srvIdLbl.Text = "ID: " .. (game.JobId ~= "" and game.JobId or "Studio / Local")
srvIdLbl.TextColor3 = Color3.fromRGB(210, 205, 255)
srvIdLbl.TextXAlignment = Enum.TextXAlignment.Left
srvIdLbl.TextTruncate = Enum.TextTruncate.AtEnd
srvIdLbl.Font = Enum.Font.Code
srvIdLbl.TextSize = 6.6
srvIdLbl.ZIndex = 17
srvIdLbl.Parent = srvCard

-- 4 Mode Tabs: RESULTS | PLAYERS | SERVERS | LOG
local modeBar = Instance.new("Frame")
modeBar.Size = UDim2.new(1, -12, 0, 18)
modeBar.Position = UDim2.fromOffset(6, 220)
modeBar.BackgroundTransparency = 1
modeBar.ZIndex = 16
modeBar.Parent = card

local function makeTabBtn(txt, w, xOff)
	local b = Instance.new("TextButton")
	b.Size = UDim2.fromOffset(w, 18)
	b.Position = UDim2.fromOffset(xOff, 0)
	b.BackgroundColor3 = Color3.fromRGB(28, 34, 46)
	b.Text = txt
	b.TextColor3 = Color3.fromRGB(185, 200, 224)
	b.Font = Enum.Font.GothamBold
	b.TextSize = 6.9
	b.ZIndex = 17
	b.Parent = modeBar
	Instance.new("UICorner", b).CornerRadius = UDim.new(0, 5)
	return b
end

local tabResultsBtn = makeTabBtn("RESULTS", 74, 0)
local tabPlayersBtn = makeTabBtn("PLAYERS", 74, 77)
local tabServersBtn = makeTabBtn("SERVERS", 74, 154)
local tabLogBtn     = makeTabBtn("LOG", 47, 231)

statusCard = Instance.new("Frame")
statusCard.Name = "StatusCard"
statusCard.Size = UDim2.new(1, -12, 0, BASE_CARD_HEIGHT - 260)
statusCard.Position = UDim2.fromOffset(6, 241)
statusCard.BackgroundColor3 = Color3.fromRGB(21, 26, 36)
statusCard.BorderSizePixel = 0
statusCard.ZIndex = 16
statusCard.Parent = card
Instance.new("UICorner", statusCard).CornerRadius = UDim.new(0, 7)

cardStroke = Instance.new("UIStroke")
cardStroke.Color = themes[1].accent
cardStroke.Thickness = 1
cardStroke.Parent = statusCard

local f = Instance.new("ScrollingFrame")
f.Size = UDim2.new(1, -8, 1, -8)
f.Position = UDim2.fromOffset(4, 4)
f.BackgroundTransparency = 1
f.BorderSizePixel = 0
f.ScrollBarThickness = 2
f.AutomaticCanvasSize = Enum.AutomaticSize.Y
f.CanvasSize = UDim2.new(0, 0, 0, 0)
f.ZIndex = 17
f.Parent = statusCard

local ly = Instance.new("UIListLayout", f)
ly.SortOrder = Enum.SortOrder.LayoutOrder
ly.Padding = UDim.new(0, 6)

local emptyResultsLbl = Instance.new("TextLabel")
emptyResultsLbl.Size = UDim2.new(1, 0, 0, 24)
emptyResultsLbl.BackgroundTransparency = 1
emptyResultsLbl.Text = "1.1K Hub ready. Search a username or UserId above."
emptyResultsLbl.TextColor3 = Color3.fromRGB(145, 165, 190)
emptyResultsLbl.TextWrapped = true
emptyResultsLbl.Font = Enum.Font.GothamSemibold
emptyResultsLbl.TextSize = 7.0
emptyResultsLbl.ZIndex = 18
emptyResultsLbl.Parent = f

local function updateEmptyResultsPrompt()
	local hasCard = false
	for _, ch in ipairs(f:GetChildren()) do
		if ch:IsA("Frame") then
			hasCard = true
			break
		end
	end
	emptyResultsLbl.Visible = not hasCard
end

-- PLAYERS tab
local playersContainer = Instance.new("Frame")
playersContainer.Size = UDim2.new(1, -8, 1, -8)
playersContainer.Position = UDim2.fromOffset(4, 4)
playersContainer.BackgroundTransparency = 1
playersContainer.Visible = false
playersContainer.ZIndex = 17
playersContainer.Parent = statusCard

local playerFilterInp = prepInput(Instance.new("TextBox"))
playerFilterInp.Size = UDim2.new(1, -138, 0, 16)
playerFilterInp.Position = UDim2.fromOffset(0, 0)
playerFilterInp.BackgroundColor3 = Color3.fromRGB(15, 19, 28)
playerFilterInp.PlaceholderText = "Filter players..."
playerFilterInp.PlaceholderColor3 = Color3.fromRGB(130, 148, 172)
playerFilterInp.Text = ""
playerFilterInp.TextColor3 = Color3.fromRGB(235, 245, 255)
playerFilterInp.Font = Enum.Font.GothamSemibold
playerFilterInp.TextSize = 6.8
playerFilterInp.ZIndex = 18
playerFilterInp.Parent = playersContainer
Instance.new("UICorner", playerFilterInp).CornerRadius = UDim.new(0, 4)

local clrFilterBtn = Instance.new("TextButton")
clrFilterBtn.Size = UDim2.fromOffset(16, 16)
clrFilterBtn.Position = UDim2.new(1, -135, 0, 0)
clrFilterBtn.BackgroundColor3 = Color3.fromRGB(48, 32, 38)
clrFilterBtn.Text = "X"
clrFilterBtn.TextColor3 = Color3.fromRGB(255, 180, 180)
clrFilterBtn.Font = Enum.Font.GothamBold
clrFilterBtn.TextSize = 6.6
clrFilterBtn.ZIndex = 18
clrFilterBtn.Parent = playersContainer
Instance.new("UICorner", clrFilterBtn).CornerRadius = UDim.new(0, 4)

local sortPlayersAZ = false
local sortPlayersBtn = Instance.new("TextButton")
sortPlayersBtn.Size = UDim2.fromOffset(34, 16)
sortPlayersBtn.Position = UDim2.new(1, -116, 0, 0)
sortPlayersBtn.BackgroundColor3 = Color3.fromRGB(38, 52, 76)
sortPlayersBtn.Text = "A-Z"
sortPlayersBtn.TextColor3 = Color3.fromRGB(220, 236, 255)
sortPlayersBtn.Font = Enum.Font.GothamBold
sortPlayersBtn.TextSize = 6.4
sortPlayersBtn.ZIndex = 18
sortPlayersBtn.Parent = playersContainer
Instance.new("UICorner", sortPlayersBtn).CornerRadius = UDim.new(0, 4)

local prevSpecBtn = Instance.new("TextButton")
prevSpecBtn.Size = UDim2.fromOffset(22, 16)
prevSpecBtn.Position = UDim2.new(1, -79, 0, 0)
prevSpecBtn.BackgroundColor3 = Color3.fromRGB(64, 46, 108)
prevSpecBtn.Text = "<"
prevSpecBtn.TextColor3 = Color3.fromRGB(240, 236, 255)
prevSpecBtn.Font = Enum.Font.GothamBold
prevSpecBtn.TextSize = 7.2
prevSpecBtn.ZIndex = 18
prevSpecBtn.Parent = playersContainer
Instance.new("UICorner", prevSpecBtn).CornerRadius = UDim.new(0, 4)

local nextSpecBtn = Instance.new("TextButton")
nextSpecBtn.Size = UDim2.fromOffset(22, 16)
nextSpecBtn.Position = UDim2.new(1, -54, 0, 0)
nextSpecBtn.BackgroundColor3 = Color3.fromRGB(64, 46, 108)
nextSpecBtn.Text = ">"
nextSpecBtn.TextColor3 = Color3.fromRGB(240, 236, 255)
nextSpecBtn.Font = Enum.Font.GothamBold
nextSpecBtn.TextSize = 7.2
nextSpecBtn.ZIndex = 18
nextSpecBtn.Parent = playersContainer
Instance.new("UICorner", nextSpecBtn).CornerRadius = UDim.new(0, 4)

local stopSpecBtn = Instance.new("TextButton")
stopSpecBtn.Size = UDim2.fromOffset(29, 16)
stopSpecBtn.Position = UDim2.new(1, -29, 0, 0)
stopSpecBtn.BackgroundColor3 = Color3.fromRGB(92, 42, 52)
stopSpecBtn.Text = "OFF"
stopSpecBtn.TextColor3 = Color3.fromRGB(255, 235, 238)
stopSpecBtn.Font = Enum.Font.GothamBold
stopSpecBtn.TextSize = 6.4
stopSpecBtn.ZIndex = 18
stopSpecBtn.Parent = playersContainer
Instance.new("UICorner", stopSpecBtn).CornerRadius = UDim.new(0, 4)

local plyMetaBar = Instance.new("Frame")
plyMetaBar.Size = UDim2.new(1, 0, 0, 15)
plyMetaBar.Position = UDim2.fromOffset(0, 18)
plyMetaBar.BackgroundTransparency = 1
plyMetaBar.ZIndex = 18
plyMetaBar.Parent = playersContainer

local plyCountLbl = Instance.new("TextLabel")
plyCountLbl.Size = UDim2.new(1, -112, 1, 0)
plyCountLbl.BackgroundTransparency = 1
plyCountLbl.Text = "Players: 0/0"
plyCountLbl.TextColor3 = Color3.fromRGB(175, 198, 226)
plyCountLbl.TextXAlignment = Enum.TextXAlignment.Left
plyCountLbl.Font = Enum.Font.GothamBold
plyCountLbl.TextSize = 6.6
plyCountLbl.ZIndex = 19
plyCountLbl.Parent = plyMetaBar

local copyNamesBtn = Instance.new("TextButton")
copyNamesBtn.Size = UDim2.fromOffset(54, 14)
copyNamesBtn.Position = UDim2.new(1, -108, 0, 0)
copyNamesBtn.BackgroundColor3 = Color3.fromRGB(34, 76, 68)
copyNamesBtn.Text = "CPY NAMES"
copyNamesBtn.TextColor3 = Color3.fromRGB(230, 255, 245)
copyNamesBtn.Font = Enum.Font.GothamBold
copyNamesBtn.TextSize = 6.0
copyNamesBtn.ZIndex = 19
copyNamesBtn.Parent = plyMetaBar
Instance.new("UICorner", copyNamesBtn).CornerRadius = UDim.new(0, 3)

local copyIdsBtn = Instance.new("TextButton")
copyIdsBtn.Size = UDim2.fromOffset(50, 14)
copyIdsBtn.Position = UDim2.new(1, -50, 0, 0)
copyIdsBtn.BackgroundColor3 = Color3.fromRGB(38, 66, 98)
copyIdsBtn.Text = "CPY IDS"
copyIdsBtn.TextColor3 = Color3.fromRGB(230, 244, 255)
copyIdsBtn.Font = Enum.Font.GothamBold
copyIdsBtn.TextSize = 6.0
copyIdsBtn.ZIndex = 19
copyIdsBtn.Parent = plyMetaBar
Instance.new("UICorner", copyIdsBtn).CornerRadius = UDim.new(0, 3)

local playersFrame = Instance.new("ScrollingFrame")
playersFrame.Size = UDim2.new(1, 0, 1, -36)
playersFrame.Position = UDim2.fromOffset(0, 36)
playersFrame.BackgroundTransparency = 1
playersFrame.BorderSizePixel = 0
playersFrame.ScrollBarThickness = 2
playersFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
playersFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
playersFrame.ZIndex = 18
playersFrame.Parent = playersContainer

local plyLayout = Instance.new("UIListLayout", playersFrame)
plyLayout.SortOrder = Enum.SortOrder.LayoutOrder
plyLayout.Padding = UDim.new(0, 4)

-- SERVERS tab
local serversContainer = Instance.new("Frame")
serversContainer.Size = UDim2.new(1, -8, 1, -8)
serversContainer.Position = UDim2.fromOffset(4, 4)
serversContainer.BackgroundTransparency = 1
serversContainer.Visible = false
serversContainer.ZIndex = 17
serversContainer.Parent = statusCard

local serverSortModes = { "DESC", "OPEN", "ASC", "LOW PING", "SNIPER", "EMPTY" }
local serverSortIdx = 1
local nextServerCursor = nil

local sortServersBtn = Instance.new("TextButton")
sortServersBtn.Size = UDim2.fromOffset(78, 16)
sortServersBtn.Position = UDim2.fromOffset(0, 0)
sortServersBtn.BackgroundColor3 = Color3.fromRGB(48, 36, 98)
sortServersBtn.Text = "SORT: DESC"
sortServersBtn.TextColor3 = Color3.fromRGB(238, 235, 255)
sortServersBtn.Font = Enum.Font.GothamBold
sortServersBtn.TextSize = 6.2
sortServersBtn.ZIndex = 18
sortServersBtn.Parent = serversContainer
Instance.new("UICorner", sortServersBtn).CornerRadius = UDim.new(0, 4)

local maxPingInp = prepInput(Instance.new("TextBox"))
maxPingInp.Size = UDim2.fromOffset(48, 16)
maxPingInp.Position = UDim2.fromOffset(81, 0)
maxPingInp.BackgroundColor3 = Color3.fromRGB(15, 19, 28)
maxPingInp.PlaceholderText = "MaxPing"
maxPingInp.PlaceholderColor3 = Color3.fromRGB(125, 145, 170)
maxPingInp.Text = ""
maxPingInp.TextColor3 = Color3.fromRGB(230, 242, 255)
maxPingInp.Font = Enum.Font.GothamSemibold
maxPingInp.TextSize = 6.4
maxPingInp.ZIndex = 18
maxPingInp.Parent = serversContainer
Instance.new("UICorner", maxPingInp).CornerRadius = UDim.new(0, 4)

local refreshServersBtn = Instance.new("TextButton")
refreshServersBtn.Size = UDim2.fromOffset(54, 16)
refreshServersBtn.Position = UDim2.fromOffset(132, 0)
refreshServersBtn.BackgroundColor3 = Color3.fromRGB(34, 88, 68)
refreshServersBtn.Text = "REFRESH"
refreshServersBtn.TextColor3 = Color3.fromRGB(240, 255, 248)
refreshServersBtn.Font = Enum.Font.GothamBold
refreshServersBtn.TextSize = 6.2
refreshServersBtn.ZIndex = 18
refreshServersBtn.Parent = serversContainer
Instance.new("UICorner", refreshServersBtn).CornerRadius = UDim.new(0, 4)

local nextPageSrvBtn = Instance.new("TextButton")
nextPageSrvBtn.Size = UDim2.fromOffset(76, 16)
nextPageSrvBtn.Position = UDim2.fromOffset(189, 0)
nextPageSrvBtn.BackgroundColor3 = Color3.fromRGB(38, 64, 92)
nextPageSrvBtn.Text = "MORE SRVS"
nextPageSrvBtn.TextColor3 = Color3.fromRGB(225, 240, 255)
nextPageSrvBtn.Font = Enum.Font.GothamBold
nextPageSrvBtn.TextSize = 6.2
nextPageSrvBtn.ZIndex = 18
nextPageSrvBtn.Parent = serversContainer
Instance.new("UICorner", nextPageSrvBtn).CornerRadius = UDim.new(0, 4)

local serversFrame = Instance.new("ScrollingFrame")
serversFrame.Size = UDim2.new(1, 0, 1, -20)
serversFrame.Position = UDim2.fromOffset(0, 20)
serversFrame.BackgroundTransparency = 1
serversFrame.BorderSizePixel = 0
serversFrame.ScrollBarThickness = 2
serversFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
serversFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
serversFrame.ZIndex = 18
serversFrame.Parent = serversContainer

local srvLayout = Instance.new("UIListLayout", serversFrame)
srvLayout.SortOrder = Enum.SortOrder.LayoutOrder
srvLayout.Padding = UDim.new(0, 4)

-- LOG tab with tag filter
local logContainer = Instance.new("Frame")
logContainer.Size = UDim2.new(1, -8, 1, -8)
logContainer.Position = UDim2.fromOffset(4, 4)
logContainer.BackgroundTransparency = 1
logContainer.Visible = false
logContainer.ZIndex = 17
logContainer.Parent = statusCard

local logFilterBtn = Instance.new("TextButton")
logFilterBtn.Size = UDim2.fromOffset(68, 16)
logFilterBtn.Position = UDim2.fromOffset(0, 0)
logFilterBtn.BackgroundColor3 = Color3.fromRGB(48, 36, 98)
logFilterBtn.Text = "FLT: ALL"
logFilterBtn.TextColor3 = Color3.fromRGB(238, 235, 255)
logFilterBtn.Font = Enum.Font.GothamBold
logFilterBtn.TextSize = 6.2
logFilterBtn.ZIndex = 18
logFilterBtn.Parent = logContainer
Instance.new("UICorner", logFilterBtn).CornerRadius = UDim.new(0, 4)

local copyLogBtn = Instance.new("TextButton")
copyLogBtn.Size = UDim2.fromOffset(62, 16)
copyLogBtn.Position = UDim2.fromOffset(72, 0)
copyLogBtn.BackgroundColor3 = Color3.fromRGB(34, 88, 68)
copyLogBtn.Text = "COPY LOG"
copyLogBtn.TextColor3 = Color3.fromRGB(235, 255, 245)
copyLogBtn.Font = Enum.Font.GothamBold
copyLogBtn.TextSize = 6.2
copyLogBtn.ZIndex = 18
copyLogBtn.Parent = logContainer
Instance.new("UICorner", copyLogBtn).CornerRadius = UDim.new(0, 4)

local clrLogBtn = Instance.new("TextButton")
clrLogBtn.Size = UDim2.fromOffset(62, 16)
clrLogBtn.Position = UDim2.fromOffset(138, 0)
clrLogBtn.BackgroundColor3 = Color3.fromRGB(78, 36, 44)
clrLogBtn.Text = "CLEAR LOG"
clrLogBtn.TextColor3 = Color3.fromRGB(255, 220, 225)
clrLogBtn.Font = Enum.Font.GothamBold
clrLogBtn.TextSize = 6.2
clrLogBtn.ZIndex = 18
clrLogBtn.Parent = logContainer
Instance.new("UICorner", clrLogBtn).CornerRadius = UDim.new(0, 4)

local logFrame = Instance.new("ScrollingFrame")
logFrame.Size = UDim2.new(1, 0, 1, -20)
logFrame.Position = UDim2.fromOffset(0, 20)
logFrame.BackgroundTransparency = 1
logFrame.BorderSizePixel = 0
logFrame.ScrollBarThickness = 2
logFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
logFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
logFrame.ZIndex = 18
logFrame.Parent = logContainer

local logLayout = Instance.new("UIListLayout", logFrame)
logLayout.SortOrder = Enum.SortOrder.LayoutOrder
logLayout.Padding = UDim.new(0, 3)

local logFilterModes = { "ALL", "SRCH", "TP", "COPY", "ERR" }
local logFilterIdx = 1

refreshLogTab = function()
	for _, ch in ipairs(logFrame:GetChildren()) do
		if ch:IsA("TextLabel") then ch:Destroy() end
	end
	for _, item in ipairs(logEntries) do
		if logFilterMode == "ALL" or item.tag == logFilterMode then
			local lbl = Instance.new("TextLabel")
			lbl.Size = UDim2.new(1, 0, 0, 14)
			lbl.BackgroundTransparency = 1
			lbl.Text = item.line
			lbl.TextColor3 = (item.tag == "ERR") and Color3.fromRGB(255, 155, 145) or Color3.fromRGB(205, 220, 240)
			lbl.TextXAlignment = Enum.TextXAlignment.Left
			lbl.TextTruncate = Enum.TextTruncate.AtEnd
			lbl.Font = Enum.Font.Code
			lbl.TextSize = 6.4
			lbl.ZIndex = 19
			lbl.Parent = logFrame
		end
	end
end

bindTap(logFilterBtn, function()
	logFilterIdx = (logFilterIdx % #logFilterModes) + 1
	logFilterMode = logFilterModes[logFilterIdx]
	logFilterBtn.Text = "FLT: " .. logFilterMode
	refreshLogTab()
end)

bindTap(copyLogBtn, function()
	if #logEntries == 0 then
		setFooter("Log is empty.", Color3.fromRGB(255, 165, 130))
		return
	end
	local lines = {}
	for _, item in ipairs(logEntries) do
		if logFilterMode == "ALL" or item.tag == logFilterMode then
			table.insert(lines, item.line)
		end
	end
	copyWithFallback(table.concat(lines, "\n"), "session log")
	setFooter("Copied " .. tostring(#lines) .. " log lines.", Color3.fromRGB(135, 245, 185))
end)

bindTap(clrLogBtn, function()
	table.clear(logEntries)
	refreshLogTab()
	setFooter("Cleared session log.", Color3.fromRGB(165, 210, 255))
end)

footerLbl = Instance.new("TextLabel")
footerLbl.Size = UDim2.new(1, -12, 0, 16)
footerLbl.Position = UDim2.fromOffset(6, BASE_CARD_HEIGHT - 18)
footerLbl.BackgroundTransparency = 1
footerLbl.Text = "1.1K Modular Hub ready. Tap footer to cycle status."
footerLbl.TextColor3 = Color3.fromRGB(155, 175, 200)
footerLbl.TextXAlignment = Enum.TextXAlignment.Left
footerLbl.TextTruncate = Enum.TextTruncate.AtEnd
footerLbl.Font = Enum.Font.GothamSemibold
footerLbl.TextSize = 6.9
footerLbl.Active = true
footerLbl.ZIndex = 16
footerLbl.Parent = card

bindTap(footerLbl, function()
	if #statusHistory > 1 then
		statusHistoryIdx = (statusHistoryIdx % #statusHistory) + 1
		local item = statusHistory[statusHistoryIdx]
		footerLbl.Text = item.text
		footerLbl.TextColor3 = item.color
	end
end)

local function formatTeleportErr(err)
	local s = tostring(err or "Unknown")
	if string.find(string.lower(s), "unauthorized") or string.find(string.lower(s), "restricted") then
		return "Restricted/Private server or invalid PlaceId (" .. s .. ")"
	elseif string.find(string.lower(s), "full") then
		return "Target server is full (" .. s .. ")"
	end
	return s
end

local lastHopTime = 0
local function executeTeleport(targetPlaceId, targetJobId, statusBtn)
	local placeNum = tonumber(targetPlaceId)
	local cleanJob = sanitizeJobId(targetJobId)
	local hasJob = cleanJob ~= "" and cleanJob ~= "Hidden/N/A" and cleanJob ~= "N/A" and isLikelyValidJobId(cleanJob)

	if (not placeNum or placeNum <= 0) and hasJob then
		placeNum = game.PlaceId
	end

	if not placeNum or placeNum <= 0 then
		setFooter("Join blocked: No PlaceId or valid JobId available.", Color3.fromRGB(255, 165, 130))
		flashStatusCard(Color3.fromRGB(255, 110, 95))
		return
	end

	if hasJob and isPackEnabled("HOP") then
		visitedServers[cleanJob] = true
		pushHistory("JOB", cleanJob)
	end

	local origText = statusBtn and statusBtn.Text or "JOIN"
	if statusBtn then statusBtn.Text = "..." end
	setFooter(hasJob and ("Joining JobId: " .. cleanJob .. "...") or ("Teleporting to PlaceId: " .. tostring(placeNum) .. "..."), Color3.fromRGB(135, 245, 185))
	pushLog("TP", (hasJob and ("JobId " .. cleanJob) or ("Place " .. tostring(placeNum))))

	local tpOk, tpErr = pcall(function()
		if hasJob then
			ts:TeleportToPlaceInstance(placeNum, cleanJob, l)
		else
			ts:Teleport(placeNum, l)
		end
	end)

	if not tpOk then
		local friendly = formatTeleportErr(tpErr)
		setFooter("Join failed: " .. friendly, Color3.fromRGB(255, 140, 125))
		flashStatusCard(Color3.fromRGB(255, 85, 85))
		pushLog("ERR", friendly)
		if statusBtn and statusBtn.Parent then
			statusBtn.Text = "FAIL"
		end
	else
		flashStatusCard(Color3.fromRGB(95, 235, 155))
	end

	task.delay(2, function()
		if statusBtn and statusBtn.Parent then
			statusBtn.Text = origText
		end
	end)
end

bindTap(retryBtn, function()
	if not isPackEnabled("GUARD") then
		setFooter("P10 GUARD pack is disabled.", Color3.fromRGB(255, 165, 130))
		return
	end
	retryJoinActive = not retryJoinActive
	retryBtn.Text = retryJoinActive and "RETRY JOIN: ON" or "RETRY JOIN: OFF"
	retryBtn.BackgroundColor3 = retryJoinActive and Color3.fromRGB(42, 132, 86) or Color3.fromRGB(48, 76, 112)
	setFooter(retryJoinActive and "Auto-retry active (4s interval)." or "Auto-retry stopped.", Color3.fromRGB(165, 225, 255))
	if retryJoinActive then
		task.spawn(function()
			while retryJoinActive and gui.Parent do
				local jid = sanitizeJobId(jobInp.Text)
				local pid = tonumber(placeInp.Text) or game.PlaceId
				if jid ~= "" then
					executeTeleport(pid, jid, joinJobBtn)
				elseif pid and pid > 0 then
					executeTeleport(pid, nil, nil)
				end
				task.wait(4)
			end
		end)
	end
end)

bindTap(stopSpecBtn, function()
	stopSpectate()
	setFooter("Stopped spectating.", Color3.fromRGB(185, 210, 240))
end)
bindTap(prevSpecBtn, function() cycleSpectate(-1) end)
bindTap(nextSpecBtn, function() cycleSpectate(1) end)

local function refreshServerPlayersList()
	table.clear(specButtonsByPlayer)
	table.clear(followButtonsByPlayer)
	for _, ch in ipairs(playersFrame:GetChildren()) do
		if ch:IsA("Frame") then ch:Destroy() end
	end

	local allPlrs = p:GetPlayers()
	plyCountLbl.Text = string.format("Players: %d/%d", #allPlrs, math.max(p.MaxPlayers, #allPlrs))

	local sortedPlrs = {}
	for _, plr in ipairs(allPlrs) do
		table.insert(sortedPlrs, plr)
	end
	if sortPlayersAZ then
		table.sort(sortedPlrs, function(a, b)
			return string.lower(a.Name) < string.lower(b.Name)
		end)
	end

	local filterQ = string.lower(trimStr(playerFilterInp.Text))
	local myRoot = l.Character and l.Character:FindFirstChild("HumanoidRootPart")

	for _, plr in ipairs(sortedPlrs) do
		local nameMatch = filterQ == ""
			or string.find(string.lower(plr.Name), filterQ, 1, true) ~= nil
			or string.find(string.lower(plr.DisplayName), filterQ, 1, true) ~= nil

		if nameMatch then
			local row = Instance.new("Frame")
			row.Size = UDim2.new(1, 0, 0, 26)
			row.BackgroundColor3 = (plr == l) and Color3.fromRGB(24, 34, 48) or Color3.fromRGB(16, 20, 29)
			row.BorderSizePixel = 0
			row.ZIndex = 19
			row.Parent = playersFrame
			Instance.new("UICorner", row).CornerRadius = UDim.new(0, 4)

			local distStr = ""
			local theirRoot = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
			if isPackEnabled("RADAR") and myRoot and theirRoot and plr ~= l then
				distStr = string.format(" [%dm]", math.round((myRoot.Position - theirRoot.Position).Magnitude))
			end

			local hum = plr.Character and plr.Character:FindFirstChildOfClass("Humanoid")
			local hpStr = hum and (hum.Health > 0 and string.format(" HP:%d", math.round(hum.Health)) or " [DEAD]") or ""
			local teamStr = (plr.Team and plr.Team.Name ~= "") and (" (" .. plr.Team.Name .. ")") or ""

			local pNameLbl = Instance.new("TextLabel")
			pNameLbl.Size = UDim2.new(1, -158, 0, 12)
			pNameLbl.Position = UDim2.fromOffset(4, 1)
			pNameLbl.BackgroundTransparency = 1
			pNameLbl.Text = string.format("%s (@%s)%s%s%s", plr.DisplayName, plr.Name, teamStr, distStr, hpStr)
			pNameLbl.TextColor3 = Color3.fromRGB(225, 236, 252)
			pNameLbl.TextXAlignment = Enum.TextXAlignment.Left
			pNameLbl.TextTruncate = Enum.TextTruncate.AtEnd
			pNameLbl.Font = Enum.Font.GothamSemibold
			pNameLbl.TextSize = 6.5
			pNameLbl.ZIndex = 20
			pNameLbl.Parent = row

			local function makeMiniBtn(txt, w, xOff, bg)
				local b = Instance.new("TextButton")
				b.Size = UDim2.fromOffset(w, 11)
				b.Position = UDim2.new(1, xOff, 0, 13)
				b.BackgroundColor3 = bg
				b.Text = txt
				b.TextColor3 = Color3.fromRGB(255, 255, 255)
				b.Font = Enum.Font.GothamBold
				b.TextSize = 5.9
				b.ZIndex = 20
				b.Parent = row
				Instance.new("UICorner", b).CornerRadius = UDim.new(0, 3)
				return b
			end

			local fillBtn = makeMiniBtn("FILL", 24, -154, Color3.fromRGB(38, 96, 150))
			local idBtn   = makeMiniBtn("ID", 18, -128, Color3.fromRGB(34, 88, 68))
			local tpBtn   = makeMiniBtn("TP", 20, -108, Color3.fromRGB(45, 125, 84))
			local flwBtn  = makeMiniBtn((followTarget == plr) and "UNFLW" or "FLW", 28, -86, Color3.fromRGB(48, 86, 118))
			local specBtn = makeMiniBtn((spectatingTarget == plr) and "UNSPEC" or "SPEC", 32, -56, Color3.fromRGB(82, 56, 128))
			local espBtn  = makeMiniBtn(espEnabledByPlayer[plr] and "UNESP" or "ESP", 22, -22, Color3.fromRGB(115, 72, 34))

			specButtonsByPlayer[plr] = specBtn
			followButtonsByPlayer[plr] = flwBtn

			bindTap(fillBtn, function()
				inp.Text = plr.Name
				setFooter("Filled username: " .. plr.Name, Color3.fromRGB(150, 215, 255))
			end)

			bindTap(idBtn, function()
				copyWithFallback(tostring(plr.UserId), "UserId " .. tostring(plr.UserId))
				setFooter("Copied UserId: " .. tostring(plr.UserId), Color3.fromRGB(135, 245, 185))
			end)

			bindTap(tpBtn, function()
				if not isPackEnabled("RADAR") then
					setFooter("P4 RADAR pack is disabled.", Color3.fromRGB(255, 165, 130))
					return
				end
				local myR = l.Character and l.Character:FindFirstChild("HumanoidRootPart")
				local thR = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
				if myR and thR then
					myR.CFrame = thR.CFrame * CFrame.new(0, 0, 3)
					setFooter("Teleported behind " .. plr.Name, Color3.fromRGB(135, 245, 185))
				else
					setFooter("Character not loaded for TP to " .. plr.Name, Color3.fromRGB(255, 165, 130))
				end
			end)

			bindTap(flwBtn, function()
				if not isPackEnabled("RADAR") then
					setFooter("P4 RADAR pack is disabled.", Color3.fromRGB(255, 165, 130))
					return
				end
				if followTarget == plr then
					followTarget = nil
					syncFollowButtons()
					setFooter("Stopped following " .. plr.Name, Color3.fromRGB(185, 210, 240))
				else
					followTarget = plr
					syncFollowButtons()
					setFooter("Following " .. plr.Name, Color3.fromRGB(145, 235, 200))
				end
			end)

			bindTap(specBtn, function()
				if spectatingTarget == plr then
					stopSpectate()
					setFooter("Stopped spectating " .. plr.Name, Color3.fromRGB(185, 210, 240))
				elseif not startSpectatePlayer(plr) then
					setFooter("Character not loaded for " .. plr.Name, Color3.fromRGB(255, 165, 130))
				end
			end)

			bindTap(espBtn, function()
				if not isPackEnabled("ESP") then
					setFooter("P5 ESP pack is disabled.", Color3.fromRGB(255, 165, 130))
					return
				end
				espEnabledByPlayer[plr] = not espEnabledByPlayer[plr]
				if espEnabledByPlayer[plr] and plr.Character then
					clearEspForPlayer(plr)
					local hl = Instance.new("Highlight")
					hl.Name = "VlexEspHighlight"
					hl.FillColor = themes[themeIdx].accent
					hl.OutlineColor = Color3.fromRGB(255, 255, 255)
					hl.FillTransparency = 0.65
					hl.Parent = plr.Character
					espHighlights[plr] = hl
					espBtn.Text = "UNESP"
					setFooter("ESP ON for " .. plr.Name, Color3.fromRGB(255, 205, 130))
				else
					espEnabledByPlayer[plr] = false
					clearEspForPlayer(plr)
					espBtn.Text = "ESP"
					setFooter("ESP OFF for " .. plr.Name, Color3.fromRGB(185, 210, 240))
				end
			end)
		end
	end
end

trackConn(rs.Heartbeat:Connect(function()
	if followTarget and followTarget.Parent then
		local myR = l.Character and l.Character:FindFirstChild("HumanoidRootPart")
		local thR = followTarget.Character and followTarget.Character:FindFirstChild("HumanoidRootPart")
		if myR and thR then
			myR.CFrame = thR.CFrame * CFrame.new(0, 0, 3.5)
		end
	elseif followTarget and not followTarget.Parent then
		followTarget = nil
		syncFollowButtons()
	end

	if spectatingTarget then
		local hum = spectatingTarget.Character and spectatingTarget.Character:FindFirstChildOfClass("Humanoid")
		if not spectatingTarget.Parent or not hum or hum.Health <= 0 then
			stopSpectate()
		end
	end
end))

bindTap(clrFilterBtn, function()
	playerFilterInp.Text = ""
	refreshServerPlayersList()
end)

bindTap(sortPlayersBtn, function()
	sortPlayersAZ = not sortPlayersAZ
	sortPlayersBtn.Text = sortPlayersAZ and "JOIN" or "A-Z"
	refreshServerPlayersList()
end)

trackConn(playerFilterInp:GetPropertyChangedSignal("Text"):Connect(function()
	if playersContainer.Visible then
		refreshServerPlayersList()
	end
end))

bindTap(copyNamesBtn, function()
	local names = {}
	for _, plr in ipairs(p:GetPlayers()) do
		table.insert(names, plr.Name)
	end
	copyWithFallback(table.concat(names, "\n"), "server usernames")
	setFooter("Copied " .. tostring(#names) .. " usernames.", Color3.fromRGB(135, 245, 185))
end)

bindTap(copyIdsBtn, function()
	local ids = {}
	for _, plr in ipairs(p:GetPlayers()) do
		table.insert(ids, tostring(plr.UserId))
	end
	copyWithFallback(table.concat(ids, ", "), "server UserIds")
	setFooter("Copied " .. tostring(#ids) .. " UserIds.", Color3.fromRGB(135, 245, 185))
end)

local function loadPublicServers(appendNext)
	if not isPackEnabled("SNIPE") then
		setFooter("P2 SNIPE pack is disabled.", Color3.fromRGB(255, 165, 130))
		return
	end
	if not appendNext then
		nextServerCursor = nil
		for _, ch in ipairs(serversFrame:GetChildren()) do
			if ch:IsA("Frame") or ch:IsA("TextLabel") then ch:Destroy() end
		end
	end

	local loadingLbl = Instance.new("TextLabel")
	loadingLbl.Size = UDim2.new(1, 0, 0, 18)
	loadingLbl.BackgroundTransparency = 1
	loadingLbl.Text = appendNext and "Loading more servers..." or "Fetching public servers..."
	loadingLbl.TextColor3 = Color3.fromRGB(185, 210, 245)
	loadingLbl.Font = Enum.Font.GothamSemibold
	loadingLbl.TextSize = 7.0
	loadingLbl.ZIndex = 19
	loadingLbl.Parent = serversFrame

	local targetPlace = tonumber(placeInp.Text) or game.PlaceId
	local mode = serverSortModes[serverSortIdx] or "DESC"
	local orderParam = (mode == "ASC" or mode == "LOW PING" or mode == "EMPTY") and "Asc" or "Desc"
	local url = string.format("https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=%s&limit=50", targetPlace, orderParam)
	if appendNext and nextServerCursor then
		url = url .. "&cursor=" .. hs:UrlEncode(nextServerCursor)
	end

	local ok, raw = pcall(function() return game:HttpGet(url) end)
	if loadingLbl and loadingLbl.Parent then loadingLbl:Destroy() end

	if not ok or not raw then
		local errLbl = Instance.new("TextLabel")
		errLbl.Size = UDim2.new(1, 0, 0, 20)
		errLbl.BackgroundTransparency = 1
		errLbl.Text = "Could not load server list."
		errLbl.TextColor3 = Color3.fromRGB(255, 150, 135)
		errLbl.Font = Enum.Font.GothamSemibold
		errLbl.TextSize = 7.0
		errLbl.ZIndex = 19
		errLbl.Parent = serversFrame
		return
	end

	local dOk, data = pcall(function() return hs:JSONDecode(raw) end)
	if not dOk or not data or type(data.data) ~= "table" or #data.data == 0 then
		if not appendNext then
			local emptyLbl = Instance.new("TextLabel")
			emptyLbl.Size = UDim2.new(1, 0, 0, 20)
			emptyLbl.BackgroundTransparency = 1
			emptyLbl.Text = "No servers returned."
			emptyLbl.TextColor3 = Color3.fromRGB(200, 210, 225)
			emptyLbl.Font = Enum.Font.GothamSemibold
			emptyLbl.TextSize = 7.0
			emptyLbl.ZIndex = 19
			emptyLbl.Parent = serversFrame
		else
			setFooter("No more server pages.", Color3.fromRGB(200, 210, 225))
		end
		return
	end

	nextServerCursor = data.nextPageCursor
	local maxPingFilter = tonumber(maxPingInp.Text)

	local list = {}
	for _, srv in ipairs(data.data) do
		if srv.id then
			local playing = srv.playing or 0
			local maxPlr = math.max(srv.maxPlayers or 1, 1)
			local ping = srv.ping or 9999
			local pingOk = (not maxPingFilter) or (ping <= maxPingFilter)
			local modeOk = true
			if mode == "OPEN" then
				modeOk = playing < maxPlr
			elseif mode == "SNIPER" then
				modeOk = (maxPlr - playing) > 0 and (maxPlr - playing) <= 2
			end
			if pingOk and modeOk then
				table.insert(list, srv)
			end
		end
	end

	if mode == "LOW PING" then
		table.sort(list, function(a, b) return (a.ping or 9999) < (b.ping or 9999) end)
	elseif mode == "OPEN" or mode == "SNIPER" then
		table.sort(list, function(a, b) return (a.playing or 0) > (b.playing or 0) end)
	elseif mode == "EMPTY" then
		table.sort(list, function(a, b) return (a.playing or 0) < (b.playing or 0) end)
	end

	for _, srv in ipairs(list) do
		local playing = srv.playing or 0
		local maxPlr = math.max(srv.maxPlayers or 1, 1)
		local ratio = math.clamp(playing / maxPlr, 0, 1)

		local row = Instance.new("Frame")
		row.Size = UDim2.new(1, 0, 0, 24)
		row.BackgroundColor3 = Color3.fromRGB(16, 20, 29)
		row.BorderSizePixel = 0
		row.ZIndex = 19
		row.Parent = serversFrame
		Instance.new("UICorner", row).CornerRadius = UDim.new(0, 4)

		local infoLbl = Instance.new("TextLabel")
		infoLbl.Size = UDim2.new(1, -78, 0, 14)
		infoLbl.Position = UDim2.fromOffset(4, 1)
		infoLbl.BackgroundTransparency = 1
		infoLbl.Text = string.format("%d/%d | %dms | %s", playing, maxPlr, srv.ping or 0, tostring(srv.id))
		infoLbl.TextColor3 = Color3.fromRGB(220, 232, 248)
		infoLbl.TextXAlignment = Enum.TextXAlignment.Left
		infoLbl.TextTruncate = Enum.TextTruncate.AtEnd
		infoLbl.Font = Enum.Font.Code
		infoLbl.TextSize = 6.6
		infoLbl.ZIndex = 20
		infoLbl.Parent = row

		local miniBarBg = Instance.new("Frame")
		miniBarBg.Size = UDim2.new(1, -82, 0, 3)
		miniBarBg.Position = UDim2.fromOffset(4, 18)
		miniBarBg.BackgroundColor3 = Color3.fromRGB(32, 38, 52)
		miniBarBg.BorderSizePixel = 0
		miniBarBg.ZIndex = 20
		miniBarBg.Parent = row

		local miniBarFill = Instance.new("Frame")
		miniBarFill.Size = UDim2.new(ratio, 0, 1, 0)
		miniBarFill.BackgroundColor3 = themes[themeIdx].accent
		miniBarFill.BorderSizePixel = 0
		miniBarFill.ZIndex = 21
		miniBarFill.Parent = miniBarBg

		local copySrvBtn = Instance.new("TextButton")
		copySrvBtn.Size = UDim2.fromOffset(34, 16)
		copySrvBtn.Position = UDim2.new(1, -74, 0.5, -8)
		copySrvBtn.BackgroundColor3 = Color3.fromRGB(34, 88, 68)
		copySrvBtn.Text = "COPY"
		copySrvBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
		copySrvBtn.Font = Enum.Font.GothamBold
		copySrvBtn.TextSize = 6.4
		copySrvBtn.ZIndex = 20
		copySrvBtn.Parent = row
		Instance.new("UICorner", copySrvBtn).CornerRadius = UDim.new(0, 3)
		bindTap(copySrvBtn, function()
			jobInp.Text = tostring(srv.id)
			pushHistory("JOB", tostring(srv.id))
			copyWithFallback(tostring(srv.id), "server JobId")
			setFooter("Copied JobId: " .. tostring(srv.id), Color3.fromRGB(135, 245, 185))
		end)

		local joinSrvBtn = Instance.new("TextButton")
		joinSrvBtn.Size = UDim2.fromOffset(34, 16)
		joinSrvBtn.Position = UDim2.new(1, -37, 0.5, -8)
		joinSrvBtn.BackgroundColor3 = Color3.fromRGB(45, 142, 92)
		joinSrvBtn.Text = "JOIN"
		joinSrvBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
		joinSrvBtn.Font = Enum.Font.GothamBold
		joinSrvBtn.TextSize = 6.4
		joinSrvBtn.ZIndex = 20
		joinSrvBtn.Parent = row
		Instance.new("UICorner", joinSrvBtn).CornerRadius = UDim.new(0, 3)
		bindTap(joinSrvBtn, function()
			jobInp.Text = tostring(srv.id)
			executeTeleport(targetPlace, tostring(srv.id), joinSrvBtn)
		end)
	end
end

bindTap(sortServersBtn, function()
	serverSortIdx = (serverSortIdx % #serverSortModes) + 1
	sortServersBtn.Text = "SORT: " .. serverSortModes[serverSortIdx]
	if serversContainer.Visible then
		task.spawn(function() loadPublicServers(false) end)
	end
end)

bindTap(refreshServersBtn, function()
	if serversContainer.Visible then
		task.spawn(function() loadPublicServers(false) end)
	end
end)

bindTap(nextPageSrvBtn, function()
	if serversContainer.Visible then
		task.spawn(function() loadPublicServers(true) end)
	end
end)

local function setMode(modeName)
	f.Visible = (modeName == "RESULTS")
	playersContainer.Visible = (modeName == "PLAYERS")
	serversContainer.Visible = (modeName == "SERVERS")
	logContainer.Visible = (modeName == "LOG")

	local tabs = {
		RESULTS = tabResultsBtn,
		PLAYERS = tabPlayersBtn,
		SERVERS = tabServersBtn,
		LOG = tabLogBtn,
	}
	for k, b in pairs(tabs) do
		b.BackgroundColor3 = (k == modeName) and themes[themeIdx].btn or Color3.fromRGB(28, 34, 46)
		b.TextColor3 = (k == modeName) and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(185, 200, 224)
	end

	if modeName == "RESULTS" then
		updateEmptyResultsPrompt()
	elseif modeName == "PLAYERS" then
		refreshServerPlayersList()
	elseif modeName == "SERVERS" then
		task.spawn(function() loadPublicServers(false) end)
	elseif modeName == "LOG" then
		refreshLogTab()
	end
end

bindTap(tabResultsBtn, function() setMode("RESULTS") end)
bindTap(tabPlayersBtn, function() setMode("PLAYERS") end)
bindTap(tabServersBtn, function() setMode("SERVERS") end)
bindTap(tabLogBtn, function() setMode("LOG") end)

trackConn(p.PlayerAdded:Connect(function()
	if playersContainer.Visible then refreshServerPlayersList() end
end))
trackConn(p.PlayerRemoving:Connect(function(remPlr)
	if spectatingTarget == remPlr then stopSpectate() end
	if followTarget == remPlr then followTarget = nil; syncFollowButtons() end
	clearEspForPlayer(remPlr)
	if playersContainer.Visible then refreshServerPlayersList() end
end))

-- Live Telemetry Loop (#801-#900)
local sessionStart = os.clock()
local lastFrameClock = os.clock()
local cachedSrvSummary = ""

task.spawn(function()
	while gui.Parent do
		local now = os.clock()
		local dt = math.max(now - lastFrameClock, 0.001)
		lastFrameClock = now
		local fps = math.clamp(math.round(1 / dt), 1, 240)

		local curCount = #p:GetPlayers()
		local maxCount = math.max(p.MaxPlayers, 1)
		local ratio = math.clamp(curCount / maxCount, 0, 1)
		capFill.Size = UDim2.new(ratio, 0, 1, 0)
		srvCapLbl.Text = string.format("%d/%d max", curCount, maxCount)

		local pingMs = nil
		pcall(function()
			local v = sts.Network.ServerStatsItem["Data Ping"]:GetValue()
			if type(v) == "number" and v > 0 then
				pingMs = math.round(v)
			end
		end)

		local memMb = math.round(gcinfo() / 1024)
		local elapsed = math.floor(now - sessionStart)
		local upStr = string.format("%02d:%02d", math.floor(elapsed / 60), elapsed % 60)
		local activeJob = game.JobId ~= "" and game.JobId or "Studio / Local"

		srvStatsLbl.Text = string.format(
			"Ping: %s | FPS: %d | Mem: %dMB\nPlaceId: %d | Up: %s",
			pingMs and (tostring(pingMs) .. " ms") or "N/A",
			fps,
			memMb,
			game.PlaceId,
			upStr
		)
		srvIdLbl.Text = "ID: " .. activeJob
		cachedSrvSummary = string.format(
			"PlaceId: %d\nJobId: %s\nPlayers: %d/%d\nPing: %s\nFPS: %d\nMem: %dMB\nUptime: %s",
			game.PlaceId,
			activeJob,
			curCount,
			maxCount,
			pingMs and (tostring(pingMs) .. " ms") or "N/A",
			fps,
			memMb,
			upStr
		)
		task.wait(1.5)
	end
end)

bindTap(copySrvInfoBtn, function()
	if cachedSrvSummary ~= "" then
		copyWithFallback(cachedSrvSummary, "server telemetry")
		setFooter("Copied server telemetry summary.", Color3.fromRGB(135, 245, 185))
	end
end)

bindTap(rejoinBtn, function()
	executeTeleport(game.PlaceId, game.JobId, rejoinBtn)
end)

bindTap(joinJobBtn, function()
	local cleanJob = sanitizeJobId(jobInp.Text)
	jobInp.Text = cleanJob
	if cleanJob == "" then
		setFooter("Paste a JobId first.", Color3.fromRGB(255, 165, 130))
		return
	end
	pushHistory("JOB", cleanJob)
	executeTeleport(placeInp.Text, cleanJob, joinJobBtn)
end)

bindTap(clrBtn, function()
	inp.Text = ""
	jobInp.Text = ""
	placeInp.Text = ""
	setFooter("Cleared inputs.", Color3.fromRGB(155, 175, 200))
end)

bindTap(clrResultsBtn, function()
	for _, ch in ipairs(f:GetChildren()) do
		if ch:IsA("Frame") then ch:Destroy() end
	end
	updateEmptyResultsPrompt()
	setFooter("Cleared result cards.", Color3.fromRGB(165, 210, 255))
end)

bindTap(fmtBtn, function()
	if not isPackEnabled("FMT") then
		setFooter("P6 FMT pack is disabled.", Color3.fromRGB(255, 165, 130))
		return
	end
	copyModeIdx = (copyModeIdx % #copyModes) + 1
	fmtBtn.Text = "FMT: " .. copyModes[copyModeIdx]
	setFooter("Copy mode set to " .. copyModes[copyModeIdx], Color3.fromRGB(165, 225, 255))
end)

bindTap(cpBtn, function()
	if game.JobId ~= "" then
		copyWithFallback(game.JobId, "current JobId")
		jobInp.Text = game.JobId
		pushHistory("JOB", game.JobId)
		setFooter("Copied JobId: " .. game.JobId, Color3.fromRGB(135, 245, 185))
	else
		setFooter("No JobId available in this session.", Color3.fromRGB(255, 165, 130))
	end
	cpBtn.Text = "COPIED"
	task.delay(1, function()
		if cpBtn and cpBtn.Parent then cpBtn.Text = "JOBID" end
	end)
end)

local function hopToServer(randomPick)
	if not isPackEnabled("HOP") then
		setFooter("P3 HOP pack is disabled.", Color3.fromRGB(255, 165, 130))
		return
	end
	if os.clock() - lastHopTime < 2.2 then
		setFooter("Hop cooldown active—wait a second.", Color3.fromRGB(255, 195, 110))
		return
	end
	lastHopTime = os.clock()
	local targetBtn = randomPick and randSrvBtn or hopBtn
	local origLbl = targetBtn.Text
	targetBtn.Text = "..."
	setFooter(randomPick and "Picking a random public server..." or "Searching for a new server...", Color3.fromRGB(165, 210, 255))

	task.spawn(function()
		local hopped = false
		local targetPlace = tonumber(placeInp.Text) or game.PlaceId
		local url = string.format("https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Desc&limit=100", targetPlace)
		local ok, raw = pcall(function() return game:HttpGet(url) end)
		if ok and raw then
			local dOk, data = pcall(function() return hs:JSONDecode(raw) end)
			if dOk and data and type(data.data) == "table" then
				local candidates = {}
				for _, srv in ipairs(data.data) do
					if srv.id and srv.id ~= game.JobId and not visitedServers[srv.id] and (srv.playing or 0) < (srv.maxPlayers or 999) then
						table.insert(candidates, srv)
					end
				end
				if #candidates == 0 then
					for _, srv in ipairs(data.data) do
						if srv.id and srv.id ~= game.JobId and (srv.playing or 0) < (srv.maxPlayers or 999) then
							table.insert(candidates, srv)
						end
					end
				end
				if #candidates > 0 then
					local chosen = randomPick and candidates[math.random(1, #candidates)] or candidates[1]
					visitedServers[chosen.id] = true
					local tpOk = pcall(function()
						ts:TeleportToPlaceInstance(targetPlace, chosen.id, l)
					end)
					if tpOk then
						hopped = true
					end
				end
			end
		end
		if not hopped then
			pcall(function() ts:Teleport(targetPlace, l) end)
		end
		task.delay(2, function()
			if targetBtn and targetBtn.Parent then targetBtn.Text = origLbl end
		end)
	end)
end

bindTap(hopBtn, function() hopToServer(false) end)
bindTap(randSrvBtn, function() hopToServer(true) end)

local function resolveGameName(placeId, fallbackLocation)
	if placeId and placeId > 0 then
		local ok, info = pcall(function() return ms:GetProductInfo(placeId) end)
		if ok and info and info.Name and info.Name ~= "" then
			return info.Name
		end
	end
	if fallbackLocation and fallbackLocation ~= "" then
		return fallbackLocation
	end
	return "None / Unknown"
end

trackConn(placeInp:GetPropertyChangedSignal("Text"):Connect(function()
	local digits = string.gsub(placeInp.Text, "%D", "")
	if digits ~= placeInp.Text then
		placeInp.Text = digits
	end
end))

local function formatPlayerPayload(modeName, name, dName, st, jobStr, friended, gameName, uid)
	if modeName == "COMPACT" then
		return string.format(
			"Username: %s | Display name: %s | Status: %s | Jobid: %s | Friended: %s | Game: %s | User id: %s",
			name, dName, st, jobStr, friended, gameName, tostring(uid)
		)
	elseif modeName == "JSON" then
		return hs:JSONEncode({
			username = name,
			displayName = dName,
			status = st,
			jobId = jobStr,
			friended = friended,
			game = gameName,
			userId = tonumber(uid) or uid,
		})
	elseif modeName == "DISCORD" then
		return string.format(
			"**@%s** (%s)\nStatus: `%s` | Friended: `%s`\nGame: **%s**\nJobId: `%s`\nUserId: `%s`",
			name, dName, st, friended, gameName, jobStr, tostring(uid)
		)
	end
	return table.concat({
		"Username: " .. name,
		"Display name: " .. dName,
		"Status: " .. st,
		"Jobid: " .. jobStr,
		"Friended: " .. friended,
		"Game: " .. gameName,
		"User id: " .. tostring(uid),
	}, "\n")
end

local function createPlayerResultCard(singleQuery, customJob, customPlace)
	local cardItem = Instance.new("Frame")
	cardItem.Size = UDim2.new(1, 0, 0, 144)
	cardItem.BackgroundColor3 = Color3.fromRGB(16, 20, 29)
	cardItem.BorderSizePixel = 0
	cardItem.ZIndex = 18
	cardItem.Parent = f
	Instance.new("UICorner", cardItem).CornerRadius = UDim.new(0, 6)
	updateEmptyResultsPrompt()

	local itemStroke = Instance.new("UIStroke")
	itemStroke.Color = Color3.fromRGB(42, 54, 74)
	itemStroke.Thickness = 1
	itemStroke.Parent = cardItem

	local xBtn = Instance.new("TextButton")
	xBtn.Size = UDim2.fromOffset(18, 16)
	xBtn.Position = UDim2.new(1, -22, 0, 3)
	xBtn.BackgroundColor3 = Color3.fromRGB(155, 44, 52)
	xBtn.Text = "X"
	xBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	xBtn.Font = Enum.Font.GothamBold
	xBtn.TextSize = 7.4
	xBtn.ZIndex = 19
	xBtn.Parent = cardItem
	Instance.new("UICorner", xBtn).CornerRadius = UDim.new(0, 4)
	bindTap(xBtn, function()
		cardItem:Destroy()
		updateEmptyResultsPrompt()
	end)

	local img = Instance.new("ImageLabel")
	img.Size = UDim2.fromOffset(48, 48)
	img.Position = UDim2.fromOffset(6, 5)
	img.BackgroundColor3 = Color3.fromRGB(28, 34, 46)
	img.BorderSizePixel = 0
	img.ZIndex = 19
	img.Parent = cardItem
	Instance.new("UICorner", img).CornerRadius = UDim.new(0, 5)

	local joinBtn = Instance.new("TextButton")
	joinBtn.Size = UDim2.fromOffset(48, 16)
	joinBtn.Position = UDim2.fromOffset(6, 57)
	joinBtn.BackgroundColor3 = Color3.fromRGB(45, 142, 92)
	joinBtn.Text = "JOIN"
	joinBtn.TextColor3 = Color3.fromRGB(245, 255, 250)
	joinBtn.Font = Enum.Font.GothamBold
	joinBtn.TextSize = 7.0
	joinBtn.Visible = false
	joinBtn.ZIndex = 19
	joinBtn.Parent = cardItem
	Instance.new("UICorner", joinBtn).CornerRadius = UDim.new(0, 4)

	local copyPlayerBtn = Instance.new("TextButton")
	copyPlayerBtn.Size = UDim2.fromOffset(48, 16)
	copyPlayerBtn.Position = UDim2.fromOffset(6, 76)
	copyPlayerBtn.BackgroundColor3 = Color3.fromRGB(38, 96, 150)
	copyPlayerBtn.Text = "COPY"
	copyPlayerBtn.TextColor3 = Color3.fromRGB(245, 252, 255)
	copyPlayerBtn.Font = Enum.Font.GothamBold
	copyPlayerBtn.TextSize = 7.0
	copyPlayerBtn.ZIndex = 19
	copyPlayerBtn.Parent = cardItem
	Instance.new("UICorner", copyPlayerBtn).CornerRadius = UDim.new(0, 4)

	local txt = Instance.new("TextLabel")
	txt.Size = UDim2.new(1, -86, 1, -24)
	txt.Position = UDim2.fromOffset(58, 3)
	txt.BackgroundTransparency = 1
	txt.Font = Enum.Font.GothamSemibold
	txt.TextColor3 = Color3.fromRGB(215, 228, 245)
	txt.TextSize = 6.8
	txt.TextXAlignment = Enum.TextXAlignment.Left
	txt.TextYAlignment = Enum.TextYAlignment.Top
	txt.TextWrapped = true
	txt.ZIndex = 19
	txt.Text = "Fetching data for " .. singleQuery .. "..."
	txt.Parent = cardItem

	local actBar = Instance.new("Frame")
	actBar.Size = UDim2.new(1, -12, 0, 15)
	actBar.Position = UDim2.new(0, 6, 1, -18)
	actBar.BackgroundTransparency = 1
	actBar.ZIndex = 19
	actBar.Parent = cardItem

	local function makeCardAct(t, w, xO, bg)
		local b = Instance.new("TextButton")
		b.Size = UDim2.fromOffset(w, 15)
		b.Position = UDim2.fromOffset(xO, 0)
		b.BackgroundColor3 = bg
		b.Text = t
		b.TextColor3 = Color3.fromRGB(240, 248, 255)
		b.Font = Enum.Font.GothamBold
		b.TextSize = 5.9
		b.ZIndex = 20
		b.Parent = actBar
		Instance.new("UICorner", b).CornerRadius = UDim.new(0, 3)
		return b
	end

	local fillJobCardBtn   = makeCardAct("TO JOB", 38, 0, Color3.fromRGB(48, 38, 92))
	local fillPlaceCardBtn = makeCardAct("TO PLC", 38, 41, Color3.fromRGB(36, 56, 86))
	local cpyIdCardBtn     = makeCardAct("CPY ID", 36, 82, Color3.fromRGB(34, 88, 68))
	local cpyProfBtn       = makeCardAct("PROFILE", 44, 121, Color3.fromRGB(42, 66, 94))
	local cpyGameBtn       = makeCardAct("GAME URL", 48, 168, Color3.fromRGB(42, 66, 94))
	local bioBtn           = makeCardAct("BIO", 32, 219, Color3.fromRGB(66, 48, 86))

	task.spawn(function()
		local uid = tonumber(singleQuery)
		if not uid then
			local ok, resolvedId = pcall(function() return p:GetUserIdFromNameAsync(singleQuery) end)
			if ok and resolvedId then
				uid = resolvedId
			end
		end

		if not uid or uid <= 0 then
			txt.Text = "Error: User not found."
			setFooter("User not found: " .. singleQuery, Color3.fromRGB(255, 150, 135))
			pushLog("ERR", "Not found: " .. singleQuery)
			return
		end

		local tOk, tUrl = pcall(function() return p:GetUserThumbnailAsync(uid, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size150x150) end)
		if tOk and tUrl and img and img.Parent then img.Image = tUrl end

		local aOk, aData = pcall(function() return hs:JSONDecode(game:HttpGet("https://users.roblox.com/v1/users/" .. tostring(uid))) end)
		local dName, name, bioStr, createdStr = "Unknown", singleQuery, "No bio available.", "Unknown"
		if aOk and aData then
			dName = aData.displayName or "Unknown"
			name = aData.name or singleQuery
			if aData.description and trimStr(aData.description) ~= "" then
				bioStr = trimStr(aData.description)
			end
			if aData.created and tostring(aData.created) ~= "" then
				createdStr = string.sub(tostring(aData.created), 1, 10)
			end
		end

		local friended = "No"
		pcall(function()
			if l:IsFriendsWith(uid) then
				friended = "Yes"
			end
		end)

		local st = "Offline / Unknown"
		local targetPlaceId = customPlace
		local targetJobId = customJob
		local gameName = "Not in a game"

		local inServerPlayer = p:GetPlayerByUserId(uid)
		if inServerPlayer then
			st = "In This Server"
			if not targetPlaceId then targetPlaceId = game.PlaceId end
			if not targetJobId and game.JobId ~= "" then
				targetJobId = game.JobId
			end
			gameName = resolveGameName(targetPlaceId or game.PlaceId, "Current Game")
		else
			local onOk, onList = pcall(function() return l:GetFriendsOnline(200) end)
			if onOk and onList then
				for _, fr in ipairs(onList) do
					if fr.VisitorId == uid or fr.UserId == uid then
						st = "Online (Friend)"
						friended = "Yes"
						if fr.PlaceId and fr.PlaceId > 0 then
							if not targetPlaceId then targetPlaceId = fr.PlaceId end
							gameName = resolveGameName(fr.PlaceId, fr.LastLocation)
						elseif fr.LastLocation and fr.LastLocation ~= "" then
							gameName = fr.LastLocation
						end
						if not targetJobId and fr.GameId and fr.GameId ~= "" then
							targetJobId = fr.GameId
						end
						break
					end
				end
			end
		end

		if not targetPlaceId and targetJobId then
			targetPlaceId = game.PlaceId
			gameName = resolveGameName(targetPlaceId, "Current Game")
		end

		local jobStr = (targetJobId and targetJobId ~= "") and tostring(targetJobId) or "Hidden/N/A"
		local showBio = false

		local function rebuildCardText()
			local base = string.format(
				"Username: %s\nDisplay name: %s\nStatus: %s\nJobid: %s\nFriended: %s\nGame: %s\nUser id: %s\nCreated: %s",
				name, dName, st, jobStr, friended, gameName, tostring(uid), createdStr
			)
			if showBio then
				base = base .. "\nBio: " .. bioStr
			end
			txt.Text = base
		end
		rebuildCardText()

		bindTap(bioBtn, function()
			showBio = not showBio
			bioBtn.Text = showBio and "HIDE BIO" or "BIO"
			rebuildCardText()
		end)

		bindTap(fillJobCardBtn, function()
			if jobStr ~= "Hidden/N/A" then
				jobInp.Text = jobStr
				pushHistory("JOB", jobStr)
				setFooter("Loaded JobId into box.", Color3.fromRGB(165, 215, 255))
			else
				setFooter("JobId is Hidden/N/A for @" .. name, Color3.fromRGB(255, 165, 130))
			end
		end)

		bindTap(fillPlaceCardBtn, function()
			if targetPlaceId and targetPlaceId > 0 then
				placeInp.Text = tostring(targetPlaceId)
				setFooter("Loaded PlaceId " .. tostring(targetPlaceId) .. " into box.", Color3.fromRGB(165, 215, 255))
			else
				setFooter("No PlaceId detected for @" .. name, Color3.fromRGB(255, 165, 130))
			end
		end)

		bindTap(cpyIdCardBtn, function()
			copyWithFallback(tostring(uid), "UserId " .. tostring(uid))
			setFooter("Copied UserId: " .. tostring(uid), Color3.fromRGB(135, 245, 185))
		end)

		bindTap(cpyProfBtn, function()
			local url = "https://www.roblox.com/users/" .. tostring(uid) .. "/profile"
			copyWithFallback(url, "profile URL")
			setFooter("Copied profile link for @" .. name, Color3.fromRGB(135, 245, 185))
		end)

		bindTap(cpyGameBtn, function()
			if targetPlaceId and targetPlaceId > 0 then
				local gUrl = "https://www.roblox.com/games/" .. tostring(targetPlaceId) .. "/"
				copyWithFallback(gUrl, "game URL")
				setFooter("Copied game URL for PlaceId " .. tostring(targetPlaceId), Color3.fromRGB(135, 245, 185))
			else
				setFooter("No PlaceId URL available.", Color3.fromRGB(255, 165, 130))
			end
		end)

		bindTap(copyPlayerBtn, function()
			local modeNow = copyModes[copyModeIdx] or "MULTI"
			local outTxt = formatPlayerPayload(modeNow, name, dName, st, jobStr, friended, gameName, uid)
			copyWithFallback(outTxt, "player info (@" .. name .. ", " .. modeNow .. ")")
			copyPlayerBtn.Text = "COPIED"
			setFooter("Copied @" .. name .. " [" .. modeNow .. "]", Color3.fromRGB(135, 245, 185))
			task.delay(1.1, function()
				if copyPlayerBtn and copyPlayerBtn.Parent then copyPlayerBtn.Text = "COPY" end
			end)
		end)

		local hasValidJob = targetJobId and targetJobId ~= "" and targetJobId ~= "Hidden/N/A"
		if (targetPlaceId and targetPlaceId > 0) or hasValidJob then
			joinBtn.Visible = true
			bindTap(joinBtn, function()
				executeTeleport(targetPlaceId, targetJobId, joinBtn)
			end)
		end

		setFooter("Found @" .. name .. " (" .. st .. ")", Color3.fromRGB(150, 215, 255))
		pushLog("SRCH", "@" .. name .. " [" .. st .. "]")
	end)
end

local function triggerPlayerSearch()
	if not isPackEnabled("INTEL") then
		setFooter("P1 INTEL pack is disabled.", Color3.fromRGB(255, 165, 130))
		return
	end
	setMode("RESULTS")
	local rawQ = trimStr(inp.Text)
	if rawQ == "" then
		setFooter("Enter a username or UserId first.", Color3.fromRGB(255, 165, 130))
		return
	end

	local customJob = sanitizeJobId(jobInp.Text)
	if customJob == "" then customJob = nil end
	local customPlace = tonumber(trimStr(placeInp.Text))

	local parts = {}
	for token in string.gmatch(rawQ, "[^,%s]+") do
		local t = trimStr(token)
		if t ~= "" then
			table.insert(parts, t)
		end
	end

	if #parts == 0 then parts = { rawQ } end
	for _, token in ipairs(parts) do
		pushHistory("USER", token)
		createPlayerResultCard(token, customJob, customPlace)
	end
end

bindTap(sBtn, triggerPlayerSearch)

local dg, ds, dp
local function clampCardPos(posX, posY)
	local vp = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1280, 720)
	local minX = -card.Size.X.Offset + 48
	local maxX = math.max(minX, vp.X - 48)
	local minY = 0
	local maxY = math.max(0, vp.Y - 36)
	return UDim2.fromOffset(math.clamp(posX, minX, maxX), math.clamp(posY, minY, maxY))
end

bindTap(snapBtn, function()
	card.Position = DEFAULT_CARD_POS
	setFooter("Snapped card to default position.", Color3.fromRGB(165, 215, 255))
end)

trackConn(header.InputBegan:Connect(function(i)
	if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
		dg, ds, dp = true, i.Position, card.Position
	end
end))
trackConn(uis.InputChanged:Connect(function(i)
	if dg and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
		local d = i.Position - ds
		card.Position = clampCardPos(dp.X.Offset + d.X, dp.Y.Offset + d.Y)
	end
end))
trackConn(uis.InputEnded:Connect(function(i)
	if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then dg = false end
end))

local introDone = false
local function finishIntro()
	if introDone then return end
	introDone = true
	pcall(function() introBlur:Destroy() end)
	pcall(function() introOverlay:Destroy() end)
	if card and card.Parent then
		card.Visible = true
	end
end

local function safeTweenWait(inst, info, props, holdAfter)
	if introDone or not inst or not inst.Parent then return end
	local ok = pcall(function()
		local tw = tws:Create(inst, info, props)
		tw:Play()
		tw.Completed:Wait()
	end)
	if not ok then
		pcall(function()
			for k, v in pairs(props) do
				inst[k] = v
			end
		end)
	end
	if not introDone and holdAfter and holdAfter > 0 then
		task.wait(holdAfter)
	end
end

-- Hard fail-safe so the intro can never stay stuck
task.delay(6.5, finishIntro)

task.spawn(function()
	local fadeIn = TweenInfo.new(0.75, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local fadeOut = TweenInfo.new(0.65, Enum.EasingStyle.Quad, Enum.EasingDirection.In)

	pcall(function()
		if introBlur and introBlur.Parent then
			tws:Create(introBlur, fadeIn, { Size = 18 }):Play()
		end
	end)

	introTitle.Text = "Welcome"
	introSub.Text = "Initializing SEARCH HUB 1.1K..."
	safeTweenWait(introTitle, fadeIn, { TextTransparency = 0 }, 0)
	safeTweenWait(introSub, fadeIn, { TextTransparency = 0 }, 1.35)

	safeTweenWait(introTitle, fadeOut, { TextTransparency = 1 }, 0)
	safeTweenWait(introSub, fadeOut, { TextTransparency = 1 }, 0.35)

	introTitle.Text = "made by f3liks/11f3liks"
	introSub.Text = "Credits • Loading interface..."
	safeTweenWait(introTitle, fadeIn, { TextTransparency = 0 }, 0)
	safeTweenWait(introSub, fadeIn, { TextTransparency = 0 }, 1.55)

	safeTweenWait(introTitle, fadeOut, { TextTransparency = 1 }, 0)
	safeTweenWait(introSub, fadeOut, { TextTransparency = 1 }, 0)
	pcall(function()
		if introBlur and introBlur.Parent then
			tws:Create(introBlur, fadeOut, { Size = 0 }):Play()
		end
	end)
	safeTweenWait(introOverlay, fadeOut, { BackgroundTransparency = 1 }, 0.25)

	finishIntro()
end)
]=])()
