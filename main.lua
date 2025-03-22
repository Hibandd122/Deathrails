-- Khai báo các dịch vụ của Roblox
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local StarterGui = game:GetService("StarterGui")
local HttpService = game:GetService("HttpService")
local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
local camera = Workspace.CurrentCamera

-- Biến toàn cục
local dragging = false
local dragStart, startPos
local buildingESP = buildingESP or {}
local nameTags = nameTags or {}
local highlights = highlights or {}
local autoMoneybag = false
local moneybagLoopRunning = false
local espBuilding = false
local espItem = false
local menuVisible = false
local maxDistance = 1000
local maxloot = 15
local fullBright = false
local autoLoot = false
local autoLootRunning = false
local instantPrompts = false
local npcLock = false
local espNPC = false
local autoTeleportAmmo = false
local autoTeleportRunning = false
local promptLoopRunning = false
local autoDrive = false
local autoDriveRunning = false
local noclipOn = false
local noclipConnection
local InfJump = false
local InfJumpConnection
local promptsFar = false          -- Trạng thái bật/tắt PromptsFar
local promptsFarLoopRunning = false  -- Trạng thái vòng lặp
local defaultPromptDistance = 10  -- Khoảng cách mặc định của Prompts
local farPromptDistance = 20     -- Khoảng cách xa hơn khi bật
local floatName = "HumanoidRootPart"

-- Cấu trúc cài đặt hợp nhất
local settingsFile = "settings.json"
local settings = {
    toggles = {
        ESPBuilding = false,
        ESPItem = false,
        ESPNPC = false,
        AutoMoneybag = false,
        NPCLock = false,
        TeleportAmmo = false,
        FullBright = false,
        AutoLoot = false,
        Noclip = false,
        InfJump = false,
        InstantPrompts = false,
        AutoDrive = false,
        AutoWin = false,
        PromptsFar = false  -- Thêm PromptsFar
    },
    keybinds = {
        ESPBuilding = nil,
        ESPItem = nil,
        ESPNPC = nil,
        AutoMoneybag = nil,
        NPCLock = nil,
        TeleportAmmo = nil,
        FullBright = nil,
        Noclip = nil,
        InfJump = nil,
        AutoLoot = nil,
        InstantPrompts = nil,
        AutoDrive = nil,
        AutoWin = nil,
        PromptsFar = nil  -- Thêm keybind cho PromptsFar
    },
    colors = {
        ESPBuilding = {R = 255, G = 255, B = 0},
        ESPItem = {R = 0, G = 191, B = 255},
        ESPNPC = {R = 0, G = 255, B = 0},
        ESPNPCSpecial = {R = 255, G = 0, B = 0}
    }
}

-- Hàm mã hóa và giải mã JSON
local function encodeSettings(tbl)
    return HttpService:JSONEncode(tbl)
end

local function decodeSettings(jsonData)
    if typeof(jsonData) ~= "string" then return nil end
    local success, result = pcall(function()
        return HttpService:JSONDecode(jsonData)
    end)
    return success and result or nil
end

-- Hàm lưu và tải cài đặt
local function saveSettings()
    if not writefile then return end
    local dataToSave = {
        toggles = settings.toggles,
        keybinds = {},
        colors = settings.colors
    }
    for key, value in pairs(settings.keybinds) do
        dataToSave.keybinds[key] = value and value.Name or nil
    end
    writefile(settingsFile, encodeSettings(dataToSave))
end

local function loadSettings()
    if not readfile or not isfile(settingsFile) then return end
    local jsonData = readfile(settingsFile)
    local loadedData = decodeSettings(jsonData)
    if loadedData then
        for key, value in pairs(loadedData.toggles or {}) do
            if settings.toggles[key] ~= nil then
                settings.toggles[key] = value
            end
        end
        for key, value in pairs(loadedData.keybinds or {}) do
            if value then
                settings.keybinds[key] = Enum.KeyCode[value]
            end
        end
        for key, value in pairs(loadedData.colors or {}) do
            if settings.colors[key] then
                settings.colors[key] = value
            end
        end
    end
end

loadSettings()
-- Hàm áp dụng khoảng cách xa hơn và tự động nhấn Prompts
local function applyFarPrompts(enable)
    for _, prompt in pairs(game:GetDescendants()) do
        if prompt:IsA("ProximityPrompt") then
            if enable then
                -- Lưu khoảng cách mặc định nếu chưa lưu
                if not prompt:GetAttribute("DefaultMaxActivationDistance") then
                    prompt:SetAttribute("DefaultMaxActivationDistance", prompt.MaxActivationDistance)
                end
                prompt.MaxActivationDistance = farPromptDistance
                
                -- Tự động kích hoạt Prompt nếu trong phạm vi
                local character = game.Players.LocalPlayer.Character
                local rootPart = character and character:FindFirstChild("HumanoidRootPart")
                if rootPart and prompt.Parent and prompt.Parent:IsA("BasePart") then
                    local distance = (rootPart.Position - prompt.Parent.Position).Magnitude
                    if distance <= farPromptDistance then
                        print("🔥 Đang kích hoạt Prompt: " .. prompt.Parent.Name)
                        fireproximityprompt(prompt)
                    end
                end
            else
                -- Khôi phục khoảng cách mặc định
                local defaultDistance = prompt:GetAttribute("DefaultMaxActivationDistance") or defaultPromptDistance
                prompt.MaxActivationDistance = defaultDistance
            end
        end
    end
end

-- Vòng lặp để liên tục áp dụng khi bật PromptsFar
local function promptsFarLoop()
    if promptsFarLoopRunning then return end  -- Tránh tạo nhiều vòng lặp
    promptsFarLoopRunning = true
    while promptsFar do
        applyFarPrompts(true)
        task.wait(0.1)  -- Cập nhật mỗi 0.1 giây để áp dụng cho Prompts mới và tự động nhấn
    end
    applyFarPrompts(false)
    promptsFarLoopRunning = false
end
-- Hàm bật/tắt noclip
local function ToggleNoclip()
    if noclipOn then
        if noclipConnection then noclipConnection:Disconnect() end
        noclipConnection = RunService.Stepped:Connect(function()
            if noclipOn and player.Character then
                for _, child in pairs(player.Character:GetDescendants()) do
                    if child:IsA("BasePart") and child.Name ~= floatName then
                        child.CanCollide = false
                    end
                end
            end
        end)
    else
        if noclipConnection then
            noclipConnection:Disconnect()
            noclipConnection = nil
        end
        if player.Character then
            for _, child in pairs(player.Character:GetDescendants()) do
                if child:IsA("BasePart") and child.Name ~= floatName then
                    child.CanCollide = true
                end
            end
        end
    end
end
local function teleportToEnd()
    local character = game.Players.LocalPlayer.Character
    local rootPart = character and character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return end
    rootPart.CFrame = CFrame.new(-2047.5, -80, -49429, 1, 0, 0, 0, 1, 0, 0, 0, 1)
    wait(0.5)
    rootPart.CFrame = CFrame.new(0.5, -80, -49429, 1, 0, 0, 0, 1, 0, 0, 0, 1)
    wait(0.1)
end
-- Hàm kiểm tra xem người chơi có trên BridgeHalf hay không
local function isPlayerOnBridge()
    local character = game.Players.LocalPlayer.Character
    local rootPart = character and character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return false end

    local playerPos = rootPart.Position
    local bridgeHalf = game.Workspace:FindFirstChild("Baseplates")
        and game.Workspace.Baseplates:FindFirstChild("FinalBasePlate")
        and game.Workspace.Baseplates.FinalBasePlate:FindFirstChild("OutlawBase")
        and game.Workspace.Baseplates.FinalBasePlate.OutlawBase:FindFirstChild("Bridge")
        and game.Workspace.Baseplates.FinalBasePlate.OutlawBase.Bridge:FindFirstChild("BridgeHalf")

    if not bridgeHalf then return false end

    local bridgeCFrame, bridgeSize = bridgeHalf:GetBoundingBox()
    local bridgePos = bridgeCFrame.Position
    local minX, maxX = bridgePos.X - bridgeSize.X / 2, bridgePos.X + bridgeSize.X / 2
    local minY, maxY = bridgePos.Y - bridgeSize.Y / 2, bridgePos.Y + bridgeSize.Y / 2
    local minZ, maxZ = bridgePos.Z - bridgeSize.Z / 2, bridgePos.Z + bridgeSize.Z / 2

    return playerPos.X >= minX and playerPos.X <= maxX
        and playerPos.Y >= minY and playerPos.Y <= maxY
        and playerPos.Z >= minZ and playerPos.Z <= maxZ
end

