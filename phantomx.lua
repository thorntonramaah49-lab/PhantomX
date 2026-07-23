-- ⚡ Phantom X | Murders vs Sheriffs Duels | Red21 Games
-- Mobile-compatible | Zero external dependencies
warn("[Phantom X] Starting...")

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

-- Wait for LocalPlayer to be ready
local LP = Players.LocalPlayer or Players:GetPropertyChangedSignal("LocalPlayer"):Wait()
local Cam = Workspace.CurrentCamera
local PID = game.PlaceId

-- Confirm script is running with a Roblox notification
pcall(function()
    StarterGui:SetCore("SendNotification", {
        Title = "⚡ Phantom X",
        Text = "Loading... please wait",
        Duration = 4,
    })
end)

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
--  GUI SETUP
-- ════════════════════════════════════════
if _G.PhantomX then pcall(function() _G.PhantomX:Destroy() end) end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name           = "PhantomX"
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.DisplayOrder   = 999
ScreenGui.ResetOnSpawn   = false
ScreenGui.IgnoreGuiInset = true

-- Try every known GUI parent method for mobile executors
local function mountGui()
    -- gethui() = undetectable container, supported by Delta, Fluxus, etc.
    if gethui then
        local ok = pcall(function() ScreenGui.Parent = gethui() end)
        if ok then return end
    end
    -- CoreGui works on most executors
    local ok2 = pcall(function() ScreenGui.Parent = game:GetService("CoreGui") end)
    if ok2 then return end
    -- Last resort: PlayerGui
    pcall(function() ScreenGui.Parent = LP:WaitForChild("PlayerGui", 10) end)
end
mountGui()
_G.PhantomX = ScreenGui

warn("[Phantom X] GUI mounted to: " .. tostring(ScreenGui.Parent))

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
    border  = Color3.fromRGB(60, 40, 100),
}

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

-- ── DRAGGABLE (works with touch + mouse) ─
local function makeDraggable(handle, frame)
    local dragging = false
    local dragStart, startPos

    local function onStart(pos)
        dragging = true
        dragStart = pos
        startPos = frame.Position
    end
    local function onMove(pos)
        if not dragging then return end
        local d = pos - dragStart
        frame.Position = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + d.X,
            startPos.Y.Scale, startPos.Y.Offset + d.Y
        )
    end
    local function onEnd() dragging = false end

    -- Mouse
    handle.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            onStart(Vector2.new(i.Position.X, i.Position.Y))
        elseif i.UserInputType == Enum.UserInputType.Touch then
            onStart(Vector2.new(i.Position.X, i.Position.Y))
        end
    end)
    handle.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1
        or i.UserInputType == Enum.UserInputType.Touch then
            onEnd()
        end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseMovement
        or i.UserInputType == Enum.UserInputType.Touch then
            onMove(Vector2.new(i.Position.X, i.Position.Y))
        end
    end)
end

-- ── MAIN WINDOW (sized for mobile) ───────
local Win = mkFrame(UDim2.new(0,340,0,460), UDim2.new(0.5,-170,0.5,-230), C.bg, ScreenGui)
Win.Active = true; mkCorner(12,Win); mkStroke(C.border,1.5,Win)

local TitleBar = mkFrame(UDim2.new(1,0,0,42), nil, C.panel, Win)
mkCorner(12,TitleBar)
local TBFix = mkFrame(UDim2.new(1,0,0,12), UDim2.new(0,0,1,-12), C.panel, TitleBar); TBFix.ZIndex=2

local TitleIcon = mkLabel("⚡",18,C.accent,Enum.Font.GothamBold,TitleBar)
TitleIcon.Size=UDim2.new(0,30,1,0); TitleIcon.Position=UDim2.new(0,10,0,0)
TitleIcon.TextXAlignment=Enum.TextXAlignment.Center

local TitleLbl = mkLabel("Phantom X",15,C.text,Enum.Font.GothamBold,TitleBar)
TitleLbl.Size=UDim2.new(1,-110,1,0); TitleLbl.Position=UDim2.new(0,42,0,0)

local SubLbl = mkLabel("MvS Duels",11,C.sub,Enum.Font.Gotham,TitleBar)
SubLbl.Size=UDim2.new(1,-110,0,14); SubLbl.Position=UDim2.new(0,42,0,22)

