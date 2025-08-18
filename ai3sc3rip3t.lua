local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local Camera = Workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- ESP Settings
local ESPSettings = {
    Enabled = true,
    TeamCheck = false,
    ShowTeam = false,
    MaxDistance = 3000,
    RefreshRate = 1/30,
    HealthESP = true,
    HealthMaxDistance = 2000,
    ShowDistance = true,
    DistanceUnit = "m",
    DistanceMaxDistance = 2000,
}

local ESPColors = {
    Enemy = Color3.fromRGB(255, 50, 50),
    Ally = Color3.fromRGB(50, 255, 50),
    Health = Color3.fromRGB(80, 255, 80),
    Distance = Color3.fromRGB(200, 200, 200),
}

local ESPDrawings = {
    ESP = {}
}

-- Aimbot Settings
local AimbotSettings = {
    TargetPartName = "Head",
    VerticalOffsetBase = 0,
    VerticalOffsetScalar = 0,
    AimFOVDegrees = 10,
    CrosshairYOffsetPixels = -30,
    SecondDotYOffsetPixels = 100,
    SecondDotSizeScale = 0.5,
    
    AimbotEnabled = false,
    AimbotNPCAndDeadEnabled = false,
    CrosshairEnabled = false,
}

local lockedTarget = nil
local CrosshairGui = Instance.new("ScreenGui")
CrosshairGui.Name = "CrosshairGui"
CrosshairGui.ResetOnSpawn = false
CrosshairGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local CrosshairDot = Instance.new("Frame")
CrosshairDot.Name = "CrosshairDot"
CrosshairDot.Size = UDim2.new(0, 3, 0, 3)
CrosshairDot.Position = UDim2.new(0.5, 0, 0.5, AimbotSettings.CrosshairYOffsetPixels)
CrosshairDot.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
CrosshairDot.BorderSizePixel = 0
CrosshairDot.AnchorPoint = Vector2.new(0.5, 0.5)
CrosshairDot.Visible = false
CrosshairDot.Parent = CrosshairGui

local SecondDot = Instance.new("Frame")
SecondDot.Name = "SecondDot"
SecondDot.Size = UDim2.new(0, 9, 0, 9)
SecondDot.Position = UDim2.new(0.5, 0, 0.5, AimbotSettings.SecondDotYOffsetPixels)
SecondDot.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
SecondDot.BorderSizePixel = 0
SecondDot.AnchorPoint = Vector2.new(0.5, 0.5)
SecondDot.Visible = false
SecondDot.Parent = CrosshairGui

-- ESP Functions
local function HideAllESPDrawings()
    for player, espData in pairs(ESPDrawings.ESP) do
        if espData then
            if espData.HealthBar and espData.HealthBar.Text then
                espData.HealthBar.Text.Visible = false
            end
            if espData.Info and espData.Info.Distance then
                espData.Info.Distance.Visible = false
            end
        end
    end
end

local function CleanupESP()
    for player, espData in pairs(ESPDrawings.ESP) do
        if espData then
            if espData.HealthBar and espData.HealthBar.Text then
                espData.HealthBar.Text:Remove()
            end
            if espData.Info and espData.Info.Distance then
                espData.Info.Distance:Remove()
            end
        end
    end
    ESPDrawings.ESP = {}
end

local function CreateESP(player)
    if player == LocalPlayer or ESPDrawings.ESP[player] then return end

    local healthBar = {
        Text = Drawing.new("Text")
    }
    healthBar.Text.Visible = false
    healthBar.Text.Center = true
    healthBar.Text.Size = 14
    healthBar.Text.Color = ESPColors.Health
    healthBar.Text.Font = 2
    healthBar.Text.Outline = true

    local info = {
        Distance = Drawing.new("Text")
    }
    info.Distance.Visible = false
    info.Distance.Center = true
    info.Distance.Size = 14
    info.Distance.Color = ESPColors.Distance
    info.Distance.Font = 2
    info.Distance.Outline = true

    ESPDrawings.ESP[player] = {
        HealthBar = healthBar,
        Info = info,
    }
