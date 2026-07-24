-- ⚡ Phantom X | Murders vs Sheriffs Duels
-- v6 — zero external deps, sidebar panel like the screenshot
if getgenv and getgenv().PhantomX_v6 then return end
if getgenv then getgenv().PhantomX_v6 = true end
warn("[PX] Starting…")

-- ════════════════════════════════════
--  SERVICES
-- ════════════════════════════════════
local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")
local RepStorage = game:GetService("ReplicatedStorage")
local UIS        = game:GetService("UserInputService")
local TweenSvc   = game:GetService("TweenService")
local Lighting   = game:GetService("Lighting")
local WS         = game:GetService("Workspace")
local TpSvc      = game:GetService("TeleportService")
local HttpSvc    = game:GetService("HttpService")
local Debris     = game:GetService("Debris")
local StarterGui = game:GetService("StarterGui")

local LP = Players.LocalPlayer
if not LP then Players:GetPropertyChangedSignal("LocalPlayer"):Wait() LP = Players.LocalPlayer end
local Cam = WS.CurrentCamera
local PID = game.PlaceId

-- ════════════════════════════════════
--  STATE
-- ════════════════════════════════════
local G = {
    autoQueue=false, queueMode="1v1",
    autoAccept=false, autoVote=false, autoReturn=false,
    autoCollect=false, autoSpin=false, spinDelay=2,
    autoshoot=false, autoshootDist=300, autoshootCD=2.5,
    triggerbot=false, hitbox=false, hitboxSize=13,
    noGunCD=false, autoKnife=false, knifeDist=300, knifeCD=2,
    streakRegain=false, streakProtect=false,
    kills=0, wins=0, losses=0, streak=0, best=0, coins=0,
    fly=false, flySpeed=80,
    noclip=false, ws=16, jp=50,
    espEnabled=false,
    antiAfk=true, autoRespawn=false,
    inMatch=false, matchEnemies={},
}

-- ════════════════════════════════════
--  GUI ROOT — mount with every method
-- ════════════════════════════════════
if _G.PX_ROOT then pcall(function() _G.PX_ROOT:Destroy() end) end

local ROOT = Instance.new("ScreenGui")
ROOT.Name           = "PhantomX"
ROOT.ResetOnSpawn   = false
ROOT.IgnoreGuiInset = true
ROOT.DisplayOrder   = 9999
ROOT.Enabled        = true

local function Mount()
    if ROOT.Parent then return end
    if typeof(gethui)=="function" then pcall(function() ROOT.Parent=gethui() end) end
    if not ROOT.Parent and syn and syn.protect_gui then pcall(function() syn.protect_gui(ROOT) ROOT.Parent=game:GetService("CoreGui") end) end
    if not ROOT.Parent then pcall(function() ROOT.Parent=game:GetService("CoreGui") end) end
    if not ROOT.Parent then pcall(function() ROOT.Parent=LP:WaitForChild("PlayerGui",10) end) end
    warn("[PX] GUI parent = "..tostring(ROOT.Parent))
end
Mount()
_G.PX_ROOT = ROOT

task.spawn(function()
    while task.wait(1) do
        if ROOT and not ROOT.Parent then Mount() end
    end
end)

-- ════════════════════════════════════
--  COLOUR PALETTE  (dark + purple)
-- ════════════════════════════════════
local C = {
    win    = Color3.fromRGB(18, 18, 28),
    winB   = Color3.fromRGB(26, 26, 40),
    side   = Color3.fromRGB(22, 22, 35),
    sideHi = Color3.fromRGB(32, 32, 52),
    hdr    = Color3.fromRGB(14, 14, 22),
    accent = Color3.fromRGB(138, 63, 255),
    acc2   = Color3.fromRGB(100, 40, 200),
    text   = Color3.fromRGB(230, 230, 248),
    sub    = Color3.fromRGB(140, 140, 175),
    on     = Color3.fromRGB(68, 207, 110),
    off    = Color3.fromRGB(200, 60,  60),
    card   = Color3.fromRGB(30,  30,  46),
    bord   = Color3.fromRGB(50,  30,  85),
    btnbg  = Color3.fromRGB(36,  36,  56),
}

-- ════════════════════════════════════
--  UI PRIMITIVES
-- ════════════════════════════════════
local function corner(r, p) local c=Instance.new("UICorner") c.CornerRadius=UDim.new(0,r) c.Parent=p end
local function stroke(col,t,p) local s=Instance.new("UIStroke") s.Color=col s.Thickness=t s.ApplyStrokeMode=Enum.ApplyStrokeMode.Border s.Parent=p end
local function pad(t,b,l,r,p) local x=Instance.new("UIPadding") x.PaddingTop=UDim.new(0,t) x.PaddingBottom=UDim.new(0,b) x.PaddingLeft=UDim.new(0,l) x.PaddingRight=UDim.new(0,r) x.Parent=p end

local function newF(sz,pos,col,par,tr)
    local f=Instance.new("Frame")
    f.Size=sz f.Position=pos or UDim2.new(0,0,0,0)
    f.BackgroundColor3=col or C.card
    f.BackgroundTransparency=tr or 0
    f.BorderSizePixel=0 f.Parent=par
    return f
end
local function newL(txt,tsz,col,font,par,xa)
    local l=Instance.new("TextLabel")
    l.Text=txt l.TextSize=tsz or 13
    l.TextColor3=col or C.text
    l.Font=font or Enum.Font.GothamMedium
    l.BackgroundTransparency=1
    l.TextXAlignment=xa or Enum.TextXAlignment.Left
    l.TextTruncate=Enum.TextTruncate.AtEnd
    l.Size=UDim2.new(1,0,1,0)
    l.Parent=par return l
end
local function newBtn(par)
    local b=Instance.new("TextButton")
    b.Size=UDim2.new(1,0,1,0) b.BackgroundTransparency=1
    b.Text="" b.Parent=par return b
end

