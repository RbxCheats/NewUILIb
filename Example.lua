-- Test menu: uses every element and every method of the library, wired to things you can see.
-- loadstring(game:HttpGet("https://raw.githubusercontent.com/RbxCheats/NewUILIb/main/Example.lua"))()

local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/RbxCheats/NewUILIb/main/Library.lua"))()

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local StarterGui = game:GetService("StarterGui")

local Flags, Options = Library.Flags, Library.Options
local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local connections = {}
local function connect(signal, fn)
    table.insert(connections, signal:Connect(fn))
end

local function humanoid()
    return player.Character and player.Character:FindFirstChildOfClass("Humanoid")
end

-- values put back by the Unload button
local original = {
    Gravity = workspace.Gravity,
    ClockTime = Lighting.ClockTime,
    FieldOfView = camera.FieldOfView,
}

local Window = Library:CreateWindow({
    Title = "NewUILib | Test Menu",
    Accent = Color3.fromRGB(255, 0, 0),
    ToggleKey = Enum.KeyCode.RightShift,
})

local PlayerTab = Window:AddTab("Player")
local VisualsTab = Window:AddTab("Visuals")
local ElementsTab = Window:AddTab("Elements")
local SettingsTab = Window:AddTab("Settings")

----------------------------------------------------------------------
-- Player: sliders, toggles with keybind + color picker, buttons
----------------------------------------------------------------------

local function applyMovement()
    local hum = humanoid()
    if hum then
        hum.WalkSpeed = Flags.WalkSpeed
        hum.UseJumpPower = true
        hum.JumpPower = Flags.JumpPower
    end
end

local Movement = PlayerTab:AddSection("Movement", "Left")

Movement:AddSlider({
    Name = "Walk Speed",
    Min = 0,
    Max = 150,
    Default = 16,
    Suffix = " studs/s",
    Flag = "WalkSpeed",
    Callback = applyMovement,
})

Movement:AddSlider({
    Name = "Jump Power",
    Min = 0,
    Max = 300,
    Default = 50,
    Increment = 5,
    Flag = "JumpPower",
    Callback = applyMovement,
})

Movement:AddSlider({
    Name = "Gravity",
    Min = 0,
    Max = 400,
    Default = math.clamp(math.floor(original.Gravity + 0.5), 0, 400),
    Increment = 2,
    Flag = "Gravity",
    Callback = function(value)
        workspace.Gravity = value
    end,
})

Movement:AddToggle({
    Name = "Spin",
    Flag = "Spin",
}):AddKeybind({ Default = Enum.KeyCode.G, Flag = "SpinKey" })

Movement:AddSlider({
    Name = "Spin Speed",
    Min = 30,
    Max = 1080,
    Default = 360,
    Increment = 30,
    Suffix = " deg/s",
    Flag = "SpinSpeed",
})

Movement:AddKeybind({
    Name = "Hop",
    Default = Enum.KeyCode.H,
    Flag = "HopKey",
    Callback = function()
        local hum = humanoid()
        if hum then
            hum:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end,
})

Movement:AddButton({
    Name = "Reset Movement",
    Callback = function()
        Options.WalkSpeed:Set(16)
        Options.JumpPower:Set(50)
        Options.Gravity:Set(original.Gravity)
        Options.Spin:Set(false)
    end,
})

local highlight
local function applyHighlight()
    if highlight then
        highlight:Destroy()
        highlight = nil
    end
    if Flags.Highlight and player.Character then
        highlight = Instance.new("Highlight")
        highlight.FillColor = Flags.HighlightColor
        highlight.OutlineColor = Flags.HighlightOutline
        highlight.FillTransparency = 1 - Flags.HighlightFill
        highlight.Parent = player.Character
    end
end

local Character = PlayerTab:AddSection("Character", "Right")

local HighlightToggle = Character:AddToggle({
    Name = "Highlight",
    Flag = "Highlight",
    Callback = applyHighlight,
})
HighlightToggle:AddKeybind({ Flag = "HighlightKey" })
HighlightToggle:AddColorPicker({
    Default = Color3.fromRGB(255, 0, 0),
    Flag = "HighlightColor",
    Callback = applyHighlight,
})

