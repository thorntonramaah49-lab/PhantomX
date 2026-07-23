-- ⚡ Phantom X | Murders vs Sheriffs Duels | Red21 Games
warn("[Phantom X] Loading Rayfield...")

-- ════════════════════════════════════════
--  RAYFIELD UI LIBRARY
-- ════════════════════════════════════════
local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

-- ════════════════════════════════════════
--  SERVICES
-- ════════════════════════════════════════
local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService        = game:GetService("RunService")
local UserInputService  = game:GetService("UserInputService")
local TweenService      = game:GetService("TweenService")
local Lighting          = game:GetService("Lighting")
local Workspace         = game:GetService("Workspace")
local TeleportService   = game:GetService("TeleportService")
local HttpService       = game:GetService("HttpService")
local StarterGui        = game:GetService("StarterGui")

local LP  = Players.LocalPlayer
local Cam = Workspace.CurrentCamera
local PID = game.PlaceId

-- ════════════════════════════════════════
--  STATE
-- ════════════════════════════════════════
local S = {
    autoQueue=false, queueMode="1v1",
    autoAccept=false, autoVote=false, autoReturn=false,
    autoCollect=false, autoSpin=false, spinDelay=2,
    afk=false, autoRespawn=false, autoEquip=false, autoCharm=false,
    noCd=false, noDash=false,
    fly=false, flySpeed=80, noclip=false, skeleton=false,
    ws=16, jp=50, fpsBoost=false, antiLag=false,
    antiAfk=true,
    kills=0, wins=0, losses=0, streak=0, best=0, last=0, coins=0,
    t0=tick(),
}

-- ════════════════════════════════════════
--  REMOTE HELPERS
-- ════════════════════════════════════════
local RC = {}
local function GR(name)
    if RC[name] then return RC[name] end
    for _, v in ipairs(ReplicatedStorage:GetDescendants()) do
        if v.Name == name and (v:IsA("RemoteEvent") or v:IsA("RemoteFunction")) then
            RC[name] = v; return v
        end
    end
    return nil
end
local function FR(name, ...)
    local r = GR(name); if not r then return false end
    pcall(function()
        if r:IsA("RemoteEvent") then r:FireServer(...) else r:InvokeServer(...) end
    end); return true
end
local function FRA(names, ...)
    for _, n in ipairs(names) do FR(n, ...) end
end

-- ════════════════════════════════════════
--  NOTIFICATION HELPER
-- ════════════════════════════════════════
local function Notif(title, msg, dur)
    pcall(function()
        Rayfield:Notify({
            Title = title,
            Content = msg,
            Duration = dur or 4,
            Image = 4483362458,
        })
    end)
end

-- ════════════════════════════════════════
--  GAME FUNCTIONS
-- ════════════════════════════════════════
local function Root()  local c=LP.Character; return c and c:FindFirstChild("HumanoidRootPart") end
local function Hum()   local c=LP.Character; return c and c:FindFirstChildOfClass("Humanoid") end
local function TP(cf)  local r=Root(); if r then pcall(function() r.CFrame=cf end) end end

-- Fly
local fConn
local function StopFly()
    S.fly=false; if fConn then fConn:Disconnect(); fConn=nil end
    pcall(function()
        local r=Root(); if r then
            local b=r:FindFirstChild("PX_BV"); if b then b:Destroy() end
            local g=r:FindFirstChild("PX_BG"); if g then g:Destroy() end
        end
        local h=Hum(); if h then h.PlatformStand=false end
    end)
end
local function StartFly()
    StopFly(); S.fly=true
    local r=Root(); local h=Hum(); if not r or not h then return end
    h.PlatformStand=true
    local BV=Instance.new("BodyVelocity"); BV.Name="PX_BV"
    BV.MaxForce=Vector3.new(1e6,1e6,1e6); BV.Parent=r
    local BG=Instance.new("BodyGyro"); BG.Name="PX_BG"
    BG.MaxTorque=Vector3.new(1e6,1e6,1e6); BG.P=1e4; BG.Parent=r
    fConn=RunService.Heartbeat:Connect(function()
        if not S.fly then StopFly(); return end
        local d=Vector3.zero
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then d=d+Cam.CFrame.LookVector  end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then d=d-Cam.CFrame.LookVector  end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then d=d-Cam.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then d=d+Cam.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space)     then d=d+Vector3.new(0,1,0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then d=d-Vector3.new(0,1,0) end
        BV.Velocity=d.Magnitude>0 and d.Unit*S.flySpeed or Vector3.zero
        BG.CFrame=Cam.CFrame
    end)