-- Danh sách tọa độ để dịch chuyển
local teleportPositions = {
    CFrame.new(-377.4882570324219, 3.500000476837158, -49057.0546875, 1, 0, 0, 0, 1, 0, 0, 0, 1),
    CFrame.new(-367.093994140625, 2.999938726425171, -49052.3203125, 1, 0, 0, 0, 1, 0, 0, 0, 1),
    CFrame.new(-360.430389042069, 2.999938726425171, -49052.4375, 1, 0, 0, 0, 1, 0, 0, 0, 1),
    CFrame.new(-355.4365539550781, 2.999938726425171, -49047.703125, 1, 0, 0, 0, 1, 0, 0, 0, 1), -- Đã sửa
    CFrame.new(-353.4365539550781, 2.999938726425171, -49047.703125, 1, 0, 0, 0, 1, 0, 0, 0, 1),
    CFrame.new(-350.469, 3.4999387, -49046.155625, 1, 0, 0, 0, 1, 0, 0, 0, 1),
    CFrame.new(-347.5015, 3.9999387, -49044.608125, 1, 0, 0, 0, 1, 0, 0, 0, 1),
    CFrame.new(-344.534, 4.4999387, -49043.060625, 1, 0, 0, 0, 1, 0, 0, 0, 1),
    CFrame.new(-341.566105957031, 5, -49041.51171875, 1, 0, 0, 0, 1, 0, 0, 0, 1)
}

-- Hàm dịch chuyển qua teleportPositions
local function teleportToPositions()
    local character = game.Players.LocalPlayer.Character
    local rootPart = character and character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return end
    for i, targetCFrame in ipairs(teleportPositions) do
        rootPart.CFrame = targetCFrame
        task.wait(0.5)
    end
end
local function main()
    local character = game.Players.LocalPlayer.Character
    if not character then
        character = game.Players.LocalPlayer.CharacterAdded:Wait()
        wait(0.5)
    end
    
    local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
    if not humanoidRootPart then
        warn("HumanoidRootPart không tồn tại!")
        return
    end
    
    while settings.toggles.AutoWin do
        -- Kiểm tra và gọi teleportToEnd
        if not teleportToEnd then
            warn("teleportToEnd không được định nghĩa!")
            return
        end
        teleportToEnd()
        wait(1)
        
        -- Kiểm tra và gọi isPlayerOnBridge
        if not isPlayerOnBridge then
            warn("isPlayerOnBridge không được định nghĩa!")
            return
        end
        if isPlayerOnBridge() then
            -- Kiểm tra và gọi teleportToPositions
            if not teleportToPositions then
                warn("teleportToPositions không được định nghĩa!")
                return
            end
            teleportToPositions()
            
            -- Tắt AutoWin sau khi hoàn thành
            settings.toggles.AutoWin = false
            showNotification("Đã hoàn thành dịch chuyển, AutoWin TẮT", 1.5)
            saveSettings()
            break
        end
        wait(0.5)
    end
end
-- Hàm tìm và loot vật phẩm
local function findAndLootItems(specialItems, class, range)
    range = range or 50
    local runtimeItems = Workspace:FindFirstChild("RuntimeItems")
    local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if not runtimeItems or not root then return end

    local specialItemSet = {}
    for _, itemName in ipairs(specialItems) do
        specialItemSet[itemName:lower()] = true
    end

    while autoLoot do
        local foundSpecialItems = {}
        local foundOtherItems = {}
        local hasAnyItem = false

        for _, item in pairs(runtimeItems:GetChildren()) do
            if item:IsA(class) then
                local itemPart = item:IsA("Model") and item.PrimaryPart or (item:IsA("BasePart") and item or nil)
                if itemPart and itemPart.Position then
                    local distance = (Vector2.new(root.Position.X, root.Position.Z) - Vector2.new(itemPart.Position.X, itemPart.Position.Z)).Magnitude
                    if distance <= range then
                        local itemNameLower = item.Name:lower()
                        if specialItemSet[itemNameLower] then
                            if not foundSpecialItems[item.Name] then
                                foundSpecialItems[item.Name] = {}
                            end
                            if #foundSpecialItems[item.Name] < maxloot then
                                table.insert(foundSpecialItems[item.Name], item)
                                hasAnyItem = true
                            end
                        else
                            if #foundOtherItems < maxloot then
                                table.insert(foundOtherItems, item)
                                hasAnyItem = true
                            end
                        end
                    end
                end
            end
        end

        if not hasAnyItem then
            task.wait(1)
            return
        end

        local pickUpTool = ReplicatedStorage:FindFirstChild("Remotes")
            and ReplicatedStorage.Remotes:FindFirstChild("Tool")
            and ReplicatedStorage.Remotes.Tool:FindFirstChild("PickUpTool")
        if pickUpTool then
            for _, items in pairs(foundSpecialItems) do
                for _, item in ipairs(items) do
                    pickUpTool:FireServer(item)
                    task.wait(0.1)
                end
            end
        end

        for _, item in pairs(foundOtherItems) do
            local args = { [1] = item }
            game:GetService("ReplicatedStorage").Remotes.StoreItem:FireServer(unpack(args))
            task.wait(0.1)
        end
        task.wait(1)
    end
end

-- Hàm teleport đạn
local function teleportAmmo()
    local runtimeItems = Workspace:FindFirstChild("RuntimeItems")
    if not runtimeItems then return end

    local character = player.Character or player.CharacterAdded:Wait()
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart") or character:WaitForChild("HumanoidRootPart")

    local foundItems = {}
    for _, item in pairs(runtimeItems:GetChildren()) do
        if item:IsA("Model") and (item.Name:match("Ammo") or item.Name:match("Shells") or item.Name == "Bond") then
            local itemPart = item.PrimaryPart or item:FindFirstChildWhichIsA("BasePart")
            if itemPart then
                local delta = itemPart.Position - humanoidRootPart.Position
                local distance = math.sqrt(delta.X^2 + delta.Z^2)
                local maxDistance = item.Name == "" and 5 or 20
                
                if distance <= maxDistance then
                    table.insert(foundItems, item)
                end
            end
        end
    end

    if #foundItems == 0 then return end

    local tweens = {}
    for _, obj in pairs(foundItems) do
        local objPart = obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
        if objPart and objPart:IsA("BasePart") then
            local offsetX = math.random(-3, 3) * 2
            local offsetZ = math.random(-3, 3) * 2
            local targetCFrame = humanoidRootPart.CFrame * CFrame.new(offsetX, 1, offsetZ)
            local tweenInfo = TweenInfo.new(0.15, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)
            local tween = TweenService:Create(objPart, tweenInfo, {CFrame = targetCFrame})
            tween:Play()
            table.insert(tweens, {tween = tween, obj = obj})
        end
    end

    task.wait(0.5)
    for _, data in pairs(tweens) do
        game:GetService("ReplicatedStorage")
            :WaitForChild("Packages")
            :WaitForChild("RemotePromise")
            :WaitForChild("Remotes")
            :WaitForChild("C_ActivateObject")
            :FireServer(data.obj)
        task.wait(1)
    end
end

-- Hàm xử lý Moneybag
local function handleMoneybag(pickUp)
    local runtimeItems = Workspace:FindFirstChild("RuntimeItems")
    if not runtimeItems then return end

    local moneybags = {}
    for _, item in pairs(runtimeItems:GetChildren()) do
        if item:IsA("Model") and item.Name == "Moneybag" then
            table.insert(moneybags, item)
        end
    end

    local character = player.Character or player.CharacterAdded:Wait()
    local humanoidRootPart = character:WaitForChild("HumanoidRootPart")

    local tweens = {}
    for _, moneybag in pairs(moneybags) do
        local movePart = moneybag.PrimaryPart or moneybag:FindFirstChildWhichIsA("BasePart")
        if movePart then
            if not moneybag.PrimaryPart then moneybag.PrimaryPart = movePart end

            local distance = (humanoidRootPart.Position - movePart.Position).Magnitude
            if distance > 100 then return end

            if movePart.Anchored then movePart.Anchored = false end

            local collectPrompt = moneybag:WaitForChild("MoneyBag"):FindFirstChild("CollectPrompt")
            if collectPrompt and collectPrompt:IsA("ProximityPrompt") then
                collectPrompt.HoldDuration = -10
            end

            local targetPosition
            if pickUp then
                local moneybagSize = moneybag:GetExtentsSize()
                local maxDimension = math.max(moneybagSize.X, moneybagSize.Y, moneybagSize.Z)
                local promptDistance = maxDimension / 2 + 5
                local playerForward = humanoidRootPart.CFrame.LookVector
                targetPosition = humanoidRootPart.Position + (playerForward * promptDistance)
            else
                local offset = Vector3.new(5, 5, 5)
                targetPosition = humanoidRootPart.Position + offset
            end

            local tweenInfo = TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
            local goal = {CFrame = CFrame.new(targetPosition)}
            local tween = TweenService:Create(movePart, tweenInfo, goal)
            tween:Play()
            table.insert(tweens, {tween = tween, prompt = collectPrompt})
        end
    end

    task.wait(0.2)
    for _, data in pairs(tweens) do
        if data.prompt then
            fireproximityprompt(data.prompt)
        end
    end
