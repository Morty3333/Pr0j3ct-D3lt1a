--// =========================================================
--// PREMIUM UNIVERSAL MENU
--// Линии + Зум + Освещение + FOV + AIMBOT + ESP (ХП, Дистанция) + ТРУПЫ + ВЫХОДЫ
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
    },

    corpses = {
        enabled = false,
        showDistance = true,
        color = Color3.fromRGB(255,100,100),
        distanceColor = Color3.fromRGB(200,200,200),
        maxDistance = 2000,
        textSize = 12
    },

    exits = {
        enabled = false,
        showDistance = true,
        color = Color3.fromRGB(100,255,100),
        distanceColor = Color3.fromRGB(200,200,200),
        maxDistance = 3000,
        textSize = 14
    }
}

-- Координаты выходов
local exitLocations = {
    {pos = Vector3.new(-2022, 27, -2672), name = "ВЫХОД 1"},
    {pos = Vector3.new(-1153, 28, -3005), name = "ВЫХОД 2"}
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
local corpseDrawings = {}
local exitDrawings = {}

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

    if features.esp.health then
        esp.health.Text = math.floor(humanoid.Health)
        esp.health.Position = Vector2.new(boxPosition.X + boxWidth + 8, boxPosition.Y + boxHeight / 2 - 7)
        esp.health.Visible = true
        esp.health.Color = features.esp.healthColor
    else
        esp.health.Visible = false
    end

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
-- ФУНКЦИИ ТРУПОВ (С ОТДЕЛЬНЫМ ТЕКСТОМ ДЛЯ ДИСТАНЦИИ)
--========================================================--

task.spawn(function()
    while true do
        if features.corpses.enabled then
            for corpse, drawings in pairs(corpseDrawings) do
                if not corpse or not corpse.Parent then
                    if drawings.text then drawings.text:Remove() end
                    if drawings.distance then drawings.distance:Remove() end
                    corpseDrawings[corpse] = nil
                end
            end
            
            for _, child in ipairs(Workspace:GetChildren()) do
                if child:IsA("Model") then
                    local humanoid = child:FindFirstChild("Humanoid")
                    if humanoid and humanoid.Health <= 0 then
                        local player = Players:GetPlayerFromCharacter(child)
                        if player ~= LocalPlayer then
                            local rootPart = child:FindFirstChild("HumanoidRootPart") or 
                                           child:FindFirstChild("UpperTorso") or 
                                           child:FindFirstChild("Torso") or
                                           child:FindFirstChild("Head")
                            
                            if rootPart then
                                local distance = (rootPart.Position - Camera.CFrame.Position).Magnitude
                                
                                if distance <= features.corpses.maxDistance then
                                    local pos, onScreen = Camera:WorldToViewportPoint(rootPart.Position)
                                    
                                    if onScreen then
                                        if not corpseDrawings[child] then
                                            local text = Drawing.new("Text")
                                            text.Center = true
                                            text.Font = 2
                                            text.Outline = true
                                            
                                            local distText = Drawing.new("Text")
                                            distText.Center = true
                                            distText.Font = 2
                                            distText.Outline = true
                                            distText.Size = 10
                                            
                                            corpseDrawings[child] = {
                                                text = text,
                                                distance = distText
                                            }
                                        end
                                        
                                        local drawings = corpseDrawings[child]
                                        
                                        -- Основная надпись
                                        drawings.text.Text = "💀 ТРУП"
                                        drawings.text.Position = Vector2.new(pos.X, pos.Y - 15)
                                        drawings.text.Color = features.corpses.color
                                        drawings.text.Size = features.corpses.textSize
                                        drawings.text.Visible = true
                                        
                                        -- Дистанция (отдельным текстом)
                                        if features.corpses.showDistance then
                                            local distMeters = math.floor(distance * 0.28)
                                            drawings.distance.Text = "["..distMeters.."m]"
                                            drawings.distance.Position = Vector2.new(pos.X, pos.Y + 5)
                                            drawings.distance.Color = features.corpses.distanceColor
                                            drawings.distance.Visible = true
                                        else
                                            drawings.distance.Visible = false
                                        end
                                    else
                                        if corpseDrawings[child] then
                                            corpseDrawings[child].text.Visible = false
                                            if corpseDrawings[child].distance then
                                                corpseDrawings[child].distance.Visible = false
                                            end
                                        end
                                    end
                                else
                                    if corpseDrawings[child] then
                                        corpseDrawings[child].text.Visible = false
                                        if corpseDrawings[child].distance then
                                            corpseDrawings[child].distance.Visible = false
                                        end
                                    end
                                end
                            else
                                if corpseDrawings[child] then
                                    corpseDrawings[child].text.Visible = false
                                    if corpseDrawings[child].distance then
                                        corpseDrawings[child].distance.Visible = false
                                    end
                                end
                            end
                        end
                    end
                end
            end
        else
            for _, drawings in pairs(corpseDrawings) do
                if drawings.text then drawings.text.Visible = false end
                if drawings.distance then drawings.distance.Visible = false end
            end
        end
        
        task.wait(0.2)
    end
end)

--========================================================--
-- ФУНКЦИИ ВЫХОДОВ
--========================================================--

task.spawn(function()
    while true do
        if features.exits.enabled then
            for i, exit in ipairs(exitLocations) do
                local exitId = "exit_"..i
                local distance = (exit.pos - Camera.CFrame.Position).Magnitude
                
                if distance <= features.exits.maxDistance then
                    local pos, onScreen = Camera:WorldToViewportPoint(exit.pos)
                    
                    if onScreen then
                        if not exitDrawings[exitId] then
                            local text = Drawing.new("Text")
                            text.Center = true
                            text.Font = 2
                            text.Outline = true
                            exitDrawings[exitId] = text
                        end
                        
                        local text = exitDrawings[exitId]
                        
                        local displayText = "🚪 "..exit.name
                        if features.exits.showDistance then
                            local distMeters = math.floor(distance * 0.28)
                            displayText = "🚪 "..exit.name.." ["..distMeters.."m]"
                        end
                        
                        text.Text = displayText
                        text.Position = Vector2.new(pos.X, pos.Y)
                        text.Color = features.exits.color
                        text.Size = features.exits.textSize
                        text.Visible = true
                    else
                        if exitDrawings[exitId] then
                            exitDrawings[exitId].Visible = false
                        end
                    end
                else
                    if exitDrawings[exitId] then
                        exitDrawings[exitId].Visible = false
                    end
                end
            end
        else
            for _, text in pairs(exitDrawings) do
                text.Visible = false
            end
        end
        
        task.wait(0.2)
    end
end)

--========================================================--
-- GUI С ВКЛАДКАМИ
--========================================================--

local gui = Instance.new("ScreenGui")
gui.Name = "PremiumMenu"
gui.ResetOnSpawn = false
gui.Parent = game.CoreGui

local main = Instance.new("Frame")
main.Parent = gui
main.Size = UDim2.new(0, 550, 0, 600)
main.Position = UDim2.new(0.5, -275, 0.5, -300)
main.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
main.BorderSizePixel = 0
main.Visible = false
Instance.new("UICorner", main).CornerRadius = UDim.new(0, 12)

-- TITLE
local title = Instance.new("TextLabel")
title.Parent = main
title.Size = UDim2.new(1, 0, 0, 45)
title.BackgroundColor3 = Color3.fromRGB(35, 35, 50)
title.Text = "⚡ PREMIUM MENU ⚡"
title.TextColor3 = Color3.fromRGB(255, 200, 100)
title.Font = Enum.Font.GothamBold
title.TextSize = 20
Instance.new("UICorner", title).CornerRadius = UDim.new(0, 12)

-- Кнопка закрытия
local closeBtn = Instance.new("TextButton")
closeBtn.Parent = title
closeBtn.Size = UDim2.new(0, 35, 0, 35)
closeBtn.Position = UDim2.new(1, -38, 0, 5)
closeBtn.Text = "✕"
closeBtn.TextColor3 = Color3.fromRGB(255, 100, 100)
closeBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
closeBtn.BorderSizePixel = 0
closeBtn.TextSize = 18
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 8)
closeBtn.MouseButton1Click:Connect(function()
    main.Visible = false
end)