-- Drag (mouse + touch)
local function MakeDraggable(handle, frame)
    local dragging, dragStart, startPos = false, nil, nil
    local function begin(pos)
        dragging=true dragStart=pos startPos=frame.Position
    end
    handle.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
            begin(Vector2.new(i.Position.X,i.Position.Y))
        end
    end)
    handle.InputEnded:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then dragging=false end
    end)
    UIS.InputChanged:Connect(function(i)
        if dragging and (i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) then
            local d=Vector2.new(i.Position.X,i.Position.Y)-dragStart
            frame.Position=UDim2.new(startPos.X.Scale,startPos.X.Offset+d.X,startPos.Y.Scale,startPos.Y.Offset+d.Y)
        end
    end)
end

-- Notification
local function Notify(title,msg,dur)
    pcall(function() StarterGui:SetCore("SendNotification",{Title=title,Text=msg,Duration=dur or 4}) end)
end

-- ════════════════════════════════════
--  MAIN WINDOW  (mimics the screenshot)
--  620 × 420, centred
-- ════════════════════════════════════
local WIN = newF(UDim2.new(0,620,0,420), UDim2.new(0.5,-310,0.5,-210), C.win, ROOT)
WIN.Active=true corner(10,WIN) stroke(C.bord,1.5,WIN)

-- ── HEADER BAR ──────────────────────
local HDR = newF(UDim2.new(1,0,0,46), UDim2.new(0,0,0,0), C.hdr, WIN)
corner(10,HDR)
newF(UDim2.new(1,0,0,14), UDim2.new(0,0,1,-14), C.hdr, WIN) -- fill bottom corners

-- lightning bolt icon bg
local IconBg = newF(UDim2.new(0,32,0,32), UDim2.new(0,8,0,7), C.acc2, HDR)
corner(8,IconBg)
local IconLbl = newL("⚡",16,Color3.new(1,1,1),Enum.Font.GothamBold,IconBg,Enum.TextXAlignment.Center)

local TitleLbl = newL("Phantom X",15,C.text,Enum.Font.GothamBold,HDR)
TitleLbl.Size=UDim2.new(0,180,0,22) TitleLbl.Position=UDim2.new(0,48,0,5)

local SubLbl = newL("Dev : phantom | v6.0",10,C.sub,Enum.Font.Gotham,HDR)
SubLbl.Size=UDim2.new(0,200,0,14) SubLbl.Position=UDim2.new(0,48,0,25)

-- Undetected tag
local TagBg = newF(UDim2.new(0,94,0,22), UDim2.new(0,242,0,12), Color3.fromRGB(30,80,30), HDR)
corner(5,TagBg) stroke(Color3.fromRGB(68,207,110),1,TagBg)
local TagLbl = newL("✔ UNDETECTED",9,Color3.fromRGB(68,207,110),Enum.Font.GothamBold,TagBg,Enum.TextXAlignment.Center)

-- Window control buttons
local function WinBtn(icon, xoff, bg)
    local b=Instance.new("TextButton")
    b.Size=UDim2.new(0,28,0,28) b.Position=UDim2.new(1,xoff,0.5,-14)
    b.BackgroundColor3=bg b.Text=icon b.TextColor3=C.text
    b.TextSize=12 b.Font=Enum.Font.GothamBold b.BorderSizePixel=0
    b.Parent=HDR corner(6,b) return b
end
local MinBtn = WinBtn("━", -92, C.btnbg)
local MxBtn  = WinBtn("⤢", -60, C.btnbg)
local ClsBtn = WinBtn("✕", -28, Color3.fromRGB(180,45,45))
MakeDraggable(HDR, WIN)

-- ── SIDEBAR ─────────────────────────
local SIDE = newF(UDim2.new(0,170,1,-46), UDim2.new(0,0,0,46), C.side, WIN)
stroke(C.bord,0.8,SIDE)

local SideList = Instance.new("UIListLayout")
SideList.SortOrder = Enum.SortOrder.LayoutOrder
SideList.Padding   = UDim.new(0,2)
SideList.Parent    = SIDE
pad(6,6,4,4,SIDE)

-- Player card at bottom of sidebar
local PlayerCard = newF(UDim2.new(1,-8,0,48), UDim2.new(0,4,1,-54), C.card, SIDE)
corner(8,PlayerCard) pad(4,4,6,6,PlayerCard)
local pcLbl = newL(LP.Name,11,C.text,Enum.Font.GothamBold,PlayerCard)
pcLbl.Size=UDim2.new(1,0,0,18) pcLbl.Position=UDim2.new(0,0,0,2)
local pcSub = newL("MvS Duels",9,C.sub,Enum.Font.Gotham,PlayerCard)
pcSub.Size=UDim2.new(1,0,0,14) pcSub.Position=UDim2.new(0,0,0,22)

-- ── CONTENT ─────────────────────────
local CONT = newF(UDim2.new(1,-172,1,-48), UDim2.new(0,172,0,47), C.winB, WIN)

-- Mini pill (when window hidden)
local MINI = newF(UDim2.new(0,150,0,36), UDim2.new(0.5,-75,0,6), C.hdr, ROOT)
MINI.Visible=false corner(18,MINI) stroke(C.accent,1.5,MINI)
local MiniIco = newL("⚡ Phantom X",12,C.accent,Enum.Font.GothamBold,MINI,Enum.TextXAlignment.Left)
MiniIco.Size=UDim2.new(1,-36,1,0) MiniIco.Position=UDim2.new(0,10,0,0)
local MiniOpen=Instance.new("TextButton")
MiniOpen.Size=UDim2.new(0,28,0,28) MiniOpen.Position=UDim2.new(1,-32,0.5,-14)
MiniOpen.BackgroundColor3=C.accent MiniOpen.Text="+" MiniOpen.TextColor3=Color3.new(1,1,1)
MiniOpen.TextSize=16 MiniOpen.Font=Enum.Font.GothamBold MiniOpen.BorderSizePixel=0
MiniOpen.Parent=MINI corner(14,MiniOpen)
MakeDraggable(MINI,MINI)

