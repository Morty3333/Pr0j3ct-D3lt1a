--// =========================================================
--// PREMIUM UNIVERSAL MENU
--// Линии + Зум + Освещение + FOV + AIMBOT + ESP (ХП, Дистанция)
--// INS = открыть меню
--// =========================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")

local Camera = Workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

--========================================================--
-- НАСТРОЙКИ
--========================================================--

local features = {

    lines = {
        enabled = false,
        color = Color3.fromRGB(255,0,0),
        thickness = 2
    },

    zoom = {
        enabled = false,
        key = Enum.KeyCode.C,
        zoomFOV = 40,
        normalFOV = Camera.FieldOfView,
        active = false
    },

    lighting = {
        enabled = false,
        color = Color3.fromRGB(255,255,255),
        brightness = 2,
        defaultAmbient = Lighting.Ambient,
        defaultOutdoor = Lighting.OutdoorAmbient,
        defaultBrightness = Lighting.Brightness
    },

    aimbot = {
        enabled = false,
        active = false,
        key = Enum.KeyCode.Z,
        targetPart = "Head",
        circleRadius = 150,
        circleColor = Color3.fromRGB(255,255,255),
        circleThickness = 2,
        smoothness = 0.85,
        currentTarget = nil
    },

    esp = {
        enabled = false,
        health = true,
        distance = true,
        teamCheck = false,
        maxDistance = 3000,
        healthColor = Color3.fromRGB(80,255,80),
        distanceColor = Color3.fromRGB(200,200,200),
        enemyColor = Color3.fromRGB(255,50,50),
        allyColor = Color3.fromRGB(50,255,50)
    }
}

-- Сохраняем стандартные настройки освещения
features.lighting.defaultAmbient = Lighting.Ambient
features.lighting.defaultOutdoor = Lighting.OutdoorAmbient
features.lighting.defaultBrightness = Lighting.Brightness

--========================================================--
-- DRAWING
--========================================================--

local lines = {}
local fovCircle = Drawing.new("Circle")
local espDrawings = {}

fovCircle.Visible = false
fovCircle.Filled = false
fovCircle.NumSides = 64
fovCircle.Transparency = 1

--========================================================--
-- ESP FUNCTIONS
--========================================================--

local function createESP(player)
    if player == LocalPlayer or espDrawings[player] then return end

    local healthText = Drawing.new("Text")
    healthText.Visible = false
    healthText.Center = true
    healthText.Size = 14
    healthText.Color = features.esp.healthColor
    healthText.Font = 2
    healthText.Outline = true

    local distanceText = Drawing.new("Text")
    distanceText.Visible = false
    distanceText.Center = true
    distanceText.Size = 12
    distanceText.Color = features.esp.distanceColor
    distanceText.Font = 2
    distanceText.Outline = true

    espDrawings[player] = {
        health = healthText,
        distance = distanceText
    }
end

local function removeESP(player)
    local esp = espDrawings[player]
    if esp then
        if esp.health then esp.health:Remove() end
        if esp.distance then esp.distance:Remove() end
        espDrawings[player] = nil
    end
end

local function getPlayerColor(player)
    if not player.Team or not LocalPlayer.Team then
        return features.esp.enemyColor
    end
    return player.Team == LocalPlayer.Team and features.esp.allyColor or features.esp.enemyColor
end

