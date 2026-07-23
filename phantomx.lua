-- ⚡ Phantom X | Murders vs Sheriffs Duels | Red21 Games
-- Zero external dependencies — works on any executor
print("[Phantom X] Loading...")

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
local HttpService        = game:GetService("HttpService")
local StarterGui         = game:GetService("StarterGui")

local LP      = Players.LocalPlayer
local Cam     = Workspace.CurrentCamera
local PID     = game.PlaceId

-- ════════════════════════════════════════
--  REMOTE HELPERS
-- ════════════════════════════════════════
local RC = {}
local function GR(name) -- get remote by name (deep scan)
    if RC[name] then return RC[name] end
    for _, v in ipairs(ReplicatedStorage:GetDescendants()) do
        if v.Name == name and (v:IsA("RemoteEvent") or v:IsA("RemoteFunction")) then
            RC[name] = v; return v
        end
    end
    return nil
end
local function FR(name, ...) -- fire remote
    local r = GR(name); if not r then return false end
    pcall(function()
        if r:IsA("RemoteEvent") then r:FireServer(...) else r:InvokeServer(...) end
    end); return true
end
local function FRA(names, ...) -- fire multiple
    for _, n in ipairs(names) do FR(n, ...) end
end

-- ════════════════════════════════════════
--  STATE
-- ════════════════════════════════════════
local S = {
    autoFarm=false, autoQueue=false, queueMode="1v1",
    autoAccept=false, autoVote=false, autoReturn=false,
    autoCollect=false, autoSpin=false, spinDelay=2,
    afk=false, autoRespawn=false, autoEquip=false, autoCharm=false,
    noCd=false, noDash=false, coinFarm=false,
    fly=false, flySpeed=80, noclip=false, skeleton=false,
    ws=16, jp=50, fpsBoost=false, antiLag=false,
    antiAfk=true, rejoin=false,
    kills=0, wins=0, losses=0, streak=0, best=0, last=0, coins=0,
    t0=tick(), uiOpen=true,
}

-- ════════════════════════════════════════
--  CUSTOM UI
-- ════════════════════════════════════════
-- destroy old instance if reinjecting
if _G.PhantomX then pcall(function() _G.PhantomX:Destroy() end) end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name           = "PhantomX"
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.DisplayOrder   = 999
ScreenGui.ResetOnSpawn   = false
-- Try CoreGui first (works on most mobile executors), fallback to PlayerGui
local guiParented = false
pcall(function()
    ScreenGui.Parent = game:GetService("CoreGui")
    guiParented = true
end)
if not guiParented then
    pcall(function() ScreenGui.Parent = LP:WaitForChild("PlayerGui") end)
end
_G.PhantomX = ScreenGui

-- colour palette
local C = {
    bg      = Color3.fromRGB(14, 14, 20),
    panel   = Color3.fromRGB(22, 22, 32),
    accent  = Color3.fromRGB(140, 70, 255),
    accent2 = Color3.fromRGB(100, 40, 200),
    text    = Color3.fromRGB(240, 240, 255),
    sub     = Color3.fromRGB(160, 160, 190),
    on      = Color3.fromRGB(80, 220, 120),
    off     = Color3.fromRGB(220, 70, 70),
    btn     = Color3.fromRGB(38, 38, 58),
    btnHov  = Color3.fromRGB(55, 55, 80),
    border  = Color3.fromRGB(60, 40, 100),
}

-- ── helpers ──────────────────────────────
local function mkCorner(r, p)
    local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, r); c.Parent = p; return c
end
local function mkStroke(col, thick, p)
    local s = Instance.new("UIStroke"); s.Color=col; s.Thickness=thick; s.Parent=p; return s
end
local function mkPad(t,b,l,r,p)
    local pad=Instance.new("UIPadding")
    pad.PaddingTop=UDim.new(0,t); pad.PaddingBottom=UDim.new(0,b)
    pad.PaddingLeft=UDim.new(0,l); pad.PaddingRight=UDim.new(0,r)
    pad.Parent=p; return pad
end
local function mkLabel(txt, size, col, font, p)
    local l=Instance.new("TextLabel")
    l.Text=txt; l.TextSize=size or 13; l.TextColor3=col or C.text
    l.Font=font or Enum.Font.GothamMedium
    l.BackgroundTransparency=1; l.TextXAlignment=Enum.TextXAlignment.Left
    l.Size=UDim2.new(1,0,0,size and size+6 or 20)
    l.Parent=p; return l
end
local function mkFrame(sz, pos, col, p)
    local f=Instance.new("Frame")
    f.Size=sz; f.Position=pos or UDim2.new(0,0,0,0)
    f.BackgroundColor3=col or C.panel; f.BorderSizePixel=0; f.Parent=p; return f
