-- ⚡ Phantom X | Murders vs Sheriffs Duels
-- v4 — self-contained, no external deps, mobile-bulletproof
warn("[PX] Script received — starting...")

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
local StarterGui   = game:GetService("StarterGui")

-- Wait for LocalPlayer
local LP = Players.LocalPlayer
if not LP then
    Players:GetPropertyChangedSignal("LocalPlayer"):Wait()
    LP = Players.LocalPlayer
end
local Cam = WS.CurrentCamera
local PID = game.PlaceId

warn("[PX] LocalPlayer = " .. tostring(LP))

-- ════════════════════════════════════
--  STATE
-- ════════════════════════════════════
local S = {
    autoQueue=false, queueMode="1v1",
    autoAccept=false, autoVote=false, autoReturn=false,
    autoCollect=false, autoSpin=false, spinDelay=2,
    afk=false, autoRespawn=false, autoEquip=false, autoCharm=false,
    noCd=false, noDash=false,
    fly=false, flySpeed=80, noclip=false, skeleton=false,
    ws=16, jp=50, fpsBoost=false, antiLag=false, antiAfk=true,
    kills=0, wins=0, losses=0, streak=0, best=0, last=0, coins=0,
    t0=tick(), open=true,
}

-- ════════════════════════════════════
--  GUI MOUNTING — tries every method
-- ════════════════════════════════════
if _G.PX_GUI then
    pcall(function() _G.PX_GUI:Destroy() end)
end

local Root_GUI = Instance.new("ScreenGui")
Root_GUI.Name            = "PhantomX"
Root_GUI.ResetOnSpawn    = false
Root_GUI.IgnoreGuiInset  = true
Root_GUI.DisplayOrder    = 9999
Root_GUI.Enabled         = true

local function mountGUI()
    if Root_GUI.Parent then return end
    -- 1) gethui() — Delta / Fluxus / most modern executors
    if typeof(gethui) == "function" then
        local ok = pcall(function() Root_GUI.Parent = gethui() end)
        if ok and Root_GUI.Parent then
            warn("[PX] Mounted via gethui()"); return
        end
    end
    -- 2) syn.protect_gui — Synapse X
    if syn and syn.protect_gui then
        pcall(syn.protect_gui, Root_GUI)
    end
    -- 3) CoreGui
    local ok2 = pcall(function() Root_GUI.Parent = game:GetService("CoreGui") end)
    if ok2 and Root_GUI.Parent then
        warn("[PX] Mounted via CoreGui"); return
    end
    -- 4) PlayerGui fallback
    pcall(function() Root_GUI.Parent = LP:WaitForChild("PlayerGui", 10) end)
    warn("[PX] Mounted via PlayerGui")
end

mountGUI()
_G.PX_GUI = Root_GUI

-- Keep alive — reparent if game destroys it
task.spawn(function()
    while task.wait(1) do
        if Root_GUI and not Root_GUI.Parent then
            warn("[PX] GUI destroyed — remounting...")
            mountGUI()
        end
    end
end)

warn("[PX] GUI parent = " .. tostring(Root_GUI.Parent))

-- ════════════════════════════════════
--  COLOURS
-- ════════════════════════════════════
local C = {
    bg      = Color3.fromRGB(15, 15, 22),
    panel   = Color3.fromRGB(24, 24, 36),
    accent  = Color3.fromRGB(130, 60, 255),
    accent2 = Color3.fromRGB(90, 35, 190),
    text    = Color3.fromRGB(235, 235, 255),
    sub     = Color3.fromRGB(155, 155, 185),
    on      = Color3.fromRGB(70, 210, 110),
    off     = Color3.fromRGB(210, 65, 65),
    btn     = Color3.fromRGB(35, 35, 55),
    border  = Color3.fromRGB(55, 35, 95),
}

-- ════════════════════════════════════
--  UI HELPERS
-- ════════════════════════════════════
local function corner(r,p)  local c=Instance.new("UICorner");c.CornerRadius=UDim.new(0,r);c.Parent=p end
local function stroke(c,t,p) local s=Instance.new("UIStroke");s.Color=c;s.Thickness=t;s.Parent=p end
local function pad(a,b,c,d,p)
    local x=Instance.new("UIPadding")
    x.PaddingTop=UDim.new(0,a);x.PaddingBottom=UDim.new(0,b)
    x.PaddingLeft=UDim.new(0,c);x.PaddingRight=UDim.new(0,d);x.Parent=p
