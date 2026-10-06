-- Full demo of every element. Run it with:
-- loadstring(game:HttpGet("https://raw.githubusercontent.com/RbxCheats/NewUILIb/main/Example.lua"))()

local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/RbxCheats/NewUILIb/main/Library.lua"))()

local Window = Library:CreateWindow({
    Title = "NewUILib | Example",
    Accent = Color3.fromRGB(255, 0, 0),
    ToggleKey = Enum.KeyCode.RightShift,
})

local Main = Window:AddTab("Main")
local Visuals = Window:AddTab("Visuals")
local Misc = Window:AddTab("Miscellaneous")
local Settings = Window:AddTab("Settings")

-- Main ----------------------------------------------------------------

local Character = Main:AddSection("Character", "Left")

local player = game:GetService("Players").LocalPlayer
local function humanoid()
    return player.Character and player.Character:FindFirstChildOfClass("Humanoid")
end

Character:AddSlider({
    Name = "Walk Speed",
    Min = 16,
    Max = 100,
    Default = 16,
    Suffix = " studs/s",
    Flag = "WalkSpeed",
    Callback = function(value)
        local hum = humanoid()
        if hum then
            hum.WalkSpeed = value
        end
    end,
})

Character:AddSlider({
    Name = "Jump Power",
    Min = 50,
    Max = 200,
    Default = 50,
    Increment = 5,
    Flag = "JumpPower",
    Callback = function(value)
        local hum = humanoid()
        if hum then
            hum.UseJumpPower = true
            hum.JumpPower = value
        end
    end,
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

local Camera = Main:AddSection("Camera", "Right")

Camera:AddSlider({
    Name = "Field Of View",
    Min = 30,
    Max = 120,
    Default = 70,
    Suffix = " deg",
    Flag = "FOV",
    Callback = function(value)
        workspace.CurrentCamera.FieldOfView = value
    end,
})

-- Visuals -------------------------------------------------------------

local Toggles = Visuals:AddSection("Toggles", "Left")

Toggles:AddToggle({
    Name = "Enabled",
    Default = false,
    Flag = "Enabled",
    Callback = function(value)
        print("Enabled:", value)
    end,
}):AddKeybind({ Default = Enum.KeyCode.E, Flag = "EnabledKey" })

local Boxes = Toggles:AddToggle({ Name = "Boxes", Flag = "Boxes" })
Boxes:AddColorPicker({
    Default = Color3.fromRGB(255, 255, 255),
    Flag = "BoxColor",
    Callback = function(color)
        print("Box color:", color)
    end,
})

Toggles:AddToggle({ Name = "Health Bars", Default = true, Flag = "HealthBars" })
    :AddColorPicker({ Default = Color3.fromRGB(0, 255, 0), Flag = "HealthColor" })

local Preference = Visuals:AddSection("Preference", "Right")

Preference:AddDropdown({
    Name = "Preferred Measurement",
    Options = { "Roblox", "Meters", "Feet" },
    Default = "Roblox",
    Flag = "Measurement",
    Callback = function(option)
        print("Measurement:", option)
    end,
})

Preference:AddDropdown({
    Name = "Shown Info",
    Options = { "Name", "Distance", "Health", "Weapon" },
    Default = { "Name", "Distance" },
    Multi = true,
    Flag = "ShownInfo",
    Callback = function(selected)
        print("Shown info:", table.concat(selected, ", "))
    end,
})

Preference:AddColorPicker({
    Name = "Crosshair Color",
    Default = Color3.fromRGB(80, 200, 255),
    Flag = "CrosshairColor",
})

-- Miscellaneous -------------------------------------------------------

local Info = Misc:AddSection("Info", "Left")
local clicks = 0
local counter = Info:AddLabel("Clicks: 0")

Info:AddButton({
    Name = "Click Me",
    Callback = function()
        clicks += 1
        counter:Set("Clicks: " .. clicks)
    end,
})

Info:AddButton({
    Name = "Print Flags",
    Callback = function()
        for flag, value in pairs(Library.Flags) do
            print(flag, value)
        end
    end,
})

-- Settings ------------------------------------------------------------

local Menu = Settings:AddSection("Menu", "Left")

Menu:AddKeybind({
    Name = "Toggle Menu",
    Default = Enum.KeyCode.RightShift,
    Flag = "MenuKey",
    Changed = function(key)
        Window:SetToggleKey(key)
    end,
})

Menu:AddButton({
    Name = "Unload",
    Callback = function()
        Library:Unload()
    end,
})
