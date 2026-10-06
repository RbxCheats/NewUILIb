--[[
    NewUILib
    https://github.com/RbxCheats/NewUILIb

    local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/RbxCheats/NewUILIb/main/Library.lua"))()

    See README.md for the full API.
]]

local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

local Library = {
    Flags = {}, -- Flags[flag] = current value
    Options = {}, -- Options[flag] = element object (:Set / :Get)
    Theme = {
        Accent = Color3.fromRGB(255, 0, 0),
        Background = Color3.fromRGB(22, 22, 22),
        Element = Color3.fromRGB(12, 12, 12),
        Border = Color3.fromRGB(42, 42, 42),
        Outline = Color3.fromRGB(0, 0, 0),
        Text = Color3.fromRGB(235, 235, 235),
        DimText = Color3.fromRGB(110, 110, 110),
    },
    Unloaded = false,
    _connections = {},
    _guis = {},
}

local FONT_FAMILY = "rbxasset://fonts/families/GothamSSm.json"
local FONT = Font.new(FONT_FAMILY, Enum.FontWeight.Medium)
local FONT_BOLD = Font.new(FONT_FAMILY, Enum.FontWeight.Bold)
local TEXT_SIZE = 12

----------------------------------------------------------------------
-- helpers
----------------------------------------------------------------------

local function connect(signal, fn)
    local connection = signal:Connect(fn)
    table.insert(Library._connections, connection)
    return connection
end

local function create(class, props, children)
    local inst = Instance.new(class)
    if inst:IsA("GuiObject") then
        inst.BorderSizePixel = 0
    end
    if inst:IsA("GuiButton") then
        inst.AutoButtonColor = false
    end
    if inst:IsA("TextLabel") or inst:IsA("TextButton") or inst:IsA("TextBox") then
        inst.FontFace = FONT
        inst.TextSize = TEXT_SIZE
        inst.TextColor3 = Library.Theme.Text
        inst.BackgroundTransparency = 1
    end
    local parent
    for key, value in pairs(props or {}) do
        if key == "Parent" then
            parent = value
        else
            inst[key] = value
        end
    end
    for _, child in ipairs(children or {}) do
        child.Parent = inst
    end
    inst.Parent = parent
    return inst
end

local function stroke(color)
    return create("UIStroke", {
        Color = color or Library.Theme.Border,
        Thickness = 1,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        LineJoinMode = Enum.LineJoinMode.Miter,
    })
end

local function isPress(input)
    return input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch
end

local function isMove(input)
    return input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch
end

local function isInside(gui, position)
    local pos, size = gui.AbsolutePosition, gui.AbsoluteSize
    return position.X >= pos.X and position.X <= pos.X + size.X
        and position.Y >= pos.Y and position.Y <= pos.Y + size.Y
end

-- Calls onMove(input) while the mouse / finger is held down on `target`.
local function trackDrag(target, onMove, onBegin)
    local dragging = false
    connect(target.InputBegan, function(input)
        if isPress(input) then
            dragging = true
            if onBegin then
                onBegin(input)
            end
            onMove(input)
        end
    end)
    connect(UserInputService.InputChanged, function(input)
        if dragging and isMove(input) then
            onMove(input)
        end
    end)
    connect(UserInputService.InputEnded, function(input)
        if isPress(input) then
            dragging = false
        end
    end)
end

local function safeCall(callback, ...)
    if typeof(callback) ~= "function" then
        return
    end
    local ok, err = pcall(callback, ...)
    if not ok then
        warn("[NewUILib] callback error: " .. tostring(err))
    end
end

local function parentGui(gui)
    local ok, hidden = pcall(function()
        return gethui()
    end)
    if ok and typeof(hidden) == "Instance" then
        gui.Parent = hidden
        return
    end
    if pcall(function()
        gui.Parent = game:GetService("CoreGui")
    end) then
        return
    end
    gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
end