local function mkTitleBtn(icon, xoff, col)
    local b=Instance.new("TextButton")
    b.Size=UDim2.new(0,30,0,30); b.Position=UDim2.new(1,xoff,0.5,-15)
    b.BackgroundColor3=col; b.Text=icon
    b.TextColor3=C.text; b.TextSize=15; b.Font=Enum.Font.GothamBold
    b.BorderSizePixel=0; b.Parent=TitleBar; mkCorner(6,b); return b
end
local MinBtn   = mkTitleBtn("−",-66,C.btn)
local CloseBtn = mkTitleBtn("✕",-32,Color3.fromRGB(180,50,50))

makeDraggable(TitleBar, Win)

-- ── MINI BAR ─────────────────────────────
local Mini = mkFrame(UDim2.new(0,200,0,40), UDim2.new(0.5,-100,0,10), C.bg, ScreenGui)
Mini.Active=true; Mini.Visible=false; mkCorner(10,Mini); mkStroke(C.accent,1.5,Mini)
local MiniLbl = mkLabel("⚡ Phantom X",13,C.accent,Enum.Font.GothamBold,Mini)
MiniLbl.Size=UDim2.new(1,-46,1,0); MiniLbl.Position=UDim2.new(0,10,0,0)
local MiniOpen = Instance.new("TextButton")
MiniOpen.Size=UDim2.new(0,34,0,28); MiniOpen.Position=UDim2.new(1,-38,0.5,-14)
MiniOpen.BackgroundColor3=C.accent; MiniOpen.Text="+"; MiniOpen.TextColor3=C.text
MiniOpen.TextSize=18; MiniOpen.Font=Enum.Font.GothamBold; MiniOpen.BorderSizePixel=0
MiniOpen.Parent=Mini; mkCorner(6,MiniOpen)
makeDraggable(Mini, Mini)

local function SetUI(open)
    S.uiOpen=open; Win.Visible=open; Mini.Visible=not open
end
MinBtn.MouseButton1Click:Connect(function()   SetUI(false) end)
CloseBtn.MouseButton1Click:Connect(function() SetUI(false) end)
MiniOpen.MouseButton1Click:Connect(function() SetUI(true)  end)
-- Touch events for mobile buttons
MinBtn.Activated:Connect(function()   SetUI(false) end)
CloseBtn.Activated:Connect(function() SetUI(false) end)
MiniOpen.Activated:Connect(function() SetUI(true)  end)

-- ── TAB SYSTEM ───────────────────────────
local TabBar = mkFrame(UDim2.new(0,100,1,-42), UDim2.new(0,0,0,42), C.panel, Win)
mkStroke(C.border,0.5,TabBar)
local TBList = Instance.new("UIListLayout"); TBList.SortOrder=Enum.SortOrder.LayoutOrder; TBList.Parent=TabBar

local ContentArea = mkFrame(UDim2.new(1,-102,1,-44), UDim2.new(0,102,0,43), C.bg, Win)

local activeTab = nil
local tabs = {}

local function makeTab(name, icon)
    local btn=Instance.new("TextButton")
    btn.Size=UDim2.new(1,0,0,38)
    btn.BackgroundColor3=C.panel; btn.Text=""
    btn.BorderSizePixel=0; btn.LayoutOrder=#tabs+1; btn.Parent=TabBar

    local lbl=mkLabel(icon.."\n"..name,10,C.sub,Enum.Font.GothamMedium,btn)
    lbl.Size=UDim2.new(1,0,1,0)
    lbl.TextXAlignment=Enum.TextXAlignment.Center
    lbl.TextWrapped=true

    local frame=mkFrame(UDim2.new(1,0,1,0),nil,C.bg,ContentArea)
    frame.Visible=false
    local scroll=Instance.new("ScrollingFrame")
    scroll.Size=UDim2.new(1,-4,1,-4); scroll.Position=UDim2.new(0,2,0,2)
    scroll.BackgroundTransparency=1; scroll.BorderSizePixel=0
    scroll.ScrollBarThickness=4; scroll.ScrollBarImageColor3=C.accent
    scroll.CanvasSize=UDim2.new(0,0,0,0); scroll.AutomaticCanvasSize=Enum.AutomaticSize.Y
    scroll.ScrollingDirection=Enum.ScrollingDirection.Y
    scroll.Parent=frame
    local list=Instance.new("UIListLayout")
    list.SortOrder=Enum.SortOrder.LayoutOrder; list.Padding=UDim.new(0,4)
    list.Parent=scroll
    mkPad(6,6,6,6,scroll)

    local tab={btn=btn,frame=frame,scroll=scroll,lbl=lbl,items=0}

    local function activate()
        if activeTab then
            activeTab.frame.Visible=false
            activeTab.lbl.TextColor3=C.sub
            activeTab.btn.BackgroundColor3=C.panel
        end
        activeTab=tab; frame.Visible=true
        lbl.TextColor3=C.accent; btn.BackgroundColor3=C.btn
    end
    btn.MouseButton1Click:Connect(activate)
    btn.Activated:Connect(activate)

    table.insert(tabs,tab); return tab