local function updateESP(player)
    local esp = espDrawings[player]
    if not features.esp.enabled then
        if esp then
            esp.health.Visible = false
            esp.distance.Visible = false
        end
        return
    end
    
    if not esp then
        createESP(player)
        esp = espDrawings[player]
        if not esp then return end
    end

    local character = player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    local rootPart = character and character:FindFirstChild("HumanoidRootPart")

    if not (character and humanoid and humanoid.Health > 0 and rootPart) then
        esp.health.Visible = false
        esp.distance.Visible = false
        return
    end

    local distance = (rootPart.Position - Camera.CFrame.Position).Magnitude
    if distance > features.esp.maxDistance then
        esp.health.Visible = false
        esp.distance.Visible = false
        return
    end

    if features.esp.teamCheck and player.Team == LocalPlayer.Team then
        esp.health.Visible = false
        esp.distance.Visible = false
        return
    end

    local pos, onScreen = Camera:WorldToViewportPoint(rootPart.Position)
    if not onScreen then
        esp.health.Visible = false
        esp.distance.Visible = false
        return
    end

    local size = character:GetExtentsSize()
    local cf = rootPart.CFrame
    local topPos = Camera:WorldToViewportPoint((cf * CFrame.new(0, size.Y / 2, 0)).Position)
    local bottomPos = Camera:WorldToViewportPoint((cf * CFrame.new(0, -size.Y / 2, 0)).Position)
    
    local boxHeight = bottomPos.Y - topPos.Y
    local boxWidth = boxHeight * 0.65
    local boxPosition = Vector2.new(topPos.X - boxWidth / 2, topPos.Y)

    -- Health ESP
    if features.esp.health then
        esp.health.Text = math.floor(humanoid.Health)
        esp.health.Position = Vector2.new(boxPosition.X + boxWidth + 8, boxPosition.Y + boxHeight / 2 - 7)
        esp.health.Visible = true
        esp.health.Color = features.esp.healthColor
    else
        esp.health.Visible = false
    end

    -- Distance ESP
    if features.esp.distance then
        local distanceInMeters = math.floor(distance * 0.28)
        esp.distance.Text = "["..distanceInMeters.."m]"
        esp.distance.Position = Vector2.new(pos.X, bottomPos.Y + 5)
        esp.distance.Visible = true
        esp.distance.Color = features.esp.distanceColor
    else
        esp.distance.Visible = false
    end
end

local function hideAllESP()
    for player, esp in pairs(espDrawings) do
        if esp then
            esp.health.Visible = false
            esp.distance.Visible = false
        end
    end
end

--========================================================--
-- GUI
--========================================================--

local gui = Instance.new("ScreenGui")
gui.Name = "PremiumMenu"
gui.ResetOnSpawn = false
gui.Parent = game.CoreGui

local main = Instance.new("Frame")
main.Parent = gui
main.Size = UDim2.new(0,550,0,650)
main.Position = UDim2.new(0.5,-275,0.5,-325)
main.BackgroundColor3 = Color3.fromRGB(25,25,35)
main.BorderSizePixel = 0
main.Visible = false

Instance.new("UICorner",main).CornerRadius = UDim.new(0,12)

-- TITLE

local title = Instance.new("TextLabel")
title.Parent = main
title.Size = UDim2.new(1,0,0,40)
title.BackgroundColor3 = Color3.fromRGB(35,35,50)
title.Text = "⚡ PREMIUM MENU ⚡"
title.TextColor3 = Color3.fromRGB(255,200,100)
title.Font = Enum.Font.GothamBold
title.TextSize = 20

Instance.new("UICorner",title).CornerRadius = UDim.new(0,12)

-- DRAG

local dragging = false
local dragStart
local startPos

title.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = main.Position
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - dragStart
        main.Position = UDim2.new(
            startPos.X.Scale,
            startPos.X.Offset + delta.X,
            startPos.Y.Scale,
            startPos.Y.Offset + delta.Y
        )
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
    end
end)

--========================================================--
-- SCROLL
--========================================================--

local scroll = Instance.new("ScrollingFrame")
scroll.Parent = main
scroll.Size = UDim2.new(1,-10,1,-50)
scroll.Position = UDim2.new(0,5,0,45)
scroll.ScrollBarThickness = 8
scroll.BackgroundTransparency = 1
scroll.BorderSizePixel = 0
scroll.ScrollBarImageColor3 = Color3.fromRGB(80,80,120)

local scrollContainer = Instance.new("Frame")
scrollContainer.Parent = scroll
scrollContainer.Size = UDim2.new(1,0,0,0)
scrollContainer.BackgroundTransparency = 1
scrollContainer.AutomaticSize = Enum.AutomaticSize.Y

local layout = Instance.new("UIListLayout")
layout.Parent = scrollContainer
layout.Padding = UDim.new(0,8)
layout.HorizontalAlignment = Enum.HorizontalAlignment.Center

local function updateCanvasSize()
    scroll.CanvasSize = UDim2.new(0,0,0,scrollContainer.AbsoluteSize.Y + 15)
end

scrollContainer:GetPropertyChangedSignal("AbsoluteSize"):Connect(updateCanvasSize)
layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateCanvasSize)
task.wait(0.1)
updateCanvasSize()