end

local function RemoveESP(player)
    local esp = ESPDrawings.ESP[player]
    if esp then
        if esp.HealthBar and esp.HealthBar.Text then esp.HealthBar.Text:Remove() end
        if esp.Info and esp.Info.Distance then esp.Info.Distance:Remove() end
        ESPDrawings.ESP[player] = nil
    end
end

local function GetPlayerColor(player)
    if not player.Team or not LocalPlayer.Team then
        return ESPColors.Enemy
    end
    return player.Team == LocalPlayer.Team and ESPColors.Ally or ESPColors.Enemy
end

local function UpdateESP(player)
    local esp = ESPDrawings.ESP[player]
    local character = player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    local rootPart = character and character:FindFirstChild("HumanoidRootPart")

    local function hide()
        if esp then
            esp.HealthBar.Text.Visible = false
            esp.Info.Distance.Visible = false
        end
    end

    if not (esp and character and humanoid and humanoid.Health > 0 and rootPart) then
        return hide()
    end

    local distance = (rootPart.Position - Camera.CFrame.Position).Magnitude
    if distance > ESPSettings.MaxDistance then
        return hide()
    end

    if ESPSettings.TeamCheck and player.Team == LocalPlayer.Team and not ESPSettings.ShowTeam then
        return hide()
    end

    local pos, onScreen = Camera:WorldToViewportPoint(rootPart.Position)
    if not onScreen then
        return hide()
    end

    local size = character:GetExtentsSize()
    local cf = rootPart.CFrame
    local top_pos = Camera:WorldToViewportPoint((cf * CFrame.new(0, size.Y / 2, 0)).Position)
    local bottom_pos = Camera:WorldToViewportPoint((cf * CFrame.new(0, -size.Y / 2, 0)).Position)
    
    local screenSize = bottom_pos.Y - top_pos.Y
    local boxWidth = screenSize * 0.65
    local boxPosition = Vector2.new(top_pos.X - boxWidth / 2, top_pos.Y)

    if ESPSettings.HealthESP and distance <= ESPSettings.HealthMaxDistance then
        esp.HealthBar.Text.Text = math.floor(humanoid.Health)
        esp.HealthBar.Text.Position = Vector2.new(boxPosition.X + boxWidth + 5, boxPosition.Y)
        esp.HealthBar.Text.Visible = true
        esp.HealthBar.Text.Color = ESPColors.Health
    else
        esp.HealthBar.Text.Visible = false
    end

    if ESPSettings.ShowDistance and distance <= ESPSettings.DistanceMaxDistance then
        local distanceInMeters = distance * 0.28
        esp.Info.Distance.Text = string.format("[%.0f%s]", distanceInMeters, ESPSettings.DistanceUnit)
        esp.Info.Distance.Position = Vector2.new(pos.X, bottom_pos.Y + 5)
        esp.Info.Distance.Visible = true
    else
        esp.Info.Distance.Visible = false
    end
end

-- Aimbot Functions
local function checkObstruction(targetPosition, targetCharacter)
    local rayOrigin = Camera.CFrame.Position
    local rayDirection = targetPosition - rayOrigin
    local distanceToTarget = rayDirection.Magnitude

    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude

    local filterList = {}
    if LocalPlayer.Character then table.insert(filterList, LocalPlayer.Character) end
    if targetCharacter then table.insert(filterList, targetCharacter) end

    raycastParams.FilterDescendantsInstances = filterList
    raycastParams.IgnoreWater = true

    local raycastResult = Workspace:Raycast(rayOrigin, rayDirection, raycastParams)

    if raycastResult and raycastResult.Distance < distanceToTarget - 0.5 then
        return true
    end
    return false
end

