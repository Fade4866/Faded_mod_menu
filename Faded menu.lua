--[[ Lumber Tycoon 2 Ultimate Faded Mod Menu ]]--

local plr = game.Players.LocalPlayer
local hrp = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
local rs = game:GetService("RunService")
local uis = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")

if not hrp then
    plr.CharacterAdded:Wait()
    hrp = plr.Character:WaitForChild("HumanoidRootPart")
end

-- GUI Creation
local gui = Instance.new("ScreenGui", plr.PlayerGui)
gui.Name = "LT2ModMenu"
gui.Enabled = true

local frame = Instance.new("Frame", gui)
frame.Size = UDim2.new(0, 260, 0, 600)
frame.Position = UDim2.new(0, 10, 0.2, 0)
frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
frame.BorderSizePixel = 0
frame.Active = true
frame.Draggable = true

-- Title bar
local titleLabel = Instance.new("TextLabel", frame)
titleLabel.Size = UDim2.new(1, 0, 0, 40)
titleLabel.Position = UDim2.new(0, 0, 0, 0)
titleLabel.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
titleLabel.BorderSizePixel = 0
titleLabel.Text = "faded mod menu"
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextSize = 22
titleLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
titleLabel.TextStrokeTransparency = 0.7
titleLabel.TextScaled = false
titleLabel.TextXAlignment = Enum.TextXAlignment.Center
titleLabel.TextYAlignment = Enum.TextYAlignment.Center

-- Notify helper
local function notify(text)
    pcall(function()
        game.StarterGui:SetCore("SendNotification", {
            Title = "faded mod menu",
            Text = text,
            Duration = 3
        })
    end)
end

-- Button maker
local function makeButton(text, y, callback)
    local btn = Instance.new("TextButton", frame)
    btn.Size = UDim2.new(0, 240, 0, 30)
    btn.Position = UDim2.new(0, 10, 0, y)
    btn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Text = text
    btn.Font = Enum.Font.SourceSansBold
    btn.TextSize = 16
    btn.AutoButtonColor = true
    btn.MouseButton1Click:Connect(callback)
    return btn
end

-- Variables
local chopping = false
local flying = false
local msgSpam = false
local autoSell = false
local autoShave = false
local autoCollect = false
local antiAFK = false

local visible = true

-- Keybinds setup with defaults
local defaultKeybinds = {
    ToggleAutoChop = Enum.KeyCode.C,
    ToggleFly = Enum.KeyCode.F,
    ToggleAntiAFK = Enum.KeyCode.Z,
}

local keybindsFile = "lt2_modmenu_keybinds.json"
local keybinds = {}

-- Load keybinds from file
local function loadKeybinds()
    if pcall(function() return readfile(keybindsFile) end) then
        local content = readfile(keybindsFile)
        local ok, data = pcall(function()
            return HttpService:JSONDecode(content)
        end)
        if ok and type(data) == "table" then
            for k,v in pairs(data) do
                if Enum.KeyCode[v] then
                    keybinds[k] = Enum.KeyCode[v]
                else
                    keybinds[k] = defaultKeybinds[k]
                end
            end
            return
        end
    end
    keybinds = defaultKeybinds
end

-- Save keybinds to file
local function saveKeybinds()
    local saveData = {}
    for k,v in pairs(keybinds) do
        saveData[k] = tostring(v.Name)
    end
    writefile(keybindsFile, HttpService:JSONEncode(saveData))
end

loadKeybinds()

-- Key dropdown UI helper
local function createKeyDropdown(parent, position, currentKey, callback)
    local keyNames = {}
    for _, key in pairs(Enum.KeyCode:GetEnumItems()) do
        table.insert(keyNames, key.Name)
    end
    table.sort(keyNames)

    local label = Instance.new("TextLabel", parent)
    label.Size = UDim2.new(0, 140, 0, 25)
    label.Position = position
    label.BackgroundColor3 = Color3.fromRGB(50,50,50)
    label.TextColor3 = Color3.new(1,1,1)
    label.Font = Enum.Font.SourceSans
    label.TextSize = 14
    label.Text = currentKey.Name

    local dropdown = Instance.new("TextButton", parent)
    dropdown.Size = UDim2.new(0, 90, 0, 25)
    dropdown.Position = position + UDim2.new(0, 150, 0, 0)
    dropdown.BackgroundColor3 = Color3.fromRGB(70,70,70)
    dropdown.TextColor3 = Color3.new(1,1,1)
    dropdown.Font = Enum.Font.SourceSans
    dropdown.TextSize = 14
    dropdown.Text = "Change"

    dropdown.MouseButton1Click:Connect(function()
        local idx = table.find(keyNames, label.Text) or 1
        idx = idx + 1
        if idx > #keyNames then idx = 1 end
        label.Text = keyNames[idx]
        callback(Enum.KeyCode[keyNames[idx]])
    end)

    return label, dropdown