end

-- ── make draggable ────────────────────────
local function makeDraggable(handle, frame)
    local drag, ds, sp = false, nil, nil
    handle.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 then
            drag=true; ds=i.Position; sp=frame.Position
        end
    end)
    handle.InputEnded:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 then drag=false end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if drag and i.UserInputType==Enum.UserInputType.MouseMovement then
            local d=i.Position-ds
            frame.Position=UDim2.new(sp.X.Scale,sp.X.Offset+d.X,sp.Y.Scale,sp.Y.Offset+d.Y)
        end
    end)
end

-- ── MAIN WINDOW ──────────────────────────
local Win = mkFrame(UDim2.new(0,340,0,460), UDim2.new(0.5,-170,0.5,-230), C.bg, ScreenGui)
Win.Active=true; mkCorner(12,Win); mkStroke(C.border,1.5,Win)

-- title bar
local TitleBar = mkFrame(UDim2.new(1,0,0,42), nil, C.panel, Win)
mkCorner(12,TitleBar)
-- fix bottom corners of title bar
local TBFix=mkFrame(UDim2.new(1,0,0,12),UDim2.new(0,0,1,-12),C.panel,TitleBar); TBFix.ZIndex=2

local TitleIcon=mkLabel("⚡",18,C.accent,Enum.Font.GothamBold,TitleBar)
TitleIcon.Size=UDim2.new(0,30,1,0); TitleIcon.Position=UDim2.new(0,10,0,0)
TitleIcon.TextXAlignment=Enum.TextXAlignment.Center

local TitleLbl=mkLabel("Phantom X",15,C.text,Enum.Font.GothamBold,TitleBar)
TitleLbl.Size=UDim2.new(1,-110,1,0); TitleLbl.Position=UDim2.new(0,42,0,0)

local SubLbl=mkLabel("Murders vs Sheriffs Duels",11,C.sub,Enum.Font.Gotham,TitleBar)
SubLbl.Size=UDim2.new(1,-110,0,14); SubLbl.Position=UDim2.new(0,42,0,22)

-- close / minimise buttons
local function mkTitleBtn(icon, xoff, col)
    local b=Instance.new("TextButton")
    b.Size=UDim2.new(0,26,0,26); b.Position=UDim2.new(1,xoff,0.5,-13)
    b.BackgroundColor3=col; b.Text=icon
    b.TextColor3=C.text; b.TextSize=13; b.Font=Enum.Font.GothamBold
    b.BorderSizePixel=0; b.Parent=TitleBar; mkCorner(6,b); return b
end
local MinBtn   = mkTitleBtn("−", -60, C.btn)
local CloseBtn = mkTitleBtn("✕", -30, Color3.fromRGB(180,50,50))

makeDraggable(TitleBar, Win)

-- ── MINI BAR (when minimised) ─────────────
local Mini=mkFrame(UDim2.new(0,200,0,36),UDim2.new(0.5,-100,0,20),C.bg,ScreenGui)
Mini.Active=true; Mini.Visible=false; mkCorner(10,Mini); mkStroke(C.accent,1.5,Mini)
local MiniLbl=mkLabel("⚡ Phantom X",13,C.accent,Enum.Font.GothamBold,Mini)
MiniLbl.Size=UDim2.new(1,-44,1,0); MiniLbl.Position=UDim2.new(0,10,0,0)
local MiniOpen=Instance.new("TextButton")
MiniOpen.Size=UDim2.new(0,30,0,24); MiniOpen.Position=UDim2.new(1,-36,0.5,-12)
MiniOpen.BackgroundColor3=C.accent; MiniOpen.Text="+"; MiniOpen.TextColor3=C.text
MiniOpen.TextSize=16; MiniOpen.Font=Enum.Font.GothamBold; MiniOpen.BorderSizePixel=0
MiniOpen.Parent=Mini; mkCorner(6,MiniOpen)
makeDraggable(Mini, Mini)

local function SetUI(open)
    S.uiOpen=open; Win.Visible=open; Mini.Visible=not open
end
MinBtn.MouseButton1Click:Connect(function()   SetUI(false) end)
CloseBtn.MouseButton1Click:Connect(function() SetUI(false) end)
MiniOpen.MouseButton1Click:Connect(function() SetUI(true)  end)

-- ── TAB SYSTEM ───────────────────────────
local TabBar=mkFrame(UDim2.new(0,120,1,-42),UDim2.new(0,0,0,42),C.panel,Win)
mkStroke(C.border,0.5,TabBar)
local TBList=Instance.new("UIListLayout"); TBList.SortOrder=Enum.SortOrder.LayoutOrder; TBList.Parent=TabBar