local function getFacingTarget(aimingPlayersOnly)
    local localCharacter = LocalPlayer.Character
    if not localCharacter or not localCharacter:FindFirstChild("HumanoidRootPart") then return nil end

    local playerLookVector = Camera.CFrame.LookVector
    local playerPosition = Camera.CFrame.Position
    local AIM_FOV_RADIANS = math.rad(AimbotSettings.AimFOVDegrees)

    if lockedTarget and lockedTarget:IsDescendantOf(Workspace) then
        local humanoid = lockedTarget:FindFirstChildOfClass("Humanoid")
        local targetHead = lockedTarget:FindFirstChild(AimbotSettings.TargetPartName)

        local isValidLockedTarget = false
        if humanoid and targetHead then
            if aimingPlayersOnly then
                if Players:GetPlayerFromCharacter(lockedTarget) and humanoid.Health > 0 then
                    isValidLockedTarget = true
                end
            else
                local isPlayerCharacter = Players:GetPlayerFromCharacter(lockedTarget) ~= nil
                if lockedTarget ~= localCharacter then
                    if isPlayerCharacter then
                        if humanoid.Health <= 0 then
                            isValidLockedTarget = true
                        end
                    else
                        isValidLockedTarget = true
                    end
                end
            end
        end

        if isValidLockedTarget then
            local distance = (targetHead.Position - playerPosition).Magnitude
            local dynamicOffset = AimbotSettings.VerticalOffsetBase + (distance * AimbotSettings.VerticalOffsetScalar)
            local adjustedPosition = targetHead.Position + Vector3.new(0, dynamicOffset, 0)
            return adjustedPosition, lockedTarget
        else
            lockedTarget = nil
        end
    end

    if not lockedTarget then
        local bestTargetPart = nil
        local smallestAngle = AIM_FOV_RADIANS
        local closestDistance = math.huge

        local potentialTargets = {}
        if aimingPlayersOnly then
            for _, player in ipairs(Players:GetPlayers()) do
                if player ~= LocalPlayer and player.Character then
                    local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
                    if humanoid and humanoid.Health > 0 then
                        table.insert(potentialTargets, player.Character)
                    end
                end
            end
        else
            for _, entity in ipairs(Workspace:GetChildren()) do
                if entity == localCharacter or not entity:IsA("Model") then
                    continue
                end

                local humanoid = entity:FindFirstChildOfClass("Humanoid")
                if humanoid then
                    local isPlayerCharacter = Players:GetPlayerFromCharacter(entity) ~= nil

                    if isPlayerCharacter then
                        if humanoid.Health <= 0 then
                            table.insert(potentialTargets, entity)
                        end
                    else
                        table.insert(potentialTargets, entity)
                    end
                end
            end
        end

        for _, entity in ipairs(potentialTargets) do
            local targetHead = entity:FindFirstChild(AimbotSettings.TargetPartName)
            if targetHead then
                local distance = (targetHead.Position - playerPosition).Magnitude
                local vectorToTarget = (targetHead.Position - playerPosition).Unit
                local angle = math.acos(playerLookVector:Dot(vectorToTarget))

                if angle < smallestAngle then
                    smallestAngle = angle
                    bestTargetPart = targetHead
                    closestDistance = distance
                end
            end
        end

        if bestTargetPart then
            lockedTarget = bestTargetPart.Parent
            local dynamicOffset = AimbotSettings.VerticalOffsetBase + (closestDistance * AimbotSettings.VerticalOffsetScalar)
            local adjustedPosition = bestTargetPart.Position + Vector3.new(0, dynamicOffset, 0)
            return adjustedPosition, lockedTarget
        end
    end

    return nil
end

