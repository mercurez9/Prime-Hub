--[[
    Nova UI Library
    Prime-Hub | Roblox client-side UI framework
    API: CreateWindow -> CreateTab -> CreateSection -> AddElement
]]

local Nova = {}
Nova.__index = Nova

Nova.Flags = {}

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer

local DEFAULT_THEME = {
    Background = Color3.fromRGB(18, 20, 25),
    Panel = Color3.fromRGB(24, 27, 34),
    Element = Color3.fromRGB(30, 34, 43),
    ElementHover = Color3.fromRGB(38, 44, 55),
    Accent = Color3.fromRGB(85, 155, 255),
    Text = Color3.fromRGB(238, 242, 250),
    Muted = Color3.fromRGB(145, 155, 172),
    Border = Color3.fromRGB(65, 112, 175),
    Success = Color3.fromRGB(100, 210, 145),
}

local function create(className, properties, children)
    local object = Instance.new(className)
    for property, value in pairs(properties or {}) do
        object[property] = value
    end
    for _, child in ipairs(children or {}) do
        child.Parent = object
    end
    return object
end

local function corner(parent, radius)
    return create("UICorner", { CornerRadius = UDim.new(0, radius or 8), Parent = parent })
end

local function stroke(parent, color, transparency, thickness)
    return create("UIStroke", {
        Color = color,
        Transparency = transparency or 0,
        Thickness = thickness or 1,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        Parent = parent,
    })
end

local function padding(parent, left, right, top, bottom)
    return create("UIPadding", {
        PaddingLeft = UDim.new(0, left or 0),
        PaddingRight = UDim.new(0, right or 0),
        PaddingTop = UDim.new(0, top or 0),
        PaddingBottom = UDim.new(0, bottom or 0),
        Parent = parent,
    })
end

local function listLayout(parent, gap, direction)
    return create("UIListLayout", {
        FillDirection = direction or Enum.FillDirection.Vertical,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, gap or 6),
        Parent = parent,
    })
end

local function tween(object, duration, properties)
    local animation = TweenService:Create(object, TweenInfo.new(duration or 0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), properties)
    animation:Play()
    return animation
end

local function makeLabel(parent, text, size, color, font)
    return create("TextLabel", {
        BackgroundTransparency = 1,
        Text = tostring(text or ""),
        TextColor3 = color,
        TextSize = size or 13,
        Font = font or Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
        Size = UDim2.new(1, 0, 1, 0),
        Parent = parent,
    })
end

local function getTheme(config)
    local theme = {}
    for key, value in pairs(DEFAULT_THEME) do
        theme[key] = value
    end
    if type(config) == "table" then
        for key, value in pairs(config) do
            if theme[key] ~= nil then
                theme[key] = value
            end
        end
    end
    return theme
end

local function flagValue(flag, value)
    if flag and flag ~= "" then
        Nova.Flags[flag] = value
    end
end

function Nova:GetFlag(flag)
    return self.Flags[flag]
end

function Nova:SetFlag(flag, value)
    self.Flags[flag] = value
end