end

-- ── WIDGETS ──────────────────────────────
local function Section(tab, title)
    local f=mkFrame(UDim2.new(1,-4,0,22),nil,Color3.fromRGB(0,0,0,0),tab.scroll)
    f.BackgroundTransparency=1; f.LayoutOrder=tab.items; tab.items+=1
    local l=mkLabel("  "..title:upper(),10,C.accent,Enum.Font.GothamBold,f)
    l.Size=UDim2.new(1,0,1,0)
    mkFrame(UDim2.new(1,0,0,1),UDim2.new(0,0,1,-1),C.border,f)
end

local function Toggle(tab, label, default, cb)
    local f=mkFrame(UDim2.new(1,-4,0,40),nil,C.btn,tab.scroll)
    mkCorner(8,f); f.LayoutOrder=tab.items; tab.items+=1
    local l=mkLabel(label,12,C.text,Enum.Font.GothamMedium,f)
    l.Size=UDim2.new(1,-54,1,0); l.Position=UDim2.new(0,8,0,0)
    l.TextWrapped=true

    local pill=mkFrame(UDim2.new(0,40,0,22),UDim2.new(1,-48,0.5,-11),default and C.on or C.off,f)
    mkCorner(11,pill)
    local dot=mkFrame(UDim2.new(0,16,0,16),default and UDim2.new(1,-19,0.5,-8) or UDim2.new(0,3,0.5,-8),Color3.new(1,1,1),pill)
    mkCorner(8,dot)

    local val=default or false
    local ti=TweenInfo.new(0.15)
    local btn=Instance.new("TextButton")
    btn.Size=UDim2.new(1,0,1,0); btn.BackgroundTransparency=1; btn.Text=""; btn.Parent=f

    local function toggle()
        val=not val
        TweenService:Create(pill,ti,{BackgroundColor3=val and C.on or C.off}):Play()
        TweenService:Create(dot,ti,{Position=val and UDim2.new(1,-19,0.5,-8) or UDim2.new(0,3,0.5,-8)}):Play()
        pcall(cb,val)
    end
    btn.MouseButton1Click:Connect(toggle)
    btn.Activated:Connect(toggle)
    if default then pcall(cb,true) end
    return toggle
end

local function Button(tab, label, cb)
    local f=mkFrame(UDim2.new(1,-4,0,38),nil,C.accent2,tab.scroll)
    mkCorner(8,f); f.LayoutOrder=tab.items; tab.items+=1
    mkStroke(C.accent,0.8,f)
    local btn=Instance.new("TextButton")
    btn.Size=UDim2.new(1,0,1,0); btn.BackgroundTransparency=1
    btn.Text=label; btn.TextColor3=C.text; btn.TextSize=12
    btn.Font=Enum.Font.GothamBold; btn.TextWrapped=true; btn.Parent=f
    btn.MouseButton1Click:Connect(function() pcall(cb) end)
    btn.Activated:Connect(function() pcall(cb) end)
end