--========================================================--
-- UI FUNCTIONS
--========================================================--

local activeColorPicker = nil

local function createSection(name)
    local frame = Instance.new("Frame")
    frame.Parent = scrollContainer
    frame.Size = UDim2.new(1,-10,0,0)
    frame.BackgroundColor3 = Color3.fromRGB(35,35,50)
    frame.BorderSizePixel = 0
    frame.AutomaticSize = Enum.AutomaticSize.Y
    Instance.new("UICorner",frame).CornerRadius = UDim.new(0,12)

    local titleLabel = Instance.new("TextLabel")
    titleLabel.Parent = frame
    titleLabel.Size = UDim2.new(1,0,0,35)
    titleLabel.BackgroundColor3 = Color3.fromRGB(45,45,65)
    titleLabel.Text = name
    titleLabel.TextColor3 = Color3.fromRGB(255,200,100)
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextSize = 16
    Instance.new("UICorner",titleLabel).CornerRadius = UDim.new(0,12)

    local holder = Instance.new("Frame")
    holder.Parent = frame
    holder.Size = UDim2.new(1,-10,0,0)
    holder.Position = UDim2.new(0,5,0,40)
    holder.BackgroundTransparency = 1
    holder.AutomaticSize = Enum.AutomaticSize.Y

    local lay = Instance.new("UIListLayout")
    lay.Parent = holder
    lay.Padding = UDim.new(0,6)

    return holder
end

local function createToggle(parent,text,getter,setter)
    local button = Instance.new("TextButton")
    button.Parent = parent
    button.Size = UDim2.new(1,0,0,35)
    button.BackgroundColor3 = Color3.fromRGB(50,50,70)
    button.Font = Enum.Font.Gotham
    button.TextSize = 14
    Instance.new("UICorner",button).CornerRadius = UDim.new(0,8)

    local function update()
        if getter() then
            button.Text = text.." : ✅ ON"
            button.TextColor3 = Color3.fromRGB(0,255,120)
        else
            button.Text = text.." : ❌ OFF"
            button.TextColor3 = Color3.fromRGB(255,100,100)
        end
    end
    update()

    button.Activated:Connect(function()
        setter(not getter())
        update()
    end)
end