function Nova:CreateWindow(config)
    config = config or {}
    local theme = getTheme(config.Theme)
    if typeof(config.Accent) == "Color3" then
        theme.Accent = config.Accent
    end

    local playerGui = LocalPlayer:WaitForChild("PlayerGui")
    local old = playerGui:FindFirstChild(config.GuiName or "NovaUI")
    if old then old:Destroy() end

    local gui = create("ScreenGui", {
        Name = config.GuiName or "NovaUI",
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        Parent = playerGui,
    })

    local size = config.Size or UDim2.fromOffset(680, 460)
    local main = create("Frame", {
        Name = "Main",
        Size = size,
        Position = config.Position or UDim2.new(0.5, -size.X.Offset / 2, 0.5, -size.Y.Offset / 2),
        BackgroundColor3 = theme.Background,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        Parent = gui,
    })
    corner(main, 11)
    stroke(main, theme.Border, 0.18, 1.2)

    local topbar = create("Frame", {
        Name = "Topbar",
        Size = UDim2.new(1, 0, 0, 43),
        BackgroundColor3 = theme.Panel,
        BorderSizePixel = 0,
        Parent = main,
    })
    create("Frame", {
        Size = UDim2.new(1, 0, 0, 1),
        Position = UDim2.new(0, 0, 1, -1),
        BackgroundColor3 = theme.Border,
        BackgroundTransparency = 0.35,
        BorderSizePixel = 0,
        Parent = topbar,
    })
    local title = makeLabel(create("Frame", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(15, 0),
        Size = UDim2.new(1, -115, 1, 0),
        Parent = topbar,
    }), config.Title or "Nova UI", 14, theme.Text, Enum.Font.GothamSemibold)

    local minimize = create("TextButton", {
        Text = "—",
        TextSize = 17,
        Font = Enum.Font.GothamBold,
        TextColor3 = theme.Muted,
        BackgroundColor3 = theme.Element,
        AutoButtonColor = false,
        Size = UDim2.fromOffset(30, 27),
        Position = UDim2.new(1, -75, 0.5, -13),
        Parent = topbar,
    })
    corner(minimize, 6)
    local close = create("TextButton", {
        Text = "×",
        TextSize = 20,
        Font = Enum.Font.Gotham,
        TextColor3 = theme.Muted,
        BackgroundColor3 = theme.Element,
        AutoButtonColor = false,
        Size = UDim2.fromOffset(30, 27),
        Position = UDim2.new(1, -39, 0.5, -13),
        Parent = topbar,
    })
    corner(close, 6)

    local sidebar = create("Frame", {
        Name = "Sidebar",
        Position = UDim2.fromOffset(0, 44),
        Size = UDim2.new(0, 145, 1, -44),
        BackgroundColor3 = theme.Panel,
        BorderSizePixel = 0,
        Parent = main,
    })
    padding(sidebar, 9, 9, 12, 9)
    local tabList = listLayout(sidebar, 6)

    local content = create("Frame", {
        Name = "Content",
        Position = UDim2.new(0, 145, 0, 44),
        Size = UDim2.new(1, -145, 1, -44),
        BackgroundTransparency = 1,
        Parent = main,
    })

    local window = {
        Gui = gui,
        Main = main,
        Theme = theme,
        Tabs = {},
        CurrentTab = nil,
        _minimized = false,
        _normalSize = size,
    }

    -- Dragging is limited to the title bar so controls remain easy to use.
    do
        local dragging, dragInput, dragStart, startPosition
        topbar.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                dragStart = input.Position
                startPosition = main.Position
                input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then dragging = false end
                end)
            end
        end)
        topbar.InputChanged:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
                dragInput = input
            end
        end)
        UserInputService.InputChanged:Connect(function(input)
            if dragging and input == dragInput then
                local delta = input.Position - dragStart
                main.Position = UDim2.new(startPosition.X.Scale, startPosition.X.Offset + delta.X, startPosition.Y.Scale, startPosition.Y.Offset + delta.Y)
            end
        end)
    end

    function window:SelectTab(tab)
        if self.CurrentTab == tab then return end
        for _, item in ipairs(self.Tabs) do
            item.Page.Visible = item == tab
            tween(item.Button, 0.13, {
                BackgroundColor3 = item == tab and theme.ElementHover or theme.Panel,
                TextColor3 = item == tab and theme.Text or theme.Muted,
            })
        end
        self.CurrentTab = tab
    end

    function window:CreateTab(tabConfig)
        tabConfig = type(tabConfig) == "table" and tabConfig or { Name = tostring(tabConfig) }
        local tabName = tabConfig.Name or "Tab"
        local button = create("TextButton", {
            Name = tabName .. "Tab",
            Size = UDim2.new(1, 0, 0, 34),
            BackgroundColor3 = theme.Panel,
            Text = (tabConfig.Icon and (tostring(tabConfig.Icon) .. "   ") or "") .. tabName,
            TextColor3 = theme.Muted,
            TextSize = 12,
            Font = Enum.Font.GothamMedium,
            TextXAlignment = Enum.TextXAlignment.Left,
            AutoButtonColor = false,
            Parent = sidebar,
        })
        corner(button, 7)
        padding(button, 10, 6, 0, 0)

        local page = create("ScrollingFrame", {
            Name = tabName .. "Page",
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ScrollBarThickness = 3,
            ScrollBarImageColor3 = theme.Accent,
            CanvasSize = UDim2.new(),
            Visible = false,
            Parent = content,
        })
        padding(page, 12, 12, 12, 12)

        local columns = {}
        for _, side in ipairs({"Left", "Right"}) do
            local column = create("Frame", {
                Name = side .. "Column",
                BackgroundTransparency = 1,
                Size = UDim2.new(0.5, -7, 0, 0),
                AutomaticSize = Enum.AutomaticSize.Y,
                Parent = page,
            })
            if side == "Right" then
                column.Position = UDim2.new(0.5, 7, 0, 0)
            end
            local layout = listLayout(column, 10)
            layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                column.Size = UDim2.new(0.5, -7, 0, layout.AbsoluteContentSize.Y)
                local left = page:FindFirstChild("LeftColumn")
                local right = page:FindFirstChild("RightColumn")
                local height = math.max(left and left.AbsoluteSize.Y or 0, right and right.AbsoluteSize.Y or 0)
                page.CanvasSize = UDim2.new(0, 0, 0, height + 24)
            end)
            columns[side] = column
        end

        local tab = { Name = tabName, Button = button, Page = page, Columns = columns, Window = window }
        table.insert(window.Tabs, tab)
        button.MouseButton1Click:Connect(function() window:SelectTab(tab) end)
        if #window.Tabs == 1 then window:SelectTab(tab) end

        function tab:CreateSection(sectionConfig)
            sectionConfig = type(sectionConfig) == "table" and sectionConfig or { Name = tostring(sectionConfig) }
            local sectionName = sectionConfig.Name or "Section"
            local side = sectionConfig.Side == "Right" and "Right" or "Left"
            local panel = create("Frame", {
                Name = sectionName:gsub("%s+", "") .. "Section",
                Size = UDim2.new(1, 0, 0, 40),
                AutomaticSize = Enum.AutomaticSize.Y,
                BackgroundColor3 = theme.Panel,
                BorderSizePixel = 0,
                Parent = columns[side],
            })
            corner(panel, 8)
            stroke(panel, theme.Border, 0.48, 1)
            local header = create("Frame", {
                Size = UDim2.new(1, 0, 0, 34),
                BackgroundTransparency = 1,
                Parent = panel,
            })
            padding(header, 11, 10, 0, 0)
            makeLabel(header, sectionName, 12, theme.Text, Enum.Font.GothamSemibold)
            local body = create("Frame", {
                Name = "Elements",
                Position = UDim2.fromOffset(0, 34),
                Size = UDim2.new(1, 0, 0, 0),
                AutomaticSize = Enum.AutomaticSize.Y,
                BackgroundTransparency = 1,
                Parent = panel,
            })
            padding(body, 8, 8, 0, 9)
            local bodyLayout = listLayout(body, 6)
            local section = { Frame = panel, Container = body, Theme = theme }

            local function elementRow(name, height)
                return create("Frame", {
                    Name = name or "Element",
                    Size = UDim2.new(1, 0, 0, height or 34),
                    BackgroundColor3 = theme.Element,
                    BorderSizePixel = 0,
                    Parent = body,
                })
            end

            function section:AddLabel(options)
                options = type(options) == "table" and options or { Name = tostring(options) }
                local row = create("Frame", {
                    Size = UDim2.new(1, 0, 0, options.Height or 25),
                    BackgroundTransparency = 1,
                    Parent = body,
                })
                local label = makeLabel(row, options.Name or "Label", options.TextSize or 12, options.Color or theme.Muted)
                label.TextWrapped = options.Wrapped or false
                return { Set = function(_, value) label.Text = tostring(value) end, Label = label }
            end

            function section:AddDivider()
                local line = create("Frame", {
                    Size = UDim2.new(1, 0, 0, 1),
                    BackgroundColor3 = theme.Border,
                    BackgroundTransparency = 0.45,
                    BorderSizePixel = 0,
                    Parent = body,
                })
                return line
            end

            function section:AddButton(options)
                options = type(options) == "table" and options or { Name = tostring(options) }
                local row = elementRow("Button", options.Height or 34)
                corner(row, 6)
                local buttonElement = create("TextButton", {
                    Size = UDim2.new(1, 0, 1, 0),
                    BackgroundTransparency = 1,
                    Text = options.Name or "Button",
                    TextColor3 = theme.Text,
                    TextSize = 12,
                    Font = Enum.Font.GothamMedium,
                    AutoButtonColor = false,
                    Parent = row,
                })
                buttonElement.MouseEnter:Connect(function() tween(row, 0.12, {BackgroundColor3 = theme.ElementHover}) end)
                buttonElement.MouseLeave:Connect(function() tween(row, 0.12, {BackgroundColor3 = theme.Element}) end)
                buttonElement.MouseButton1Click:Connect(function()
                    if options.Callback then task.spawn(options.Callback) end
                end)
                return { Button = buttonElement, SetText = function(_, value) buttonElement.Text = tostring(value) end }
            end

            function section:AddToggle(options)
                options = options or {}
                local value = options.Default == true
                local row = elementRow("Toggle", 36)
                corner(row, 6)
                local label = makeLabel(create("Frame", {
                    BackgroundTransparency = 1,
                    Position = UDim2.fromOffset(10, 0),
                    Size = UDim2.new(1, -62, 1, 0),
                    Parent = row,
                }), options.Name or "Toggle", 12, theme.Text)
                local switch = create("Frame", {
                    Size = UDim2.fromOffset(36, 19),
                    Position = UDim2.new(1, -45, 0.5, -9),
                    BackgroundColor3 = value and theme.Accent or theme.Background,
                    BorderSizePixel = 0,
                    Parent = row,
                })
                corner(switch, 20)
                local knob = create("Frame", {
                    Size = UDim2.fromOffset(13, 13),
                    Position = value and UDim2.new(1, -16, 0.5, -6) or UDim2.fromOffset(3, 3),
                    BackgroundColor3 = Color3.fromRGB(245, 247, 250),
                    BorderSizePixel = 0,
                    Parent = switch,
                })
                corner(knob, 20)
                local click = create("TextButton", {
                    Size = UDim2.new(1, 0, 1, 0),
                    BackgroundTransparency = 1,
                    Text = "",
                    Parent = row,
                })
                local function setValue(nextValue, silent)
                    value = nextValue == true
                    tween(switch, 0.15, {BackgroundColor3 = value and theme.Accent or theme.Background})
                    tween(knob, 0.15, {Position = value and UDim2.new(1, -16, 0.5, -6) or UDim2.fromOffset(3, 3)})
                    flagValue(options.Flag, value)
                    if not silent and options.Callback then task.spawn(options.Callback, value) end
                end
                click.MouseButton1Click:Connect(function() setValue(not value) end)
                flagValue(options.Flag, value)
                if options.Callback then task.spawn(options.Callback, value) end
                return { Set = function(_, v) setValue(v, true) end, Get = function() return value end }
            end

            function section:AddSlider(options)
                options = options or {}
                local min = tonumber(options.Min) or 0
                local max = tonumber(options.Max) or 100
                if max <= min then max = min + 1 end
                local value = math.clamp(tonumber(options.Default) or min, min, max)
                local row = elementRow("Slider", 52)
                corner(row, 6)
                local name = makeLabel(create("Frame", {
                    BackgroundTransparency = 1,
                    Position = UDim2.fromOffset(10, 3),
                    Size = UDim2.new(1, -75, 0, 20),
                    Parent = row,
                }), options.Name or "Slider", 12, theme.Text)
                local valueText = makeLabel(create("Frame", {
                    BackgroundTransparency = 1,
                    Position = UDim2.new(1, -65, 0, 3),
                    Size = UDim2.fromOffset(55, 20),
                    Parent = row,
                }), value, 11, theme.Muted)
                valueText.TextXAlignment = Enum.TextXAlignment.Right
                local bar = create("Frame", {
                    Position = UDim2.new(0, 10, 0, 32),
                    Size = UDim2.new(1, -20, 0, 7),
                    BackgroundColor3 = theme.Background,
                    BorderSizePixel = 0,
                    Parent = row,
                })
                corner(bar, 8)
                local fill = create("Frame", {
                    Size = UDim2.new((value - min) / (max - min), 0, 1, 0),
                    BackgroundColor3 = theme.Accent,
                    BorderSizePixel = 0,
                    Parent = bar,
                })
                corner(fill, 8)
                local hitbox = create("TextButton", {
                    Size = UDim2.new(1, 0, 0, 20),
                    Position = UDim2.new(0, 0, 0, -6),
                    BackgroundTransparency = 1,
                    Text = "",
                    Parent = bar,
                })
                local dragging = false
                local function setValue(v, silent)
                    value = math.clamp(tonumber(v) or min, min, max)
                    if options.Round then
                        local places = tonumber(options.Round) or 0
                        local mult = 10 ^ places
                        value = math.floor(value * mult + 0.5) / mult
                    end
                    local alpha = (value - min) / (max - min)
                    fill.Size = UDim2.new(alpha, 0, 1, 0)
                    valueText.Text = tostring(value)
                    flagValue(options.Flag, value)
                    if not silent and options.Callback then task.spawn(options.Callback, value) end
                end
                local function update(input)
                    local alpha = math.clamp((input.Position.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
                    setValue(min + (max - min) * alpha)
                end
                hitbox.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                        dragging = true
                        update(input)
                    end
                end)
                UserInputService.InputChanged:Connect(function(input)
                    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then update(input) end
                end)
                UserInputService.InputEnded:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = false end
                end)
                setValue(value, true)
                return { Set = function(_, v) setValue(v, true) end, Get = function() return value end }
            end

            function section:AddDropdown(options)
                options = options or {}
                local selected = options.Default
                local expanded = false
                local row = elementRow("Dropdown", 36)
                corner(row, 6)
                local title = makeLabel(create("Frame", {
                    BackgroundTransparency = 1,
                    Position = UDim2.fromOffset(10, 0),
                    Size = UDim2.new(1, -105, 1, 0),
                    Parent = row,
                }), options.Name or "Dropdown", 12, theme.Text)
                local current = create("TextButton", {
                    Position = UDim2.new(1, -112, 0, 5),
                    Size = UDim2.fromOffset(102, 26),
                    BackgroundColor3 = theme.Background,
                    Text = tostring(selected or "Select") .. "  ▾",
                    TextColor3 = theme.Muted,
                    TextSize = 10,
                    Font = Enum.Font.Gotham,
                    AutoButtonColor = false,
                    Parent = row,
                })
                corner(current, 5)
                local optionHolder = create("Frame", {
                    Size = UDim2.new(1, 0, 0, 0),
                    AutomaticSize = Enum.AutomaticSize.Y,
                    BackgroundTransparency = 1,
                    Visible = false,
                    Parent = body,
                })
                local optionLayout = listLayout(optionHolder, 4)
                local function setValue(v, silent)
                    selected = v
                    current.Text = tostring(v) .. "  ▾"
                    flagValue(options.Flag, v)
                    if not silent and options.Callback then task.spawn(options.Callback, v) end
                end
                local function refresh()
                    for _, child in ipairs(optionHolder:GetChildren()) do
                        if child:IsA("TextButton") then child:Destroy() end
                    end
                    for _, option in ipairs(options.Options or {}) do
                        local optionButton = create("TextButton", {
                            Size = UDim2.new(1, 0, 0, 28),
                            BackgroundColor3 = theme.Element,
                            Text = tostring(option),
                            TextColor3 = theme.Text,
                            TextSize = 11,
                            Font = Enum.Font.Gotham,
                            AutoButtonColor = false,
                            Parent = optionHolder,
                        })
                        corner(optionButton, 5)
                        optionButton.MouseButton1Click:Connect(function()
                            setValue(option)
                            expanded = false
                            optionHolder.Visible = false
                            optionHolder.Size = UDim2.new(1, 0, 0, 0)
                        end)
                    end
                end
                refresh()
                current.MouseButton1Click:Connect(function()
                    expanded = not expanded
                    optionHolder.Visible = expanded
                    optionHolder.Size = expanded and UDim2.new(1, 0, 0, 0) or UDim2.new(1, 0, 0, 0)
                end)
                if selected ~= nil then flagValue(options.Flag, selected) end
                return {
                    Set = function(_, v) setValue(v, true) end,
                    Get = function() return selected end,
                    Refresh = function(_, newOptions)
                        options.Options = newOptions or {}
                        refresh()
                    end,
                }
            end

            function section:AddTextbox(options)
                options = options or {}
                local row = elementRow("Textbox", 36)
                corner(row, 6)
                makeLabel(create("Frame", {
                    BackgroundTransparency = 1,
                    Position = UDim2.fromOffset(10, 0),
                    Size = UDim2.new(0.42, -5, 1, 0),
                    Parent = row,
                }), options.Name or "Textbox", 12, theme.Text)
                local box = create("TextBox", {
                    Position = UDim2.new(0.42, 0, 0, 5),
                    Size = UDim2.new(0.58, -10, 1, -10),
                    BackgroundColor3 = theme.Background,
                    Text = tostring(options.Default or ""),
                    PlaceholderText = options.Placeholder or "Enter text...",
                    PlaceholderColor3 = theme.Muted,
                    TextColor3 = theme.Text,
                    TextSize = 11,
                    Font = Enum.Font.Gotham,
                    ClearTextOnFocus = false,
                    Parent = row,
                })
                corner(box, 5)
                padding(box, 7, 7, 0, 0)
                box.FocusLost:Connect(function(enterPressed)
                    flagValue(options.Flag, box.Text)
                    if options.Callback then task.spawn(options.Callback, box.Text, enterPressed) end
                end)
                flagValue(options.Flag, box.Text)
                return { Set = function(_, v) box.Text = tostring(v) end, Get = function() return box.Text end, Input = box }
            end

            function section:AddKeybind(options)
                options = options or {}
                local key = options.Default or Enum.KeyCode.RightControl
                local listening = false
                local row = elementRow("Keybind", 36)
                corner(row, 6)
                makeLabel(create("Frame", {
                    BackgroundTransparency = 1,
                    Position = UDim2.fromOffset(10, 0),
                    Size = UDim2.new(1, -100, 1, 0),
                    Parent = row,
                }), options.Name or "Keybind", 12, theme.Text)
                local keyButton = create("TextButton", {
                    Position = UDim2.new(1, -88, 0, 5),
                    Size = UDim2.fromOffset(78, 26),
                    BackgroundColor3 = theme.Background,
                    Text = key.Name,
                    TextColor3 = theme.Muted,
                    TextSize = 10,
                    Font = Enum.Font.Gotham,
                    AutoButtonColor = false,
                    Parent = row,
                })
                corner(keyButton, 5)
                keyButton.MouseButton1Click:Connect(function()
                    listening = true
                    keyButton.Text = "Press key..."
                end)
                UserInputService.InputBegan:Connect(function(input, processed)
                    if processed then return end
                    if listening then
                        if input.KeyCode ~= Enum.KeyCode.Unknown then
                            key = input.KeyCode
                            keyButton.Text = key.Name
                            listening = false
                            flagValue(options.Flag, key)
                        end
                    elseif input.KeyCode == key then
                        if options.Callback then task.spawn(options.Callback, key) end
                    end
                end)
                flagValue(options.Flag, key)
                return {
                    Set = function(_, newKey)
                        if typeof(newKey) == "EnumItem" then
                            key = newKey
                            keyButton.Text = key.Name
                            flagValue(options.Flag, key)
                        end
                    end,
                    Get = function() return key end,
                }
            end

            function section:AddParagraph(options)
                options = options or {}
                local row = create("Frame", {
                    Size = UDim2.new(1, 0, 0, 58),
                    BackgroundColor3 = theme.Element,
                    BorderSizePixel = 0,
                    Parent = body,
                })
                corner(row, 6)
                padding(row, 9, 9, 6, 6)
                local heading = makeLabel(create("Frame", {
                    Size = UDim2.new(1, 0, 0, 18),
                    BackgroundTransparency = 1,
                    Parent = row,
                }), options.Title or "Information", 12, theme.Text, Enum.Font.GothamSemibold)
                local description = create("TextLabel", {
                    Position = UDim2.fromOffset(0, 20),
                    Size = UDim2.new(1, 0, 1, -20),
                    BackgroundTransparency = 1,
                    Text = options.Content or "",
                    TextColor3 = theme.Muted,
                    TextSize = 11,
                    Font = Enum.Font.Gotham,
                    TextWrapped = true,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextYAlignment = Enum.TextYAlignment.Top,
                    Parent = row,
                })
                return {
                    SetTitle = function(_, v) heading.Text = tostring(v) end,
                    SetContent = function(_, v) description.Text = tostring(v) end,
                }
            end

            return section
        end

        return tab
    end

    function window:Notify(options)
        options = options or {}
        local holder = gui:FindFirstChild("Notifications")
        if not holder then
            holder = create("Frame", {
                Name = "Notifications",
                AnchorPoint = Vector2.new(1, 1),
                Position = UDim2.new(1, -16, 1, -16),
                Size = UDim2.fromOffset(280, 220),
                BackgroundTransparency = 1,
                Parent = gui,
            })
            listLayout(holder, 8)
        end
        local card = create("Frame", {
            Size = UDim2.new(1, 0, 0, 70),
            BackgroundColor3 = theme.Panel,
            BackgroundTransparency = 0.04,
            BorderSizePixel = 0,
            Parent = holder,
        })
        corner(card, 8)
        stroke(card, theme.Border, 0.25, 1)
        padding(card, 11, 10, 7, 7)
        makeLabel(create("Frame", {
            Size = UDim2.new(1, 0, 0, 20),
            BackgroundTransparency = 1,
            Parent = card,
        }), options.Title or "Notification", 12, theme.Text, Enum.Font.GothamSemibold)
        local body = create("TextLabel", {
            Position = UDim2.fromOffset(0, 22),
            Size = UDim2.new(1, 0, 1, -22),
            BackgroundTransparency = 1,
            Text = options.Content or "",
            TextColor3 = theme.Muted,
            TextSize = 11,
            Font = Enum.Font.Gotham,
            TextWrapped = true,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Top,
            Parent = card,
        })
        card.BackgroundTransparency = 1
        tween(card, 0.18, {BackgroundTransparency = 0.04})
        task.delay(tonumber(options.Duration) or 3, function()
            if card and card.Parent then
                tween(card, 0.16, {BackgroundTransparency = 1})
                task.wait(0.18)
                if card then card:Destroy() end
            end
        end)
        return card
    end

    function window:SetVisible(visible)
        main.Visible = visible == true
    end

    function window:Destroy()
        gui:Destroy()
    end

    minimize.MouseButton1Click:Connect(function()
        window._minimized = not window._minimized
        sidebar.Visible = not window._minimized
        content.Visible = not window._minimized
        tween(main, 0.18, {
            Size = window._minimized and UDim2.new(size.X.Scale, size.X.Offset, 0, 43) or window._normalSize,
        })
    end)
    close.MouseButton1Click:Connect(function() window:Destroy() end)

    return window
end

return setmetatable(Nova, Nova)