end

-- Skeleton
local function Skeleton(on)
    S.skeleton=on
    pcall(function()
        local c=LP.Character; if not c then return end
        for _,v in ipairs(c:GetChildren()) do if v.Name=="PX_SB" then v:Destroy() end end
        for _,p in ipairs(c:GetDescendants()) do
            if p:IsA("BasePart") then
                p.Transparency=on and (p.Name=="HumanoidRootPart" and 1 or 0.94) or (p.Name=="HumanoidRootPart" and 1 or 0)
                if on then
                    local sb=Instance.new("SelectionBox"); sb.Name="PX_SB"
                    sb.Color3=Color3.fromRGB(180,120,255); sb.LineThickness=0.03
                    sb.Adornee=p; sb.Parent=c
                end
            end
        end
    end)
end

-- Cooldown zeroing
RunService.Heartbeat:Connect(function()
    if not S.noCd and not S.noDash then return end
    pcall(function()
        local c=LP.Character; if not c then return end
        for _,v in ipairs(c:GetDescendants()) do
            if (v:IsA("NumberValue") or v:IsA("IntValue")) and v.Value>0 then
                local n=v.Name:lower()
                if (S.noCd and (n:match("cool") or n:match("cd") or n:match("ability")))
                or (S.noDash and n:match("dash")) then v.Value=0 end
            end
        end
        if S.noCd then
            for _,a in ipairs({"Cooldown","DashCooldown","AbilityCooldown","CharmCooldown"}) do
                if LP:GetAttribute(a) and LP:GetAttribute(a)~=0 then LP:SetAttribute(a,0) end
            end
        end
    end)
end)

-- Anti-AFK
local afkT=tick()
RunService.Heartbeat:Connect(function()
    if not S.antiAfk then return end
    if tick()-afkT>55 then afkT=tick(); pcall(function() local h=Hum(); if h then h.Jump=true end end) end
end)

-- Noclip
RunService.Stepped:Connect(function()
    if not S.noclip then return end
    pcall(function()
        local c=LP.Character; if not c then return end
        for _,p in ipairs(c:GetDescendants()) do
            if p:IsA("BasePart") and p.CanCollide then p.CanCollide=false end
        end
    end)
end)

-- Respawn handler
LP.CharacterAdded:Connect(function(c)
    task.wait(1.5)
    local h=c:FindFirstChildOfClass("Humanoid"); if not h then return end
    h.WalkSpeed=S.ws; h.JumpPower=S.jp
    if S.skeleton then task.spawn(function() Skeleton(true) end) end
    if S.fly then task.wait(0.5); StartFly() end
    h.Died:Connect(function()
        if S.streak>0 then S.last=S.streak end
        S.losses+=1; S.streak=0
        if S.autoRespawn then task.wait(0.3); pcall(function() LP:LoadCharacter() end) end
    end)
end)

-- Queue helpers
local function FindPad(mode)
    local kw=mode:lower(); local r=Root(); if not r then return nil end
    local best,bd=nil,math.huge
    for _,v in ipairs(Workspace:GetDescendants()) do
        if v:IsA("BasePart") then
            local n=v.Name:lower()
            if n:match(kw) or n:match("queue") or n:match("pad") then
                local d=(v.Position-r.Position).Magnitude
                if d<bd then best=v; bd=d end
            end
        end
    end
    return best
end
local function JoinQueue()
    local pad=FindPad(S.queueMode)
    if pad then TP(CFrame.new(pad.Position+Vector3.new(0,4,0))) end
    FRA({"JoinQueue","QueueJoin","JoinMatch","EnterQueue","StartQueue"},S.queueMode)
end
local function Accept()
    FRA({"AcceptMatch","AcceptQueue","ReadyUp","ConfirmMatch"})
    for _,v in ipairs(LP.PlayerGui:GetDescendants()) do
        if v:IsA("TextButton") then
            local t=v.Text:lower()
            if t:match("accept") or t:match("ready") or t:match("confirm") then
                pcall(function() v.MouseButton1Click:Fire() end)
            end
        end
    end
end
local function Vote()
    FRA({"Vote","VoteMap","MapVote"},1)
    for _,v in ipairs(LP.PlayerGui:GetDescendants()) do
        if v:IsA("TextButton") and v.Text:lower():match("vote") then
            pcall(function() v.MouseButton1Click:Fire() end); break
        end
    end