local ContentArea=mkFrame(UDim2.new(1,-122,1,-44),UDim2.new(0,122,0,43),C.bg,Win)

local activeTab=nil
local tabs={}

local function makeTab(name, icon)
    local btn=Instance.new("TextButton")
    btn.Size=UDim2.new(1,0,0,38)
    btn.BackgroundColor3=C.panel; btn.Text=""
    btn.BorderSizePixel=0; btn.LayoutOrder=#tabs+1; btn.Parent=TabBar

    local lbl=mkLabel(icon.." "..name,12,C.sub,Enum.Font.GothamMedium,btn)
    lbl.Size=UDim2.new(1,-8,1,0); lbl.Position=UDim2.new(0,8,0,0)
    lbl.TextXAlignment=Enum.TextXAlignment.Left

    -- content frame for this tab
    local frame=mkFrame(UDim2.new(1,0,1,0),nil,C.bg,ContentArea)
    frame.Visible=false
    local scroll=Instance.new("ScrollingFrame")
    scroll.Size=UDim2.new(1,-4,1,-4); scroll.Position=UDim2.new(0,2,0,2)
    scroll.BackgroundTransparency=1; scroll.BorderSizePixel=0
    scroll.ScrollBarThickness=3; scroll.ScrollBarImageColor3=C.accent
    scroll.CanvasSize=UDim2.new(0,0,0,0); scroll.AutomaticCanvasSize=Enum.AutomaticSize.Y
    scroll.Parent=frame
    local list=Instance.new("UIListLayout")
    list.SortOrder=Enum.SortOrder.LayoutOrder; list.Padding=UDim.new(0,4)
    list.Parent=scroll
    mkPad(6,6,8,8,scroll)

    local tab={btn=btn, frame=frame, scroll=scroll, lbl=lbl, items=0}

    btn.MouseButton1Click:Connect(function()
        if activeTab then
            activeTab.frame.Visible=false
            activeTab.lbl.TextColor3=C.sub
            activeTab.btn.BackgroundColor3=C.panel
        end
        activeTab=tab; frame.Visible=true
        lbl.TextColor3=C.accent; btn.BackgroundColor3=C.btn
    end)

    table.insert(tabs,tab); return tab
end

-- ── WIDGET BUILDERS ──────────────────────
local function Section(tab, title)
    local f=mkFrame(UDim2.new(1,-4,0,22),nil,Color3.fromRGB(0,0,0,0),tab.scroll)
    f.BackgroundTransparency=1; f.LayoutOrder=tab.items; tab.items+=1
    local l=mkLabel("  "..title:upper(),10,C.accent,Enum.Font.GothamBold,f)
    l.Size=UDim2.new(1,0,1,0)
    local line=mkFrame(UDim2.new(1,0,0,1),UDim2.new(0,0,1,-1),C.border,f)
end

local function Toggle(tab, label, default, cb)
    local f=mkFrame(UDim2.new(1,-4,0,36),nil,C.btn,tab.scroll)
    mkCorner(8,f); f.LayoutOrder=tab.items; tab.items+=1
    local l=mkLabel(label,13,C.text,Enum.Font.GothamMedium,f)
    l.Size=UDim2.new(1,-54,1,0); l.Position=UDim2.new(0,10,0,0)

    local pill=mkFrame(UDim2.new(0,40,0,20),UDim2.new(1,-48,0.5,-10),default and C.on or C.off,f)
    mkCorner(10,pill)
    local dot=mkFrame(UDim2.new(0,14,0,14),default and UDim2.new(1,-17,0.5,-7) or UDim2.new(0,3,0.5,-7),Color3.new(1,1,1),pill)
    mkCorner(8,dot)

    local val=default or false
    local ti=TweenInfo.new(0.15)

    local btn=Instance.new("TextButton")
    btn.Size=UDim2.new(1,0,1,0); btn.BackgroundTransparency=1; btn.Text=""; btn.Parent=f
    btn.MouseButton1Click:Connect(function()
        val=not val
        TweenService:Create(pill,ti,{BackgroundColor3=val and C.on or C.off}):Play()
        TweenService:Create(dot,ti,{Position=val and UDim2.new(1,-17,0.5,-7) or UDim2.new(0,3,0.5,-7)}):Play()
        pcall(cb,val)
    end)
    if default then pcall(cb,true) end
    return function() btn.MouseButton1Click:Fire() end -- return toggler
end

