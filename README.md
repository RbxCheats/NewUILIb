# NewUILib

A compact, dark Roblox UI library with tabs, two-column sections, toggles, sliders, dropdowns, color pickers, keybinds and buttons. One file, loaded with `loadstring`.

## Quick start

```lua
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/RbxCheats/NewUILIb/main/Library.lua"))()

local Window = Library:CreateWindow({ Title = "My Script" })
local Tab = Window:AddTab("Main")
local Section = Tab:AddSection("Player", "Left")

Section:AddToggle({
    Name = "Enabled",
    Default = false,
    Callback = function(value)
        print("Enabled:", value)
    end,
})

Section:AddSlider({
    Name = "Walk Speed",
    Min = 16,
    Max = 100,
    Default = 16,
    Callback = function(value)
        game.Players.LocalPlayer.Character.Humanoid.WalkSpeed = value
    end,
})
```

Want to see everything at once? Run the demo:

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/RbxCheats/NewUILIb/main/Example.lua"))()
```

**Controls:** drag the window by its title bar. Press `RightShift` to hide / show it (changeable).

## How it is laid out

```
Window
└── Tab            (the buttons along the top)
    └── Section    (a titled box in the "Left" or "Right" column)
        └── Elements (toggle, slider, dropdown, ...)
```

## Window

```lua
local Window = Library:CreateWindow({
    Title = "My Script",                    -- text in the title bar
    Accent = Color3.fromRGB(255, 0, 0),     -- highlight color (default red)
    Size = UDim2.fromOffset(500, 600),      -- window size (default 500x600)
    ToggleKey = Enum.KeyCode.RightShift,    -- hide/show key, false to disable
})
```

| Method | What it does |
| --- | --- |
| `Window:AddTab(name)` | Adds a tab and returns it. The first tab is selected automatically. |
| `Window:SetVisible(bool)` / `Window:Toggle()` | Show or hide the window. |
| `Window:SetTitle(text)` | Change the title. |
| `Window:SetToggleKey(keyCode)` | Change the hide/show key. |

## Tabs and sections

```lua
local Tab = Window:AddTab("Visuals")
local Left = Tab:AddSection("Players", "Left")
local Right = Tab:AddSection("Colors", "Right")
```

The second argument is the column: `"Left"` (default) or `"Right"`. Columns scroll if they get too tall. `Tab:Select()` switches to a tab from code.

## Elements

Every element takes a table of options. Options shared by most elements:

| Option | Meaning |
| --- | --- |
| `Name` | The text shown. |
| `Default` | Starting value. |
| `Callback` | Function called when the user changes the value. |
| `Flag` | Optional name. The value is then readable at `Library.Flags[Flag]`. |

Every element returns an object with `:Set(value)` and `:Get()`.

### Toggle

The box fills with the accent color when it is on.

```lua
local Toggle = Section:AddToggle({
    Name = "Boxes",
    Default = false,
    Flag = "Boxes",
    Callback = function(value) -- true / false
    end,
})

Toggle:Set(true)
print(Toggle:Get())
```

A toggle can carry a color picker and/or a keybind on the right side of its row:

```lua
Toggle:AddColorPicker({
    Default = Color3.fromRGB(255, 255, 255),
    Flag = "BoxColor",
    Callback = function(color) end,
})

Toggle:AddKeybind({ Default = Enum.KeyCode.E }) -- pressing E flips the toggle
```

### Slider

```lua
Section:AddSlider({
    Name = "Distance",
    Min = 0,
    Max = 10000,
    Default = 2000,
    Increment = 1,       -- step size, use 0.1 / 0.01 for decimals
    Suffix = " studs",   -- text after the number
    Flag = "Distance",
    Callback = function(value) end,
})
```

### Dropdown

```lua
local Dropdown = Section:AddDropdown({
    Name = "Measurement",
    Options = { "Roblox", "Meters", "Feet" },
    Default = "Roblox",
    Flag = "Measurement",
    Callback = function(option) end,
})

Dropdown:Set("Meters")
Dropdown:Refresh({ "A", "B", "C" }) -- replace the options
```

Multi-select: add `Multi = true`. `Default`, the callback value and `:Get()` are then lists.

```lua
Section:AddDropdown({
    Name = "Shown Info",
    Options = { "Name", "Distance", "Health" },
    Default = { "Name" },
    Multi = true,
    Callback = function(selected) -- e.g. { "Name", "Health" }
    end,
})
```

### Color picker

Click the swatch to open the picker: drag in the square for saturation / brightness, drag the bar for hue, or type a hex code.

```lua
Section:AddColorPicker({
    Name = "Crosshair Color",
    Default = Color3.fromRGB(80, 200, 255),
    Flag = "CrosshairColor",
    Callback = function(color) -- Color3
    end,
})
```

### Button

```lua
Section:AddButton({
    Name = "Click Me",
    Callback = function()
        print("clicked")
    end,
})
```

### Keybind

Click it, then press a key. `Esc` or `Backspace` clears it.

```lua
Section:AddKeybind({
    Name = "Toggle Menu",
    Default = Enum.KeyCode.RightShift,
    Callback = function(key) end,  -- the bound key was pressed
    Changed = function(key)        -- the user bound a different key (nil = cleared)
        Window:SetToggleKey(key)
    end,
})
```

### Label

```lua
local Label = Section:AddLabel("Status: idle")
Label:Set("Status: running")
```

## Flags

Give an element a `Flag` and read its value from anywhere, without callbacks:

```lua
Section:AddToggle({ Name = "Enabled", Flag = "Enabled" })
Section:AddSlider({ Name = "Speed", Min = 0, Max = 100, Flag = "Speed" })

game:GetService("RunService").Heartbeat:Connect(function()
    if Library.Flags.Enabled then
        print(Library.Flags.Speed)
    end
end)
```

`Library.Options[Flag]` gives the element object, so `Library.Options.Speed:Set(50)` works too.

`:Set(value, true)` on any element changes the value without firing its callback.

## Unloading

```lua
Library:Unload() -- removes the UI and disconnects everything the library created
```