local function SetVisible(v)
    WIN.Visible=v MINI.Visible=not v
end
MinBtn.Activated:Connect(function() SetVisible(false) end)
ClsBtn.Activated:Connect(function() SetVisible(false) end)
MxBtn.Activated:Connect(function()
    local big = WIN.Size.X.Offset < 650
    WIN:TweenSize(big and UDim2.new(0,760,0,520) or UDim2.new(0,620,0,420),Enum.EasingDirection.Out,Enum.EasingStyle.Quad,0.2,true)
end)
MiniOpen.Activated:Connect(function() SetVisible(true) end)

-- ════════════════════════════════════
--  TAB SYSTEM
-- ════════════════════════════════════
local activeTab = nil
local tabs      = {}
local tabCount  = 0

local function MakeTab(icon, title)
    tabCount += 1
    local order = tabCount

    -- Sidebar button
    local Btn = Instance.new("TextButton")
    Btn.Size=UDim2.new(1,-8,0,38) Btn.BackgroundColor3=C.side
    Btn.Text="" Btn.BorderSizePixel=0 Btn.LayoutOrder=order
    Btn.Parent=SIDE corner(8,Btn)

    local Row = newF(UDim2.new(1,0,1,0),UDim2.new(0,0,0,0),Color3.new(0,0,0),Btn,1)
    local IcoL = newL(icon,15,C.sub,Enum.Font.GothamMedium,Row)
    IcoL.Size=UDim2.new(0,28,1,0) IcoL.Position=UDim2.new(0,6,0,0) IcoL.TextXAlignment=Enum.TextXAlignment.Center
    local TxtL = newL(title,12,C.sub,Enum.Font.GothamMedium,Row)
    TxtL.Size=UDim2.new(1,-38,1,0) TxtL.Position=UDim2.new(0,36,0,0)

    -- Accent bar (visible when active)
    local Bar = newF(UDim2.new(0,3,0.7,0),UDim2.new(0,0,0.15,0),C.accent,Btn)
    Bar.Visible=false corner(2,Bar)

    -- Content scroll
    local Scroll = Instance.new("ScrollingFrame")
    Scroll.Size=UDim2.new(1,0,1,0) Scroll.BackgroundTransparency=1
    Scroll.BorderSizePixel=0 Scroll.ScrollBarThickness=3
    Scroll.ScrollBarImageColor3=C.accent Scroll.CanvasSize=UDim2.new(0,0,0,0)
    Scroll.AutomaticCanvasSize=Enum.AutomaticSize.Y
    Scroll.ScrollingDirection=Enum.ScrollingDirection.Y
    Scroll.Visible=false Scroll.Parent=CONT
    pad(8,10,8,8,Scroll)
    local List=Instance.new("UIListLayout")
    List.SortOrder=Enum.SortOrder.LayoutOrder List.Padding=UDim.new(0,5) List.Parent=Scroll

    local tab={scroll=Scroll,n=0,btnBg=Btn,bar=Bar,ico=IcoL,lbl=TxtL}

    local function activate()
        if activeTab then
            activeTab.scroll.Visible=false
            activeTab.bar.Visible=false
            activeTab.btnBg.BackgroundColor3=C.side
            activeTab.ico.TextColor3=C.sub
            activeTab.lbl.TextColor3=C.sub
        end
        activeTab=tab
        Scroll.Visible=true Bar.Visible=true
        Btn.BackgroundColor3=C.sideHi
        IcoL.TextColor3=C.accent TxtL.TextColor3=C.text
    end
    Btn.Activated:Connect(activate)
    table.insert(tabs,{tab=tab,activate=activate})
    return tab, activate
end

-- ── WIDGETS ─────────────────────────
local function Section(tab, title)
    tab.n+=1
    local f=newF(UDim2.new(1,-2,0,22),nil,Color3.new(0,0,0),tab.scroll,1)
    f.LayoutOrder=tab.n
    local l=newL("  "..title:upper(),9,C.accent,Enum.Font.GothamBold,f)
    l.Size=UDim2.new(1,0,1,0)
    newF(UDim2.new(1,0,0,1),UDim2.new(0,0,1,-1),C.bord,f)
end

local function Toggle(tab, title, desc, default, cb)
    tab.n+=1
    local h=desc and 46 or 38
    local f=newF(UDim2.new(1,-2,0,h),nil,C.card,tab.scroll)
    corner(8,f) f.LayoutOrder=tab.n

    local tl=newL(title,11,C.text,Enum.Font.GothamMedium,f)
    tl.Size=UDim2.new(1,-58,0,16) tl.Position=UDim2.new(0,10,0,6)
    if desc then
        local dl=newL(desc,9,C.sub,Enum.Font.Gotham,f)
        dl.Size=UDim2.new(1,-58,0,14) dl.Position=UDim2.new(0,10,0,24)
        dl.TextWrapped=true
    end

    local pill=newF(UDim2.new(0,40,0,22),UDim2.new(1,-50,0.5,-11),default and C.on or C.off,f)
    corner(11,pill)
    local dot=newF(UDim2.new(0,16,0,16),default and UDim2.new(1,-19,0.5,-8) or UDim2.new(0,3,0.5,-8),Color3.new(1,1,1),pill)
    corner(8,dot)

    local val=default or false
    local ti=TweenInfo.new(0.12)
    local btn=newBtn(f)
    local function toggle()
        val=not val
        TweenSvc:Create(pill,ti,{BackgroundColor3=val and C.on or C.off}):Play()
        TweenSvc:Create(dot,ti,{Position=val and UDim2.new(1,-19,0.5,-8) or UDim2.new(0,3,0.5,-8)}):Play()
        pcall(cb,val)
    end
    btn.Activated:Connect(toggle)
    if default then pcall(cb,true) end
    return {setValue=function(v) if v~=val then toggle() end}
end

