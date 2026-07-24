-- ⚡ Phantom X v7 | Murders vs Sheriffs Duels
-- GUI is created in the FIRST lines so it always shows, even if game logic errors later.

-- ════════════════════════════════════
--  STEP 1 — ROOT GUI (runs instantly, no dependencies)
-- ════════════════════════════════════
local ROOT = Instance.new("ScreenGui")
ROOT.Name           = "PhantomX"
ROOT.ResetOnSpawn   = false
ROOT.IgnoreGuiInset = true
ROOT.DisplayOrder   = 9999
ROOT.Enabled        = true

-- Try every parent method — first one that works wins
local function Mount()
    if ROOT.Parent then return end
    if typeof(gethui) == "function" then
        pcall(function() ROOT.Parent = gethui() end)
    end
    if not ROOT.Parent and typeof(syn) == "table" and syn.protect_gui then
        pcall(function() syn.protect_gui(ROOT) ROOT.Parent = game:GetService("CoreGui") end)
    end
    if not ROOT.Parent then
        pcall(function() ROOT.Parent = game:GetService("CoreGui") end)
    end
    if not ROOT.Parent then
        pcall(function() ROOT.Parent = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui", 10) end)
    end
end
Mount()

-- Keep alive every second in case the game destroys it
task.spawn(function()
    while task.wait(1) do
        if ROOT and not ROOT.Parent then Mount() end
    end
end)

-- Notify helper (works before StarterGui is set up)
local function Notify(t, m, d)
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {Title=t, Text=m, Duration=d or 4})
    end)
end

-- Show a loading badge instantly so the user knows the script is alive
local LoadBadge = Instance.new("Frame")
LoadBadge.Size              = UDim2.new(0, 160, 0, 36)
LoadBadge.Position          = UDim2.new(0.5, -80, 0, 8)
LoadBadge.BackgroundColor3  = Color3.fromRGB(18, 18, 28)
LoadBadge.BorderSizePixel   = 0
LoadBadge.Parent            = ROOT
do local c=Instance.new("UICorner") c.CornerRadius=UDim.new(0,18) c.Parent=LoadBadge end
do local s=Instance.new("UIStroke") s.Color=Color3.fromRGB(138,63,255) s.Thickness=1.5 s.Parent=LoadBadge end
local LoadLbl = Instance.new("TextLabel")
LoadLbl.Size=UDim2.new(1,0,1,0) LoadLbl.BackgroundTransparency=1
LoadLbl.Text="⚡ Phantom X — Loading…" LoadLbl.TextColor3=Color3.fromRGB(220,220,248)
LoadLbl.TextSize=11 LoadLbl.Font=Enum.Font.GothamBold
LoadLbl.TextXAlignment=Enum.TextXAlignment.Center
LoadLbl.Parent=LoadBadge

-- ════════════════════════════════════
--  STEP 2 — SERVICES (safe, no crash possible)
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

-- Wait for LocalPlayer safely
local LP = Players.LocalPlayer
if not LP then
    local conn; conn = Players:GetPropertyChangedSignal("LocalPlayer"):Connect(function()
        LP = Players.LocalPlayer conn:Disconnect()
    end)
    repeat task.wait() until LP
end
local Cam = WS.CurrentCamera
local PID = game.PlaceId

-- ════════════════════════════════════
--  STEP 3 — STATE
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
--  STEP 4 — COLOURS
-- ════════════════════════════════════
local C = {
    win    = Color3.fromRGB(18,  18,  28),
    winB   = Color3.fromRGB(23,  23,  38),
    side   = Color3.fromRGB(22,  22,  35),
    sideHi = Color3.fromRGB(32,  32,  52),
    hdr    = Color3.fromRGB(14,  14,  22),
    accent = Color3.fromRGB(138, 63,  255),
    acc2   = Color3.fromRGB(100, 40,  200),
    text   = Color3.fromRGB(230, 230, 248),
    sub    = Color3.fromRGB(140, 140, 175),
    on     = Color3.fromRGB(68,  207, 110),
    off    = Color3.fromRGB(200, 60,  60),
    card   = Color3.fromRGB(30,  30,  46),
    bord   = Color3.fromRGB(50,  30,  85),
    btnbg  = Color3.fromRGB(36,  36,  56),
}

-- ════════════════════════════════════
--  STEP 5 — UI HELPERS
-- ════════════════════════════════════
local function corner(r,p)  local c=Instance.new("UICorner") c.CornerRadius=UDim.new(0,r) c.Parent=p end
local function stroke(col,t,p) local s=Instance.new("UIStroke") s.Color=col s.Thickness=t s.ApplyStrokeMode=Enum.ApplyStrokeMode.Border s.Parent=p end
local function pad(t,b,l,r,p) local x=Instance.new("UIPadding") x.PaddingTop=UDim.new(0,t) x.PaddingBottom=UDim.new(0,b) x.PaddingLeft=UDim.new(0,l) x.PaddingRight=UDim.new(0,r) x.Parent=p end

local function F(sz,pos,col,par,tr)
    local f=Instance.new("Frame") f.Size=sz f.Position=pos or UDim2.new(0,0,0,0)
    f.BackgroundColor3=col or C.card f.BackgroundTransparency=tr or 0 f.BorderSizePixel=0 f.Parent=par return f
end
local function L(txt,tsz,col,font,par,xa)
    local l=Instance.new("TextLabel") l.Text=txt l.TextSize=tsz or 13 l.TextColor3=col or C.text
    l.Font=font or Enum.Font.GothamMedium l.BackgroundTransparency=1
    l.TextXAlignment=xa or Enum.TextXAlignment.Left l.TextTruncate=Enum.TextTruncate.AtEnd
    l.Size=UDim2.new(1,0,1,0) l.Parent=par return l