end
local function ToLobby()
    FRA({"ReturnToLobby","BackToLobby","LeaveLobby","Lobby"})
    for _,v in ipairs(LP.PlayerGui:GetDescendants()) do
        if v:IsA("TextButton") then
            local t=v.Text:lower()
            if t:match("lobby") or t:match("leave") or t:match("return") then
                pcall(function() v.MouseButton1Click:Fire() end); break
            end
        end
    end
end
local function Daily()
    FRA({"ClaimDaily","DailyReward","ClaimReward"})
    for _,v in ipairs(LP.PlayerGui:GetDescendants()) do
        if v:IsA("TextButton") then
            local t=v.Text:lower()
            if t:match("daily") or t:match("claim") then
                pcall(function() v.MouseButton1Click:Fire() end)
                Notif("Daily", "Reward claimed!"); return
            end
        end
    end
end
local function Spin()
    FRA({"OpenCrate","SpinCrate","Spin","OpenCase","SpinCase","OpenBox"})
    for _,v in ipairs(LP.PlayerGui:GetDescendants()) do
        if v:IsA("TextButton") then
            local t=v.Text:lower()
            if t:match("spin") or t:match("open") or t:match("crate") then
                pcall(function() v.MouseButton1Click:Fire() end); return
            end
        end
    end
end
local function EquipBest()
    FRA({"EquipBest","EquipWeapon","AutoEquip"})
    local bp=LP:FindFirstChild("Backpack"); local h=Hum()
    if bp and h then
        local tools=bp:GetChildren()
        table.sort(tools,function(a,b)
            return (a:GetAttribute("Power") or a:GetAttribute("Damage") or 0)>
                   (b:GetAttribute("Power") or b:GetAttribute("Damage") or 0)
        end)
        if tools[1] then pcall(function() h:EquipTool(tools[1]) end); Notif("Weapon", tools[1].Name) end
    end
end
local function EquipCharm()
    FRA({"EquipCharm","UseCharm","ActivateCharm"})
    local bp=LP:FindFirstChild("Backpack"); local h=Hum()
    if bp and h then
        for _,v in ipairs(bp:GetChildren()) do
            if v.Name:lower():match("charm") then
                pcall(function() h:EquipTool(v) end); Notif("Charm", v.Name); return
            end
        end
    end
end
local function Collect()
    local r=Root(); if not r then return end
    for _,v in ipairs(Workspace:GetDescendants()) do
        if v:IsA("BasePart") then
            local n=v.Name:lower()
            if n:match("coin") or n:match("pickup") or n:match("gem") or n:match("collect") then
                if (v.Position-r.Position).Magnitude<60 then
                    TP(CFrame.new(v.Position+Vector3.new(0,3,0))); task.wait(0.05)
                end
            end
        end
    end
end
local function GiveCoins(amt)
    FRA({"GiveCoins","AddCoins","GrantCoins","GiveCash","AddCash","GrantCash","CoinReward","EarnCoins","AddMoney"},amt)
    pcall(function()
        local ls=LP:FindFirstChild("leaderstats")
        if ls then for _,v in ipairs(ls:GetChildren()) do
            if v:IsA("IntValue") or v:IsA("NumberValue") then v.Value+=amt end
        end end
    end)
    Notif("Coins", "+"..amt.." sent!")
end
local function RegainStreak()
    if S.last<=0 then Notif("Streak","No previous streak."); return end
    FRA({"SetStreak","RestoreStreak","SetWinStreak"},S.last)
    pcall(function()
        LP:SetAttribute("Streak",S.last); LP:SetAttribute("WinStreak",S.last)
        local ls=LP:FindFirstChild("leaderstats")
        if ls then for _,v in ipairs(ls:GetChildren()) do
            if v.Name:lower():match("streak") then v.Value=S.last end
        end end
    end)
    Notif("Streak","Restored "..S.last)
end
local function Hop()
    Notif("Server Hop","Finding new server...")
    local ok,data=pcall(function()
        return HttpService:JSONDecode(game:HttpGet(
            "https://games.roblox.com/v1/games/"..PID.."/servers/Public?sortOrder=Asc&limit=100",true))
    end)
    if ok and data and data.data then
        for _,srv in ipairs(data.data) do
            if srv.id~=game.JobId and srv.playing<srv.maxPlayers then
                pcall(function() TeleportService:TeleportToPlaceInstance(PID,srv.id,LP) end); return
            end
        end
    end
    pcall(function() TeleportService:Teleport(PID,LP) end)