-- DRAG
local dragging = false
local dragStart, startPos
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
        main.Position = UDim2.new(0, startPos.X.Offset + delta.X, 0, startPos.Y.Offset + delta.Y)
    end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
end)

--========================================================--
-- ВКЛАДКИ
--========================================================--

local tabContainer = Instance.new("Frame")
tabContainer.Parent = main
tabContainer.Size = UDim2.new(1, 0, 0, 40)
tabContainer.Position = UDim2.new(0, 0, 0, 45)
tabContainer.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
tabContainer.BackgroundTransparency = 0
tabContainer.BorderSizePixel = 0

local contentContainer = Instance.new("Frame")
contentContainer.Parent = main
contentContainer.Size = UDim2.new(1, -10, 1, -95)
contentContainer.Position = UDim2.new(0, 5, 0, 90)
contentContainer.BackgroundTransparency = 1

-- Создание вкладок
local tabs = {"ESP", "AIMBOT", "WHAT", "WORLD", "UV"}
local currentTab = 1
local tabButtons = {}
local contentFrames = {}

local function createTabButton(name, index)
    local btn = Instance.new("TextButton")
    btn.Parent = tabContainer
    btn.Size = UDim2.new(0.2, -2, 1, -4)
    btn.Position = UDim2.new((index - 1) * 0.2, 1, 0, 2)
    btn.Text = name
    btn.TextColor3 = index == 1 and Color3.fromRGB(255, 200, 100) or Color3.fromRGB(180, 180, 200)
    btn.BackgroundColor3 = index == 1 and Color3.fromRGB(45, 45, 65) or Color3.fromRGB(35, 35, 50)
    btn.BorderSizePixel = 0
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 14
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
    
    btn.MouseButton1Click:Connect(function()
        currentTab = index
        for i, b in pairs(tabButtons) do
            b.TextColor3 = i == index and Color3.fromRGB(255, 200, 100) or Color3.fromRGB(180, 180, 200)
            b.BackgroundColor3 = i == index and Color3.fromRGB(45, 45, 65) or Color3.fromRGB(35, 35, 50)
        end
        for i, frame in pairs(contentFrames) do
            frame.Visible = (i == index)
        end
    end)
    
    return btn
