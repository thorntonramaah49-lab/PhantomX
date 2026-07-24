-- ⚡ Phantom X | Murders vs Sheriffs Duels
-- WindUI edition — sidebar layout, mobile-ready
if getgenv().PhantomX_Loaded then
    print("[PX] Already loaded!")
    return
end
getgenv().PhantomX_Loaded = true

-- ════════════════════════════════════
--  SERVICES
-- ════════════════════════════════════
local Players      = game:GetService("Players")
local RunService   = game:GetService("RunService")
local RepStorage   = game:GetService("ReplicatedStorage")
local UIS          = game:GetService("UserInputService")
local TweenSvc     = game:GetService("TweenService")
local Lighting     = game:GetService("Lighting")
local WS           = game:GetService("Workspace")
local TpSvc        = game:GetService("TeleportService")
local HttpSvc      = game:GetService("HttpService")
local Debris       = game:GetService("Debris")
local StarterGui   = game:GetService("StarterGui")

local Player = Players.LocalPlayer
if not Player then
    Players:GetPropertyChangedSignal("LocalPlayer"):Wait()
    Player = Players.LocalPlayer
end
local Camera = WS.CurrentCamera
local PID    = game.PlaceId

-- ════════════════════════════════════
--  WIND UI
-- ════════════════════════════════════
local wind = loadstring(game:HttpGet(
    "https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"
))()

local window = wind:CreateWindow({
    Title              = "Phantom X",
    Icon               = "zap",
    Author             = "MvS Duels | v4.0",
    Folder             = "PhantomX",
    Size               = UDim2.fromOffset(620, 420),
    MinSize            = Vector2.new(440, 260),
    Transparent        = true,
    Theme              = "Dark",
    Resizable          = true,
    SideBarWidth       = 180,
    BackgroundImageTransparency = 0.45,
    HideSearchBar      = true,
    ScrollBarEnabled   = false,
    User = { Enabled = false },
})

window:EditOpenButton({
    Title         = "Phantom X",
    Icon          = "zap",
    CornerRadius  = UDim.new(0, 16),
    StrokeThickness = 2,
    Color         = ColorSequence.new(
        Color3.fromHex("0D0D1A"),
        Color3.fromHex("6C00FF")
    ),
    OnlyMobile    = false,
    Enabled       = true,
    Draggable     = true,
})

window:Tag({
    Title = "UNDETECTED",
    Icon  = "shield-check",
    Color = Color3.fromHex("#a855f7"),
    Radius = 5,
})

-- ════════════════════════════════════
--  GLOBAL STATE
-- ════════════════════════════════════
local G = {
    -- farm
    autoQueue=false, queueMode="1v1",
    autoAccept=false, autoVote=false, autoReturn=false,
    autoCollect=false, autoSpin=false, spinDelay=2,
    autoDaily=false,
    -- combat
    autoshoot=false, autoshootDist=300, autoshootCD=2.5,
    triggerbot=false, triggerbotCD=1,
    hitbox=false, hitboxSize=13,
    noGunCD=false, autoKnife=false, knifeDist=300, knifeCD=2,
    -- streak
    streakRegain=false, streakProtect=false,
    kills=0, wins=0, losses=0, streak=0, best=0, coins=0,
    -- movement
    fly=false, flySpeed=80,
    noclip=false, ws=16, jp=50,
    -- visual/esp
    espEnabled=false, espTeamColor=Color3.fromRGB(0,255,0), espEnemyColor=Color3.fromRGB(255,50,50),
    -- qol
    antiAfk=true, autoRespawn=false,
    -- internals
    inMatch=false, matchEnemies={},
}

-- ════════════════════════════════════
--  HELPERS
-- ════════════════════════════════════
local function Rt()  local c=Player.Character; return c and c:FindFirstChild("HumanoidRootPart") end
local function Hm()  local c=Player.Character; return c and c:FindFirstChildOfClass("Humanoid") end
local function TP(cf) local r=Rt(); if r then pcall(function() r.CFrame=cf end) end end

local RC={}
local function GR(n)
    if RC[n] then return RC[n] end
    for _,v in ipairs(RepStorage:GetDescendants()) do
        if v.Name==n and(v:IsA("RemoteEvent") or v:IsA("RemoteFunction")) then RC[n]=v; return v end
    end
end
local function FR(n,...) local r=GR(n); if not r then return end; pcall(function() if r:IsA("RemoteEvent") then r:FireServer(...) else r:InvokeServer(...) end end) end
local function FRA(t,...) for _,n in ipairs(t) do FR(n,...) end end