local function Button(tab, title, sub, cb)
    tab.n+=1
    local f=newF(UDim2.new(1,-2,0,38),nil,C.acc2,tab.scroll)
    corner(8,f) stroke(C.accent,0.8,f) f.LayoutOrder=tab.n
    local l=newL(title,11,C.text,Enum.Font.GothamBold,f,Enum.TextXAlignment.Center)
    if sub then
        l.Size=UDim2.new(1,0,0,18) l.Position=UDim2.new(0,0,0,5)
        local sl=newL(sub,9,C.sub,Enum.Font.Gotham,f,Enum.TextXAlignment.Center)
        sl.Size=UDim2.new(1,0,0,14) sl.Position=UDim2.new(0,0,0,22)
    end
    local btn=newBtn(f)
    btn.Activated:Connect(function() pcall(cb) end)
end

local function Slider(tab, title, mn, mx, def, step, cb)
    tab.n+=1
    local f=newF(UDim2.new(1,-2,0,56),nil,C.card,tab.scroll)
    corner(8,f) f.LayoutOrder=tab.n

    local val=def
    local lbl=newL(title..":  "..val,11,C.text,Enum.Font.GothamMedium,f)
    lbl.Size=UDim2.new(1,-8,0,18) lbl.Position=UDim2.new(0,10,0,4)

    local trk=newF(UDim2.new(1,-20,0,8),UDim2.new(0,10,0,34),C.side,f)
    corner(4,trk) stroke(C.bord,0.5,trk)
    local fill=newF(UDim2.new((def-mn)/(mx-mn),0,1,0),nil,C.accent,trk) corner(4,fill)
    local nub=newF(UDim2.new(0,18,0,18),UDim2.new((def-mn)/(mx-mn),0,0.5,-9),Color3.new(1,1,1),trk) corner(9,nub)

    local drag=false
    local function upd(x)
        local r=math.clamp((x-trk.AbsolutePosition.X)/math.max(trk.AbsoluteSize.X,1),0,1)
        val=mn+math.round((mx-mn)*r/(step or 1))*(step or 1)
        fill.Size=UDim2.new(r,0,1,0) nub.Position=UDim2.new(r,0,0.5,-9)
        lbl.Text=title..":  "..val pcall(cb,val)
    end
    local function si(i) if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then drag=true upd(i.Position.X) end end
    trk.InputBegan:Connect(si) nub.InputBegan:Connect(si)
    UIS.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then drag=false end end)
    UIS.InputChanged:Connect(function(i) if drag and(i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) then upd(i.Position.X) end end)
    pcall(cb,def)
end

local function Dropdown(tab, title, opts, cb)
    tab.n+=1
    local f=newF(UDim2.new(1,-2,0,38),nil,C.card,tab.scroll)
    corner(8,f) f.LayoutOrder=tab.n

    local cur=1
    local lbl=newL(title..":  "..opts[1],11,C.text,Enum.Font.GothamMedium,f)
    lbl.Size=UDim2.new(1,-30,1,0) lbl.Position=UDim2.new(0,10,0,0)
    local arr=newL("▾",14,C.accent,Enum.Font.GothamBold,f,Enum.TextXAlignment.Center)
    arr.Size=UDim2.new(0,24,1,0) arr.Position=UDim2.new(1,-28,0,0)

    pcall(cb,opts[1])
    local btn=newBtn(f)
    btn.Activated:Connect(function()
        cur=cur%#opts+1 lbl.Text=title..":  "..opts[cur] pcall(cb,opts[cur])
    end)
end

local function InfoCard(tab, title, body, col)
    tab.n+=1
    local f=newF(UDim2.new(1,-2,0,10),nil,C.card,tab.scroll)
    corner(8,f) f.LayoutOrder=tab.n
    f.AutomaticSize=Enum.AutomaticSize.Y

    local bar=newF(UDim2.new(0,3,1,0),nil,col or C.accent,f) corner(2,bar)
    local tl=Instance.new("TextLabel")
    tl.Size=UDim2.new(1,-16,0,16) tl.Position=UDim2.new(0,12,0,6)
    tl.Text=title tl.TextSize=11 tl.Font=Enum.Font.GothamBold
    tl.TextColor3=col or C.accent tl.BackgroundTransparency=1 tl.TextXAlignment=Enum.TextXAlignment.Left
    tl.Parent=f
    local bl=Instance.new("TextLabel")
    bl.Size=UDim2.new(1,-16,0,0) bl.Position=UDim2.new(0,12,0,24)
    bl.Text=body bl.TextSize=10 bl.Font=Enum.Font.Gotham
    bl.TextColor3=C.sub bl.BackgroundTransparency=1 bl.TextXAlignment=Enum.TextXAlignment.Left
    bl.TextWrapped=true bl.AutomaticSize=Enum.AutomaticSize.Y
    bl.Parent=f
    return bl
end

local function Space(tab)
    tab.n+=1
    local f=newF(UDim2.new(1,-2,0,6),nil,Color3.new(0,0,0),tab.scroll,1)
    f.LayoutOrder=tab.n
end

-- ════════════════════════════════════
--  GAME LOGIC
-- ════════════════════════════════════
local RC={}
local function GR(n) if RC[n] then return RC[n] end for _,v in ipairs(RepStorage:GetDescendants()) do if v.Name==n and(v:IsA("RemoteEvent") or v:IsA("RemoteFunction")) then RC[n]=v return v end end end
local function FR(n,...) local r=GR(n) if not r then return end pcall(function() if r:IsA("RemoteEvent") then r:FireServer(...) else r:InvokeServer(...) end end) end
local function FRA(t,...) for _,n in ipairs(t) do FR(n,...) end end

local function Rt()  local c=LP.Character return c and c:FindFirstChild("HumanoidRootPart") end
local function Hm()  local c=LP.Character return c and c:FindFirstChildOfClass("Humanoid") end
local function TP(cf) local r=Rt() if r then pcall(function() r.CFrame=cf end) end end