end

local function Frame(sz,pos,col,par)
    local f=Instance.new("Frame")
    f.Size=sz;f.Position=pos or UDim2.new(0,0,0,0)
    f.BackgroundColor3=col or C.panel;f.BorderSizePixel=0;f.Parent=par
    return f
end

local function Label(txt,sz,col,font,par)
    local l=Instance.new("TextLabel")
    l.Text=txt;l.TextSize=sz or 13;l.TextColor3=col or C.text
    l.Font=font or Enum.Font.GothamMedium
    l.BackgroundTransparency=1;l.TextXAlignment=Enum.TextXAlignment.Left
    l.Size=UDim2.new(1,0,0,(sz or 13)+7);l.TextWrapped=true
    l.Parent=par;return l
end

-- Drag (mouse + touch)
local function Drag(handle, frame)
    local down,ds,sp=false,nil,nil
    local function start(pos)
        down=true;ds=pos;sp=frame.Position
    end
    local function move(pos)
        if not down then return end
        local d=pos-ds
        frame.Position=UDim2.new(sp.X.Scale,sp.X.Offset+d.X,sp.Y.Scale,sp.Y.Offset+d.Y)
    end
    handle.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1
        or i.UserInputType==Enum.UserInputType.Touch then
            start(Vector2.new(i.Position.X,i.Position.Y))
        end
    end)
    handle.InputEnded:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1
        or i.UserInputType==Enum.UserInputType.Touch then down=false end
    end)
    UIS.InputChanged:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseMovement
        or i.UserInputType==Enum.UserInputType.Touch then
            move(Vector2.new(i.Position.X,i.Position.Y))
        end
    end)
end

-- ════════════════════════════════════
--  MAIN WINDOW
--  Centred, AnchorPoint so it always
--  appears in the middle of any screen
-- ════════════════════════════════════
local Win=Frame(UDim2.new(0,320,0,440),UDim2.new(0.5,0,0.5,0),C.bg,Root_GUI)
Win.AnchorPoint=Vector2.new(0.5,0.5)
Win.Active=true; corner(12,Win); stroke(C.border,1.5,Win)

-- Title bar
local TB=Frame(UDim2.new(1,0,0,44),UDim2.new(0,0,0,0),C.panel,Win)
corner(12,TB)
Frame(UDim2.new(1,0,0,14),UDim2.new(0,0,1,-14),C.panel,TB)  -- square bottom corners

local TIcon=Label("⚡",18,C.accent,Enum.Font.GothamBold,TB)
TIcon.Size=UDim2.new(0,28,1,0);TIcon.Position=UDim2.new(0,8,0,0)
TIcon.TextXAlignment=Enum.TextXAlignment.Center

local TName=Label("Phantom X",14,C.text,Enum.Font.GothamBold,TB)
TName.Size=UDim2.new(1,-110,0,22);TName.Position=UDim2.new(0,40,0,6)

local TSub=Label("MvS Duels",10,C.sub,Enum.Font.Gotham,TB)
TSub.Size=UDim2.new(1,-110,0,14);TSub.Position=UDim2.new(0,40,0,26)

local function TBtn(icon,xoff,col)
    local b=Instance.new("TextButton")
    b.Size=UDim2.new(0,30,0,30);b.Position=UDim2.new(1,xoff,0.5,-15)
    b.BackgroundColor3=col;b.Text=icon;b.TextColor3=C.text
    b.TextSize=14;b.Font=Enum.Font.GothamBold;b.BorderSizePixel=0
    b.Parent=TB;corner(6,b);return b
end
local MinBtn=TBtn("—",-66,C.btn)
local ClsBtn=TBtn("✕",-32,Color3.fromRGB(175,45,45))
Drag(TB,Win)

