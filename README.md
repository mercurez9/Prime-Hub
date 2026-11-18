# Prime Hub — Nova UI Library

A reusable Roblox client-side UI library with a compact dark interface, blue accent outlines, draggable windows, tabs, two-column sections, and common UI controls.

## Repository

- [Library source](PrimeLib.lua)
- [Documentation](Documentation.md)
- [Working example](Example.lua)

## Quick start

Use the raw GitHub URL in a client environment that supports `loadstring` and `game:HttpGet`:

```lua
local Nova = loadstring(game:HttpGet("https://raw.githubusercontent.com/mercurez9/Prime-Hub/refs/heads/main/PrimeLib.lua"))()
local Window = Nova:CreateWindow({ Title = "My Hub" })
local Tab = Window:CreateTab({ Name = "Main" })
local Section = Tab:CreateSection({ Name = "General", Side = "Left" })

Section:AddToggle({
    Name = "Example",
    Default = false,
    Callback = function(value)
        print(value)
    end,
})
```

See [Documentation.md](Documentation.md) for the full API and [Example.lua](Example.lua) for a multi-tab example.

## Current controls

Button, toggle, slider, dropdown, textbox, keybind, label, divider, and paragraph.

## License

No license has been added yet. Add a license file if you want to specify reuse and distribution terms.
