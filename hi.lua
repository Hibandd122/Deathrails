-- Khai báo các dịch vụ của Roblox
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
local playerGui = player:WaitForChild("PlayerGui")

-- Biến toàn cục
local noclipOn = true
local promptsFar = true
local floatName = "HumanoidRootPart"
local farPromptDistance = 100
local defaultPromptDistance = 100

-- Hàm lấy giá trị TextLabel (thời gian)
local function getTextLabelValue()
    local success, result = pcall(function()
        local textLabel = Workspace.Baseplates.FinalBasePlate.OutlawBase.Bridge.BridgeControl.Part.BillboardGui.TextLabel
        return textLabel.Text
    end)
    if success then
        return result
    else
        return "Không tìm thấy TextLabel: " .. result
    end
end

-- Tạo ScreenGui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "FullScreenDisplay"
screenGui.Parent = playerGui
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true

-- Tạo Frame trắng full màn hình
local frame = Instance.new("Frame")
frame.Size = UDim2.new(1, 0, 1, 0)
frame.Position = UDim2.new(0, 0, 0, 0)
frame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
frame.Parent = screenGui
frame.Visible = true -- Mặc định hiển thị

-- Tạo TextLabel ở giữa
local textLabel = Instance.new("TextLabel")
textLabel.Size = UDim2.new(0.5, 0, 0.2, 0)
textLabel.Position = UDim2.new(0.25, 0, 0.4, 0)
textLabel.BackgroundTransparency = 1
textLabel.TextColor3 = Color3.fromRGB(0, 0, 0)
textLabel.TextScaled = true
textLabel.Font = Enum.Font.SourceSansBold
textLabel.Text = "Loading..."
textLabel.Parent = frame

-- Tạo nút bật/tắt
local toggleButton = Instance.new("TextButton")
toggleButton.Size = UDim2.new(0.1, 0, 0.05, 0)
toggleButton.Position = UDim2.new(0.88, 0, 0.02, 0)
toggleButton.BackgroundColor3 = Color3.fromRGB(200, 200, 200)
toggleButton.TextColor3 = Color3.fromRGB(0, 0, 0)
toggleButton.Text = "Ẩn" -- Mặc định là "Ẩn" vì Frame đang hiện
toggleButton.TextScaled = true
toggleButton.Parent = screenGui
toggleButton.ZIndex = 2

-- Biến kiểm soát trạng thái
local isVisible = true
local isRunning = true

-- Hàm cập nhật thời gian liên tục
local function updateDisplay()
    while isRunning do
        if isVisible then
            local timeValue = getTextLabelValue()
            if timeValue == "5:00" then
                textLabel.Text = "Đợi (5:00)"
            else
                textLabel.Text = "Thời gian: " .. timeValue
            end
        end
        task.wait(0.05) -- Cập nhật nhanh hơn (mỗi 0.05 giây) để theo dõi thời gian mượt mà
    end
end

-- Xử lý nút bật/tắt
toggleButton.MouseButton1Click:Connect(function()
    isVisible = not isVisible
    frame.Visible = isVisible
    toggleButton.Text = isVisible and "Ẩn" or "Hiện"
end)

-- Hàm bật Noclip
local noclipConnection
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

-- Hàm dịch chuyển đến điểm cuối
local function teleportToEnd()
    local character = player.Character
    local rootPart = character and character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return end
    rootPart.CFrame = CFrame.new(-2047.5, -80, -49429, 1, 0, 0, 0, 1, 0, 0, 0, 1)
    wait(0.5)
    rootPart.CFrame = CFrame.new(0.5, -80, -49429, 1, 0, 0, 0, 1, 0, 0, 0, 1)
    wait(0.1)
end