end

-- Buttons Y-position tracker
local yPos = 50

-- AUTO CHOP
makeButton("Toggle Auto Chop (Key: C)", yPos, function()
    chopping = not chopping
    notify("Auto Chop: " .. (chopping and "ON" or "OFF"))
    if chopping then
        spawn(function()
            while chopping do
                wait(2)
                local treeRegion = workspace:FindFirstChild("TreeRegion")
                if not treeRegion then wait(1) continue end
                local closest, dist = nil, math.huge
                for _, tree in pairs(treeRegion:GetChildren()) do
                    if tree:FindFirstChild("WoodSection") then
                        local d = (tree.WoodSection.Position - hrp.Position).Magnitude
                        if d < dist then
                            dist = d
                            closest = tree
                        end
                    end
                end
                if closest then
                    pcall(function()
                        game.ReplicatedStorage.Interaction.RemoteEvent:FireServer("CutTree", closest, closest.WoodSection.Position)
                    end)
                end
            end
        end)
    end
end)
yPos = yPos + 40

-- FLY
makeButton("Toggle Fly (Key: F)", yPos, function()
    flying = not flying
    notify("Fly: " .. (flying and "ON" or "OFF"))
end)
yPos = yPos + 40

rs.RenderStepped:Connect(function()
    if flying then
        local dir = Vector3.zero
        if uis:IsKeyDown(Enum.KeyCode.W) then dir += hrp.CFrame.LookVector end
        if uis:IsKeyDown(Enum.KeyCode.S) then dir -= hrp.CFrame.LookVector end
        if uis:IsKeyDown(Enum.KeyCode.A) then dir -= hrp.CFrame.RightVector end
        if uis:IsKeyDown(Enum.KeyCode.D) then dir += hrp.CFrame.RightVector end
        hrp.Velocity = dir.Unit * 70
    else
        hrp.Velocity = Vector3.new(0, hrp.Velocity.Y, 0)
    end
end)

-- TELEPORT TO BASE
makeButton("Teleport to My Base", yPos, function()
    local base = nil
    for _, plot in pairs(workspace.Properties:GetChildren()) do
        if plot:FindFirstChild("Owner") and plot.Owner.Value == plr then
            base = plot
            break
        end
    end
    if base then
        hrp.CFrame = base.OriginSquare.CFrame + Vector3.new(0, 5, 0)
        notify("Teleported to your base!")
    else
        notify("Base not found!")
    end
end)
yPos = yPos + 40

-- TREE TELEPORT DROPDOWN
local dropdownLabel = Instance.new("TextLabel", frame)
dropdownLabel.Size = UDim2.new(0, 240, 0, 25)
dropdownLabel.Position = UDim2.new(0, 10, 0, yPos)
dropdownLabel.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
dropdownLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
dropdownLabel.Text = "🌲 Select Tree Type"
dropdownLabel.Font = Enum.Font.SourceSansBold
dropdownLabel.TextSize = 14
yPos = yPos + 30

local dropdown = Instance.new("TextButton", frame)
dropdown.Size = UDim2.new(0, 240, 0, 25)
dropdown.Position = UDim2.new(0, 10, 0, yPos)
dropdown.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
dropdown.TextColor3 = Color3.fromRGB(255, 255, 255)
dropdown.Text = "Elm"
dropdown.Font = Enum.Font.SourceSans
dropdown.TextSize = 14
yPos = yPos + 40

local treesList = {"Elm", "Fir", "Oak", "Pine", "Walnut", "Cherry", "Birch", "Koa", "Lava", "Frost"}
local selectedTree = "Elm"