local function decimalsOf(increment)
    local fraction = string.match(tostring(increment), "%.(%d+)")
    return fraction and #fraction or 0
end

----------------------------------------------------------------------
-- popups (dropdown lists / color pickers) - only one open at a time
----------------------------------------------------------------------

local openPopup -- { frame, owner, close }

local function closePopup()
    local popup = openPopup
    if popup then
        openPopup = nil
        popup.close()
    end
end

-- Places `frame` (a child of `layer`) right under `owner`, kept on screen.
local function placePopup(layer, frame, owner, alignRight)
    local origin = owner.AbsolutePosition - layer.AbsolutePosition
    local size = Vector2.new(frame.Size.X.Offset, frame.Size.Y.Offset)
    local x = alignRight and (origin.X + owner.AbsoluteSize.X - size.X) or origin.X
    local y = origin.Y + owner.AbsoluteSize.Y + 3
    if y + size.Y > layer.AbsoluteSize.Y then
        y = origin.Y - size.Y - 3
    end
    x = math.clamp(x, 0, math.max(0, layer.AbsoluteSize.X - size.X))
    frame.Position = UDim2.fromOffset(x, math.max(0, y))
end

connect(UserInputService.InputBegan, function(input)
    if openPopup and isPress(input) then
        if not isInside(openPopup.frame, input.Position) and not isInside(openPopup.owner, input.Position) then
            closePopup()
        end
    end
end)

----------------------------------------------------------------------
-- addons: things that sit on the right side of a row
----------------------------------------------------------------------

local function registerFlag(flag, object, value)
    if flag then
        Library.Flags[flag] = value
        Library.Options[flag] = object
    end
end