Character:AddColorPicker({
    Name = "Outline Color",
    Default = Color3.fromRGB(255, 255, 255),
    Flag = "HighlightOutline",
    Callback = applyHighlight,
})

Character:AddSlider({
    Name = "Fill Opacity",
    Min = 0,
    Max = 1,
    Default = 0.5,
    Increment = 0.05,
    Flag = "HighlightFill",
    Callback = applyHighlight,
})

Character:AddButton({
    Name = "Reset Character",
    Callback = function()
        local hum = humanoid()
        if hum then
            hum.Health = 0
        end
    end,
})

connect(player.CharacterAdded, function(character)
    character:WaitForChild("Humanoid")
    applyMovement()
    applyHighlight()
end)

connect(RunService.Heartbeat, function(dt)
    local root = Flags.Spin and player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if root then
        root.CFrame *= CFrame.Angles(0, math.rad(Flags.SpinSpeed * dt), 0)
    end
end)

----------------------------------------------------------------------
-- Visuals: dropdowns (single + multi), decimals, live redraw
----------------------------------------------------------------------

local crosshairGui = Instance.new("ScreenGui")
crosshairGui.Name = "NewUILibCrosshair"
crosshairGui.IgnoreGuiInset = true
crosshairGui.ResetOnSpawn = false
crosshairGui.DisplayOrder = 998
crosshairGui.Parent = Window.Gui.Parent

local crosshair = Instance.new("Frame")
crosshair.AnchorPoint = Vector2.new(0.5, 0.5)
crosshair.Position = UDim2.fromScale(0.5, 0.5)
crosshair.BackgroundTransparency = 1
crosshair.Parent = crosshairGui

local function drawCrosshair()
    crosshair:ClearAllChildren()
    crosshair.Visible = Flags.Crosshair
    local color = Flags.CrosshairColor
    local size, thickness, gap = Flags.CrosshairSize, Flags.CrosshairThickness, Flags.CrosshairGap
    local style = Flags.CrosshairStyle

    local function part(width, height, x, y)
        local frame = Instance.new("Frame")
        frame.AnchorPoint = Vector2.new(0.5, 0.5)
        frame.Position = UDim2.fromOffset(x, y)
        frame.Size = UDim2.fromOffset(width, height)
        frame.BackgroundColor3 = color
        frame.BorderSizePixel = 0
        frame.Parent = crosshair
        return frame
    end

    if style == "Cross" or style == "Cross + Dot" then
        local offset = gap + size / 2
        part(size, thickness, -offset, 0)
        part(size, thickness, offset, 0)
        part(thickness, size, 0, -offset)
        part(thickness, size, 0, offset)
    end
    if style == "Dot" or style == "Cross + Dot" then
        part(thickness + 2, thickness + 2, 0, 0)
    end
    if style == "Circle" then
        local ring = part((gap + size) * 2, (gap + size) * 2, 0, 0)
        ring.BackgroundTransparency = 1
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(1, 0)
        corner.Parent = ring
        local outline = Instance.new("UIStroke")
        outline.Color = color
        outline.Thickness = thickness
        outline.Parent = ring
    end
end

local Crosshair = VisualsTab:AddSection("Crosshair", "Left")

local CrosshairToggle = Crosshair:AddToggle({
    Name = "Enabled",
    Default = true,
    Flag = "Crosshair",
    Callback = drawCrosshair,
})
CrosshairToggle:AddKeybind({ Default = Enum.KeyCode.C, Flag = "CrosshairKey" })
CrosshairToggle:AddColorPicker({
    Default = Color3.fromRGB(0, 255, 0),
    Flag = "CrosshairColor",
    Callback = drawCrosshair,
})

Crosshair:AddDropdown({
    Name = "Style",
    Options = { "Cross", "Cross + Dot", "Dot", "Circle" },
    Default = "Cross",
    Flag = "CrosshairStyle",
    Callback = drawCrosshair,
})