end
local function Btn(par)
    local b=Instance.new("TextButton") b.Size=UDim2.new(1,0,1,0) b.BackgroundTransparency=1 b.Text="" b.Parent=par return b
end

-- Drag (mouse + touch, works on mobile)
local function Draggable(handle, frame)
    local down, ds, sp = false, nil, nil
    handle.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
            down=true ds=Vector2.new(i.Position.X,i.Position.Y) sp=frame.Position
        end
    end)
    handle.InputEnded:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then down=false end
    end)
    UIS.InputChanged:Connect(function(i)
        if not down then return end
        if i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch then
            local d=Vector2.new(i.Position.X,i.Position.Y)-ds
            frame.Position=UDim2.new(sp.X.Scale,sp.X.Offset+d.X,sp.Y.Scale,sp.Y.Offset+d.Y)
        end
    end)
end

-- ════════════════════════════════════
--  STEP 6 — WINDOW
-- ════════════════════════════════════
local WIN = F(UDim2.new(0,620,0,428), UDim2.new(0.5,-310,0.5,-214), C.win, ROOT)
WIN.Active=true corner(10,WIN) stroke(C.bord,1.5,WIN)

-- Header
local HDR = F(UDim2.new(1,0,0,46), UDim2.new(0,0,0,0), C.hdr, WIN)
corner(10,HDR)
F(UDim2.new(1,0,0,12), UDim2.new(0,0,1,-12), C.hdr, WIN)   -- square off bottom corners

local IcoBg = F(UDim2.new(0,32,0,32), UDim2.new(0,8,0,7), C.acc2, HDR) corner(8,IcoBg)
L("⚡",17,Color3.new(1,1,1),Enum.Font.GothamBold,IcoBg,Enum.TextXAlignment.Center)

local TitleL = L("Phantom X",15,C.text,Enum.Font.GothamBold,HDR)
TitleL.Size=UDim2.new(0,180,0,22) TitleL.Position=UDim2.new(0,48,0,5)

local SubL = L("Dev: phantom  |  v7.0",10,C.sub,Enum.Font.Gotham,HDR)
SubL.Size=UDim2.new(0,210,0,14) SubL.Position=UDim2.new(0,48,0,27)

-- Undetected tag
local TagBg = F(UDim2.new(0,96,0,22), UDim2.new(0,244,0,12), Color3.fromRGB(20,60,20), HDR)
corner(5,TagBg) stroke(Color3.fromRGB(68,207,110),1,TagBg)
local TagL=L("✔ UNDETECTED",9,Color3.fromRGB(68,207,110),Enum.Font.GothamBold,TagBg,Enum.TextXAlignment.Center)

-- Window buttons
local function WBtn(icon,xoff,bg)
    local b=Instance.new("TextButton")
    b.Size=UDim2.new(0,28,0,28) b.Position=UDim2.new(1,xoff,0.5,-14)
    b.BackgroundColor3=bg b.Text=icon b.TextColor3=C.text b.TextSize=12
    b.Font=Enum.Font.GothamBold b.BorderSizePixel=0 b.Parent=HDR corner(6,b) return b
end
local MinBtn = WBtn("━",-94,C.btnbg)
local MxBtn  = WBtn("⤢",-62,C.btnbg)
local ClsBtn = WBtn("✕",-30,Color3.fromRGB(180,45,45))
Draggable(HDR, WIN)

-- Mini pill
local MINI = F(UDim2.new(0,150,0,36), UDim2.new(0.5,-75,0,6), C.hdr, ROOT)
MINI.Visible=false corner(18,MINI) stroke(C.accent,1.5,MINI)
L("⚡ Phantom X",12,C.accent,Enum.Font.GothamBold,MINI,Enum.TextXAlignment.Left).Position=UDim2.new(0,10,0,0)
local MiniOpen=Instance.new("TextButton")
MiniOpen.Size=UDim2.new(0,28,0,28) MiniOpen.Position=UDim2.new(1,-32,0.5,-14)
MiniOpen.BackgroundColor3=C.accent MiniOpen.Text="+" MiniOpen.TextColor3=Color3.new(1,1,1)
MiniOpen.TextSize=16 MiniOpen.Font=Enum.Font.GothamBold MiniOpen.BorderSizePixel=0 MiniOpen.Parent=MINI corner(14,MiniOpen)
Draggable(MINI,MINI)

local function SetVisible(v) WIN.Visible=v MINI.Visible=not v end
MinBtn.Activated:Connect(function() SetVisible(false) end)
ClsBtn.Activated:Connect(function() SetVisible(false) end)
MxBtn.Activated:Connect(function()
    local big=WIN.Size.X.Offset<640
    WIN:TweenSize(big and UDim2.new(0,760,0,520) or UDim2.new(0,620,0,428),Enum.EasingDirection.Out,Enum.EasingStyle.Quad,0.18,true)
end)
MiniOpen.Activated:Connect(function() SetVisible(true) end)

-- Sidebar
local SIDE = F(UDim2.new(0,170,1,-46), UDim2.new(0,0,0,46), C.side, WIN)
stroke(C.bord,0.8,SIDE)
local SideList=Instance.new("UIListLayout") SideList.SortOrder=Enum.SortOrder.LayoutOrder SideList.Padding=UDim.new(0,2) SideList.Parent=SIDE
pad(6,6,4,4,SIDE)

-- Player card (bottom of sidebar)
local PCard = F(UDim2.new(1,-8,0,48), UDim2.new(0,4,1,-54), C.card, SIDE) corner(8,PCard) pad(4,4,6,6,PCard)
local PName=L(LP.Name,11,C.text,Enum.Font.GothamBold,PCard) PName.Size=UDim2.new(1,0,0,18) PName.Position=UDim2.new(0,0,0,2)
local PSub =L("MvS Duels",9,C.sub,Enum.Font.Gotham,PCard)   PSub.Size=UDim2.new(1,0,0,14)  PSub.Position=UDim2.new(0,0,0,22)