local function Slider(tab, label, min, max, default, cb)
    local f=mkFrame(UDim2.new(1,-4,0,56),nil,C.btn,tab.scroll)
    mkCorner(8,f); f.LayoutOrder=tab.items; tab.items+=1
    local lbl=mkLabel(label..": "..default,12,C.text,Enum.Font.GothamMedium,f)
    lbl.Size=UDim2.new(1,-10,0,18); lbl.Position=UDim2.new(0,8,0,5)

    local track=mkFrame(UDim2.new(1,-16,0,8),UDim2.new(0,8,0,34),C.panel,f)
    mkCorner(4,track); mkStroke(C.border,0.5,track)
    local fill=mkFrame(UDim2.new((default-min)/(max-min),0,1,0),nil,C.accent,track)
    mkCorner(4,fill)
    local nub=mkFrame(UDim2.new(0,18,0,18),UDim2.new((default-min)/(max-min),0,0.5,-9),C.text,track)
    mkCorner(9,nub)

    local dragging=false
    local function update(x)
        local rel=math.clamp((x-track.AbsolutePosition.X)/track.AbsoluteSize.X,0,1)
        local v=math.floor(min+(max-min)*rel)
        fill.Size=UDim2.new(rel,0,1,0)
        nub.Position=UDim2.new(rel,0,0.5,-9)
        lbl.Text=label..": "..v
        pcall(cb,v)
    end

    local function onInput(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1
        or i.UserInputType==Enum.UserInputType.Touch then
            dragging=true; update(i.Position.X)
        end
    end
    local function onEnd(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1
        or i.UserInputType==Enum.UserInputType.Touch then dragging=false end
    end

    nub.InputBegan:Connect(onInput)
    track.InputBegan:Connect(onInput)
    UserInputService.InputEnded:Connect(onEnd)
    UserInputService.InputChanged:Connect(function(i)
        if dragging and (i.UserInputType==Enum.UserInputType.MouseMovement
        or i.UserInputType==Enum.UserInputType.Touch) then
            update(i.Position.X)
        end
    end)
    pcall(cb,default)
end

local function Dropdown(tab, label, options, cb)
    local f=mkFrame(UDim2.new(1,-4,0,38),nil,C.btn,tab.scroll)
    mkCorner(8,f); f.LayoutOrder=tab.items; tab.items+=1
    local lbl=mkLabel(label..": "..options[1],12,C.text,Enum.Font.GothamMedium,f)
    lbl.Size=UDim2.new(1,-36,1,0); lbl.Position=UDim2.new(0,8,0,0)
    local arr=mkLabel("▾",14,C.accent,Enum.Font.GothamBold,f)
    arr.Size=UDim2.new(0,24,1,0); arr.Position=UDim2.new(1,-28,0,0)
    arr.TextXAlignment=Enum.TextXAlignment.Center
    local cur=1; pcall(cb,options[1])
    local btn=Instance.new("TextButton")
    btn.Size=UDim2.new(1,0,1,0); btn.BackgroundTransparency=1; btn.Text=""; btn.Parent=f
    local function cycle()
        cur=cur%#options+1; lbl.Text=label..": "..options[cur]; pcall(cb,options[cur])
    end
    btn.MouseButton1Click:Connect(cycle)
    btn.Activated:Connect(cycle)
end

-- ── NOTIFICATION ─────────────────────────
local notifQ={}
local function Notif(title, msg)
    pcall(function()
        StarterGui:SetCore("SendNotification",{Title=title,Text=msg,Duration=4})
    end)
    -- also show in-GUI notif
    pcall(function()
        local nf=mkFrame(UDim2.new(0,220,0,0),UDim2.new(1,-228,1,-8),C.panel,ScreenGui)
        nf.AutomaticSize=Enum.AutomaticSize.Y; nf.AnchorPoint=Vector2.new(0,1)
        nf.Position=UDim2.new(1,-228,1,-8); mkCorner(8,nf); mkStroke(C.accent,1,nf)
        mkPad(8,8,10,10,nf)
        local list=Instance.new("UIListLayout"); list.SortOrder=Enum.SortOrder.LayoutOrder; list.Parent=nf
        local tl=mkLabel(title,12,C.accent,Enum.Font.GothamBold,nf); tl.LayoutOrder=0
        local ml=mkLabel(msg,11,C.text,Enum.Font.Gotham,nf)
        ml.TextWrapped=true; ml.Size=UDim2.new(1,0,0,0)
        ml.AutomaticSize=Enum.AutomaticSize.Y; ml.LayoutOrder=1
        for _,n in ipairs(notifQ) do
            pcall(function()
                TweenService:Create(n,TweenInfo.new(0.2),{Position=UDim2.new(n.Position.X.Scale,n.Position.X.Offset,1,n.Position.Y.Offset-55)}):Play()
            end)
        end
        table.insert(notifQ,nf)
        task.delay(4,function()
            pcall(function()
                TweenService:Create(nf,TweenInfo.new(0.3),{BackgroundTransparency=1}):Play()
                task.wait(0.3); nf:Destroy()
                local idx=table.find(notifQ,nf)
                if idx then table.remove(notifQ,idx) end
            end)
        end)
    end)
end

-- ════════════════════════════════════════
--  GAME FUNCTIONS
-- ════════════════════════════════════════
local function Root()  local c=LP.Character; return c and c:FindFirstChild("HumanoidRootPart") end
local function Hum()   local c=LP.Character; return c and c:FindFirstChildOfClass("Humanoid") end
local function TP(cf)  local r=Root(); if r then pcall(function() r.CFrame=cf end) end end

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

local afkT=tick()
RunService.Heartbeat:Connect(function()
    if not S.antiAfk then return end
    if tick()-afkT>55 then afkT=tick(); pcall(function() local h=Hum(); if h then h.Jump=true end end) end
end)

RunService.Stepped:Connect(function()
    if not S.noclip then return end
    pcall(function()
        local c=LP.Character; if not c then return end
        for _,p in ipairs(c:GetDescendants()) do
            if p:IsA("BasePart") and p.CanCollide then p.CanCollide=false end
        end
    end)
end)

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
    FRA({"GiveCoins","AddCoins","GrantCoins","GiveCash","AddCash","GrantCash","CoinReward","EarnCoins","AddMoney"},amt)
    pcall(function()
        local ls=LP:FindFirstChild("leaderstats")
        if ls then for _,v in ipairs(ls:GetChildren()) do
            if v:IsA("IntValue") or v:IsA("NumberValue") then v.Value+=amt end
        end end
    end)
    Notif("💰 Coins","Sent +"..amt)
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
    Notif("🔥 Streak","Restored "..S.last)
end
local function Hop()
    Notif("🔀 Hop","Finding server...")
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
    S.fpsBoost=on; pcall(function()
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
    Notif("⚡ FPS",on and "Boosted!" or "Restored.")
end

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
                    Notif("🏆 Win!","Streak: "..S.streak)
                end
                if n:match("coin") or n:match("cash") or n:match("gem") then S.coins=val end
                if n:match("streak") then S.streak=val end
            end)
        end
    end
end)

-- ════════════════════════════════════════
--  BUILD TABS
-- ════════════════════════════════════════
local tAuto   = makeTab("Farm",     "🎮")
local tCombat = makeTab("Combat",   "⚔️")
local tCoins  = makeTab("Coins",    "💰")
local tMove   = makeTab("Move",     "✈️")
local tVisual = makeTab("Visual",   "👁")
local tQoL    = makeTab("QoL",      "🔧")
local tStats  = makeTab("Stats",    "📊")

-- activate first
do local function a() if activeTab then activeTab.frame.Visible=false; activeTab.lbl.TextColor3=C.sub; activeTab.btn.BackgroundColor3=C.panel end activeTab=tAuto; tAuto.frame.Visible=true; tAuto.lbl.TextColor3=C.accent; tAuto.btn.BackgroundColor3=C.btn end; a() end

-- 🎮 FARM
Section(tAuto,"Automation")
Toggle(tAuto,"🚀 Auto Farm (All-in-One)",false,function(v)
    S.autoFarm=v; S.autoQueue=v; S.autoAccept=v; S.autoVote=v; S.autoCollect=v; S.autoReturn=v
    Notif("Auto Farm",v and "ON" or "OFF")
end)
Toggle(tAuto,"Auto Queue",false,function(v) S.autoQueue=v end)
Toggle(tAuto,"Auto Accept",false,function(v) S.autoAccept=v end)
Toggle(tAuto,"Auto Vote",false,function(v) S.autoVote=v end)
Toggle(tAuto,"Auto Return to Lobby",false,function(v) S.autoReturn=v end)
Toggle(tAuto,"Auto Collect Pickups",false,function(v) S.autoCollect=v end)
Toggle(tAuto,"Auto Spin Crates",false,function(v) S.autoSpin=v end)
Toggle(tAuto,"AFK Farm Mode",false,function(v) S.afk=v; S.autoQueue=v end)
Toggle(tAuto,"Auto Claim Daily",false,function(v) if v then task.spawn(Daily) end end)
Dropdown(tAuto,"Queue Mode",{"1v1","2v2","3v3","4v4"},function(v) S.queueMode=v end)
Section(tAuto,"Manual")
Button(tAuto,"📍 Join Queue",      function() JoinQueue(); Notif("Queue","Fired.") end)
Button(tAuto,"✅ Accept Match",    function() Accept() end)
Button(tAuto,"🗳️ Vote",           function() Vote() end)
Button(tAuto,"🏠 Return to Lobby", function() ToLobby() end)
Button(tAuto,"🎁 Claim Daily",    function() Daily() end)
Button(tAuto,"🎰 Spin Crate",     function() Spin(); Notif("Crate","Fired.") end)

-- ⚔️ COMBAT
Section(tCombat,"Abilities")
Toggle(tCombat,"⚡ No Ability Cooldown",false,function(v)
    S.noCd=v; Notif("Cooldown",v and "Instant!" or "Normal")
end)
Toggle(tCombat,"💨 No Dash Cooldown",false,function(v) S.noDash=v end)
Toggle(tCombat,"Auto Equip Best Weapon",false,function(v) S.autoEquip=v; if v then EquipBest() end end)
Toggle(tCombat,"Auto Equip Charm",false,function(v) S.autoCharm=v; if v then EquipCharm() end end)
Button(tCombat,"⚔️ Equip Best Weapon", function() EquipBest() end)
Button(tCombat,"💎 Equip Best Charm",  function() EquipCharm() end)

-- 💰 COINS
Section(tCoins,"Currency")
local coinAmt=50000
Slider(tCoins,"Amount",1000,500000,50000,function(v) coinAmt=v end)
Button(tCoins,"💰 Give Coins", function() GiveCoins(coinAmt) end)

-- ✈️ MOVEMENT
Section(tMove,"Fly")
Toggle(tMove,"✈️ Fly",false,function(v) if v then StartFly() else StopFly() end end)
Slider(tMove,"Fly Speed",10,300,80,function(v) S.flySpeed=v end)
Section(tMove,"Ground")
Toggle(tMove,"👻 Noclip",false,function(v) S.noclip=v end)
Slider(tMove,"Walk Speed",16,300,16,function(v) S.ws=v; local h=Hum(); if h then h.WalkSpeed=v end end)
Slider(tMove,"Jump Power",50,300,50,function(v) S.jp=v; local h=Hum(); if h then h.JumpPower=v end end)
Section(tMove,"Teleport")
Button(tMove,"Teleport to Spawn",function()
    local sp=Workspace:FindFirstChildOfClass("SpawnLocation")
    if sp then TP(sp.CFrame+Vector3.new(0,5,0)); Notif("Spawn","Done.") else Notif("Spawn","Not found.") end
end)

-- 👁 VISUAL
Section(tVisual,"Character")
Toggle(tVisual,"💀 Skeleton Mode",false,function(v) Skeleton(v) end)
Section(tVisual,"Performance")
Toggle(tVisual,"⚡ FPS Boost",false,function(v) FPSBoost(v) end)
Toggle(tVisual,"🛡️ Anti-Lag",false,function(v)
    S.antiLag=v
    if v then pcall(function()
        for _,t in ipairs(Workspace:GetDescendants()) do
            if t:IsA("Texture") or t:IsA("Decal") then t.Transparency=1 end
        end
    end); Notif("Anti-Lag","ON") end
end)

-- 🔧 QOL
Section(tQoL,"Quality of Life")
Toggle(tQoL,"Anti-AFK",true,function(v) S.antiAfk=v end)
Toggle(tQoL,"Auto Respawn",false,function(v) S.autoRespawn=v end)
Button(tQoL,"🔀 Server Hop", function() task.spawn(Hop) end)
Button(tQoL,"🔄 Rejoin Now", function()
    Notif("Rejoin","..."); task.wait(1)
    pcall(function() TeleportService:Teleport(PID,LP) end)
end)
Button(tQoL,"🔍 Dump Remotes",function()
    print("[PX] Remotes:")
    for _,v in ipairs(ReplicatedStorage:GetDescendants()) do
        if v:IsA("RemoteEvent") or v:IsA("RemoteFunction") then print("  "..v:GetFullName()) end
    end
    Notif("Remotes","Check output.")
end)

-- 📊 STATS
Section(tStats,"Session")
Button(tStats,"📊 Print Stats",function()
    local e=math.floor(tick()-S.t0)
    print("═══ Phantom X ═══")
    print("K:"..S.kills.." W:"..S.wins.." L:"..S.losses.." Streak:"..S.streak.." Best:"..S.best)
    print("Coins:"..S.coins.." Uptime:"..e.."s")
    Notif("Stats","Printed.")
end)
Button(tStats,"🔥 Restore Last Streak", function() RegainStreak() end)
Button(tStats,"Reset Stats",function()
    S.kills=0;S.wins=0;S.losses=0;S.streak=0;S.coins=0;S.t0=tick(); Notif("Stats","Reset.")
end)

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
                if t:match("lobby") or t:match("return") then pcall(function() v.MouseButton1Click:Fire() end) end
            end
        end
    end
end)

warn("[Phantom X] Ready!")
Notif("⚡ Phantom X","GUI loaded! Drag the title bar to move it.")