local function Notify(title, msg, dur)
    pcall(function() StarterGui:SetCore("SendNotification",{Title=title,Text=msg,Duration=dur or 4}) end)
end

local function getGun()
    local c=Player.Character; if not c then return end
    for _,t in ipairs(c:GetChildren()) do if t:IsA("Tool") and t:FindFirstChild("Fire",true) then return t end end
    local bp=Player.Backpack; if not bp then return end
    for _,t in ipairs(bp:GetChildren()) do if t:IsA("Tool") and t:FindFirstChild("Fire",true) then return t end end
end

local function BulletRenderer(s,e)
    local sp=Instance.new("Part"); sp.Size=Vector3.new(0.1,0.1,0.1); sp.Anchored=true; sp.CanCollide=false; sp.Transparency=1; sp.Position=s; sp.Parent=WS
    local ep=Instance.new("Part"); ep.Size=Vector3.new(0.1,0.1,0.1); ep.Anchored=true; ep.CanCollide=false; ep.Transparency=1; ep.Position=e; ep.Parent=WS
    local beam=Instance.new("Beam"); beam.Color=ColorSequence.new(Color3.fromHex("#a855f7")); beam.Width0=0; beam.Width1=0; beam.LightEmission=0.6; beam.FaceCamera=true; beam.Segments=1
    local a0=Instance.new("Attachment",sp); local a1=Instance.new("Attachment",ep); beam.Attachment0=a0; beam.Attachment1=a1; beam.Parent=sp
    TweenSvc:Create(beam,TweenInfo.new(0.05,Enum.EasingStyle.Cubic),{Width0=0.3,Width1=0.6}):Play()
    task.delay(0.05,function()
        TweenSvc:Create(beam,TweenInfo.new(0.1,Enum.EasingStyle.Cubic),{Width0=0,Width1=0}):Play()
    end)
    Debris:AddItem(sp,0.3); Debris:AddItem(ep,0.3)
end

-- ════════════════════════════════════
--  MATCH TRACKING
-- ════════════════════════════════════
task.spawn(function()
    while true do
        G.inMatch = (Player:GetAttribute("Match") ~= nil)
        local cur = Player:GetAttribute("Match")
        local tmp = {}
        if cur then
            for _,v in ipairs(Players:GetPlayers()) do
                if v~=Player and v:GetAttribute("Match")==cur then
                    local c=v.Character
                    if c and c:FindFirstChildOfClass("Humanoid") and c.Humanoid.Health>0 then
                        table.insert(tmp,v)
                    end
                end
            end
        end
        G.matchEnemies=tmp
        task.wait(0.1)
    end
end)

-- ════════════════════════════════════
--  COMBAT ENGINE
-- ════════════════════════════════════
local canShoot=true; local shootThread; local knifeThread

local function CharOrigin(char)
    local hrp=char and char:FindFirstChild("HumanoidRootPart"); if not hrp then return end
    return (hrp.CFrame*CFrame.new(0,0,hrp.Size.Z/2)).Position
end

local function ShootAt(target)
    if not canShoot then return end
    local myChar=Player.Character; if not myChar then return end
    local origin=CharOrigin(myChar); if not origin then return end
    local hit=target.Character and (target.Character:FindFirstChild("Head") or target.Character:FindFirstChild("HumanoidRootPart"))
    local tool=getGun(); if not tool or not hit then return end
    canShoot=false
    local startPos=(tool:FindFirstChild("Muzzle",true) and tool:FindFirstChild("Muzzle",true).WorldPosition) or origin
    BulletRenderer(startPos,hit.Position)
    pcall(function() RepStorage.Remotes.ShootGun:FireServer(origin,hit.Position,hit,hit.Position) end)
    local snd=tool:FindFirstChild("Fire",true); if snd and snd:IsA("Sound") then pcall(function() snd:Play() end) end
    task.delay(G.autoshootCD,function() canShoot=true end)
end

local function ThrowKnifeAt(target)
    local hit=target.Character and (target.Character:FindFirstChild("Head") or target.Character:FindFirstChild("HumanoidRootPart")); if not hit then return end
    pcall(function()
        RepStorage.Remotes.ThrowKnife:FireServer(hit.Position)
        local tool=Player.Character and Player.Character:FindFirstChildOfClass("Tool")
        if tool then local fly=tool:FindFirstChild("fly",true) or tool:FindFirstChild("Throw",true) if fly and fly:IsA("Sound") then fly:Play() end end
    end)
end

