# Nova UI Library

A lightweight, customizable Roblox client UI library for building organized interfaces. Nova uses a dark charcoal theme with restrained blue accents, rounded panels, thin outlines, and consistent spacing.

## Installation

Place `PrimeLib.lua` somewhere accessible to your project. In a Roblox Studio project, you can use a ModuleScript and require it:

```lua
local Nova = require(path.to.PrimeLib)
```

For this repository, use the raw GitHub URL in a client environment that supports `loadstring` and `game:HttpGet`:

```lua
local Nova = loadstring(game:HttpGet("https://raw.githubusercontent.com/mercurez9/Prime-Hub/refs/heads/main/PrimeLib.lua"))()
```

The library creates its ScreenGui under the local player's PlayerGui. Use it from a LocalScript or another client-side context.

## Quick start

```lua
local Nova = require(path.to.PrimeLib)

local Window = Nova:CreateWindow({
    Title = "Prime Hub",
    Size = UDim2.fromOffset(680, 460),
    Theme = {
        Accent = Color3.fromRGB(85, 155, 255),
    },
})

local Main = Window:CreateTab({ Name = "Main", Icon = "⌂" })
local General = Main:CreateSection({ Name = "General", Side = "Left" })

General:AddButton({
    Name = "Print message",
    Callback = function()
        print("Hello from Nova")
    end,
})

General:AddToggle({
    Name = "Enabled",
    Flag = "Enabled",
    Default = false,
    Callback = function(value)
        print("Enabled:", value)
    end,
})

General:AddSlider({
    Name = "Amount",
    Min = 0,
    Max = 100,
    Default = 50,
    Callback = function(value)
        print("Amount:", value)
    end,
})
```

## API

### `Nova:CreateWindow(options)`

Creates a window and returns a Window object.

| Option | Type | Default | Description |
|---|---|---|---|
| `Title` | string | `"Nova UI"` | Text displayed in the title bar |
| `Size` | UDim2 | 680 × 460 | Window dimensions |
| `Position` | UDim2 | centered | Initial window position |
| `GuiName` | string | `"NovaUI"` | ScreenGui name; an existing GUI with this name is replaced |
| `Theme` | table | default theme | Theme color overrides |
| `Accent` | Color3 | theme accent | Shortcut for changing the accent color |

Theme keys: `Background`, `Panel`, `Element`, `ElementHover`, `Accent`, `Text`, `Muted`, `Border`, and `Success`.

### Window methods

- `Window:CreateTab({ Name, Icon })` — creates a tab and returns a Tab object. `Icon` is optional text/emoji.
- `Window:SelectTab(tab)` — selects a tab created by this window.
- `Window:Notify({ Title, Content, Duration })` — displays a temporary notification.
- `Window:SetVisible(boolean)` — shows or hides the window.
- `Window:Destroy()` — removes the ScreenGui.

### `Tab:CreateSection(options)`

Creates a section in a tab. Sections automatically stack and resize.

| Option | Type | Default | Description |
|---|---|---|---|
| `Name` | string | `"Section"` | Section heading |
| `Side` | string | `"Left"` | `"Left"` or `"Right"` column |

### Section elements

Every element method returns a small control object where applicable.

#### `Section:AddLabel({ Name, TextSize, Color, Height, Wrapped })`

Adds a simple label. Returned object: `label:Set(text)`.

#### `Section:AddDivider()`

Adds a thin horizontal divider.

#### `Section:AddButton({ Name, Callback, Height })`

Runs `Callback()` when clicked.

#### `Section:AddToggle({ Name, Flag, Default, Callback })`

Creates an animated switch. Callback receives a boolean. Returned object supports `control:Set(boolean)` and `control:Get()`.

#### `Section:AddSlider({ Name, Min, Max, Default, Round, Flag, Callback })`

Creates a draggable slider. Callback receives the current number. `Round` optionally sets decimal places (for example, `0` for integers or `2` for two decimals). Returned object supports `Set(number)` and `Get()`.

#### `Section:AddDropdown({ Name, Options, Default, Flag, Callback })`

Creates a dropdown. Callback receives the selected option. Returned object supports `Set(value)`, `Get()`, and `Refresh(newOptions)`.

#### `Section:AddTextbox({ Name, Default, Placeholder, Flag, Callback })`

Creates a text input. Callback receives `text, enterPressed` when focus is lost. Returned object supports `Set(text)` and `Get()`.

#### `Section:AddKeybind({ Name, Default, Flag, Callback })`

Creates a key picker. Click the key field, then press a key. Callback runs when the selected key is pressed. The callback receives the selected KeyCode. The default is `Enum.KeyCode.RightControl`.

#### `Section:AddParagraph({ Title, Content })`

Adds a title and wrapped description. Returned object supports `SetTitle(text)` and `SetContent(text)`.

## Flags

Elements with a `Flag` option store their latest value in Nova's flag table.

```lua
print(Nova:GetFlag("Enabled"))
Nova:SetFlag("Enabled", true)
```

Flags are in-memory only; this version does not automatically save configuration files.

## Example: two-column layout

```lua
local Left = Main:CreateSection({ Name = "General", Side = "Left" })
local Right = Main:CreateSection({ Name = "Options", Side = "Right" })

Left:AddToggle({ Name = "Feature", Default = false })
Right:AddDropdown({
    Name = "Mode",
    Options = { "Smooth", "Instant", "Manual" },
    Default = "Smooth",
})
```

## Notes

- This is a client-side UI library; create it from a LocalScript/client context.
- Use callbacks for your own game logic. The library only provides interface controls.
- Keybind callbacks ignore input already processed by Roblox.
- The library does not include persistence/config saving, icon asset loading, or automatic mobile-specific resizing yet.