local function getGun()
    local c=LP.Character if not c then return end
    for _,t in ipairs(c:GetChildren()) do if t:IsA("Tool") and t:FindFirstChild("Fire",true) then return t end end
    for _,t in ipairs(LP.Backpack:GetChildren()) do if t:IsA("Tool") and t:FindFirstChild("Fire",true) then return t end end
end

local function BulletRenderer(s,e)
    local sp=Instance.new("Part") sp.Size=Vector3.new(.1,.1,.1) sp.Anchored=true sp.CanCollide=false sp.Transparency=1 sp.Position=s sp.Parent=WS
    local ep=Instance.new("Part") ep.Size=Vector3.new(.1,.1,.1) ep.Anchored=true ep.CanCollide=false ep.Transparency=1 ep.Position=e ep.Parent=WS
    local beam=Instance.new("Beam") beam.Color=ColorSequence.new(C.accent) beam.Width0=0 beam.Width1=0 beam.LightEmission=0.6 beam.FaceCamera=true beam.Segments=1
    local a0=Instance.new("Attachment",sp) local a1=Instance.new("Attachment",ep) beam.Attachment0=a0 beam.Attachment1=a1 beam.Parent=sp
    TweenSvc:Create(beam,TweenInfo.new(0.05),{Width0=0.3,Width1=0.6}):Play()
    task.delay(0.05,function() TweenSvc:Create(beam,TweenInfo.new(0.1),{Width0=0,Width1=0}):Play() end)
    Debris:AddItem(sp,0.3) Debris:AddItem(ep,0.3)
end

-- Match tracking
task.spawn(function()
    while true do
        G.inMatch=(LP:GetAttribute("Match")~=nil)
        local cur=LP:GetAttribute("Match")
        local tmp={}
        if cur then for _,v in ipairs(Players:GetPlayers()) do if v~=LP and v:GetAttribute("Match")==cur then local c=v.Character if c and c:FindFirstChildOfClass("Humanoid") and c.Humanoid.Health>0 then table.insert(tmp,v) end end end end
        G.matchEnemies=tmp
        task.wait(0.1)
    end
end)

local function GetNearest(maxD)
    local r=Rt() if not r then return end
    local best,bd=nil,maxD or math.huge
    for _,v in ipairs(G.matchEnemies) do local c=v.Character if not c then continue end local h=c:FindFirstChild("HumanoidRootPart") if not h then continue end local d=(h.Position-r.Position).Magnitude if d<bd then best=v bd=d end end
    return best
end

-- Aimbot
local canShoot=true local shootThr,knifeThr
local function ShootAt(target)
    if not canShoot then return end
    local myC=LP.Character if not myC then return end
    local hr=myC:FindFirstChild("HumanoidRootPart") if not hr then return end
    local hit=target.Character and(target.Character:FindFirstChild("Head") or target.Character:FindFirstChild("HumanoidRootPart"))
    local tool=getGun() if not tool or not hit then return end
    canShoot=false
    local muz=tool:FindFirstChild("Muzzle",true)
    BulletRenderer(muz and muz.WorldPosition or hr.Position, hit.Position)
    pcall(function() RepStorage.Remotes.ShootGun:FireServer(hr.Position,hit.Position,hit,hit.Position) end)
    local snd=tool:FindFirstChild("Fire",true) if snd and snd:IsA("Sound") then pcall(function() snd:Play() end) end
    task.delay(G.autoshootCD,function() canShoot=true end)
end
local function ThrowAt(target)
    local hit=target.Character and(target.Character:FindFirstChild("Head") or target.Character:FindFirstChild("HumanoidRootPart")) if not hit then return end
    pcall(function() RepStorage.Remotes.ThrowKnife:FireServer(hit.Position) end)
end
local function StartAutoshoot() if shootThr then task.cancel(shootThr) end shootThr=task.spawn(function() while G.autoshoot do local e=GetNearest(G.autoshootDist) if e then ShootAt(e) end task.wait(0.1) end end) end
local function StartAutoKnife() if knifeThr then task.cancel(knifeThr) end knifeThr=task.spawn(function() while G.autoKnife do local e=GetNearest(G.knifeDist) if e then ThrowAt(e) end task.wait(G.knifeCD) end end) end

-- Triggerbot
RunService.Heartbeat:Connect(function()
    if not G.triggerbot then return end
    local ray=Cam:ScreenPointToRay(Cam.ViewportSize.X/2,Cam.ViewportSize.Y/2)
    local res=WS:Raycast(ray.Origin,ray.Direction*600)
    if res and res.Instance then local m=res.Instance:FindFirstAncestorOfClass("Model") if m then local p=Players:GetPlayerFromCharacter(m) if p and p~=LP and p:GetAttribute("Match")==LP:GetAttribute("Match") then ShootAt(p) end end end
end)

-- No gun cooldown
RunService.Heartbeat:Connect(function()
    if not G.noGunCD then return end
    local c=LP.Character if not c then return end
    for _,v in ipairs(c:GetDescendants()) do if(v:IsA("NumberValue") or v:IsA("IntValue")) and v.Value>0 then local n=v.Name:lower() if n:match("cool") or n:match("cd") then v.Value=0 end end end
end)

-- Hitboxes
local function ClearHitboxes() for _,v in ipairs(WS:GetDescendants()) do if v.Name=="PX_HB" then pcall(function() v:Destroy() end) end end end
local function RefreshHitboxes()
    ClearHitboxes() if not G.hitbox then return end
    for _,v in ipairs(G.matchEnemies) do
        local c=v.Character if not c then continue end local hrp=c:FindFirstChild("HumanoidRootPart") if not hrp then continue end
        local h=Instance.new("Part") h.Name="PX_HB" h.Size=Vector3.new(G.hitboxSize,G.hitboxSize,G.hitboxSize) h.Transparency=0.75 h.CanCollide=false h.BrickColor=BrickColor.new("Bright red") h.Material=Enum.Material.Neon h.Parent=c
        local w=Instance.new("Weld") w.Part0=hrp w.Part1=h w.Parent=hrp
    end