end
local function FPSBoost(on)
    S.fpsBoost=on
    pcall(function()
        Lighting.GlobalShadows=not on
        for _,v in ipairs(Lighting:GetChildren()) do
            if v:IsA("PostEffect") or v:IsA("Atmosphere") or v:IsA("Sky") then
                pcall(function() v.Enabled=not on end)
            end
        end
        for _,v in ipairs(Workspace:GetDescendants()) do
            if v:IsA("ParticleEmitter") or v:IsA("Fire") or v:IsA("Smoke") then
                pcall(function() v.Enabled=not on end)
            end
        end
    end)
    Notif("FPS Boost", on and "Enabled!" or "Disabled.")
end

-- Leaderstats watcher
task.spawn(function()
    local ls=LP:WaitForChild("leaderstats",15); if not ls then return end
    for _,v in ipairs(ls:GetChildren()) do
        if v:IsA("IntValue") or v:IsA("NumberValue") then
            v.Changed:Connect(function(val)
                local n=v.Name:lower()
                if n:match("kill") then S.kills=val end
                if n:match("win") and val>S.wins then
                    S.wins=val; S.streak+=1
                    if S.streak>S.best then S.best=S.streak end
                    Notif("Win!", "Streak: "..S.streak)
                end
                if n:match("coin") or n:match("cash") or n:match("gem") then S.coins=val end
                if n:match("streak") then S.streak=val end
            end)
        end
    end
end)

-- ════════════════════════════════════════
--  BUILD RAYFIELD WINDOW
-- ════════════════════════════════════════
local Window = Rayfield:CreateWindow({
    Name = "Phantom X",
    LoadingTitle = "Phantom X",
    LoadingSubtitle = "Murders vs Sheriffs Duels",
    ConfigurationSaving = { Enabled = false },
    Discord = { Enabled = false },
    KeySystem = false,
})

-- ── AUTO FARM TAB ─────────────────────
local FarmTab = Window:CreateTab("Auto Farm", 4483362458)

FarmTab:CreateSection("Automation")

FarmTab:CreateToggle({
    Name = "Auto Farm (All-in-One)",
    CurrentValue = false,
    Flag = "AutoFarm",
    Callback = function(v)
        S.autoQueue=v; S.autoAccept=v; S.autoVote=v; S.autoCollect=v; S.autoReturn=v
        Notif("Auto Farm", v and "All automation ON" or "Turned OFF")
    end,
})
FarmTab:CreateToggle({
    Name = "Auto Queue",
    CurrentValue = false,
    Flag = "AutoQueue",
    Callback = function(v) S.autoQueue=v end,
})
FarmTab:CreateToggle({
    Name = "Auto Accept Match",
    CurrentValue = false,
    Flag = "AutoAccept",
    Callback = function(v) S.autoAccept=v end,
})
FarmTab:CreateToggle({
    Name = "Auto Vote",
    CurrentValue = false,
    Flag = "AutoVote",
    Callback = function(v) S.autoVote=v end,
})
FarmTab:CreateToggle({
    Name = "Auto Return to Lobby",
    CurrentValue = false,
    Flag = "AutoReturn",
    Callback = function(v) S.autoReturn=v end,
})
FarmTab:CreateToggle({
    Name = "Auto Collect Pickups",
    CurrentValue = false,
    Flag = "AutoCollect",
    Callback = function(v) S.autoCollect=v end,
})
FarmTab:CreateToggle({
    Name = "Auto Spin Crates",
    CurrentValue = false,
    Flag = "AutoSpin",
    Callback = function(v) S.autoSpin=v end,
})
FarmTab:CreateToggle({
    Name = "AFK Farm Mode",
    CurrentValue = false,
    Flag = "AFKFarm",
    Callback = function(v) S.afk=v; S.autoQueue=v end,
})
FarmTab:CreateToggle({
    Name = "Auto Claim Daily Reward",
    CurrentValue = false,
    Flag = "AutoDaily",
    Callback = function(v) if v then task.spawn(Daily) end end,
})
FarmTab:CreateDropdown({
    Name = "Queue Mode",
    Options = {"1v1","2v2","3v3","4v4"},
    CurrentOption = {"1v1"},
    Flag = "QueueMode",
    Callback = function(v) S.queueMode=v[1] or v end,
})