-- Content area
local CONT = F(UDim2.new(1,-172,1,-48), UDim2.new(0,172,0,47), C.winB, WIN)

-- ════════════════════════════════════
--  TAB SYSTEM
-- ════════════════════════════════════
local activeTab=nil
local tabN=0

local function MakeTab(ico, title)
    tabN+=1
    local order=tabN

    local TabBtn=Instance.new("TextButton")
    TabBtn.Size=UDim2.new(1,-8,0,38) TabBtn.BackgroundColor3=C.side
    TabBtn.Text="" TabBtn.BorderSizePixel=0 TabBtn.LayoutOrder=order TabBtn.Parent=SIDE corner(8,TabBtn)

    local Row=F(UDim2.new(1,0,1,0),nil,Color3.new(0,0,0),TabBtn,1)
    local IcoL=L(ico,14,C.sub,Enum.Font.GothamMedium,Row,Enum.TextXAlignment.Center) IcoL.Size=UDim2.new(0,28,1,0) IcoL.Position=UDim2.new(0,6,0,0)
    local TxtL=L(title,12,C.sub,Enum.Font.GothamMedium,Row) TxtL.Size=UDim2.new(1,-38,1,0) TxtL.Position=UDim2.new(0,36,0,0)

    local Bar=F(UDim2.new(0,3,0.68,0),UDim2.new(0,0,0.16,0),C.accent,TabBtn) Bar.Visible=false corner(2,Bar)

    local Scroll=Instance.new("ScrollingFrame")
    Scroll.Size=UDim2.new(1,0,1,0) Scroll.BackgroundTransparency=1
    Scroll.BorderSizePixel=0 Scroll.ScrollBarThickness=3 Scroll.ScrollBarImageColor3=C.accent
    Scroll.CanvasSize=UDim2.new(0,0,0,0) Scroll.AutomaticCanvasSize=Enum.AutomaticSize.Y
    Scroll.ScrollingDirection=Enum.ScrollingDirection.Y Scroll.Visible=false Scroll.Parent=CONT
    pad(8,10,8,8,Scroll)
    local SList=Instance.new("UIListLayout") SList.SortOrder=Enum.SortOrder.LayoutOrder SList.Padding=UDim.new(0,5) SList.Parent=Scroll

    local tab={scroll=Scroll,n=0,tabBtn=TabBtn,bar=Bar,icoL=IcoL,txtL=TxtL}

    local function activate()
        if activeTab then
            activeTab.scroll.Visible=false activeTab.bar.Visible=false
            activeTab.tabBtn.BackgroundColor3=C.side activeTab.icoL.TextColor3=C.sub activeTab.txtL.TextColor3=C.sub
        end
        activeTab=tab Scroll.Visible=true Bar.Visible=true
        TabBtn.BackgroundColor3=C.sideHi IcoL.TextColor3=C.accent TxtL.TextColor3=C.text
    end
    TabBtn.Activated:Connect(activate)
    return tab, activate
end

-- ── WIDGETS ──────────────────────────────────────────
local function Sect(tab, title)
    tab.n+=1
    local f=F(UDim2.new(1,-2,0,22),nil,Color3.new(0,0,0),tab.scroll,1) f.LayoutOrder=tab.n
    local l=L("  "..title:upper(),9,C.accent,Enum.Font.GothamBold,f) l.Size=UDim2.new(1,0,1,0)
    F(UDim2.new(1,0,0,1),UDim2.new(0,0,1,-1),C.bord,f)
end

local function Toggle(tab, title, desc, default, cb)
    tab.n+=1
    local h=desc and 48 or 38
    local f=F(UDim2.new(1,-2,0,h),nil,C.card,tab.scroll) corner(8,f) f.LayoutOrder=tab.n

    local tl=L(title,11,C.text,Enum.Font.GothamMedium,f) tl.Size=UDim2.new(1,-58,0,16) tl.Position=UDim2.new(0,10,0,6)
    if desc and desc~="" then
        local dl=L(desc,9,C.sub,Enum.Font.Gotham,f) dl.Size=UDim2.new(1,-58,0,14) dl.Position=UDim2.new(0,10,0,26)
        dl.TextWrapped=true
    end

    local pill=F(UDim2.new(0,40,0,22),UDim2.new(1,-50,0.5,-11),default and C.on or C.off,f) corner(11,pill)
    local dot=F(UDim2.new(0,16,0,16),default and UDim2.new(1,-19,0.5,-8) or UDim2.new(0,3,0.5,-8),Color3.new(1,1,1),pill) corner(8,dot)

    local val=default or false
    local ti=TweenInfo.new(0.12)
    local btn=Btn(f)
    local function tog()
        val=not val
        TweenSvc:Create(pill,ti,{BackgroundColor3=val and C.on or C.off}):Play()
        TweenSvc:Create(dot,ti,{Position=val and UDim2.new(1,-19,0.5,-8) or UDim2.new(0,3,0.5,-8)}):Play()
        pcall(cb,val)
    end
    btn.Activated:Connect(tog)
    if default then pcall(cb,true) end
end

local function Button(tab, title, sub, cb)
    tab.n+=1
    local f=F(UDim2.new(1,-2,0,38),nil,C.acc2,tab.scroll) corner(8,f) stroke(C.accent,0.8,f) f.LayoutOrder=tab.n
    local l=L(title,11,C.text,Enum.Font.GothamBold,f,Enum.TextXAlignment.Center)
    if sub and sub~="" then l.Size=UDim2.new(1,0,0,18) l.Position=UDim2.new(0,0,0,5)
        local sl=L(sub,9,C.sub,Enum.Font.Gotham,f,Enum.TextXAlignment.Center) sl.Size=UDim2.new(1,0,0,14) sl.Position=UDim2.new(0,0,0,24)
    end
    Btn(f).Activated:Connect(function() pcall(cb) end)