end

-- Создаём контент для каждой вкладки
local function createContentFrame()
    local frame = Instance.new("ScrollingFrame")
    frame.Parent = contentContainer
    frame.Size = UDim2.new(1, 0, 1, 0)
    frame.BackgroundTransparency = 1
    frame.BorderSizePixel = 0
    frame.ScrollBarThickness = 6
    frame.Visible = false
    
    local container = Instance.new("Frame")
    container.Parent = frame
    container.Size = UDim2.new(1, 0, 0, 0)
    container.BackgroundTransparency = 1
    container.AutomaticSize = Enum.AutomaticSize.Y
    
    local layout = Instance.new("UIListLayout")
    layout.Parent = container
    layout.Padding = UDim.new(0, 8)
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    
    local function updateCanvas()
        frame.CanvasSize = UDim2.new(0, 0, 0, container.AbsoluteSize.Y + 10)
    end
    container:GetPropertyChangedSignal("AbsoluteSize"):Connect(updateCanvas)
    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateCanvas)
    task.wait(0.1)
    updateCanvas()
    
    return frame, container
end

-- Создаём 5 вкладок
for i = 1, 5 do
    table.insert(tabButtons, createTabButton(tabs[i], i))
    local frame, container = createContentFrame()
    contentFrames[i] = frame
    if i == 1 then frame.Visible = true end
end

--========================================================--
-- UI ФУНКЦИИ
--========================================================--

local activeColorPicker = nil

local function createSection(parent, name, icon)
    local frame = Instance.new("Frame")
    frame.Parent = parent
    frame.Size = UDim2.new(1, -10, 0, 0)
    frame.BackgroundColor3 = Color3.fromRGB(35, 35, 50)
    frame.BorderSizePixel = 0
    frame.AutomaticSize = Enum.AutomaticSize.Y
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 12)

    local titleLabel = Instance.new("TextLabel")
    titleLabel.Parent = frame
    titleLabel.Size = UDim2.new(1, 0, 0, 35)
    titleLabel.BackgroundColor3 = Color3.fromRGB(45, 45, 65)
    titleLabel.Text = icon.." "..name
    titleLabel.TextColor3 = Color3.fromRGB(255, 200, 100)
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextSize = 16
    Instance.new("UICorner", titleLabel).CornerRadius = UDim.new(0, 12)

    local holder = Instance.new("Frame")
    holder.Parent = frame
    holder.Size = UDim2.new(1, -10, 0, 0)
    holder.Position = UDim2.new(0, 5, 0, 40)
    holder.BackgroundTransparency = 1
    holder.AutomaticSize = Enum.AutomaticSize.Y

    local lay = Instance.new("UIListLayout")
    lay.Parent = holder
    lay.Padding = UDim.new(0, 6)

    return holder
end