FarmTab:CreateSection("Manual")
FarmTab:CreateButton({ Name = "Join Queue Now",       Callback = function() JoinQueue(); Notif("Queue","Fired!") end })
FarmTab:CreateButton({ Name = "Accept Match Now",     Callback = function() Accept() end })
FarmTab:CreateButton({ Name = "Vote Now",             Callback = function() Vote() end })
FarmTab:CreateButton({ Name = "Return to Lobby",      Callback = function() ToLobby() end })
FarmTab:CreateButton({ Name = "Claim Daily Reward",   Callback = function() Daily() end })
FarmTab:CreateButton({ Name = "Spin Crate Now",       Callback = function() Spin(); Notif("Crate","Fired!") end })

-- ── COMBAT TAB ────────────────────────
local CombatTab = Window:CreateTab("Combat", 4483362458)

CombatTab:CreateSection("Abilities")
CombatTab:CreateToggle({
    Name = "No Ability Cooldown",
    CurrentValue = false,
    Flag = "NoCd",
    Callback = function(v) S.noCd=v; Notif("Cooldown", v and "Instant!" or "Normal") end,
})
CombatTab:CreateToggle({
    Name = "No Dash Cooldown",
    CurrentValue = false,
    Flag = "NoDash",
    Callback = function(v) S.noDash=v end,
})

CombatTab:CreateSection("Weapons")
CombatTab:CreateToggle({
    Name = "Auto Equip Best Weapon",
    CurrentValue = false,
    Flag = "AutoEquip",
    Callback = function(v) S.autoEquip=v; if v then EquipBest() end end,
})
CombatTab:CreateToggle({
    Name = "Auto Equip Charm",
    CurrentValue = false,
    Flag = "AutoCharm",
    Callback = function(v) S.autoCharm=v; if v then EquipCharm() end end,
})
CombatTab:CreateButton({ Name = "Equip Best Weapon Now", Callback = function() EquipBest() end })
CombatTab:CreateButton({ Name = "Equip Best Charm Now",  Callback = function() EquipCharm() end })

-- ── COINS TAB ─────────────────────────
local CoinsTab = Window:CreateTab("Coins", 4483362458)

CoinsTab:CreateSection("Currency")
local coinAmt = 50000
CoinsTab:CreateSlider({
    Name = "Amount",
    Range = {1000, 500000},
    Increment = 1000,
    Suffix = " coins",
    CurrentValue = 50000,
    Flag = "CoinAmt",
    Callback = function(v) coinAmt=v end,
})
CoinsTab:CreateButton({ Name = "Give Coins", Callback = function() GiveCoins(coinAmt) end })

-- ── MOVEMENT TAB ──────────────────────
local MoveTab = Window:CreateTab("Movement", 4483362458)

MoveTab:CreateSection("Fly")
MoveTab:CreateToggle({
    Name = "Fly",
    CurrentValue = false,
    Flag = "Fly",
    Callback = function(v) if v then StartFly() else StopFly() end end,
})
MoveTab:CreateSlider({
    Name = "Fly Speed",
    Range = {10, 300},
    Increment = 5,
    CurrentValue = 80,
    Flag = "FlySpeed",
    Callback = function(v) S.flySpeed=v end,
})

MoveTab:CreateSection("Ground")
MoveTab:CreateToggle({
    Name = "Noclip",
    CurrentValue = false,
    Flag = "Noclip",
    Callback = function(v) S.noclip=v end,
})
MoveTab:CreateSlider({
    Name = "Walk Speed",
    Range = {16, 300},
    Increment = 1,
    CurrentValue = 16,
    Flag = "WalkSpeed",
    Callback = function(v) S.ws=v; local h=Hum(); if h then h.WalkSpeed=v end end,
})
MoveTab:CreateSlider({
    Name = "Jump Power",
    Range = {50, 300},
    Increment = 5,
    CurrentValue = 50,
    Flag = "JumpPower",
    Callback = function(v) S.jp=v; local h=Hum(); if h then h.JumpPower=v end end,
})

MoveTab:CreateSection("Teleport")
MoveTab:CreateButton({ Name = "Teleport to Spawn", Callback = function()
    local sp=Workspace:FindFirstChildOfClass("SpawnLocation")
    if sp then TP(sp.CFrame+Vector3.new(0,5,0)); Notif("Teleport","At spawn!") else Notif("Teleport","No spawn found.") end
end })

-- ── VISUALS TAB ───────────────────────
local VisualTab = Window:CreateTab("Visuals", 4483362458)

VisualTab:CreateSection("Character")
VisualTab:CreateToggle({
    Name = "Skeleton Mode",
    CurrentValue = false,
    Flag = "Skeleton",
    Callback = function(v) Skeleton(v); Notif("Skeleton", v and "ON" or "OFF") end,
})

