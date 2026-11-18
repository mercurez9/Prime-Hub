-- PrimeLib / Nova example
-- Run from a LocalScript in a Roblox Studio project.
-- If using a ModuleScript, update the require path below.

local Nova = require(game.ReplicatedStorage:WaitForChild("PrimeLib"))

local Window = Nova:CreateWindow({
    Title = "Prime Hub",
    Size = UDim2.fromOffset(680, 460),
    Theme = {
        Accent = Color3.fromRGB(78, 145, 255),
        Background = Color3.fromRGB(18, 20, 25),
        Panel = Color3.fromRGB(24, 27, 34),
    },
})

local Main = Window:CreateTab({ Name = "Main", Icon = "⌂" })
local Visuals = Window:CreateTab({ Name = "Visuals", Icon = "◉" })
local Settings = Window:CreateTab({ Name = "Settings", Icon = "⚙" })

local General = Main:CreateSection({ Name = "General", Side = "Left" })
local Values = Main:CreateSection({ Name = "Values", Side = "Right" })

General:AddParagraph({
    Title = "Welcome",
    Content = "This is a sample layout built with the Nova UI library.",
})

General:AddButton({
    Name = "Send notification",
    Callback = function()
        Window:Notify({
            Title = "Prime Hub",
            Content = "Your button works.",
            Duration = 3,
        })
    end,
})

General:AddToggle({
    Name = "Example toggle",
    Flag = "ExampleToggle",
    Default = false,
    Callback = function(value)
        print("Toggle:", value)
    end,
})

Values:AddSlider({
    Name = "Example amount",
    Flag = "ExampleAmount",
    Min = 0,
    Max = 100,
    Default = 35,
    Round = 0,
    Callback = function(value)
        print("Slider:", value)
    end,
})

Values:AddDropdown({
    Name = "Example mode",
    Flag = "ExampleMode",
    Options = { "Smooth", "Instant", "Manual" },
    Default = "Smooth",
    Callback = function(value)
        print("Dropdown:", value)
    end,
})

local VisualSection = Visuals:CreateSection({ Name = "Visual options", Side = "Left" })
VisualSection:AddToggle({
    Name = "Show markers",
    Default = true,
    Callback = function(value)
        print("Show markers:", value)
    end,
})
VisualSection:AddColorPlaceholder -- intentionally not part of this library; see supported elements in Documentation.md

local SettingsSection = Settings:CreateSection({ Name = "Interface", Side = "Left" })
SettingsSection:AddTextbox({
    Name = "Display name",
    Placeholder = "Type something...",
    Callback = function(text)
        print("Textbox:", text)
    end,
})
SettingsSection:AddKeybind({
    Name = "Example keybind",
    Default = Enum.KeyCode.RightShift,
    Callback = function(key)
        print("Pressed:", key.Name)
    end,
})
SettingsSection:AddDivider()
SettingsSection:AddLabel({ Name = "Nova UI • Prime Hub" })

task.delay(1, function()
    Window:Notify({
        Title = "Nova loaded",
        Content = "The example interface is ready.",
        Duration = 3,
    })
end)
