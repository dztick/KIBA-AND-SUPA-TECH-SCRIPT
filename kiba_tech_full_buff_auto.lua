-- KibaTech_FullBuff_Auto.lua
-- Script ini menggabungkan buff permanen, Kiba Tech manual, GUI ultra-mini, dan notifikasi STARTED

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local root = character:WaitForChild("HumanoidRootPart")

-- RemoteEvent asli
local DashRemote = ReplicatedStorage:FindFirstChild("DashRemote")
local UppercutRemote = ReplicatedStorage:FindFirstChild("UppercutRemote")

if not DashRemote or not UppercutRemote then
    warn("DashRemote atau UppercutRemote tidak ditemukan!")
end

-- Config default
local defaultRadius = 12
local defaultFloatHeight = 10
local kibaWindow = 2 -- durasi Kiba Tech

local kibaActiveUntil = 0
local buffActive = false

-- Buff permanen untuk hitbox & Supa Tech
local function BuffPermanent()
    buffActive = false
    for _, otherPlayer in pairs(Players:GetPlayers()) do
        if otherPlayer ~= player and otherPlayer.Character and otherPlayer.Character:FindFirstChild("HumanoidRootPart") then
            local hrp = otherPlayer.Character.HumanoidRootPart
            if (root.Position - hrp.Position).Magnitude <= defaultRadius then
                if hrp:FindFirstChild("BodyVelocity") then
                    hrp.BodyVelocity.Velocity = Vector3.new(0,0,0)
                end
                buffActive = true
            end
        end
    end
end

-- Trigger Kiba Tech manual
local function KibaTechTrigger(targetRoot)
    if DashRemote and UppercutRemote and targetRoot and targetRoot.Parent and targetRoot:FindFirstChild("HumanoidRootPart") then
        local dist = (root.Position - targetRoot.Position).Magnitude
        local floatHeight = math.clamp(dist/2, 5, 15)
        UppercutRemote:FireServer(targetRoot.Position)
        task.wait(0.05)
        DashRemote:FireServer(targetRoot.Position, 1)
        root.CFrame = CFrame.new(targetRoot.Position.X, targetRoot.Position.Y + floatHeight, targetRoot.Position.Z)
    end
end

-- Auto-target semua musuh valid untuk Kiba Tech
local function getAllUppercutTargets()
    local targets = {}
    for _, otherPlayer in pairs(Players:GetPlayers()) do
        if otherPlayer ~= player and otherPlayer.Character and otherPlayer.Character:FindFirstChild("HumanoidRootPart") then
            local hrp = otherPlayer.Character.HumanoidRootPart
            local dist = (root.Position - hrp.Position).Magnitude
            local humanoid = otherPlayer.Character:FindFirstChild("Humanoid")
            if dist <= defaultRadius and humanoid and humanoid.FloorMaterial == Enum.Material.Air then
                table.insert(targets, hrp)
            end
        end
    end
    return targets
end

-- GUI ultra-mini
local function setupGUI()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Parent = player:WaitForChild("PlayerGui")
    screenGui.IgnoreGuiInset = true

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0,50,0,15)
    label.Position = UDim2.new(0,5,1,-20)
    label.BackgroundTransparency = 0.5
    label.TextColor3 = Color3.fromRGB(0,255,0)
    label.TextScaled = true
    label.Text = ""
    label.Parent = screenGui

    return label
end

local guiLabel = setupGUI()

-- Update setiap frame
RunService.Heartbeat:Connect(function()
    -- Kiba Tech manual hanya aktif saat R ditekan
    if tick() <= kibaActiveUntil then
        local targets = getAllUppercutTargets()
        for _, target in ipairs(targets) do
            KibaTechTrigger(target)
        end
    end

    -- Buff permanen selalu aktif
    BuffPermanent()

    -- Update GUI
    local remaining = math.max(0, kibaActiveUntil - tick())
    if remaining > 0 or buffActive then
        guiLabel.Text = string.format("%.1fs", remaining)
        if buffActive then
            guiLabel.Text = guiLabel.Text .. " | BUFF"
        end
    else
        guiLabel.Text = ""
    end
end)

-- Tekan R untuk aktifkan Kiba Tech manual
UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.KeyCode == Enum.KeyCode.R then
        kibaActiveUntil = tick() + kibaWindow
    end
end)

-- Notifikasi STARTED
local function showNotification(text, duration)
    local screenGui = Instance.new("ScreenGui")
    screenGui.Parent = player:WaitForChild("PlayerGui")
    screenGui.IgnoreGuiInset = true

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0,150,0,40)
    label.Position = UDim2.new(1,-160,1,-50)
    label.BackgroundColor3 = Color3.fromRGB(30,30,30)
    label.TextColor3 = Color3.fromRGB(0,255,0)
    label.TextScaled = true
    label.Text = text
    label.BackgroundTransparency = 0.3
    label.TextTransparency = 1
    label.Parent = screenGui

    for i=0,1,0.05 do
        label.TextTransparency = 1 - i
        task.wait(0.03)
    end

    task.wait(duration or 2)

    for i=0,1,0.05 do
        label.TextTransparency = i
        task.wait(0.03)
    end

    screenGui:Destroy()
end

showNotification("STARTED", 2)