end

-- GUI Setup
local screenGui = Instance.new("ScreenGui", CoreGui)
screenGui.Enabled = true

local distanceLabel = Instance.new("TextLabel", screenGui)
distanceLabel.Size = UDim2.new(0, 200, 0, 20)
distanceLabel.Position = UDim2.new(0, 10, 1, -70)
distanceLabel.BackgroundTransparency = 1
distanceLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
distanceLabel.Font = Enum.Font.GothamBold
distanceLabel.TextSize = 14
distanceLabel.TextXAlignment = Enum.TextXAlignment.Left
distanceLabel.TextStrokeTransparency = 0.5
distanceLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
distanceLabel.Text = "Distance: Checking..."

local timeLabel = Instance.new("TextLabel", screenGui)
timeLabel.Size = UDim2.new(0, 200, 0, 20)
timeLabel.Position = UDim2.new(0, 10, 1, -50)
timeLabel.BackgroundTransparency = 1
timeLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
timeLabel.Font = Enum.Font.GothamBold
timeLabel.TextSize = 14
timeLabel.TextXAlignment = Enum.TextXAlignment.Left
timeLabel.TextStrokeTransparency = 0.5
timeLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
timeLabel.Text = "Time: Checking..."

local fuelLabel = Instance.new("TextLabel", screenGui)
fuelLabel.Size = UDim2.new(0, 200, 0, 20)
fuelLabel.Position = UDim2.new(0, 10, 1, -30)
fuelLabel.BackgroundTransparency = 1
fuelLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
fuelLabel.Font = Enum.Font.GothamBold
fuelLabel.TextSize = 14
fuelLabel.TextXAlignment = Enum.TextXAlignment.Left
fuelLabel.TextStrokeTransparency = 0.5
fuelLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
fuelLabel.Text = "Fuel: Checking..."

local function updateTrainInfo()
    local train = Workspace:FindFirstChild("Train")
    if not train then
        distanceLabel.Text = "Distance: N/A"
        timeLabel.Text = "Time: N/A"
        fuelLabel.Text = "Fuel: N/A"
        return
    end

    local trainControls = train:FindFirstChild("TrainControls")
    local distanceDial = trainControls and trainControls:FindFirstChild("DistanceDial")
    local timeDial = trainControls and trainControls:FindFirstChild("TimeDial")
    local fuel = train:FindFirstChild("Fuel")

    if distanceDial then
        local distanceSurfaceGui = distanceDial:FindFirstChild("SurfaceGui")
        if distanceSurfaceGui then
            local distanceTextLabel = distanceSurfaceGui:FindFirstChild("TextLabel")
            if distanceTextLabel then
                distanceLabel.Text = "Distance: " .. distanceTextLabel.Text
            end
        end
    end

    if timeDial then
        local timeSurfaceGui = timeDial:FindFirstChild("SurfaceGui")
        if timeSurfaceGui then
            local timeTextLabel = timeSurfaceGui:FindFirstChild("TextLabel")
            if timeTextLabel then
                timeLabel.Text = "Time: " .. timeTextLabel.Text
            end
        end
    end

    if fuel then
        fuelLabel.Text = "Fuel: " .. tostring(fuel.Value) .. "/250"
    end
end

local frame = Instance.new("Frame", screenGui)
frame.Size = UDim2.new(0, 500, 0, 500)
frame.Position = UDim2.new(0.5, -250, 0.5, -200)
frame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
frame.BorderSizePixel = 0
frame.Visible = false
frame.BackgroundTransparency = 0.2

local uiCorner = Instance.new("UICorner", frame)
uiCorner.CornerRadius = UDim.new(0, 10)

local uiStroke = Instance.new("UIStroke", frame)
uiStroke.Thickness = 2
uiStroke.Color = Color3.fromRGB(100, 100, 100)
uiStroke.Transparency = 0.4

-- Tab System
local tabFrame = Instance.new("Frame", frame)
tabFrame.Size = UDim2.new(1, 0, 0, 40)
tabFrame.Position = UDim2.new(0, 0, 0, 0)
tabFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
tabFrame.BorderSizePixel = 0

local tabLayout = Instance.new("UIListLayout", tabFrame)
tabLayout.FillDirection = Enum.FillDirection.Horizontal
tabLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
tabLayout.VerticalAlignment = Enum.VerticalAlignment.Center
tabLayout.Padding = UDim.new(0, 5)

local contentFrame = Instance.new("Frame", frame)
contentFrame.Size = UDim2.new(1, 0, 1, -40)
contentFrame.Position = UDim2.new(0, 0, 0, 40)
contentFrame.BackgroundTransparency = 1

-- Tab Buttons
local function createTabButton(name)
    local button = Instance.new("TextButton", tabFrame)
    button.Size = UDim2.new(0, 100, 0, 30)
    button.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    button.Text = name
    button.TextColor3 = Color3.fromRGB(255, 255, 255)
    button.Font = Enum.Font.GothamBold
    button.TextSize = 14
    local corner = Instance.new("UICorner", button)
    corner.CornerRadius = UDim.new(0, 5)
    return button
end

local toggleTab = Instance.new("Frame", contentFrame)
toggleTab.Size = UDim2.new(1, 0, 1, 0)
toggleTab.BackgroundTransparency = 1
toggleTab.Visible = true

local colorTab = Instance.new("Frame", contentFrame)
colorTab.Size = UDim2.new(1, 0, 1, 0)
colorTab.BackgroundTransparency = 1
colorTab.Visible = false

local toggleTabButton = createTabButton("Toggles")
local colorTabButton = createTabButton("Color")

local function switchTab(tabToShow)
    toggleTab.Visible = (tabToShow == toggleTab)
    colorTab.Visible = (tabToShow == colorTab)
    toggleTabButton.BackgroundColor3 = (tabToShow == toggleTab) and Color3.fromRGB(70, 70, 70) or Color3.fromRGB(50, 50, 50)
    colorTabButton.BackgroundColor3 = (tabToShow == colorTab) and Color3.fromRGB(70, 70, 70) or Color3.fromRGB(50, 50, 50)
end

toggleTabButton.MouseButton1Click:Connect(function()
    switchTab(toggleTab)
end)

colorTabButton.MouseButton1Click:Connect(function()
    switchTab(colorTab)
end)

-- Toggle Tab Content
local toggleContent = Instance.new("Frame", toggleTab)
toggleContent.Size = UDim2.new(1, 0, 1, 0)
toggleContent.Position = UDim2.new(0, 0, 0, 0)
toggleContent.BackgroundTransparency = 1

local layout = Instance.new("UIGridLayout", toggleContent)
layout.CellSize = UDim2.new(0, 200, 0, 50)
layout.CellPadding = UDim2.new(0, 10, 0, 10)
layout.FillDirection = Enum.FillDirection.Vertical
layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
layout.VerticalAlignment = Enum.VerticalAlignment.Center

-- Color Tab Content
local colorContent = Instance.new("Frame", colorTab)
colorContent.Size = UDim2.new(1, 0, 1, 0)
colorContent.Position = UDim2.new(0, 0, 0, 0)
colorContent.BackgroundTransparency = 1

local colorLayout = Instance.new("UIListLayout", colorContent)
colorLayout.FillDirection = Enum.FillDirection.Vertical
colorLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
colorLayout.VerticalAlignment = Enum.VerticalAlignment.Top
colorLayout.Padding = UDim.new(0, 10)

-- Hàm chuyển đổi HSV sang RGB
local function hsvToRgb(h, s, v)
    local r, g, b
    local i = math.floor(h * 6)
    local f = h * 6 - i
    local p = v * (1 - s)
    local q = v * (1 - f * s)
    local t = v * (1 - (1 - f) * s)

    i = i % 6

    if i == 0 then r, g, b = v, t, p
    elseif i == 1 then r, g, b = q, v, p
    elseif i == 2 then r, g, b = p, v, t
    elseif i == 3 then r, g, b = p, q, v
    elseif i == 4 then r, g, b = t, p, v
    elseif i == 5 then r, g, b = v, p, q
    end

    return math.floor(r * 255), math.floor(g * 255), math.floor(b * 255)
end