local function addColorPicker(layer, holder, opts)
    opts = opts or {}
    local theme = Library.Theme
    local callback = opts.Callback
    local flag = opts.Flag
    local color = opts.Default or Color3.new(1, 1, 1)
    local hue, sat, val = color:ToHSV()

    local picker = { Type = "ColorPicker" }

    local swatch = create("TextButton", {
        Name = "ColorPicker",
        Text = "",
        Size = UDim2.fromOffset(34, 12),
        BackgroundTransparency = 0,
        BackgroundColor3 = color,
        LayoutOrder = 2,
        Parent = holder,
    }, { stroke(theme.Outline) })

    local popup = create("Frame", {
        Name = "ColorPopup",
        Size = UDim2.fromOffset(190, 190),
        BackgroundColor3 = theme.Background,
        Visible = false,
        Active = true,
        Parent = layer,
    }, { stroke(theme.Border) })

    local svMap = create("Frame", {
        Position = UDim2.fromOffset(6, 6),
        Size = UDim2.fromOffset(152, 152),
        BackgroundColor3 = Color3.fromHSV(hue, 1, 1),
        Parent = popup,
    }, {
        stroke(theme.Outline),
        create("Frame", { -- saturation: white -> transparent
            Size = UDim2.fromScale(1, 1),
            BackgroundColor3 = Color3.new(1, 1, 1),
        }, {
            create("UIGradient", { Transparency = NumberSequence.new(0, 1) }),
        }),
        create("Frame", { -- value: transparent -> black
            Size = UDim2.fromScale(1, 1),
            BackgroundColor3 = Color3.new(0, 0, 0),
        }, {
            create("UIGradient", { Transparency = NumberSequence.new(1, 0), Rotation = 90 }),
        }),
    })
    local svCursor = create("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Size = UDim2.fromOffset(4, 4),
        BackgroundColor3 = Color3.new(1, 1, 1),
        Parent = svMap,
    }, { stroke(theme.Outline) })
    local svInput = create("TextButton", { Text = "", Size = UDim2.fromScale(1, 1), Parent = svMap })

    local hueKeys = {}
    for i = 0, 6 do
        table.insert(hueKeys, ColorSequenceKeypoint.new(i / 6, Color3.fromHSV(i / 6, 1, 1)))
    end
    local hueBar = create("Frame", {
        Position = UDim2.fromOffset(164, 6),
        Size = UDim2.fromOffset(20, 152),
        BackgroundColor3 = Color3.new(1, 1, 1),
        Parent = popup,
    }, {
        stroke(theme.Outline),
        create("UIGradient", { Color = ColorSequence.new(hueKeys), Rotation = 90 }),
    })
    local hueCursor = create("Frame", {
        AnchorPoint = Vector2.new(0, 0.5),
        Size = UDim2.new(1, 0, 0, 2),
        BackgroundColor3 = Color3.new(1, 1, 1),
        Parent = hueBar,
    }, { stroke(theme.Outline) })
    local hueInput = create("TextButton", { Text = "", Size = UDim2.fromScale(1, 1), Parent = hueBar })

    local hexBox = create("TextBox", {
        Position = UDim2.fromOffset(6, 164),
        Size = UDim2.new(1, -12, 0, 20),
        BackgroundTransparency = 0,
        BackgroundColor3 = theme.Element,
        ClearTextOnFocus = false,
        PlaceholderText = "#FFFFFF",
        Parent = popup,
    }, { stroke(theme.Border) })

    local function refresh(silent)
        color = Color3.fromHSV(hue, sat, val)
        swatch.BackgroundColor3 = color
        svMap.BackgroundColor3 = Color3.fromHSV(hue, 1, 1)
        svCursor.Position = UDim2.fromScale(sat, 1 - val)
        hueCursor.Position = UDim2.fromScale(0, hue)
        hexBox.Text = "#" .. string.upper(color:ToHex())
        if flag then
            Library.Flags[flag] = color
        end
        if not silent then
            safeCall(callback, color)
        end
    end

    trackDrag(svInput, function(input)
        local pos, size = svMap.AbsolutePosition, svMap.AbsoluteSize
        sat = math.clamp((input.Position.X - pos.X) / size.X, 0, 1)
        val = 1 - math.clamp((input.Position.Y - pos.Y) / size.Y, 0, 1)
        refresh()
    end)

    trackDrag(hueInput, function(input)
        hue = math.clamp((input.Position.Y - hueBar.AbsolutePosition.Y) / hueBar.AbsoluteSize.Y, 0, 1)
        refresh()
    end)

    connect(hexBox.FocusLost, function()
        local ok, parsed = pcall(Color3.fromHex, hexBox.Text)
        if ok then
            picker:Set(parsed)
        else
            refresh(true)
        end
    end)

    connect(swatch.MouseButton1Click, function()
        if openPopup and openPopup.frame == popup then
            closePopup()
            return
        end
        closePopup()
        popup.Visible = true
        placePopup(layer, popup, swatch, true)
        openPopup = {
            frame = popup,
            owner = swatch,
            close = function()
                popup.Visible = false
            end,
        }
    end)

    function picker:Set(newColor, silent)
        hue, sat, val = newColor:ToHSV()
        refresh(silent)
    end

    function picker:Get()
        return color
    end

    registerFlag(flag, picker, color)
    refresh(true)
    return picker
end