local function startAimbot()
    RunService.RenderStepped:Connect(function()
        local currentAimbotActive = AimbotSettings.AimbotEnabled or AimbotSettings.AimbotNPCAndDeadEnabled

        if not currentAimbotActive or not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            if CrosshairDot.Visible then
                CrosshairDot.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                SecondDot.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            end
            return
        end

        local targetPosition, targetCharacter = nil
        if AimbotSettings.AimbotEnabled then
            targetPosition, targetCharacter = getFacingTarget(true)
        elseif AimbotSettings.AimbotNPCAndDeadEnabled then
            targetPosition, targetCharacter = getFacingTarget(false)
        end

        if targetPosition then
            local desiredDirection = (targetPosition - Camera.CFrame.Position).Unit
            local newCFrame = CFrame.new(Camera.CFrame.Position, Camera.CFrame.Position + desiredDirection)
            Camera.CFrame = Camera.CFrame:Lerp(newCFrame, 0.9)

            if CrosshairDot.Visible then
                if targetCharacter and not checkObstruction(targetPosition, targetCharacter) then
                    CrosshairDot.BackgroundColor3 = Color3.fromRGB(128, 0, 128)
                    SecondDot.BackgroundColor3 = Color3.fromRGB(128, 0, 128)
                else
                    CrosshairDot.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                    SecondDot.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                end
            end
        else
            if CrosshairDot.Visible then
                CrosshairDot.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                SecondDot.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            end
        end
    end)
end

local function onCharacterAdded(character)
    AimbotSettings.AimbotEnabled = false
    AimbotSettings.AimbotNPCAndDeadEnabled = false
    lockedTarget = nil

    CrosshairDot.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    SecondDot.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
end

-- Input Bindings
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end

    if input.KeyCode == Enum.KeyCode.X then
        AimbotSettings.AimbotEnabled = true
        AimbotSettings.AimbotNPCAndDeadEnabled = false
        lockedTarget = nil
    end

    if input.KeyCode == Enum.KeyCode.Z then
        AimbotSettings.AimbotNPCAndDeadEnabled = true
        AimbotSettings.AimbotEnabled = false
        lockedTarget = nil
    end

    if input.KeyCode == Enum.KeyCode.H then
        AimbotSettings.CrosshairEnabled = not AimbotSettings.CrosshairEnabled
        CrosshairDot.Visible = AimbotSettings.CrosshairEnabled
        SecondDot.Visible = AimbotSettings.CrosshairEnabled

        if AimbotSettings.CrosshairEnabled then
            CrosshairDot.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            SecondDot.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        end
    end
end)

UserInputService.InputEnded:Connect(function(input, gameProcessed)
    if gameProcessed then return end

    if input.KeyCode == Enum.KeyCode.X then
        AimbotSettings.AimbotEnabled = false
        lockedTarget = nil
    end

    if input.KeyCode == Enum.KeyCode.K then
        AimbotSettings.AimbotNPCAndDeadEnabled = false
        lockedTarget = nil
    end
end)

-- ESP Main Loop
local lastESPUpdate = 0
local isCurrentlyESPEnabled = ESPSettings.Enabled

RunService.RenderStepped:Connect(function()
    -- ESP Update
    if ESPSettings.Enabled ~= isCurrentlyESPEnabled then
        isCurrentlyESPEnabled = ESPSettings.Enabled
        if not isCurrentlyESPEnabled then
            HideAllESPDrawings()
        end
    end

    if not ESPSettings.Enabled then return end

    local now = tick()
    if now - lastESPUpdate < ESPSettings.RefreshRate then
        return
    end
    lastESPUpdate = now

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            if not ESPDrawings.ESP[player] then
                CreateESP(player)
            end
            UpdateESP(player)
        end
    end
end)

-- Initialize
Players.PlayerAdded:Connect(CreateESP)
Players.PlayerRemoving:Connect(RemoveESP)

for _, player in ipairs(Players:GetPlayers()) do
    CreateESP(player)
end

LocalPlayer.CharacterAdded:Connect(onCharacterAdded)
if LocalPlayer.Character then
    onCharacterAdded(LocalPlayer.Character)
end

startAimbot()

game:BindToClose(function()
    CleanupESP()
end)

-- Всё сделанно нейронкой бесплатной