-- Mini-bar (when minimised)
local Mini=Frame(UDim2.new(0,180,0,38),UDim2.new(0.5,-90,0,8),C.bg,Root_GUI)
Mini.Visible=false;Mini.AnchorPoint=Vector2.new(0,0)
corner(10,Mini);stroke(C.accent,1.5,Mini)
local ML=Label("⚡ Phantom X",12,C.accent,Enum.Font.GothamBold,Mini)
ML.Size=UDim2.new(1,-42,1,0);ML.Position=UDim2.new(0,8,0,0)
local MO=Instance.new("TextButton")
MO.Size=UDim2.new(0,32,0,26);MO.Position=UDim2.new(1,-36,0.5,-13)
MO.BackgroundColor3=C.accent;MO.Text="+";MO.TextColor3=C.text
MO.TextSize=16;MO.Font=Enum.Font.GothamBold;MO.BorderSizePixel=0
MO.Parent=Mini;corner(6,MO)
Drag(Mini,Mini)

local function SetOpen(v)
    S.open=v;Win.Visible=v;Mini.Visible=not v
end
MinBtn.Activated:Connect(function() SetOpen(false) end)
ClsBtn.Activated:Connect(function() SetOpen(false) end)
MO.Activated:Connect(function() SetOpen(true) end)

-- ════════════════════════════════════
--  TAB SYSTEM
-- ════════════════════════════════════
local Sidebar=Frame(UDim2.new(0,88,1,-44),UDim2.new(0,0,0,44),C.panel,Win)
stroke(C.border,0.5,Sidebar)
local SBList=Instance.new("UIListLayout")
SBList.SortOrder=Enum.SortOrder.LayoutOrder;SBList.Parent=Sidebar

local Content=Frame(UDim2.new(1,-90,1,-46),UDim2.new(0,90,0,45),C.bg,Win)

local active=nil
local tabs={}

local function MakeTab(name,icon)
    local btn=Instance.new("TextButton")
    btn.Size=UDim2.new(1,0,0,40)
    btn.BackgroundColor3=C.panel;btn.Text=""
    btn.BorderSizePixel=0;btn.LayoutOrder=#tabs+1;btn.Parent=Sidebar

    local lbl=Label(icon.."\n"..name,9,C.sub,Enum.Font.GothamMedium,btn)
    lbl.Size=UDim2.new(1,0,1,0);lbl.TextXAlignment=Enum.TextXAlignment.Center

    local frame=Frame(UDim2.new(1,0,1,0),UDim2.new(0,0,0,0),C.bg,Content)
    frame.Visible=false

    local scroll=Instance.new("ScrollingFrame")
    scroll.Size=UDim2.new(1,0,1,0)
    scroll.BackgroundTransparency=1;scroll.BorderSizePixel=0
    scroll.ScrollBarThickness=3;scroll.ScrollBarImageColor3=C.accent
    scroll.AutomaticCanvasSize=Enum.AutomaticSize.Y
    scroll.CanvasSize=UDim2.new(0,0,0,0)
    scroll.ScrollingDirection=Enum.ScrollingDirection.Y
    scroll.Parent=frame
    pad(6,8,6,6,scroll)

    local list=Instance.new("UIListLayout")
    list.SortOrder=Enum.SortOrder.LayoutOrder
    list.Padding=UDim.new(0,4);list.Parent=scroll

    local tab={btn=btn,lbl=lbl,frame=frame,scroll=scroll,n=0}

    local function activate()
        if active then
            active.frame.Visible=false
            active.lbl.TextColor3=C.sub
            active.btn.BackgroundColor3=C.panel
        end
        active=tab;frame.Visible=true
        lbl.TextColor3=C.accent;btn.BackgroundColor3=C.btn
    end
    btn.Activated:Connect(activate)
    table.insert(tabs,tab);return tab,activate
end

-- Widgets
local function Sect(tab,title)
    local f=Frame(UDim2.new(1,-4,0,20),nil,Color3.new(0,0,0),tab.scroll)
    f.BackgroundTransparency=1;f.LayoutOrder=tab.n;tab.n+=1
    local l=Label("  "..title:upper(),9,C.accent,Enum.Font.GothamBold,f)
    l.Size=UDim2.new(1,0,1,0)
    Frame(UDim2.new(1,0,0,1),UDim2.new(0,0,1,-1),C.border,f)
end