local function GetNearestEnemy(maxDist)
    local r=Rt(); if not r then return end
    local best,bd=nil,maxDist or math.huge
    for _,v in ipairs(G.matchEnemies) do
        local c=v.Character; if not c then continue end
        local hrp=c:FindFirstChild("HumanoidRootPart"); if not hrp then continue end
        local d=(hrp.Position-r.Position).Magnitude
        if d<bd then best=v; bd=d end
    end
    return best
end

-- autoshoot loop
local function StartAutoShoot()
    if shootThread then task.cancel(shootThread) end
    shootThread=task.spawn(function()
        while G.autoshoot do
            local e=GetNearestEnemy(G.autoshootDist)
            if e then ShootAt(e) end
            task.wait(0.1)
        end
    end)
end
local function StopAutoShoot() G.autoshoot=false; if shootThread then task.cancel(shootThread) end end

-- auto knife loop
local function StartAutoKnife()
    if knifeThread then task.cancel(knifeThread) end
    knifeThread=task.spawn(function()
        while G.autoKnife do
            local e=GetNearestEnemy(G.knifeDist)
            if e then ThrowKnifeAt(e) end
            task.wait(G.knifeCD)
        end
    end)
end
local function StopAutoKnife() G.autoKnife=false; if knifeThread then task.cancel(knifeThread) end end

-- hitbox
local hitboxConnections={}
local function ApplyHitbox(char)
    if not char then return end
    local hrp=char:FindFirstChild("HumanoidRootPart"); if not hrp then return end
    local h=Instance.new("Part"); h.Name="PX_Hitbox"; h.Size=Vector3.new(G.hitboxSize,G.hitboxSize,G.hitboxSize)
    h.Transparency=0.7; h.CanCollide=false; h.CFrame=hrp.CFrame; h.BrickColor=BrickColor.new("Bright red"); h.Material=Enum.Material.Neon
    h.Parent=char
    local w=Instance.new("Weld"); w.Part0=hrp; w.Part1=h; w.Parent=hrp
end
local function ClearHitboxes()
    for _,v in ipairs(WS:GetDescendants()) do if v.Name=="PX_Hitbox" then pcall(function() v:Destroy() end) end end
end
local function RefreshHitboxes()
    ClearHitboxes()
    if not G.hitbox then return end
    for _,v in ipairs(G.matchEnemies) do ApplyHitbox(v.Character) end
end

-- triggerbot
RunService.Heartbeat:Connect(function()
    if not G.triggerbot then return end
    local cam=Camera; local ray=cam:ScreenPointToRay(cam.ViewportSize.X/2,cam.ViewportSize.Y/2)
    local result=WS:Raycast(ray.Origin,ray.Direction*600,RaycastParams.new())
    if result and result.Instance then
        local hit=result.Instance
        local char=hit:FindFirstAncestorOfClass("Model")
        if char then
            local p=Players:GetPlayerFromCharacter(char)
            if p and p~=Player and p:GetAttribute("Match")==Player:GetAttribute("Match") then
                ShootAt(p)
            end
        end
    end
end)

-- no gun cooldown
RunService.Heartbeat:Connect(function()
    if not G.noGunCD then return end
    local c=Player.Character; if not c then return end
    for _,v in ipairs(c:GetDescendants()) do
        if(v:IsA("NumberValue") or v:IsA("IntValue")) and v.Value>0 then
            local n=v.Name:lower()
            if n:match("cool") or n:match("cd") then v.Value=0 end
        end
    end
end)

-- ════════════════════════════════════
--  FLY
-- ════════════════════════════════════
local flyConn
local function StopFly()
    G.fly=false
    if flyConn then flyConn:Disconnect(); flyConn=nil end
    pcall(function()
        local r=Rt(); if not r then return end
        for _,n in ipairs({"PX_BV","PX_BG"}) do local x=r:FindFirstChild(n); if x then x:Destroy() end end
        local h=Hm(); if h then h.PlatformStand=false end
    end)
end
local function StartFly()
    StopFly(); G.fly=true
    local r=Rt(); local h=Hm(); if not r or not h then return end
    h.PlatformStand=true
    local BV=Instance.new("BodyVelocity"); BV.Name="PX_BV"; BV.MaxForce=Vector3.new(1e6,1e6,1e6); BV.Parent=r
    local BG=Instance.new("BodyGyro"); BG.Name="PX_BG"; BG.MaxTorque=Vector3.new(1e6,1e6,1e6); BG.P=1e4; BG.Parent=r
    flyConn=RunService.Heartbeat:Connect(function()
        if not G.fly then StopFly(); return end
        local d=Vector3.zero
        if UIS:IsKeyDown(Enum.KeyCode.W) then d=d+Camera.CFrame.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.S) then d=d-Camera.CFrame.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.A) then d=d-Camera.CFrame.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.D) then d=d+Camera.CFrame.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.Space) then d=d+Vector3.new(0,1,0) end
        if UIS:IsKeyDown(Enum.KeyCode.LeftShift) then d=d-Vector3.new(0,1,0) end
        BV.Velocity=d.Magnitude>0 and d.Unit*G.flySpeed or Vector3.zero
        BG.CFrame=Camera.CFrame
    end)