dropdown.MouseButton1Click:Connect(function()
    local currentIndex = table.find(treesList, selectedTree) or 1
    selectedTree = treesList[(currentIndex % #treesList) + 1]
    dropdown.Text = selectedTree
end)

makeButton("Teleport to Selected Tree", yPos, function()
    local treeRegion = workspace:FindFirstChild("TreeRegion")
    if not treeRegion then
        notify("TreeRegion not found!")
        return
    end
    for _, tree in pairs(treeRegion:GetChildren()) do
        if tree.Name:lower():find(selectedTree:lower()) and tree:FindFirstChild("WoodSection") then
            hrp.CFrame = tree.WoodSection.CFrame + Vector3.new(0, 5, 0)
            notify("Teleported to: " .. selectedTree)
            return
        end
    end
    notify(selectedTree .. " tree not found!")
end)
yPos = yPos + 40

-- DONATE MESSAGE SPAM
makeButton("Toggle Donate Spam", yPos, function()
    msgSpam = not msgSpam
    notify("Donate Spam: " .. (msgSpam and "ON" or "OFF"))
    if msgSpam then
        spawn(function()
            while msgSpam do
                wait(120)
                pcall(function()
                    game.ReplicatedStorage.DefaultChatSystemChatEvents.SayMessageRequest:FireServer(
                        "💸 Donate if you want — every bit helps!", "All")
                end)
            end
        end)
    end
end)
yPos = yPos + 40

-- AUTO SELL LOGS
makeButton("Toggle Auto Sell Logs", yPos, function()
    autoSell = not autoSell
    notify("Auto Sell Logs: " .. (autoSell and "ON" or "OFF"))
    if autoSell then
        spawn(function()
            while autoSell do
                wait(5)
                local plots = workspace.Properties:GetChildren()
                for _, plot in pairs(plots) do
                    if plot:FindFirstChild("Owner") and plot.Owner.Value == plr then
                        for _, item in pairs(plot:GetDescendants()) do
                            if item:IsA("Model") and item:FindFirstChild("TreeClass") and item:FindFirstChild("Main") then
                                local dropOff = workspace:FindFirstChild("WoodDropoff")
                                if dropOff then
                                    pcall(function()
                                        item:SetPrimaryPartCFrame(dropOff.CFrame + Vector3.new(0, 3, 0))
                                    end)
                                end
                            end
                        end
                    end
                end
            end
        end)
    end
end)
yPos = yPos + 40

-- AUTO SHAVE LOGS
makeButton("Toggle Auto Shave Logs", yPos, function()
    autoShave = not autoShave
    notify("Auto Shave Logs: " .. (autoShave and "ON" or "OFF"))
    if autoShave then
        spawn(function()
            while autoShave do
                wait(5)
                local sawmills = {}
                for _, obj in pairs(workspace:GetDescendants()) do
                    if obj.Name == "Saw" and obj:FindFirstChild("Owner") and obj.Owner.Value == plr then
                        table.insert(sawmills, obj)
                    end
                end

                for _, saw in pairs(sawmills) do
                    for _, item in pairs(workspace:GetChildren()) do
                        if item:IsA("Model") and item:FindFirstChild("TreeClass") and item:FindFirstChild("Main") then
                            if (item:GetModelCFrame().p - saw.Position).Magnitude < 30 then
                                pcall(function()
                                    item:SetPrimaryPartCFrame(saw.CFrame + Vector3.new(0, 1.5, 0))
                                end)
                            end
                        end
                    end
                end
            end
        end)
    end
end)
yPos = yPos + 40

-- AUTO COLLECT PROCESSED PLANKS
makeButton("Toggle Auto Collect Planks", yPos, function()
    autoCollect = not autoCollect
    notify("Auto Collect Planks: " .. (autoCollect and "ON" or "OFF"))
    if autoCollect then
        spawn(function()
            while autoCollect do
                wait(5)
                local collectPos = hrp.Position + Vector3.new(5, 1, 5)
                for _, obj in pairs(workspace:GetChildren()) do
                    if obj:IsA("Model") and obj:FindFirstChild("TreeClass") and obj:FindFirstChild("Main") then
                        local size = obj:GetExtentsSize()
                        if size.Y < 1 and (obj:GetModelCFrame().p - hrp.Position).Magnitude < 50 then
                            pcall(function()
                                obj:SetPrimaryPartCFrame(CFrame.new(collectPos + Vector3.new(math.random(-3,3),0,math.random(-3,3))))
                            end)
                        end
                    end
                end
            end
        end)
    end
end)
yPos = yPos + 40

-- SAWMILL SIZE EDITOR (2x3)
makeButton("Edit Sawmill Size (2x3)", yPos, function()
    local width = 2
    local length = 3
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj.Name == "Saw" and obj:FindFirstChild("Owner") and obj.Owner.Value == plr then
            pcall(function()
                game.ReplicatedStorage.Interaction.RemoteFunction:InvokeServer("SetSawmillSettings", obj.Parent, width, length)
            end)
            notify("Sawmill size set to "..width.." x "..length)
        end
    end
end)
yPos = yPos + 40

-- TELEPORT TRUCK WITH YOU, UPRIGHT, INCLUDING WOOD
makeButton("Teleport Truck (With You + Wood Upright)", yPos, function()
    local character = plr.Character
    if not character then notify("Character not loaded!") return end

    local seat = nil
    for _, part in pairs(character:GetDescendants()) do
        if part:IsA("Seat") or part:IsA("VehicleSeat") then
            seat = part
            break
        end
    end

    if not seat then
        notify("You must be seated in a truck!")
        return
    end

    local truckModel = seat:FindFirstAncestorOfClass("Model")
    if not truckModel or not truckModel.PrimaryPart then
        notify("Could not find truck model or PrimaryPart!")
        return
    end

    local base = nil
    for _, plot in pairs(workspace.Properties:GetChildren()) do
        if plot:FindFirstChild("Owner") and plot.Owner.Value == plr then
            base = plot
            break
        end
    end

    if not base then
        notify("Your base was not found!")
        return
    end

    local basePos = base.OriginSquare.Position + Vector3.new(5, 5, 5)
    local uprightCFrame = CFrame.new(basePos) * CFrame.Angles(0, truckModel.PrimaryPart.Orientation.Y * math.pi/180, 0)

    truckModel:SetPrimaryPartCFrame(uprightCFrame)

    -- Teleport wood inside truck preserving relative offsets
    for _, obj in pairs(truckModel:GetDescendants()) do
        if obj:IsA("Model") and obj:FindFirstChild("TreeClass") and obj:FindFirstChild("Main") then
            local log = obj
            if log.PrimaryPart then
                local relPos = truckModel.PrimaryPart.CFrame:PointToObjectSpace(log.PrimaryPart.Position)
                local newLogPos = uprightCFrame:PointToWorldSpace(relPos)
                pcall(function()
                    log:SetPrimaryPartCFrame(CFrame.new(newLogPos))
                end)
            end
        end
    end

    notify("Truck + wood teleported upright with you inside!")
end)
yPos = yPos + 40

-- ANTI AFK
makeButton("Toggle Anti-AFK (Key: Z)", yPos, function()
    antiAFK = not antiAFK
    notify("Anti-AFK: " .. (antiAFK and "ON" or "OFF"))
    if antiAFK then
        spawn(function()
            local vu = game:GetService("VirtualUser")
            while antiAFK do
                wait(60)
                pcall(function()
                    vu:Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
                    wait(1)
                    vu:Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
                end)
            end
        end)
    end
end)
yPos = yPos + 40

-- Keybinds UI Section
local keybindTitle = Instance.new("TextLabel", frame)
keybindTitle.Size = UDim2.new(0, 240, 0, 25)
keybindTitle.Position = UDim2.new(0, 10, 0, yPos)
keybindTitle.BackgroundColor3 = Color3.fromRGB(30,30,30)
keybindTitle.TextColor3 = Color3.fromRGB(255,255,255)
keybindTitle.Font = Enum.Font.SourceSansBold
keybindTitle.TextSize = 16
keybindTitle.Text = "Keybind Settings:"
yPos = yPos + 30

local function addKeybindSetting(name, displayName)
    local currentKey = keybinds[name] or defaultKeybinds[name]
    createKeyDropdown(frame, UDim2.new(0, 10, 0, yPos), currentKey, function(newKey)
        keybinds[name] = newKey
    end)
    local nameLabel = Instance.new("TextLabel", frame)
    nameLabel.Size = UDim2.new(0, 140, 0, 25)
    nameLabel.Position = UDim2.new(0, 10, 0, yPos)
    nameLabel.BackgroundTransparency = 1
    nameLabel.TextColor3 = Color3.new(1,1,1)
    nameLabel.Font = Enum.Font.SourceSans
    nameLabel.TextSize = 14
    nameLabel.Text = displayName
    yPos = yPos + 30
end

addKeybindSetting("ToggleAutoChop", "Toggle Auto Chop")
addKeybindSetting("ToggleFly", "Toggle Fly")
addKeybindSetting("ToggleAntiAFK", "Toggle Anti-AFK")

makeButton("Save Keybinds", yPos + 5, function()
    saveKeybinds()
    notify("Keybinds saved!")
end)

-- Keybinds toggling via keyboard and menu visibility toggle
uis.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end

    if input.KeyCode == Enum.KeyCode.Insert then
        visible = not visible
        gui.Enabled = visible
        notify("Mod Menu " .. (visible and "Opened" or "Closed"))
    end

    if input.KeyCode == (keybinds.ToggleAutoChop or Enum.KeyCode.C) then
        chopping = not chopping
        notify("Auto Chop: " .. (chopping and "ON" or "OFF"))
    elseif input.KeyCode == (keybinds.ToggleFly or Enum.KeyCode.F) then
        flying = not flying
        notify("Fly: " .. (flying and "ON" or "OFF"))
    elseif input.KeyCode == (keybinds.ToggleAntiAFK or Enum.KeyCode.Z) then
        antiAFK = not antiAFK
        notify("Anti-AFK: " .. (antiAFK and "ON" or "OFF"))
    end
end)

-- END OF SCRIPT