local function Button(tab, label, cb)
    local f=mkFrame(UDim2.new(1,-4,0,34),nil,C.accent2,tab.scroll)
    mkCorner(8,f); f.LayoutOrder=tab.items; tab.items+=1
    mkStroke(C.accent,0.8,f)
    local btn=Instance.new("TextButton")
    btn.Size=UDim2.new(1,0,1,0); btn.BackgroundTransparency=1
    btn.Text=label; btn.TextColor3=C.text; btn.TextSize=13
    btn.Font=Enum.Font.GothamBold; btn.Parent=f
    btn.MouseEnter:Connect(function()
        TweenService:Create(f,TweenInfo.new(0.1),{BackgroundColor3=C.accent}):Play()
    end)
    btn.MouseLeave:Connect(function()
        TweenService:Create(f,TweenInfo.new(0.1),{BackgroundColor3=C.accent2}):Play()
    end)
    btn.MouseButton1Click:Connect(function() pcall(cb) end)
end

local function Slider(tab, label, min, max, default, cb)
    local f=mkFrame(UDim2.new(1,-4,0,52),nil,C.btn,tab.scroll)
    mkCorner(8,f); f.LayoutOrder=tab.items; tab.items+=1
    local lbl=mkLabel(label..": "..default,12,C.text,Enum.Font.GothamMedium,f)
    lbl.Size=UDim2.new(1,-10,0,18); lbl.Position=UDim2.new(0,10,0,6)

    local track=mkFrame(UDim2.new(1,-20,0,6),UDim2.new(0,10,0,32),C.panel,f)
    mkCorner(3,track); mkStroke(C.border,0.5,track)
    local fill=mkFrame(UDim2.new((default-min)/(max-min),0,1,0),nil,C.accent,track)
    mkCorner(3,fill)
    local nub=mkFrame(UDim2.new(0,14,0,14),UDim2.new((default-min)/(max-min),0,0.5,-7),C.text,track)
    mkCorner(7,nub)

    local dragging=false
    local function update(x)
        local rel=math.clamp((x - track.AbsolutePosition.X)/track.AbsoluteSize.X,0,1)
        local v=math.floor(min+(max-min)*rel)
        fill.Size=UDim2.new(rel,0,1,0)
        nub.Position=UDim2.new(rel,0,0.5,-7)
        lbl.Text=label..": "..v
        pcall(cb,v)
    end
    nub.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then dragging=true end end)
    UserInputService.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then dragging=false end end)
    UserInputService.InputChanged:Connect(function(i)
        if dragging and i.UserInputType==Enum.UserInputType.MouseMovement then update(i.Position.X) end
    end)
    track.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 then update(i.Position.X) end
    end)
    pcall(cb, default)
end

local function Dropdown(tab, label, options, cb)
    local f=mkFrame(UDim2.new(1,-4,0,34),nil,C.btn,tab.scroll)
    mkCorner(8,f); f.LayoutOrder=tab.items; tab.items+=1
    local lbl=mkLabel(label..": "..options[1],13,C.text,Enum.Font.GothamMedium,f)
    lbl.Size=UDim2.new(1,-40,1,0); lbl.Position=UDim2.new(0,10,0,0)
    local arr=mkLabel("▾",14,C.accent,Enum.Font.GothamBold,f)
    arr.Size=UDim2.new(0,24,1,0); arr.Position=UDim2.new(1,-28,0,0)
    arr.TextXAlignment=Enum.TextXAlignment.Center

    local cur=1; pcall(cb, options[1])

    local btn=Instance.new("TextButton")
    btn.Size=UDim2.new(1,0,1,0); btn.BackgroundTransparency=1; btn.Text=""; btn.Parent=f
    btn.MouseButton1Click:Connect(function()
        cur=cur%#options+1
        lbl.Text=label..": "..options[cur]
        pcall(cb, options[cur])
    end)
end

-- ── NOTIFICATION ─────────────────────────
local notifQ={}
local function Notif(title, msg)
    local nf=mkFrame(UDim2.new(0,260,0,0),UDim2.new(1,-270,1,-10),C.panel,ScreenGui)
    nf.AutomaticSize=Enum.AutomaticSize.Y; nf.AnchorPoint=Vector2.new(0,1)
    nf.Position=UDim2.new(1,-270,1,-10); mkCorner(8,nf); mkStroke(C.accent,1,nf)
    mkPad(8,8,10,10,nf)
    local list=Instance.new("UIListLayout"); list.SortOrder=Enum.SortOrder.LayoutOrder; list.Parent=nf
    local tl=mkLabel(title,13,C.accent,Enum.Font.GothamBold,nf); tl.LayoutOrder=0
    local ml=mkLabel(msg,12,C.text,Enum.Font.Gotham,nf)
    ml.TextWrapped=true; ml.Size=UDim2.new(1,0,0,0)
    ml.AutomaticSize=Enum.AutomaticSize.Y; ml.LayoutOrder=1

    -- slide in
    local startY=nf.Position.Y.Offset
    for _, n in ipairs(notifQ) do
        pcall(function()
            TweenService:Create(n,TweenInfo.new(0.2),{Position=UDim2.new(n.Position.X.Scale,n.Position.X.Offset,1,n.Position.Y.Offset-60)}):Play()
        end)
    end
    table.insert(notifQ,nf)
    task.delay(4, function()
        pcall(function()
            TweenService:Create(nf,TweenInfo.new(0.3),{BackgroundTransparency=1}):Play()
            task.wait(0.3); nf:Destroy()
            table.remove(notifQ, table.find(notifQ,nf) or 1)
        end)
    end)
