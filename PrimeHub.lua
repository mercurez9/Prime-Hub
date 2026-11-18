-- primehub.lua

local uiLoader = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/topitbopit/dollarware/main/library.lua"
))

local ui = uiLoader({
    rounding = false,
    theme = "orange",
    smoothDragging = true
})

ui.autoDisableToggles = true

-- ==========================================
-- WINDOW
-- ==========================================

local window = ui.newWindow({
    text = "Prime Hub",
    resize = true,
    size = Vector2.new(600, 430),
    position = nil
})

-- ==========================================
-- MAIN TAB
-- ==========================================

local Main = window:addMenu({
    text = "Main"
})

-- BOOSTERS SECTION
local Boosters = Main:addSection({
    text = "Boosters",
    side = "left",
    showMinButton = true
})

Boosters:addLabel({
    text = "Booster Options"
})

-- ADMIN SECTION
local Admin = Main:addSection({
    text = "Admin",
    side = "right",
    showMinButton = true
})

Admin:addLabel({
    text = "Admin Options"
})

-- ==========================================
-- AP SPAMMER (Connect.cc UI + Rez's AP logic)
-- Row click: 1st click = Semi, click again within 5s = Full.
-- ==========================================

local APPlayers = game:GetService("Players")
local APUIS     = game:GetService("UserInputService")
local APLocal   = APPlayers.LocalPlayer

local AP_OBJECT_ID    = "rbxassetid://122128878224452"
local AP_ROW_IDLE     = Color3.fromRGB(28, 28, 34)
local AP_ROW_BUSY     = Color3.fromRGB(120, 90, 30)
local AP_ROW_COOLDOWN = Color3.fromRGB(100, 40, 40)
local AP_COMBO_WINDOW = 5

local QuickCommandCooldowns = {
    rocket = 120, ragdoll = 30, balloon = 30, inverse = 60,
    jail = 60, control = 60, tiny = 60, jumpscare = 60, morph = 60,
}
local QuickLastCommandUse = {}

local function apNotify(msg)
    local env = getgenv and getgenv() or _G
    if type(env.DatShawnNotify) == "function" then
        pcall(env.DatShawnNotify, msg, true)
    else
        print("[AP Spammer] " .. tostring(msg))
    end
end

local function apAdminPanel()
    local gui = APLocal:FindFirstChildOfClass("PlayerGui") or APLocal:WaitForChild("PlayerGui", 10)
    if not gui then return nil end
    return gui:FindFirstChild("AdminPanel") or gui:WaitForChild("AdminPanel", 3)
end

local function quickFireClick(guiButton)
    if not guiButton then return false end
    if typeof(getconnections) == "function" then
        for _, signal in ipairs({guiButton.Activated, guiButton.MouseButton1Click}) do
            local ok, connections = pcall(getconnections, signal)
            if ok then
                for _, connection in ipairs(connections) do
                    if type(connection.Fire) == "function" then
                        pcall(function() connection:Fire() end)
                        return true
                    elseif type(connection.Function) == "function" then
                        pcall(connection.Function)
                        return true
                    end
                end
            end
        end
    end
    if typeof(firesignal) == "function" then
        pcall(firesignal, guiButton.MouseButton1Click)
        return true
    end
    return false
end

local function quickFindButton(root, wantedName)
    if not root then return nil end
    local direct = root:FindFirstChild(wantedName)
    if direct and direct:IsA("GuiButton") then return direct end
    for _, d in ipairs(root:GetDescendants()) do
        if d:IsA("GuiButton") and d.Name:lower() == wantedName:lower() then
            return d
        end
    end
end

local function quickFindPlayerButton(root, targetPlayer)
    if not root or not targetPlayer then return nil end
    for _, d in ipairs(root:GetDescendants()) do
        if d:IsA("GuiButton") then
            if d.Name == targetPlayer.Name then return d end
            local textObj = d:FindFirstChildWhichIsA("TextLabel", true)
            if textObj and (textObj.Text == targetPlayer.Name or textObj.Text == targetPlayer.DisplayName) then
                return d
            end
        end
    end
end

local function apVisibleChain(obj, stopAt)
    local node = obj
    while node and node ~= stopAt do
        if node:IsA("GuiObject") and node.Visible == false then return false end
        node = node.Parent
    end
    return true
end

local function apParseSeconds(text)
    if not text then return nil end
    local t = tostring(text):gsub("%s", "")
    if t == "" then return nil end
    local m, s = t:match("^(%d+):(%d+)$")
    if m then return (tonumber(m) or 0) * 60 + (tonumber(s) or 0) end
    local secs = t:match("^(%d+)s?$")
    if secs then return tonumber(secs) end
    return nil
end

-- Finds the live countdown shown on a command button ("48s", "1:20", ...).
-- Returns the seconds, or nil when nothing is counting down.
local function apButtonCountdown(cmdBtn)
    if not cmdBtn then return nil end

    local function visible(obj)
        return obj.Visible and apVisibleChain(obj, cmdBtn)
    end

    -- 1) dedicated timer label the game uses for cooldowns
    local timer = cmdBtn:FindFirstChild("Timer")
    if timer then
        local obj
        if timer:IsA("TextLabel") or timer:IsA("TextButton") or timer:IsA("TextBox") then
            obj = timer
        else
            obj = timer:FindFirstChildWhichIsA("TextLabel", true)
        end
        if obj and visible(obj) then
            local secs = apParseSeconds(obj.Text)
            if secs and secs > 0 then return secs end
        end
    end

    -- 2) anything drawn inside a CooldownFrame
    local frame = cmdBtn:FindFirstChild("CooldownFrame")
    if frame then
        if frame:IsA("TextLabel") or frame:IsA("TextButton") or frame:IsA("TextBox") then
            if visible(frame) then
                local secs = apParseSeconds(frame.Text)
                if secs and secs > 0 then return secs end
            end
        end
        for _, d in ipairs(frame:GetDescendants()) do
            if d:IsA("TextLabel") or d:IsA("TextButton") or d:IsA("TextBox") then
                if visible(d) then
                    local secs = apParseSeconds(d.Text)
                    if secs and secs > 0 then return secs end
                end
            end
        end
    end

    -- 3) a "12s" / "1:20" label anywhere else on the button
    --    (bare numbers are ignored here so keybind labels are not mistaken for timers)
    for _, d in ipairs(cmdBtn:GetDescendants()) do
        if d:IsA("TextLabel") or d:IsA("TextButton") or d:IsA("TextBox") then
            if visible(d) then
                local t = tostring(d.Text):gsub("%s", "")
                local secs
                local m, s = t:match("^(%d+):(%d+)$")
                if m then
                    secs = (tonumber(m) or 0) * 60 + (tonumber(s) or 0)
                elseif t:match("^(%d+)s$") then
                    secs = tonumber((t:gsub("s$", "")))
                end
                if secs and secs > 0 then return secs end
            end
        end
    end

    return nil
end

local function quickCooldownRemaining(commandName)
    local adminGui = apAdminPanel()
    if not adminGui then return 0 end
    local ok, scroll = pcall(function() return adminGui.AdminPanel.Content.ScrollingFrame end)
    local remoteRemaining = 0
    if ok and scroll then
        local cmdBtn = quickFindButton(scroll, commandName)
        remoteRemaining = apButtonCountdown(cmdBtn) or 0
    end
    local usedAt = QuickLastCommandUse[commandName]
    local localRemaining = usedAt and math.max(0, (QuickCommandCooldowns[commandName] or 0) - (os.clock() - usedAt)) or 0
    return math.max(remoteRemaining, localRemaining)
end

-- A CooldownFrame exists under every command button (hidden while the command is
-- ready), so presence alone means nothing. It only counts as "on cooldown" when it
-- is visible AND is actually displaying a countdown.
local function apCooldownFrameActive(cmdBtn)
    if not cmdBtn then return false end

    local frame = cmdBtn:FindFirstChild("CooldownFrame")
    if not frame then
        for _, d in ipairs(cmdBtn:GetDescendants()) do
            if d.Name == "CooldownFrame" and not d:FindFirstAncestor("Template") then
                frame = d
                break
            end
        end
    end
    if not frame then return false end
    if not apVisibleChain(frame, cmdBtn) then return false end

    if (frame:IsA("TextLabel") or frame:IsA("TextButton") or frame:IsA("TextBox"))
    and apParseSeconds(frame.Text) then
        return true
    end
    for _, d in ipairs(frame:GetDescendants()) do
        if d:IsA("TextLabel") or d:IsA("TextButton") or d:IsA("TextBox") then
            if d.Visible and apVisibleChain(d, cmdBtn) and apParseSeconds(d.Text) then
                return true
            end
        end
    end
    return false
end

-- Returns: onCooldown(bool), remaining(number), button(GuiButton?), frameActive(bool)
local function quickCommandState(commandName, scroll)
    if not scroll then
        local adminGui = apAdminPanel()
        if adminGui then
            local ok, s = pcall(function() return adminGui.AdminPanel.Content.ScrollingFrame end)
            if ok then scroll = s end
        end
    end

    local btn = quickFindButton(scroll, commandName)
    local counted = btn and apButtonCountdown(btn)
    local usedAt = QuickLastCommandUse[commandName]
    local localRemaining = usedAt and math.max(0, (QuickCommandCooldowns[commandName] or 0) - (os.clock() - usedAt)) or 0
    local remaining = math.max(counted or 0, localRemaining)

    local frameActive = false
    if not counted then
        frameActive = apCooldownFrameActive(btn)
        if frameActive and remaining < 1 then remaining = 1 end
    end

    return (remaining > 0), remaining, btn, frameActive
end

-- Shared 0.3s ticker that keeps the Quick AP buttons and the cooldown board fresh
local apTickerOn = false
local apStartTicker

local function runQuickCommand(targetPlayer, commandName, silent)
    local adminGui = apAdminPanel()
    if not adminGui then
        if not silent then apNotify("Admin Panel was not found") end
        return false
    end

    local remaining = quickCooldownRemaining(commandName)
    if remaining > 0 then
        if not silent then apNotify(commandName:upper() .. " cooldown: " .. math.ceil(remaining) .. "s") end
        return false
    end

    local _, cmdScroll = pcall(function() return adminGui.AdminPanel.Content.ScrollingFrame end)
    local cmdBtn = quickFindButton(cmdScroll, commandName) or quickFindButton(adminGui, commandName)
    if not cmdBtn or not quickFireClick(cmdBtn) then
        if not silent then apNotify(commandName:upper() .. " command unavailable") end
        return false
    end

    local _, profScroll = pcall(function() return adminGui.AdminPanel.Profiles.ScrollingFrame end)
    local playerBtn = quickFindPlayerButton(profScroll, targetPlayer) or quickFindPlayerButton(adminGui, targetPlayer)
    if playerBtn and quickFireClick(playerBtn) then
        QuickLastCommandUse[commandName] = os.clock()
        if not silent then apNotify(commandName:upper() .. " -> " .. targetPlayer.DisplayName) end
        return true
    elseif not silent then
        apNotify("Player button unavailable")
    end
    return false
end

local AP_COMMAND_ORDER = { "tiny", "rocket", "inverse", "ragdoll", "jail", "morph", "jumpscare" }

local AP_MODES = {
    Semi = { tiny = true, rocket = true, inverse = true },
    Full = { tiny = true, rocket = true, inverse = true, ragdoll = true, jail = true, morph = true, jumpscare = true },
}

local APSpamBusy = {}
local APDispatchBusy = false

local function runAPSpam(targetPlayer, mode)
    if not targetPlayer or targetPlayer == APLocal then return end
    if APSpamBusy[targetPlayer] then return end
    if APDispatchBusy then apNotify("AP batch already running"); return end

    local commands = AP_MODES[mode]
    if not commands then return end

    APSpamBusy[targetPlayer] = true
    APDispatchBusy = true
    task.spawn(function()
        local used = 0
        for _, cmd in ipairs(AP_COMMAND_ORDER) do
            if commands[cmd] then
                local ok, fired = pcall(runQuickCommand, targetPlayer, cmd, true)
                if ok and fired then used += 1 end
            end
        end
        APSpamBusy[targetPlayer] = nil
        APDispatchBusy = false
        apNotify(string.format("AP %s -> %s (%d)", mode:upper(), targetPlayer.DisplayName, used))
    end)
end

-- AP UI state
local APUI         = nil
local APPlayerList = nil
local APRowConns   = {}
local APDragConns  = {}
local APComboActive = false
local APComboUntil  = 0

local function apHandleRowClick(Player)
    local now = os.clock()
    if APComboActive and now <= APComboUntil then
        APComboActive = false
        APComboUntil  = 0
        apNotify("Combo -> FULL on " .. Player.DisplayName)
        runAPSpam(Player, "Full")
    else
        APComboActive = true
        APComboUntil  = now + AP_COMBO_WINDOW
        apNotify("Semi on " .. Player.DisplayName .. " - click again within 5s for FULL")
        runAPSpam(Player, "Semi")

        task.delay(AP_COMBO_WINDOW, function()
            if APComboActive and os.clock() >= APComboUntil then
                APComboActive = false
                APComboUntil  = 0
            end
        end)
    end
