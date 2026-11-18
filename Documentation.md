
local Window  = Nova:CreateWindow({ Title = "Nova | v1.0" })
local Tab     = Window:CreateTab("Main")
local Section = Tab:CreateSection("General")

Section:AddToggle({ Name = "Enabled", Flag = "Enabled", Callback = function(v) end })
Section:AddSlider({ Name = "Amount", Min = 0, Max = 100, Default = 50 })
Section:AddDropdown({ Name = "Mode", Options = {"A","B"} })
Section:AddButton / AddTextbox / AddKeybind / AddLabel / AddDivider
Window:Notify({ Title = "Hi", Content = "Works", Duration = 3 })