Crosshair:AddSlider({ Name = "Size", Min = 2, Max = 40, Default = 8, Suffix = "px", Flag = "CrosshairSize", Callback = drawCrosshair })
Crosshair:AddSlider({ Name = "Thickness", Min = 1, Max = 8, Default = 2, Suffix = "px", Flag = "CrosshairThickness", Callback = drawCrosshair })
Crosshair:AddSlider({ Name = "Gap", Min = 0, Max = 20, Default = 4, Suffix = "px", Flag = "CrosshairGap", Callback = drawCrosshair })

Crosshair:AddToggle({ Name = "Rotate", Flag = "CrosshairRotate" })
Crosshair:AddSlider({
    Name = "Rotate Speed",
    Min = 10,
    Max = 720,
    Default = 90,
    Increment = 10,
    Suffix = " deg/s",
    Flag = "CrosshairRotateSpeed",
})

connect(RunService.RenderStepped, function(dt)
    crosshair.Rotation = Flags.CrosshairRotate and (crosshair.Rotation + Flags.CrosshairRotateSpeed * dt) % 360 or 0
end)

local tint = Instance.new("ColorCorrectionEffect")
tint.Name = "NewUILibTint"
tint.Enabled = false
tint.Parent = Lighting

local World = VisualsTab:AddSection("World", "Right")

World:AddSlider({
    Name = "Time Of Day",
    Min = 0,
    Max = 24,
    Default = math.floor(original.ClockTime * 10 + 0.5) / 10,
    Increment = 0.1,
    Suffix = "h",
    Flag = "ClockTime",
    Callback = function(value)
        Lighting.ClockTime = value
    end,
})

World:AddSlider({
    Name = "Field Of View",
    Min = 30,
    Max = 120,
    Default = math.clamp(math.floor(original.FieldOfView + 0.5), 30, 120),
    Suffix = " deg",
    Flag = "FOV",
    Callback = function(value)
        camera.FieldOfView = value
    end,
})

World:AddToggle({
    Name = "Screen Tint",
    Flag = "Tint",
    Callback = function(value)
        tint.Enabled = value
    end,
}):AddColorPicker({
    Default = Color3.fromRGB(255, 150, 150),
    Flag = "TintColor",
    Callback = function(color)
        tint.TintColor = color
    end,
})
tint.TintColor = Flags.TintColor

World:AddSlider({
    Name = "Tint Saturation",
    Min = -1,
    Max = 1,
    Default = 0,
    Increment = 0.01,
    Flag = "Saturation",
    Callback = function(value)
        tint.Saturation = value
    end,
})

local coreGuiTypes = {
    Chat = Enum.CoreGuiType.Chat,
    Backpack = Enum.CoreGuiType.Backpack,
    ["Player List"] = Enum.CoreGuiType.PlayerList,
    Health = Enum.CoreGuiType.Health,
    Emotes = Enum.CoreGuiType.EmotesMenu,
}

local function applyHiddenHud(hidden)
    for name, coreGuiType in pairs(coreGuiTypes) do
        pcall(StarterGui.SetCoreGuiEnabled, StarterGui, coreGuiType, table.find(hidden, name) == nil)
    end
end

World:AddDropdown({
    Name = "Hide Roblox HUD",
    Options = { "Chat", "Backpack", "Player List", "Health", "Emotes" },
    Default = {},
    Multi = true,
    Flag = "HiddenHud",
    Callback = applyHiddenHud,
})

----------------------------------------------------------------------
-- Elements: one of everything, plus buttons that drive them from code
----------------------------------------------------------------------

local Controls = ElementsTab:AddSection("Controls", "Left")
local Api = ElementsTab:AddSection("Drive From Code", "Right")

local lastCallback = Controls:AddLabel("Last callback: none")
local status = Api:AddLabel("Press a button below")

local function describe(value)
    if typeof(value) == "table" then
        return "{" .. table.concat(value, ", ") .. "}"
    elseif typeof(value) == "Color3" then
        return "#" .. string.upper(value:ToHex())
    elseif typeof(value) == "EnumItem" then
        return value.Name
    end
    return tostring(value)