end

-- ════════════════════════════════════
--  NOCLIP
-- ════════════════════════════════════
RunService.Stepped:Connect(function()
    if not G.noclip then return end
    local c=Player.Character; if not c then return end
    for _,p in ipairs(c:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide=false end end
end)

-- ════════════════════════════════════
--  ESP
-- ════════════════════════════════════
local espHighlights={}
local function ClearESP()
    for _,h in pairs(espHighlights) do pcall(function() h:Destroy() end) end
    espHighlights={}
end
local function RefreshESP()
    ClearESP()
    if not G.espEnabled then return end
    local myMatch=Player:GetAttribute("Match")
    for _,p in ipairs(Players:GetPlayers()) do
        if p~=Player and p.Character then
            local h=Instance.new("SelectionBox")
            h.LineThickness=0.05
            h.Color3=p:GetAttribute("Match")==myMatch and G.espTeamColor or G.espEnemyColor
            h.SurfaceTransparency=0.7
            h.Adornee=p.Character
            h.Parent=p.Character
            espHighlights[p]=h
        end
    end
end
RunService.Heartbeat:Connect(function()
    if not G.espEnabled then return end
    local myMatch=Player:GetAttribute("Match")
    for p,h in pairs(espHighlights) do
        if not p.Character or not h.Parent then espHighlights[p]=nil; continue end
        h.Color3=p:GetAttribute("Match")==myMatch and G.espTeamColor or G.espEnemyColor
    end
end)

-- ════════════════════════════════════
--  FARM HELPERS
-- ════════════════════════════════════
local function FindPad(mode)
    local r=Rt(); if not r then return end
    local kw=mode:lower(); local best,bd=nil,math.huge
    for _,v in ipairs(WS:GetDescendants()) do
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
    local p=FindPad(G.queueMode)
    if p then TP(CFrame.new(p.Position+Vector3.new(0,4,0))) end
    FRA({"JoinQueue","QueueJoin","JoinMatch","EnterQueue"},G.queueMode)
end
local function AcceptMatch()
    FRA({"AcceptMatch","AcceptQueue","ReadyUp","ConfirmMatch"})
    for _,v in ipairs(Player.PlayerGui:GetDescendants()) do if v:IsA("TextButton") then local t=v.Text:lower(); if t:match("accept") or t:match("ready") then pcall(function() v.MouseButton1Click:Fire() end) end end end
end
local function VoteMap()
    FRA({"Vote","VoteMap","MapVote"},1)
    for _,v in ipairs(Player.PlayerGui:GetDescendants()) do if v:IsA("TextButton") and v.Text:lower():match("vote") then pcall(function() v.MouseButton1Click:Fire() end); break end end
end
local function ReturnLobby()
    FRA({"ReturnToLobby","BackToLobby","Lobby"})
    for _,v in ipairs(Player.PlayerGui:GetDescendants()) do if v:IsA("TextButton") then local t=v.Text:lower(); if t:match("lobby") or t:match("leave") then pcall(function() v.MouseButton1Click:Fire() end); break end end end
end
local function ClaimDaily()
    FRA({"ClaimDaily","DailyReward","ClaimReward"})
    for _,v in ipairs(Player.PlayerGui:GetDescendants()) do if v:IsA("TextButton") then local t=v.Text:lower(); if t:match("daily") or t:match("claim") then pcall(function() v.MouseButton1Click:Fire() end); Notify("Daily","Claimed!"); return end end end
end
local function Spin()
    FRA({"Spin","SpinCrate","OpenCrate","OpenCase"})
    for _,v in ipairs(Player.PlayerGui:GetDescendants()) do if v:IsA("TextButton") then local t=v.Text:lower(); if t:match("spin") or t:match("open") then pcall(function() v.MouseButton1Click:Fire() end); return end end end
end
local function Collect()
    local r=Rt(); if not r then return end
    for _,v in ipairs(WS:GetDescendants()) do
        if v:IsA("BasePart") then local n=v.Name:lower()
            if n:match("coin") or n:match("gem") or n:match("pickup") then
                if(v.Position-r.Position).Magnitude<60 then TP(CFrame.new(v.Position+Vector3.new(0,3,0))); task.wait(0.05) end
            end
        end
    end
end
local function ServerHop()
    Notify("Server Hop","Searching…")
    local ok,data=pcall(function() return HttpSvc:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/"..PID.."/servers/Public?sortOrder=Asc&limit=100",true)) end)
    if ok and data and data.data then
        for _,s in ipairs(data.data) do
            if s.id~=game.JobId and s.playing<s.maxPlayers then
                pcall(function() TpSvc:TeleportToPlaceInstance(PID,s.id,Player) end); return
            end
        end
    end
    pcall(function() TpSvc:Teleport(PID,Player) end)
end

-- ════════════════════════════════════
--  STREAK REGAIN
-- ════════════════════════════════════
local function StreakRegain()
    -- When health is low: TP away from all enemies and hide
    local r=Rt(); local h=Hm(); if not r or not h then return end
    if h.Health/h.MaxHealth > 0.3 then return end
    local safePos
    local maxDist=0
    -- Find position furthest from all enemies
    for _,offset in ipairs({Vector3.new(30,0,0),Vector3.new(-30,0,0),Vector3.new(0,0,30),Vector3.new(0,0,-30),Vector3.new(20,0,20),Vector3.new(-20,0,-20)}) do
        local pos=r.Position+offset
        local minDist=math.huge
        for _,e in ipairs(G.matchEnemies) do
            local ec=e.Character; if not ec then continue end
            local ehr=ec:FindFirstChild("HumanoidRootPart"); if not ehr then continue end
            minDist=math.min(minDist,(pos-ehr.Position).Magnitude)
        end
        if minDist>maxDist then maxDist=minDist; safePos=pos end
    end
    if safePos then TP(CFrame.new(safePos)); Notify("Streak Protect","Dodged! Streak: "..G.streak) end
end

-- ════════════════════════════════════
--  ANTI-AFK + RESPAWN
-- ════════════════════════════════════
local lastAfk=tick()
RunService.Heartbeat:Connect(function()
    if not G.antiAfk then return end
    if tick()-lastAfk>55 then lastAfk=tick(); pcall(function() local h=Hm(); if h then h.Jump=true end end) end
end)

-- Low health streak protect loop
RunService.Heartbeat:Connect(function()
    if G.streakProtect then StreakRegain() end
end)

-- ════════════════════════════════════
--  STATS TRACKING
-- ════════════════════════════════════
task.spawn(function()
    local ls=Player:WaitForChild("leaderstats",15); if not ls then return end
    for _,v in ipairs(ls:GetChildren()) do
        if v:IsA("IntValue") or v:IsA("NumberValue") then
            v.Changed:Connect(function(val)
                local n=v.Name:lower()
                if n:match("kill") then G.kills=val end
                if n:match("win") and val>G.wins then
                    G.wins=val; G.streak+=1
                    if G.streak>G.best then G.best=G.streak end
                    Notify("Win! 🏆","Streak: "..G.streak.." | Best: "..G.best)
                end
                if n:match("loss") or n:match("death") then
                    if G.streak>0 then
                        local prev=G.streak; G.streak=0
                        if G.streakRegain then
                            Notify("Streak Lost","Was "..prev.." — regaining…")
                            task.spawn(function() task.wait(2); JoinQueue() end)
                        end
                    end
                    G.losses=G.losses+1
                end
                if n:match("coin") or n:match("cash") then G.coins=val end
            end)
        end
    end
end)

Player.CharacterAdded:Connect(function(c)
    task.wait(1.5)
    local h=c:FindFirstChildOfClass("Humanoid"); if not h then return end
    h.WalkSpeed=G.ws; h.JumpPower=G.jp
    if G.fly then task.wait(0.5); StartFly() end
    if G.espEnabled then task.spawn(RefreshESP) end
    h.Died:Connect(function()
        if G.autoRespawn then task.wait(0.4); pcall(function() Player:LoadCharacter() end) end
    end)
end)

-- ════════════════════════════════════
--  MAIN LOOP
-- ════════════════════════════════════
local TM={q=0,a=0,v=0,col=0,sp=0}
RunService.Heartbeat:Connect(function()
    local now=tick()
    if G.autoQueue  and now-TM.q>8   then TM.q=now;  task.spawn(JoinQueue) end
    if G.autoAccept and now-TM.a>2   then TM.a=now;  AcceptMatch() end
    if G.autoVote   and now-TM.v>3   then TM.v=now;  VoteMap() end
    if G.autoCollect and now-TM.col>2 then TM.col=now; task.spawn(Collect) end
    if G.autoSpin   and now-TM.sp>G.spinDelay then TM.sp=now; Spin() end
    if G.autoReturn then
        for _,v in ipairs(Player.PlayerGui:GetDescendants()) do
            if v:IsA("TextButton") then local t=v.Text:lower(); if t:match("lobby") or t:match("return") then pcall(function() v.MouseButton1Click:Fire() end) end end
        end
    end
    if G.hitbox and #G.matchEnemies>0 then task.spawn(RefreshHitboxes) end
end)

-- ════════════════════════════════════════════════════════
--  TABS
-- ════════════════════════════════════════════════════════

-- ── HOME ──────────────────────────────────────────────
local Home = window:Tab({ Title="Home", Icon="house" })
Home:Paragraph({
    Title="⚡ Phantom X — MvS Duels",
    Desc="Full-featured exploit for Murders vs Sheriffs Duels. Mobile-ready. Fly, auto farm, aimbot, streak regain, ESP, and more.",
    Color=Color3.fromHex("#a855f7"),
})
Home:Paragraph({
    Title="How to use",
    Desc="Pick a tab from the left sidebar. All toggles save their state. Press the purple ⚡ button to reopen if you close the window.",
    Color="Green",
})
Home:Space()
local statsPara=Home:Paragraph({ Title="Session Stats", Desc="Loading…", Color=Color3.fromHex("#6366f1") })
task.spawn(function()
    while true do
        task.wait(2)
        pcall(function()
            statsPara:Set({
                Title="Session Stats",
                Desc=string.format("Kills: %d | Wins: %d | Losses: %d\nStreak: %d | Best Streak: %d | Coins: %d",
                    G.kills,G.wins,G.losses,G.streak,G.best,G.coins)
            })
        end)
    end
end)
Home:Select()

-- ── COMBAT ────────────────────────────────────────────
local Combat = window:Tab({ Title="Combat", Icon="swords" })

local CombatSect = Combat:Section({ Title="Aimbot", Opened=true })
CombatSect:Toggle({
    Title="Auto Shoot", Desc="Automatically fires at the nearest enemy in your match.",
    Icon="crosshair", Default=false, Flag="AutoShoot",
    Callback=function(v) G.autoshoot=v; if v then StartAutoShoot() else StopAutoShoot() end end
})
CombatSect:Slider({
    Title="Shoot Distance", Icon="ruler", Flag="ShootDist",
    Value={Min=50,Max=800,Default=300},
    Callback=function(v) G.autoshootDist=v end
})
CombatSect:Slider({
    Title="Shoot Cooldown (s)", Icon="timer", Flag="ShootCD",
    Value={Min=0.5,Max=10,Default=2.5}, Step=0.5,
    Callback=function(v) G.autoshootCD=v end
})
CombatSect:Toggle({
    Title="Auto Throw Knife", Desc="Automatically throws knife at nearest enemy.",
    Icon="knife", Default=false, Flag="AutoKnife",
    Callback=function(v) G.autoKnife=v; if v then StartAutoKnife() else StopAutoKnife() end end
})
CombatSect:Slider({
    Title="Knife Distance", Icon="ruler", Flag="KnifeDist",
    Value={Min=20,Max=400,Default=300},
    Callback=function(v) G.knifeDist=v end
})
CombatSect:Slider({
    Title="Knife Cooldown (s)", Icon="timer", Flag="KnifeCD",
    Value={Min=0.5,Max=8,Default=2}, Step=0.5,
    Callback=function(v) G.knifeCD=v end
})

local TriggerSect=Combat:Section({ Title="Trigger Bot", Opened=false })
TriggerSect:Toggle({
    Title="Trigger Bot", Desc="Shoots when your crosshair is over an enemy.",
    Icon="target", Default=false, Flag="TriggerBot",
    Callback=function(v) G.triggerbot=v end
})
TriggerSect:Slider({
    Title="Trigger Cooldown (s)", Icon="timer", Flag="TriggerCD",
    Value={Min=0,Max=3,Default=1}, Step=0.1,
    Callback=function(v) G.triggerbotCD=v end
})

local HitboxSect=Combat:Section({ Title="Hitbox", Opened=false })
HitboxSect:Toggle({
    Title="Hitbox Expander", Desc="Enlarges enemy hitboxes to make them easier to hit.",
    Icon="box", Default=false, Flag="HitboxExpand",
    Callback=function(v) G.hitbox=v; if not v then ClearHitboxes() end end
})
HitboxSect:Slider({
    Title="Hitbox Size", Icon="maximize-2", Flag="HitboxSize",
    Value={Min=5,Max=80,Default=13},
    Callback=function(v) G.hitboxSize=v end
})

Combat:Toggle({
    Title="Remove Gun Cooldown", Desc="Zeroes weapon cooldown values every frame.",
    Icon="zap", Default=false, Flag="NoGunCD",
    Callback=function(v) G.noGunCD=v end
})

-- ── FARM ──────────────────────────────────────────────
local Farm = window:Tab({ Title="Farm", Icon="wheat" })

local AutoSect=Farm:Section({ Title="Auto Farm", Opened=true })
AutoSect:Toggle({
    Title="All-in-One Farm", Desc="Enables all farm options at once.",
    Icon="play", Default=false, Flag="AllFarm",
    Callback=function(v)
        G.autoQueue=v; G.autoAccept=v; G.autoVote=v; G.autoCollect=v; G.autoReturn=v
        Notify("Auto Farm", v and "All farm ON" or "All farm OFF")
    end
})
AutoSect:Toggle({ Title="Auto Queue",          Default=false, Flag="AQueue",   Callback=function(v) G.autoQueue=v end })
AutoSect:Toggle({ Title="Auto Accept Match",    Default=false, Flag="AAccept",  Callback=function(v) G.autoAccept=v end })
AutoSect:Toggle({ Title="Auto Vote Map",        Default=false, Flag="AVote",    Callback=function(v) G.autoVote=v end })
AutoSect:Toggle({ Title="Auto Return to Lobby", Default=false, Flag="AReturn",  Callback=function(v) G.autoReturn=v end })
AutoSect:Toggle({ Title="Auto Collect Pickups", Default=false, Flag="ACollect", Callback=function(v) G.autoCollect=v end })
AutoSect:Toggle({ Title="Auto Spin Crates",     Default=false, Flag="ASpin",    Callback=function(v) G.autoSpin=v end })
AutoSect:Slider({
    Title="Spin Delay (s)", Icon="timer", Flag="SpinDelay",
    Value={Min=1,Max=10,Default=2},
    Callback=function(v) G.spinDelay=v end
})
AutoSect:Dropdown({
    Title="Queue Mode", Icon="list", Flag="QueueMode",
    Values={"1v1","2v2","3v3","4v4"}, Default=1,
    Callback=function(v) G.queueMode=v end
})

local ManualSect=Farm:Section({ Title="Manual Actions", Opened=false })
ManualSect:Button({ Title="Join Queue Now",      Icon="log-in",      Callback=function() JoinQueue();  Notify("Queue","Fired!") end })
ManualSect:Button({ Title="Accept Match Now",    Icon="check",       Callback=function() AcceptMatch() end })
ManualSect:Button({ Title="Vote Map Now",        Icon="thumbs-up",   Callback=function() VoteMap() end })
ManualSect:Button({ Title="Return to Lobby",     Icon="door-open",   Callback=function() ReturnLobby() end })
ManualSect:Button({ Title="Claim Daily Reward",  Icon="gift",        Callback=function() ClaimDaily() end })
ManualSect:Button({ Title="Spin Crate Now",      Icon="refresh-cw",  Callback=function() Spin(); Notify("Crate","Spun!") end })
ManualSect:Button({ Title="Collect Pickups Now", Icon="coins",       Callback=function() task.spawn(Collect) end })

-- ── STREAK ────────────────────────────────────────────
local Streak = window:Tab({ Title="Streak", Icon="trending-up" })

local StreakSect=Streak:Section({ Title="Streak Management", Opened=true })
StreakSect:Toggle({
    Title="Streak Regain", Desc="When you lose your streak, auto-queues immediately to get it back.",
    Icon="refresh-cw", Default=false, Flag="StreakRegain",
    Callback=function(v) G.streakRegain=v end
})
StreakSect:Toggle({
    Title="Streak Protect", Desc="When HP drops below 30%, teleports you to a safe position to avoid dying.",
    Icon="shield", Default=false, Flag="StreakProtect",
    Callback=function(v) G.streakProtect=v end
})
StreakSect:Button({
    Title="Force Rejoin Queue", Icon="log-in",
    Callback=function() task.spawn(JoinQueue); Notify("Queue","Fired to regain streak!") end
})
Streak:Space()
Streak:Paragraph({
    Title="How Streak Protect works",
    Desc="The script watches your HP every frame. If it drops below 30% while in a match, it teleports you to the furthest point from all enemies so you can heal or escape.",
    Color=Color3.fromHex("#6366f1"),
})

-- ── MOVEMENT ──────────────────────────────────────────
local Movement = window:Tab({ Title="Movement", Icon="plane" })

local FlySect=Movement:Section({ Title="Fly", Opened=true })
FlySect:Toggle({
    Title="Fly", Desc="WASD to move, Space=up, Shift=down.",
    Icon="plane", Default=false, Flag="Fly",
    Callback=function(v) if v then StartFly() else StopFly() end end
})
FlySect:Slider({
    Title="Fly Speed", Icon="wind", Flag="FlySpeed",
    Value={Min=10,Max=400,Default=80},
    Callback=function(v) G.flySpeed=v end
})

local GroundSect=Movement:Section({ Title="Ground", Opened=true })
GroundSect:Toggle({
    Title="Noclip", Desc="Walk through walls.",
    Icon="ghost", Default=false, Flag="Noclip",
    Callback=function(v) G.noclip=v end
})
GroundSect:Slider({
    Title="Walk Speed", Icon="footprints", Flag="WalkSpeed",
    Value={Min=16,Max=300,Default=16},
    Callback=function(v) G.ws=v; local h=Hm(); if h then h.WalkSpeed=v end end
})
GroundSect:Slider({
    Title="Jump Power", Icon="arrow-up", Flag="JumpPower",
    Value={Min=50,Max=300,Default=50},
    Callback=function(v) G.jp=v; local h=Hm(); if h then h.JumpPower=v end end
})
GroundSect:Button({
    Title="Teleport to Spawn", Icon="map-pin",
    Callback=function()
        local sp=WS:FindFirstChildOfClass("SpawnLocation")
        if sp then TP(sp.CFrame+Vector3.new(0,5,0)); Notify("Teleport","Done!") end
    end
})

-- ── ESP ────────────────────────────────────────────────
local Esp = window:Tab({ Title="ESP", Icon="eye" })

local EspSect=Esp:Section({ Title="Highlights", Opened=true })
EspSect:Toggle({
    Title="Enable ESP", Desc="Outlines all players with a coloured box.",
    Icon="eye", Default=false, Flag="EspToggle",
    Callback=function(v) G.espEnabled=v; if v then RefreshESP() else ClearESP() end end
})
EspSect:Button({ Title="Refresh ESP", Icon="refresh-cw", Callback=function() if G.espEnabled then RefreshESP() end end })
Esp:Space()
Esp:Paragraph({
    Title="Note",
    Desc="ESP colour: green = same match team, red = enemy. Refreshes automatically when entering a match.",
    Color=Color3.fromHex("#a855f7"),
})

-- ── QOL ───────────────────────────────────────────────
local QoL = window:Tab({ Title="QoL", Icon="settings" })

local QoLSect=QoL:Section({ Title="Quality of Life", Opened=true })
QoLSect:Toggle({
    Title="Anti-AFK", Desc="Jumps every 55 seconds to prevent kick.",
    Icon="activity", Default=true, Flag="AntiAfk",
    Callback=function(v) G.antiAfk=v end
})
QoLSect:Toggle({
    Title="Auto Respawn", Desc="Respawns automatically on death.",
    Icon="refresh-cw", Default=false, Flag="AutoRespawn",
    Callback=function(v) G.autoRespawn=v end
})
QoLSect:Toggle({
    Title="FPS Boost", Desc="Disables shadows, effects, and particles.",
    Icon="zap", Default=false, Flag="FpsBoost",
    Callback=function(v)
        pcall(function()
            Lighting.GlobalShadows=not v
            for _,x in ipairs(Lighting:GetChildren()) do if x:IsA("PostEffect") or x:IsA("Atmosphere") then pcall(function() x.Enabled=not v end) end end
            for _,x in ipairs(WS:GetDescendants()) do if x:IsA("ParticleEmitter") or x:IsA("Fire") or x:IsA("Smoke") then pcall(function() x.Enabled=not v end) end end
        end)
        Notify("FPS Boost",v and "ON" or "OFF")
    end
})

QoL:Space()
local ServerSect=QoL:Section({ Title="Server", Opened=true })
ServerSect:Button({ Title="Server Hop",  Icon="shuffle",    Callback=function() task.spawn(ServerHop) end })
ServerSect:Button({ Title="Rejoin Now",  Icon="log-out",    Callback=function() Notify("Rejoin","…"); task.wait(1); pcall(function() TpSvc:Teleport(PID,Player) end) end })
ServerSect:Button({
    Title="Dump Remotes", Icon="terminal",
    Callback=function()
        for _,v in ipairs(RepStorage:GetDescendants()) do
            if v:IsA("RemoteEvent") or v:IsA("RemoteFunction") then print("["..v.ClassName.."] "..v:GetFullName()) end
        end
        Notify("Remotes","Printed to console!")
    end
})

warn("[PX] ✅ Phantom X loaded — WindUI edition")
Notify("Phantom X","Loaded! Use the ⚡ button to reopen.",5)