VisualTab:CreateSection("Performance")
VisualTab:CreateToggle({
    Name = "FPS Boost",
    CurrentValue = false,
    Flag = "FPSBoost",
    Callback = function(v) FPSBoost(v) end,
})
VisualTab:CreateToggle({
    Name = "Anti-Lag (hide textures)",
    CurrentValue = false,
    Flag = "AntiLag",
    Callback = function(v)
        S.antiLag=v
        if v then pcall(function()
            for _,t in ipairs(Workspace:GetDescendants()) do
                if t:IsA("Texture") or t:IsA("Decal") then t.Transparency=1 end
            end
        end); Notif("Anti-Lag","Textures hidden.") end
    end,
})

-- ── QOL TAB ───────────────────────────
local QoLTab = Window:CreateTab("QoL", 4483362458)

QoLTab:CreateSection("Quality of Life")
QoLTab:CreateToggle({
    Name = "Anti-AFK",
    CurrentValue = true,
    Flag = "AntiAFK",
    Callback = function(v) S.antiAfk=v end,
})
QoLTab:CreateToggle({
    Name = "Auto Respawn",
    CurrentValue = false,
    Flag = "AutoRespawn",
    Callback = function(v) S.autoRespawn=v end,
})
QoLTab:CreateButton({ Name = "Server Hop",  Callback = function() task.spawn(Hop) end })
QoLTab:CreateButton({ Name = "Rejoin Now",  Callback = function()
    Notif("Rejoin","Rejoining..."); task.wait(1)
    pcall(function() TeleportService:Teleport(PID,LP) end)
end })
QoLTab:CreateButton({ Name = "Dump All Remotes (output)", Callback = function()
    print("[PX] All RemoteEvents/Functions:")
    for _,v in ipairs(ReplicatedStorage:GetDescendants()) do
        if v:IsA("RemoteEvent") or v:IsA("RemoteFunction") then
            print("  ["..v.ClassName.."] "..v:GetFullName())
        end
    end
    Notif("Remotes","Printed to output!")
end })

-- ── STATS TAB ─────────────────────────
local StatsTab = Window:CreateTab("Stats", 4483362458)

StatsTab:CreateSection("Session Stats")
StatsTab:CreateButton({ Name = "Print Stats to Output", Callback = function()
    local e=math.floor(tick()-S.t0)
    print("═══ Phantom X Stats ═══")
    print("Kills: "..S.kills.." | Wins: "..S.wins.." | Losses: "..S.losses)
    print("Streak: "..S.streak.." | Best: "..S.best.." | Last: "..S.last)
    print("Coins: "..S.coins.." | Uptime: "..e.."s")
    Notif("Stats","Printed to output!")
end })
StatsTab:CreateButton({ Name = "Restore Last Streak", Callback = function() RegainStreak() end })
StatsTab:CreateButton({ Name = "Reset Session Stats", Callback = function()
    S.kills=0;S.wins=0;S.losses=0;S.streak=0;S.coins=0;S.t0=tick()
    Notif("Stats","Reset!")
end })

-- ════════════════════════════════════════
--  MAIN LOOP
-- ════════════════════════════════════════
local T={q=0,a=0,v=0,col=0,sp=0,eq=0,ch=0}
RunService.Heartbeat:Connect(function()
    local now=tick()
    if (S.autoQueue or S.afk) and now-T.q>8   then T.q=now; task.spawn(JoinQueue) end
    if S.autoAccept            and now-T.a>2   then T.a=now; Accept() end
    if S.autoVote              and now-T.v>3   then T.v=now; Vote() end
    if S.autoCollect           and now-T.col>2 then T.col=now; task.spawn(Collect) end
    if S.autoSpin              and now-T.sp>S.spinDelay then T.sp=now; Spin() end
    if S.autoEquip             and now-T.eq>5  then T.eq=now; task.spawn(EquipBest) end
    if S.autoCharm             and now-T.ch>5  then T.ch=now; task.spawn(EquipCharm) end
    if S.autoReturn then
        for _,v in ipairs(LP.PlayerGui:GetDescendants()) do
            if v:IsA("TextButton") then
                local t=v.Text:lower()
                if t:match("lobby") or t:match("return") then
                    pcall(function() v.MouseButton1Click:Fire() end)
                end
            end
        end
    end
end)

warn("[Phantom X] Ready!")