end

-- every test element reports here, so you can see exactly when a callback fires
local function report(name)
    return function(value)
        lastCallback:Set("Last callback: " .. name .. " = " .. describe(value))
    end
end

local clicks = 0
local ClickButton
ClickButton = Controls:AddButton({
    Name = "Clicked 0 times",
    Callback = function()
        clicks += 1
        ClickButton:SetText("Clicked " .. clicks .. " times")
    end,
})

local TestToggle = Controls:AddToggle({ Name = "Test Toggle", Flag = "TestToggle", Callback = report("Toggle") })
TestToggle:AddKeybind({ Default = Enum.KeyCode.T, Flag = "TestToggleKey", Changed = report("Toggle key") })
TestToggle:AddColorPicker({ Default = Color3.fromRGB(255, 200, 0), Flag = "TestToggleColor", Callback = report("Toggle color") })

Controls:AddSlider({ Name = "Whole Slider", Min = 0, Max = 100, Default = 50, Suffix = "%", Flag = "TestSlider", Callback = report("Slider") })
Controls:AddSlider({ Name = "Decimal Slider", Min = -5, Max = 5, Default = 0, Increment = 0.25, Flag = "TestDecimal", Callback = report("Decimal") })

Controls:AddDropdown({
    Name = "Single Dropdown",
    Options = { "One", "Two", "Three" },
    Default = "One",
    Flag = "TestDropdown",
    Callback = report("Dropdown"),
})

Controls:AddDropdown({
    Name = "Multi Dropdown",
    Options = { "Red", "Green", "Blue", "Yellow", "Purple", "Orange", "Pink", "Cyan", "White", "Black" },
    Default = { "Red", "Blue" },
    Multi = true,
    Flag = "TestMulti",
    Callback = report("Multi"),
})

Controls:AddColorPicker({ Name = "Color Picker", Default = Color3.fromRGB(80, 200, 255), Flag = "TestColor", Callback = report("Color") })
Controls:AddKeybind({ Name = "Keybind", Default = Enum.KeyCode.K, Flag = "TestKey", Callback = report("Keybind pressed"), Changed = report("Keybind changed") })

Api:AddButton({
    Name = "Flip Toggle",
    Callback = function()
        Options.TestToggle:Set(not Options.TestToggle:Get())
        status:Set("Toggle:Set(" .. tostring(Flags.TestToggle) .. ")")
    end,
})

Api:AddButton({
    Name = "Random Sliders",
    Callback = function()
        Options.TestSlider:Set(math.random(0, 100))
        Options.TestDecimal:Set(math.random(-20, 20) / 4)
        status:Set("Sliders: " .. Flags.TestSlider .. " and " .. Flags.TestDecimal)
    end,
})

Api:AddButton({
    Name = "Slider Out Of Range (999)",
    Callback = function()
        Options.TestSlider:Set(999)
        status:Set("Set 999, clamped to " .. Flags.TestSlider)
    end,
})

Api:AddButton({
    Name = "Next Dropdown Option",
    Callback = function()
        local order = { One = "Two", Two = "Three", Three = "One" }
        Options.TestDropdown:Set(order[Flags.TestDropdown] or "One")
        status:Set("Dropdown:Set(" .. describe(Flags.TestDropdown) .. ")")
    end,
})