end

-- ════════════════════════════════════════
--  GAME FUNCTIONS
-- ════════════════════════════════════════

-- helpers
local function Root()  local c=LP.Character; return c and c:FindFirstChild("HumanoidRootPart") end
local function Hum()   local c=LP.Character; return c and c:FindFirstChildOfClass("Humanoid") end
local function TP(cf)  local r=Root(); if r then pcall(function() r.CFrame=cf end) end end

-- fly
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

-- skeleton
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

-- cooldowns
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
                if LP:GetAttribute(a) and LP:GetAttribute(a)~=0 then
                    LP:SetAttribute(a,0)
                end
            end
        end
    end)
end)

-- anti afk
local afkT=tick()
RunService.Heartbeat:Connect(function()
    if not S.antiAfk then return end
    if tick()-afkT>55 then
        afkT=tick()
        pcall(function() local h=Hum(); if h then h.Jump=true end end)
    end
end)

-- noclip
RunService.Stepped:Connect(function()
    if not S.noclip then return end
    pcall(function()
        local c=LP.Character; if not c then return end
        for _,p in ipairs(c:GetDescendants()) do
            if p:IsA("BasePart") and p.CanCollide then p.CanCollide=false end
        end
    end)
end)

-- char added
LocalPlayer = LP
LP.CharacterAdded:Connect(function(c)
    task.wait(1.5)
    local h=c:FindFirstChildOfClass("Humanoid"); if not h then return end
    h.WalkSpeed=S.ws; h.JumpPower=S.jp
    if S.skeleton then task.spawn(function() Skeleton(true) end) end
    if S.fly      then task.wait(0.5); StartFly() end
    h.Died:Connect(function()
        if S.streak>0 then S.last=S.streak end
        S.losses+=1; S.streak=0
        if S.autoRespawn then task.wait(0.3); pcall(function() LP:LoadCharacter() end) end
    end)
end)

-- queue / pads
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
                Notif("🎁 Daily","Claimed!"); return
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
        if tools[1] then pcall(function() h:EquipTool(tools[1]) end); Notif("⚔️ Weapon",tools[1].Name) end
    end
end

local function EquipCharm()
    FRA({"EquipCharm","UseCharm","ActivateCharm"})
    local bp=LP:FindFirstChild("Backpack"); local h=Hum()
    if bp and h then
        for _,v in ipairs(bp:GetChildren()) do
            if v.Name:lower():match("charm") then
                pcall(function() h:EquipTool(v) end); Notif("💎 Charm",v.Name); return
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
    local names={"GiveCoins","AddCoins","GrantCoins","GiveCash","AddCash",
                 "GrantCash","CoinReward","EarnCoins","AddMoney","GiveDiamonds","AddGems"}
    FRA(names,amt)
    pcall(function()
        local ls=LP:FindFirstChild("leaderstats")
        if ls then for _,v in ipairs(ls:GetChildren()) do
            if v:IsA("IntValue") or v:IsA("NumberValue") then v.Value+=amt end
        end end
    end)
    Notif("💰 Coins","Sent +"..amt.." via all methods.")
end

local function RegainStreak()
    if S.last<=0 then Notif("🔥 Streak","No previous streak."); return end
    FRA({"SetStreak","RestoreStreak","SetWinStreak"},S.last)
    pcall(function()
        LP:SetAttribute("Streak",S.last); LP:SetAttribute("WinStreak",S.last)
        local ls=LP:FindFirstChild("leaderstats")
        if ls then for _,v in ipairs(ls:GetChildren()) do
            if v.Name:lower():match("streak") then v.Value=S.last end
        end end
    end)
    Notif("🔥 Streak","Tried to restore "..S.last.." streak")
end

local function Hop()
    Notif("🔀 Server Hop","Finding server...")
    local ok2,data=pcall(function()
        return HttpService:JSONDecode(game:HttpGet(
            "https://games.roblox.com/v1/games/"..PID.."/servers/Public?sortOrder=Asc&limit=100",true))
    end)
    if ok2 and data and data.data then
        for _,srv in ipairs(data.data) do
            if srv.id~=game.JobId and srv.playing<srv.maxPlayers then
                pcall(function() TeleportService:TeleportToPlaceInstance(PID,srv.id,LP) end); return
            end
        end
    end
    pcall(function() TeleportService:Teleport(PID,LP) end)