local function Toggle(tab,name,def,cb)
    local f=Frame(UDim2.new(1,-4,0,38),nil,C.btn,tab.scroll)
    corner(7,f);f.LayoutOrder=tab.n;tab.n+=1
    local l=Label(name,11,C.text,Enum.Font.GothamMedium,f)
    l.Size=UDim2.new(1,-52,1,0);l.Position=UDim2.new(0,8,0,0)

    local pill=Frame(UDim2.new(0,38,0,20),UDim2.new(1,-46,0.5,-10),def and C.on or C.off,f)
    corner(10,pill)
    local dot=Frame(UDim2.new(0,14,0,14),def and UDim2.new(1,-17,0.5,-7) or UDim2.new(0,3,0.5,-7),Color3.new(1,1,1),pill)
    corner(7,dot)

    local val=def or false
    local ti=TweenInfo.new(0.12)
    local btn=Instance.new("TextButton")
    btn.Size=UDim2.new(1,0,1,0);btn.BackgroundTransparency=1;btn.Text="";btn.Parent=f
    local function tog()
        val=not val
        TweenSvc:Create(pill,ti,{BackgroundColor3=val and C.on or C.off}):Play()
        TweenSvc:Create(dot,ti,{Position=val and UDim2.new(1,-17,0.5,-7) or UDim2.new(0,3,0.5,-7)}):Play()
        pcall(cb,val)
    end
    btn.Activated:Connect(tog)
    if def then pcall(cb,true) end
end

local function Btn(tab,name,cb)
    local f=Frame(UDim2.new(1,-4,0,36),nil,C.accent2,tab.scroll)
    corner(7,f);f.LayoutOrder=tab.n;tab.n+=1;stroke(C.accent,0.8,f)
    local btn=Instance.new("TextButton")
    btn.Size=UDim2.new(1,0,1,0);btn.BackgroundTransparency=1
    btn.Text=name;btn.TextColor3=C.text;btn.TextSize=11
    btn.Font=Enum.Font.GothamBold;btn.TextWrapped=true;btn.Parent=f
    btn.Activated:Connect(function() pcall(cb) end)
end

local function Slider(tab,name,mn,mx,def,cb)
    local f=Frame(UDim2.new(1,-4,0,54),nil,C.btn,tab.scroll)
    corner(7,f);f.LayoutOrder=tab.n;tab.n+=1
    local lbl=Label(name..": "..def,11,C.text,Enum.Font.GothamMedium,f)
    lbl.Size=UDim2.new(1,-8,0,18);lbl.Position=UDim2.new(0,8,0,4)
    local trk=Frame(UDim2.new(1,-16,0,8),UDim2.new(0,8,0,32),C.panel,f)
    corner(4,trk);stroke(C.border,0.5,trk)
    local fill=Frame(UDim2.new((def-mn)/(mx-mn),0,1,0),nil,C.accent,trk);corner(4,fill)
    local nub=Frame(UDim2.new(0,16,0,16),UDim2.new((def-mn)/(mx-mn),0,0.5,-8),C.text,trk);corner(8,nub)
    local drag=false
    local function upd(x)
        local r=math.clamp((x-trk.AbsolutePosition.X)/trk.AbsoluteSize.X,0,1)
        local v=math.floor(mn+(mx-mn)*r)
        fill.Size=UDim2.new(r,0,1,0);nub.Position=UDim2.new(r,0,0.5,-8)
        lbl.Text=name..": "..v;pcall(cb,v)
    end
    local function si(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1
        or i.UserInputType==Enum.UserInputType.Touch then drag=true;upd(i.Position.X) end
    end
    trk.InputBegan:Connect(si);nub.InputBegan:Connect(si)
    UIS.InputEnded:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1
        or i.UserInputType==Enum.UserInputType.Touch then drag=false end
    end)
    UIS.InputChanged:Connect(function(i)
        if drag and(i.UserInputType==Enum.UserInputType.MouseMovement
        or i.UserInputType==Enum.UserInputType.Touch) then upd(i.Position.X) end
    end)
    pcall(cb,def)
end