Api:AddButton({
    Name = "Select All In Multi",
    Callback = function()
        Options.TestMulti:Set({ "Red", "Green", "Blue", "Yellow", "Purple", "Orange", "Pink", "Cyan", "White", "Black" })
        status:Set("Multi has " .. #Flags.TestMulti .. " selected")
    end,
})

Api:AddButton({
    Name = "Refresh Dropdown: Players",
    Callback = function()
        local names = {}
        for _, other in ipairs(Players:GetPlayers()) do
            table.insert(names, other.Name)
        end
        Options.TestDropdown:Refresh(names)
        status:Set("Dropdown now lists " .. #names .. " player(s)")
    end,
})

Api:AddButton({
    Name = "Refresh Dropdown: Numbers",
    Callback = function()
        Options.TestDropdown:Refresh({ "One", "Two", "Three" })
        status:Set("Dropdown back to One / Two / Three")
    end,
})

Api:AddButton({
    Name = "Random Colors",
    Callback = function()
        Options.TestColor:Set(Color3.fromHSV(math.random(), 1, 1))
        Options.TestToggleColor:Set(Color3.fromHSV(math.random(), 1, 1))
        status:Set("Color: " .. describe(Flags.TestColor))
    end,
})

Api:AddButton({
    Name = "Bind Keybind To P",
    Callback = function()
        Options.TestKey:Set(Enum.KeyCode.P)
        status:Set("Keybind is now " .. describe(Flags.TestKey))
    end,
})

-- the second argument `true` changes the value without firing the callback,
-- so "Last callback" on the left must NOT change when this is pressed
Api:AddButton({
    Name = "Silent Set (no callback)",
    Callback = function()
        Options.TestSlider:Set(math.random(0, 100), true)
        Options.TestToggle:Set(not Flags.TestToggle, true)
        status:Set("Silently set: " .. Flags.TestSlider .. ", " .. tostring(Flags.TestToggle))
    end,
})

Api:AddButton({
    Name = "Print All Flags",
    Callback = function()
        local names = {}
        for flag in pairs(Flags) do
            table.insert(names, flag)
        end
        table.sort(names)
        for _, flag in ipairs(names) do
            print(flag, "=", describe(Flags[flag]))
        end
        status:Set("Printed " .. #names .. " flags to console (F9)")
    end,
})

----------------------------------------------------------------------
-- Settings: window methods
----------------------------------------------------------------------

local Menu = SettingsTab:AddSection("Menu", "Left")

Menu:AddKeybind({
    Name = "Toggle Menu",
    Default = Enum.KeyCode.RightShift,
    Flag = "MenuKey",
    Changed = function(key)
        Window:SetToggleKey(key)
    end,
})

Menu:AddButton({
    Name = "Hide For 3 Seconds",
    Callback = function()
        Window:SetVisible(false)
        task.delay(3, function()
            if not Library.Unloaded then
                Window:SetVisible(true)
            end
        end)
    end,
})

local titles = { "NewUILib | Test Menu", "Title changed!", "ars.red | <3" }
local titleIndex = 1
Menu:AddButton({
    Name = "Next Title",
    Callback = function()
        titleIndex = titleIndex % #titles + 1
        Window:SetTitle(titles[titleIndex])
    end,
})

Menu:AddButton({
    Name = "Go To Player Tab",
    Callback = function()
        PlayerTab:Select()
    end,
})

Menu:AddButton({
    Name = "Unload",
    Callback = function()
        for _, connection in ipairs(connections) do
            connection:Disconnect()
        end
        crosshairGui:Destroy()
        tint:Destroy()
        if highlight then
            highlight:Destroy()
        end
        workspace.Gravity = original.Gravity
        Lighting.ClockTime = original.ClockTime
        camera.FieldOfView = original.FieldOfView
        applyHiddenHud({})
        local hum = humanoid()
        if hum then
            hum.WalkSpeed = 16
            hum.JumpPower = 50
        end
        Library:Unload()
    end,
})

local Stats = SettingsTab:AddSection("Stats", "Right")
local fpsLabel = Stats:AddLabel("FPS: ...")
local positionLabel = Stats:AddLabel("Position: ...")
Stats:AddLabel("Flags registered: " .. (function()
    local count = 0
    for _ in pairs(Flags) do
        count += 1
    end
    return count
end)())

local frames, elapsed = 0, 0
connect(RunService.RenderStepped, function(dt)
    frames += 1
    elapsed += dt
    if elapsed >= 0.5 then
        fpsLabel:Set(string.format("FPS: %d", math.floor(frames / elapsed + 0.5)))
        frames, elapsed = 0, 0
        local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
        if root then
            local p = root.Position
            positionLabel:Set(string.format("Position: %d, %d, %d", math.floor(p.X), math.floor(p.Y), math.floor(p.Z)))
        end
    end
end)

drawCrosshair()