end

local function Slider(tab, title, mn, mx, def, stp, cb)
    tab.n+=1
    local f=F(UDim2.new(1,-2,0,58),nil,C.card,tab.scroll) corner(8,f) f.LayoutOrder=tab.n
    local val=def
    local lbl=L(title..":  "..val,11,C.text,Enum.Font.GothamMedium,f) lbl.Size=UDim2.new(1,-8,0,18) lbl.Position=UDim2.new(0,10,0,5)
    local trk=F(UDim2.new(1,-20,0,8),UDim2.new(0,10,0,36),C.side,f) corner(4,trk) stroke(C.bord,0.5,trk)
    local fill=F(UDim2.new((def-mn)/(mx-mn),0,1,0),nil,C.accent,trk) corner(4,fill)
    local nub=F(UDim2.new(0,18,0,18),UDim2.new((def-mn)/(mx-mn),0,0.5,-9),Color3.new(1,1,1),trk) corner(9,nub)
    local drag=false
    local function upd(x)
        local r=math.clamp((x-trk.AbsolutePosition.X)/math.max(trk.AbsoluteSize.X,1),0,1)
        val=mn+math.round((mx-mn)*r/(stp or 1))*(stp or 1)
        fill.Size=UDim2.new(r,0,1,0) nub.Position=UDim2.new(r,0,0.5,-9) lbl.Text=title..":  "..val pcall(cb,val)
    end
    local function si(i) if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then drag=true upd(i.Position.X) end end
    trk.InputBegan:Connect(si) nub.InputBegan:Connect(si)
    UIS.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then drag=false end end)
    UIS.InputChanged:Connect(function(i) if drag and(i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) then upd(i.Position.X) end end)
    pcall(cb,def)
end