end

-- Fly
local flyConn
local function StopFly() G.fly=false if flyConn then flyConn:Disconnect() flyConn=nil end pcall(function() local r=Rt() if not r then return end for _,n in ipairs({"PX_BV","PX_BG"}) do local x=r:FindFirstChild(n) if x then x:Destroy() end end local h=Hm() if h then h.PlatformStand=false end end) end
local function StartFly() StopFly() G.fly=true local r=Rt() local h=Hm() if not r or not h then return end h.PlatformStand=true local BV=Instance.new("BodyVelocity") BV.Name="PX_BV" BV.MaxForce=Vector3.new(1e6,1e6,1e6) BV.Parent=r local BG=Instance.new("BodyGyro") BG.Name="PX_BG" BG.MaxTorque=Vector3.new(1e6,1e6,1e6) BG.P=1e4 BG.Parent=r flyConn=RunService.Heartbeat:Connect(function() if not G.fly then StopFly() return end local d=Vector3.zero if UIS:IsKeyDown(Enum.KeyCode.W) then d=d+Cam.CFrame.LookVector end if UIS:IsKeyDown(Enum.KeyCode.S) then d=d-Cam.CFrame.LookVector end if UIS:IsKeyDown(Enum.KeyCode.A) then d=d-Cam.CFrame.RightVector end if UIS:IsKeyDown(Enum.KeyCode.D) then d=d+Cam.CFrame.RightVector end if UIS:IsKeyDown(Enum.KeyCode.Space) then d=d+Vector3.new(0,1,0) end if UIS:IsKeyDown(Enum.KeyCode.LeftShift) then d=d-Vector3.new(0,1,0) end BV.Velocity=d.Magnitude>0 and d.Unit*G.flySpeed or Vector3.zero BG.CFrame=Cam.CFrame end) end