end

-- FPS boost
local function FPSBoost(on)
    S.fpsBoost=on; pcall(function()
        Lighting.GlobalShadows=not on; Lighting.FogEnd=on and 1e6 or 1e4
        for _,v in ipairs(Lighting:GetChildren()) do
            if v:IsA("PostEffect") or v:IsA("Atmosphere") or v:IsA("Sky") then
                pcall(function() v.Enabled=not on end)
            end
        end
        for _,v in ipairs(Workspace:GetDescendants()) do
            if v:IsA("ParticleEmitter") or v:IsA("Fire") or v:IsA("Smoke") or v:IsA("Sparkles") then
                pcall(function() v.Enabled=not on end)
            end
        end
    end)
    Notif("⚡ FPS Boost",on and "Shadows & particles off." or "Restored.")
end

-- leaderstats watcher
task.spawn(function()
    local ls=LP:WaitForChild("leaderstats",15)
    if not ls then return end
    for _,v in ipairs(ls:GetChildren()) do
        if v:IsA("IntValue") or v:IsA("NumberValue") then
            v.Changed:Connect(function(val)
                local n=v.Name:lower()
                if n:match("kill")   then S.kills=val end
                if n:match("win")    then
                    if val>S.wins then S.wins=val; S.streak+=1
                        if S.streak>S.best then S.best=S.streak end
                        Notif("🏆 Win!","Streak: "..S.streak)
                    end
                end
                if n:match("coin") or n:match("cash") or n:match("gem") then S.coins=val end
                if n:match("streak") then S.streak=val end
            end)
        end
    end
end)

-- keybinds
UserInputService.InputBegan:Connect(function(i,gpe)
    if gpe then return end
    if i.KeyCode==Enum.KeyCode.RightShift then SetUI(not S.uiOpen) end
    if i.KeyCode==Enum.KeyCode.F          then if S.fly then StopFly() else StartFly() end end
    if i.KeyCode==Enum.KeyCode.N          then S.noclip=not S.noclip end
    if i.KeyCode==Enum.KeyCode.H          then task.spawn(Hop) end
end)

-- ════════════════════════════════════════
--  BUILD TABS
-- ════════════════════════════════════════
local tAuto   = makeTab("Auto Farm",  "🎮")
local tCombat = makeTab("Combat",     "⚔️")
local tCoins  = makeTab("Coins",      "💰")
local tCrates = makeTab("Crates",     "📦")
local tMove   = makeTab("Movement",   "✈️")
local tVisual = makeTab("Visuals",    "💀")
local tQoL    = makeTab("QoL",        "🔧")
local tStats  = makeTab("Stats",      "📊")
local tInfo   = makeTab("Info",       "ℹ️")

-- activate first tab
tabs[1].btn.MouseButton1Click:Fire()

-- ── 🎮 AUTO FARM ──────────────────────────
Section(tAuto,"Automation")
Toggle(tAuto,"🚀 Auto Farm (All-in-One)",false,function(v)
    S.autoFarm=v; S.autoQueue=v; S.autoAccept=v; S.autoVote=v; S.autoCollect=v; S.autoReturn=v
    Notif("Auto Farm",v and "All automation ON." or "OFF.")
end)
Toggle(tAuto,"Auto Queue",false,function(v) S.autoQueue=v end)
Toggle(tAuto,"Auto Requeue",false,function(v) S.autoRequeue=v end)
Toggle(tAuto,"Auto Accept Match",false,function(v) S.autoAccept=v end)
Toggle(tAuto,"Auto Vote",false,function(v) S.autoVote=v end)
Toggle(tAuto,"Auto Return to Lobby",false,function(v) S.autoReturn=v end)
Toggle(tAuto,"Auto Collect Pickups",false,function(v) S.autoCollect=v end)
Toggle(tAuto,"AFK Farm Mode",false,function(v) S.afk=v; S.autoQueue=v end)
Toggle(tAuto,"Auto Claim Daily Reward",false,function(v) if v then task.spawn(Daily) end end)
Dropdown(tAuto,"Queue Mode",{"1v1","2v2","3v3","4v4"},function(v) S.queueMode=v end)
Section(tAuto,"Manual")
Button(tAuto,"📍 Teleport to Queue Pad",function()
    local pad=FindPad(S.queueMode)
    if pad then TP(CFrame.new(pad.Position+Vector3.new(0,4,0))); Notif("📍 Pad","Teleported to "..S.queueMode)
    else JoinQueue(); Notif("📍 Pad","Fired queue remotes.") end
end)
Button(tAuto,"✅ Accept Match Now",      function() Accept() end)
Button(tAuto,"🗳️ Vote Now",             function() Vote()   end)
Button(tAuto,"🏠 Return to Lobby",       function() ToLobby() end)
Button(tAuto,"🎁 Claim Daily Reward",    function() Daily()  end)
Toggle(tAuto,"Auto Spin Crates",false,function(v) S.autoSpin=v end)
Slider(tAuto,"Spin Delay (s)",0,10,2,function(v) S.spinDelay=v end)