local function Dropdown(tab, title, opts, cb)
    tab.n+=1
    local f=F(UDim2.new(1,-2,0,38),nil,C.card,tab.scroll) corner(8,f) f.LayoutOrder=tab.n
    local cur=1
    local lbl=L(title..":  "..opts[1],11,C.text,Enum.Font.GothamMedium,f) lbl.Size=UDim2.new(1,-30,1,0) lbl.Position=UDim2.new(0,10,0,0)
    local arr=L("▾",14,C.accent,Enum.Font.GothamBold,f,Enum.TextXAlignment.Center) arr.Size=UDim2.new(0,24,1,0) arr.Position=UDim2.new(1,-28,0,0)
    pcall(cb,opts[1])
    Btn(f).Activated:Connect(function() cur=cur%#opts+1 lbl.Text=title..":  "..opts[cur] pcall(cb,opts[cur]) end)
end

local function Card(tab, title, body, col)
    tab.n+=1
    local f=F(UDim2.new(1,-2,0,10),nil,C.card,tab.scroll) f.AutomaticSize=Enum.AutomaticSize.Y corner(8,f) f.LayoutOrder=tab.n
    F(UDim2.new(0,3,1,0),nil,col or C.accent,f) corner(2,F(UDim2.new(0,3,1,0),nil,col or C.accent,f))
    local tl=Instance.new("TextLabel") tl.Size=UDim2.new(1,-16,0,16) tl.Position=UDim2.new(0,12,0,6) tl.Text=title tl.TextSize=11 tl.Font=Enum.Font.GothamBold tl.TextColor3=col or C.accent tl.BackgroundTransparency=1 tl.TextXAlignment=Enum.TextXAlignment.Left tl.Parent=f
    local bl=Instance.new("TextLabel") bl.Size=UDim2.new(1,-16,0,0) bl.Position=UDim2.new(0,12,0,24) bl.Text=body bl.TextSize=10 bl.Font=Enum.Font.Gotham bl.TextColor3=C.sub bl.BackgroundTransparency=1 bl.TextXAlignment=Enum.TextXAlignment.Left bl.TextWrapped=true bl.AutomaticSize=Enum.AutomaticSize.Y bl.Parent=f
    return bl
end

local function Space(tab) tab.n+=1 local f=F(UDim2.new(1,-2,0,5),nil,Color3.new(0,0,0),tab.scroll,1) f.LayoutOrder=tab.n end

-- ════════════════════════════════════
--  GAME LOGIC (all wrapped in pcall so UI never breaks)
-- ════════════════════════════════════
local RC={}
local function GR(n) if RC[n] then return RC[n] end pcall(function() for _,v in ipairs(RepStorage:GetDescendants()) do if v.Name==n and(v:IsA("RemoteEvent") or v:IsA("RemoteFunction")) then RC[n]=v end end end) return RC[n] end
local function FR(n,...) local r=GR(n) if not r then return end pcall(function() if r:IsA("RemoteEvent") then r:FireServer(...) else r:InvokeServer(...) end end) end
local function FRA(t,...) for _,n in ipairs(t) do FR(n,...) end end
local function Rt()  local c=LP.Character return c and c:FindFirstChild("HumanoidRootPart") end
local function Hm()  local c=LP.Character return c and c:FindFirstChildOfClass("Humanoid") end
local function TP(cf) pcall(function() local r=Rt() if r then r.CFrame=cf end end) end

local function getGun()
    local c=LP.Character if not c then return end
    for _,t in ipairs(c:GetChildren()) do if t:IsA("Tool") and t:FindFirstChild("Fire",true) then return t end end
    local ok,bp=pcall(function() return LP.Backpack end) if ok and bp then for _,t in ipairs(bp:GetChildren()) do if t:IsA("Tool") and t:FindFirstChild("Fire",true) then return t end end end
end

-- Match tracking
task.spawn(function()
    while true do
        pcall(function()
            G.inMatch=(LP:GetAttribute("Match")~=nil)
            local cur=LP:GetAttribute("Match")
            local tmp={}
            if cur then
                for _,v in ipairs(Players:GetPlayers()) do
                    if v~=LP and v:GetAttribute("Match")==cur then
                        local c=v.Character
                        if c and c:FindFirstChildOfClass("Humanoid") and c.Humanoid.Health>0 then
                            table.insert(tmp,v)
                        end
                    end
                end
            end
            G.matchEnemies=tmp
        end)
        task.wait(0.1)
    end
end)

local function GetNearest(maxD)
    local r=Rt() if not r then return end
    local best,bd=nil,maxD or math.huge
    for _,v in ipairs(G.matchEnemies) do
        pcall(function()
            local c=v.Character if not c then return end
            local h=c:FindFirstChild("HumanoidRootPart") if not h then return end
            local d=(h.Position-r.Position).Magnitude if d<bd then best=v bd=d end
        end)
    end
    return best
end

-- Bullet tracer
local function BulletRenderer(s,e)
    pcall(function()
        local sp=Instance.new("Part") sp.Size=Vector3.new(.1,.1,.1) sp.Anchored=true sp.CanCollide=false sp.Transparency=1 sp.Position=s sp.Parent=WS
        local ep=Instance.new("Part") ep.Size=Vector3.new(.1,.1,.1) ep.Anchored=true ep.CanCollide=false ep.Transparency=1 ep.Position=e ep.Parent=WS
        local beam=Instance.new("Beam") beam.Color=ColorSequence.new(C.accent) beam.Width0=0 beam.Width1=0 beam.LightEmission=0.6 beam.FaceCamera=true beam.Segments=1
        local a0=Instance.new("Attachment",sp) local a1=Instance.new("Attachment",ep) beam.Attachment0=a0 beam.Attachment1=a1 beam.Parent=sp
        TweenSvc:Create(beam,TweenInfo.new(0.05),{Width0=0.3,Width1=0.6}):Play()
        task.delay(0.05,function() TweenSvc:Create(beam,TweenInfo.new(0.1),{Width0=0,Width1=0}):Play() end)
        Debris:AddItem(sp,0.3) Debris:AddItem(ep,0.3)
    end)
end

-- Aimbot
local canShoot=true local shootThr, knifeThr
local function ShootAt(t)
    pcall(function()
        if not canShoot then return end
        local myC=LP.Character if not myC then return end
        local hr=myC:FindFirstChild("HumanoidRootPart") if not hr then return end
        local hit=t.Character and(t.Character:FindFirstChild("Head") or t.Character:FindFirstChild("HumanoidRootPart"))
        local tool=getGun() if not tool or not hit then return end
        canShoot=false
        local muz=tool:FindFirstChild("Muzzle",true)
        BulletRenderer(muz and muz.WorldPosition or hr.Position, hit.Position)
        pcall(function() RepStorage.Remotes.ShootGun:FireServer(hr.Position,hit.Position,hit,hit.Position) end)
        local snd=tool:FindFirstChild("Fire",true) if snd and snd:IsA("Sound") then pcall(function() snd:Play() end) end
        task.delay(G.autoshootCD,function() canShoot=true end)
    end)
end
local function ThrowAt(t) pcall(function() local hit=t.Character and(t.Character:FindFirstChild("Head") or t.Character:FindFirstChild("HumanoidRootPart")) if not hit then return end RepStorage.Remotes.ThrowKnife:FireServer(hit.Position) end) end
local function StartAutoshoot() if shootThr then task.cancel(shootThr) end shootThr=task.spawn(function() while G.autoshoot do local e=GetNearest(G.autoshootDist) if e then ShootAt(e) end task.wait(0.1) end end) end
local function StartAutoKnife() if knifeThr then task.cancel(knifeThr) end knifeThr=task.spawn(function() while G.autoKnife do local e=GetNearest(G.knifeDist) if e then ThrowAt(e) end task.wait(G.knifeCD) end end) end

-- Triggerbot
RunService.Heartbeat:Connect(function()
    if not G.triggerbot then return end
    pcall(function()
        local ray=Cam:ScreenPointToRay(Cam.ViewportSize.X/2,Cam.ViewportSize.Y/2)
        local res=WS:Raycast(ray.Origin,ray.Direction*600)
        if not res then return end
        local m=res.Instance:FindFirstAncestorOfClass("Model")
        if not m then return end
        local p=Players:GetPlayerFromCharacter(m)
        if p and p~=LP and p:GetAttribute("Match")==LP:GetAttribute("Match") then ShootAt(p) end
    end)
end)

-- No gun cooldown
RunService.Heartbeat:Connect(function()
    if not G.noGunCD then return end
    pcall(function() local c=LP.Character if not c then return end for _,v in ipairs(c:GetDescendants()) do if(v:IsA("NumberValue") or v:IsA("IntValue")) and v.Value>0 then local n=v.Name:lower() if n:match("cool") or n:match("cd") then v.Value=0 end end end end)
end)

-- Hitbox
local function ClearHitboxes() pcall(function() for _,v in ipairs(WS:GetDescendants()) do if v.Name=="PX_HB" then v:Destroy() end end end) end
local function RefreshHitboxes()
    ClearHitboxes() if not G.hitbox then return end
    for _,v in ipairs(G.matchEnemies) do pcall(function()
        local c=v.Character if not c then return end local hrp=c:FindFirstChild("HumanoidRootPart") if not hrp then return end
        local h=Instance.new("Part") h.Name="PX_HB" h.Size=Vector3.new(G.hitboxSize,G.hitboxSize,G.hitboxSize) h.Transparency=0.75 h.CanCollide=false h.BrickColor=BrickColor.new("Bright red") h.Material=Enum.Material.Neon h.Parent=c
        local w=Instance.new("Weld") w.Part0=hrp w.Part1=h w.Parent=hrp
    end) end
end

-- Fly
local flyConn
local function StopFly() G.fly=false if flyConn then flyConn:Disconnect() flyConn=nil end pcall(function() local r=Rt() if not r then return end for _,n in ipairs({"PX_BV","PX_BG"}) do local x=r:FindFirstChild(n) if x then x:Destroy() end end local h=Hm() if h then h.PlatformStand=false end end) end
local function StartFly()
    StopFly() G.fly=true
    local r=Rt() local h=Hm() if not r or not h then return end
    h.PlatformStand=true
    local BV=Instance.new("BodyVelocity") BV.Name="PX_BV" BV.MaxForce=Vector3.new(1e6,1e6,1e6) BV.Parent=r
    local BG=Instance.new("BodyGyro") BG.Name="PX_BG" BG.MaxTorque=Vector3.new(1e6,1e6,1e6) BG.P=1e4 BG.Parent=r
    flyConn=RunService.Heartbeat:Connect(function()
        if not G.fly then StopFly() return end
        local d=Vector3.zero
        if UIS:IsKeyDown(Enum.KeyCode.W) then d=d+Cam.CFrame.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.S) then d=d-Cam.CFrame.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.A) then d=d-Cam.CFrame.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.D) then d=d+Cam.CFrame.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.Space) then d=d+Vector3.new(0,1,0) end
        if UIS:IsKeyDown(Enum.KeyCode.LeftShift) then d=d-Vector3.new(0,1,0) end
        BV.Velocity=d.Magnitude>0 and d.Unit*G.flySpeed or Vector3.zero BG.CFrame=Cam.CFrame
    end)