local function addKeybind(holder, opts, onPressed)
    opts = opts or {}
    local theme = Library.Theme
    local callback = opts.Callback
    local flag = opts.Flag
    local key = opts.Default
    local binding = false

    local keybind = { Type = "Keybind" }

    local button = create("TextButton", {
        Name = "Keybind",
        Size = UDim2.fromOffset(0, 14),
        AutomaticSize = Enum.AutomaticSize.X,
        TextColor3 = theme.DimText,
        LayoutOrder = 1,
        Parent = holder,
    })

    local function refresh()
        button.Text = binding and "[...]" or ("[" .. (key and key.Name or "None") .. "]")
        if flag then
            Library.Flags[flag] = key
        end
    end

    connect(button.MouseButton1Click, function()
        binding = true
        refresh()
    end)

    connect(UserInputService.InputBegan, function(input)
        if input.UserInputType ~= Enum.UserInputType.Keyboard then
            return
        end
        if binding then
            binding = false
            if input.KeyCode == Enum.KeyCode.Escape or input.KeyCode == Enum.KeyCode.Backspace then
                key = nil
            else
                key = input.KeyCode
            end
            refresh()
            safeCall(opts.Changed, key)
            return
        end
        if key and input.KeyCode == key and not UserInputService:GetFocusedTextBox() then
            if onPressed then
                onPressed()
            end
            safeCall(callback, key)
        end
    end)

    function keybind:Set(newKey)
        key = newKey
        refresh()
    end

    function keybind:Get()
        return key
    end

    registerFlag(flag, keybind, key)
    refresh()
    return keybind
end

----------------------------------------------------------------------
-- window
----------------------------------------------------------------------

