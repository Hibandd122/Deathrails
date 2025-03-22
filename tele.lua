-- Khai báo dịch vụ Players
local Players = game:GetService("Players")
local player = Players.LocalPlayer

-- Lấy nhân vật và HumanoidRootPart
local character = player.Character or player.CharacterAdded:Wait()
local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
local humanoid = character:WaitForChild("Humanoid")

-- Vị trí đầu tiên (đi bộ)
local firstPosition = Vector3.new(19.760950088500977, 3.6000008583068848, 124.74312591552734)

-- Danh sách vị trí teleport
local teleportPositions = {
    Vector3.new(25.15083885192871, 7.046726703643799, 125.3345718383789),
    Vector3.new(31.887962341308594, 7.599999904632568, 125.32569885253906)
}

-- Danh sách TeleportZones
local teleportZones = {
    workspace.TeleportZones.TeleportZone,
    workspace.TeleportZones.TeleportZone1,
    workspace.TeleportZones.TeleportZone2,
    workspace.TeleportZones.TeleportZone3
}

-- Hàm di chuyển đến vị trí
local function moveToPosition(targetPosition)
    if humanoid then
        local maxAttempts = 5
        local attempt = 0
        local success = false

        while attempt < maxAttempts do
            humanoid:MoveTo(targetPosition)
            humanoid.MoveToFinished:Wait()
            
            -- Kiểm tra nếu đã đến nơi
            local currentPos = humanoidRootPart.Position
            if (currentPos - targetPosition).Magnitude < 2 then
                success = true
                break
            end

            attempt += 1
            task.wait(0.5)
        end

        if not success then
            print("Di chuyển thất bại, cưỡng chế đặt vị trí")
            humanoidRootPart.CFrame = CFrame.new(targetPosition)
        else
            print("Đã di chuyển thành công!")
        end
    end
end

-- Hàm kiểm tra nếu nhân vật đã ở trong một TeleportZone
local function isPlayerInAnyZone()
    for _, zone in ipairs(teleportZones) do
        if zone.PrimaryPart and (humanoidRootPart.Position - zone.PrimaryPart.Position).Magnitude < 3 then
            print("Người chơi đã ở trong TeleportZone!")
            return true
        end
    end
    return false
end

-- Hàm tìm TeleportZone gần nhất đang "Waiting for players..."
local function findNearestTeleportZone()
    local nearestZone = nil
    local minDistance = math.huge

    for _, zone in ipairs(teleportZones) do
        local stateLabel = zone:FindFirstChild("BillboardGui") and zone.BillboardGui:FindFirstChild("StateLabel")
        local zonePosition = zone.PrimaryPart and zone.PrimaryPart.Position

        if stateLabel and stateLabel.Text == "Waiting for players..." and zonePosition then
            local distance = (humanoidRootPart.Position - zonePosition).Magnitude
            if distance < minDistance then
                minDistance = distance
                nearestZone = zone
            end
        end
    end

    return nearestZone
end

-- Hàm tạo party (gọi liên tục)
local function createParty()
    while true do
        local args = {
            [1] = { ["maxPlayers"] = 1 }
        }
        game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("RemotePromise"):WaitForChild("Remotes"):WaitForChild("C_CreateParty"):FireServer(unpack(args))
        print("Đã gửi yêu cầu tạo party!")
        task.wait(1) -- Lặp lại mỗi giây
    end
end

-- Di chuyển đến TeleportZone chính xác và gọi createParty()
local function moveToTeleportZone()
    -- Nếu đã ở trong TeleportZone, không cần di chuyển, gọi createParty() luôn
    if isPlayerInAnyZone() then
        task.spawn(createParty)
        return true
    end

    local timeout = 20
    local elapsedTime = 0

    while elapsedTime < timeout do
        local nearestZone = findNearestTeleportZone()

        if nearestZone then
            -- Gọi createParty() liên tục khi tìm thấy zone phù hợp
            task.spawn(createParty)

            local zonePosition = nearestZone.PrimaryPart.Position
            local distance = (humanoidRootPart.Position - zonePosition).Magnitude

            if distance > 3 then
                print("Đang di chuyển đến TeleportZone gần nhất...")
                moveToPosition(zonePosition)
            else
                print("Đã đến đúng TeleportZone!")
                return true
            end
        end

        task.wait(1)
        elapsedTime += 1
    end

    print("Không tìm thấy TeleportZone hợp lệ sau 20 giây!")
    return false
end

-- Hàm thực hiện toàn bộ quá trình
local function teleportSequence()
    -- 🔹 BƯỚC 1: Đi bộ đến `firstPosition`
    moveToPosition(firstPosition)

    -- 🔹 BƯỚC 2: Dịch chuyển đến tất cả `teleportPositions`
    for _, position in ipairs(teleportPositions) do
        humanoidRootPart.CFrame = CFrame.new(position)
        print("Đã dịch chuyển đến: X = " .. position.X .. ", Y = " .. position.Y .. ", Z = " .. position.Z)
        task.wait(0.5)
    end

    -- 🔹 BƯỚC 3: Tìm và di chuyển đến TeleportZone chính xác, đồng thời gọi createParty()
    local foundZone = moveToTeleportZone()

    if foundZone then
        print("Đã hoàn thành toàn bộ quy trình!")
    else
        print("Không thể tìm thấy TeleportZone hợp lệ!")
    end
end

-- Chạy chuỗi dịch chuyển
task.spawn(teleportSequence)
