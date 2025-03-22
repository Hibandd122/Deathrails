-- 🔹 KHAI BÁO DỊCH VỤ & NGƯỜI CHƠI
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local player = Players.LocalPlayer

-- 🔹 BIẾN TOÀN CỤC
local noclipOn = true
local noclipConnection = nil
local floatName = "HumanoidRootPart" -- Bộ phận không bị tắt NoClip
local settings = { toggles = { AutoWin = true } } -- Tùy chỉnh AutoWin

-- 🔹 HÀM BẬT/TẮT NOCLIP
local function ToggleNoclip()
    if noclipOn then
        if noclipConnection then noclipConnection:Disconnect() end
        noclipConnection = RunService.Stepped:Connect(function()
            if player.Character then
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

-- 🔹 HÀM DỊCH CHUYỂN ĐẾN ĐIỂM CUỐI
local function teleportToEnd()
    local character = player.Character
    local rootPart = character and character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return end
    
    rootPart.CFrame = CFrame.new(-2047.5, -80, -49429)
    task.wait(0.5)
    rootPart.CFrame = CFrame.new(0.5, -80, -49429)
    task.wait(0.1)
end

-- 🔹 HÀM KIỂM TRA NGƯỜI CHƠI ĐỨNG TRÊN CẦU
local function isPlayerOnBridge()
    local character = player.Character
    local rootPart = character and character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return false end

    local bridgeHalf = workspace:FindFirstChild("Baseplates")
        and workspace.Baseplates:FindFirstChild("FinalBasePlate")
        and workspace.Baseplates.FinalBasePlate:FindFirstChild("OutlawBase")
        and workspace.Baseplates.FinalBasePlate.OutlawBase:FindFirstChild("Bridge")
        and workspace.Baseplates.FinalBasePlate.OutlawBase.Bridge:FindFirstChild("BridgeHalf")

    if not bridgeHalf then return false end
    return (rootPart.Position - bridgeHalf.Position).Magnitude < 5
end

-- 🔹 DANH SÁCH ĐIỂM DỊCH CHUYỂN
local teleportPositions = {
    CFrame.new(-377.48, 3.5, -49057.05),
    CFrame.new(-367.09, 2.99, -49052.32),
    CFrame.new(-360.43, 2.99, -49052.43),
    CFrame.new(-355.43, 2.99, -49047.70),
    CFrame.new(-353.43, 2.99, -49047.70),
    CFrame.new(-350.46, 3.49, -49046.15),
    CFrame.new(-347.50, 3.99, -49044.60),
    CFrame.new(-344.53, 4.49, -49043.06),
    CFrame.new(-341.56, 5, -49041.51)
}

-- 🔹 HÀM DỊCH CHUYỂN THEO `teleportPositions`
local function teleportToPositions()
    local character = player.Character
    local rootPart = character and character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return end
    for _, targetCFrame in ipairs(teleportPositions) do
        rootPart.CFrame = targetCFrame
        task.wait(0.5)
    end
end

-- 🔹 CHƯƠNG TRÌNH CHÍNH (AutoWin)
local function main()
    local character = player.Character
    if not character then
        character = player.CharacterAdded:Wait()
        task.wait(0.5)
    end
    
    local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
    if not humanoidRootPart then return end
    
    while settings.toggles.AutoWin do
        teleportToEnd()
        task.wait(1)

        if isPlayerOnBridge() then
            teleportToPositions()
            settings.toggles.AutoWin = false
            print("✅ Đã hoàn thành AutoWin!")
            break
        end
        task.wait(0.5)
    end
end

-- 🔹 TỰ ĐỘNG BẤM PROXIMITY PROMPT
local function activatePrompts()
    for _, descendant in ipairs(workspace:GetDescendants()) do
        if descendant:IsA("ProximityPrompt") then
            fireproximityprompt(descendant)
        end
    end
end

-- 🔹 CHẠY CÁC CHỨC NĂNG
ToggleNoclip()       -- Bật NoClip
task.spawn(main)     -- Chạy AutoWin
task.spawn(function() -- Tự động bấm Prompt mỗi 3 giây
    while true do
        activatePrompts()
        task.wait(3)
    end
end)