end

local function apThumbnail(userId)
    local ok, res = pcall(function()
        return APPlayers:GetUserThumbnailAsync(userId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size420x420)
    end)
    return ok and res or nil
end

local function apAddPlayerFrame(Player)
    if not APPlayerList then return end
    if Player == APLocal or APPlayerList:FindFirstChild(Player.Name) then return end

    local template = APPlayerList:FindFirstChild("Template")
    if not template then return end

    local pf = template:Clone()
    pf.Parent = APPlayerList
    pf.Name = Player.Name
    pf.Visible = true

    pf:WaitForChild("User", 9e9)
    pf:WaitForChild("Display", 9e9)

    pf.User.TextLabel.Text = Player.DisplayName
    pf.Display.TextLabel.Text = "@" .. Player.Name

    local thumb = apThumbnail(Player.UserId)
    if thumb then
        pf.ImageLabel.Image = thumb
    end

    pf.Bounds.MouseButton1Click:Connect(function()
        apHandleRowClick(Player)
    end)
end

local function apRemovePlayerFrame(Player)
    local f = APPlayerList and APPlayerList:FindFirstChild(Player.Name)
    if f then f:Destroy() end
end

local function apSetupDrag(frame)
    local dragHandle = frame:FindFirstChild("Drag")
    if not dragHandle then return end

    local dragging, dragOffset = false, Vector2.zero

    table.insert(APDragConns, dragHandle.InputBegan:Connect(function(input)
        if input.UserInputType ~= Enum.UserInputType.MouseButton1
        and input.UserInputType ~= Enum.UserInputType.Touch then return end

        dragging = true
        local mouse = Vector2.new(input.Position.X, input.Position.Y)
        local abs   = frame.AbsolutePosition
        dragOffset  = mouse - Vector2.new(abs.X, abs.Y)

        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end))

    table.insert(APDragConns, APUIS.InputChanged:Connect(function(input)
        if not dragging then return end
        if input.UserInputType ~= Enum.UserInputType.MouseMovement
        and input.UserInputType ~= Enum.UserInputType.Touch then return end
        local mouse = Vector2.new(input.Position.X, input.Position.Y) - dragOffset
        frame.Position = UDim2.new(0, mouse.X, 0, mouse.Y)
    end))
end

local function apMountParent()
    if gethui then
        local ok, hui = pcall(gethui)
        if ok and hui then return hui end
    end
    return game:GetService("CoreGui")
end

local function startAPSpammer()
    if APUI then return end
    if not game.GetObjects then
        apNotify("Executor is missing game:GetObjects")
        return
    end

    local ok, obj = pcall(function() return game:GetObjects(AP_OBJECT_ID)[1] end)
    if not ok or not obj then
        apNotify("AP Spammer UI failed to load")
        return
    end

    local frame = obj:FindFirstChild("Frame") or obj
    local list  = frame:FindFirstChild("PlayerList")
    if not list then
        apNotify("AP Spammer UI is missing PlayerList")
        obj:Destroy()
        return
    end

    APUI         = obj
    APPlayerList = list

    for _, p in ipairs(APPlayers:GetPlayers()) do apAddPlayerFrame(p) end

    table.insert(APRowConns, APPlayers.PlayerAdded:Connect(function(p) task.wait(0.1); apAddPlayerFrame(p) end))
    table.insert(APRowConns, APPlayers.PlayerRemoving:Connect(apRemovePlayerFrame))

    apSetupDrag(frame)
    obj.Parent = apMountParent()

    -- Row tint: busy / any cooldown / idle
    task.spawn(function()
        while APUI == obj and obj.Parent do
            for _, child in ipairs(list:GetChildren()) do
                if child:IsA("GuiObject") and child.Name ~= "Template" then
                    local target = APPlayers:FindFirstChild(child.Name)
                    if target then
                        local busy = APSpamBusy[target] or APDispatchBusy
                        local anyCD = false
                        for cmd in pairs(AP_MODES.Full) do
                            if quickCooldownRemaining(cmd) > 0 then anyCD = true; break end
                        end
                        if busy then
                            child.BackgroundColor3 = AP_ROW_BUSY
                        elseif anyCD then
                            child.BackgroundColor3 = AP_ROW_COOLDOWN
                        else
                            child.BackgroundColor3 = AP_ROW_IDLE
                        end
                    end
                end
            end
            task.wait(0.4)
        end
    end)
end

local function stopAPSpammer()
    for _, c in ipairs(APRowConns) do pcall(function() c:Disconnect() end) end
    table.clear(APRowConns)
    for _, c in ipairs(APDragConns) do pcall(function() c:Disconnect() end) end
    table.clear(APDragConns)
    if APUI then pcall(function() APUI:Destroy() end) end
    APUI         = nil
    APPlayerList = nil
    APComboActive = false
    APComboUntil  = 0
end

-- ==========================================
-- QUICK AP (one click = one command on that player)
-- Buttons per player: Tiny, Rocket, Inverse, Balloon, Jail, Ragdoll
-- ==========================================

local QUICK_AP_W      = 320
local QUICK_AP_ROW_H  = 60
local QUICK_AP_GAP    = 4
local QUICK_AP_COL_BG      = Color3.fromRGB(34, 34, 38)
local QUICK_AP_COL_BG_CD   = Color3.fromRGB(20, 20, 22)
local QUICK_AP_COL_TEXT    = Color3.fromRGB(228, 228, 234)
local QUICK_AP_COL_TEXT_CD = Color3.fromRGB(96, 96, 104)

local QUICK_AP_COMMANDS = {
    { key = "tiny",    label = "Tiny",    accent = Color3.fromRGB(120, 205, 255) },
    { key = "rocket",  label = "Rocket",  accent = Color3.fromRGB(255, 150, 90)  },
    { key = "inverse", label = "Inverse", accent = Color3.fromRGB(180, 135, 255) },
    { key = "balloon", label = "Balloon", accent = Color3.fromRGB(255, 120, 180) },
    { key = "jail",    label = "Jail",    accent = Color3.fromRGB(255, 205, 90)  },
    { key = "ragdoll", label = "Ragdoll", accent = Color3.fromRGB(120, 235, 165) },
}

local QuickAP = {
    gui        = nil,
    panel      = nil,
    list       = nil,
    empty      = nil,
    countLbl   = nil,
    rows       = {},
    btns       = {},
    conns      = {},
    dragConns  = {},
    nextOrder  = 1,
    position   = UDim2.new(0.5, -(QUICK_AP_W / 2), 0.5, -150),
}

local QuickAPLastFired = {}

local function qCorner(obj, r)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, r or 4)
    c.Parent = obj
    return c
end

local function qStroke(obj, color, transparency)
    local s = Instance.new("UIStroke")
    s.Color = color or Color3.fromRGB(44, 44, 48)
    s.Thickness = 1
    s.Transparency = transparency or 0
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Parent = obj
    return s
end

local function quickAPRun(pl, cmd)
    if not pl or pl == APLocal then return end
    local key = pl.UserId .. ":" .. cmd
    local now = os.clock()
    if QuickAPLastFired[key] and now - QuickAPLastFired[key] < 0.35 then return end
    QuickAPLastFired[key] = now
    task.spawn(runQuickCommand, pl, cmd, false)
end

local function quickAPLayout()
    local count = 0
    for _ in pairs(QuickAP.rows) do count += 1 end

    local listH = math.clamp(count * (QUICK_AP_ROW_H + QUICK_AP_GAP) + QUICK_AP_GAP, 64, 336)
    if QuickAP.list then
        QuickAP.list.Size = UDim2.new(1, -12, 0, listH)
    end
    if QuickAP.panel then
        QuickAP.panel.Size = UDim2.fromOffset(QUICK_AP_W, 30 + listH + 8)
    end
    if QuickAP.empty then
        QuickAP.empty.Visible = (count == 0)
    end
    if QuickAP.countLbl then
        QuickAP.countLbl.Text = count .. (count == 1 and " player" or " players")
    end
end

local function quickAPResetButton(entry)
    entry.button:SetAttribute("Cd", false)
    entry.button.BackgroundColor3 = QUICK_AP_COL_BG
    entry.button.TextColor3   = QUICK_AP_COL_TEXT
    entry.button.Text         = entry.label
    entry.stroke.Color        = Color3.fromRGB(56, 56, 62)
    entry.stroke.Transparency = 0.15
    entry.state = false
    entry.shown = entry.label
end