end

-- Noclip
RunService.Stepped:Connect(function()
    if not G.noclip then return end
    pcall(function() local c=LP.Character if not c then return end for _,p in ipairs(c:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide=false end end end)
end)

-- ESP
local espH={}
local function ClearESP() for _,h in pairs(espH) do pcall(function() h:Destroy() end) end espH={} end
local function RefreshESP()
    ClearESP() if not G.espEnabled then return end
    local myM=LP:GetAttribute("Match")
    for _,p in ipairs(Players:GetPlayers()) do pcall(function()
        if p==LP or not p.Character then return end
        local h=Instance.new("SelectionBox") h.LineThickness=0.05
        h.Color3=p:GetAttribute("Match")==myM and C.on or C.off
        h.SurfaceTransparency=0.8 h.Adornee=p.Character h.Parent=p.Character espH[p]=h
    end) end
end

-- Farm helpers
local function FindPad(mode) local r=Rt() if not r then return end local kw=mode:lower() local best,bd=nil,math.huge pcall(function() for _,v in ipairs(WS:GetDescendants()) do if v:IsA("BasePart") then local n=v.Name:lower() if n:match(kw) or n:match("queue") or n:match("pad") then local d=(v.Position-r.Position).Magnitude if d<bd then best=v bd=d end end end end end) return best end
local function JoinQueue() pcall(function() local p=FindPad(G.queueMode) if p then TP(CFrame.new(p.Position+Vector3.new(0,4,0))) end FRA({"JoinQueue","QueueJoin","JoinMatch","EnterQueue"},G.queueMode) end) end
local function AcceptMatch() pcall(function() FRA({"AcceptMatch","AcceptQueue","ReadyUp","ConfirmMatch"}) for _,v in ipairs(LP.PlayerGui:GetDescendants()) do if v:IsA("TextButton") then local t=v.Text:lower() if t:match("accept") or t:match("ready") then v.MouseButton1Click:Fire() end end end end) end
local function VoteMap() pcall(function() FRA({"Vote","VoteMap","MapVote"},1) for _,v in ipairs(LP.PlayerGui:GetDescendants()) do if v:IsA("TextButton") and v.Text:lower():match("vote") then v.MouseButton1Click:Fire() break end end end) end
local function ReturnLobby() pcall(function() FRA({"ReturnToLobby","BackToLobby","Lobby"}) for _,v in ipairs(LP.PlayerGui:GetDescendants()) do if v:IsA("TextButton") then local t=v.Text:lower() if t:match("lobby") or t:match("leave") then v.MouseButton1Click:Fire() break end end end end) end
local function ClaimDaily() pcall(function() FRA({"ClaimDaily","DailyReward","ClaimReward"}) for _,v in ipairs(LP.PlayerGui:GetDescendants()) do if v:IsA("TextButton") then local t=v.Text:lower() if t:match("daily") or t:match("claim") then v.MouseButton1Click:Fire() Notify("Daily","Claimed!") return end end end end) end
local function Spin() pcall(function() FRA({"Spin","SpinCrate","OpenCrate"}) for _,v in ipairs(LP.PlayerGui:GetDescendants()) do if v:IsA("TextButton") then local t=v.Text:lower() if t:match("spin") or t:match("open") then v.MouseButton1Click:Fire() return end end end end) end
local function Collect() pcall(function() local r=Rt() if not r then return end for _,v in ipairs(WS:GetDescendants()) do if v:IsA("BasePart") then local n=v.Name:lower() if n:match("coin") or n:match("gem") or n:match("pickup") then if(v.Position-r.Position).Magnitude<60 then TP(CFrame.new(v.Position+Vector3.new(0,3,0))) task.wait(0.05) end end end end end) end
local function ServerHop() Notify("Server Hop","Searching…") pcall(function() local data=HttpSvc:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/"..PID.."/servers/Public?sortOrder=Asc&limit=100",true)) if data and data.data then for _,s in ipairs(data.data) do if s.id~=game.JobId and s.playing<s.maxPlayers then TpSvc:TeleportToPlaceInstance(PID,s.id,LP) return end end end TpSvc:Teleport(PID,LP) end) end

-- Streak protect
local function TryProtect() pcall(function()
    local r=Rt() local h=Hm() if not r or not h then return end
    if h.Health/h.MaxHealth>0.3 then return end
    local best,bd=nil,0
    for _,off in ipairs({Vector3.new(30,0,0),Vector3.new(-30,0,0),Vector3.new(0,0,30),Vector3.new(0,0,-30),Vector3.new(22,0,22),Vector3.new(-22,0,-22)}) do
        local pos=r.Position+off local mn=math.huge
        for _,e in ipairs(G.matchEnemies) do pcall(function() local ec=e.Character if not ec then return end local eh=ec:FindFirstChild("HumanoidRootPart") if not eh then return end mn=math.min(mn,(pos-eh.Position).Magnitude) end) end
        if mn>bd then bd=mn best=pos end
    end
    if best then TP(CFrame.new(best)) Notify("Streak Protect","Dodged! Streak: "..G.streak) end
end) end

-- Anti-AFK
local lastAfk=tick()
RunService.Heartbeat:Connect(function()
    if G.antiAfk and tick()-lastAfk>55 then lastAfk=tick() pcall(function() local h=Hm() if h then h.Jump=true end end) end
    if G.streakProtect then TryProtect() end
    if G.hitbox and #G.matchEnemies>0 then task.spawn(RefreshHitboxes) end
end)

-- Stats
task.spawn(function()
    local ls=LP:WaitForChild("leaderstats",15) if not ls then return end
    for _,v in ipairs(ls:GetChildren()) do
        if v:IsA("IntValue") or v:IsA("NumberValue") then v.Changed:Connect(function(val)
            local n=v.Name:lower()
            if n:match("kill") then G.kills=val end
            if n:match("win") and val>G.wins then G.wins=val G.streak+=1 if G.streak>G.best then G.best=G.streak end Notify("Win! 🏆","Streak: "..G.streak.."  Best: "..G.best) end
            if(n:match("loss") or n:match("death")) and G.streak>0 then local prev=G.streak G.streak=0 if G.streakRegain then Notify("Streak Lost","Was "..prev.." — re-queuing…") task.spawn(function() task.wait(2) JoinQueue() end) end G.losses+=1 end
            if n:match("coin") or n:match("cash") then G.coins=val end
        end) end
    end
end)

LP.CharacterAdded:Connect(function(c)
    task.wait(1.5) local h=c:FindFirstChildOfClass("Humanoid") if not h then return end
    h.WalkSpeed=G.ws h.JumpPower=G.jp
    if G.fly then task.wait(0.5) StartFly() end
    if G.espEnabled then task.spawn(RefreshESP) end
    h.Died:Connect(function() if G.autoRespawn then task.wait(0.4) pcall(function() LP:LoadCharacter() end) end end)
end)

-- Main loop
local TM={q=0,a=0,v=0,col=0,sp=0}
RunService.Heartbeat:Connect(function()
    local now=tick()
    if G.autoQueue   and now-TM.q>8          then TM.q=now   task.spawn(JoinQueue) end
    if G.autoAccept  and now-TM.a>2          then TM.a=now   AcceptMatch() end
    if G.autoVote    and now-TM.v>3          then TM.v=now   VoteMap() end
    if G.autoCollect and now-TM.col>2        then TM.col=now  task.spawn(Collect) end
    if G.autoSpin    and now-TM.sp>G.spinDelay then TM.sp=now Spin() end
    if G.autoReturn  then pcall(function() for _,v in ipairs(LP.PlayerGui:GetDescendants()) do if v:IsA("TextButton") then local t=v.Text:lower() if t:match("lobby") or t:match("return") then v.MouseButton1Click:Fire() end end end end) end
end)

-- ════════════════════════════════════
--  BUILD TABS
-- ════════════════════════════════════

local tHome,   aHome   = MakeTab("🏠","Home")
local tCombat, _       = MakeTab("⚔️","Combat")
local tFarm,   _       = MakeTab("🌾","Farm")
local tStreak, _       = MakeTab("📈","Streak")
local tMove,   _       = MakeTab("✈️","Move")
local tEsp,    _       = MakeTab("👁","ESP")
local tQoL,    _       = MakeTab("🔧","QoL")

-- HOME
Card(tHome,"⚡ Phantom X — MvS Duels","Full-featured script. Fly, auto farm, aimbot, streak regain, ESP. Pick a tab from the left.",C.accent)
Space(tHome)
local statsBody=Card(tHome,"Session Stats","Loading…",Color3.fromRGB(100,140,255))
task.spawn(function() while true do task.wait(3) pcall(function() statsBody.Text=("Kills: %d   Wins: %d   Losses: %d\nStreak: %d   Best: %d   Coins: %d"):format(G.kills,G.wins,G.losses,G.streak,G.best,G.coins) end) end end)
aHome()

-- COMBAT
Sect(tCombat,"Aimbot")
Toggle(tCombat,"Auto Shoot","Fires at nearest match enemy automatically.","",false,function(v) G.autoshoot=v if v then StartAutoshoot() end end)
Slider(tCombat,"Shoot Distance",50,800,300,10,function(v) G.autoshootDist=v end)
Slider(tCombat,"Shoot Cooldown (s)",0.5,10,2.5,0.5,function(v) G.autoshootCD=v end)
Toggle(tCombat,"Auto Throw Knife","Throws knife at nearest enemy automatically.","",false,function(v) G.autoKnife=v if v then StartAutoKnife() end end)
Slider(tCombat,"Knife Distance",20,400,300,10,function(v) G.knifeDist=v end)
Slider(tCombat,"Knife Cooldown (s)",0.5,8,2,0.5,function(v) G.knifeCD=v end)
Sect(tCombat,"Misc")
Toggle(tCombat,"Trigger Bot","Auto-shoots when crosshair hovers over enemy.","",false,function(v) G.triggerbot=v end)
Toggle(tCombat,"Hitbox Expander","Makes enemy hitboxes larger.","",false,function(v) G.hitbox=v if not v then ClearHitboxes() end end)
Slider(tCombat,"Hitbox Size",5,80,13,1,function(v) G.hitboxSize=v end)
Toggle(tCombat,"Remove Gun Cooldown","Zeroes weapon cooldown values each frame.","",false,function(v) G.noGunCD=v end)

-- FARM
Sect(tFarm,"Automation")
Toggle(tFarm,"All-in-One Farm","Enables every farm option at once.","",false,function(v) G.autoQueue=v G.autoAccept=v G.autoVote=v G.autoCollect=v G.autoReturn=v Notify("Auto Farm",v and "ON" or "OFF") end)
Toggle(tFarm,"Auto Queue","","",false,function(v) G.autoQueue=v end)
Toggle(tFarm,"Auto Accept Match","","",false,function(v) G.autoAccept=v end)
Toggle(tFarm,"Auto Vote Map","","",false,function(v) G.autoVote=v end)
Toggle(tFarm,"Auto Return to Lobby","","",false,function(v) G.autoReturn=v end)
Toggle(tFarm,"Auto Collect Pickups","","",false,function(v) G.autoCollect=v end)
Toggle(tFarm,"Auto Spin Crates","","",false,function(v) G.autoSpin=v end)
Dropdown(tFarm,"Queue Mode",{"1v1","2v2","3v3","4v4"},function(v) G.queueMode=v end)
Sect(tFarm,"Manual")
Button(tFarm,"Join Queue Now","Fires remote + walks to queue pad",function() JoinQueue() Notify("Queue","Fired!") end)
Button(tFarm,"Accept Match Now","",function() AcceptMatch() end)
Button(tFarm,"Vote Map Now","",function() VoteMap() end)
Button(tFarm,"Return to Lobby","",function() ReturnLobby() end)
Button(tFarm,"Claim Daily Reward","",function() ClaimDaily() end)
Button(tFarm,"Spin Crate Now","",function() Spin() Notify("Crate","Spun!") end)

-- STREAK
Sect(tStreak,"Streak Management")
Toggle(tStreak,"Streak Regain","Auto-queues immediately after losing a streak.","",false,function(v) G.streakRegain=v end)
Toggle(tStreak,"Streak Protect","Teleports away when HP drops below 30%.","",false,function(v) G.streakProtect=v end)
Space(tStreak)
Button(tStreak,"Force Queue (Regain)","Instantly fires queue remote to get streak back",function() task.spawn(JoinQueue) Notify("Queue","Firing to regain streak!") end)
Space(tStreak)
Card(tStreak,"How Streak Protect works","Watches your HP every frame. Under 30% health inside a match it finds the point furthest from all enemies and teleports you there so you survive.",C.accent)

-- MOVE
Sect(tMove,"Fly")
Toggle(tMove,"Fly","WASD = dir  |  Space = up  |  Shift = down","",false,function(v) if v then StartFly() else StopFly() end end)
Slider(tMove,"Fly Speed",10,400,80,5,function(v) G.flySpeed=v end)
Sect(tMove,"Ground")
Toggle(tMove,"Noclip","Walk through walls.","",false,function(v) G.noclip=v end)
Slider(tMove,"Walk Speed",16,300,16,1,function(v) G.ws=v local h=Hm() if h then h.WalkSpeed=v end end)
Slider(tMove,"Jump Power",50,300,50,5,function(v) G.jp=v local h=Hm() if h then h.JumpPower=v end end)
Button(tMove,"Teleport to Spawn","",function() pcall(function() local sp=WS:FindFirstChildOfClass("SpawnLocation") if sp then TP(sp.CFrame+Vector3.new(0,5,0)) Notify("Teleport","Done!") end end) end)

-- ESP
Sect(tEsp,"Player Highlights")
Toggle(tEsp,"Enable ESP","Green = teammate  |  Red = enemy","",false,function(v) G.espEnabled=v if v then RefreshESP() else ClearESP() end end)
Button(tEsp,"Refresh ESP","",function() if G.espEnabled then RefreshESP() end end)
Card(tEsp,"Note","ESP auto-refreshes each time you enter a match.",C.sub)

-- QOL
Sect(tQoL,"Quality of Life")
Toggle(tQoL,"Anti-AFK","Jumps every 55 s to prevent AFK kick.","",true,function(v) G.antiAfk=v end)
Toggle(tQoL,"Auto Respawn","Respawns automatically on death.","",false,function(v) G.autoRespawn=v end)
Toggle(tQoL,"FPS Boost","Removes shadows, particles, and post-effects.","",false,function(v)
    pcall(function()
        Lighting.GlobalShadows=not v
        for _,x in ipairs(Lighting:GetChildren()) do if x:IsA("PostEffect") or x:IsA("Atmosphere") then pcall(function() x.Enabled=not v end) end end
        for _,x in ipairs(WS:GetDescendants()) do if x:IsA("ParticleEmitter") or x:IsA("Fire") or x:IsA("Smoke") then pcall(function() x.Enabled=not v end) end end
    end) Notify("FPS Boost",v and "ON" or "OFF")
end)
Sect(tQoL,"Server")
Button(tQoL,"Server Hop","",function() task.spawn(ServerHop) end)
Button(tQoL,"Rejoin","",function() Notify("Rejoin","…") task.wait(1) pcall(function() TpSvc:Teleport(PID,LP) end) end)
Button(tQoL,"Dump Remotes","Prints all RemoteEvents to console",function() pcall(function() for _,v in ipairs(RepStorage:GetDescendants()) do if v:IsA("RemoteEvent") or v:IsA("RemoteFunction") then print("["..v.ClassName.."] "..v:GetFullName()) end end end) Notify("Remotes","Printed!") end)

-- ════════════════════════════════════
--  DONE — remove loading badge
-- ════════════════════════════════════
LoadBadge:Destroy()
Notify("Phantom X","Loaded!  Drag the header to move.",5)