local function Dropdown(tab,name,opts,cb)
    local f=Frame(UDim2.new(1,-4,0,36),nil,C.btn,tab.scroll)
    corner(7,f);f.LayoutOrder=tab.n;tab.n+=1
    local lbl=Label(name..": "..opts[1],11,C.text,Enum.Font.GothamMedium,f)
    lbl.Size=UDim2.new(1,-28,1,0);lbl.Position=UDim2.new(0,8,0,0)
    local arr=Label("▾",13,C.accent,Enum.Font.GothamBold,f)
    arr.Size=UDim2.new(0,20,1,0);arr.Position=UDim2.new(1,-24,0,0)
    arr.TextXAlignment=Enum.TextXAlignment.Center
    local cur=1;pcall(cb,opts[1])
    local btn=Instance.new("TextButton")
    btn.Size=UDim2.new(1,0,1,0);btn.BackgroundTransparency=1;btn.Text="";btn.Parent=f
    btn.Activated:Connect(function()
        cur=cur%#opts+1;lbl.Text=name..": "..opts[cur];pcall(cb,opts[cur])
    end)
end

-- Notification
local function Notif(title,msg)
    pcall(function()
        StarterGui:SetCore("SendNotification",{Title=title,Text=msg,Duration=4})
    end)
end

-- ════════════════════════════════════
--  GAME FUNCTIONS
-- ════════════════════════════════════
local RC={}
local function GR(n)
    if RC[n] then return RC[n] end
    for _,v in ipairs(RepStorage:GetDescendants()) do
        if v.Name==n and(v:IsA("RemoteEvent") or v:IsA("RemoteFunction")) then RC[n]=v;return v end
    end
end
local function FR(n,...) local r=GR(n);if not r then return end;pcall(function() if r:IsA("RemoteEvent") then r:FireServer(...) else r:InvokeServer(...) end end) end
local function FRA(t,...) for _,n in ipairs(t) do FR(n,...) end end

local function Rt()  local c=LP.Character;return c and c:FindFirstChild("HumanoidRootPart") end
local function Hm()  local c=LP.Character;return c and c:FindFirstChildOfClass("Humanoid") end
local function TP(cf) local r=Rt();if r then pcall(function() r.CFrame=cf end) end end

local fc
local function StopFly()
    S.fly=false;if fc then fc:Disconnect();fc=nil end
    pcall(function()
        local r=Rt();if r then for _,n in ipairs({"PX_BV","PX_BG"}) do local x=r:FindFirstChild(n);if x then x:Destroy() end end end
        local h=Hm();if h then h.PlatformStand=false end
    end)
end
local function StartFly()
    StopFly();S.fly=true
    local r=Rt();local h=Hm();if not r or not h then return end
    h.PlatformStand=true
    local BV=Instance.new("BodyVelocity");BV.Name="PX_BV";BV.MaxForce=Vector3.new(1e6,1e6,1e6);BV.Parent=r
    local BG=Instance.new("BodyGyro");BG.Name="PX_BG";BG.MaxTorque=Vector3.new(1e6,1e6,1e6);BG.P=1e4;BG.Parent=r
    fc=RunService.Heartbeat:Connect(function()
        if not S.fly then StopFly();return end
        local d=Vector3.zero
        if UIS:IsKeyDown(Enum.KeyCode.W) then d=d+Cam.CFrame.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.S) then d=d-Cam.CFrame.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.A) then d=d-Cam.CFrame.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.D) then d=d+Cam.CFrame.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.Space) then d=d+Vector3.new(0,1,0) end
        if UIS:IsKeyDown(Enum.KeyCode.LeftShift) then d=d-Vector3.new(0,1,0) end
        BV.Velocity=d.Magnitude>0 and d.Unit*S.flySpeed or Vector3.zero;BG.CFrame=Cam.CFrame
    end)
end

