--[[
    PRIME HUB | NOVA UI
    Example showcase for the Nova UI library.
    Run from a client context that supports loadstring and game:HttpGet.
]]

local Nova = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/mercurez9/Prime-Hub/refs/heads/main/PrimeLib.lua"
))()

local Window = Nova:CreateWindow({
    Title = "PRIME  /  COMMUNITY",
    Size = UDim2.fromOffset(760, 490),
    ToggleKey = Enum.KeyCode.RightControl,
    Theme = {
        Background = Color3.fromRGB(12, 14, 19),
        Panel = Color3.fromRGB(18, 21, 28),
        Element = Color3.fromRGB(25, 29, 38),
        ElementHover = Color3.fromRGB(33, 39, 51),
        Accent = Color3.fromRGB(80, 145, 255),
        Text = Color3.fromRGB(240, 243, 250),
        Muted = Color3.fromRGB(137, 148, 168),
        Border = Color3.fromRGB(54, 65, 84),
    },
})

-- OVERVIEW
local Home = Window:CreateTab({ Name = "Overview" })
local Session = Home:CreateSection({ Name = "SESSION", Side = "Left" })
local Quick = Home:CreateSection({ Name = "QUICK ACTIONS", Side = "Right" })

Session:AddParagraph({
    Title = "Welcome to Prime",
    Content = "A clean control panel for your Roblox experience. Choose a tab to explore the available interface components.",
})

Session:AddLabel({ Name = "SESSION INFORMATION", TextSize = 10, Color = Color3.fromRGB(105, 160, 255) })
Session:AddLabel({ Name = "Status     •     Interface loaded" })
Session:AddLabel({ Name = "Library    •     Nova UI" })
Session:AddLabel({ Name = "Toggle     •     RightControl" })

Quick:AddButton({
    Name = "Test notification",
    Callback = function()
        Window:Notify({
            Title = "Prime Hub",
            Content = "Notifications are working correctly.",
            Duration = 3,
        })
    end,
})
Quick:AddButton({
    Name = "Print test message",
    Callback = function()
        print("[Prime Hub] Button pressed")
    end,
})
Quick:AddDivider()
Quick:AddToggle({
    Name = "Demo toggle",
    Flag = "DemoToggle",
    Default = true,
    Callback = function(value)
        print("Demo toggle:", value)
    end,
})

-- PLAYER
local Player = Window:CreateTab({ Name = "Player" })
local Movement = Player:CreateSection({ Name = "MOVEMENT", Side = "Left" })
local Character = Player:CreateSection({ Name = "CHARACTER", Side = "Right" })

Movement:AddSlider({
    Name = "Walk speed",
    Flag = "WalkSpeedDemo",
    Min = 0,
    Max = 100,
    Default = 16,
    Round = 0,
    Callback = function(value)
        print("Walk speed demo:", value)
    end,
})
Movement:AddSlider({
    Name = "Jump power",
    Flag = "JumpPowerDemo",
    Min = 0,
    Max = 150,
    Default = 50,
    Round = 0,
    Callback = function(value)
        print("Jump power demo:", value)
    end,
})
Movement:AddDropdown({
    Name = "Movement mode",
    Flag = "MovementMode",
    Options = { "Default", "Smooth", "Custom" },
    Default = "Default",
    Callback = function(value)
        print("Movement mode:", value)
    end,
})

Character:AddToggle({
    Name = "Demo character option",
    Default = false,
    Callback = function(value)
        print("Character option:", value)
    end,
})
Character:AddButton({
    Name = "Reset demo values",
    Callback = function()
        Nova:SetFlag("WalkSpeedDemo", 16)
        Nova:SetFlag("JumpPowerDemo", 50)
        print("Demo values reset in flag storage")
    end,
})

-- VISUALS
local Visuals = Window:CreateTab({ Name = "Visuals" })
local PlayerVisuals = Visuals:CreateSection({ Name = "PLAYER VISUALS", Side = "Left" })
local WorldVisuals = Visuals:CreateSection({ Name = "WORLD", Side = "Right" })

PlayerVisuals:AddToggle({
    Name = "Player highlight",
    Default = false,
    Callback = function(value)
        print("Player highlight demo:", value)
    end,
})
PlayerVisuals:AddToggle({
    Name = "Display names",
    Default = true,
    Callback = function(value)
        print("Display names demo:", value)
    end,
})
PlayerVisuals:AddToggle({
    Name = "Show distance",
    Default = false,
    Callback = function(value)
        print("Show distance demo:", value)
    end,
})
WorldVisuals:AddDropdown({
    Name = "Highlight color",
    Options = { "Blue", "White", "Purple", "Red" },
    Default = "Blue",
    Callback = function(value)
        print("Highlight color demo:", value)
    end,
})
WorldVisuals:AddSlider({
    Name = "Visual range",
    Min = 50,
    Max = 1000,
    Default = 250,
    Round = 0,
    Callback = function(value)
        print("Visual range demo:", value)
    end,
})

-- SETTINGS
local Settings = Window:CreateTab({ Name = "Settings" })
local Interface = Settings:CreateSection({ Name = "INTERFACE", Side = "Left" })
local Information = Settings:CreateSection({ Name = "INFORMATION", Side = "Right" })

Interface:AddKeybind({
    Name = "UI toggle key",
    Default = Enum.KeyCode.RightControl,
    Callback = function(key)
        print("Key pressed:", key.Name)
    end,
})
Interface:AddToggle({
    Name = "Demo setting",
    Default = false,
    Callback = function(value)
        print("Demo setting:", value)
    end,
})
Interface:AddTextbox({
    Name = "Custom label",
    Placeholder = "Enter a label...",
    Callback = function(value)
        print("Custom label:", value)
    end,
})

Information:AddParagraph({
    Title = "Nova UI",
    Content = "A lightweight Roblox interface library. This example demonstrates the available controls; demo callbacks only print values and do not change gameplay.",
})
Information:AddLabel({ Name = "Prime Hub  •  Nova UI" })
Information:AddLabel({ Name = "RightControl  •  Hide / show" })

Window:Notify({
    Title = "Prime Hub",
    Content = "Interface loaded successfully.",
    Duration = 3,
})