local function createSlider(parent,text,min,max,getter,setter,isInt)
    local frame = Instance.new("Frame")
    frame.Parent = parent
    frame.Size = UDim2.new(1,0,0,55)
    frame.BackgroundTransparency = 1

    local label = Instance.new("TextLabel")
    label.Parent = frame
    label.Size = UDim2.new(1,0,0,20)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Color3.new(1,1,1)
    label.Font = Enum.Font.Gotham
    label.TextSize = 13

    local valueLabel = Instance.new("TextLabel")
    valueLabel.Parent = frame
    valueLabel.Size = UDim2.new(1,0,0,20)
    valueLabel.Position = UDim2.new(0,0,0,20)
    valueLabel.BackgroundTransparency = 1
    local val = getter()
    if isInt then val = math.floor(val) end
    valueLabel.Text = "⭐ "..tostring(val)
    valueLabel.TextColor3 = Color3.fromRGB(255,200,100)
    valueLabel.Font = Enum.Font.Gotham
    valueLabel.TextSize = 12

    local bar = Instance.new("Frame")
    bar.Parent = frame
    bar.Size = UDim2.new(1,0,0,12)
    bar.Position = UDim2.new(0,0,0,38)
    bar.BackgroundColor3 = Color3.fromRGB(50,50,70)
    Instance.new("UICorner",bar).CornerRadius = UDim.new(1,0)

    local fill = Instance.new("Frame")
    fill.Parent = bar
    fill.BackgroundColor3 = Color3.fromRGB(100,170,255)
    fill.Size = UDim2.new((getter()-min)/(max-min),0,1,0)
    Instance.new("UICorner",fill).CornerRadius = UDim.new(1,0)

    local dragging = false

    local function update(input)
        local percent = math.clamp((input.Position.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
        local value = min + ((max-min)*percent)
        setter(value)
        fill.Size = UDim2.new(percent,0,1,0)
        if isInt then
            valueLabel.Text = "⭐ "..math.floor(value)
        else
            valueLabel.Text = "⭐ "..math.floor(value*100)/100
        end
    end

    bar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            update(input)
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            update(input)
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
end

local function createColorPicker(parent,text,getter,setter)
    local button = Instance.new("TextButton")
    button.Parent = parent
    button.Size = UDim2.new(1,0,0,35)
    button.BackgroundColor3 = getter()
    button.Text = "🎨 "..text
    button.TextColor3 = Color3.new(1,1,1)
    button.Font = Enum.Font.GothamBold
    button.TextSize = 13
    Instance.new("UICorner",button).CornerRadius = UDim.new(0,8)

    button.Activated:Connect(function()
        if activeColorPicker then activeColorPicker:Destroy() end

        local picker = Instance.new("Frame")
        picker.Parent = gui
        picker.Size = UDim2.new(0,280,0,220)
        picker.Position = UDim2.new(0.5,-140,0.5,-110)
        picker.BackgroundColor3 = Color3.fromRGB(35,35,50)
        picker.BorderSizePixel = 1
        picker.BorderColor3 = Color3.fromRGB(80,80,120)
        Instance.new("UICorner",picker).CornerRadius = UDim.new(0,12)
        activeColorPicker = picker

        local pickerTitle = Instance.new("TextLabel")
        pickerTitle.Parent = picker
        pickerTitle.Size = UDim2.new(1,0,0,35)
        pickerTitle.BackgroundColor3 = Color3.fromRGB(45,45,65)
        pickerTitle.Text = "🎨 RGB ПАЛИТРА"
        pickerTitle.TextColor3 = Color3.fromRGB(255,200,100)
        pickerTitle.Font = Enum.Font.GothamBold
        pickerTitle.TextSize = 15
        Instance.new("UICorner",pickerTitle).CornerRadius = UDim.new(0,12)

        local closePicker = Instance.new("TextButton")
        closePicker.Parent = picker
        closePicker.Size = UDim2.new(0,30,0,30)
        closePicker.Position = UDim2.new(1,-35,0,3)
        closePicker.Text = "✕"
        closePicker.TextColor3 = Color3.fromRGB(255,100,100)
        closePicker.BackgroundColor3 = Color3.fromRGB(60,60,80)
        closePicker.Font = Enum.Font.GothamBold
        closePicker.TextSize = 16
        closePicker.BorderSizePixel = 0
        Instance.new("UICorner",closePicker).CornerRadius = UDim.new(0,8)
        closePicker.Activated:Connect(function()
            picker:Destroy()
            activeColorPicker = nil
        end)

        local r,g,b = getter().R, getter().G, getter().B
        local colorPreview = Instance.new("Frame")
        colorPreview.Parent = picker
        colorPreview.Size = UDim2.new(0,50,0,50)
        colorPreview.Position = UDim2.new(0,15,0,50)
        colorPreview.BackgroundColor3 = getter()
        colorPreview.BorderSizePixel = 1
        colorPreview.BorderColor3 = Color3.fromRGB(255,255,255)
        Instance.new("UICorner",colorPreview).CornerRadius = UDim.new(0,8)

        local function makeSlider(name,color,startY)
            local label = Instance.new("TextLabel")
            label.Parent = picker
            label.Position = UDim2.new(0,80,0,startY)
            label.Size = UDim2.new(0,30,0,20)
            label.Text = name
            label.TextColor3 = color
            label.BackgroundTransparency = 1
            label.Font = Enum.Font.GothamBold
            label.TextSize = 16

            local valueBox = Instance.new("TextBox")
            valueBox.Parent = picker
            valueBox.Position = UDim2.new(0,230,0,startY-3)
            valueBox.Size = UDim2.new(0,40,0,25)
            valueBox.Text = "0.00"
            valueBox.TextColor3 = Color3.fromRGB(255,255,255)
            valueBox.BackgroundColor3 = Color3.fromRGB(50,50,70)
            valueBox.Font = Enum.Font.Gotham
            valueBox.TextSize = 11
            Instance.new("UICorner",valueBox).CornerRadius = UDim.new(0,6)

            local bar = Instance.new("Frame")
            bar.Parent = picker
            bar.Position = UDim2.new(0,80,0,startY+22)
            bar.Size = UDim2.new(0,190,0,10)
            bar.BackgroundColor3 = Color3.fromRGB(60,60,80)
            Instance.new("UICorner",bar).CornerRadius = UDim.new(1,0)

            local fill = Instance.new("Frame")
            fill.Parent = bar
            fill.Size = UDim2.new(0,0,1,0)
            fill.BackgroundColor3 = color
            Instance.new("UICorner",fill).CornerRadius = UDim.new(1,0)

            local currentVal = 0

            local function updateValue(input)
                local percent = math.clamp((input.Position.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
                currentVal = percent
                fill.Size = UDim2.new(percent,0,1,0)
                valueBox.Text = string.format("%.2f", percent)
                return percent
            end

            local dragging = false
            bar.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    dragging = true
                    local val = updateValue(input)
                    if name == "R" then r = val elseif name == "G" then g = val else b = val end
                    local newColor = Color3.new(r,g,b)
                    setter(newColor)
                    button.BackgroundColor3 = newColor
                    colorPreview.BackgroundColor3 = newColor
                end
            end)

            UserInputService.InputChanged:Connect(function(input)
                if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                    local val = updateValue(input)
                    if name == "R" then r = val elseif name == "G" then g = val else b = val end
                    local newColor = Color3.new(r,g,b)
                    setter(newColor)
                    button.BackgroundColor3 = newColor
                    colorPreview.BackgroundColor3 = newColor
                end
            end)

            UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    dragging = false
                end
            end)

            valueBox.FocusLost:Connect(function()
                local val = tonumber(valueBox.Text)
                if val then
                    val = math.clamp(val,0,1)
                    currentVal = val
                    fill.Size = UDim2.new(val,0,1,0)
                    valueBox.Text = string.format("%.2f", val)
                    if name == "R" then r = val elseif name == "G" then g = val else b = val end
                    local newColor = Color3.new(r,g,b)
                    setter(newColor)
                    button.BackgroundColor3 = newColor
                    colorPreview.BackgroundColor3 = newColor
                else
                    valueBox.Text = string.format("%.2f", currentVal)
                end
            end)

            return {setVal = function(val) currentVal = val; fill.Size = UDim2.new(val,0,1,0); valueBox.Text = string.format("%.2f", val) end}
        end

        local red = makeSlider("R", Color3.fromRGB(255,80,80), 55)
        local green = makeSlider("G", Color3.fromRGB(80,255,80), 105)
        local blue = makeSlider("B", Color3.fromRGB(80,80,255), 155)

        red.setVal(r)
        green.setVal(g)
        blue.setVal(b)
    end)
end

local function createKeybind(parent,text,getter,setter)
    local button = Instance.new("TextButton")
    button.Parent = parent
    button.Size = UDim2.new(1,0,0,35)
    button.BackgroundColor3 = Color3.fromRGB(50,50,70)
    button.TextColor3 = Color3.new(1,1,1)
    button.Font = Enum.Font.Gotham
    button.TextSize = 13
    Instance.new("UICorner",button).CornerRadius = UDim.new(0,8)
    button.Text = "⌨ "..text.." : "..getter().Name

    button.Activated:Connect(function()
        button.Text = "⌨ "..text.." : нажми..."
        local con
        con = UserInputService.InputBegan:Connect(function(input,gp)
            if gp then return end
            if input.UserInputType == Enum.UserInputType.Keyboard then
                setter(input.KeyCode)
                button.Text = "⌨ "..text.." : "..input.KeyCode.Name
                con:Disconnect()
            end
        end)
    end)
end

local function createDropdown(parent,text,options,getter,setter)
    local index = 1
    for i,v in ipairs(options) do
        if v == getter() then index = i end
    end

    local button = Instance.new("TextButton")
    button.Parent = parent
    button.Size = UDim2.new(1,0,0,35)
    button.BackgroundColor3 = Color3.fromRGB(50,50,70)
    button.TextColor3 = Color3.new(1,1,1)
    button.Font = Enum.Font.Gotham
    button.TextSize = 13
    Instance.new("UICorner",button).CornerRadius = UDim.new(0,8)
    button.Text = "🎯 "..text.." : "..getter()

    button.Activated:Connect(function()
        index = index + 1
        if index > #options then index = 1 end
        setter(options[index])
        button.Text = "🎯 "..text.." : "..options[index]
    end)
end

--========================================================--
-- SECTIONS
--========================================================--

-- LINES SECTION
local lineSection = createSection("📏 LINES")
createToggle(lineSection,"Линии", function() return features.lines.enabled end, function(v) features.lines.enabled = v end)
createSlider(lineSection,"Толщина",1,10, function() return features.lines.thickness end, function(v) features.lines.thickness = v end, true)
createColorPicker(lineSection,"Цвет линий", function() return features.lines.color end, function(v) features.lines.color = v end)

-- ZOOM SECTION
local zoomSection = createSection("🔍 ZOOM")
createToggle(zoomSection,"Зум", function() return features.zoom.enabled end, function(v) features.zoom.enabled = v end)
createSlider(zoomSection,"FOV",20,120, function() return features.zoom.zoomFOV end, function(v) features.zoom.zoomFOV = v end, true)
createKeybind(zoomSection,"Кнопка зума", function() return features.zoom.key end, function(v) features.zoom.key = v end)

-- LIGHTING SECTION
local lightSection = createSection("☀️ LIGHTING")
createToggle(lightSection,"Освещение", function() return features.lighting.enabled end, function(v)
    features.lighting.enabled = v
    if not v then
        Lighting.Ambient = features.lighting.defaultAmbient
        Lighting.OutdoorAmbient = features.lighting.defaultOutdoor
        Lighting.Brightness = features.lighting.defaultBrightness
        Lighting.GlobalShadows = true
    end
end)
createSlider(lightSection,"Яркость",0.5,5, function() return features.lighting.brightness end, function(v)
    features.lighting.brightness = v
    if features.lighting.enabled then Lighting.Brightness = v end
end, false)
createColorPicker(lightSection,"Цвет карты", function() return features.lighting.color end, function(v)
    features.lighting.color = v
    if features.lighting.enabled then
        Lighting.Ambient = v
        Lighting.OutdoorAmbient = v
    end
end)

-- AIMBOT SECTION
local aimSection = createSection("🎯 AIMBOT")
createToggle(aimSection,"Аимбот", function() return features.aimbot.enabled end, function(v) features.aimbot.enabled = v end)
createSlider(aimSection,"Радиус круга",50,500, function() return features.aimbot.circleRadius end, function(v) features.aimbot.circleRadius = v end, true)
createSlider(aimSection,"Плавность",0.1,1, function() return features.aimbot.smoothness end, function(v) features.aimbot.smoothness = v end, false)
createSlider(aimSection,"Толщина круга",1,10, function() return features.aimbot.circleThickness end, function(v) features.aimbot.circleThickness = v end, true)
createColorPicker(aimSection,"Цвет круга", function() return features.aimbot.circleColor end, function(v) features.aimbot.circleColor = v end)
createKeybind(aimSection,"Кнопка аима", function() return features.aimbot.key end, function(v) features.aimbot.key = v end)
createDropdown(aimSection,"Часть тела", {"Head","HumanoidRootPart","UpperTorso","LowerTorso","Torso"}, function() return features.aimbot.targetPart end, function(v) features.aimbot.targetPart = v end)

-- ESP SECTION
local espSection = createSection("👁️ ESP (ХП, Дистанция)")
createToggle(espSection,"ESP", function() return features.esp.enabled end, function(v) 
    features.esp.enabled = v
    if not v then hideAllESP() end
end)
createToggle(espSection,"Показывать ХП", function() return features.esp.health end, function(v) features.esp.health = v end)
createToggle(espSection,"Показывать дистанцию", function() return features.esp.distance end, function(v) features.esp.distance = v end)
createToggle(espSection,"Team Check (не показывать союзников)", function() return features.esp.teamCheck end, function(v) features.esp.teamCheck = v end)
createSlider(espSection,"Макс. дистанция",500,5000, function() return features.esp.maxDistance end, function(v) features.esp.maxDistance = v end, true)
createColorPicker(espSection,"Цвет ХП", function() return features.esp.healthColor end, function(v) features.esp.healthColor = v end)
createColorPicker(espSection,"Цвет дистанции", function() return features.esp.distanceColor end, function(v) features.esp.distanceColor = v end)
createColorPicker(espSection,"Цвет врага", function() return features.esp.enemyColor end, function(v) features.esp.enemyColor = v end)
createColorPicker(espSection,"Цвет союзника", function() return features.esp.allyColor end, function(v) features.esp.allyColor = v end)

--========================================================--
-- LINES
--========================================================--

local function createLine(player)
    local line = Drawing.new("Line")
    line.Visible = false
    lines[player] = line
end

for _,player in pairs(Players:GetPlayers()) do
    if player ~= LocalPlayer then createLine(player) end
    createESP(player)
end

Players.PlayerAdded:Connect(function(player)
    if player ~= LocalPlayer then createLine(player) end
    createESP(player)
end)

Players.PlayerRemoving:Connect(function(player)
    if lines[player] then lines[player]:Remove() lines[player] = nil end
    removeESP(player)
end)

--========================================================--
-- AIMBOT GET TARGET
--========================================================--

local function getTarget()
    local closest = nil
    local shortest = math.huge
    local center = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)

    for _,player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local humanoid = player.Character:FindFirstChild("Humanoid")
            local part = player.Character:FindFirstChild(features.aimbot.targetPart)
            if humanoid and humanoid.Health > 0 and part then
                local pos, visible = Camera:WorldToViewportPoint(part.Position)
                if visible then
                    local dist = (Vector2.new(pos.X, pos.Y) - center).Magnitude
                    if dist < shortest and dist <= features.aimbot.circleRadius then
                        shortest = dist
                        closest = part
                    end
                end
            end
        end
    end
    return closest
end

--========================================================--
-- INPUT
--========================================================--

UserInputService.InputBegan:Connect(function(input,gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode.Insert then main.Visible = not main.Visible end
    if input.KeyCode == features.zoom.key and features.zoom.enabled then
        features.zoom.active = true
        Camera.FieldOfView = features.zoom.zoomFOV
    end
    if input.KeyCode == features.aimbot.key and features.aimbot.enabled then
        features.aimbot.active = true
    end
end)

UserInputService.InputEnded:Connect(function(input,gp)
    if gp then return end
    if input.KeyCode == features.zoom.key then
        features.zoom.active = false
        Camera.FieldOfView = features.zoom.normalFOV
    end
    if input.KeyCode == features.aimbot.key then
        features.aimbot.active = false
    end
end)

--========================================================--
-- LOOP
--========================================================--

RunService.RenderStepped:Connect(function()
    -- LINES
    for player,line in pairs(lines) do
        if features.lines.enabled and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local root = player.Character.HumanoidRootPart
            local pos, visible = Camera:WorldToViewportPoint(root.Position)
            if visible then
                line.Visible = true
                line.From = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y)
                line.To = Vector2.new(pos.X, pos.Y)
                line.Color = features.lines.color
                line.Thickness = features.lines.thickness
            else
                line.Visible = false
            end
        else
            if line then line.Visible = false end
        end
    end

    -- LIGHTING
    if features.lighting.enabled then
        Lighting.Ambient = features.lighting.color
        Lighting.OutdoorAmbient = features.lighting.color
        Lighting.Brightness = features.lighting.brightness
        Lighting.GlobalShadows = false
        Lighting.ClockTime = 12
        Lighting.FogEnd = 100000
        Lighting.FogStart = 100000
    end

    -- CIRCLE
    if features.aimbot.enabled then
        fovCircle.Visible = true
        fovCircle.Position = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
        fovCircle.Radius = features.aimbot.circleRadius
        fovCircle.Color = features.aimbot.circleColor
        fovCircle.Thickness = features.aimbot.circleThickness
    else
        fovCircle.Visible = false
    end

    -- AIMBOT
    if features.aimbot.enabled and features.aimbot.active then
        local target = getTarget()
        if target then
            local cf = CFrame.new(Camera.CFrame.Position, target.Position)
            Camera.CFrame = Camera.CFrame:Lerp(cf, features.aimbot.smoothness)
        end
    end

    -- ESP UPDATE
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            updateESP(player)
        end
    end
end)

-- Форсированное обновление CanvasSize
task.wait(0.5)
updateCanvasSize()

print("✅ Premium Menu загружен! Нажми INS для открытия")
print("📌 ESP показывает ХП и дистанцию до игроков")
print("📌 Все настройки ESP в разделе 👁️ ESP")