-- Noclip
RunService.Stepped:Connect(function() if not G.noclip then return end local c=LP.Character if not c then return end for _,p in ipairs(c:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide=false end end end)

-- ESP
local espH={}
local function ClearESP() for _,h in pairs(espH) do pcall(function() h:Destroy() end) end espH={} end
local function RefreshESP()
    ClearESP() if not G.espEnabled then return end
    local myM=LP:GetAttribute("Match")
    for _,p in ipairs(Players:GetPlayers()) do
        if p~=LP and p.Character then
            local h=Instance.new("SelectionBox") h.LineThickness=0.05
            h.Color3=p:GetAttribute("Match")==myM and Color3.fromRGB(68,207,110) or Color3.fromRGB(220,55,55)
            h.SurfaceTransparency=0.8 h.Adornee=p.Character h.Parent=p.Character
            espH[p]=h
        end
    end
end

-- Farm helpers
local function FindPad(mode) local r=Rt() if not r then return end local kw=mode:lower() local best,bd=nil,math.huge for _,v in ipairs(WS:GetDescendants()) do if v:IsA("BasePart") then local n=v.Name:lower() if n:match(kw) or n:match("queue") or n:match("pad") then local d=(v.Position-r.Position).Magnitude if d<bd then best=v bd=d end end end end return best end
local function JoinQueue() local p=FindPad(G.queueMode) if p then TP(CFrame.new(p.Position+Vector3.new(0,4,0))) end FRA({"JoinQueue","QueueJoin","JoinMatch","EnterQueue"},G.queueMode) end
local function AcceptMatch() FRA({"AcceptMatch","AcceptQueue","ReadyUp","ConfirmMatch"}) for _,v in ipairs(LP.PlayerGui:GetDescendants()) do if v:IsA("TextButton") then local t=v.Text:lower() if t:match("accept") or t:match("ready") then pcall(function() v.MouseButton1Click:Fire() end) end end end end
local function VoteMap() FRA({"Vote","VoteMap","MapVote"},1) for _,v in ipairs(LP.PlayerGui:GetDescendants()) do if v:IsA("TextButton") and v.Text:lower():match("vote") then pcall(function() v.MouseButton1Click:Fire() end) break end end end
local function ReturnLobby() FRA({"ReturnToLobby","BackToLobby","Lobby"}) for _,v in ipairs(LP.PlayerGui:GetDescendants()) do if v:IsA("TextButton") then local t=v.Text:lower() if t:match("lobby") or t:match("leave") then pcall(function() v.MouseButton1Click:Fire() end) break end end end end
local function ClaimDaily() FRA({"ClaimDaily","DailyReward","ClaimReward"}) for _,v in ipairs(LP.PlayerGui:GetDescendants()) do if v:IsA("TextButton") then local t=v.Text:lower() if t:match("daily") or t:match("claim") then pcall(function() v.MouseButton1Click:Fire() end) Notify("Daily","Claimed!") return end end end end
local function Spin() FRA({"Spin","SpinCrate","OpenCrate"}) for _,v in ipairs(LP.PlayerGui:GetDescendants()) do if v:IsA("TextButton") then local t=v.Text:lower() if t:match("spin") or t:match("open") then pcall(function() v.MouseButton1Click:Fire() end) return end end end end
local function Collect() local r=Rt() if not r then return end for _,v in ipairs(WS:GetDescendants()) do if v:IsA("BasePart") then local n=v.Name:lower() if n:match("coin") or n:match("gem") or n:match("pickup") then if(v.Position-r.Position).Magnitude<60 then TP(CFrame.new(v.Position+Vector3.new(0,3,0))) task.wait(0.05) end end end end end
local function ServerHop() Notify("Server Hop","Searching…") local ok,data=pcall(function() return HttpSvc:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/"..PID.."/servers/Public?sortOrder=Asc&limit=100",true)) end) if ok and data and data.data then for _,s in ipairs(data.data) do if s.id~=game.JobId and s.playing<s.maxPlayers then pcall(function() TpSvc:TeleportToPlaceInstance(PID,s.id,LP) end) return end end end pcall(function() TpSvc:Teleport(PID,LP) end) end

-- Streak protect
local function TryProtect() local r=Rt() local h=Hm() if not r or not h then return end if h.Health/h.MaxHealth>0.3 then return end local best,bd=nil,0 for _,off in ipairs({Vector3.new(30,0,0),Vector3.new(-30,0,0),Vector3.new(0,0,30),Vector3.new(0,0,-30),Vector3.new(22,0,22),Vector3.new(-22,0,-22)}) do local pos=r.Position+off local mn=math.huge for _,e in ipairs(G.matchEnemies) do local ec=e.Character if not ec then continue end local eh=ec:FindFirstChild("HumanoidRootPart") if not eh then continue end mn=math.min(mn,(pos-eh.Position).Magnitude) end if mn>bd then bd=mn best=pos end end if best then TP(CFrame.new(best)) Notify("Streak Protect","Dodged! Streak:"..G.streak) end end

-- Anti-AFK
local lastAfk=tick()
RunService.Heartbeat:Connect(function() if not G.antiAfk then return end if tick()-lastAfk>55 then lastAfk=tick() pcall(function() local h=Hm() if h then h.Jump=true end end) end if G.streakProtect then TryProtect() end end)

-- Hitbox refresh
RunService.Heartbeat:Connect(function() if G.hitbox and#G.matchEnemies>0 then task.spawn(RefreshHitboxes) end end)

-- Stats tracking
task.spawn(function()
    local ls=LP:WaitForChild("leaderstats",15) if not ls then return end
    for _,v in ipairs(ls:GetChildren()) do if v:IsA("IntValue") or v:IsA("NumberValue") then v.Changed:Connect(function(val) local n=v.Name:lower() if n:match("kill") then G.kills=val end if n:match("win") and val>G.wins then G.wins=val G.streak+=1 if G.streak>G.best then G.best=G.streak end Notify("Win! 🏆","Streak: "..G.streak.." | Best: "..G.best) end if n:match("loss") or n:match("death") then if G.streak>0 then local prev=G.streak G.streak=0 if G.streakRegain then Notify("Streak Lost","Was "..prev.." — auto queuing…") task.spawn(function() task.wait(2) JoinQueue() end) end end G.losses+=1 end if n:match("coin") or n:match("cash") then G.coins=val end end) end end
end)

LP.CharacterAdded:Connect(function(c)
    task.wait(1.5)
    local h=c:FindFirstChildOfClass("Humanoid") if not h then return end
    h.WalkSpeed=G.ws h.JumpPower=G.jp
    if G.fly then task.wait(0.5) StartFly() end
    if G.espEnabled then task.spawn(RefreshESP) end
    h.Died:Connect(function() if G.autoRespawn then task.wait(0.4) pcall(function() LP:LoadCharacter() end) end end)
end)

-- Main farm loop
local TM={q=0,a=0,v=0,col=0,sp=0}
RunService.Heartbeat:Connect(function()
    local now=tick()
    if G.autoQueue   and now-TM.q>8    then TM.q=now   task.spawn(JoinQueue) end
    if G.autoAccept  and now-TM.a>2    then TM.a=now   AcceptMatch() end
    if G.autoVote    and now-TM.v>3    then TM.v=now   VoteMap() end
    if G.autoCollect and now-TM.col>2  then TM.col=now  task.spawn(Collect) end
    if G.autoSpin    and now-TM.sp>G.spinDelay then TM.sp=now Spin() end
    if G.autoReturn  then for _,v in ipairs(LP.PlayerGui:GetDescendants()) do if v:IsA("TextButton") then local t=v.Text:lower() if t:match("lobby") or t:match("return") then pcall(function() v.MouseButton1Click:Fire() end) end end end end
end)

-- ════════════════════════════════════
--  BUILD TABS
-- ════════════════════════════════════

-- ── HOME ────────────────────────────
local tHome, aHome = MakeTab("🏠","Home")
InfoCard(tHome,"⚡ Phantom X — MvS Duels","Full-featured script. Fly, auto farm, aimbot, streak regain, ESP. Tap any tab on the left sidebar.",C.accent)
Space(tHome)
local statsBody=InfoCard(tHome,"Session Stats","Loading…",Color3.fromRGB(100,140,255))
task.spawn(function() while true do task.wait(3) pcall(function() statsBody.Text=string.format("Kills: %d   Wins: %d   Losses: %d\nStreak: %d   Best: %d   Coins: %d",G.kills,G.wins,G.losses,G.streak,G.best,G.coins) end) end end)
aHome()

-- ── COMBAT ──────────────────────────
local tCombat, _ = MakeTab("⚔️","Combat")
Section(tCombat,"Aimbot")
Toggle(tCombat,"Auto Shoot","Fires at nearest match enemy automatically.",false,function(v) G.autoshoot=v if v then StartAutoshoot() end end)
Slider(tCombat,"Shoot Distance",50,800,300,10,function(v) G.autoshootDist=v end)
Slider(tCombat,"Shoot Cooldown (s)",0.5,10,2.5,0.5,function(v) G.autoshootCD=v end)
Toggle(tCombat,"Auto Throw Knife","Throws knife at nearest enemy.",false,function(v) G.autoKnife=v if v then StartAutoKnife() end end)
Slider(tCombat,"Knife Distance",20,400,300,10,function(v) G.knifeDist=v end)
Slider(tCombat,"Knife Cooldown (s)",0.5,8,2,0.5,function(v) G.knifeCD=v end)
Section(tCombat,"Misc")
Toggle(tCombat,"Trigger Bot","Auto-shoots when crosshair is over enemy.",false,function(v) G.triggerbot=v end)
Toggle(tCombat,"Hitbox Expander","Enlarges enemy hitboxes.",false,function(v) G.hitbox=v if not v then ClearHitboxes() end end)
Slider(tCombat,"Hitbox Size",5,80,13,1,function(v) G.hitboxSize=v end)
Toggle(tCombat,"Remove Gun Cooldown","Zeroes weapon cooldowns every frame.",false,function(v) G.noGunCD=v end)

-- ── FARM ────────────────────────────
local tFarm, _ = MakeTab("🌾","Farm")
Section(tFarm,"Automation")
Toggle(tFarm,"All-in-One Farm","Enables all farm options at once.",false,function(v) G.autoQueue=v G.autoAccept=v G.autoVote=v G.autoCollect=v G.autoReturn=v Notify("Auto Farm",v and "ON" or "OFF") end)
Toggle(tFarm,"Auto Queue",nil,false,function(v) G.autoQueue=v end)
Toggle(tFarm,"Auto Accept Match",nil,false,function(v) G.autoAccept=v end)
Toggle(tFarm,"Auto Vote Map",nil,false,function(v) G.autoVote=v end)
Toggle(tFarm,"Auto Return to Lobby",nil,false,function(v) G.autoReturn=v end)
Toggle(tFarm,"Auto Collect Pickups",nil,false,function(v) G.autoCollect=v end)
Toggle(tFarm,"Auto Spin Crates",nil,false,function(v) G.autoSpin=v end)
Dropdown(tFarm,"Queue Mode",{"1v1","2v2","3v3","4v4"},function(v) G.queueMode=v end)
Section(tFarm,"Manual")
Button(tFarm,"Join Queue Now","Fires queue remote + walks to pad",function() JoinQueue() Notify("Queue","Fired!") end)
Button(tFarm,"Accept Match Now",nil,function() AcceptMatch() end)
Button(tFarm,"Vote Map Now",nil,function() VoteMap() end)
Button(tFarm,"Return to Lobby",nil,function() ReturnLobby() end)
Button(tFarm,"Claim Daily Reward",nil,function() ClaimDaily() end)
Button(tFarm,"Spin Crate Now",nil,function() Spin() Notify("Crate","Spun!") end)

-- ── STREAK ──────────────────────────
local tStreak, _ = MakeTab("📈","Streak")
Section(tStreak,"Streak Management")
Toggle(tStreak,"Streak Regain","Auto-queues immediately after losing a streak.",false,function(v) G.streakRegain=v end)
Toggle(tStreak,"Streak Protect","Teleports you away from enemies when HP < 30%.",false,function(v) G.streakProtect=v end)
Space(tStreak)
Button(tStreak,"Force Queue (Regain)",nil,function() task.spawn(JoinQueue) Notify("Queue","Forcing queue to regain streak!") end)
Space(tStreak)
InfoCard(tStreak,"How Streak Protect works","Watches your HP each frame. Below 30% health while in a match, it teleports you to the point furthest from all enemies so you survive.",C.accent)

-- ── MOVEMENT ────────────────────────
local tMove, _ = MakeTab("✈️","Move")
Section(tMove,"Fly")
Toggle(tMove,"Fly","WASD = direction  |  Space = up  |  Shift = down",false,function(v) if v then StartFly() else StopFly() end end)
Slider(tMove,"Fly Speed",10,400,80,5,function(v) G.flySpeed=v end)
Section(tMove,"Ground")
Toggle(tMove,"Noclip","Walk through walls.",false,function(v) G.noclip=v end)
Slider(tMove,"Walk Speed",16,300,16,1,function(v) G.ws=v local h=Hm() if h then h.WalkSpeed=v end end)
Slider(tMove,"Jump Power",50,300,50,5,function(v) G.jp=v local h=Hm() if h then h.JumpPower=v end end)
Button(tMove,"Teleport to Spawn",nil,function() local sp=WS:FindFirstChildOfClass("SpawnLocation") if sp then TP(sp.CFrame+Vector3.new(0,5,0)) Notify("Teleport","Done!") end end)

-- ── ESP ─────────────────────────────
local tEsp, _ = MakeTab("👁","ESP")
Section(tEsp,"Player Highlights")
Toggle(tEsp,"Enable ESP","Green = teammate, Red = enemy.",false,function(v) G.espEnabled=v if v then RefreshESP() else ClearESP() end end)
Button(tEsp,"Refresh ESP",nil,function() if G.espEnabled then RefreshESP() end end)
InfoCard(tEsp,"Note","ESP auto-refreshes when you enter a match.",C.sub)

-- ── QOL ─────────────────────────────
local tQoL, _ = MakeTab("🔧","QoL")
Section(tQoL,"Quality of Life")
Toggle(tQoL,"Anti-AFK","Jumps every 55s to prevent AFK kick.",true,function(v) G.antiAfk=v end)
Toggle(tQoL,"Auto Respawn","Respawns automatically on death.",false,function(v) G.autoRespawn=v end)
Toggle(tQoL,"FPS Boost","Disables shadows, particles, and effects.",false,function(v) pcall(function() Lighting.GlobalShadows=not v for _,x in ipairs(Lighting:GetChildren()) do if x:IsA("PostEffect") or x:IsA("Atmosphere") then pcall(function() x.Enabled=not v end) end end for _,x in ipairs(WS:GetDescendants()) do if x:IsA("ParticleEmitter") or x:IsA("Fire") or x:IsA("Smoke") then pcall(function() x.Enabled=not v end) end end end) Notify("FPS Boost",v and "ON" or "OFF") end)
Section(tQoL,"Server")
Button(tQoL,"Server Hop",nil,function() task.spawn(ServerHop) end)
Button(tQoL,"Rejoin",nil,function() Notify("Rejoin","…") task.wait(1) pcall(function() TpSvc:Teleport(PID,LP) end) end)
Button(tQoL,"Dump Remotes to Console",nil,function() for _,v in ipairs(RepStorage:GetDescendants()) do if v:IsA("RemoteEvent") or v:IsA("RemoteFunction") then print("["..v.ClassName.."] "..v:GetFullName()) end end Notify("Remotes","Printed!") end)

-- ════════════════════════════════════
warn("[PX] ✅ Done — window visible!")
Notify("Phantom X","Loaded! Drag the header to move.",5)
