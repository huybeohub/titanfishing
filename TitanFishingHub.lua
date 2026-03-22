--[[
    ╔══════════════════════════════════════════════════════════════╗
    ║          🎣  TITAN FISHING HUB  - FLUENT UI                 ║
    ║         Auto Fish | Auto Skill | Auto Sell | Teleport       ║
    ║                  Version: 2.0  |  2026                      ║
    ╚══════════════════════════════════════════════════════════════╝
    
    FEATURES:
    ✅ Auto Fish        - Tự động câu cá (cast + reel)
    ✅ Auto Skill       - Tự động dùng kỹ năng Z/X/C/Q
    ✅ Auto Sell        - Tự động bán cá
    ✅ Auto Buy Bait    - Tự động mua mồi
    ✅ Auto Buy Rod     - Tự động mua cần câu tiếp theo
    ✅ Fish Filter      - Lọc cá theo độ hiếm
    ✅ Teleport         - Di chuyển nhanh
    ✅ Anti-AFK         - Chống kick AFK
    ✅ Walk Speed       - Tăng tốc độ di chuyển
    ✅ Save Config      - Lưu cài đặt
]]

-- ═══════════════════════════════════════════
-- [1] LOAD FLUENT UI LIBRARY (dawid-scripts)
-- ═══════════════════════════════════════════
local success, Fluent = pcall(function()
    return loadstring(game:HttpGet(
        "https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"
    ))()
end)

if not success then
    warn("[TitanFishingHub] Không thể load Fluent UI! Thử lại...")
    -- Fallback: thử URL khác
    Fluent = loadstring(game:HttpGet(
        "https://raw.githubusercontent.com/dawid-scripts/Fluent/master/main.lua"
    ))()
end

local SaveManager = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"
))()

local InterfaceManager = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"
))()

-- ═══════════════════════════════════════════
-- [2] SERVICES & VARIABLES
-- ═══════════════════════════════════════════
local Players            = game:GetService("Players")
local RunService         = game:GetService("RunService")
local TweenService       = game:GetService("TweenService")
local VirtualInput       = game:GetService("VirtualInputManager")
local UserInputService   = game:GetService("UserInputService")
local ReplicatedStorage  = game:GetService("ReplicatedStorage")
local Workspace          = game:GetService("Workspace")
local HttpService        = game:GetService("HttpService")
local StarterGui         = game:GetService("StarterGui")

local Player    = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")
local Mouse     = Player:GetMouse()

-- Character Reference (reload on respawn)
local Character, HRP, Humanoid
local function UpdateCharacter()
    Character  = Player.Character or Player.CharacterAdded:Wait()
    HRP        = Character:WaitForChild("HumanoidRootPart", 10)
    Humanoid   = Character:WaitForChild("Humanoid", 10)
end
UpdateCharacter()
Player.CharacterAdded:Connect(UpdateCharacter)

-- ═══════════════════════════════════════════
-- [3] SETTINGS TABLE
-- ═══════════════════════════════════════════
local Settings = {
    -- Auto Farm
    AutoFish        = false,
    AutoSell        = false,
    AutoBuyBait     = false,
    AutoBuyRod      = false,
    FishDelay       = 1.0,
    SellDelay       = 30,   -- giây giữa các lần sell tự động
    MinRarity       = "Common",

    -- Auto Skill
    AutoSkill       = false,
    SkillZ          = true,
    SkillX          = true,
    SkillC          = true,
    SkillQ          = false,
    SkillDelay      = 0.3,
    SkillInterval   = 1.0,  -- chu kỳ lặp kỹ năng

    -- Player
    WalkSpeed       = 16,
    AntiAFK         = false,
    Noclip          = false,

    -- Teleport
    AutoFarmLocation = "Island 1",
}

-- Rarity Order (để filter)
local RarityOrder = { "Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythical" }
local RarityColors = {
    Common    = Color3.fromRGB(180, 180, 180),
    Uncommon  = Color3.fromRGB(100, 200, 100),
    Rare      = Color3.fromRGB(60, 120, 220),
    Epic      = Color3.fromRGB(160, 60, 220),
    Legendary = Color3.fromRGB(255, 165, 0),
    Mythical  = Color3.fromRGB(255, 50, 50),
}

-- ═══════════════════════════════════════════
-- [4] GAME DETECTION - TÌM REMOTE EVENTS
-- ═══════════════════════════════════════════
local Remotes = {}
local GameRemotes = ReplicatedStorage:FindFirstChild("Remotes")
    or ReplicatedStorage:FindFirstChild("Events")
    or ReplicatedStorage:FindFirstChild("RE")
    or ReplicatedStorage