local function quickAPAddRow(pl)
    if not QuickAP.list or not pl or pl == APLocal then return end
    if QuickAP.rows[pl] then return end

    local row = Instance.new("Frame")
    row.Name = pl.Name
    row.LayoutOrder = QuickAP.nextOrder
    QuickAP.nextOrder += 1
    row.Size = UDim2.new(1, 0, 0, QUICK_AP_ROW_H)
    row.BackgroundColor3 = Color3.fromRGB(24, 24, 26)
    row.BorderSizePixel = 0
    row.Parent = QuickAP.list
    qCorner(row, 7)
    qStroke(row, Color3.fromRGB(44, 44, 49), 0.1)

    local avatar = Instance.new("ImageLabel")
    avatar.Name = "Avatar"
    avatar.Position = UDim2.fromOffset(8, 6)
    avatar.Size = UDim2.fromOffset(28, 28)
    avatar.BackgroundColor3 = Color3.fromRGB(32, 32, 36)
    avatar.BorderSizePixel = 0
    avatar.Parent = row
    qCorner(avatar, 8)

    local nameLbl = Instance.new("TextLabel")
    nameLbl.BackgroundTransparency = 1
    nameLbl.Position = UDim2.fromOffset(44, 6)
    nameLbl.Size = UDim2.new(1, -52, 0, 14)
    nameLbl.Font = Enum.Font.GothamBold
    nameLbl.Text = pl.DisplayName
    nameLbl.TextColor3 = Color3.fromRGB(240, 240, 245)
    nameLbl.TextSize = 12
    nameLbl.TextXAlignment = Enum.TextXAlignment.Left
    nameLbl.TextTruncate = Enum.TextTruncate.AtEnd
    nameLbl.Parent = row

    local userLbl = Instance.new("TextLabel")
    userLbl.BackgroundTransparency = 1
    userLbl.Position = UDim2.fromOffset(44, 21)
    userLbl.Size = UDim2.new(1, -52, 0, 12)
    userLbl.Font = Enum.Font.GothamMedium
    userLbl.Text = "@" .. pl.Name
    userLbl.TextColor3 = Color3.fromRGB(116, 116, 126)
    userLbl.TextSize = 10
    userLbl.TextXAlignment = Enum.TextXAlignment.Left
    userLbl.TextTruncate = Enum.TextTruncate.AtEnd
    userLbl.Parent = row

    local btnRow = Instance.new("Frame")
    btnRow.Name = "Buttons"
    btnRow.BackgroundTransparency = 1
    btnRow.Position = UDim2.fromOffset(8, 36)
    btnRow.Size = UDim2.new(1, -16, 0, 20)
    btnRow.Parent = row

    local layout = Instance.new("UIListLayout")
    layout.FillDirection = Enum.FillDirection.Horizontal
    layout.Padding = UDim.new(0, 3)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = btnRow

    local store = {}
    QuickAP.btns[pl] = store

    for i, cmd in ipairs(QUICK_AP_COMMANDS) do
        local btn = Instance.new("TextButton")
        btn.Name = cmd.key
        btn.LayoutOrder = i
        btn.Size = UDim2.fromOffset(48, 20)
        btn.BackgroundColor3 = QUICK_AP_COL_BG
        btn.BorderSizePixel = 0
        btn.AutoButtonColor = false
        btn.Font = Enum.Font.GothamBold
        btn.Text = cmd.label
        btn.TextSize = 9
        btn.TextColor3 = QUICK_AP_COL_TEXT
        btn.Parent = btnRow
        qCorner(btn, 5)
        local stroke = qStroke(btn, Color3.fromRGB(56, 56, 62), 0.15)

        local entry = {
            button = btn,
            stroke = stroke,
            label  = cmd.label,
            accent = cmd.accent,
            state  = false,
            shown  = cmd.label,
        }
        store[cmd.key] = entry
        quickAPResetButton(entry)

        btn.MouseEnter:Connect(function()
            if entry.state then return end
            btn.BackgroundColor3 = cmd.accent:Lerp(Color3.fromRGB(18, 18, 20), 0.74)
            stroke.Color = cmd.accent
            stroke.Transparency = 0.35
        end)

        btn.MouseLeave:Connect(function()
            if entry.state then return end
            btn.BackgroundColor3 = QUICK_AP_COL_BG
            stroke.Color = Color3.fromRGB(56, 56, 62)
            stroke.Transparency = 0.15
        end)

        btn.MouseButton1Down:Connect(function()
            if entry.state then return end
            btn.BackgroundColor3 = cmd.accent:Lerp(Color3.fromRGB(0, 0, 0), 0.45)
        end)

        btn.MouseButton1Up:Connect(function()
            if entry.state then return end
            btn.BackgroundColor3 = QUICK_AP_COL_BG
        end)

        btn.MouseButton1Click:Connect(function()
            quickAPRun(pl, cmd.key)
        end)
    end

    row.MouseEnter:Connect(function()
        row.BackgroundColor3 = Color3.fromRGB(31, 31, 35)
    end)
    row.MouseLeave:Connect(function()
        row.BackgroundColor3 = Color3.fromRGB(24, 24, 26)
    end)

    QuickAP.rows[pl] = row
    quickAPLayout()

    task.spawn(function()
        local ok, img = pcall(function()
            return APPlayers:GetUserThumbnailAsync(pl.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
        end)
        if ok and img and QuickAP.rows[pl] == row and avatar.Parent then
            avatar.Image = img
        end
    end)
end

local function quickAPRemoveRow(pl)
    local row = QuickAP.rows[pl]
    if row then
        row:Destroy()
        QuickAP.rows[pl] = nil
    end
    QuickAP.btns[pl] = nil
    quickAPLayout()
end

-- Paints every Quick AP button from the game's live CooldownFrame state
local function quickAPApplyStates()
    if not QuickAP.gui or not QuickAP.list then return end

    local adminGui = apAdminPanel()
    local scroll
    if adminGui then
        local ok, s = pcall(function() return adminGui.AdminPanel.Content.ScrollingFrame end)
        if ok then scroll = s end
    end

    local states = {}
    for _, cmd in ipairs(QUICK_AP_COMMANDS) do
        local on, remaining, _, hasFrame = quickCommandState(cmd.key, scroll)
        states[cmd.key] = { on = on, remaining = remaining, hasFrame = hasFrame }
    end

    for pl, store in pairs(QuickAP.btns) do
        if QuickAP.rows[pl] then
            for _, cmd in ipairs(QUICK_AP_COMMANDS) do
                local entry = store[cmd.key]
                local st = states[cmd.key]
                if entry and st then
                    if st.on then
                        local text
                        if st.remaining <= 1.05 then
                            text = "CD"
                        else
                            text = math.ceil(st.remaining) .. "s"
                        end
                        if entry.state ~= true or entry.shown ~= text then
                            entry.state = true
                            entry.shown = text
                            entry.button:SetAttribute("Cd", true)
                            entry.button.BackgroundColor3 = QUICK_AP_COL_BG_CD
                            entry.button.TextColor3 = QUICK_AP_COL_TEXT_CD
                            entry.button.Text = text
                            entry.stroke.Color = Color3.fromRGB(44, 44, 48)
                            entry.stroke.Transparency = 0.6
                        end
                    elseif entry.state then
                        quickAPResetButton(entry)
                    end
                end
            end
        end
    end
end

local function quickAPBindDrag(panel, ...)
    local dragging, offset = false, Vector2.zero
    local handles = { ... }

    for _, handle in ipairs(handles) do
        table.insert(QuickAP.dragConns, handle.InputBegan:Connect(function(input)
            if input.UserInputType ~= Enum.UserInputType.MouseButton1
            and input.UserInputType ~= Enum.UserInputType.Touch then return end

            dragging = true
            local mouse = Vector2.new(input.Position.X, input.Position.Y)
            local abs   = panel.AbsolutePosition
            offset      = mouse - Vector2.new(abs.X, abs.Y)

            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end))
    end

    table.insert(QuickAP.dragConns, APUIS.InputChanged:Connect(function(input)
        if not dragging then return end
        if input.UserInputType ~= Enum.UserInputType.MouseMovement
        and input.UserInputType ~= Enum.UserInputType.Touch then return end
        local mouse = Vector2.new(input.Position.X, input.Position.Y) - offset
        panel.Position = UDim2.fromOffset(mouse.X, mouse.Y)
        QuickAP.position = panel.Position
    end))
end

local function startQuickAP()
    if QuickAP.gui then return end

    local gui = Instance.new("ScreenGui")
    gui.Name = "QuickAP_" .. tostring(math.random(100000, 999999))
    gui.ResetOnSpawn = false
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.IgnoreGuiInset = true
    gui.DisplayOrder = 2147483000
    gui.Parent = apMountParent()

    local panel = Instance.new("Frame")
    panel.Name = "Panel"
    panel.Position = QuickAP.position
    panel.Size = UDim2.fromOffset(QUICK_AP_W, 104)
    panel.BackgroundColor3 = Color3.fromRGB(14, 14, 15)
    panel.BorderSizePixel = 0
    panel.ClipsDescendants = true
    panel.Parent = gui
    qCorner(panel, 8)
    qStroke(panel, Color3.fromRGB(48, 48, 52), 0)

    local titleBar = Instance.new("Frame")
    titleBar.Name = "TitleBar"
    titleBar.Size = UDim2.new(1, 0, 0, 26)
    titleBar.BackgroundColor3 = Color3.fromRGB(20, 20, 22)
    titleBar.BorderSizePixel = 0
    titleBar.Parent = panel

    local trim = Instance.new("Frame")
    trim.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    trim.BorderSizePixel = 0
    trim.Position = UDim2.fromOffset(0, 0)
    trim.Size = UDim2.new(1, 0, 0, 1)
    trim.BackgroundTransparency = 0.55
    trim.Parent = panel

    local title = Instance.new("TextLabel")
    title.BackgroundTransparency = 1
    title.Position = UDim2.fromOffset(10, 0)
    title.Size = UDim2.new(1, -20, 1, 0)
    title.Font = Enum.Font.GothamBold
    title.Text = "QUICK AP"
    title.TextColor3 = Color3.fromRGB(240, 240, 244)
    title.TextSize = 12
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = titleBar

    local hint = Instance.new("TextLabel")
    hint.BackgroundTransparency = 1
    hint.AnchorPoint = Vector2.new(1, 0.5)
    hint.Position = UDim2.new(1, -10, 0.5, 0)
    hint.Size = UDim2.fromOffset(120, 14)
    hint.Font = Enum.Font.GothamMedium
    hint.Text = "0 players"
    hint.TextColor3 = Color3.fromRGB(120, 120, 128)
    hint.TextSize = 9
    hint.TextXAlignment = Enum.TextXAlignment.Right
    hint.Parent = titleBar

    local list = Instance.new("ScrollingFrame")
    list.Name = "List"
    list.Position = UDim2.new(0, 6, 0, 30)
    list.Size = UDim2.new(1, -12, 0, 64)
    list.BackgroundTransparency = 1
    list.BorderSizePixel = 0
    list.ScrollBarThickness = 2
    list.ScrollBarImageColor3 = Color3.fromRGB(70, 70, 76)
    list.ScrollBarImageTransparency = 0.2
    list.CanvasSize = UDim2.new(0, 0, 0, 0)
    list.AutomaticCanvasSize = Enum.AutomaticSize.Y
    list.ScrollingDirection = Enum.ScrollingDirection.Y
    list.Parent = panel

    local listLayout = Instance.new("UIListLayout")
    listLayout.Padding = UDim.new(0, QUICK_AP_GAP)
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.Parent = list

    local empty = Instance.new("TextLabel")
    empty.Name = "Empty"
    empty.BackgroundTransparency = 1
    empty.Position = UDim2.new(0, 6, 0, 36)
    empty.Size = UDim2.new(1, -12, 0, 26)
    empty.Font = Enum.Font.GothamMedium
    empty.Text = "waiting for players..."
    empty.TextColor3 = Color3.fromRGB(110, 110, 118)
    empty.TextSize = 11
    empty.Parent = panel

    QuickAP.gui      = gui
    QuickAP.panel    = panel
    QuickAP.list     = list
    QuickAP.empty    = empty
    QuickAP.countLbl = hint

    quickAPBindDrag(panel, titleBar, title, hint)

    for _, p in ipairs(APPlayers:GetPlayers()) do quickAPAddRow(p) end

    table.insert(QuickAP.conns, APPlayers.PlayerAdded:Connect(function(p)
        task.wait(0.1)
        quickAPAddRow(p)
    end))
    table.insert(QuickAP.conns, APPlayers.PlayerRemoving:Connect(quickAPRemoveRow))

    quickAPLayout()
    quickAPApplyStates()
    if apStartTicker then apStartTicker() end
end

local function stopQuickAP()
    for _, c in ipairs(QuickAP.conns) do pcall(function() c:Disconnect() end) end
    table.clear(QuickAP.conns)
    for _, c in ipairs(QuickAP.dragConns) do pcall(function() c:Disconnect() end) end
    table.clear(QuickAP.dragConns)
    if QuickAP.gui then pcall(function() QuickAP.gui:Destroy() end) end
    QuickAP.gui      = nil
    QuickAP.panel    = nil
    QuickAP.list     = nil
    QuickAP.empty    = nil
    QuickAP.countLbl = nil
    QuickAP.nextOrder = 1
    table.clear(QuickAP.rows)
    table.clear(QuickAP.btns)
    table.clear(QuickAPLastFired)
end

-- ==========================================
-- COMMAND COOLDOWNS (small live status board)
-- On cooldown = the game has a "CooldownFrame" child under that
-- command button inside AdminPanel.AdminPanel.Content.ScrollingFrame
-- ==========================================

local CD_W        = 268
local CD_CELL_W   = 126
local CD_CELL_H   = 22
local CD_GAP      = 4
local CD_COL_BG   = Color3.fromRGB(24, 24, 26)
local CD_COL_NA   = Color3.fromRGB(112, 112, 120)
local CD_COL_READY = Color3.fromRGB(120, 225, 150)
local CD_COL_BUSY  = Color3.fromRGB(240, 112, 112)

local CD_COMMANDS = {
    "balloon", "control", "inverse", "jail", "jumpscare",
    "morph", "nightvision", "ragdoll", "rocket", "tiny",
}

local CD_GRID_ROWS = math.ceil(#CD_COMMANDS / 2)
local CD_GRID_H    = CD_GRID_ROWS * CD_CELL_H + (CD_GRID_ROWS - 1) * CD_GAP

local Cooldowns = {
    gui       = nil,
    panel     = nil,
    grid      = nil,
    summary   = nil,
    rows      = {},
    dragConns = {},
    position  = UDim2.new(0.5, 176, 0.5, -120),
}

local function cooldownRefresh()
    if not Cooldowns.gui then return end

    local adminGui = apAdminPanel()
    local scroll
    if adminGui then
        local ok, s = pcall(function() return adminGui.AdminPanel.Content.ScrollingFrame end)
        if ok then scroll = s end
    end

    local ready = 0
    for _, name in ipairs(CD_COMMANDS) do
        local row = Cooldowns.rows[name]
        if row then
            local on, remaining, btn, hasFrame = quickCommandState(name, scroll)
            local text, color
            if not btn then
                text, color = "N/A", CD_COL_NA
            elseif on then
                if remaining <= 1.05 then
                    text = "CD"
                else
                    text = math.ceil(remaining) .. "s"
                end
                color = CD_COL_BUSY
            else
                ready += 1
                text, color = "READY", CD_COL_READY
            end

            if row.shown ~= text then
                row.shown = text
                row.status.Text = text
                row.status.TextColor3 = color
                row.dot.BackgroundColor3 = color
            end
        end
    end

    if Cooldowns.summary then
        Cooldowns.summary.Text = ready .. "/" .. #CD_COMMANDS .. " ready"
    end
end

local function cooldownAddRow(name, index)
    local cell = Instance.new("Frame")
    cell.Name = name
    cell.LayoutOrder = index
    cell.BackgroundColor3 = CD_COL_BG
    cell.BorderSizePixel = 0
    cell.Parent = Cooldowns.grid
    qCorner(cell, 5)
    qStroke(cell, Color3.fromRGB(42, 42, 47), 0.25)

    local dot = Instance.new("Frame")
    dot.Name = "Dot"
    dot.AnchorPoint = Vector2.new(0, 0.5)
    dot.Position = UDim2.new(0, 8, 0.5, 0)
    dot.Size = UDim2.fromOffset(6, 6)
    dot.BackgroundColor3 = CD_COL_NA
    dot.BorderSizePixel = 0
    dot.Parent = cell
    qCorner(dot, 3)

    local label = Instance.new("TextLabel")
    label.BackgroundTransparency = 1
    label.Position = UDim2.fromOffset(20, 0)
    label.Size = UDim2.new(1, -64, 1, 0)
    label.Font = Enum.Font.GothamMedium
    label.Text = name
    label.TextColor3 = Color3.fromRGB(226, 226, 232)
    label.TextSize = 10
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextTruncate = Enum.TextTruncate.AtEnd
    label.Parent = cell

    local status = Instance.new("TextLabel")
    status.BackgroundTransparency = 1
    status.AnchorPoint = Vector2.new(1, 0.5)
    status.Position = UDim2.new(1, -8, 0.5, 0)
    status.Size = UDim2.fromOffset(40, 12)
    status.Font = Enum.Font.GothamBold
    status.Text = "--"
    status.TextColor3 = CD_COL_NA
    status.TextSize = 9
    status.TextXAlignment = Enum.TextXAlignment.Right
    status.Parent = cell

    Cooldowns.rows[name] = { cell = cell, dot = dot, status = status, shown = "--" }
end

local function cdBindDrag(panel, ...)
    local dragging, offset = false, Vector2.zero
    local handles = { ... }

    for _, handle in ipairs(handles) do
        table.insert(Cooldowns.dragConns, handle.InputBegan:Connect(function(input)
            if input.UserInputType ~= Enum.UserInputType.MouseButton1
            and input.UserInputType ~= Enum.UserInputType.Touch then return end

            dragging = true
            local mouse = Vector2.new(input.Position.X, input.Position.Y)
            local abs   = panel.AbsolutePosition
            offset      = mouse - Vector2.new(abs.X, abs.Y)

            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end))
    end

    table.insert(Cooldowns.dragConns, APUIS.InputChanged:Connect(function(input)
        if not dragging then return end
        if input.UserInputType ~= Enum.UserInputType.MouseMovement
        and input.UserInputType ~= Enum.UserInputType.Touch then return end
        local mouse = Vector2.new(input.Position.X, input.Position.Y) - offset
        panel.Position = UDim2.fromOffset(mouse.X, mouse.Y)
        Cooldowns.position = panel.Position
    end))
end

local function startCooldowns()
    if Cooldowns.gui then return end

    local gui = Instance.new("ScreenGui")
    gui.Name = "CmdCooldowns_" .. tostring(math.random(100000, 999999))
    gui.ResetOnSpawn = false
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.IgnoreGuiInset = true
    gui.DisplayOrder = 2147482999
    gui.Parent = apMountParent()

    local panel = Instance.new("Frame")
    panel.Name = "Panel"
    panel.Position = Cooldowns.position
    panel.Size = UDim2.fromOffset(CD_W, 26 + 6 + CD_GRID_H + 8)
    panel.BackgroundColor3 = Color3.fromRGB(14, 14, 15)
    panel.BorderSizePixel = 0
    panel.ClipsDescendants = true
    panel.Parent = gui
    qCorner(panel, 8)
    qStroke(panel, Color3.fromRGB(48, 48, 52), 0)

    local titleBar = Instance.new("Frame")
    titleBar.Name = "TitleBar"
    titleBar.Size = UDim2.new(1, 0, 0, 26)
    titleBar.BackgroundColor3 = Color3.fromRGB(20, 20, 22)
    titleBar.BorderSizePixel = 0
    titleBar.Parent = panel

    local trim = Instance.new("Frame")
    trim.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    trim.BorderSizePixel = 0
    trim.Size = UDim2.new(1, 0, 0, 1)
    trim.BackgroundTransparency = 0.55
    trim.Parent = panel

    local title = Instance.new("TextLabel")
    title.BackgroundTransparency = 1
    title.Position = UDim2.fromOffset(10, 0)
    title.Size = UDim2.new(1, -20, 1, 0)
    title.Font = Enum.Font.GothamBold
    title.Text = "COOLDOWNS"
    title.TextColor3 = Color3.fromRGB(240, 240, 244)
    title.TextSize = 12
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = titleBar

    local summary = Instance.new("TextLabel")
    summary.BackgroundTransparency = 1
    summary.AnchorPoint = Vector2.new(1, 0.5)
    summary.Position = UDim2.new(1, -10, 0.5, 0)
    summary.Size = UDim2.fromOffset(120, 14)
    summary.Font = Enum.Font.GothamMedium
    summary.Text = "--/" .. #CD_COMMANDS .. " ready"
    summary.TextColor3 = Color3.fromRGB(120, 120, 128)
    summary.TextSize = 9
    summary.TextXAlignment = Enum.TextXAlignment.Right
    summary.Parent = titleBar

    local grid = Instance.new("Frame")
    grid.Name = "Grid"
    grid.Position = UDim2.new(0, 6, 0, 32)
    grid.Size = UDim2.new(1, -12, 0, CD_GRID_H)
    grid.BackgroundTransparency = 1
    grid.Parent = panel

    local gridLayout = Instance.new("UIGridLayout")
    gridLayout.CellSize = UDim2.fromOffset(CD_CELL_W, CD_CELL_H)
    gridLayout.CellPadding = UDim2.fromOffset(CD_GAP, CD_GAP)
    gridLayout.SortOrder = Enum.SortOrder.LayoutOrder
    gridLayout.FillDirectionMaxCells = 2
    gridLayout.Parent = grid

    Cooldowns.gui     = gui
    Cooldowns.panel   = panel
    Cooldowns.grid    = grid
    Cooldowns.summary = summary

    for i, name in ipairs(CD_COMMANDS) do
        cooldownAddRow(name, i)
    end

    cdBindDrag(panel, titleBar, title, summary)

    cooldownRefresh()
    if apStartTicker then apStartTicker() end
end

local function stopCooldowns()
    for _, c in ipairs(Cooldowns.dragConns) do pcall(function() c:Disconnect() end) end
    table.clear(Cooldowns.dragConns)
    if Cooldowns.gui then pcall(function() Cooldowns.gui:Destroy() end) end
    Cooldowns.gui     = nil
    Cooldowns.panel   = nil
    Cooldowns.grid    = nil
    Cooldowns.summary = nil
    table.clear(Cooldowns.rows)
end

apStartTicker = function()
    if apTickerOn then return end
    apTickerOn = true

    task.spawn(function()
        while apTickerOn do
            local okA, errA = pcall(quickAPApplyStates)
            if not okA then warn("[Quick AP] " .. tostring(errA)) end
            local okB, errB = pcall(cooldownRefresh)
            if not okB then warn("[Cooldowns] " .. tostring(errB)) end

            if not QuickAP.gui and not Cooldowns.gui then
                apTickerOn = false
                break
            end
            task.wait(0.3)
        end
    end)
end

Admin:addToggle({
    text = "AP Spammer",
    state = false
}, function(state)
    if state then
        startAPSpammer()
    else
        stopAPSpammer()
    end
end)

Admin:addToggle({
    text = "Quick AP",
    state = false
}, function(state)
    if state then
        startQuickAP()
    else
        stopQuickAP()
    end
end)

Admin:addToggle({
    text = "Command Cooldowns",
    state = false
}, function(state)
    if state then
        startCooldowns()
    else
        stopCooldowns()
    end
end)

-- ==========================================
-- FPS OPTIMIZER (ported from aurora)
-- Level 1 = FPS Optimizer, Level 2 = Extreme FPS Optimizer
-- Reversible: originals are saved per instance and restored on toggle off
-- ==========================================

local FPSOptimizer = {
    level   = 0,
    saved   = setmetatable({}, { __mode = "k" }),
    anims   = {},
    conns   = {},
    quality = nil,
    qualitySvc = nil,
}

local FPS_ANIM_NAMES = {
    walk = true, run = true,
    walkanim = true, runanim = true,
    walkanimation = true, runanimation = true,
}

local FPS_ANIM_IDS = {
    ["180426354"] = true,
    ["507777826"] = true,
    ["507767714"] = true,
}

local function fpsNotify(msg)
    local env = getgenv and getgenv() or _G
    if type(env.DatShawnNotify) == "function" then
        pcall(env.DatShawnNotify, msg, true)
    else
        print("[FPS] " .. tostring(msg))
    end
end

local function fpsSet(instance, property, value)
    local props = FPSOptimizer.saved[instance]
    if not props then
        props = {}
        FPSOptimizer.saved[instance] = props
    end

    if props[property] == nil then
        local ok, original = pcall(function() return instance[property] end)
        if not ok then return false end
        props[property] = original
    end

    return pcall(function() instance[property] = value end)
end

local function fpsRestore(instance)
    local props = FPSOptimizer.saved[instance]
    if not props then return end
    FPSOptimizer.saved[instance] = nil
    for property, value in pairs(props) do
        pcall(function() instance[property] = value end)
    end
end

local function fpsAnimationId(anim)
    if not anim then return nil end
    local id = anim.AnimationId or ""
    return id:match("rbxassetid://(%d+)")
        or id:match("[?&]id=(%d+)")
        or id:match("^(%d+)$")
end

-- keeps only walk/run (and emote/walk assets) alive in extreme mode
local function fpsTrackAllowed(animator, track)
    local anim = track and track.Animation
    if not anim then return false end

    local character = animator.Parent
    if not character then return false end

    local id = fpsAnimationId(anim)
    local animate = character:FindFirstChild("Animate")
    if animate then
        for _, name in ipairs({ "walk", "run" }) do
            local node = animate:FindFirstChild(name)
            if node then
                if node == anim then return true end
                if node:IsA("Animation") and id and fpsAnimationId(node) == id then return true end
                for _, d in ipairs(node:GetDescendants()) do
                    if d:IsA("Animation") and (d == anim or (id and fpsAnimationId(d) == id)) then
                        return true
                    end
                end
            end
        end
    end

    if FPS_ANIM_NAMES[string.lower(anim.Name)] then return true end
    if id and FPS_ANIM_IDS[id] then return true end
    return false
end

local function fpsUnhookAnimator(animator)
    local entry = FPSOptimizer.anims[animator]
    if not entry then return end
    FPSOptimizer.anims[animator] = nil
    for _, conn in pairs(entry) do
        pcall(function() conn:Disconnect() end)
    end
end

local function fpsHookAnimator(animator)
    if FPSOptimizer.anims[animator] then return end

    local entry = {}

    local okPlayed, played = pcall(function()
        return animator.AnimationPlayed:Connect(function(track)
            if FPSOptimizer.level == 2 and animator:IsDescendantOf(workspace) then
                if not fpsTrackAllowed(animator, track) then
                    pcall(function() track:Stop(0) end)
                end
            else
                fpsUnhookAnimator(animator)
            end
        end)
    end)
    if okPlayed then entry.played = played end

    local okAncestry, ancestry = pcall(function()
        return animator.AncestryChanged:Connect(function()
            if not animator:IsDescendantOf(workspace) then
                fpsUnhookAnimator(animator)
            end
        end)
    end)
    if okAncestry then entry.ancestry = ancestry end

    FPSOptimizer.anims[animator] = entry

    local okTracks, tracks = pcall(function()
        return animator:GetPlayingAnimationTracks()
    end)
    if okTracks then
        for _, track in ipairs(tracks) do
            if not fpsTrackAllowed(animator, track) then
                pcall(function() track:Stop(0) end)
            end
        end
    end
end

local function fpsApply(instance)
    if FPSOptimizer.level == 0 then return end
    if not instance or not instance.Parent then return end
    if instance:GetAttribute("__AH") then return end

    if instance:IsA("BasePart") then
        fpsSet(instance, "CastShadow", false)
        if FPSOptimizer.level == 2 then
            fpsSet(instance, "Material", Enum.Material.SmoothPlastic)
            fpsSet(instance, "Reflectance", 0)
        end
    elseif instance:IsA("ParticleEmitter")
        or instance:IsA("Trail")
        or instance:IsA("Beam")
        or instance:IsA("Smoke")
        or instance:IsA("Fire")
        or instance:IsA("Sparkles")
        or instance:IsA("PostEffect") then
        fpsSet(instance, "Enabled", false)
    elseif FPSOptimizer.level == 2 and (instance:IsA("Decal") or instance:IsA("Texture")) then
        fpsSet(instance, "Transparency", 1)
    elseif FPSOptimizer.level == 2 and instance:IsA("Animator") then
        if instance:IsDescendantOf(workspace) then
            fpsHookAnimator(instance)
        end
    end
end

-- chunked so a huge map never freezes the client
local function fpsApplyTree(root)
    local list = root:GetDescendants()
    for i = 1, #list do
        if FPSOptimizer.level == 0 then return end
        fpsApply(list[i])
        if i % 400 == 0 then task.wait() end
    end
end

local function fpsStart(level)
    local Lighting = game:GetService("Lighting")
    local world = workspace

    FPSOptimizer.level = level

    fpsSet(Lighting, "GlobalShadows", false)
    fpsSet(Lighting, "EnvironmentSpecularScale", 0)

    if level == 2 then
        fpsSet(Lighting, "EnvironmentDiffuseScale", 0)

        pcall(function()
            game:GetService("MaterialService"):SetBaseMaterialOverride(Enum.Material.SmoothPlastic, "")
        end)

        if type(UserSettings) == "function" then
            local ok, svc, previous = pcall(function()
                local settings = UserSettings():GetService("UserGameSettings")
                local saved = settings.SavedQualityLevel
                settings.SavedQualityLevel = Enum.SavedQualitySetting.QualityLevel1
                return settings, saved
            end)
            if ok then
                FPSOptimizer.qualitySvc = svc
                FPSOptimizer.quality = previous
            end
        end
    end

    fpsApplyTree(world)
    fpsApplyTree(Lighting)

    if not FPSOptimizer.conns.world then
        FPSOptimizer.conns.world = world.DescendantAdded:Connect(function(instance)
            if FPSOptimizer.level > 0 then fpsApply(instance) end
        end)
        FPSOptimizer.conns.lighting = Lighting.DescendantAdded:Connect(function(instance)
            if FPSOptimizer.level > 0 then fpsApply(instance) end
        end)
    end
end

local function fpsStop()
    local wasExtreme = FPSOptimizer.level == 2
    FPSOptimizer.level = 0

    if FPSOptimizer.conns.world then
        pcall(function() FPSOptimizer.conns.world:Disconnect() end)
        FPSOptimizer.conns.world = nil
    end
    if FPSOptimizer.conns.lighting then
        pcall(function() FPSOptimizer.conns.lighting:Disconnect() end)
        FPSOptimizer.conns.lighting = nil
    end

    for animator in pairs(FPSOptimizer.anims) do
        fpsUnhookAnimator(animator)
    end

    if wasExtreme then
        pcall(function()
            game:GetService("MaterialService"):SetBaseMaterialOverride(Enum.Material.SmoothPlastic, "")
        end)
    end

    if FPSOptimizer.qualitySvc and FPSOptimizer.quality then
        pcall(function()
            FPSOptimizer.qualitySvc.SavedQualityLevel = FPSOptimizer.quality
        end)
    end
    FPSOptimizer.qualitySvc = nil
    FPSOptimizer.quality = nil

    for instance in pairs(FPSOptimizer.saved) do
        fpsRestore(instance)
    end
end

local function fpsSetLevel(level)
    if FPSOptimizer.level == level then return end
    fpsStop()
    if level > 0 then
        fpsStart(level)
        fpsNotify(level == 2 and "Extreme FPS Optimizer on" or "FPS Optimizer on")
    else
        fpsNotify("FPS Optimizer off")
    end
end

-- ==========================================
-- AUTO STEAL (ported from aurora)
--   Nearest  = closest stealable animal on another player's plot
--   Priority = first entry of your priority list ("plotName|slot") that is stealable
--   Stealable = enemy plot + enabled ProximityPrompt with ActionText "Steal"
-- ==========================================

local AS_RS      = game:GetService("ReplicatedStorage")
local AS_Players = game:GetService("Players")
local AS_Local   = AS_Players.LocalPlayer
local AS_World   = workspace

local AS = {
    mode         = nil,   -- "nearest" | "priority"
    running      = true,
    busy         = false,
    inFlight     = false,
    stealing     = false,
    stealName    = nil,
    lastError    = nil,

    plotsRoot    = nil,
    plotsFolder  = nil,
    ownerMemo    = {},
    myPlot       = nil,
    myPlotScan   = 0,
    enemyPlots   = nil,
    enemyPlotsT  = 0,

    promptCache  = {},
    animalMeta   = {},
    animalMetaN  = 0,

    brainrots    = {},
    byPrompt     = {},
    nearestCache = nil,

    priorityKeys  = {},
    priorityRanks = {},
    priorityAttempt = nil,
    attempts     = {},
    cleanups     = setmetatable({}, { __mode = "k" }),

    panelGui     = nil,
    panel        = nil,
    panelList    = nil,
    panelSummary = nil,
    panelStatus  = nil,
    panelDrag    = {},
    panelRows    = {},

    esp          = {},
    espFolder    = nil,
    espStamp     = 0,

    progress     = nil,
    barGui       = nil,
    barRoot      = nil,
    barTitle     = nil,
    barPct       = nil,
    barFill      = nil,
}

local AS_Data = {}

local function asNotify(message)
    local env = getgenv and getgenv() or _G
    if type(env.DatShawnNotify) == "function" then
        pcall(env.DatShawnNotify, message, true)
    else
        print("[Auto Steal] " .. tostring(message))
    end
end

-- game modules (aurora: Datas/*, Utils/NumberUtils, Controllers/PlotController)
task.spawn(function()
    pcall(function()
        local datas = AS_RS:WaitForChild("Datas", 25)
        if datas then
            AS_Data.Animals   = require(datas:WaitForChild("Animals", 10))
            AS_Data.Game      = require(datas:WaitForChild("Game", 10))
            AS_Data.Mutations = require(datas:WaitForChild("Mutations", 10))
            AS_Data.Traits    = require(datas:WaitForChild("Traits", 10))
        end
        local utils = AS_RS:FindFirstChild("Utils")
        if utils then
            AS_Data.NumberUtils = require(utils:WaitForChild("NumberUtils", 10))
        end
        local controllers = AS_RS:FindFirstChild("Controllers")
        if controllers then
            AS_Data.PlotController = require(controllers:WaitForChild("PlotController", 10))
        end
        AS.plotsFolder = AS_World:WaitForChild("Plots", 25)
    end)
end)

local function asCharacterRoot()
    local character = AS_Local.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if not humanoid or humanoid.Health <= 0 then
        return nil
    end
    return character:FindFirstChild("HumanoidRootPart") or character.PrimaryPart
end

local function asIncome(index, mutation, traits)
    local animals = AS_Data.Animals
    if not animals then return 0 end

    local animal = animals[index]
    if not animal then return 0 end

    local generation = animal.Generation
    if not generation then
        local gameMod = AS_Data.Game and AS_Data.Game.Game and AS_Data.Game.Game.AnimalGanerationModifier
        generation = (animal.Price or 0) * (gameMod or 0)
    end

    local multiplier = 1
    if mutation and AS_Data.Mutations and AS_Data.Mutations[mutation] then
        multiplier = 1 + (AS_Data.Mutations[mutation].Modifier or 0)
    end

    local sleepy = false
    if traits and AS_Data.Traits then
        for _, traitName in pairs(traits) do
            local trait = AS_Data.Traits[traitName]
            if trait then
                if traitName == "Sleepy" then
                    sleepy = true
                else
                    multiplier += (trait.MultiplierModifier or 0)
                end
            end
        end
    end

    local value = generation * multiplier
    if sleepy then value *= 0.5 end
    return math.round(value)
end

local function asIsLocalOwner(name)
    if name == nil then return false end
    return name == AS_Local.DisplayName or name == AS_Local.Name
end

local function asPlotOwner(plot)
    local plotSign = plot:FindFirstChild("PlotSign")
    local surface = plotSign and plotSign:FindFirstChild("SurfaceGui")
    local frame = surface and surface:FindFirstChild("Frame")
    local label = frame and frame:FindFirstChild("TextLabel")
    if not label then return nil end

    local text = label.Text
    if text == "Empty Base" then return nil end

    local memo = AS.ownerMemo
    local cached = memo[text]
    if cached ~= nil then return cached end

    local owner
    if text:lower():find("your base", 1, true) then
        owner = AS_Local.DisplayName
    else
        owner = text:gsub("'s [Bb]ase$", ""):gsub("%s+$", "")
    end

    local count = 0
    for _ in pairs(memo) do
        count += 1
        if count > 64 then memo = {}; AS.ownerMemo = memo; break end
    end
    memo[text] = owner
    return owner
end

local function asOwnPlot()
    local cached = AS.myPlot
    if cached then
        if cached.Parent then return cached end
        AS.myPlot = nil
    end
    local now = os.clock()
    if now - (AS.myPlotScan or 0) < 1 then return nil end
    AS.myPlotScan = now

    local folder = AS.plotsFolder
    if not folder then return nil end
    for _, plot in ipairs(folder:GetChildren()) do
        if asIsLocalOwner(asPlotOwner(plot)) then
            AS.myPlot = plot
            return plot
        end
    end
    return nil
end

local function asEnemyPlots()
    local now = os.clock()
    if AS.enemyPlots and now - (AS.enemyPlotsT or 0) < 1 then
        return AS.enemyPlots
    end

    local folder = AS.plotsFolder
    if not folder then return {} end

    local mine = AS.myPlot
    if mine and not mine.Parent then mine = nil end

    local list = {}
    for _, plot in ipairs(folder:GetChildren()) do
        if plot ~= mine then
            local owner = asPlotOwner(plot)
            if owner ~= nil and not asIsLocalOwner(owner) then
                list[#list + 1] = plot
            end
        end
    end
    AS.enemyPlots = list
    AS.enemyPlotsT = now
    return list
end

-- aurora: pulls the plot table out of the game's PlotController upvalues
local function asPlotsTable()
    local out = {}
    local controller = AS_Data.PlotController
    if not controller then return out end

    local root = AS.plotsRoot
    if type(root) ~= "table" or next(root) == nil then
        local function looksLikePlots(candidate)
            if type(candidate) ~= "table" then return false end
            local count = 0
            for _, value in next, candidate, nil do
                if type(value) ~= "table" or rawget(value, "Channel") == nil then
                    return false
                end
                count += 1
                if count >= 2 then break end
            end
            return count > 0
        end

        local function upvalueAt(fn, index)
            if type(fn) ~= "function" then return nil end
            if type(debug) ~= "table" or type(debug.getupvalue) ~= "function" then return nil end
            local first, second = debug.getupvalue(fn, index)
            if type(first) == "table" then return first end
            if type(second) == "table" then return second end
            return nil
        end

        local found = upvalueAt(rawget(controller, "GetPlots"), 1)
        if not looksLikePlots(found) then found = nil end

        if not found then
            for index = 1, 24 do
                local candidate = upvalueAt(rawget(controller, "Start"), index)
                if looksLikePlots(candidate) then
                    found = candidate
                    break
                end
            end
        end

        root = found
        AS.plotsRoot = root
    end

    if type(root) ~= "table" then return out end

    for name, plot in next, root, nil do
        local channel = type(plot) == "table" and rawget(plot, "Channel")
        local cache = type(channel) == "table" and rawget(channel, "CacheTable")
        if type(cache) == "table" then
            out[tostring(name)] = cache
        end
    end
    return out
end

local function asPromptForPodium(podium)
    if not podium then return nil end

    local base = podium:FindFirstChild("Base")
    local spawn = base and base:FindFirstChild("Spawn")
    local attachment = spawn and spawn:FindFirstChild("PromptAttachment")
    local prompt = attachment and attachment:FindFirstChildWhichIsA("ProximityPrompt")
    if prompt and prompt.ActionText == "Steal" then
        return prompt
    end

    for _, child in ipairs((spawn or base or podium):GetDescendants()) do
        if child:IsA("ProximityPrompt") and child.ActionText == "Steal" then
            return child
        end
    end
    return nil
end

local function asPromptLookup(plot, slot)
    local cacheKey = (plot and plot.Name or "?") .. "\0" .. tostring(slot)
    local cached = AS.promptCache[cacheKey]
    if cached and cached.prompt and cached.prompt.Parent
        and cached.prompt.ActionText == "Steal" and cached.podium.Parent then
        return cached.prompt, cached.base, cached.podium
    end

    local podiums = plot and plot:FindFirstChild("AnimalPodiums")
    local podium = podiums and slot ~= nil and podiums:FindFirstChild(tostring(slot))
    if not podium then
        AS.promptCache[cacheKey] = nil
        return nil, nil, nil
    end

    local base = podium:FindFirstChild("Base")
    local prompt = asPromptForPodium(podium)
    AS.promptCache[cacheKey] = { prompt = prompt, base = base or podium, podium = podium }
    return prompt, base or podium, podium
end

local function asAnimalModel(target)
    if not target then return nil end

    local cached = target._part
    if cached and cached.Parent then return cached end

    local missingUntil = target._partMissingUntil
    if missingUntil and tick() < missingUntil then return nil end

    local base = target.base
    if base and base.Parent then
        target._part = base
        target._partMissingUntil = nil
        return base
    end

    local promptParent = target.prompt and target.prompt.Parent
    if promptParent then
        if promptParent:IsA("Attachment") then promptParent = promptParent.Parent end
        if promptParent and promptParent.Parent then
            target._part = promptParent
            return promptParent
        end
    end

    if target.model and target.model.Parent then
        target._part = target.model
        return target.model
    end

    target._partMissingUntil = tick() + 2
    return nil
end

local function asPromptPosition(prompt)
    if not prompt then return nil end
    local target = prompt.Parent
    if not target then return nil end
    if target:IsA("Attachment") then return target.WorldPosition end
    if target:IsA("BasePart") then return target.Position end
    if target:IsA("Model") and target.PrimaryPart then return target.PrimaryPart.Position end
    return nil
end

-- aurora: internalValue207 + internalValue223 (count how many copies of the target you own)
local function asOwnPlots()
    local plot = asOwnPlot()
    if not plot then return {} end
    return { plot }
end

local function asOwnedCount(target)
    if not target then return 0 end
    local plotsData = asPlotsTable()
    local count = 0

    for _, plot in ipairs(asOwnPlots()) do
        local data = plotsData[plot.Name]
        local list = data and rawget(data, "AnimalList")
        if type(list) == "table" then
            for _, entry in pairs(list) do
                local match = type(entry) == "table"
                    and entry.Index == target.index
                    and entry.Mutation == target.mutation
                if match then
                    match = table.concat(entry.Traits or {}, ",") == table.concat(target.traits or {}, ",")
                end
                if match then count += 1 end
            end
        end
    end

    return count
end

-- aurora: internalValue229 (only drop the priority key once the steal really landed)
local asPriorityRemove

local function asPriorityConfirmRemove(binding)
    if not binding.confirmed or AS_Local.Character ~= binding.char then return false end
    if asOwnedCount(binding.target) <= (binding.owned or 0) then return false end
    return asPriorityRemove(binding.key)
end

local function asRarityRank(rarity)
    local text = tostring(rarity)
    if text == "OG" then return 3 end
    if text == "Secret" then return 2 end
    return 1
end

local function asScanner()
    if (AS.animalMetaN or 0) > 400 then
        AS.animalMeta = {}
        AS.animalMetaN = 0
    end

    local items = {}
    local plotsData = asPlotsTable()

    for _, plot in ipairs(asEnemyPlots()) do
        pcall(function()
            local data = plotsData[plot.Name]
            local animalList = data and rawget(data, "AnimalList")
            if type(animalList) ~= "table" then return end

            for slot, animal in next, animalList, nil do
                if type(animal) == "table" and animal.Index then
                    local prompt, base, podium = asPromptLookup(plot, slot)
                    if prompt and prompt.Parent then
                        local metaKey = tostring(animal.Index) .. ":" .. tostring(animal.Mutation)
                            .. ":" .. (animal.Traits and table.concat(animal.Traits, ",") or "")

                        local meta = AS.animalMeta[metaKey]
                        if not meta then
                            local info = AS_Data.Animals and AS_Data.Animals[animal.Index]
                            local num = asIncome(animal.Index, animal.Mutation, animal.Traits)
                            local numberUtils = AS_Data.NumberUtils
                            meta = {
                                displayName = info and info.DisplayName or tostring(animal.Index),
                                rarity = info and info.Rarity,
                                num = num,
                                price = info and tonumber(info.Price) or 0,
                                gen = "$" .. (numberUtils and numberUtils:ToString(num) or tostring(num)) .. "/s",
                            }
                            AS.animalMeta[metaKey] = meta
                            AS.animalMetaN = (AS.animalMetaN or 0) + 1
                        end

                        items[#items + 1] = {
                            displayName = meta.displayName,
                            gen = meta.gen,
                            num = meta.num,
                            rarity = meta.rarity,
                            price = meta.price or 0,
                            index = animal.Index,
                            mutation = animal.Mutation,
                            traits = animal.Traits,
                            plot = plot,
                            prompt = prompt,
                            base = base,
                            podium = podium,
                            model = podium,
                            slot = tostring(slot),
                        }
                    end
                end
            end
        end)
    end

    table.sort(items, function(a, b)
        local rankA, rankB = asRarityRank(a.rarity), asRarityRank(b.rarity)
        if rankA ~= rankB then return rankA > rankB end
        if (a.price or 0) ~= (b.price or 0) then return a.price > b.price end
        return (a.num or 0) > (b.num or 0)
    end)

    return items
end

local function asPriorityKey(target)
    return tostring(target.plot and target.plot.Name) .. "|" .. tostring(target.slot)
end

local function asRebuildPriorityRanks()
    AS.priorityRanks = {}
    for index, key in ipairs(AS.priorityKeys) do
        AS.priorityRanks[key] = index
    end
end

local function asStealable(target)
    return target
        and target.plot and target.plot.Parent
        and target.prompt and target.prompt.Parent
        and target.prompt.Enabled
        and target.prompt.ActionText == "Steal"
        and asAnimalModel(target) ~= nil
end

local function asNearestTarget(priorityOnly)
    if priorityOnly then
        local bestRank, selected = math.huge, nil
        for _, animal in ipairs(AS.brainrots) do
            local rank = AS.priorityRanks[asPriorityKey(animal)]
            if rank and rank < bestRank and asStealable(animal) then
                bestRank, selected = rank, animal
            end
        end
        return selected
    end

    local root = asCharacterRoot()
    if not root then return nil end

    local cache = AS.nearestCache
    if cache and cache.best and os.clock() - cache.t < 0.12
        and (cache.pos - root.Position).Magnitude < 1
        and asStealable(cache.best) then
        return cache.best
    end

    local nearestDistance, selected = math.huge, nil
    for _, animal in ipairs(AS.brainrots) do
        if asStealable(animal) then
            local model = asAnimalModel(animal)
            local ok, pivot = pcall(function() return model:GetPivot() end)
            if ok and pivot then
                local distance = (root.Position - pivot.Position).Magnitude
                if distance < nearestDistance then
                    nearestDistance, selected = distance, animal
                end
            end
        end
    end

    AS.nearestCache = { best = selected, t = os.clock(), pos = root.Position }
    return selected
end

local function asTargetSelection()
    if AS.mode == "priority" then return asNearestTarget(true) end
    if AS.mode == "nearest" then return asNearestTarget(false) end
    return nil
end

-- ==========================================
-- AUTO STEAL VISUALS (target ESP + steal bar)
-- ==========================================

local asRefreshPriorityPanel

local function asEspStop()
    for key, entry in pairs(AS.esp) do
        if entry.highlight then pcall(function() entry.highlight:Destroy() end) end
        if entry.bill then pcall(function() entry.bill:Destroy() end) end
        AS.esp[key] = nil
    end
    if AS.espFolder then
        pcall(function() AS.espFolder:Destroy() end)
        AS.espFolder = nil
    end
end

local function asEspAnchor(part)
    if not part then return nil end
    if part:IsA("BasePart") then return part end
    local primary = part.PrimaryPart
    if primary then return primary end
    return part:FindFirstChildWhichIsA("BasePart", true)
end

local function asEspCreate(target, key)
    local model = asAnimalModel(target)
    local anchor = asEspAnchor(model)
    if not anchor or not anchor.Parent then return nil end

    if not AS.espFolder or not AS.espFolder.Parent then
        local folder = Instance.new("Folder")
        folder.Name = "AutoStealESP_" .. tostring(math.random(100000, 999999))
        folder.Parent = apMountParent()
        AS.espFolder = folder
    end

    local entry = { part = model, key = key }

    local highlight = Instance.new("Highlight")
    highlight.Name = "AS_Target"
    highlight.Adornee = (target.podium and target.podium.Parent) and target.podium or anchor
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.FillColor = Color3.fromRGB(210, 26, 26)
    highlight.FillTransparency = 0.86
    highlight.OutlineColor = Color3.fromRGB(255, 46, 46)
    highlight.OutlineTransparency = 0.05
    highlight.Parent = AS.espFolder
    entry.highlight = highlight

    local bill = Instance.new("BillboardGui")
    bill.Name = "AS_TargetName"
    bill.Adornee = anchor
    bill.Size = UDim2.fromOffset(190, 30)
    bill.StudsOffset = Vector3.new(0, 4.6, 0)
    bill.AlwaysOnTop = true
    bill.MaxDistance = 2500
    bill.LightInfluence = 0
    bill.Parent = anchor

    local nameLabel = Instance.new("TextLabel")
    nameLabel.BackgroundTransparency = 1
    nameLabel.Size = UDim2.new(1, 0, 0, 15)
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextSize = 12
    nameLabel.TextColor3 = Color3.fromRGB(255, 240, 240)
    nameLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    nameLabel.TextStrokeTransparency = 0
    nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
    nameLabel.Parent = bill

    local infoLabel = Instance.new("TextLabel")
    infoLabel.BackgroundTransparency = 1
    infoLabel.Position = UDim2.fromOffset(0, 15)
    infoLabel.Size = UDim2.new(1, 0, 0, 14)
    infoLabel.Font = Enum.Font.GothamMedium
    infoLabel.TextSize = 10
    infoLabel.TextColor3 = Color3.fromRGB(240, 90, 90)
    infoLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    infoLabel.TextStrokeTransparency = 0
    infoLabel.TextTruncate = Enum.TextTruncate.AtEnd
    infoLabel.Parent = bill

    entry.bill = bill
    entry.nameLabel = nameLabel
    entry.infoLabel = infoLabel
    return entry
end

local function asRefreshESP()
    if not AS.mode then
        if AS.espFolder or next(AS.esp) then asEspStop() end
        return
    end

    local stamp = (AS.espStamp or 0) + 1
    AS.espStamp = stamp

    local root = asCharacterRoot()
    local shown = 0

    for _, target in ipairs(AS.brainrots) do
        if shown >= 60 then break end
        local key = asPriorityKey(target)
        local model = asAnimalModel(target)
        local anchor = asEspAnchor(model)

        if anchor and anchor.Parent then
            local entry = AS.esp[key]
            if entry and (entry.part ~= model or not entry.bill or not entry.bill.Parent) then
                if entry.highlight then pcall(function() entry.highlight:Destroy() end) end
                if entry.bill then pcall(function() entry.bill:Destroy() end) end
                entry = nil
                AS.esp[key] = nil
            end

            if not entry then
                entry = asEspCreate(target, key)
                AS.esp[key] = entry
            end

            if entry then
                shown += 1
                entry.stamp = stamp

                local priority = AS.priorityRanks[key] ~= nil
                local gold = Color3.fromRGB(255, 205, 45)
                local red = Color3.fromRGB(255, 46, 46)

                if entry.highlight then
                    entry.highlight.FillColor = priority and gold or Color3.fromRGB(210, 26, 26)
                    entry.highlight.OutlineColor = priority and gold or red
                end

                if entry.nameLabel then
                    entry.nameLabel.Text = tostring(target.displayName)
                    entry.nameLabel.TextColor3 = priority and gold or Color3.fromRGB(255, 240, 240)
                end

                if entry.infoLabel then
                    local dist = ""
                    if root then
                        local ok, pivot = pcall(function() return anchor:GetPivot() end)
                        if ok and pivot then
                            dist = "  ·  " .. tostring(math.floor((root.Position - pivot.Position).Magnitude)) .. "m"
                        end
                    end
                    entry.infoLabel.Text = tostring(target.gen)
                        .. "  ·  slot " .. tostring(target.slot) .. dist
                end
            end
        end
    end

    for key, entry in pairs(AS.esp) do
        if entry.stamp ~= stamp then
            if entry.highlight then pcall(function() entry.highlight:Destroy() end) end
            if entry.bill then pcall(function() entry.bill:Destroy() end) end
            AS.esp[key] = nil
        end
    end
end

local function asEnsureStealBar()
    if AS.barRoot and AS.barRoot.Parent then return end

    local gui = Instance.new("ScreenGui")
    gui.Name = "AutoStealBar_" .. tostring(math.random(100000, 999999))
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.DisplayOrder = 2147482997
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.Parent = apMountParent()

    local root = Instance.new("Frame")
    root.Name = "Bar"
    root.AnchorPoint = Vector2.new(0.5, 1)
    root.Position = UDim2.new(0.5, 0, 1, -104)
    root.Size = UDim2.fromOffset(300, 42)
    root.BackgroundColor3 = Color3.fromRGB(10, 10, 11)
    root.BorderSizePixel = 0
    root.Visible = false
    root.Parent = gui
    qCorner(root, 7)
    qStroke(root, Color3.fromRGB(96, 18, 18), 0)

    local title = Instance.new("TextLabel")
    title.BackgroundTransparency = 1
    title.Position = UDim2.fromOffset(10, 5)
    title.Size = UDim2.new(1, -62, 0, 14)
    title.Font = Enum.Font.GothamBold
    title.Text = "STEALING"
    title.TextColor3 = Color3.fromRGB(245, 238, 238)
    title.TextSize = 11
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.TextTruncate = Enum.TextTruncate.AtEnd
    title.Parent = root

    local pct = Instance.new("TextLabel")
    pct.AnchorPoint = Vector2.new(1, 0)
    pct.Position = UDim2.new(1, -10, 0, 4)
    pct.Size = UDim2.fromOffset(62, 14)
    pct.BackgroundTransparency = 1
    pct.Font = Enum.Font.GothamBlack
    pct.Text = "0%"
    pct.TextColor3 = Color3.fromRGB(255, 62, 62)
    pct.TextSize = 12
    pct.TextXAlignment = Enum.TextXAlignment.Right
    pct.Parent = root

    local track = Instance.new("Frame")
    track.Name = "Track"
    track.Position = UDim2.fromOffset(10, 24)
    track.Size = UDim2.new(1, -20, 0, 10)
    track.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    track.BorderSizePixel = 0
    track.ClipsDescendants = true
    track.Parent = root
    qCorner(track, 4)
    qStroke(track, Color3.fromRGB(70, 14, 14), 0)

    local fill = Instance.new("Frame")
    fill.Name = "Fill"
    fill.Size = UDim2.new(0, 0, 1, 0)
    fill.BackgroundColor3 = Color3.fromRGB(224, 24, 24)
    fill.BorderSizePixel = 0
    fill.Parent = track
    qCorner(fill, 4)

    AS.barGui = gui
    AS.barRoot = root
    AS.barTitle = title
    AS.barPct = pct
    AS.barFill = fill
end

local function asStealBarStart(name)
    pcall(asEnsureStealBar)
    AS.progress = {
        startedAt = os.clock(),
        duration = 1.3,
        name = name or AS.stealName or "target",
        phase = "hold",
    }
end

local function asStealBarPhase(phase)
    if AS.progress then AS.progress.phase = phase end
end

local function asStealBarStop()
    AS.progress = nil
    if AS.barRoot then AS.barRoot.Visible = false end
end

task.spawn(function()
    while AS.running do
        local progress = AS.progress
        if progress and AS.barRoot then
            local ratio = math.clamp((os.clock() - progress.startedAt) / (progress.duration or 1.3), 0, 1)
            AS.barRoot.Visible = true
            AS.barFill.Size = UDim2.new(ratio, 0, 1, 0)
            AS.barPct.Text = tostring(math.floor(ratio * 100)) .. "%"
            if progress.phase == "wait" then
                AS.barTitle.Text = "WAITING  ·  " .. tostring(progress.name)
                AS.barPct.Text = "100%"
            else
                AS.barTitle.Text = "STEALING  ·  " .. tostring(progress.name)
            end
        elseif AS.barRoot then
            AS.barRoot.Visible = false
        end
        task.wait(0.03)
    end
end)

local function asRefreshScan()
    AS.brainrots = asScanner()
    AS.byPrompt = {}
    for _, item in ipairs(AS.brainrots) do
        if item.prompt then
            AS.byPrompt[item.prompt] = item
        end
    end
    AS.nearestCache = nil

    pcall(asRefreshESP)

    if AS.panelList and os.clock() - (AS.panelRefreshT or 0) > 0.25 then
        AS.panelRefreshT = os.clock()
        pcall(asRefreshPriorityPanel)
    end
end

-- aurora: resolvePromptCallbacks
local function asResolvePromptCallbacks(prompt)
    local result = { hold = {}, trigger = {}, holdEnd = {} }

    local function collect(signal, output)
        if type(getconnections) ~= "function" then return end
        local ok, list = pcall(getconnections, signal)
        if not ok or type(list) ~= "table" then return end
        for _, connection in ipairs(list) do
            local readable, callback = pcall(function() return connection.Function end)
            if readable and type(callback) == "function" then
                output[#output + 1] = function()
                    return callback(AS_Local)
                end
            end
        end
    end

    collect(prompt.PromptButtonHoldBegan, result.hold)
    collect(prompt.Triggered, result.trigger)
    collect(prompt.PromptButtonHoldEnded, result.holdEnd)

    if #result.hold == 0 then
        result.hold[1] = function()
            if prompt.Parent then prompt:InputHoldBegin() end
        end
    end

    if #result.trigger == 0 then
        result.trigger[1] = function()
            if not prompt.Parent then return end
            if type(fireproximityprompt) == "function" then
                fireproximityprompt(prompt, 0)
            else
                prompt:InputHoldEnd()
            end
        end
    end

    return result
end

-- aurora: holdAutoStealPrompt (the path used by nearest / best / priority)
local AS_OPERATION = nil

local function asHoldPrompt(prompt, mode)
    if not prompt or not prompt.Parent or not prompt.Enabled then return false end
    if mode ~= "priority" and mode ~= "nearest" then return false end
    if AS_OPERATION then return false end

    local character = AS_Local.Character

    local function distance()
        local root = asCharacterRoot()
        local position = asPromptPosition(prompt)
        if not root or not position then return math.huge end
        return (root.Position - position).Magnitude
    end

    if distance() > 999 then return false end

    local function valid()
        if not AS.running or not AS.mode or AS.mode ~= mode then return false end
        if AS_Local.Character ~= character or not prompt.Parent then return false end
        return true
    end

    local function ragdollEnd()
        local playerEnd = AS_Local:GetAttribute("RagdollEndTime")
        local characterEnd = character and character:GetAttribute("RagdollEndTime")
        playerEnd = type(playerEnd) == "number" and playerEnd == playerEnd and playerEnd or 0
        characterEnd = type(characterEnd) == "number" and characterEnd == characterEnd and characterEnd or 0
        return math.max(playerEnd, characterEnd)
    end

    local function ragdollRemaining()
        return math.max(0, ragdollEnd() - AS_World:GetServerTimeNow())
    end

    while valid() and ragdollRemaining() > 1.3 do
        task.wait(0.01)
    end
    if not valid() then return false end

    local callbacks = asResolvePromptCallbacks(prompt)
    local originalMax = prompt.MaxActivationDistance
    local originalLineOfSight = prompt.RequiresLineOfSight

    local operation = { prompt = prompt, startedAt = os.clock(), duration = 1.3, mode = mode, waitUntil = 0 }
    AS_OPERATION = operation
    AS.cleanups[prompt] = function()
        pcall(function()
            prompt.MaxActivationDistance = originalMax
            prompt.RequiresLineOfSight = originalLineOfSight
        end)
    end

    local holding = false
    local nativeHolding = false

    local ok, result = pcall(function()
        prompt.MaxActivationDistance = 999
        prompt.RequiresLineOfSight = false
        holding = true
        asStealBarStart(AS.stealName)

        if #callbacks.hold > 0 then
            for _, callback in ipairs(callbacks.hold) do
                task.spawn(callback, AS_Local)
            end
        else
            nativeHolding = true
            prompt:InputHoldBegin()
        end

        operation.startedAt = os.clock()
        local initialRagdollEnd = ragdollEnd()

        local function interrupted()
            return ragdollRemaining() > 0 and ragdollEnd() > initialRagdollEnd + 0.05
        end

        while os.clock() - operation.startedAt < 1.3 do
            if not valid() or interrupted() then return false end
            task.wait(0.01)
        end
        if not valid() then return false end

        local wasClose = distance() <= 10
        operation.waitUntil = operation.startedAt + 2.6
        asStealBarPhase("wait")

        while valid() do
            if interrupted() or os.clock() > operation.waitUntil then return false end
            if distance() <= 10 and ragdollRemaining() <= 0 then
                if not wasClose then task.wait(0.3) end
                if not valid() or interrupted() or ragdollRemaining() > 0 or distance() > 10 then
                    return false
                end
                break
            end
            task.wait(0.01)
        end
        if not valid() then return false end

        if #callbacks.trigger > 0 then
            for _, callback in ipairs(callbacks.trigger) do
                task.spawn(callback, AS_Local)
            end
            return true
        elseif type(fireproximityprompt) == "function" then
            fireproximityprompt(prompt, 0)
            return true
        end
        return false
    end)

    asStealBarStop()

    if holding and (nativeHolding or not ok or result ~= true) then
        for _, callback in ipairs(callbacks.holdEnd) do
            pcall(callback, AS_Local)
        end
        if nativeHolding and prompt.Parent then
            pcall(function() prompt:InputHoldEnd() end)
        end
    end

    pcall(function()
        prompt.MaxActivationDistance = originalMax
        prompt.RequiresLineOfSight = originalLineOfSight
    end)

    if AS_OPERATION == operation then AS_OPERATION = nil end
    AS.cleanups[prompt] = nil

    if not ok then
        AS.lastError = result
        return false
    end
    return result == true
end

local function asAutoSteal(prompt)
    if AS.busy then return false end
    if not AS.mode then return false end

    AS.busy = true
    local result = { pcall(asHoldPrompt, prompt, AS.mode) }
    AS.busy = false

    if not result[1] then
        local cleanup = AS.cleanups[prompt]
        if cleanup then pcall(cleanup) end
        AS.cleanups[prompt] = nil
        AS.lastError = result[2]
        return false
    end
    return result[2]
end

asPriorityRemove = function(key)
    for index, existing in ipairs(AS.priorityKeys) do
        if existing == key then
            table.remove(AS.priorityKeys, index)
            asRebuildPriorityRanks()
            if asRefreshPriorityPanel then asRefreshPriorityPanel() end
            return true
        end
    end
    return false
end

-- main loop (aurora: 10ms tick while active, 250ms when idle)
local function asLoop()
    local lastScan = 0
    while AS.running do
        if not AS.mode then
            task.wait(0.25)
        else
            task.wait(0.01)

            local now = os.clock()
            if now - lastScan >= 0.15 then
                lastScan = now
                local ok, err = pcall(asRefreshScan)
                if not ok then AS.lastError = err end
            end

            if AS.mode and not AS.busy and not AS.inFlight then
                local binding

                local function attempt()
                    local target = asTargetSelection()
                    if not target or not target.prompt or not target.prompt.Parent then return end

                    local root = asCharacterRoot()
                    local position = asPromptPosition(target.prompt)
                    if not root or not position then return end
                    if (root.Position - position).Magnitude > 999 then return end

                    if AS.mode == "priority" then
                        binding = {
                            target = target,
                            key = asPriorityKey(target),
                            char = AS_Local.Character,
                            owned = asOwnedCount(target),
                            confirmed = false,
                            before = AS_Local:GetAttribute("Stealing"),
                        }
                        local before = binding.before
                        binding.conn = AS_Local:GetAttributeChangedSignal("Stealing"):Connect(function()
                            local current = AS_Local:GetAttribute("Stealing")
                            if AS_Local.Character == binding.char and current ~= nil and current ~= before then
                                binding.confirmed = true
                            end
                            before = current
                        end)
                        AS.priorityAttempt = binding
                    end

                    AS.stealing = true
                    AS.stealName = target.displayName

                    local ok = asAutoSteal(target.prompt)
                    AS.stealing = false

                    if ok and binding and not AS.attempts[binding.key] then
                        binding.tracking = true
                        AS.attempts[binding.key] = binding

                        task.spawn(function()
                            local deadline = tick() + 2
                            while true do
                                local current = AS_Local:GetAttribute("Stealing")
                                if current ~= nil and current ~= binding.before then
                                    binding.confirmed = true
                                end
                                if binding.confirmed then break end
                                task.wait(0.05)
                                if not AS.running
                                    or AS.mode ~= "priority"
                                    or AS_Local.Character ~= binding.char
                                    or tick() >= deadline then
                                    break
                                end
                            end

                            if binding.confirmed then
                                while AS.running
                                    and AS.mode == "priority"
                                    and AS_Local.Character == binding.char
                                    and AS_Local:GetAttribute("Stealing") ~= nil do
                                    task.wait(0.05)
                                end

                                local confirmDeadline = tick() + 2
                                while true do
                                    local stillValid = AS.running
                                        and AS.mode == "priority"
                                        and AS_Local.Character == binding.char
                                    if stillValid then
                                        stillValid = asOwnedCount(binding.target) <= (binding.owned or 0)
                                    end
                                    if not stillValid or asStealable(binding.target)
                                        or tick() >= confirmDeadline then
                                        break
                                    end
                                    task.wait(0.05)
                                end

                                if AS.running then
                                    asPriorityConfirmRemove(binding)
                                end
                            end

                            if binding.conn then
                                pcall(function() binding.conn:Disconnect() end)
                            end
                            if AS.attempts[binding.key] == binding then
                                AS.attempts[binding.key] = nil
                            end
                        end)
                    end
                end

                local ok, err = pcall(attempt)
                if not ok then AS.lastError = err end

                if binding and not binding.tracking and binding.conn then
                    pcall(function() binding.conn:Disconnect() end)
                end
                if AS.priorityAttempt == binding then AS.priorityAttempt = nil end
                AS.stealing = false
            end
        end
    end
end

-- ==========================================
-- AUTO STEAL PRIORITY PANEL
-- ==========================================

local AS_PANEL_W = 268

asRefreshPriorityPanel = function()
    if not AS.panelList then return end

    AS.panelRows = AS.panelRows or {}

    local byKey = {}
    for _, target in ipairs(AS.brainrots) do
        byKey[asPriorityKey(target)] = target
    end

    local order = {}
    local seen = {}
    for rank, key in ipairs(AS.priorityKeys) do
        seen[key] = true
        order[#order + 1] = { key = key, target = byKey[key], rank = rank }
    end
    for _, target in ipairs(AS.brainrots) do
        local key = asPriorityKey(target)
        if not seen[key] then
            seen[key] = true
            order[#order + 1] = { key = key, target = target, rank = nil }
        end
    end

    local root = asCharacterRoot()
    local gold = Color3.fromRGB(255, 205, 45)
    local white = Color3.fromRGB(226, 226, 232)
    local dim = Color3.fromRGB(170, 170, 178)
    local active = {}

    for index, item in ipairs(order) do
        local key = item.key
        active[key] = true

        local row = AS.panelRows[key]
        if not row or not row.frame or not row.frame.Parent then
            row = {}

            local frame = Instance.new("Frame")
            frame.Name = "Row"
            frame.Size = UDim2.new(1, 0, 0, 24)
            frame.BackgroundColor3 = Color3.fromRGB(24, 24, 26)
            frame.BorderSizePixel = 0
            frame.Parent = AS.panelList
            qCorner(frame, 5)
            qStroke(frame, Color3.fromRGB(42, 42, 47), 0.3)

            local label = Instance.new("TextLabel")
            label.BackgroundTransparency = 1
            label.Position = UDim2.fromOffset(8, 0)
            label.Size = UDim2.new(1, -38, 1, 0)
            label.Font = Enum.Font.GothamMedium
            label.TextSize = 10
            label.TextXAlignment = Enum.TextXAlignment.Left
            label.TextTruncate = Enum.TextTruncate.AtEnd
            label.Parent = frame

            local button = Instance.new("TextButton")
            button.AnchorPoint = Vector2.new(1, 0.5)
            button.Position = UDim2.new(1, -6, 0.5, 0)
            button.Size = UDim2.fromOffset(20, 17)
            button.BorderSizePixel = 0
            button.AutoButtonColor = true
            button.Font = Enum.Font.GothamBold
            button.TextSize = 11
            button.Parent = frame
            qCorner(button, 4)

            row.frame = frame
            row.label = label
            row.button = button
            row.key = key

            button.MouseButton1Click:Connect(function()
                local rowKey = row.key
                if AS.priorityRanks[rowKey] then
                    asPriorityRemove(rowKey)
                    return
                end
                if #AS.priorityKeys >= 128 then
                    asNotify("Priority list is full")
                    return
                end
                AS.priorityKeys[#AS.priorityKeys + 1] = rowKey
                asRebuildPriorityRanks()
                asRefreshPriorityPanel()
            end)

            AS.panelRows[key] = row
        end

        row = AS.panelRows[key]
        row.key = key
        row.frame.LayoutOrder = index

        local isPriority = item.rank ~= nil
        row.frame.BackgroundColor3 = isPriority
            and Color3.fromRGB(34, 20, 20)
            or Color3.fromRGB(24, 24, 26)

        local target = item.target
        local name
        local info

        if target then
            name = tostring(target.displayName)
            info = tostring(target.gen) .. "  ·  slot " .. tostring(target.slot)

            if root then
                local model = asAnimalModel(target)
                if model then
                    local ok, pivot = pcall(function() return model:GetPivot() end)
                    if ok and pivot then
                        info = info .. "  ·  "
                            .. tostring(math.floor((root.Position - pivot.Position).Magnitude)) .. "m"
                    end
                end
            end
        else
            local plot, slot = tostring(key):match("^(.-)|(.+)$")
            name = tostring(plot or key) .. "  ·  slot " .. tostring(slot or "?")
            info = "not in range"
        end

        local prefix = item.rank and (tostring(item.rank) .. ". ") or "·  "
        row.label.Text = prefix .. name .. "   " .. info
        row.label.TextColor3 = isPriority and gold or white

        row.button.Text = isPriority and "x" or "+"
        row.button.TextColor3 = isPriority
            and Color3.fromRGB(255, 220, 220)
            or dim
        row.button.BackgroundColor3 = isPriority
            and Color3.fromRGB(120, 40, 40)
            or Color3.fromRGB(40, 40, 45)
    end

    for key, row in pairs(AS.panelRows) do
        if not active[key] then
            pcall(function() row.frame:Destroy() end)
            AS.panelRows[key] = nil
        end
    end

    if AS.panelSummary then
        AS.panelSummary.Text = #AS.priorityKeys .. " priority / " .. #AS.brainrots .. " targets"
    end
end

local function asAddNearestToPriority()
    if not AS.mode then
        asNotify("Turn on Auto Steal Priority first")
        return
    end

    local ok, err = pcall(asRefreshScan)
    if not ok then AS.lastError = err end

    local target = asNearestTarget(false)
    if not target then
        asNotify("No stealable animal found nearby")
        return
    end

    local key = asPriorityKey(target)
    if AS.priorityRanks[key] then
        asNotify(target.displayName .. " is already in the priority list")
        return
    end

    if #AS.priorityKeys >= 128 then
        asNotify("Priority list is full")
        return
    end

    AS.priorityKeys[#AS.priorityKeys + 1] = key
    asRebuildPriorityRanks()
    asRefreshPriorityPanel()
    asNotify("Priority added: " .. target.displayName)
end

local function asBindPanelDrag(panel, ...)
    local dragging, offset = false, Vector2.zero
    local handles = { ... }

    for _, handle in ipairs(handles) do
        table.insert(AS.panelDrag, handle.InputBegan:Connect(function(input)
            if input.UserInputType ~= Enum.UserInputType.MouseButton1
            and input.UserInputType ~= Enum.UserInputType.Touch then return end

            dragging = true
            local mouse = Vector2.new(input.Position.X, input.Position.Y)
            local abs = panel.AbsolutePosition
            offset = mouse - Vector2.new(abs.X, abs.Y)

            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end))
    end

    table.insert(AS.panelDrag, game:GetService("UserInputService").InputChanged:Connect(function(input)
        if not dragging then return end
        if input.UserInputType ~= Enum.UserInputType.MouseMovement
        and input.UserInputType ~= Enum.UserInputType.Touch then return end
        local mouse = Vector2.new(input.Position.X, input.Position.Y) - offset
        panel.Position = UDim2.fromOffset(mouse.X, mouse.Y)
    end))
end

local function asOpenPriorityPanel()
    if AS.panelGui then return end

    local gui = Instance.new("ScreenGui")
    gui.Name = "AutoStealPriority_" .. tostring(math.random(100000, 999999))
    gui.ResetOnSpawn = false
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.IgnoreGuiInset = true
    gui.DisplayOrder = 2147482998
    gui.Parent = apMountParent()

    local listH = 202
    local panel = Instance.new("Frame")
    panel.Name = "Panel"
    panel.Position = UDim2.new(0.5, -AS_PANEL_W / 2, 0.5, 150)
    panel.Size = UDim2.fromOffset(AS_PANEL_W, 26 + 6 + 4 + listH + 26 + 8)
    panel.BackgroundColor3 = Color3.fromRGB(14, 14, 15)
    panel.BorderSizePixel = 0
    panel.ClipsDescendants = true
    panel.Parent = gui
    qCorner(panel, 8)
    qStroke(panel, Color3.fromRGB(48, 48, 52), 0)

    local titleBar = Instance.new("Frame")
    titleBar.Name = "TitleBar"
    titleBar.Size = UDim2.new(1, 0, 0, 26)
    titleBar.BackgroundColor3 = Color3.fromRGB(20, 20, 22)
    titleBar.BorderSizePixel = 0
    titleBar.Parent = panel

    local trim = Instance.new("Frame")
    trim.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    trim.BorderSizePixel = 0
    trim.Size = UDim2.new(1, 0, 0, 1)
    trim.BackgroundTransparency = 0.55
    trim.Parent = panel

    local title = Instance.new("TextLabel")
    title.BackgroundTransparency = 1
    title.Position = UDim2.fromOffset(10, 0)
    title.Size = UDim2.new(1, -20, 1, 0)
    title.Font = Enum.Font.GothamBold
    title.Text = "AUTO STEAL PRIORITY"
    title.TextColor3 = Color3.fromRGB(240, 240, 244)
    title.TextSize = 12
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = titleBar

    local summary = Instance.new("TextLabel")
    summary.BackgroundTransparency = 1
    summary.AnchorPoint = Vector2.new(1, 0.5)
    summary.Position = UDim2.new(1, -10, 0.5, 0)
    summary.Size = UDim2.fromOffset(150, 14)
    summary.Font = Enum.Font.GothamMedium
    summary.Text = "0 priority / 0 targets"
    summary.TextColor3 = Color3.fromRGB(120, 120, 128)
    summary.TextSize = 9
    summary.TextXAlignment = Enum.TextXAlignment.Right
    summary.Parent = titleBar

    local list = Instance.new("ScrollingFrame")
    list.Name = "List"
    list.Position = UDim2.new(0, 6, 0, 32)
    list.Size = UDim2.new(1, -12, 0, listH)
    list.BackgroundTransparency = 1
    list.BorderSizePixel = 0
    list.ScrollBarThickness = 2
    list.ScrollBarImageColor3 = Color3.fromRGB(70, 70, 76)
    list.ScrollBarImageTransparency = 0.2
    list.CanvasSize = UDim2.new(0, 0, 0, 0)
    list.AutomaticCanvasSize = Enum.AutomaticSize.Y
    list.ScrollingDirection = Enum.ScrollingDirection.Y
    list.Parent = panel

    local listLayout = Instance.new("UIListLayout")
    listLayout.Padding = UDim.new(0, 3)
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.Parent = list

    local addButton = Instance.new("TextButton")
    addButton.Name = "Add"
    addButton.Position = UDim2.new(0, 6, 0, 32 + listH + 4)
    addButton.Size = UDim2.new(0.62, -9, 0, 20)
    addButton.BackgroundColor3 = Color3.fromRGB(34, 34, 38)
    addButton.BorderSizePixel = 0
    addButton.AutoButtonColor = true
    addButton.Font = Enum.Font.GothamBold
    addButton.Text = "+ ADD NEAREST"
    addButton.TextSize = 9
    addButton.TextColor3 = Color3.fromRGB(226, 226, 232)
    addButton.Parent = panel
    qCorner(addButton, 5)
    qStroke(addButton, Color3.fromRGB(56, 56, 62), 0.15)

    local clearButton = Instance.new("TextButton")
    clearButton.Name = "Clear"
    clearButton.Position = UDim2.new(0.62, 3, 0, 32 + listH + 4)
    clearButton.Size = UDim2.new(0.38, -9, 0, 20)
    clearButton.BackgroundColor3 = Color3.fromRGB(34, 34, 38)
    clearButton.BorderSizePixel = 0
    clearButton.AutoButtonColor = true
    clearButton.Font = Enum.Font.GothamBold
    clearButton.Text = "CLEAR"
    clearButton.TextSize = 9
    clearButton.TextColor3 = Color3.fromRGB(226, 226, 232)
    clearButton.Parent = panel
    qCorner(clearButton, 5)
    qStroke(clearButton, Color3.fromRGB(56, 56, 62), 0.15)

    addButton.MouseButton1Click:Connect(asAddNearestToPriority)
    clearButton.MouseButton1Click:Connect(function()
        table.clear(AS.priorityKeys)
        asRebuildPriorityRanks()
        asRefreshPriorityPanel()
        asNotify("Priority list cleared")
    end)

    AS.panelGui = gui
    AS.panel = panel
    AS.panelList = list
    AS.panelSummary = summary

    asBindPanelDrag(panel, titleBar, title, summary)
    asRefreshPriorityPanel()
end

local function asClosePriorityPanel()
    for _, conn in ipairs(AS.panelDrag) do
        pcall(function() conn:Disconnect() end)
    end
    table.clear(AS.panelDrag)
    if AS.panelGui then
        pcall(function() AS.panelGui:Destroy() end)
    end
    AS.panelGui = nil
    AS.panel = nil
    AS.panelList = nil
    AS.panelSummary = nil
    AS.panelRows = {}
end

local function asSetMode(mode)
    AS.mode = mode
    AS.brainrots = {}
    AS.byPrompt = {}
    AS.nearestCache = nil

    if mode then
        local ok, err = pcall(asRefreshScan)
        if not ok then AS.lastError = err end
        asNotify("Auto Steal " .. (mode == "priority" and "Priority" or "Nearest") .. " on")
    else
        asNotify("Auto Steal off")
        asStealBarStop()
        asEspStop()
        asClosePriorityPanel()
    end
end

task.spawn(asLoop)

-- MISC SETTINGS SECTION
local MiscSettings = Main:addSection({
    text = "Misc Settings",
    side = "left",
    showMinButton = true
})

MiscSettings:addLabel({
    text = "General Settings"
})

local fpsBoostToggle
local extremeFpsToggle

fpsBoostToggle = MiscSettings:addToggle({
    text = "FPS Optimizer",
    state = false
}, function(state)
    if state then
        if extremeFpsToggle and extremeFpsToggle.toggled then
            extremeFpsToggle:disable()
        end
        fpsSetLevel(1)
    elseif FPSOptimizer.level == 1 then
        fpsSetLevel(0)
    end
end)

extremeFpsToggle = MiscSettings:addToggle({
    text = "Extreme FPS Optimizer",
    state = false
}, function(state)
    if state then
        if fpsBoostToggle and fpsBoostToggle.toggled then
            fpsBoostToggle:disable()
        end
        fpsSetLevel(2)
    elseif FPSOptimizer.level == 2 then
        fpsSetLevel(0)
    end
end)

local autoStealNearestToggle
local autoStealPriorityToggle

autoStealNearestToggle = MiscSettings:addToggle({
    text = "Auto Steal Nearest",
    state = false
}, function(state)
    if state then
        if autoStealPriorityToggle and autoStealPriorityToggle.toggled then
            autoStealPriorityToggle:disable()
        end
        asSetMode("nearest")
    elseif AS.mode == "nearest" then
        asSetMode(nil)
    end
end)

autoStealPriorityToggle = MiscSettings:addToggle({
    text = "Auto Steal Priority",
    state = false
}, function(state)
    if state then
        if autoStealNearestToggle and autoStealNearestToggle.toggled then
            autoStealNearestToggle:disable()
        end
        asSetMode("priority")
        asOpenPriorityPanel()
    else
        if AS.mode == "priority" then
            asSetMode(nil)
        else
            asClosePriorityPanel()
        end
    end
end)


-- CONFIGS SECTION
local Configs = Main:addSection({
    text = "Configs",
    side = "right",
    showMinButton = true
})

Configs:addLabel({
    text = "Configuration Manager"
})

-- ==========================================
-- OTHER TABS
-- ==========================================

local Visuals = window:addMenu({
    text = "Visuals"
})

local Player = window:addMenu({
    text = "Player"
})

local Misc = window:addMenu({
    text = "Misc"
})

local Settings = window:addMenu({
    text = "Settings"
})