RunService.Stepped:Connect(function()
    if not S.noclip then return end
    pcall(function()
        local c=LP.Character;if not c then return end
        for _,p in ipairs(c:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide=false end end
    end)
end)

local afkT=tick()
RunService.Heartbeat:Connect(function()
    if not S.antiAfk then return end
    if tick()-afkT>55 then afkT=tick();pcall(function() local h=Hm();if h then h.Jump=true end end) end
end)

RunService.Heartbeat:Connect(function()
    if not S.noCd and not S.noDash then return end
    pcall(function()
        local c=LP.Character;if not c then return end
        for _,v in ipairs(c:GetDescendants()) do
            if(v:IsA("NumberValue") or v:IsA("IntValue")) and v.Value>0 then
                local n=v.Name:lower()
                if(S.noCd and(n:match("cool") or n:match("cd") or n:match("ability")))
                or(S.noDash and n:match("dash")) then v.Value=0 end
            end
        end
        if S.noCd then for _,a in ipairs({"Cooldown","DashCooldown","AbilityCooldown"}) do if LP:GetAttribute(a) then LP:SetAttribute(a,0) end end end
    end)
end)

LP.CharacterAdded:Connect(function(c)
    task.wait(1.5)
    local h=c:FindFirstChildOfClass("Humanoid");if not h then return end
    h.WalkSpeed=S.ws;h.JumpPower=S.jp
    if S.fly then task.wait(0.5);StartFly() end
    h.Died:Connect(function()
        if S.streak>0 then S.last=S.streak end
        S.losses+=1;S.streak=0
        if S.autoRespawn then task.wait(0.3);pcall(function() LP:LoadCharacter() end) end
    end)
end)

local function FindPad(mode)
    local kw=mode:lower();local r=Rt();if not r then return nil end
    local best,bd=nil,math.huge
    for _,v in ipairs(WS:GetDescendants()) do
        if v:IsA("BasePart") then
            local n=v.Name:lower()
            if n:match(kw) or n:match("queue") or n:match("pad") then
                local d=(v.Position-r.Position).Magnitude
                if d<bd then best=v;bd=d end
            end
        end
    end
    return best
end
local function JoinQueue() local p=FindPad(S.queueMode);if p then TP(CFrame.new(p.Position+Vector3.new(0,4,0))) end;FRA({"JoinQueue","QueueJoin","JoinMatch","EnterQueue"},S.queueMode) end
local function Accept()
    FRA({"AcceptMatch","AcceptQueue","ReadyUp","ConfirmMatch"})
    for _,v in ipairs(LP.PlayerGui:GetDescendants()) do if v:IsA("TextButton") then local t=v.Text:lower();if t:match("accept") or t:match("ready") then pcall(function() v.MouseButton1Click:Fire() end) end end end
end
local function Vote()
    FRA({"Vote","VoteMap","MapVote"},1)
    for _,v in ipairs(LP.PlayerGui:GetDescendants()) do if v:IsA("TextButton") and v.Text:lower():match("vote") then pcall(function() v.MouseButton1Click:Fire() end);break end end
end
local function ToLobby()
    FRA({"ReturnToLobby","BackToLobby","Lobby"})
    for _,v in ipairs(LP.PlayerGui:GetDescendants()) do if v:IsA("TextButton") then local t=v.Text:lower();if t:match("lobby") or t:match("leave") then pcall(function() v.MouseButton1Click:Fire() end);break end end end
end
local function Daily()
    FRA({"ClaimDaily","DailyReward","ClaimReward"})
    for _,v in ipairs(LP.PlayerGui:GetDescendants()) do if v:IsA("TextButton") then local t=v.Text:lower();if t:match("daily") or t:match("claim") then pcall(function() v.MouseButton1Click:Fire() end);Notif("Daily","Claimed!");return end end end
end
local function Spin()
    FRA({"Spin","SpinCrate","OpenCrate","OpenCase"})
    for _,v in ipairs(LP.PlayerGui:GetDescendants()) do if v:IsA("TextButton") then local t=v.Text:lower();if t:match("spin") or t:match("open") then pcall(function() v.MouseButton1Click:Fire() end);return end end end
end
local function EquipBest()
    local bp=LP:FindFirstChild("Backpack");local h=Hm()
    if bp and h then local t=bp:GetChildren();table.sort(t,function(a,b) return(a:GetAttribute("Power") or 0)>(b:GetAttribute("Power") or 0) end);if t[1] then pcall(function() h:EquipTool(t[1]) end);Notif("Weapon",t[1].Name) end end
end
local function Collect()
    local r=Rt();if not r then return end
    for _,v in ipairs(WS:GetDescendants()) do if v:IsA("BasePart") then local n=v.Name:lower();if n:match("coin") or n:match("gem") or n:match("pickup") then if(v.Position-r.Position).Magnitude<60 then TP(CFrame.new(v.Position+Vector3.new(0,3,0)));task.wait(0.05) end end end end
end
local function GiveCoins(amt)
    FRA({"GiveCoins","AddCoins","GrantCoins","GiveCash"},amt)
    pcall(function() local ls=LP:FindFirstChild("leaderstats");if ls then for _,v in ipairs(ls:GetChildren()) do if v:IsA("IntValue") or v:IsA("NumberValue") then v.Value+=amt end end end end)
    Notif("Coins","+"..amt.." sent!")
end
local function Hop()
    Notif("Server Hop","Searching...")
    local ok,data=pcall(function() return HttpSvc:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/"..PID.."/servers/Public?sortOrder=Asc&limit=100",true)) end)
    if ok and data and data.data then for _,s in ipairs(data.data) do if s.id~=game.JobId and s.playing<s.maxPlayers then pcall(function() TpSvc:TeleportToPlaceInstance(PID,s.id,LP) end);return end end end
    pcall(function() TpSvc:Teleport(PID,LP) end)
end

task.spawn(function()
    local ls=LP:WaitForChild("leaderstats",15);if not ls then return end
    for _,v in ipairs(ls:GetChildren()) do
        if v:IsA("IntValue") or v:IsA("NumberValue") then v.Changed:Connect(function(val)
            local n=v.Name:lower()
            if n:match("kill") then S.kills=val end
            if n:match("win") and val>S.wins then S.wins=val;S.streak+=1;if S.streak>S.best then S.best=S.streak end;Notif("Win!","Streak: "..S.streak) end
            if n:match("coin") or n:match("cash") then S.coins=val end
        end) end
    end
end)

-- ════════════════════════════════════
--  BUILD TABS
-- ════════════════════════════════════
local tFarm,  aFarm  = MakeTab("Farm",  "🎮")
local tFight, aFight = MakeTab("Fight", "⚔️")
local tCoins, aCoins = MakeTab("Coins", "💰")
local tMove,  aMove  = MakeTab("Move",  "✈️")
local tVis,   aVis   = MakeTab("Visual","👁")
local tQoL,   aQoL   = MakeTab("QoL",  "🔧")

aFarm() -- open first tab

-- 🎮 FARM
Sect(tFarm,"Automation")
Toggle(tFarm,"Auto Farm (All-in-One)",false,function(v)
    S.autoQueue=v;S.autoAccept=v;S.autoVote=v;S.autoCollect=v;S.autoReturn=v
    Notif("Auto Farm",v and "ON" or "OFF")
end)
Toggle(tFarm,"Auto Queue",false,function(v) S.autoQueue=v end)
Toggle(tFarm,"Auto Accept",false,function(v) S.autoAccept=v end)
Toggle(tFarm,"Auto Vote",false,function(v) S.autoVote=v end)
Toggle(tFarm,"Auto Return to Lobby",false,function(v) S.autoReturn=v end)
Toggle(tFarm,"Auto Collect Pickups",false,function(v) S.autoCollect=v end)
Toggle(tFarm,"Auto Spin Crates",false,function(v) S.autoSpin=v end)
Toggle(tFarm,"AFK Farm Mode",false,function(v) S.afk=v;S.autoQueue=v end)
Toggle(tFarm,"Auto Claim Daily",false,function(v) if v then task.spawn(Daily) end end)
Dropdown(tFarm,"Queue Mode",{"1v1","2v2","3v3","4v4"},function(v) S.queueMode=v end)
Sect(tFarm,"Manual")
Btn(tFarm,"Join Queue Now",function() JoinQueue();Notif("Queue","Fired!") end)
Btn(tFarm,"Accept Match Now",function() Accept() end)
Btn(tFarm,"Vote Now",function() Vote() end)
Btn(tFarm,"Return to Lobby",function() ToLobby() end)
Btn(tFarm,"Claim Daily Reward",function() Daily() end)
Btn(tFarm,"Spin Crate Now",function() Spin();Notif("Crate","Fired!") end)

-- ⚔️ FIGHT
Sect(tFight,"Abilities")
Toggle(tFight,"No Ability Cooldown",false,function(v) S.noCd=v;Notif("Cooldown",v and "Instant!" or "Normal") end)
Toggle(tFight,"No Dash Cooldown",false,function(v) S.noDash=v end)
Toggle(tFight,"Auto Equip Best Weapon",false,function(v) S.autoEquip=v;if v then EquipBest() end end)
Btn(tFight,"Equip Best Weapon Now",function() EquipBest() end)

-- 💰 COINS
Sect(tCoins,"Currency")
local coinAmt=50000
Slider(tCoins,"Amount",1000,500000,50000,function(v) coinAmt=v end)
Btn(tCoins,"Give Coins",function() GiveCoins(coinAmt) end)

-- ✈️ MOVE
Sect(tMove,"Fly")
Toggle(tMove,"Fly",false,function(v) if v then StartFly() else StopFly() end end)
Slider(tMove,"Fly Speed",10,300,80,function(v) S.flySpeed=v end)
Sect(tMove,"Ground")
Toggle(tMove,"Noclip",false,function(v) S.noclip=v end)
Slider(tMove,"Walk Speed",16,300,16,function(v) S.ws=v;local h=Hm();if h then h.WalkSpeed=v end end)
Slider(tMove,"Jump Power",50,300,50,function(v) S.jp=v;local h=Hm();if h then h.JumpPower=v end end)
Btn(tMove,"Teleport to Spawn",function()
    local sp=WS:FindFirstChildOfClass("SpawnLocation")
    if sp then TP(sp.CFrame+Vector3.new(0,5,0));Notif("Teleport","Done!") end
end)

-- 👁 VISUAL
Sect(tVis,"Performance")
Toggle(tVis,"FPS Boost",false,function(v)
    pcall(function()
        Lighting.GlobalShadows=not v
        for _,x in ipairs(Lighting:GetChildren()) do if x:IsA("PostEffect") or x:IsA("Atmosphere") then pcall(function() x.Enabled=not v end) end end
        for _,x in ipairs(WS:GetDescendants()) do if x:IsA("ParticleEmitter") or x:IsA("Fire") then pcall(function() x.Enabled=not v end) end end
    end)
    Notif("FPS Boost",v and "ON" or "OFF")
end)
Toggle(tVis,"Anti-Lag",false,function(v)
    if v then pcall(function() for _,t in ipairs(WS:GetDescendants()) do if t:IsA("Texture") or t:IsA("Decal") then t.Transparency=1 end end end) end
    Notif("Anti-Lag",v and "ON" or "OFF")
end)

-- 🔧 QOL
Sect(tQoL,"Quality of Life")
Toggle(tQoL,"Anti-AFK",true,function(v) S.antiAfk=v end)
Toggle(tQoL,"Auto Respawn",false,function(v) S.autoRespawn=v end)
Btn(tQoL,"Server Hop",function() task.spawn(Hop) end)
Btn(tQoL,"Rejoin Now",function() Notif("Rejoin","...");task.wait(1);pcall(function() TpSvc:Teleport(PID,LP) end) end)
Btn(tQoL,"Dump Remotes (output)",function()
    for _,v in ipairs(RepStorage:GetDescendants()) do
        if v:IsA("RemoteEvent") or v:IsA("RemoteFunction") then print("["..v.ClassName.."] "..v:GetFullName()) end
    end
    Notif("Remotes","Printed to output!")
end)

-- ════════════════════════════════════
--  MAIN LOOP
-- ════════════════════════════════════
local T={q=0,a=0,v=0,col=0,sp=0,eq=0}
RunService.Heartbeat:Connect(function()
    local now=tick()
    if(S.autoQueue or S.afk) and now-T.q>8  then T.q=now;task.spawn(JoinQueue) end
    if S.autoAccept and now-T.a>2            then T.a=now;Accept() end
    if S.autoVote   and now-T.v>3            then T.v=now;Vote() end
    if S.autoCollect and now-T.col>2         then T.col=now;task.spawn(Collect) end
    if S.autoSpin   and now-T.sp>S.spinDelay then T.sp=now;Spin() end
    if S.autoEquip  and now-T.eq>5           then T.eq=now;task.spawn(EquipBest) end
    if S.autoReturn then for _,v in ipairs(LP.PlayerGui:GetDescendants()) do if v:IsA("TextButton") then local t=v.Text:lower();if t:match("lobby") or t:match("return") then pcall(function() v.MouseButton1Click:Fire() end) end end end end
end)

warn("[PX] ✅ All done — window should be visible!")
Notif("Phantom X","Loaded! Window is in the centre of your screen.")