-- Hàm chuyển đổi RGB sang HSV
local function rgbToHsv(r, g, b)
    r, g, b = r / 255, g / 255, b / 255
    local max, min = math.max(r, g, b), math.min(r, g, b)
    local h, s, v
    v = max

    local d = max - min
    s = max == 0 and 0 or d / max

    if max == min then
        h = 0
    else
        if max == r then
            h = (g - b) / d + (g < b and 6 or 0)
        elseif max == g then
            h = (b - r) / d + 2
        elseif max == b then
            h = (r - g) / d + 4
        end
        h = h / 6
    end

    return h, s, v
end

-- Danh sách các color picker
local colorPickers = {
    {espType = "ESPBuilding", labelText = "ESP Building Color"},
    {espType = "ESPItem", labelText = "ESP Item Color"},
    {espType = "ESPNPC", labelText = "ESP NPC Color (Animal)"},
    {espType = "ESPNPCSpecial", labelText = "ESP NPC Color (Special)"}
}

local currentPickerIndex = 1
local currentColorFrame = nil
local function createColorPicker(espType, labelText)
    local colorFrame = Instance.new("Frame", colorContent)
    colorFrame.Size = UDim2.new(0, 300, 0, 200)
    colorFrame.Position = UDim2.new(0, 0, 0, 0)
    colorFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    colorFrame.Active = true
    local uiCorner = Instance.new("UICorner", colorFrame)
    uiCorner.CornerRadius = UDim.new(0, 8)

    local label = Instance.new("TextLabel", colorFrame)
    label.Size = UDim2.new(1, 0, 0, 30)
    label.BackgroundTransparency = 1
    label.Text = labelText
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.Font = Enum.Font.GothamBold
    label.TextSize = 16

    local preview = Instance.new("Frame", colorFrame)
    preview.Size = UDim2.new(0, 50, 0, 50)
    preview.Position = UDim2.new(1, -60, 0, 10)
    preview.BackgroundColor3 = Color3.fromRGB(settings.colors[espType].R, settings.colors[espType].G, settings.colors[espType].B)
    local previewCorner = Instance.new("UICorner", preview)
    previewCorner.CornerRadius = UDim.new(0, 5)

    local colorBar = Instance.new("Frame", colorFrame)
    colorBar.Size = UDim2.new(1, -20, 0, 30)
    colorBar.Position = UDim2.new(0, 10, 0, 100)
    colorBar.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    colorBar.Active = true
    
    local gradient = Instance.new("UIGradient", colorBar)
    gradient.Color = ColorSequence.new {
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
        ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255, 165, 0)),
        ColorSequenceKeypoint.new(0.33, Color3.fromRGB(255, 255, 0)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 255, 0)),
        ColorSequenceKeypoint.new(0.67, Color3.fromRGB(0, 0, 255)),
        ColorSequenceKeypoint.new(0.83, Color3.fromRGB(75, 0, 130)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(238, 130, 238))
    }

    local selector = Instance.new("Frame", colorBar)
    selector.Size = UDim2.new(0, 10, 1, 0)
    selector.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    selector.Active = true
    local selectorCorner = Instance.new("UICorner", selector)
    selectorCorner.CornerRadius = UDim.new(1, 0)

    local function getColorAtPosition(position)
        local colors = {
            Color3.fromRGB(255, 0, 0),
            Color3.fromRGB(255, 165, 0),
            Color3.fromRGB(255, 255, 0),
            Color3.fromRGB(0, 255, 0),
            Color3.fromRGB(0, 0, 255),
            Color3.fromRGB(75, 0, 130),
            Color3.fromRGB(238, 130, 238)
        }
        
        local index = math.clamp(math.floor(position * (#colors - 1)) + 1, 1, #colors - 1)
        local t = (position * (#colors - 1)) % 1
        
        local color = colors[index]:Lerp(colors[index + 1], t)
        return {R = math.floor(color.R * 255), G = math.floor(color.G * 255), B = math.floor(color.B * 255)}
    end

    local isDraggingSelector = false

    local function updateSelectorPosition(input)
        local relativeX = math.clamp((input.Position.X - colorBar.AbsolutePosition.X) / colorBar.AbsoluteSize.X, 0, 1)
        selector.Position = UDim2.new(relativeX, -5, 0, 0)
        local selectedColor = getColorAtPosition(relativeX)
        preview.BackgroundColor3 = Color3.fromRGB(selectedColor.R, selectedColor.G, selectedColor.B)
        settings.colors[espType] = selectedColor
        saveSettings()
        if espType == "ESPNPC" or espType == "ESPNPCSpecial" then
            for object, hitbox in pairs(highlights) do
                if hitbox:IsA("BoxHandleAdornment") then
                    local espTypeForObject = (object.Name == "Horse" or object.Name == "Unicorn") and "animal" or "animal_special"
                    if (espType == "ESPNPC" and espTypeForObject == "animal") or 
                       (espType == "ESPNPCSpecial" and espTypeForObject == "animal_special") then
                        hitbox.Color3 = Color3.fromRGB(selectedColor.R, selectedColor.G, selectedColor.B)
                    end
                end
            end
            for object, billboard in pairs(nameTags) do
                local espTypeForObject = (object.Name == "Horse" or object.Name == "Unicorn") and "animal" or "animal_special"
                if (espType == "ESPNPC" and espTypeForObject == "animal") or 
                   (espType == "ESPNPCSpecial" and espTypeForObject == "animal_special") then
                    local nameLabel = billboard:FindFirstChild("NameLabel")
                    if nameLabel then
                        nameLabel.TextColor3 = Color3.fromRGB(selectedColor.R, selectedColor.G, selectedColor.B)
                        for _, child in pairs(billboard:GetChildren()) do
                            if child:IsA("TextLabel") and child ~= nameLabel then
                                child.TextColor3 = nameLabel.TextColor3
                            end
                        end
                    end
                end
            end
        end
    end

    selector.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            isDraggingSelector = true
            updateSelectorPosition(input)
        end
    end)

    colorBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            isDraggingSelector = true
            updateSelectorPosition(input)
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if isDraggingSelector and input.UserInputType == Enum.UserInputType.MouseMovement then
            updateSelectorPosition(input)
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            isDraggingSelector = false
        end
    end)

    local showButton = Instance.new("TextButton", colorFrame)
    showButton.Size = UDim2.new(0, 100, 0, 50)
    showButton.Position = UDim2.new(0, 10, 0, 140)
    showButton.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
    showButton.Text = "Show Colors"
    showButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    showButton.Font = Enum.Font.GothamBold
    showButton.TextSize = 14

    showButton.MouseButton1Click:Connect(function()
        colorBar.Visible = not colorBar.Visible
        selector.Visible = colorBar.Visible
    end)

    colorBar.Visible = false
    selector.Visible = false

    local function initializeSelectorPosition()
        local currentColor = Color3.fromRGB(settings.colors[espType].R, settings.colors[espType].G, settings.colors[espType].B)
        local closestPos = 0
        local minDiff = math.huge
        
        for i = 0, 100 do
            local pos = i / 100
            local testColor = getColorAtPosition(pos)
            local diff = math.abs(testColor.R - settings.colors[espType].R) +
                        math.abs(testColor.G - settings.colors[espType].G) +
                        math.abs(testColor.B - settings.colors[espType].B)
            if diff < minDiff then
                minDiff = diff
                closestPos = pos
            end
        end
        
        selector.Position = UDim2.new(closestPos, -5, 0, 0)
    end
    
    initializeSelectorPosition()

    return colorFrame
end

local function showColorPicker(index)
    if currentColorFrame then
        currentColorFrame:Destroy()
    end

    local pickerData = colorPickers[index]
    currentColorFrame = createColorPicker(pickerData.espType, pickerData.labelText)
    currentColorFrame.Visible = true

    if prevButton then
        prevButton.Visible = (index > 1)
    end
    if nextButton then
        nextButton.Visible = (index < #colorPickers)
    end
end

local prevButton = Instance.new("TextButton", colorContent)
prevButton.Size = UDim2.new(0, 40, 0, 40)
prevButton.Position = UDim2.new(0, 10, 0, 10)
prevButton.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
prevButton.Text = "<"
prevButton.TextColor3 = Color3.fromRGB(255, 255, 255)
prevButton.Font = Enum.Font.GothamBold
prevButton.TextSize = 20
local prevCorner = Instance.new("UICorner", prevButton)
prevCorner.CornerRadius = UDim.new(0, 5)

local nextButton = Instance.new("TextButton", colorContent)
nextButton.Size = UDim2.new(0, 40, 0, 40)
nextButton.Position = UDim2.new(1, -50, 0, 10)
nextButton.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
nextButton.Text = ">"
nextButton.TextColor3 = Color3.fromRGB(255, 255, 255)
nextButton.Font = Enum.Font.GothamBold
nextButton.TextSize = 20
local nextCorner = Instance.new("UICorner", nextButton)
nextCorner.CornerRadius = UDim.new(0, 5)

prevButton.MouseButton1Click:Connect(function()
    if currentPickerIndex > 1 then
        currentPickerIndex = currentPickerIndex - 1
        showColorPicker(currentPickerIndex)
    end
end)

nextButton.MouseButton1Click:Connect(function()
    if currentPickerIndex < #colorPickers then
        currentPickerIndex = currentPickerIndex + 1
        showColorPicker(currentPickerIndex)
    end
end)

showColorPicker(currentPickerIndex)

local menuButton = Instance.new("TextButton", screenGui)
menuButton.Size = UDim2.new(0, 50, 0, 50)
menuButton.Position = UDim2.new(0, 10, 0, 10)
menuButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
menuButton.Text = "Menu"
menuButton.TextColor3 = Color3.fromRGB(255, 255, 255)
menuButton.TextScaled = true
menuButton.Font = Enum.Font.GothamBold
menuButton.BackgroundTransparency = 0.2

local menuButtonCorner = Instance.new("UICorner")
menuButtonCorner.CornerRadius = UDim.new(0, 8)
menuButtonCorner.Parent = menuButton

menuButton.MouseButton1Click:Connect(function()
    menuVisible = not menuVisible
    if menuVisible then
        frame.Visible = true
        local tweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        local tween = TweenService:Create(frame, tweenInfo, {Position = UDim2.new(0.5, -250, 0.5, -250), BackgroundTransparency = 0.1})
        tween:Play()
    else
        local tweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
        local tween = TweenService:Create(frame, tweenInfo, {Position = UDim2.new(0.5, -250, 0.5, -300), BackgroundTransparency = 1})
        tween:Play()
        tween.Completed:Connect(function()
            frame.Visible = false
        end)
    end
end)

frame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = frame.Position
    end
end)

frame.InputChanged:Connect(function(input)
    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - dragStart
        frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, 
            startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

frame.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
    end
end)

-- Hàm hiển thị thông báo
local currentNotification = nil
local function showNotification(message, duration)
    if currentNotification then
        currentNotification:Destroy()
        currentNotification = nil
    end

    local notification = Instance.new("Frame", screenGui)
    notification.Size = UDim2.new(0, 250, 0, 60)
    notification.Position = UDim2.new(0.5, -125, 0, -60)
    notification.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    notification.BackgroundTransparency = 1

    local textLabel = Instance.new("TextLabel", notification)
    textLabel.Size = UDim2.new(1, 0, 1, 0)
    textLabel.BackgroundTransparency = 1
    textLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    textLabel.Text = message
    textLabel.TextScaled = true
    textLabel.Font = Enum.Font.GothamBold

    local tweenIn = TweenService:Create(notification, TweenInfo.new(0.5), {Position = UDim2.new(0.5, -125, 0, 20), BackgroundTransparency = 0.2})
    tweenIn:Play()
    task.delay(duration or 2, function()
        local tweenOut = TweenService:Create(notification, TweenInfo.new(0.5), {Position = UDim2.new(0.5, -125, 0, -60), BackgroundTransparency = 1})
        tweenOut:Play()
        tweenOut.Completed:Connect(function() notification:Destroy() end)
    end)
    currentNotification = notification
end

-- Hàm hỗ trợ NPC Lock
local toggleLoop
local lastTarget = nil

local function addPlayerHighlight()
    if player.Character then
        local highlight = player.Character:FindFirstChild("PlayerHighlightESP")
        if not highlight then
            highlight = Instance.new("Highlight")
            highlight.Name = "PlayerHighlightESP"
            highlight.FillColor = Color3.new(1, 1, 1)
            highlight.OutlineColor = Color3.new(1, 1, 1)
            highlight.FillTransparency = 0.5
            highlight.OutlineTransparency = 0
            highlight.Parent = player.Character
        end
    end
end

local function removePlayerHighlight()
    if player.Character and player.Character:FindFirstChild("PlayerHighlightESP") then
        player.Character.PlayerHighlightESP:Destroy()
    end
end

local function getClosestNPC()
    local closestNPC = nil
    local closestDistance = math.huge
    if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then
        return nil
    end
    for _, object in ipairs(Workspace:GetDescendants()) do
        if object:IsA("Model") then
            local humanoid = object:FindFirstChild("Humanoid") or object:FindFirstChildWhichIsA("Humanoid")
            local hrp = object:FindFirstChild("HumanoidRootPart") or object.PrimaryPart
            if humanoid and hrp and humanoid.Health > 0 and object.Name ~= "Horse" then
                local isPlayer = Players:GetPlayerFromCharacter(object)
                if not isPlayer then
                    local distance = (player.Character.HumanoidRootPart.Position - hrp.Position).Magnitude
                    if distance < closestDistance then
                        closestDistance = distance
                        closestNPC = object
                    end
                end
            end
        end
    end
    return closestNPC
end

local function autoTeleportLoop()
    while autoTeleportAmmo do
        teleportAmmo()
        task.wait(0.5)
    end
    autoTeleportRunning = false
end

-- Tối ưu FullBright
local defaultLightingState = {
    Brightness = Lighting.Brightness,
    ClockTime = Lighting.ClockTime,
    FogEnd = Lighting.FogEnd,
    GlobalShadows = Lighting.GlobalShadows
}

local function applyFullBright()
    Lighting.Brightness = 2
    Lighting.ClockTime = 14
    Lighting.FogEnd = 100000
    Lighting.GlobalShadows = false
end

local function applyDefaultLighting()
    Lighting.Brightness = defaultLightingState.Brightness
    Lighting.ClockTime = defaultLightingState.ClockTime
    Lighting.FogEnd = defaultLightingState.FogEnd
    Lighting.GlobalShadows = defaultLightingState.GlobalShadows
end

local function setupFullBrightMonitor()
    local connections = {}
    
    local function monitorProperty(property)
        local conn = Lighting:GetPropertyChangedSignal(property):Connect(function()
            if fullBright then
                applyFullBright()
            end
        end)
        table.insert(connections, conn)
    end
    
    monitorProperty("Brightness")
    monitorProperty("ClockTime")
    monitorProperty("FogEnd")
    monitorProperty("GlobalShadows")
    
    return function()
        for _, conn in pairs(connections) do
            conn:Disconnect()
        end
    end
end

local fullBrightMonitorDisconnect = nil

local function toggleFullBright(state)
    fullBright = state
    if state then
        applyFullBright()
        if not fullBrightMonitorDisconnect then
            fullBrightMonitorDisconnect = setupFullBrightMonitor()
        end
    else
        applyDefaultLighting()
        if fullBrightMonitorDisconnect then
            fullBrightMonitorDisconnect()
            fullBrightMonitorDisconnect = nil
        end
    end
    showNotification("Full Bright " .. (fullBright and "BẬT" or "TẮT"), 1.5)
end

-- InfJump
local function ToggleInfJump()
    if InfJump then
        if InfJumpConnection then InfJumpConnection:Disconnect() end
        InfJumpConnection = UserInputService.JumpRequest:Connect(function()
            local character = player.Character
            local humanoid = character and character:FindFirstChildWhichIsA("Humanoid")
            if humanoid and humanoid.Health > 0 then
                humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
            end
        end)
    else
        if InfJumpConnection then
            InfJumpConnection:Disconnect()
            InfJumpConnection = nil
        end
    end
    showNotification("Nhảy vô hạn " .. (InfJump and "BẬT" or "TẮT"), 1.5)
end

-- ESP Functions
local function removeESP(object)
    if nameTags[object] then
        nameTags[object]:Destroy()
        nameTags[object] = nil
    end
    if highlights[object] and typeof(highlights[object]) == "Instance" then
        highlights[object]:Destroy()
    end
    highlights[object] = nil
    if buildingESP[object] then
        buildingESP[object] = nil
    end
end

local function clearAllESP()
    for object in pairs(nameTags) do
        removeESP(object)
    end
    table.clear(buildingESP)
    table.clear(highlights)
end

local function updateESP(object, customName, distance, espType)
    local textSize = math.clamp(30 - (distance * 0.05), 10, 30)
    local targetPart = object:IsA("Model") and (object.PrimaryPart or object:FindFirstChildWhichIsA("BasePart")) or object
    if not targetPart then return end

    local billboard = nameTags[object]
    if not billboard then
        billboard = Instance.new("BillboardGui")
        billboard.Parent = CoreGui
        billboard.Adornee = targetPart
        billboard.Size = UDim2.new(0, 200, 0, 100)
        local height = object:IsA("BasePart") and object.Size.Y or object:GetExtentsSize().Y
        billboard.StudsOffset = Vector3.new(0, height / 2 + 5, 0)
        billboard.AlwaysOnTop = true
        nameTags[object] = billboard

        local nameLabel = Instance.new("TextLabel")
        nameLabel.Parent = billboard
        nameLabel.Size = UDim2.new(1, 0, 0.4, 0)
        nameLabel.BackgroundTransparency = 1
        nameLabel.TextStrokeTransparency = 0
        nameLabel.TextScaled = true
        nameLabel.Font = Enum.Font.SourceSansBold
        nameLabel.Name = "NameLabel"
        nameLabel.ZIndex = 10
    end

    local nameLabel = billboard:FindFirstChild("NameLabel")
    if nameLabel then
        local lines = {}
        for line in customName:gmatch("[^\n]+") do
            table.insert(lines, line)
        end
        
        nameLabel.Text = lines[1] or ""
        nameLabel.TextSize = textSize
        
        for _, child in pairs(billboard:GetChildren()) do
            if child.Name ~= "NameLabel" and child:IsA("TextLabel") then
                child:Destroy()
            end
        end

        for i, line in ipairs(lines) do
            if i > 1 then
                local extraLabel = Instance.new("TextLabel")
                extraLabel.Parent = billboard
                extraLabel.Size = UDim2.new(1, 0, 0.2, 0)
                extraLabel.Position = UDim2.new(0, 0, 0.4 + (i-2) * 0.2, 0)
                extraLabel.BackgroundTransparency = 1
                extraLabel.TextStrokeTransparency = 0
                extraLabel.TextScaled = true
                extraLabel.Font = Enum.Font.SourceSansBold
                extraLabel.Text = line
                extraLabel.TextSize = textSize * 0.7
                extraLabel.TextColor3 = nameLabel.TextColor3
                extraLabel.ZIndex = 10
            end
        end

        if espType == "building" then
            nameLabel.TextColor3 = Color3.fromRGB(settings.colors.ESPBuilding.R, settings.colors.ESPBuilding.G, settings.colors.ESPBuilding.B)
            if string.find(customName, "Vault") then
                textSize = math.clamp(textSize * 0.6, 8, 20)
                nameLabel.TextSize = textSize
            end
        elseif espType == "item" then
            nameLabel.TextColor3 = Color3.fromRGB(settings.colors.ESPItem.R, settings.colors.ESPItem.G, settings.colors.ESPItem.B)
        elseif espType == "animal" then
            nameLabel.TextColor3 = Color3.fromRGB(settings.colors.ESPNPC.R, settings.colors.ESPNPC.G, settings.colors.ESPNPC.B)
        elseif espType == "animal_special" then
            nameLabel.TextColor3 = Color3.fromRGB(settings.colors.ESPNPCSpecial.R, settings.colors.ESPNPCSpecial.G, settings.colors.ESPNPCSpecial.B)
        end
    end

    if espType == "item" then
        if not highlights[object] then
            local highlight = Instance.new("Highlight")
            highlight.Parent = object
            highlight.Adornee = object
            highlight.FillColor = Color3.fromRGB(settings.colors.ESPItem.R, settings.colors.ESPItem.G, settings.colors.ESPItem.B)
            highlight.OutlineColor = Color3.fromRGB(settings.colors.ESPItem.R, settings.colors.ESPItem.G, settings.colors.ESPItem.B)
            highlight.FillTransparency = 0.5
            highlight.OutlineTransparency = 0
            highlights[object] = highlight
        else
            local highlight = highlights[object]
            highlight.FillColor = Color3.fromRGB(settings.colors.ESPItem.R, settings.colors.ESPItem.G, settings.colors.ESPItem.B)
            highlight.OutlineColor = Color3.fromRGB(settings.colors.ESPItem.R, settings.colors.ESPItem.G, settings.colors.ESPItem.B)
        end
    elseif espType == "animal" or espType == "animal_special" then
        if not highlights[object] then
            local hitbox = Instance.new("BoxHandleAdornment")
            hitbox.Adornee = object
            hitbox.Parent = CoreGui
            hitbox.Size = Vector3.new(10, 10, 10)
            hitbox.Color3 = (espType == "animal") and 
                Color3.fromRGB(settings.colors.ESPNPC.R, settings.colors.ESPNPC.G, settings.colors.ESPNPC.B) or 
                Color3.fromRGB(settings.colors.ESPNPCSpecial.R, settings.colors.ESPNPCSpecial.G, settings.colors.ESPNPCSpecial.B)
            hitbox.Transparency = 0.9
            highlights[object] = hitbox
        else
            local hitbox = highlights[object]
            hitbox.Color3 = (espType == "animal") and 
                Color3.fromRGB(settings.colors.ESPNPC.R, settings.colors.ESPNPC.G, settings.colors.ESPNPC.B) or 
                Color3.fromRGB(settings.colors.ESPNPCSpecial.R, settings.colors.ESPNPCSpecial.G, settings.colors.ESPNPCSpecial.B)
        end
    end

    if espType == "building" then
        buildingESP[object] = true
    end
end

local function updateLoop()
    while true do
        if not humanoidRootPart or not humanoidRootPart.Parent then
            character = player.Character or player.CharacterAdded:Wait()
            humanoidRootPart = character:WaitForChild("HumanoidRootPart")
        end

        local processedObjects = {}
        local success, err = pcall(function()
            if espNPC then
                for _, npc in pairs(Workspace:GetDescendants()) do
                    local rootPart = npc:FindFirstChild("HumanoidRootPart")
                    local hum = npc:FindFirstChild("Humanoid")
                    if rootPart and hum and hum.Health > 0 then
                        local isPlayer = Players:GetPlayerFromCharacter(npc)
                        if not isPlayer then
                            local distance = (humanoidRootPart.Position - rootPart.Position).Magnitude
                            if distance <= maxDistance then
                                local maxHealth = hum.MaxHealth or 100
                                local espType = (npc.Name == "Horse" or npc.Name == "Unicorn") and "animal" or "animal_special"
                                updateESP(npc, string.format("%s (%d m) [%d/%d]", npc.Name, math.floor(distance), hum.Health, maxHealth), distance, espType)
                                processedObjects[npc] = true
                            end
                        end
                    end
                end
            end

            if espBuilding then
                local buildings = Workspace:FindFirstChild("RandomBuildings")
                if buildings then
                    for _, building in pairs(buildings:GetChildren()) do
                        if building:IsA("Model") or building:IsA("BasePart") then
                            local targetPart = building:IsA("Model") and building:FindFirstChildWhichIsA("BasePart") or (building:IsA("BasePart") and building or nil)
                            if targetPart and targetPart.Position then
                                local distance = (humanoidRootPart.Position - targetPart.Position).Magnitude
                                if distance <= maxDistance then
                                    updateESP(building, string.format("%s (%d m)", building.Name, math.floor(distance)), distance, "building")
                                    processedObjects[building] = true
                                end
                            end
                        end
                    end
                end

                local specialBuildings = {Workspace:FindFirstChild("TeslaLab"), Workspace:FindFirstChild("Train")}
                for _, building in pairs(specialBuildings) do
                    if building then
                        local targetPart = building:IsA("Model") and (building.PrimaryPart or building:FindFirstChildWhichIsA("BasePart")) or building
                        if targetPart and targetPart:IsA("BasePart") then
                            local distance = (targetPart.Position - humanoidRootPart.Position).Magnitude
                            if distance <= maxDistance then
                                updateESP(building, string.format("%s (%d m)", building.Name, math.floor(distance)), distance, "building")
                                processedObjects[building] = true
                            end
                        end
                    end
                end

                local towns = Workspace:FindFirstChild("Towns")
                if towns then
                    for _, town in pairs(towns:GetChildren()) do
                        local buildingsFolder = town:FindFirstChild("Buildings")
                        if buildingsFolder then
                            for _, bank in pairs(buildingsFolder:GetChildren()) do
                                if bank.Name == "Bank" then
                                    local targetPart = bank:IsA("Model") and bank:FindFirstChildWhichIsA("BasePart") or (bank:IsA("BasePart") and bank or nil)
                                    if targetPart and targetPart.Position then
                                        local distance = (humanoidRootPart.Position - targetPart.Position).Magnitude
                                        if distance <= maxDistance then
                                            updateESP(bank, string.format("Bank (%d m)", math.floor(distance)), distance, "building")
                                            processedObjects[bank] = true

                                            local vault = bank:FindFirstChild("Vault")
                                            if vault then
                                                local combination = vault:FindFirstChild("Combination")
                                                local vaultPart = vault.PrimaryPart or vault:FindFirstChildWhichIsA("BasePart")
                                                if vaultPart then
                                                    local vaultDistance = (humanoidRootPart.Position - vaultPart.Position).Magnitude
                                                    if vaultDistance <= maxDistance then
                                                        local combinationText = "N/A"
                                                        if combination then
                                                            if combination:IsA("IntValue") then
                                                                combinationText = tostring(combination.Value)
                                                            elseif combination:IsA("StringValue") then
                                                                combinationText = combination.Value
                                                            elseif combination:FindFirstChildOfClass("TextLabel") then
                                                                local textLabel = combination:FindFirstChildOfClass("TextLabel")
                                                                combinationText = textLabel and textLabel.Text or "N/A"
                                                            end
                                                        end
                                                        updateESP(vault, string.format("Vault (%d m) Code: %s", math.floor(vaultDistance), combinationText), vaultDistance, "building")
                                                        processedObjects[vault] = true
                                                    end
                                                end
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            else
                for object in pairs(buildingESP) do
                    removeESP(object)
                end
            end

            if espItem then
                local items = Workspace:FindFirstChild("RuntimeItems")
                if items then
                    for _, object in pairs(items:GetChildren()) do
                        if object.Name ~= "Horse" and object.Name ~= "Banker" then
                            local targetPart = object:IsA("Model") and (object.PrimaryPart or object:FindFirstChildWhichIsA("BasePart")) or object:IsA("BasePart") and object
                            if targetPart then
                                local distance = (humanoidRootPart.Position - targetPart.Position).Magnitude
                                if distance <= maxDistance then
                                    local displayText = object.Name
                                    local additionalLines = {}
                                    
                                    local objectInfo = object:FindFirstChild("ObjectInfo")
                                    if objectInfo then
                                        local textLabels = objectInfo:GetChildren()
                                        local hasTextLabel = false
                                        for _, textLabel in pairs(textLabels) do
                                            if textLabel:IsA("TextLabel") and textLabel.Text ~= "" then
                                                if not hasTextLabel then
                                                    displayText = textLabel.Text
                                                    hasTextLabel = true
                                                else
                                                    table.insert(additionalLines, textLabel.Text)
                                                end
                                            end
                                        end
                                    end
                                    
                                    displayText = string.format("%s (%d m)", displayText, math.floor(distance))
                                    if #additionalLines > 0 then
                                        displayText = displayText .. "\n" .. table.concat(additionalLines, "\n")
                                    end
                                    
                                    updateESP(object, displayText, distance, "item")
                                    processedObjects[object] = true
                                end
                            end
                        end
                    end
                end
            end
        end)

        for object in pairs(nameTags) do
            if not processedObjects[object] or not object.Parent then
                removeESP(object)
            end
        end

        wait(0.1)
    end
end

-- Instant Prompts
local function applyInstantPrompts(enable)
    for _, prompt in pairs(game:GetDescendants()) do
        if prompt:IsA("ProximityPrompt") then
            if enable then
                prompt.HoldDuration = 0
            else
                local originalDuration = prompt:GetAttribute("OriginalHoldDuration") or 1.0
                prompt.HoldDuration = originalDuration
            end
        end
    end
end

local function promptLoop()
    while instantPrompts and promptLoopRunning do
        applyInstantPrompts(true)
        task.wait(0.1)
    end
    promptLoopRunning = false
end

player.CharacterAdded:Connect(function(newCharacter)
    character = newCharacter
    humanoidRootPart = newCharacter:WaitForChild("HumanoidRootPart")
    if noclipOn then
        for _, child in pairs(newCharacter:GetDescendants()) do
            if child:IsA("BasePart") and child.Name ~= floatName then
                child.CanCollide = false
            end
        end
    end
end)

-- Auto Drive
local autoDriveFunction = function()
    local train = Workspace:FindFirstChild("Train")
    local trainControls = train and train:FindFirstChild("TrainControls")
    local conductorSeat = trainControls and trainControls:FindFirstChild("ConductorSeat")
    local seat = conductorSeat and conductorSeat:FindFirstChildOfClass("VehicleSeat")
    local heartbeatConnection

    local function updateThrottle()
        if not seat or not seat:IsDescendantOf(Workspace) then
            return false
        end
        if seat.Occupant then
            seat.Throttle = 1
            seat.ThrottleFloat = 1
        else
            seat.Throttle = 0
            seat.ThrottleFloat = 0
        end
        return true
    end

    local function startAutoDrive()
        if not seat then
            showNotification("Không tìm thấy ghế điều khiển tàu!", 2)
            autoDrive = false
            autoDriveRunning = false
            return
        end

        if not autoDriveRunning then
            autoDriveRunning = true
            heartbeatConnection = RunService.Heartbeat:Connect(function()
                if autoDrive then
                    if not updateThrottle() then
                        showNotification("Ghế điều khiển tàu không còn tồn tại!", 2)
                        autoDrive = false
                        autoDriveRunning = false
                        if heartbeatConnection then
                            heartbeatConnection:Disconnect()
                            heartbeatConnection = nil
                        end
                    end
                else
                    autoDriveRunning = false
                    if heartbeatConnection then
                        heartbeatConnection:Disconnect()
                        heartbeatConnection = nil
                    end
                    if seat then
                        seat.Throttle = -1
                        seat.ThrottleFloat = -1
                    end
                end
            end)
        end
    end

    local function stopAutoDrive()
        autoDrive = false
        if heartbeatConnection then
            heartbeatConnection:Disconnect()
            heartbeatConnection = nil
        end
        autoDriveRunning = false
        if seat then
            seat.Throttle = -1
            seat.ThrottleFloat = -1
        end
    end

    return {
        start = startAutoDrive,
        stop = stopAutoDrive
    }
end

local autoDriveInstance = autoDriveFunction()

-- Hàm tạo nút kết hợp Toggle và Keybind
local function createCombinedButton(name, toggleFunc)
    local buttonFrame = Instance.new("Frame", toggleContent)
    buttonFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)

    local uiCorner = Instance.new("UICorner", buttonFrame)
    uiCorner.CornerRadius = UDim.new(0, 8)

    local toggleButton = Instance.new("TextButton", buttonFrame)
    toggleButton.Size = UDim2.new(0.6, 0, 1, 0)
    toggleButton.Position = UDim2.new(0, 0, 0, 0)
    toggleButton.BackgroundTransparency = 1
    toggleButton.Text = name .. ": " .. (settings.toggles[name] and "BẬT" or "TẮT")
    toggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    toggleButton.Font = Enum.Font.GothamBold
    toggleButton.TextSize = 14

    local keybindButton = Instance.new("TextButton", buttonFrame)
    keybindButton.Size = UDim2.new(0.4, 0, 1, 0)
    keybindButton.Position = UDim2.new(0.6, 0, 0, 0)
    keybindButton.BackgroundTransparency = 1
    keybindButton.Text = settings.keybinds[name] and settings.keybinds[name].Name or "Không"
    keybindButton.TextColor3 = Color3.fromRGB(200, 200, 200)
    keybindButton.Font = Enum.Font.GothamBold
    keybindButton.TextSize = 12

    local function updateToggleState()
        toggleButton.Text = name .. ": " .. (settings.toggles[name] and "BẬT" or "TẮT")
        buttonFrame.BackgroundColor3 = settings.toggles[name] and Color3.fromRGB(0, 150, 50) or Color3.fromRGB(50, 50, 50)
        saveSettings()
    end

    toggleButton.MouseButton1Click:Connect(function()
        settings.toggles[name] = not settings.toggles[name]
        updateToggleState()
        toggleFunc(settings.toggles[name])
        showNotification(name .. " " .. (settings.toggles[name] and "BẬT" or "TẮT"), 1.5)
    end)

    local waitingForInput = false
    keybindButton.MouseButton1Click:Connect(function()
        if not waitingForInput then
            waitingForInput = true
            keybindButton.Text = "Nhấn phím..."
            local connection
            connection = UserInputService.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.Keyboard then
                    if input.KeyCode == Enum.KeyCode.Escape then
                        settings.keybinds[name] = nil
                        keybindButton.Text = "Không"
                    else
                        settings.keybinds[name] = input.KeyCode
                        keybindButton.Text = input.KeyCode.Name
                    end
                    waitingForInput = false
                    connection:Disconnect()
                    saveSettings()
                end
            end)
        end
    end)

    UserInputService.InputBegan:Connect(function(input)
        if not waitingForInput and input.KeyCode == settings.keybinds[name] then
            settings.toggles[name] = not settings.toggles[name]
            updateToggleState()
            toggleFunc(settings.toggles[name])
            showNotification(name .. " " .. (settings.toggles[name] and "BẬT" or "TẮT"), 1.5)
        end
    end)

    updateToggleState()
    return buttonFrame
end

-- Tạo các nút với chức năng tương ứng
createCombinedButton("ESPBuilding", function(state) espBuilding = state end)
createCombinedButton("ESPItem", function(state) espItem = state end)
createCombinedButton("ESPNPC", function(state) espNPC = state end)
createCombinedButton("AutoMoneybag", function(state)
    autoMoneybag = state
    if state and not moneybagLoopRunning then
        moneybagLoopRunning = true
        task.spawn(function()
            while autoMoneybag do
                handleMoneybag(true)
                wait(1)
            end
            moneybagLoopRunning = false
        end)
    end
end)
createCombinedButton("NPCLock", function(state)
    npcLock = state
    if state then
        if toggleLoop then toggleLoop:Disconnect() end
        toggleLoop = RunService.RenderStepped:Connect(function()
            if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then
                character = player.Character or player.CharacterAdded:Wait()
                humanoidRootPart = character:WaitForChild("HumanoidRootPart")
                return
            end
            local npc = getClosestNPC()
            if npc and npc:FindFirstChild("Humanoid") then
                local npcHumanoid = npc:FindFirstChild("Humanoid")
                if npcHumanoid.Health > 0 then
                    camera.CameraSubject = npcHumanoid
                    lastTarget = npc
                    addPlayerHighlight()
                else
                    StarterGui:SetCore("SendNotification", {Title = "Đã hạ NPC", Text = npc.Name, Duration = 0.4})
                    lastTarget = nil
                    removePlayerHighlight()
                    if player.Character and player.Character:FindFirstChild("Humanoid") then
                        camera.CameraSubject = player.Character:FindFirstChild("Humanoid")
                    end
                end
            else
                if player.Character and player.Character:FindFirstChild("Humanoid") then
                    camera.CameraSubject = player.Character:FindFirstChild("Humanoid")
                end
                lastTarget = nil
                removePlayerHighlight()
            end
        end)
    else
        if toggleLoop then
            toggleLoop:Disconnect()
            toggleLoop = nil
        end
        removePlayerHighlight()
        if player.Character and player.Character:FindFirstChild("Humanoid") then
            camera.CameraSubject = player.Character:FindFirstChild("Humanoid")
        end
    end
end)
createCombinedButton("TeleportAmmo", function(state)
    autoTeleportAmmo = state
    if state and not autoTeleportRunning then
        autoTeleportRunning = true
        task.spawn(autoTeleportLoop)
    end
end)
createCombinedButton("FullBright", toggleFullBright)
createCombinedButton("AutoLoot", function(state)
    autoLoot = state
    if state and not autoLootRunning then
        autoLootRunning = true
        task.spawn(function()
            while autoLoot do
                findAndLootItems({"Snake Oil", "Bandage", "Holy Water"}, "Model", 50)
                wait(1)
            end
            autoLootRunning = false
        end)
    end
end)
createCombinedButton("Noclip", function(state)
    noclipOn = state
    ToggleNoclip()
    showNotification("Noclip " .. (noclipOn and "BẬT" or "TẮT"), 1.5)
end)
createCombinedButton("InfJump", function(state)
    InfJump = state
    ToggleInfJump()
end)
createCombinedButton("InstantPrompts", function(state)
    instantPrompts = state
    if state then
        applyInstantPrompts(true)
        if not promptLoopRunning then
            promptLoopRunning = true
            task.spawn(promptLoop)
        end
    else
        applyInstantPrompts(false)
        promptLoopRunning = false
    end
end)
createCombinedButton("AutoDrive", function(state)
    autoDrive = state
    if state then
        if not Workspace:FindFirstChild("Train") then
            showNotification("Không tìm thấy tàu!", 2)
            autoDrive = false
            return
        end
        autoDriveInstance.start()
        showNotification("Auto Drive BẬT", 1.5)
    else
        autoDriveInstance.stop()
        showNotification("Auto Drive TẮT", 1.5)
    end
end)
createCombinedButton("AutoWin", function(state)
    if state then
        task.spawn(function()
            main()
            showNotification("AutoWin BẬT", 1.5)
        end)
    else
        showNotification("AutoWin TẮT", 1.5)
    end
end)
createCombinedButton("PromptsFar", function(state)
    promptsFar = state
    settings.toggles.PromptsFar = state  -- Đồng bộ với settings
    if state then
        applyFarPrompts(true)
        if not promptsFarLoopRunning then
            promptsFarLoopRunning = true
            task.spawn(promptsFarLoop)
        end
        showNotification("Prompts xa hơn BẬT", 1.5)
    else
        applyFarPrompts(false)
        promptsFarLoopRunning = false
        showNotification("Prompts xa hơn TẮT", 1.5)
    end
    saveSettings()  -- Lưu trạng thái
end)
UserInputService.InputBegan:Connect(function(input)
    if input.KeyCode == settings.keybinds.AutoWin then
        task.spawn(function()
            main()
            showNotification("AutoWin đã được kích hoạt!", 1.5)
        end)
    end
end)
-- Khởi tạo các trạng thái ban đầu từ cài đặt
for toggleName, state in pairs(settings.toggles) do
    if state then
        if toggleName == "ESPBuilding" then
            espBuilding = true
        elseif toggleName == "ESPItem" then
            espItem = true
        elseif toggleName == "ESPNPC" then
            espNPC = true
        elseif toggleName == "AutoMoneybag" then
            autoMoneybag = true
            if not moneybagLoopRunning then
                moneybagLoopRunning = true
                task.spawn(function()
                    while autoMoneybag do
                        handleMoneybag(true)
                        wait(1)
                    end
                    moneybagLoopRunning = false
                end)
            end
        elseif toggleName == "NPCLock" then
            npcLock = true
            if toggleLoop then toggleLoop:Disconnect() end
            toggleLoop = RunService.RenderStepped:Connect(function()
                if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then
                    character = player.Character or player.CharacterAdded:Wait()
                    humanoidRootPart = character:WaitForChild("HumanoidRootPart")
                    return
                end
                local npc = getClosestNPC()
                if npc and npc:FindFirstChild("Humanoid") then
                    local npcHumanoid = npc:FindFirstChild("Humanoid")
                    if npcHumanoid.Health > 0 then
                        camera.CameraSubject = npcHumanoid
                        lastTarget = npc
                        addPlayerHighlight()
                    else
                        StarterGui:SetCore("SendNotification", {Title = "Đã hạ NPC", Text = npc.Name, Duration = 0.4})
                        lastTarget = nil
                        removePlayerHighlight()
                        if player.Character and player.Character:FindFirstChild("Humanoid") then
                            camera.CameraSubject = player.Character:FindFirstChild("Humanoid")
                        end
                    end
                else
                    if player.Character and player.Character:FindFirstChild("Humanoid") then
                        camera.CameraSubject = player.Character:FindFirstChild("Humanoid")
                    end
                    lastTarget = nil
                    removePlayerHighlight()
                end
            end)
        elseif toggleName == "TeleportAmmo" then
            autoTeleportAmmo = true
            if not autoTeleportRunning then
                autoTeleportRunning = true
                task.spawn(autoTeleportLoop)
            end
        elseif toggleName == "FullBright" then
            toggleFullBright(true)
        elseif toggleName == "AutoLoot" then
            autoLoot = true
            if not autoLootRunning then
                autoLootRunning = true
                task.spawn(function()
                    while autoLoot do
                        findAndLootItems({"Snake Oil", "Bandage", "Holy Water"}, "Model", 50)
                        wait(1)
                    end
                    autoLootRunning = false
                end)
            end
        elseif toggleName == "Noclip" then
            noclipOn = true
            ToggleNoclip()
        elseif toggleName == "InfJump" then
            InfJump = true
            ToggleInfJump()
        elseif toggleName == "InstantPrompts" then
            instantPrompts = true
            applyInstantPrompts(true)
            if not promptLoopRunning then
                promptLoopRunning = true
                task.spawn(promptLoop)
            end
        elseif toggleName == "AutoDrive" then
            autoDrive = true
            autoDriveInstance.start()
        elseif toggleName == "PromptsFar" then  -- Thêm khởi tạo PromptsFar
            promptsFar = true
            applyFarPrompts(true)
            if not promptsFarLoopRunning then
                promptsFarLoopRunning = true
                task.spawn(promptsFarLoop)
            end
        end
    end
end

task.spawn(function()
    while true do
        if player.CameraMode ~= Enum.CameraMode.Classic then
            player.CameraMode = Enum.CameraMode.Classic
        end
        if player.CameraMaxZoomDistance ~= 240 then
            player.CameraMaxZoomDistance = 240
        end
        if player.CameraMinZoomDistance ~= 0 then
            player.CameraMinZoomDistance = 0
        end
        task.wait(0.1)
    end
end)
task.spawn(function()
    while true do
        updateTrainInfo()
        wait(0.5)
    end
end)

-- Vòng lặp cập nhật ESP
task.spawn(updateLoop)

-- Thông báo khởi động script
showNotification("Script đã khởi động thành công!", 3)