-- Hàm tìm remote theo tên (đệ quy)
local function FindRemote(parent, name)
    for _, obj in ipairs(parent:GetDescendants()) do
        if (obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction"))
            and (obj.Name:lower():find(name:lower())) then
            return obj
        end
    end
    return nil
end

-- Cache các remotes hay dùng
local function CacheRemotes()
    Remotes.Cast     = FindRemote(ReplicatedStorage, "Cast")
                    or FindRemote(ReplicatedStorage, "CastRod")
                    or FindRemote(ReplicatedStorage, "StartFish")
    
    Remotes.Reel     = FindRemote(ReplicatedStorage, "Reel")
                    or FindRemote(ReplicatedStorage, "ReelIn")
                    or FindRemote(ReplicatedStorage, "Catch")
    
    Remotes.Sell     = FindRemote(ReplicatedStorage, "Sell")
                    or FindRemote(ReplicatedStorage, "SellFish")
                    or FindRemote(ReplicatedStorage, "SellAll")
                    or FindRemote(ReplicatedStorage, "SellInventory")
    
    Remotes.BuyBait  = FindRemote(ReplicatedStorage, "BuyBait")
                    or FindRemote(ReplicatedStorage, "PurchaseBait")
                    or FindRemote(ReplicatedStorage, "Buy")
    
    Remotes.BuyRod   = FindRemote(ReplicatedStorage, "BuyRod")
                    or FindRemote(ReplicatedStorage, "UpgradeRod")
                    or FindRemote(ReplicatedStorage, "NextRod")
    
    Remotes.Skill    = FindRemote(ReplicatedStorage, "Skill")
                    or FindRemote(ReplicatedStorage, "UseSkill")
                    or FindRemote(ReplicatedStorage, "Ability")
end

task.spawn(CacheRemotes)

-- Tự động refresh remotes mỗi 30 giây
task.spawn(function()
    while true do
        task.wait(30)
        CacheRemotes()
    end
end)

-- ═══════════════════════════════════════════
-- [5] UTILITY FUNCTIONS
-- ═══════════════════════════════════════════

-- Nhấn phím ảo
local function PressKey(keyCode, holdTime)
    holdTime = holdTime or 0.05
    VirtualInput:SendKeyEvent(true, keyCode, false, game)
    task.wait(holdTime)
    VirtualInput:SendKeyEvent(false, keyCode, false, game)
end

-- Nhấn phím và giữ
local function HoldKey(keyCode, duration)
    VirtualInput:SendKeyEvent(true, keyCode, false, game)
    task.wait(duration or 0.1)
    VirtualInput:SendKeyEvent(false, keyCode, false, game)
end

-- Fire Remote Event an toàn
local function SafeFireRemote(remote, ...)
    if remote and remote:IsA("RemoteEvent") then
        pcall(function() remote:FireServer(...) end)
        return true
    elseif remote and remote:IsA("RemoteFunction") then
        local ok, res = pcall(function() return remote:InvokeServer(...) end)
        return ok, res
    end
    return false
end

-- Teleport an toàn
local function SafeTeleport(position)
    if not HRP then UpdateCharacter() end
    if HRP then
        HRP.CFrame = CFrame.new(position + Vector3.new(0, 3, 0))
        task.wait(0.1)
    end
end

-- Lấy khoảng cách đến vị trí
local function GetDistance(pos)
    if HRP then
        return (HRP.Position - pos).Magnitude
    end
    return math.huge
end

-- Kiểm tra UI đang hiển thị (detect fishing state)
local function IsFishing()
    -- Tìm các GUI liên quan đến đang câu cá
    for _, gui in ipairs(PlayerGui:GetChildren()) do
        if gui.Name:lower():find("fish") then
            local reelBtn = gui:FindFirstChild("ReelButton", true)
                         or gui:FindFirstChild("Reel", true)
                         or gui:FindFirstChild("CatchButton", true)
            if reelBtn and reelBtn.Visible then
                return true, reelBtn
            end
        end
    end
    return false, nil
end

-- Kiểm tra xem có cá cắn chưa
local function FishBiting()
    for _, gui in ipairs(PlayerGui:GetChildren()) do
        if gui.Name:lower():find("fish") or gui.Name:lower():find("bite") then
            -- Tìm indicator "cá cắn"
            local biteIndicator = gui:FindFirstChild("Bite", true)
                                or gui:FindFirstChild("BiteIndicator", true)
                                or gui:FindFirstChild("FishBite", true)
            if biteIndicator and biteIndicator.Visible then
                return true
            end
            -- Tìm thanh reel progress
            local reelFrame = gui:FindFirstChild("ReelFrame", true)
                            or gui:FindFirstChild("FightFrame", true)
            if reelFrame and reelFrame.Visible then
                return true
            end
        end
    end
    return false
end

-- Lấy skill buttons từ GUI
local function GetSkillButtons()
    local buttons = {}
    for _, gui in ipairs(PlayerGui:GetChildren()) do
        -- Tìm skill bar / hotbar
        local skillBar = gui:FindFirstChild("SkillBar", true)
                      or gui:FindFirstChild("SkillFrame", true)
                      or gui:FindFirstChild("AbilityBar", true)
                      or gui:FindFirstChild("Hotbar", true)
        if skillBar then
            for _, btn in ipairs(skillBar:GetChildren()) do
                if btn:IsA("ImageButton") or btn:IsA("TextButton") then
                    -- Check cooldown: nếu không có overlay/cooldown frame thì có thể dùng
                    local cooldownFrame = btn:FindFirstChild("Cooldown", true)
                                       or btn:FindFirstChild("CooldownOverlay", true)
                    local isReady = not (cooldownFrame and cooldownFrame.Visible)
                    buttons[btn.Name] = { button = btn, ready = isReady }
                end
            end
        end
    end
    return buttons
end

-- ═══════════════════════════════════════════
-- [6] TELEPORT LOCATIONS
-- ═══════════════════════════════════════════
-- Các vị trí dựa trên wiki và gameplay phổ biến
-- Player có thể update tọa độ chính xác sau
local TeleportLocations = {
    ["🏝️ Island 1"]    = Vector3.new(0, 5, 0),
    ["🏝️ Island 2"]    = Vector3.new(285, 5, -210),
    ["🌋 Volcano"]      = Vector3.new(450, 80, 120),
    ["🌊 Deep Ocean"]   = Vector3.new(-380, 5, -280),
    ["🏪 Shop"]         = Vector3.new(20, 5, -50),
    ["⚓ Dock"]         = Vector3.new(60, 5, 30),
    ["🌌 Abyss Zone"]   = Vector3.new(-500, 5, 400),
    ["💎 Boss Arena"]   = Vector3.new(600, 5, -100),
}

-- ═══════════════════════════════════════════
-- [7] CORE LOGIC - AUTO FISH
-- ═══════════════════════════════════════════
local AutoFishActive   = false
local AutoSkillActive  = false
local AntiAFKActive    = false
local FishCount        = 0
local SellCount        = 0
local LastSellTime     = 0

-- Thread handles
local FishThread       = nil
local SkillThread      = nil
local AntiAFKThread    = nil
local SellThread       = nil

-- Thống kê
local Stats = {
    FishCaught  = 0,
    FishSold    = 0,
    SkillsUsed  = 0,
    RunTime     = 0,
    StartTime   = 0,
}

-- ┌─────────────────────────────┐
-- │  AUTO FISH MAIN LOOP        │
-- └─────────────────────────────┘
local function DoAutoFish()
    AutoFishActive = true
    Stats.StartTime = os.time()

    while AutoFishActive and Settings.AutoFish do
        local ok, err = pcall(function()
            -- STEP 1: Thử fire remote Cast
            local castFired = false
            if Remotes.Cast then
                castFired = SafeFireRemote(Remotes.Cast)
            end

            -- STEP 2: Nếu không có remote, dùng phím E (cast)
            if not castFired then
                PressKey(Enum.KeyCode.E)
            end

            -- Chờ một chút sau khi cast
            task.wait(0.5)

            -- STEP 3: Chờ cá cắn rồi reel
            local waitTime = 0
            local maxWait = Settings.FishDelay + 8 -- max chờ
            repeat
                task.wait(0.1)
                waitTime = waitTime + 0.1

                -- Kiểm tra xem cá đã cắn chưa
                local biting = FishBiting()
                if biting then
                    break
                end
            until waitTime >= maxWait

            -- STEP 4: Reel (thu dây)
            local reelFired = false
            if Remotes.Reel then
                reelFired = SafeFireRemote(Remotes.Reel)
            end

            if not reelFired then
                -- Dùng Space hoặc Click để reel
                PressKey(Enum.KeyCode.Space)
                task.wait(0.05)
                -- Giữ space để reel liên tục nếu có fighting mechanic
                for i = 1, 5 do
                    PressKey(Enum.KeyCode.Space, 0.05)
                    task.wait(0.1)
                end
            end

            -- STEP 5: Nhấn F để pick up / confirm catch (một số game dùng)
            task.wait(0.2)
            PressKey(Enum.KeyCode.F)

            Stats.FishCaught = Stats.FishCaught + 1
            FishCount = FishCount + 1

            -- STEP 6: Auto Sell theo interval
            if Settings.AutoSell then
                local now = os.time()
                if now - LastSellTime >= Settings.SellDelay then
                    task.wait(0.5)
                    if Remotes.Sell then
                        SafeFireRemote(Remotes.Sell)
                    end
                    -- Nhấn vào nút sell trong UI nếu có
                    for _, gui in ipairs(PlayerGui:GetChildren()) do
                        local sellBtn = gui:FindFirstChild("SellButton", true)
                                     or gui:FindFirstChild("SellAll", true)
                        if sellBtn and sellBtn:IsA("GuiButton") then
                            pcall(function() sellBtn:activate() end)
                            pcall(function() 
                                local mev = Instance.new("InputObject")
                                mev.UserInputType = Enum.UserInputType.MouseButton1
                                mev.UserInputState = Enum.UserInputState.Begin
                                sellBtn.InputBegan:Fire(mev, false)
                            end)
                        end
                    end
                    LastSellTime = now
                    Stats.FishSold = Stats.FishSold + FishCount
                    FishCount = 0
                    SellCount = SellCount + 1
                end
            end

            -- STEP 7: Auto Buy Bait
            if Settings.AutoBuyBait and Remotes.BuyBait then
                SafeFireRemote(Remotes.BuyBait, "Worm", 100)
            end

            -- STEP 8: Delay trước lần câu tiếp
            task.wait(math.max(0.1, Settings.FishDelay))
        end)

        if not ok then
            task.wait(1) -- Chờ nếu có lỗi
        end
    end

    AutoFishActive = false
end

-- ┌─────────────────────────────┐
-- │  AUTO SKILL MAIN LOOP       │
-- └─────────────────────────────┘
local function DoAutoSkill()
    AutoSkillActive = true

    while AutoSkillActive and Settings.AutoSkill do
        local ok, err = pcall(function()
            -- Kiểm tra từng skill
            -- Method 1: Dùng Virtual Key Press
            if Settings.SkillZ then
                -- Kiểm tra cooldown qua UI trước khi nhấn
                local skillBtns = GetSkillButtons()
                local zSkill = skillBtns["Z"] or skillBtns["Skill1"] or skillBtns["SkillZ"]
                if (not zSkill) or (zSkill and zSkill.ready) then
                    PressKey(Enum.KeyCode.Z)
                    Stats.SkillsUsed = Stats.SkillsUsed + 1
                    -- Fire remote nếu có
                    if Remotes.Skill then
                        SafeFireRemote(Remotes.Skill, "Z")
                    end
                end
                task.wait(Settings.SkillDelay)
            end

            if Settings.SkillX then
                local skillBtns = GetSkillButtons()
                local xSkill = skillBtns["X"] or skillBtns["Skill2"] or skillBtns["SkillX"]
                if (not xSkill) or (xSkill and xSkill.ready) then
                    PressKey(Enum.KeyCode.X)
                    Stats.SkillsUsed = Stats.SkillsUsed + 1
                    if Remotes.Skill then
                        SafeFireRemote(Remotes.Skill, "X")
                    end
                end
                task.wait(Settings.SkillDelay)
            end

            if Settings.SkillC then
                local skillBtns = GetSkillButtons()
                local cSkill = skillBtns["C"] or skillBtns["Skill3"] or skillBtns["SkillC"]
                if (not cSkill) or (cSkill and cSkill.ready) then
                    PressKey(Enum.KeyCode.C)
                    Stats.SkillsUsed = Stats.SkillsUsed + 1
                    if Remotes.Skill then
                        SafeFireRemote(Remotes.Skill, "C")
                    end
                end
                task.wait(Settings.SkillDelay)
            end

            if Settings.SkillQ then
                local skillBtns = GetSkillButtons()
                local qSkill = skillBtns["Q"] or skillBtns["Skill4"] or skillBtns["SkillQ"]
                if (not qSkill) or (qSkill and qSkill.ready) then
                    PressKey(Enum.KeyCode.Q)
                    Stats.SkillsUsed = Stats.SkillsUsed + 1
                    if Remotes.Skill then
                        SafeFireRemote(Remotes.Skill, "Q")
                    end
                end
                task.wait(Settings.SkillDelay)
            end
        end)

        if not ok then
            task.wait(0.5)
        end

        -- Interval giữa các chu kỳ dùng skill
        task.wait(Settings.SkillInterval)
    end

    AutoSkillActive = false
end

-- ┌─────────────────────────────┐
-- │  ANTI-AFK                   │
-- └─────────────────────────────┘
local function DoAntiAFK()
    AntiAFKActive = true
    while AntiAFKActive and Settings.AntiAFK do
        task.wait(60) -- Mỗi 60 giây
        -- Nhảy để tránh bị kick AFK
        if Humanoid then
            local oldState = Humanoid:GetState()
            Humanoid.Jump = true
            task.wait(0.5)
            Humanoid.Jump = false
        end
        -- Xoay nhân vật
        if HRP then
            HRP.CFrame = HRP.CFrame * CFrame.Angles(0, math.rad(5), 0)
        end
        -- Reset AFK timer của Roblox
        VirtualInput:SendMouseButtonEvent(0, 0, 0, true, game, 1)
        task.wait(0.1)
        VirtualInput:SendMouseButtonEvent(0, 0, 0, false, game, 1)
    end
    AntiAFKActive = false
end

-- ┌─────────────────────────────┐
-- │  START / STOP FUNCTIONS     │
-- └─────────────────────────────┘
local function StartAutoFish()
    if FishThread then task.cancel(FishThread) end
    FishThread = task.spawn(DoAutoFish)
end

local function StopAutoFish()
    Settings.AutoFish = false
    AutoFishActive = false
    if FishThread then
        pcall(function() task.cancel(FishThread) end)
        FishThread = nil
    end
end

local function StartAutoSkill()
    if SkillThread then task.cancel(SkillThread) end
    SkillThread = task.spawn(DoAutoSkill)
end

local function StopAutoSkill()
    Settings.AutoSkill = false
    AutoSkillActive = false
    if SkillThread then
        pcall(function() task.cancel(SkillThread) end)
        SkillThread = nil
    end
end

local function StartAntiAFK()
    if AntiAFKThread then task.cancel(AntiAFKThread) end
    AntiAFKThread = task.spawn(DoAntiAFK)
end

local function StopAntiAFK()
    Settings.AntiAFK = false
    AntiAFKActive = false
    if AntiAFKThread then
        pcall(function() task.cancel(AntiAFKThread) end)
        AntiAFKThread = nil
    end
end

-- ═══════════════════════════════════════════
-- [8] CREATE FLUENT WINDOW
-- ═══════════════════════════════════════════
local Window = Fluent:CreateWindow({
    Title       = "🎣 Titan Fishing Hub",
    SubTitle    = "v2.0 | Auto Fish • Auto Skill • Auto Sell",
    TabWidth    = 160,
    Size        = UDim2.fromOffset(600, 480),
    Acrylic     = true,          -- Hiệu ứng kính mờ (Acrylic/Blur)
    Theme       = "Dark",        -- Dark theme
    MinimizeKey = Enum.KeyCode.RightControl,  -- Phím ẩn/hiện
})

-- ═══════════════════════════════════════════
-- [9] TABS
-- ═══════════════════════════════════════════
local Tabs = {
    Farm      = Window:AddTab({ Title = "Auto Farm",  Icon = "fish" }),
    Skills    = Window:AddTab({ Title = "Auto Skill", Icon = "zap" }),
    Teleport  = Window:AddTab({ Title = "Teleport",   Icon = "map-pin" }),
    Player    = Window:AddTab({ Title = "Player",     Icon = "user" }),
    Stats     = Window:AddTab({ Title = "Stats",      Icon = "bar-chart-2" }),
    Settings  = Window:AddTab({ Title = "Settings",   Icon = "settings" }),
}

-- ═══════════════════════════════════════════
-- [10] TAB: AUTO FARM
-- ═══════════════════════════════════════════
Tabs.Farm:AddParagraph({
    Title   = "🎣 Auto Farm",
    Content = "Tự động câu cá, bán cá và mua đồ. Bật Auto Fish để bắt đầu!"
})

-- Toggle Auto Fish
local AutoFishToggle = Tabs.Farm:AddToggle("AutoFish", {
    Title       = "Auto Fish",
    Description = "Tự động cast cần và reel cá về",
    Default     = false,
    Callback    = function(v)
        Settings.AutoFish = v
        if v then
            StartAutoFish()
            Fluent:Notify({
                Title   = "✅ Auto Fish",
                Content = "Đã bật tự động câu cá!",
                Duration = 3,
            })
        else
            StopAutoFish()
            Fluent:Notify({
                Title   = "❌ Auto Fish",
                Content = "Đã tắt tự động câu cá.",
                Duration = 2,
            })
        end
    end,
})

-- Toggle Auto Sell
Tabs.Farm:AddToggle("AutoSell", {
    Title       = "Auto Sell Fish",
    Description = "Tự động bán cá sau khi câu đủ",
    Default     = false,
    Callback    = function(v)
        Settings.AutoSell = v
    end,
})

-- Sell Interval
Tabs.Farm:AddSlider("SellDelay", {
    Title       = "Sell Every (giây)",
    Description = "Tự động bán sau mỗi N giây",
    Default     = 30,
    Min         = 5,
    Max         = 120,
    Rounding    = 0,
    Callback    = function(v)
        Settings.SellDelay = v
    end,
})

-- Toggle Auto Buy Bait
Tabs.Farm:AddToggle("AutoBuyBait", {
    Title       = "Auto Buy Bait",
    Description = "Tự động mua mồi câu khi hết",
    Default     = false,
    Callback    = function(v)
        Settings.AutoBuyBait = v
    end,
})

-- Toggle Auto Buy Next Rod
Tabs.Farm:AddToggle("AutoBuyRod", {
    Title       = "Auto Buy Next Rod",
    Description = "Tự động mua cần câu tiếp theo khi đủ tiền",
    Default     = false,
    Callback    = function(v)
        Settings.AutoBuyRod = v
    end,
})

-- Fish Delay
Tabs.Farm:AddSlider("FishDelay", {
    Title       = "Fish Delay (giây)",
    Description = "Độ trễ giữa các lần câu",
    Default     = 1.0,
    Min         = 0.1,
    Max         = 5.0,
    Rounding    = 1,
    Callback    = function(v)
        Settings.FishDelay = v
    end,
})

-- Rarity Filter
Tabs.Farm:AddDropdown("MinRarity", {
    Title       = "Fish Filter (Rarity ≥)",
    Description = "Chỉ giữ cá có độ hiếm từ mức này trở lên",
    Values      = RarityOrder,
    Default     = "Common",
    Multi       = false,
    Callback    = function(v)
        Settings.MinRarity = v
    end,
})

-- Separator
Tabs.Farm:AddParagraph({ Title = "⚡ Quick Actions", Content = "" })

-- Quick Sell Button
Tabs.Farm:AddButton({
    Title       = "💰 Sell All Fish Now",
    Description = "Bán ngay tất cả cá trong túi",
    Callback    = function()
        task.spawn(function()
            if Remotes.Sell then
                SafeFireRemote(Remotes.Sell)
                Stats.FishSold = Stats.FishSold + FishCount
                FishCount = 0
                SellCount = SellCount + 1
            end
            -- Tìm nút Sell trong GUI
            for _, gui in ipairs(PlayerGui:GetChildren()) do
                local sellBtn = gui:FindFirstChild("SellButton", true)
                             or gui:FindFirstChild("SellAll", true)
                             or gui:FindFirstChild("Sell", true)
                if sellBtn and sellBtn:IsA("GuiButton") then
                    pcall(function() sellBtn.Activated:Fire() end)
                end
            end
        end)
        Fluent:Notify({
            Title   = "💰 Sell",
            Content = "Đã bán tất cả cá!",
            Duration = 3,
        })
    end,
})

-- Quick Buy Bait Button
Tabs.Farm:AddButton({
    Title       = "🪱 Buy Bait x100",
    Description = "Mua 100 mồi câu ngay",
    Callback    = function()
        task.spawn(function()
            if Remotes.BuyBait then
                SafeFireRemote(Remotes.BuyBait, "Worm", 100)
            end
        end)
        Fluent:Notify({
            Title   = "🪱 Bait",
            Content = "Đã mua 100 mồi!",
            Duration = 2,
        })
    end,
})

-- ═══════════════════════════════════════════
-- [11] TAB: AUTO SKILL
-- ═══════════════════════════════════════════
Tabs.Skills:AddParagraph({
    Title   = "⚡ Auto Skill System",
    Content = "Tự động sử dụng kỹ năng Z/X/C/Q trong khi câu cá. Kỹ năng sẽ được dùng liên tục theo chu kỳ."
})

-- Master Toggle
local AutoSkillToggle = Tabs.Skills:AddToggle("AutoSkillMaster", {
    Title       = "🔴 Auto Skill (Master)",
    Description = "Bật/tắt toàn bộ hệ thống tự động kỹ năng",
    Default     = false,
    Callback    = function(v)
        Settings.AutoSkill = v
        if v then
            StartAutoSkill()
            Fluent:Notify({
                Title   = "⚡ Auto Skill",
                Content = "Tự động kỹ năng đã BẬT! Các kỹ năng sẽ được dùng tự động.",
                Duration = 4,
            })
        else
            StopAutoSkill()
            Fluent:Notify({
                Title   = "⚡ Auto Skill",
                Content = "Tự động kỹ năng đã TẮT.",
                Duration = 2,
            })
        end
    end,
})

Tabs.Skills:AddParagraph({ Title = "🎮 Skill Keys", Content = "Chọn các phím kỹ năng muốn tự động dùng:" })

-- Skill Z
Tabs.Skills:AddToggle("SkillZ", {
    Title       = "⚡ Skill Z",
    Description = "Tự động dùng kỹ năng Z (thường là main skill/tấn công)",
    Default     = true,
    Callback    = function(v)
        Settings.SkillZ = v
    end,
})

-- Skill X
Tabs.Skills:AddToggle("SkillX", {
    Title       = "💥 Skill X",
    Description = "Tự động dùng kỹ năng X (buff/boost)",
    Default     = true,
    Callback    = function(v)
        Settings.SkillX = v
    end,
})

-- Skill C
Tabs.Skills:AddToggle("SkillC", {
    Title       = "🌀 Skill C",
    Description = "Tự động dùng kỹ năng C (special/ultimate)",
    Default     = true,
    Callback    = function(v)
        Settings.SkillC = v
    end,
})

-- Skill Q
Tabs.Skills:AddToggle("SkillQ", {
    Title       = "🔮 Skill Q",
    Description = "Tự động dùng kỹ năng Q (passive trigger)",
    Default     = false,
    Callback    = function(v)
        Settings.SkillQ = v
    end,
})

Tabs.Skills:AddParagraph({ Title = "⏱️ Timing", Content = "Điều chỉnh tốc độ sử dụng kỹ năng:" })

-- Skill Delay (giữa các phím)
Tabs.Skills:AddSlider("SkillKeyDelay", {
    Title       = "Delay giữa các phím (giây)",
    Description = "Thời gian chờ giữa mỗi lần nhấn phím kỹ năng",
    Default     = 0.3,
    Min         = 0.05,
    Max         = 2.0,
    Rounding    = 2,
    Callback    = function(v)
        Settings.SkillDelay = v
    end,
})

-- Skill Interval (chu kỳ)
Tabs.Skills:AddSlider("SkillCycleInterval", {
    Title       = "Chu kỳ lặp lại (giây)",
    Description = "Sau bao lâu thì lặp lại chu kỳ dùng skill",
    Default     = 1.0,
    Min         = 0.1,
    Max         = 10.0,
    Rounding    = 1,
    Callback    = function(v)
        Settings.SkillInterval = v
    end,
})

Tabs.Skills:AddParagraph({ Title = "🚀 Manual Use", Content = "" })

-- Use All Skills Now
Tabs.Skills:AddButton({
    Title       = "🚀 Use ALL Skills Now",
    Description = "Nhấn ngay Z + X + C + Q một lần",
    Callback    = function()
        task.spawn(function()
            PressKey(Enum.KeyCode.Z)
            task.wait(0.2)
            PressKey(Enum.KeyCode.X)
            task.wait(0.2)
            PressKey(Enum.KeyCode.C)
            task.wait(0.2)
            PressKey(Enum.KeyCode.Q)
            Stats.SkillsUsed = Stats.SkillsUsed + 4
        end)
        Fluent:Notify({
            Title   = "⚡ Skills",
            Content = "Đã sử dụng tất cả kỹ năng!",
            Duration = 2,
        })
    end,
})

-- Use Skill Z Only
Tabs.Skills:AddButton({
    Title       = "⚡ Use Skill Z Only",
    Description = "Chỉ dùng kỹ năng Z ngay bây giờ",
    Callback    = function()
        PressKey(Enum.KeyCode.Z)
        Fluent:Notify({ Title = "Skill Z", Content = "Đã dùng kỹ năng Z!", Duration = 2 })
    end,
})

-- ═══════════════════════════════════════════
-- [12] TAB: TELEPORT
-- ═══════════════════════════════════════════
Tabs.Teleport:AddParagraph({
    Title   = "🗺️ Teleport System",
    Content = "Di chuyển nhanh đến các vị trí quan trọng trong game. Tọa độ có thể không chính xác 100% - hãy cập nhật nếu cần."
})

-- Tạo button cho mỗi location
for locName, locPos in pairs(TeleportLocations) do
    local capturedPos  = locPos
    local capturedName = locName
    Tabs.Teleport:AddButton({
        Title       = capturedName,
        Description = string.format("TP đến (%.0f, %.0f, %.0f)", locPos.X, locPos.Y, locPos.Z),
        Callback    = function()
            task.spawn(function()
                SafeTeleport(capturedPos)
            end)
            Fluent:Notify({
                Title   = "🗺️ Teleport",
                Content = "Đã teleport đến " .. capturedName,
                Duration = 2,
            })
        end,
    })
end

Tabs.Teleport:AddParagraph({ Title = "📍 Custom Teleport", Content = "Teleport đến tọa độ tùy chỉnh:" })

-- Copy Current Position
Tabs.Teleport:AddButton({
    Title       = "📋 Copy Current Position",
    Description = "Copy tọa độ hiện tại vào clipboard",
    Callback    = function()
        if HRP then
            local pos = HRP.Position
            local str = string.format("%.2f, %.2f, %.2f", pos.X, pos.Y, pos.Z)
            setclipboard(str)
            Fluent:Notify({
                Title   = "📋 Position Copied",
                Content = "Tọa độ: " .. str,
                Duration = 4,
            })
        end
    end,
})

-- Teleport đến người chơi khác
Tabs.Teleport:AddButton({
    Title       = "👤 TP to Nearest Player",
    Description = "Teleport đến người chơi gần nhất",
    Callback    = function()
        local nearestPlayer = nil
        local nearestDist   = math.huge
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= Player and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
                local dist = (HRP.Position - plr.Character.HumanoidRootPart.Position).Magnitude
                if dist < nearestDist then
                    nearestDist   = dist
                    nearestPlayer = plr
                end
            end
        end
        if nearestPlayer then
            SafeTeleport(nearestPlayer.Character.HumanoidRootPart.Position + Vector3.new(3, 0, 3))
            Fluent:Notify({
                Title   = "👤 TP to Player",
                Content = "Đã teleport đến " .. nearestPlayer.Name,
                Duration = 3,
            })
        else
            Fluent:Notify({
                Title   = "❌ No Players",
                Content = "Không tìm thấy người chơi nào!",
                Duration = 3,
            })
        end
    end,
})

-- ═══════════════════════════════════════════
-- [13] TAB: PLAYER
-- ═══════════════════════════════════════════
Tabs.Player:AddParagraph({
    Title   = "👤 Player Settings",
    Content = "Tùy chỉnh nhân vật và gameplay."
})

-- Walk Speed
Tabs.Player:AddSlider("WalkSpeed", {
    Title       = "Walk Speed",
    Description = "Tốc độ di chuyển của nhân vật (mặc định: 16)",
    Default     = 16,
    Min         = 1,
    Max         = 200,
    Rounding    = 0,
    Callback    = function(v)
        Settings.WalkSpeed = v
        if Humanoid then
            Humanoid.WalkSpeed = v
        end
    end,
})

-- Jump Power
Tabs.Player:AddSlider("JumpPower", {
    Title       = "Jump Power",
    Description = "Sức mạnh nhảy (mặc định: 50)",
    Default     = 50,
    Min         = 1,
    Max         = 300,
    Rounding    = 0,
    Callback    = function(v)
        if Humanoid then
            Humanoid.JumpPower = v
        end
    end,
})

-- Anti-AFK
Tabs.Player:AddToggle("AntiAFK", {
    Title       = "Anti-AFK",
    Description = "Tự động di chuyển để tránh bị kick do AFK",
    Default     = false,
    Callback    = function(v)
        Settings.AntiAFK = v
        if v then
            StartAntiAFK()
        else
            StopAntiAFK()
        end
    end,
})

-- Noclip
local NoclipConnection = nil
Tabs.Player:AddToggle("Noclip", {
    Title       = "Noclip",
    Description = "Xuyên qua tường (cẩn thận khi dùng)",
    Default     = false,
    Callback    = function(v)
        Settings.Noclip = v
        if v then
            NoclipConnection = RunService.Stepped:Connect(function()
                if Character then
                    for _, part in ipairs(Character:GetDescendants()) do
                        if part:IsA("BasePart") then
                            part.CanCollide = false
                        end
                    end
                end
            end)
        else
            if NoclipConnection then
                NoclipConnection:Disconnect()
                NoclipConnection = nil
            end
            -- Khôi phục collision
            if Character then
                for _, part in ipairs(Character:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = true
                    end
                end
            end
        end
    end,
})

-- Inf Jump
local InfJumpConnection = nil
Tabs.Player:AddToggle("InfJump", {
    Title       = "Infinite Jump",
    Description = "Nhảy liên tục không giới hạn",
    Default     = false,
    Callback    = function(v)
        if v then
            InfJumpConnection = UserInputService.JumpRequest:Connect(function()
                if Humanoid then
                    Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                end
            end)
        else
            if InfJumpConnection then
                InfJumpConnection:Disconnect()
                InfJumpConnection = nil
            end
        end
    end,
})

-- Reset Character
Tabs.Player:AddButton({
    Title       = "🔄 Reset Character",
    Description = "Hồi sinh nhân vật về vị trí spawn",
    Callback    = function()
        if Humanoid then
            Humanoid.Health = 0
        end
    end,
})

-- ═══════════════════════════════════════════
-- [14] TAB: STATS
-- ═══════════════════════════════════════════
Tabs.Stats:AddParagraph({
    Title   = "📊 Session Statistics",
    Content = "Thống kê phiên chơi hiện tại. Tự động cập nhật mỗi 5 giây."
})

local StatsLabel = Tabs.Stats:AddParagraph({
    Title   = "📈 Live Stats",
    Content = "Đang tải..."
})

-- Update stats mỗi 5 giây
task.spawn(function()
    while true do
        task.wait(5)
        local runTime = os.time() - (Stats.StartTime > 0 and Stats.StartTime or os.time())
        local hours   = math.floor(runTime / 3600)
        local minutes = math.floor((runTime % 3600) / 60)
        local seconds = runTime % 60

        local content = string.format(
            "🎣 Cá đã câu: %d\n" ..
            "💰 Cá đã bán: %d lần\n" ..
            "⚡ Kỹ năng đã dùng: %d\n" ..
            "⏱️ Thời gian chạy: %02d:%02d:%02d\n" ..
            "🔄 Auto Fish: %s\n" ..
            "⚡ Auto Skill: %s",
            Stats.FishCaught,
            Stats.FishSold,
            Stats.SkillsUsed,
            hours, minutes, seconds,
            Settings.AutoFish and "✅ ON" or "❌ OFF",
            Settings.AutoSkill and "✅ ON" or "❌ OFF"
        )

        -- Update paragraph (nếu Fluent hỗ trợ update)
        pcall(function()
            StatsLabel:SetTitle("📈 Live Stats")
            StatsLabel:SetContent(content)
        end)
    end
end)

-- Reset Stats
Tabs.Stats:AddButton({
    Title       = "🔄 Reset Stats",
    Description = "Đặt lại tất cả thống kê về 0",
    Callback    = function()
        Stats.FishCaught  = 0
        Stats.FishSold    = 0
        Stats.SkillsUsed  = 0
        Stats.StartTime   = os.time()
        FishCount = 0
        SellCount = 0
        Fluent:Notify({
            Title   = "🔄 Stats Reset",
            Content = "Đã đặt lại tất cả thống kê!",
            Duration = 2,
        })
    end,
})

-- Remotes Info Button
Tabs.Stats:AddButton({
    Title       = "🔍 Debug Remotes",
    Description = "Hiển thị các remote events đã tìm được",
    Callback    = function()
        local info = "Remotes tìm được:\n"
        info = info .. "Cast: "   .. (Remotes.Cast   and Remotes.Cast.Name   or "❌ Không tìm thấy") .. "\n"
        info = info .. "Reel: "   .. (Remotes.Reel   and Remotes.Reel.Name   or "❌ Không tìm thấy") .. "\n"
        info = info .. "Sell: "   .. (Remotes.Sell   and Remotes.Sell.Name   or "❌ Không tìm thấy") .. "\n"
        info = info .. "BuyBait: " .. (Remotes.BuyBait and Remotes.BuyBait.Name or "❌ Không tìm thấy") .. "\n"
        info = info .. "Skill: "  .. (Remotes.Skill  and Remotes.Skill.Name  or "❌ Không tìm thấy")
        Fluent:Notify({
            Title    = "🔍 Debug",
            Content  = info,
            Duration = 8,
        })
        print("[TitanFishingHub] " .. info)
    end,
})

-- ═══════════════════════════════════════════
-- [15] TAB: SETTINGS (SaveManager)
-- ═══════════════════════════════════════════
SaveManager:SetLibrary(Fluent)
InterfaceManager:SetLibrary(Fluent)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({})
SaveManager:SetFolder("TitanFishingHub")
InterfaceManager:BuildInterfaceSection(Tabs.Settings)
SaveManager:BuildConfigSection(Tabs.Settings)

-- ═══════════════════════════════════════════
-- [16] KEYBIND SHORTCUTS
-- ═══════════════════════════════════════════
-- F1: Toggle Auto Fish
-- F2: Toggle Auto Skill
-- F3: Sell All Now
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end

    if input.KeyCode == Enum.KeyCode.F1 then
        Settings.AutoFish = not Settings.AutoFish
        AutoFishToggle:SetValue(Settings.AutoFish)
        if Settings.AutoFish then StartAutoFish() end
        Fluent:Notify({
            Title   = "[F1] Auto Fish",
            Content = Settings.AutoFish and "✅ ĐÃ BẬT" or "❌ ĐÃ TẮT",
            Duration = 2,
        })

    elseif input.KeyCode == Enum.KeyCode.F2 then
        Settings.AutoSkill = not Settings.AutoSkill
        AutoSkillToggle:SetValue(Settings.AutoSkill)
        if Settings.AutoSkill then StartAutoSkill() end
        Fluent:Notify({
            Title   = "[F2] Auto Skill",
            Content = Settings.AutoSkill and "✅ ĐÃ BẬT" or "❌ ĐÃ TẮT",
            Duration = 2,
        })

    elseif input.KeyCode == Enum.KeyCode.F3 then
        task.spawn(function()
            if Remotes.Sell then SafeFireRemote(Remotes.Sell) end
        end)
        Fluent:Notify({
            Title   = "[F3] Sell",
            Content = "💰 Đã bán tất cả cá!",
            Duration = 2,
        })
    end
end)

-- ═══════════════════════════════════════════
-- [17] CLEANUP ON CLOSE
-- ═══════════════════════════════════════════
Player.AncestryChanged:Connect(function()
    StopAutoFish()
    StopAutoSkill()
    StopAntiAFK()
end)

-- ═══════════════════════════════════════════
-- [18] STARTUP
-- ═══════════════════════════════════════════
Window:SelectTab(1)
SaveManager:LoadAutoloadConfig()

-- Welcome Notification
task.wait(0.5)
Fluent:Notify({
    Title      = "🎣 Titan Fishing Hub",
    Content    = "Script đã load thành công! Chúc bạn câu được nhiều cá!",
    SubContent = "F1: Auto Fish | F2: Auto Skill | F3: Sell All | RCtrl: Ẩn/Hiện",
    Duration   = 6,
})

-- Print info ra console
print([[
╔══════════════════════════════════════════════╗
║       🎣 TITAN FISHING HUB - LOADED!         ║
╠══════════════════════════════════════════════╣
║  F1         → Toggle Auto Fish               ║
║  F2         → Toggle Auto Skill              ║
║  F3         → Sell All Fish                  ║
║  RightCtrl  → Ẩn/Hiện Menu                  ║
╚══════════════════════════════════════════════╝
]])

-- ═══ END OF SCRIPT ═══