function Library:CreateWindow(opts)
    if typeof(opts) == "string" then
        opts = { Title = opts }
    end
    opts = opts or {}
    local theme = self.Theme
    if opts.Accent then
        theme.Accent = opts.Accent
    end
    local size = opts.Size or UDim2.fromOffset(500, 600)
    local toggleKey = opts.ToggleKey
    if toggleKey == nil then
        toggleKey = Enum.KeyCode.RightShift
    end

    local gui = create("ScreenGui", {
        Name = "NewUILib",
        ResetOnSpawn = false,
        IgnoreGuiInset = true,
        DisplayOrder = 999,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    })
    parentGui(gui)
    table.insert(self._guis, gui)

    local main = create("Frame", {
        Name = "Main",
        Position = UDim2.new(0.5, -size.X.Offset / 2, 0.5, -size.Y.Offset / 2),
        Size = size,
        BackgroundColor3 = theme.Background,
        Active = true,
        Parent = gui,
    }, { stroke(theme.Outline) })

    -- dropdown lists and color pickers live here so they draw above everything
    local layer = create("Frame", {
        Name = "Popups",
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        ZIndex = 10,
        Parent = gui,
    })

    local title = create("TextLabel", {
        Name = "Title",
        Size = UDim2.new(1, 0, 0, 22),
        Text = opts.Title or "NewUILib",
        Active = true,
        Parent = main,
    })

    create("Frame", {
        Name = "AccentLine",
        Position = UDim2.fromOffset(0, 22),
        Size = UDim2.new(1, 0, 0, 1),
        BackgroundColor3 = theme.Accent,
        Parent = main,
    })

    local tabBar = create("Frame", {
        Name = "Tabs",
        Position = UDim2.fromOffset(6, 24),
        Size = UDim2.new(1, -12, 0, 22),
        BackgroundTransparency = 1,
        Parent = main,
    }, {
        create("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal,
            SortOrder = Enum.SortOrder.LayoutOrder,
        }),
    })

    local pages = create("Frame", {
        Name = "Pages",
        Position = UDim2.fromOffset(6, 47),
        Size = UDim2.new(1, -12, 1, -53),
        BackgroundColor3 = theme.Background,
        Parent = main,
    }, { stroke(theme.Border) })

    local dragStart, dragOrigin
    trackDrag(title, function(input)
        local delta = input.Position - dragStart
        main.Position = UDim2.new(
            dragOrigin.X.Scale, dragOrigin.X.Offset + delta.X,
            dragOrigin.Y.Scale, dragOrigin.Y.Offset + delta.Y
        )
    end, function(input)
        dragStart = input.Position
        dragOrigin = main.Position
    end)

    local Window = { Tabs = {}, Gui = gui }
    local selected

    function Window:SetVisible(visible)
        closePopup()
        main.Visible = visible
    end

    function Window:Toggle()
        self:SetVisible(not main.Visible)
    end

    function Window:SetTitle(text)
        title.Text = text
    end

    function Window:SetToggleKey(key)
        toggleKey = key
    end

    connect(UserInputService.InputBegan, function(input)
        if toggleKey and input.KeyCode == toggleKey and not UserInputService:GetFocusedTextBox() then
            Window:Toggle()
        end
    end)

    function Window:AddTab(name)
        local Tab = { Name = name }

        local button = create("TextButton", {
            Name = name,
            Text = name,
            FontFace = FONT_BOLD,
            LayoutOrder = #self.Tabs + 1,
            Parent = tabBar,
        })

        local page = create("Frame", {
            Name = name,
            Size = UDim2.fromScale(1, 1),
            BackgroundTransparency = 1,
            Visible = false,
            Parent = pages,
        })

        local columns = {}
        for index, side in ipairs({ "Left", "Right" }) do
            columns[side] = create("ScrollingFrame", {
                Name = side,
                Position = UDim2.fromScale((index - 1) / 2, 0),
                Size = UDim2.fromScale(0.5, 1),
                BackgroundTransparency = 1,
                CanvasSize = UDim2.new(),
                AutomaticCanvasSize = Enum.AutomaticSize.Y,
                ScrollBarThickness = 0,
                ScrollingDirection = Enum.ScrollingDirection.Y,
                Parent = page,
            }, {
                create("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }),
                create("UIPadding", {
                    PaddingTop = UDim.new(0, 5),
                    PaddingBottom = UDim.new(0, 5),
                    PaddingLeft = UDim.new(0, index == 1 and 5 or 3),
                    PaddingRight = UDim.new(0, index == 1 and 3 or 5),
                }),
            })
            connect(columns[side]:GetPropertyChangedSignal("CanvasPosition"), closePopup)
        end

        function Tab:Select()
            if selected then
                selected.page.Visible = false
                selected.button.TextColor3 = theme.Text
            end
            closePopup()
            selected = { page = page, button = button }
            page.Visible = true
            button.TextColor3 = theme.Accent
        end

        connect(button.MouseButton1Click, function()
            Tab:Select()
        end)

        function Tab:AddSection(sectionName, side)
            if typeof(sectionName) == "table" then
                side = sectionName.Side
                sectionName = sectionName.Name
            end
            local column = columns[side == "Right" and "Right" or "Left"]
            local Section = { Name = sectionName }

            local frame = create("Frame", {
                Name = sectionName or "Section",
                Size = UDim2.new(1, 0, 0, 0),
                AutomaticSize = Enum.AutomaticSize.Y,
                BackgroundColor3 = theme.Background,
                Parent = column,
            }, {
                stroke(theme.Border),
                create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder }),
                create("UIPadding", { PaddingBottom = UDim.new(0, 6) }),
                create("TextLabel", {
                    Name = "Title",
                    Size = UDim2.new(1, 0, 0, 20),
                    Text = sectionName or "",
                    FontFace = FONT_BOLD,
                    LayoutOrder = 1,
                }),
            })

            local content = create("Frame", {
                Name = "Content",
                Size = UDim2.new(1, 0, 0, 0),
                AutomaticSize = Enum.AutomaticSize.Y,
                BackgroundTransparency = 1,
                LayoutOrder = 2,
                Parent = frame,
            }, {
                create("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }),
                create("UIPadding", { PaddingLeft = UDim.new(0, 6), PaddingRight = UDim.new(0, 6) }),
            })

            -- A text row with a holder on the right for color pickers / keybinds.
            local function makeRow(class, text, indent)
                local row = create(class, {
                    Name = text,
                    Size = UDim2.new(1, 0, 0, 16),
                    BackgroundTransparency = 1,
                    Parent = content,
                })
                if class == "TextButton" then
                    row.Text = ""
                end
                local label = create("TextLabel", {
                    Position = UDim2.fromOffset(indent, 0),
                    Size = UDim2.new(1, -indent, 1, 0),
                    Text = text,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextTruncate = Enum.TextTruncate.AtEnd,
                    Parent = row,
                })
                local holder = create("Frame", {
                    Name = "Addons",
                    AnchorPoint = Vector2.new(1, 0),
                    Position = UDim2.fromScale(1, 0),
                    Size = UDim2.fromScale(0, 1),
                    AutomaticSize = Enum.AutomaticSize.X,
                    BackgroundTransparency = 1,
                    Parent = row,
                }, {
                    create("UIListLayout", {
                        FillDirection = Enum.FillDirection.Horizontal,
                        HorizontalAlignment = Enum.HorizontalAlignment.Right,
                        VerticalAlignment = Enum.VerticalAlignment.Center,
                        Padding = UDim.new(0, 6),
                        SortOrder = Enum.SortOrder.LayoutOrder,
                    }),
                })
                return row, label, holder
            end

            function Section:AddToggle(o)
                o = o or {}
                local value = o.Default == true
                local Toggle = { Type = "Toggle" }

                local row, _, holder = makeRow("TextButton", o.Name or "Toggle", 20)
                local box = create("Frame", {
                    Position = UDim2.new(0, 0, 0.5, -6),
                    Size = UDim2.fromOffset(12, 12),
                    BackgroundColor3 = theme.Element,
                    Parent = row,
                }, { stroke(theme.Border) })

                function Toggle:Set(newValue, silent)
                    value = newValue == true
                    TweenService:Create(box, TweenInfo.new(0.1), {
                        BackgroundColor3 = value and theme.Accent or theme.Element,
                    }):Play()
                    if o.Flag then
                        Library.Flags[o.Flag] = value
                    end
                    if not silent then
                        safeCall(o.Callback, value)
                    end
                end

                function Toggle:Get()
                    return value
                end

                function Toggle:AddColorPicker(pickerOpts)
                    return addColorPicker(layer, holder, pickerOpts)
                end

                -- pressing the bound key flips the toggle
                function Toggle:AddKeybind(keybindOpts)
                    return addKeybind(holder, keybindOpts, function()
                        Toggle:Set(not value)
                    end)
                end

                connect(row.MouseButton1Click, function()
                    Toggle:Set(not value)
                end)

                registerFlag(o.Flag, Toggle, value)
                box.BackgroundColor3 = value and theme.Accent or theme.Element
                return Toggle
            end

            function Section:AddButton(o)
                if typeof(o) == "string" then
                    o = { Name = o }
                end
                o = o or {}
                local button = create("TextButton", {
                    Name = o.Name or "Button",
                    Text = o.Name or "Button",
                    Size = UDim2.new(1, 0, 0, 20),
                    BackgroundTransparency = 0,
                    BackgroundColor3 = theme.Element,
                    Parent = content,
                }, { stroke(theme.Border) })

                connect(button.MouseButton1Click, function()
                    button.BackgroundColor3 = theme.Accent
                    TweenService:Create(button, TweenInfo.new(0.25), { BackgroundColor3 = theme.Element }):Play()
                    safeCall(o.Callback)
                end)

                local Button = { Type = "Button" }
                function Button:SetText(text)
                    button.Text = text
                end
                return Button
            end

            function Section:AddLabel(text)
                local _, label = makeRow("Frame", text or "", 0)
                local Label = { Type = "Label" }
                function Label:Set(newText)
                    label.Text = newText
                end
                return Label
            end

            function Section:AddSlider(o)
                o = o or {}
                local min, max = o.Min or 0, o.Max or 100
                local increment = o.Increment or 1
                local decimals = decimalsOf(increment)
                local suffix = o.Suffix or ""
                local name = o.Name or "Slider"
                local value
                local Slider = { Type = "Slider" }

                local holder = create("Frame", {
                    Name = name,
                    Size = UDim2.new(1, 0, 0, 30),
                    BackgroundTransparency = 1,
                    Parent = content,
                })
                local label = create("TextLabel", {
                    Size = UDim2.new(1, 0, 0, 16),
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent = holder,
                })
                local bar = create("Frame", {
                    Position = UDim2.fromOffset(0, 18),
                    Size = UDim2.new(1, 0, 0, 10),
                    BackgroundColor3 = theme.Element,
                    Parent = holder,
                }, { stroke(theme.Border) })
                local fill = create("Frame", {
                    Size = UDim2.fromScale(0, 1),
                    BackgroundColor3 = theme.Accent,
                    Parent = bar,
                })
                local input = create("TextButton", { Text = "", Size = UDim2.fromScale(1, 1), Parent = bar })

                function Slider:Set(newValue, silent)
                    newValue = tonumber(newValue) or min
                    newValue = min + math.floor((newValue - min) / increment + 0.5) * increment
                    newValue = math.clamp(newValue, min, max)
                    newValue = tonumber(string.format("%." .. decimals .. "f", newValue))
                    local changed = newValue ~= value
                    value = newValue
                    fill.Size = UDim2.fromScale(max == min and 0 or (value - min) / (max - min), 1)
                    label.Text = string.format("%s: %." .. decimals .. "f%s", name, value, suffix)
                    if o.Flag then
                        Library.Flags[o.Flag] = value
                    end
                    if changed and not silent then
                        safeCall(o.Callback, value)
                    end
                end

                function Slider:Get()
                    return value
                end

                trackDrag(input, function(inputObject)
                    local percent = (inputObject.Position.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X
                    Slider:Set(min + (max - min) * math.clamp(percent, 0, 1))
                end)

                Slider:Set(o.Default or min, true)
                registerFlag(o.Flag, Slider, value)
                return Slider
            end

            function Section:AddDropdown(o)
                o = o or {}
                local multi = o.Multi == true
                local options = o.Options or {}
                local name = o.Name or "Dropdown"
                local value -- single: option or nil, multi: { option, ... }
                local Dropdown = { Type = "Dropdown" }

                local holder = create("Frame", {
                    Name = name,
                    Size = UDim2.new(1, 0, 0, 38),
                    BackgroundTransparency = 1,
                    Parent = content,
                }, {
                    create("TextLabel", {
                        Size = UDim2.new(1, 0, 0, 16),
                        Text = name,
                        TextXAlignment = Enum.TextXAlignment.Left,
                    }),
                })
                local box = create("TextButton", {
                    Text = "",
                    Position = UDim2.fromOffset(0, 18),
                    Size = UDim2.new(1, 0, 0, 18),
                    BackgroundTransparency = 0,
                    BackgroundColor3 = theme.Element,
                    Parent = holder,
                }, { stroke(theme.Border) })
                local display = create("TextLabel", {
                    Position = UDim2.fromOffset(6, 0),
                    Size = UDim2.new(1, -26, 1, 0),
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextTruncate = Enum.TextTruncate.AtEnd,
                    Parent = box,
                })
                local arrow = create("TextLabel", {
                    AnchorPoint = Vector2.new(1, 0),
                    Position = UDim2.new(1, -4, 0, 0),
                    Size = UDim2.new(0, 14, 1, 0),
                    Text = "<",
                    FontFace = FONT_BOLD,
                    Parent = box,
                })

                local list = create("ScrollingFrame", {
                    Name = "DropdownList",
                    BackgroundTransparency = 0,
                    BackgroundColor3 = theme.Element,
                    CanvasSize = UDim2.new(),
                    AutomaticCanvasSize = Enum.AutomaticSize.Y,
                    ScrollBarThickness = 2,
                    ScrollBarImageColor3 = theme.Accent,
                    ScrollingDirection = Enum.ScrollingDirection.Y,
                    Visible = false,
                    Active = true,
                    Parent = layer,
                }, {
                    stroke(theme.Border),
                    create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder }),
                })

                local optionButtons = {}

                local function isSelected(option)
                    if multi then
                        return table.find(value, option) ~= nil
                    end
                    return value == option
                end

                local function refresh()
                    if multi then
                        local names = {}
                        for _, option in ipairs(value) do
                            table.insert(names, tostring(option))
                        end
                        display.Text = #names > 0 and table.concat(names, ", ") or "None"
                    else
                        display.Text = value ~= nil and tostring(value) or "None"
                    end
                    for option, button in pairs(optionButtons) do
                        button.TextColor3 = isSelected(option) and theme.Accent or theme.Text
                    end
                    if o.Flag then
                        Library.Flags[o.Flag] = value
                    end
                end

                local function close()
                    list.Visible = false
                    arrow.Text = "<"
                end

                local function build()
                    for _, button in pairs(optionButtons) do
                        button:Destroy()
                    end
                    optionButtons = {}
                    for index, option in ipairs(options) do
                        local button = create("TextButton", {
                            Text = "  " .. tostring(option),
                            Size = UDim2.new(1, 0, 0, 18),
                            TextXAlignment = Enum.TextXAlignment.Left,
                            LayoutOrder = index,
                            Parent = list,
                        })
                        optionButtons[option] = button
                        connect(button.MouseButton1Click, function()
                            if multi then
                                local found = table.find(value, option)
                                if found then
                                    table.remove(value, found)
                                else
                                    table.insert(value, option)
                                end
                            else
                                value = option
                                closePopup()
                            end
                            refresh()
                            safeCall(o.Callback, value)
                        end)
                    end
                end

                connect(box.MouseButton1Click, function()
                    if openPopup and openPopup.frame == list then
                        closePopup()
                        return
                    end
                    closePopup()
                    list.Size = UDim2.fromOffset(box.AbsoluteSize.X, math.min(#options, 8) * 18)
                    list.Visible = true
                    arrow.Text = "v"
                    placePopup(layer, list, box, false)
                    openPopup = { frame = list, owner = box, close = close }
                end)

                function Dropdown:Set(newValue, silent)
                    if multi then
                        value = {}
                        for _, option in ipairs(typeof(newValue) == "table" and newValue or { newValue }) do
                            if table.find(options, option) then
                                table.insert(value, option)
                            end
                        end
                    else
                        value = table.find(options, newValue) and newValue or nil
                    end
                    refresh()
                    if not silent then
                        safeCall(o.Callback, value)
                    end
                end

                function Dropdown:Get()
                    return value
                end

                -- replace the option list; keeps the current selection when it still exists
                function Dropdown:Refresh(newOptions)
                    closePopup()
                    options = newOptions or {}
                    build()
                    self:Set(value, true)
                end

                build()
                Dropdown:Set(o.Default, true)
                registerFlag(o.Flag, Dropdown, value)
                return Dropdown
            end

            function Section:AddColorPicker(o)
                o = o or {}
                local _, _, holder = makeRow("Frame", o.Name or "Color", 0)
                return addColorPicker(layer, holder, o)
            end

            function Section:AddKeybind(o)
                o = o or {}
                local _, _, holder = makeRow("Frame", o.Name or "Keybind", 0)
                return addKeybind(holder, o)
            end

            return Section
        end

        table.insert(self.Tabs, Tab)
        for _, child in ipairs(tabBar:GetChildren()) do
            if child:IsA("TextButton") then
                child.Size = UDim2.fromScale(1 / #self.Tabs, 1)
            end
        end
        if #self.Tabs == 1 then
            Tab:Select()
        end
        return Tab
    end

    return Window
end

-- Removes every window and disconnects every event the library made.
function Library:Unload()
    closePopup()
    for _, connection in ipairs(self._connections) do
        connection:Disconnect()
    end
    for _, gui in ipairs(self._guis) do
        gui:Destroy()
    end
    table.clear(self._connections)
    table.clear(self._guis)
    self.Unloaded = true
end

return Library