-- ── ⚔️ COMBAT ─────────────────────────────
Section(tCombat,"Weapons & Abilities")
Toggle(tCombat,"Auto Equip Best Weapon",false,function(v) S.autoEquip=v; if v then EquipBest() end end)
Toggle(tCombat,"Auto Equip Charm",false,function(v) S.autoCharm=v; if v then EquipCharm() end end)
Toggle(tCombat,"⚡ No Ability Cooldown",false,function(v)
    S.noCd=v; Notif("Cooldown",v and "Abilities ready instantly." or "Restored.")
end)
Toggle(tCombat,"💨 No Dash Cooldown",false,function(v) S.noDash=v end)
Button(tCombat,"⚔️ Equip Best Weapon Now",function() EquipBest() end)
Button(tCombat,"💎 Equip Best Charm Now", function() EquipCharm() end)
Button(tCombat,"🔍 Dump Weapon Remotes",function()
    print("[Phantom X] Weapon/ability remotes:")
    for _,v in ipairs(ReplicatedStorage:GetDescendants()) do
        if v:IsA("RemoteEvent") or v:IsA("RemoteFunction") then
            local n=v.Name:lower()
            if n:match("equip") or n:match("weapon") or n:match("ability") or n:match("charm") or n:match("dash") then
                print("  ["..v.ClassName.."] "..v:GetFullName())
            end
        end
    end
    Notif("Remotes","Check output.")
end)

-- ── 💰 COINS ──────────────────────────────
Section(tCoins,"Currency")
local coinAmt=50000
Slider(tCoins,"Amount",1000,1000000,50000,function(v) coinAmt=v end)
Button(tCoins,"💰 Give Coins",function() GiveCoins(coinAmt) end)
Button(tCoins,"🔍 Dump Economy Remotes",function()
    print("[Phantom X] Economy remotes:")
    local kw={"coin","cash","gem","money","credit","earn","grant","reward","currency"}
    for _,v in ipairs(ReplicatedStorage:GetDescendants()) do
        if v:IsA("RemoteEvent") or v:IsA("RemoteFunction") then
            local n=v.Name:lower()
            for _,k in ipairs(kw) do
                if n:match(k) then print("  ["..v.ClassName.."] "..v:GetFullName()); break end
            end
        end
    end
    Notif("Remotes","Check output.")
end)

-- ── 📦 CRATES ─────────────────────────────
Section(tCrates,"Spins & Crates")
Toggle(tCrates,"Auto Spin / Open Crates",false,function(v) S.autoSpin=v end)
Slider(tCrates,"Spin Delay (s)",1,15,2,function(v) S.spinDelay=v end)
Button(tCrates,"🎰 Spin Now",function() Spin(); Notif("🎰 Spin","Fired.") end)

-- ── ✈️ MOVEMENT ──────────────────────────
Section(tMove,"Fly")
Toggle(tMove,"✈️ Fly [F]",false,function(v) if v then StartFly() else StopFly() end end)
Slider(tMove,"Fly Speed",10,500,80,function(v) S.flySpeed=v end)
Section(tMove,"Ground")
Toggle(tMove,"👻 Noclip [N]",false,function(v) S.noclip=v end)
Slider(tMove,"Walk Speed",16,500,16,function(v) S.ws=v; local h=Hum(); if h then h.WalkSpeed=v end end)
Slider(tMove,"Jump Power",50,500,50,function(v) S.jp=v; local h=Hum(); if h then h.JumpPower=v end end)
Section(tMove,"Teleport")
Button(tMove,"Teleport to Spawn",function()
    local sp=Workspace:FindFirstChildOfClass("SpawnLocation")
    if sp then TP(sp.CFrame+Vector3.new(0,5,0)); Notif("Spawn","Teleported.")
    else Notif("Spawn","No spawn found.") end
end)