local function createToggle(parent, text, getter, setter)
    local button = Instance.new("TextButton")
    button.Parent = parent
    button.Size = UDim2.new(1, 0, 0, 35)
    button.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
    button.Font = Enum.Font.Gotham
    button.TextSize = 14
    Instance.new("UICorner", button).CornerRadius = UDim.new(0, 8)

    local function update()
        if getter() then
            button.Text = text.." : ✅ ON"
            button.TextColor3 = Color3.fromRGB(0, 255, 120)
        else
            button.Text = text.." : ❌ OFF"
            button.TextColor3 = Color3.fromRGB(255, 100, 100)
        end
    end
    update()

    button.Activated:Connect(function()
        setter(not getter())
        update()
    end)
end

local function createSlider(parent, text, min, max, getter, setter, isInt)
    local frame = Instance.new("Frame")
    frame.Parent = parent
    frame.Size = UDim2.new(1, 0, 0, 55)
    frame.BackgroundTransparency = 1

    local label = Instance.new("TextLabel")
    label.Parent = frame
    label.Size = UDim2.new(1, 0, 0, 20)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Color3.new(1, 1, 1)
    label.Font = Enum.Font.Gotham
    label.TextSize = 13

    local valueLabel = Instance.new("TextLabel")
    valueLabel.Parent = frame
    valueLabel.Size = UDim2.new(1, 0, 0, 20)
    valueLabel.Position = UDim2.new(0, 0, 0, 20)
    valueLabel.BackgroundTransparency = 1
    local val = getter()
    if isInt then val = math.floor(val) end
    valueLabel.Text = "⭐ "..tostring(val)
    valueLabel.TextColor3 = Color3.fromRGB(255, 200, 100)
    valueLabel.Font = Enum.Font.Gotham
    valueLabel.TextSize = 12

    local bar = Instance.new("Frame")
    bar.Parent = frame
    bar.Size = UDim2.new(1, 0, 0, 12)
    bar.Position = UDim2.new(0, 0, 0, 38)
    bar.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
    Instance.new("UICorner", bar).CornerRadius = UDim.new(1, 0)

    local fill = Instance.new("Frame")
    fill.Parent = bar
    fill.BackgroundColor3 = Color3.fromRGB(100, 170, 255)
    fill.Size = UDim2.new((getter() - min) / (max - min), 0, 1, 0)
    Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)

    local dragging = false

    local function update(input)
        local percent = math.clamp((input.Position.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
        local value = min + ((max - min) * percent)
        setter(value)
        fill.Size = UDim2.new(percent, 0, 1, 0)
        if isInt then
            valueLabel.Text = "⭐ "..math.floor(value)
        else
            valueLabel.Text = "⭐ "..math.floor(value * 100) / 100
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

local function createColorPicker(parent, text, getter, setter)
    local button = Instance.new("TextButton")
    button.Parent = parent
    button.Size = UDim2.new(1, 0, 0, 35)
    button.BackgroundColor3 = getter()
    button.Text = "🎨 "..text
    button.TextColor3 = Color3.new(1, 1, 1)
    button.Font = Enum.Font.GothamBold
    button.TextSize = 13
    Instance.new("UICorner", button).CornerRadius = UDim.new(0, 8)
    
    button.Activated:Connect(function()
        if activeColorPicker then activeColorPicker:Destroy() end

        local picker = Instance.new("Frame")
        picker.Parent = gui
        picker.Size = UDim2.new(0, 280, 0, 220)
        picker.Position = UDim2.new(0.5, -140, 0.5, -110)
        picker.BackgroundColor3 = Color3.fromRGB(35, 35, 50)
        picker.BorderSizePixel = 1
        picker.BorderColor3 = Color3.fromRGB(80, 80, 120)
        Instance.new("UICorner", picker).CornerRadius = UDim.new(0, 12)

        local pickerTitle = Instance.new("TextLabel")
        pickerTitle.Parent = picker
        pickerTitle.Size = UDim2.new(1, 0, 0, 35)
        pickerTitle.BackgroundColor3 = Color3.fromRGB(45, 45, 65)
        pickerTitle.Text = "🎨 RGB ПАЛИТРА"
        pickerTitle.TextColor3 = Color3.fromRGB(255, 200, 100)
        pickerTitle.Font = Enum.Font.GothamBold
        pickerTitle.TextSize = 15
        Instance.new("UICorner", pickerTitle).CornerRadius = UDim.new(0, 12)

        local closePicker = Instance.new("TextButton")
        closePicker.Parent = picker
        closePicker.Size = UDim2.new(0, 30, 0, 30)
        closePicker.Position = UDim2.new(1, -35, 0, 3)
        closePicker.Text = "✕"
        closePicker.TextColor3 = Color3.fromRGB(255, 100, 100)
        closePicker.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
        closePicker.Font = Enum.Font.GothamBold
        closePicker.TextSize = 16
        closePicker.BorderSizePixel = 0
        Instance.new("UICorner", closePicker).CornerRadius = UDim.new(0, 8)
        closePicker.Activated:Connect(function()
            picker:Destroy()
            activeColorPicker = nil
        end)

        local r, g, b = getter().R, getter().G, getter().B
        local colorPreview = Instance.new("Frame")
        colorPreview.Parent = picker
        colorPreview.Size = UDim2.new(0, 50, 0, 50)
        colorPreview.Position = UDim2.new(0, 15, 0, 50)
        colorPreview.BackgroundColor3 = getter()
        colorPreview.BorderSizePixel = 1
        colorPreview.BorderColor3 = Color3.fromRGB(255, 255, 255)
        Instance.new("UICorner", colorPreview).CornerRadius = UDim.new(0, 8)

        local function makeSlider(name, color, startY)
            local label = Instance.new("TextLabel")
            label.Parent = picker
            label.Position = UDim2.new(0, 80, 0, startY)
            label.Size = UDim2.new(0, 30, 0, 20)
            label.Text = name
            label.TextColor3 = color
            label.BackgroundTransparency = 1
            label.Font = Enum.Font.GothamBold
            label.TextSize = 16

            local valueBox = Instance.new("TextBox")
            valueBox.Parent = picker
            valueBox.Position = UDim2.new(0, 230, 0, startY - 3)
            valueBox.Size = UDim2.new(0, 40, 0, 25)
            valueBox.Text = "0.00"
            valueBox.TextColor3 = Color3.fromRGB(255, 255, 255)
            valueBox.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
            valueBox.Font = Enum.Font.Gotham
            valueBox.TextSize = 11
            Instance.new("UICorner", valueBox).CornerRadius = UDim.new(0, 6)

            local bar = Instance.new("Frame")
            bar.Parent = picker
            bar.Position = UDim2.new(0, 80, 0, startY + 22)
            bar.Size = UDim2.new(0, 190, 0, 10)
            bar.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
            Instance.new("UICorner", bar).CornerRadius = UDim.new(1, 0)

            local fill = Instance.new("Frame")
            fill.Parent = bar
            fill.Size = UDim2.new(0, 0, 1, 0)
            fill.BackgroundColor3 = color
            Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)

            local currentVal = 0

            local function updateValue(input)
                local percent = math.clamp((input.Position.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
                currentVal = percent
                fill.Size = UDim2.new(percent, 0, 1, 0)
                valueBox.Text = string.format("%.2f", percent)
                return percent
            end

            local dragging = false
            bar.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    dragging = true
                    local val = updateValue(input)
                    if name == "R" then r = val elseif name == "G" then g = val else b = val end
                    local newColor = Color3.new(r, g, b)
                    setter(newColor)
                    button.BackgroundColor3 = newColor
                    colorPreview.BackgroundColor3 = newColor
                end
            end)

            UserInputService.InputChanged:Connect(function(input)
                if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                    local val = updateValue(input)
                    if name == "R" then r = val elseif name == "G" then g = val else b = val end
                    local newColor = Color3.new(r, g, b)
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
                    val = math.clamp(val, 0, 1)
                    currentVal = val
                    fill.Size = UDim2.new(val, 0, 1, 0)
                    valueBox.Text = string.format("%.2f", val)
                    if name == "R" then r = val elseif name == "G" then g = val else b = val end
                    local newColor = Color3.new(r, g, b)
                    setter(newColor)
                    button.BackgroundColor3 = newColor
                    colorPreview.BackgroundColor3 = newColor
                else
                    valueBox.Text = string.format("%.2f", currentVal)
                end
            end)

            return { setVal = function(val) currentVal = val; fill.Size = UDim2.new(val, 0, 1, 0); valueBox.Text = string.format("%.2f", val) end }
        end

        local red = makeSlider("R", Color3.fromRGB(255, 80, 80), 55)
        local green = makeSlider("G", Color3.fromRGB(80, 255, 80), 105)
        local blue = makeSlider("B", Color3.fromRGB(80, 80, 255), 155)

        red.setVal(r)
        green.setVal(g)
        blue.setVal(b)
    end)
end

local function createKeybind(parent, text, getter, setter)
    local button = Instance.new("TextButton")
    button.Parent = parent
    button.Size = UDim2.new(1, 0, 0, 35)
    button.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
    button.TextColor3 = Color3.new(1, 1, 1)
    button.Font = Enum.Font.Gotham
    button.TextSize = 13
    Instance.new("UICorner", button).CornerRadius = UDim.new(0, 8)
    button.Text = "⌨ "..text.." : "..getter().Name

    button.Activated:Connect(function()
        button.Text = "⌨ "..text.." : нажми..."
        local con
        con = UserInputService.InputBegan:Connect(function(input, gp)
            if gp then return end
            if input.UserInputType == Enum.UserInputType.Keyboard then
                setter(input.KeyCode)
                button.Text = "⌨ "..text.." : "..input.KeyCode.Name
                con:Disconnect()
            end
        end)
    end)
end

local function createDropdown(parent, text, options, getter, setter)
    local index = 1
    for i, v in ipairs(options) do
        if v == getter() then index = i end
    end

    local button = Instance.new("TextButton")
    button.Parent = parent
    button.Size = UDim2.new(1, 0, 0, 35)
    button.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
    button.TextColor3 = Color3.new(1, 1, 1)
    button.Font = Enum.Font.Gotham
    button.TextSize = 13
    Instance.new("UICorner", button).CornerRadius = UDim.new(0, 8)
    button.Text = "🎯 "..text.." : "..getter()

    button.Activated:Connect(function()
        index = index + 1
        if index > #options then index = 1 end
        setter(options[index])
        button.Text = "🎯 "..text.." : "..options[index]
    end)
end

--========================================================--
-- ЗАПОЛНЕНИЕ ВКЛАДОК
--========================================================--

-- ВКЛАДКА 1: ESP (ЛИНИИ + ESP)
local espTab = contentFrames[1]:FindFirstChildWhichIsA("Frame") or (function()
    local container = Instance.new("Frame")
    container.Parent = contentFrames[1]
    container.Size = UDim2.new(1, 0, 0, 0)
    container.BackgroundTransparency = 1
    container.AutomaticSize = Enum.AutomaticSize.Y
    local layout = Instance.new("UIListLayout")
    layout.Parent = container
    layout.Padding = UDim.new(0, 8)
    return container
end)()

local lineSection = createSection(espTab, "LINES", "📏")
createToggle(lineSection, "Линии", function() return features.lines.enabled end, function(v) features.lines.enabled = v end)
createSlider(lineSection, "Толщина", 1, 10, function() return features.lines.thickness end, function(v) features.lines.thickness = v end, true)
createColorPicker(lineSection, "Цвет линий", function() return features.lines.color end, function(v) features.lines.color = v end)

local espSection = createSection(espTab, "ESP", "👁️")
createToggle(espSection, "ESP", function() return features.esp.enabled end, function(v) features.esp.enabled = v end)
createToggle(espSection, "Показывать ХП", function() return features.esp.health end, function(v) features.esp.health = v end)
createToggle(espSection, "Показывать дистанцию", function() return features.esp.distance end, function(v) features.esp.distance = v end)
createToggle(espSection, "Team Check", function() return features.esp.teamCheck end, function(v) features.esp.teamCheck = v end)
createSlider(espSection, "Макс. дистанция", 500, 5000, function() return features.esp.maxDistance end, function(v) features.esp.maxDistance = v end, true)
createColorPicker(espSection, "Цвет ХП", function() return features.esp.healthColor end, function(v) features.esp.healthColor = v end)
createColorPicker(espSection, "Цвет дистанции", function() return features.esp.distanceColor end, function(v) features.esp.distanceColor = v end)
createColorPicker(espSection, "Цвет врага", function() return features.esp.enemyColor end, function(v) features.esp.enemyColor = v end)
createColorPicker(espSection, "Цвет союзника", function() return features.esp.allyColor end, function(v) features.esp.allyColor = v end)

-- ВКЛАДКА 2: AIMBOT
local aimTab = contentFrames[2]:FindFirstChildWhichIsA("Frame") or (function()
    local container = Instance.new("Frame")
    container.Parent = contentFrames[2]
    container.Size = UDim2.new(1, 0, 0, 0)
    container.BackgroundTransparency = 1
    container.AutomaticSize = Enum.AutomaticSize.Y
    local layout = Instance.new("UIListLayout")
    layout.Parent = container
    layout.Padding = UDim.new(0, 8)
    return container
end)()

local aimSection = createSection(aimTab, "AIMBOT", "🎯")
createToggle(aimSection, "Аимбот", function() return features.aimbot.enabled end, function(v) features.aimbot.enabled = v end)
createSlider(aimSection, "Радиус круга", 50, 500, function() return features.aimbot.circleRadius end, function(v) features.aimbot.circleRadius = v end, true)
createSlider(aimSection, "Плавность", 0.1, 1, function() return features.aimbot.smoothness end, function(v) features.aimbot.smoothness = v end, false)
createSlider(aimSection, "Толщина круга", 1, 10, function() return features.aimbot.circleThickness end, function(v) features.aimbot.circleThickness = v end, true)
createColorPicker(aimSection, "Цвет круга", function() return features.aimbot.circleColor end, function(v) features.aimbot.circleColor = v end)
createKeybind(aimSection, "Кнопка аима", function() return features.aimbot.key end, function(v) features.aimbot.key = v end)
createDropdown(aimSection, "Часть тела", {"Head", "HumanoidRootPart", "UpperTorso", "LowerTorso", "Torso"}, function() return features.aimbot.targetPart end, function(v) features.aimbot.targetPart = v end)

-- ВКЛАДКА 3: WHAT (ZOOM)
local zoomTab = contentFrames[3]:FindFirstChildWhichIsA("Frame") or (function()
    local container = Instance.new("Frame")
    container.Parent = contentFrames[3]
    container.Size = UDim2.new(1, 0, 0, 0)
    container.BackgroundTransparency = 1
    container.AutomaticSize = Enum.AutomaticSize.Y
    local layout = Instance.new("UIListLayout")
    layout.Parent = container
    layout.Padding = UDim.new(0, 8)
    return container
end)()

local zoomSection = createSection(zoomTab, "ZOOM", "🔍")
createToggle(zoomSection, "Зум", function() return features.zoom.enabled end, function(v) features.zoom.enabled = v end)
createSlider(zoomSection, "FOV", 20, 120, function() return features.zoom.zoomFOV end, function(v) features.zoom.zoomFOV = v end, true)
createKeybind(zoomSection, "Кнопка зума", function() return features.zoom.key end, function(v) features.zoom.key = v end)

-- ВКЛАДКА 4: WORLD (ОСВЕЩЕНИЕ + ТРУПЫ + ВЫХОДЫ)
local worldTab = contentFrames[4]:FindFirstChildWhichIsA("Frame") or (function()
    local container = Instance.new("Frame")
    container.Parent = contentFrames[4]
    container.Size = UDim2.new(1, 0, 0, 0)
    container.BackgroundTransparency = 1
    container.AutomaticSize = Enum.AutomaticSize.Y
    local layout = Instance.new("UIListLayout")
    layout.Parent = container
    layout.Padding = UDim.new(0, 8)
    return container
end)()

-- Освещение
local lightSection = createSection(worldTab, "LIGHTING", "☀️")
createToggle(lightSection, "Освещение", function() return features.lighting.enabled end, function(v)
    features.lighting.enabled = v
    if not v then
        Lighting.Ambient = features.lighting.defaultAmbient
        Lighting.OutdoorAmbient = features.lighting.defaultOutdoor
        Lighting.Brightness = features.lighting.defaultBrightness
        Lighting.GlobalShadows = true
    end
end)
createSlider(lightSection, "Яркость", 0.5, 5, function() return features.lighting.brightness end, function(v)
    features.lighting.brightness = v
    if features.lighting.enabled then Lighting.Brightness = v end
end, false)
createColorPicker(lightSection, "Цвет карты", function() return features.lighting.color end, function(v)
    features.lighting.color = v
    if features.lighting.enabled then
        Lighting.Ambient = v
        Lighting.OutdoorAmbient = v
    end
end)

-- Трупы
local corpsesSection = createSection(worldTab, "CORPSES", "💀")
createToggle(corpsesSection, "Подсветка трупов", function() return features.corpses.enabled end, function(v) 
    features.corpses.enabled = v
end)
createToggle(corpsesSection, "Показывать дистанцию", function() return features.corpses.showDistance end, function(v) features.corpses.showDistance = v end)
createSlider(corpsesSection, "Макс. дистанция", 500, 5000, function() return features.corpses.maxDistance end, function(v) features.corpses.maxDistance = v end, true)
createSlider(corpsesSection, "Размер текста", 8, 20, function() return features.corpses.textSize end, function(v) features.corpses.textSize = v end, true)
createColorPicker(corpsesSection, "Цвет надписи", function() return features.corpses.color end, function(v) features.corpses.color = v end)
createColorPicker(corpsesSection, "Цвет дистанции", function() return features.corpses.distanceColor end, function(v) features.corpses.distanceColor = v end)

-- Выходы
local exitsSection = createSection(worldTab, "EXITS", "🚪")
createToggle(exitsSection, "Подсветка выходов", function() return features.exits.enabled end, function(v) 
    features.exits.enabled = v
end)
createToggle(exitsSection, "Показывать дистанцию", function() return features.exits.showDistance end, function(v) features.exits.showDistance = v end)
createSlider(exitsSection, "Макс. дистанция", 500, 5000, function() return features.exits.maxDistance end, function(v) features.exits.maxDistance = v end, true)
createSlider(exitsSection, "Размер текста", 8, 20, function() return features.exits.textSize end, function(v) features.exits.textSize = v end, true)
createColorPicker(exitsSection, "Цвет текста", function() return features.exits.color end, function(v) features.exits.color = v end)

-- ВКЛАДКА 5: UV (В РАЗРАБОТКЕ)
local uvTab = contentFrames[5]:FindFirstChildWhichIsA("Frame") or (function()
    local container = Instance.new("Frame")
    container.Parent = contentFrames[5]
    container.Size = UDim2.new(1, 0, 0, 0)
    container.BackgroundTransparency = 1
    container.AutomaticSize = Enum.AutomaticSize.Y
    local layout = Instance.new("UIListLayout")
    layout.Parent = container
    layout.Padding = UDim.new(0, 8)
    return container
end)()

local devSection = createSection(uvTab, "В РАЗРАБОТКЕ", "🚧")
local devLabel = Instance.new("TextLabel")
devLabel.Parent = devSection
devLabel.Size = UDim2.new(1, 0, 0, 80)
devLabel.Text = "⚡ Дополнительные функции\nбудут добавлены в следующих обновлениях!\n\nСледите за обновлениями..."
devLabel.TextColor3 = Color3.fromRGB(180, 180, 200)
devLabel.BackgroundTransparency = 1
devLabel.Font = Enum.Font.Gotham
devLabel.TextSize = 14
devLabel.TextWrapped = true

--========================================================--
-- LINES
--========================================================--

local function createLine(player)
    local line = Drawing.new("Line")
    line.Visible = false
    lines[player] = line
end

for _, player in pairs(Players:GetPlayers()) do
    if player ~= LocalPlayer then createLine(player) end
    createESP(player)
end

Players.PlayerAdded:Connect(function(player)
    if player ~= LocalPlayer then createLine(player) end
    createESP(player)
end)

Players.PlayerRemoving:Connect(function(player)
    if lines[player] then
        lines[player]:Remove()
        lines[player] = nil
    end
    removeESP(player)
end)

--========================================================--
-- AIMBOT GET TARGET
--========================================================--

local function getTarget()
    local closest = nil
    local shortest = math.huge
    local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)

    for _, player in pairs(Players:GetPlayers()) do
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

UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode.U then main.Visible = not main.Visible end
    if input.KeyCode == features.zoom.key and features.zoom.enabled then
        features.zoom.active = true
        Camera.FieldOfView = features.zoom.zoomFOV
    end
    if input.KeyCode == features.aimbot.key and features.aimbot.enabled then
        features.aimbot.active = true
    end
end)

UserInputService.InputEnded:Connect(function(input, gp)
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
    for player, line in pairs(lines) do
        if features.lines.enabled and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local root = player.Character.HumanoidRootPart
            local pos, visible = Camera:WorldToViewportPoint(root.Position)
            if visible then
                line.Visible = true
                line.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
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
        fovCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
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

-- Очистка при закрытии
game:BindToClose(function()
    for _, line in pairs(lines) do if line then line:Remove() end end
    if fovCircle then fovCircle:Remove() end
    for _, esp in pairs(espDrawings) do
        if esp.health then esp.health:Remove() end
        if esp.distance then esp.distance:Remove() end
    end
    for _, drawings in pairs(corpseDrawings) do
        if drawings.text then drawings.text:Remove() end
        if drawings.distance then drawings.distance:Remove() end
    end
    for _, text in pairs(exitDrawings) do if text then text:Remove() end end
end)