-- Hàm kiểm tra xem người chơi có trên BridgeHalf không
local function isPlayerOnBridge()
    local character = player.Character
    local rootPart = character and character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return false end

    local playerPos = rootPart.Position
    local bridgeHalf = Workspace:FindFirstChild("Baseplates")
        and Workspace.Baseplates:FindFirstChild("FinalBasePlate")
        and Workspace.Baseplates.FinalBasePlate:FindFirstChild("OutlawBase")
        and Workspace.Baseplates.FinalBasePlate.OutlawBase:FindFirstChild("Bridge")
        and Workspace.Baseplates.FinalBasePlate.OutlawBase.Bridge:FindFirstChild("BridgeHalf")

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
    CFrame.new(-355.4365539550781, 2.999938726425171, -49047.703125, 1, 0, 0, 0, 1, 0, 0, 0, 1),
    CFrame.new(-353.4365539550781, 2.999938726425171, -49047.703125, 1, 0, 0, 0, 1, 0, 0, 0, 1),
    CFrame.new(-350.469, 3.4999387, -49046.155625, 1, 0, 0, 0, 1, 0, 0, 0, 1),
    CFrame.new(-347.5015, 3.9999387, -49044.608125, 1, 0, 0, 0, 1, 0, 0, 0, 1),
    CFrame.new(-344.534, 4.4999387, -49043.060625, 1, 0, 0, 0, 1, 0, 0, 0, 1),
    CFrame.new(-341.566105957031, 5, -49041.51171875, 1, 0, 0, 0, 1, 0, 0, 0, 1),
    CFrame.new(-340.566105957031, 5, -49041.51171875, 1, 0, 0, 0, 1, 0, 0, 0, 1)
}

-- Hàm dịch chuyển qua các tọa độ
local function teleportToPositions()
    local character = player.Character
    local rootPart = character and character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return end

    for i, targetCFrame in ipairs(teleportPositions) do
        rootPart.CFrame = targetCFrame
        task.wait(0.5)
    end
end

-- Hàm chính cho AutoWin
local function main()
    local character = player.Character
    if not character then
        character = player.CharacterAdded:Wait()
        wait(0.5)
    end
    
    local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
    if not humanoidRootPart then
        warn("HumanoidRootPart không tồn tại!")
        return
    end
    
    while true do
        teleportToEnd()
        wait(1)
        
        if isPlayerOnBridge() then
            teleportToPositions()
            break
        end
        wait(0.5)
    end
end

-- Hàm áp dụng PromptsFar
local function applyFarPrompts(enable)
    for _, prompt in pairs(game:GetDescendants()) do
        if prompt:IsA("ProximityPrompt") then
            if enable then
                if not prompt:GetAttribute("DefaultMaxActivationDistance") then
                    prompt:SetAttribute("DefaultMaxActivationDistance", prompt.MaxActivationDistance)
                end
                prompt.MaxActivationDistance = farPromptDistance
                
                local character = player.Character
                local rootPart = character and character:FindFirstChild("HumanoidRootPart")
                if rootPart and prompt.Parent and prompt.Parent:IsA("BasePart") then
                    local distance = (rootPart.Position - prompt.Parent.Position).Magnitude
                    if distance <= farPromptDistance then
                        print("🔥 Đang kích hoạt Prompt: " .. prompt.Parent.Name)
                        fireproximityprompt(prompt)
                    end
                end
            else
                local defaultDistance = prompt:GetAttribute("DefaultMaxActivationDistance") or defaultPromptDistance
                prompt.MaxActivationDistance = defaultDistance
            end
        end
    end
end

-- Vòng lặp PromptsFar (chậm 3 giây)
local function promptsFarLoop()
    while promptsFar do
        applyFarPrompts(true)
        task.wait(3)
    end
    applyFarPrompts(false)
end

-- Khởi chạy các chức năng
ToggleNoclip()
task.spawn(main)
task.spawn(promptsFarLoop)
task.spawn(updateDisplay)

-- Dọn dẹp khi player rời game
player.CharacterRemoving:Connect(function()
    isRunning = false
    if noclipConnection then noclipConnection:Disconnect() end
end)

print("Script đã chạy: Noclip, AutoWin, PromptsFar và GUI kiểm tra thời gian liên tục đã được bật!")
