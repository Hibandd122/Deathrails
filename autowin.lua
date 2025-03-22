-- Khai báo các dịch vụ của Roblox
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
local camera = Workspace.CurrentCamera

-- Biến toàn cục
local noclipOn = true
local promptsFar = true
local fullBright = true
local floatName = "HumanoidRootPart"
local farPromptDistance = 20
local defaultPromptDistance = 10

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
    CFrame.new(-341.566105957031, 5, -49041.51171875, 1, 0, 0, 0, 1, 0, 0, 0, 1)
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
        task.wait(3) -- Chậm lại 3 giây
    end
    applyFarPrompts(false)
end

-- Hàm làm màn hình trắng và bật FullBright để giảm lag
local function applyWhiteScreenAndFullBright()
    -- FullBright
    Lighting.Brightness = 10 -- Tăng độ sáng lên rất cao
    Lighting.ClockTime = 14
    Lighting.FogEnd = 100000
    Lighting.GlobalShadows = false
    Lighting.FogStart = 0
    Lighting.FogColor = Color3.fromRGB(255, 255, 255) -- Đặt sương mù màu trắng
    
    -- Làm màn hình trắng
    camera.FieldOfView = 1 -- Giảm góc nhìn để tạo hiệu ứng trắng gần như toàn màn hình
    for _, part in pairs(Workspace:GetDescendants()) do
        if part:IsA("BasePart") and part.Name ~= floatName then
            part.Transparency = 1 -- Ẩn tất cả các đối tượng
        elseif part:IsA("Decal") or part:IsA("Texture") then
            part.Transparency = 1 -- Ẩn các texture/decal
        end
    end
end

-- Vòng lặp duy trì màn hình trắng và FullBright
local function whiteScreenLoop()
    while fullBright do
        applyWhiteScreenAndFullBright()
        task.wait(0.1)
    end
end

-- Xử lý khi nhân vật tái sinh
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

-- Tự động bật các chức năng
ToggleNoclip()  -- Bật Noclip
task.spawn(main)  -- Bật AutoWin
task.spawn(promptsFarLoop)  -- Bật PromptsFar (chậm 3 giây)
task.spawn(whiteScreenLoop)  -- Bật màn hình trắng và FullBright

print("Script đã chạy: Noclip, AutoWin, PromptsFar, và WhiteScreen (FullBright) đã được bật!")