-- ── 💀 VISUALS ────────────────────────────
Section(tVisual,"Character")
Toggle(tVisual,"💀 Skeleton Mode",false,function(v) Skeleton(v); Notif("Skeleton",v and "ON" or "OFF") end)
Section(tVisual,"Performance")
Toggle(tVisual,"⚡ FPS Boost",false,function(v) FPSBoost(v) end)
Toggle(tVisual,"🛡️ Anti-Lag (hide textures)",false,function(v)
    S.antiLag=v
    if v then pcall(function()
        for _,t in ipairs(Workspace:GetDescendants()) do
            if t:IsA("Texture") or t:IsA("Decal") then t.Transparency=1 end
        end
    end); Notif("Anti-Lag","Textures hidden.") end
end)

-- ── 🔧 QOL ────────────────────────────────
Section(tQoL,"Quality of Life")
Toggle(tQoL,"Anti-AFK",true,function(v) S.antiAfk=v end)
Toggle(tQoL,"Auto Respawn",false,function(v) S.autoRespawn=v end)
Toggle(tQoL,"Rejoin if Kicked",false,function(v) S.rejoin=v end)
Button(tQoL,"🔀 Server Hop [H]",function() task.spawn(Hop) end)
Button(tQoL,"🔄 Rejoin Now",function()
    Notif("Rejoin","Rejoining..."); task.wait(1)
    pcall(function() TeleportService:Teleport(PID,LP) end)
end)
Button(tQoL,"🔍 Dump ALL Remotes",function()
    print("[Phantom X] All remotes:")
    for _,v in ipairs(ReplicatedStorage:GetDescendants()) do
        if v:IsA("RemoteEvent") or v:IsA("RemoteFunction") then
            print("  ["..v.ClassName.."] "..v:GetFullName())
        end
    end
    Notif("Remotes","Check output.")
end)

-- ── 📊 STATS ─────────────────────────────
Section(tStats,"Session Stats")
Button(tStats,"📊 Print Stats",function()
    local e=math.floor(tick()-S.t0)
    print("═══ Phantom X ═══")
    print("Kills: "..S.kills.." | Wins: "..S.wins.." | Losses: "..S.losses)
    print("Streak: "..S.streak.." | Best: "..S.best.." | Last: "..S.last)
    print("Coins: "..S.coins.." | Uptime: "..e.."s")
    print("═════════════════")
    Notif("📊 Stats","Printed to output.")
end)
Button(tStats,"🔥 Regain Last Streak",function() RegainStreak() end)
Button(tStats,"Reset Session Stats",function()
    S.kills=0;S.wins=0;S.losses=0;S.streak=0;S.coins=0;S.t0=tick()
    Notif("Stats","Reset.")
end)

-- ── ℹ️ INFO ──────────────────────────────
Section(tInfo,"Keybinds")
local function InfoLine(tab,txt)
    local f=mkFrame(UDim2.new(1,-4,0,28),nil,C.btn,tab.scroll)
    mkCorner(6,f); f.LayoutOrder=tab.items; tab.items+=1
    local l=mkLabel(txt,12,C.sub,Enum.Font.Gotham,f)
    l.Size=UDim2.new(1,-10,1,0); l.Position=UDim2.new(0,10,0,0)
end
InfoLine(tInfo,"[RightShift] — Toggle UI")
InfoLine(tInfo,"[F]          — Fly on/off")
InfoLine(tInfo,"[N]          — Noclip on/off")
InfoLine(tInfo,"[H]          — Server Hop")
Section(tInfo,"About")
InfoLine(tInfo,"⚡ Phantom X — Murders vs Sheriffs Duels")
InfoLine(tInfo,"Red21 Games edition")
InfoLine(tInfo,"Mini-bar: drag it, [+] to reopen")

-- ════════════════════════════════════════
--  MAIN LOOP
-- ════════════════════════════════════════
local T={q=0,a=0,v=0,col=0,sp=0,eq=0,ch=0}
RunService.Heartbeat:Connect(function()
    local now=tick()
    if (S.autoQueue or S.afk) and now-T.q>8    then T.q=now;   task.spawn(JoinQueue) end
    if S.autoAccept            and now-T.a>2    then T.a=now;   Accept() end
    if S.autoVote              and now-T.v>3    then T.v=now;   Vote()   end
    if S.autoCollect           and now-T.col>2  then T.col=now; task.spawn(Collect) end
    if S.autoSpin              and now-T.sp>S.spinDelay then T.sp=now; Spin() end
    if S.autoEquip             and now-T.eq>5   then T.eq=now;  task.spawn(EquipBest) end
    if S.autoCharm             and now-T.ch>5   then T.ch=now;  task.spawn(EquipCharm) end
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

print("[Phantom X] Ready! All systems go.")
Notif("⚡ Phantom X","[F] fly  [N] noclip  [RightShift] toggle  [H] hop")
