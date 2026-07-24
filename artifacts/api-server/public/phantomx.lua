-- Phantom X v8 | MvS Duels
local RUN=game:GetService("RunService")
local PLR=game:GetService("Players")
local UIS=game:GetService("UserInputService")
local TSV=game:GetService("TweenService")
local WS =game:GetService("Workspace")
local RS =game:GetService("ReplicatedStorage")
local TP =game:GetService("TeleportService")
local LIG=game:GetService("Lighting")
local DEB=game:GetService("Debris")
local SG =game:GetService("StarterGui")
local LP=PLR.LocalPlayer
local CAM=WS.CurrentCamera
local PID=game.PlaceId

local G={fly=false,spd=80,ws=16,jp=50,noclip=false,nocd=false,
 shoot=false,sdist=300,scd=2.5,knife=false,kdist=300,kcd=2,
 tbot=false,hbox=false,hsize=13,
 aq=false,qmode="1v1",aac=false,avt=false,arc=false,acol=false,aspin=false,spd2=2,
 sreg=false,spro=false,
 afk=true,aresp=false,fps=false,
 kills=0,wins=0,losses=0,streak=0,best=0,coins=0,
 enemies={}}

-- MOUNT GUI
local ROOT=Instance.new("ScreenGui")
ROOT.Name="PX" ROOT.ResetOnSpawn=false ROOT.IgnoreGuiInset=true ROOT.DisplayOrder=9999
local function mnt()
 if ROOT.Parent then return end
 if type(gethui)=="function" then pcall(function()ROOT.Parent=gethui()end)end
 if not ROOT.Parent then pcall(function()ROOT.Parent=game:GetService("CoreGui")end)end
 if not ROOT.Parent then pcall(function()ROOT.Parent=LP:WaitForChild("PlayerGui",8)end)end
end
mnt()
task.spawn(function() while task.wait(1) do if not ROOT.Parent then mnt() end end end)

local function N(t,m) pcall(function()SG:SetCore("SendNotification",{Title=t,Text=m,Duration=4})end)end

-- COLOURS
local BG=Color3.fromRGB(18,18,28)
local SD=Color3.fromRGB(22,22,34)
local SH=Color3.fromRGB(32,32,50)
local AC=Color3.fromRGB(138,63,255)
local A2=Color3.fromRGB(95,38,190)
local TX=Color3.fromRGB(230,230,248)
local SB=Color3.fromRGB(140,140,175)
local ON=Color3.fromRGB(68,207,110)
local OF=Color3.fromRGB(200,60,60)
local CD=Color3.fromRGB(30,30,46)
local BD=Color3.fromRGB(50,30,85)
local HD=Color3.fromRGB(14,14,22)

local function fr(sz,pos,col,par,tr)
 local f=Instance.new("Frame")
 f.Size=sz f.Position=pos or UDim2.new(0,0,0,0)
 f.BackgroundColor3=col or CD f.BackgroundTransparency=tr or 0
 f.BorderSizePixel=0 f.Parent=par return f
end
local function cr(r,p) local c=Instance.new("UICorner")c.CornerRadius=UDim.new(0,r)c.Parent=p end
local function st(col,t,p) local s=Instance.new("UIStroke")s.Color=col s.Thickness=t s.ApplyStrokeMode=Enum.ApplyStrokeMode.Border s.Parent=p end
local function lb(txt,sz,col,par,xa)
 local l=Instance.new("TextLabel")
 l.Text=txt l.TextSize=sz or 12 l.TextColor3=col or TX
 l.Font=Enum.Font.GothamMedium l.BackgroundTransparency=1
 l.TextXAlignment=xa or Enum.TextXAlignment.Left
 l.Size=UDim2.new(1,0,1,0) l.TextTruncate=Enum.TextTruncate.AtEnd l.Parent=par return l
end
local function tb(par)
 local b=Instance.new("TextButton")
 b.Size=UDim2.new(1,0,1,0) b.BackgroundTransparency=1 b.Text="" b.Parent=par return b
end

-- DRAG
local function drag(handle,frame)
 local dn,ds,sp=false
 handle.InputBegan:Connect(function(i)
  if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
   dn=true ds=Vector2.new(i.Position.X,i.Position.Y) sp=frame.Position
  end
 end)
 handle.InputEnded:Connect(function(i)
  if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then dn=false end
 end)
 UIS.InputChanged:Connect(function(i)
  if not dn then return end
  if i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch then
   local d=Vector2.new(i.Position.X,i.Position.Y)-ds
   frame.Position=UDim2.new(sp.X.Scale,sp.X.Offset+d.X,sp.Y.Scale,sp.Y.Offset+d.Y)
  end
 end)
end

-- WINDOW
local WIN=fr(UDim2.new(0,600,0,420),UDim2.new(0.5,-300,0.5,-210),BG,ROOT)
WIN.Active=true cr(10,WIN) st(BD,1.5,WIN)

local HDR=fr(UDim2.new(1,0,0,46),nil,HD,WIN) cr(10,HDR)
fr(UDim2.new(1,0,0,12),UDim2.new(0,0,1,-12),HD,WIN)
local ib=fr(UDim2.new(0,32,0,32),UDim2.new(0,8,0,7),A2,HDR) cr(8,ib)
lb("⚡",17,Color3.new(1,1,1),ib,Enum.TextXAlignment.Center)
local tl=lb("Phantom X",15,TX,HDR) tl.Size=UDim2.new(0,170,0,22) tl.Position=UDim2.new(0,48,0,5) tl.Font=Enum.Font.GothamBold
local sl=lb("MvS Duels  |  v8",10,SB,HDR) sl.Size=UDim2.new(0,200,0,14) sl.Position=UDim2.new(0,48,0,27)
local tg=fr(UDim2.new(0,94,0,22),UDim2.new(0,242,0,12),Color3.fromRGB(20,55,20),HDR) cr(5,tg) st(ON,1,tg)
lb("✔ UNDETECTED",9,ON,tg,Enum.TextXAlignment.Center)

local function wbtn(icon,xo,bg)
 local b=Instance.new("TextButton")
 b.Size=UDim2.new(0,28,0,28) b.Position=UDim2.new(1,xo,0.5,-14)
 b.BackgroundColor3=bg b.Text=icon b.TextColor3=TX b.TextSize=12
 b.Font=Enum.Font.GothamBold b.BorderSizePixel=0 b.Parent=HDR cr(6,b) return b
end
local MB=wbtn("━",-92,Color3.fromRGB(36,36,56))
wbtn("✕",-30,Color3.fromRGB(180,45,45)).Activated:Connect(function()WIN.Visible=false end)
drag(HDR,WIN)

-- MINI
local MN=fr(UDim2.new(0,148,0,34),UDim2.new(0.5,-74,0,6),HD,ROOT)
MN.Visible=false cr(17,MN) st(AC,1.5,MN)
lb("⚡ Phantom X",12,AC,MN).Position=UDim2.new(0,10,0,0)
local mo=Instance.new("TextButton")
mo.Size=UDim2.new(0,28,0,26) mo.Position=UDim2.new(1,-32,0.5,-13)
mo.BackgroundColor3=AC mo.Text="+" mo.TextColor3=Color3.new(1,1,1) mo.TextSize=15
mo.Font=Enum.Font.GothamBold mo.BorderSizePixel=0 mo.Parent=MN cr(13,mo)
drag(MN,MN)
MB.Activated:Connect(function()WIN.Visible=false MN.Visible=true end)
mo.Activated:Connect(function()WIN.Visible=true MN.Visible=false end)

-- SIDEBAR
local SIDE=fr(UDim2.new(0,166,1,-46),UDim2.new(0,0,0,46),SD,WIN) st(BD,0.7,SIDE)
local sll=Instance.new("UIListLayout") sll.SortOrder=Enum.SortOrder.LayoutOrder sll.Padding=UDim.new(0,2) sll.Parent=SIDE
local function pd(t,b,l,r,p) local x=Instance.new("UIPadding") x.PaddingTop=UDim.new(0,t) x.PaddingBottom=UDim.new(0,b) x.PaddingLeft=UDim.new(0,l) x.PaddingRight=UDim.new(0,r) x.Parent=p end
pd(6,60,4,4,SIDE)

-- Player card
local pc=fr(UDim2.new(1,-8,0,46),UDim2.new(0,4,1,-52),CD,SIDE) cr(8,pc) pd(4,4,8,4,pc)
local pn=lb(LP.Name,11,TX,pc) pn.Size=UDim2.new(1,0,0,18) pn.Position=UDim2.new(0,0,0,2) pn.Font=Enum.Font.GothamBold
local ps=lb("MvS Duels",9,SB,pc) ps.Size=UDim2.new(1,0,0,14) ps.Position=UDim2.new(0,0,0,22)

-- CONTENT
local CONT=fr(UDim2.new(1,-168,1,-48),UDim2.new(0,168,0,47),Color3.fromRGB(23,23,37),WIN)

-- TAB SYSTEM
local actTab=nil
local tn=0
local function mkTab(ico,title)
 tn=tn+1
 local ord=tn
 local btn=Instance.new("TextButton")
 btn.Size=UDim2.new(1,-8,0,36) btn.BackgroundColor3=SD btn.Text=""
 btn.BorderSizePixel=0 btn.LayoutOrder=ord btn.Parent=SIDE cr(7,btn)
 local row=fr(UDim2.new(1,0,1,0),nil,Color3.new(0,0,0),btn,1)
 local il=lb(ico,13,SB,row,Enum.TextXAlignment.Center) il.Size=UDim2.new(0,26,1,0) il.Position=UDim2.new(0,5,0,0)
 local nl=lb(title,11,SB,row) nl.Size=UDim2.new(1,-34,1,0) nl.Position=UDim2.new(0,33,0,0)
 local bar=fr(UDim2.new(0,3,0.65,0),UDim2.new(0,0,0.175,0),AC,btn) bar.Visible=false cr(2,bar)
 local scr=Instance.new("ScrollingFrame")
 scr.Size=UDim2.new(1,0,1,0) scr.BackgroundTransparency=1 scr.BorderSizePixel=0
 scr.ScrollBarThickness=3 scr.ScrollBarImageColor3=AC
 scr.CanvasSize=UDim2.new(0,0,0,0) scr.AutomaticCanvasSize=Enum.AutomaticSize.Y
 scr.ScrollingDirection=Enum.ScrollingDirection.Y scr.Visible=false scr.Parent=CONT
 pd(8,10,8,8,scr)
 local sl2=Instance.new("UIListLayout") sl2.SortOrder=Enum.SortOrder.LayoutOrder sl2.Padding=UDim.new(0,5) sl2.Parent=scr
 local t={scr=scr,n=0,btn=btn,bar=bar,il=il,nl=nl}
 local function act()
  if actTab then actTab.scr.Visible=false actTab.bar.Visible=false actTab.btn.BackgroundColor3=SD actTab.il.TextColor3=SB actTab.nl.TextColor3=SB end
  actTab=t scr.Visible=true bar.Visible=true btn.BackgroundColor3=SH il.TextColor3=AC nl.TextColor3=TX
 end
 btn.Activated:Connect(act)
 return t,act
end

-- WIDGETS
local function sect(t,title)
 t.n=t.n+1
 local f=fr(UDim2.new(1,-2,0,20),nil,Color3.new(0,0,0),t.scr,1) f.LayoutOrder=t.n
 local l=lb("  "..title:upper(),9,AC,f) l.Font=Enum.Font.GothamBold
 fr(UDim2.new(1,0,0,1),UDim2.new(0,0,1,-1),BD,f)
end
local function tog(t,title,desc,def,cb)
 t.n=t.n+1
 local h=((desc and desc~="") and 48 or 38)
 local f=fr(UDim2.new(1,-2,0,h),nil,CD,t.scr) cr(7,f) f.LayoutOrder=t.n
 local tl2=lb(title,11,TX,f) tl2.Size=UDim2.new(1,-56,0,16) tl2.Position=UDim2.new(0,10,0,6)
 if desc and desc~="" then local dl=lb(desc,9,SB,f) dl.Size=UDim2.new(1,-56,0,14) dl.Position=UDim2.new(0,10,0,26) dl.TextWrapped=true end
 local pill=fr(UDim2.new(0,40,0,22),UDim2.new(1,-48,0.5,-11),def and ON or OF,f) cr(11,pill)
 local dot=fr(UDim2.new(0,16,0,16),def and UDim2.new(1,-19,0.5,-8) or UDim2.new(0,3,0.5,-8),Color3.new(1,1,1),pill) cr(8,dot)
 local val=def or false
 local ti=TweenInfo.new(0.12)
 tb(f).Activated:Connect(function()
  val=not val
  TSV:Create(pill,ti,{BackgroundColor3=val and ON or OF}):Play()
  TSV:Create(dot,ti,{Position=val and UDim2.new(1,-19,0.5,-8) or UDim2.new(0,3,0.5,-8)}):Play()
  pcall(cb,val)
 end)
 if def then pcall(cb,true) end
end
local function btn(t,title,sub,cb)
 t.n=t.n+1
 local f=fr(UDim2.new(1,-2,0,38),nil,A2,t.scr) cr(7,f) st(AC,0.8,f) f.LayoutOrder=t.n
 local l=lb(title,11,TX,f,Enum.TextXAlignment.Center)
 if sub and sub~="" then l.Size=UDim2.new(1,0,0,18) l.Position=UDim2.new(0,0,0,5) local s=lb(sub,9,SB,f,Enum.TextXAlignment.Center) s.Size=UDim2.new(1,0,0,14) s.Position=UDim2.new(0,0,0,24) end
 tb(f).Activated:Connect(function()pcall(cb)end)
end
local function sld(t,title,mn,mx,def,stp,cb)
 t.n=t.n+1
 local f=fr(UDim2.new(1,-2,0,56),nil,CD,t.scr) cr(7,f) f.LayoutOrder=t.n
 local val=def
 local lbl=lb(title..": "..val,11,TX,f) lbl.Size=UDim2.new(1,-8,0,18) lbl.Position=UDim2.new(0,10,0,4)
 local trk=fr(UDim2.new(1,-20,0,8),UDim2.new(0,10,0,34),SD,f) cr(4,trk) st(BD,0.5,trk)
 local fill=fr(UDim2.new((def-mn)/(mx-mn),0,1,0),nil,AC,trk) cr(4,fill)
 local nub=fr(UDim2.new(0,18,0,18),UDim2.new((def-mn)/(mx-mn),0,0.5,-9),Color3.new(1,1,1),trk) cr(9,nub)
 local dn2=false
 local function upd(x)
  local r=math.clamp((x-trk.AbsolutePosition.X)/math.max(trk.AbsoluteSize.X,1),0,1)
  val=mn+math.round((mx-mn)*r/(stp or 1))*(stp or 1)
  fill.Size=UDim2.new(r,0,1,0) nub.Position=UDim2.new(r,0,0.5,-9) lbl.Text=title..": "..val pcall(cb,val)
 end
 local function si(i) if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then dn2=true upd(i.Position.X) end end
 trk.InputBegan:Connect(si) nub.InputBegan:Connect(si)
 UIS.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then dn2=false end end)
 UIS.InputChanged:Connect(function(i) if dn2 and(i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch)then upd(i.Position.X)end end)
 pcall(cb,def)
end
local function dd(t,title,opts,cb)
 t.n=t.n+1
 local f=fr(UDim2.new(1,-2,0,38),nil,CD,t.scr) cr(7,f) f.LayoutOrder=t.n
 local cur=1
 local l=lb(title..": "..opts[1],11,TX,f) l.Size=UDim2.new(1,-30,1,0) l.Position=UDim2.new(0,10,0,0)
 lb("▾",14,AC,f,Enum.TextXAlignment.Center).Size=UDim2.new(0,24,1,0)
 pcall(cb,opts[1])
 tb(f).Activated:Connect(function()cur=cur%#opts+1 l.Text=title..": "..opts[cur] pcall(cb,opts[cur])end)
end
local function card(t,title,body,col)
 t.n=t.n+1
 local f=fr(UDim2.new(1,-2,0,10),nil,CD,t.scr) f.AutomaticSize=Enum.AutomaticSize.Y cr(7,f) f.LayoutOrder=t.n
 fr(UDim2.new(0,3,1,0),nil,col or AC,f)
 local tl2=Instance.new("TextLabel") tl2.Size=UDim2.new(1,-14,0,16) tl2.Position=UDim2.new(0,12,0,5) tl2.Text=title tl2.TextSize=11 tl2.Font=Enum.Font.GothamBold tl2.TextColor3=col or AC tl2.BackgroundTransparency=1 tl2.TextXAlignment=Enum.TextXAlignment.Left tl2.Parent=f
 local bl=Instance.new("TextLabel") bl.Size=UDim2.new(1,-14,0,0) bl.Position=UDim2.new(0,12,0,23) bl.Text=body bl.TextSize=10 bl.Font=Enum.Font.Gotham bl.TextColor3=SB bl.BackgroundTransparency=1 bl.TextXAlignment=Enum.TextXAlignment.Left bl.TextWrapped=true bl.AutomaticSize=Enum.AutomaticSize.Y bl.Parent=f
 return bl
end

-- GAME HELPERS
local function rt() local c=LP.Character return c and c:FindFirstChild("HumanoidRootPart") end
local function hm() local c=LP.Character return c and c:FindFirstChildOfClass("Humanoid") end
local function tp(cf) pcall(function()local r=rt() if r then r.CFrame=cf end end) end
local RC={}
local function gr(n) if RC[n] then return RC[n] end pcall(function()for _,v in ipairs(RS:GetDescendants())do if v.Name==n and(v:IsA("RemoteEvent") or v:IsA("RemoteFunction"))then RC[n]=v end end end) return RC[n] end
local function fr2(n,...) local r=gr(n) if not r then return end pcall(function()if r:IsA("RemoteEvent")then r:FireServer(...)else r:InvokeServer(...)end end) end
local function fra(t,...) for _,n in ipairs(t)do fr2(n,...)end end

task.spawn(function()
 while true do pcall(function()
  local cur=LP:GetAttribute("Match") local tmp={}
  if cur then for _,v in ipairs(PLR:GetPlayers())do if v~=LP and v:GetAttribute("Match")==cur then local c=v.Character if c and c:FindFirstChildOfClass("Humanoid") and c.Humanoid.Health>0 then table.insert(tmp,v)end end end end
  G.enemies=tmp
 end) task.wait(0.1) end
end)

local function nearest(md)
 local r=rt() if not r then return end
 local best,bd=nil,md or math.huge
 for _,v in ipairs(G.enemies)do pcall(function()local c=v.Character if not c then return end local h=c:FindFirstChild("HumanoidRootPart") if not h then return end local d=(h.Position-r.Position).Magnitude if d<bd then best=v bd=d end end)end
 return best
end

local canShoot=true
local function shoot(v) pcall(function()
 if not canShoot then return end
 local mc=LP.Character if not mc then return end local hr=mc:FindFirstChild("HumanoidRootPart") if not hr then return end
 local hit=v.Character and(v.Character:FindFirstChild("Head") or v.Character:FindFirstChild("HumanoidRootPart")) if not hit then return end
 canShoot=false
 pcall(function()RS.Remotes.ShootGun:FireServer(hr.Position,hit.Position,hit,hit.Position)end)
 task.delay(G.scd,function()canShoot=true end)
end)end
local function throwk(v) pcall(function()local hit=v.Character and(v.Character:FindFirstChild("Head") or v.Character:FindFirstChild("HumanoidRootPart")) if hit then RS.Remotes.ThrowKnife:FireServer(hit.Position)end end)end

local sth,kth
local function stShoot() if sth then task.cancel(sth)end sth=task.spawn(function()while G.shoot do local e=nearest(G.sdist) if e then shoot(e)end task.wait(0.1)end end)end
local function stKnife() if kth then task.cancel(kth)end kth=task.spawn(function()while G.knife do local e=nearest(G.kdist) if e then throwk(e)end task.wait(G.kcd)end end)end

RUN.Heartbeat:Connect(function()
 if G.nocd then pcall(function()local c=LP.Character if not c then return end for _,v in ipairs(c:GetDescendants())do if(v:IsA("NumberValue") or v:IsA("IntValue"))and v.Value>0 then local n=v.Name:lower() if n:match("cool") or n:match("cd")then v.Value=0 end end end end)end
 if G.tbot then pcall(function()local ray=CAM:ScreenPointToRay(CAM.ViewportSize.X/2,CAM.ViewportSize.Y/2) local res=WS:Raycast(ray.Origin,ray.Direction*600) if not res then return end local m=res.Instance:FindFirstAncestorOfClass("Model") if not m then return end local p=PLR:GetPlayerFromCharacter(m) if p and p~=LP then shoot(p)end end)end
end)

local function clrHB() pcall(function()for _,v in ipairs(WS:GetDescendants())do if v.Name=="PXHB" then v:Destroy()end end end)end
local function rfHB()
 clrHB() if not G.hbox then return end
 for _,v in ipairs(G.enemies)do pcall(function()local c=v.Character if not c then return end local hr=c:FindFirstChild("HumanoidRootPart") if not hr then return end
  local h=Instance.new("Part") h.Name="PXHB" h.Size=Vector3.new(G.hsize,G.hsize,G.hsize) h.Transparency=0.75 h.CanCollide=false h.BrickColor=BrickColor.new("Bright red") h.Material=Enum.Material.Neon h.Parent=c
  local w=Instance.new("Weld") w.Part0=hr w.Part1=h w.Parent=hr
 end)end
end

local fc
local function stopFly() G.fly=false if fc then fc:Disconnect() fc=nil end pcall(function()local r=rt() if not r then return end for _,n in ipairs({"PXBV","PXBG"})do local x=r:FindFirstChild(n) if x then x:Destroy()end end local h=hm() if h then h.PlatformStand=false end end)end
local function startFly() stopFly() G.fly=true local r=rt() local h=hm() if not r or not h then return end h.PlatformStand=true
 local BV=Instance.new("BodyVelocity") BV.Name="PXBV" BV.MaxForce=Vector3.new(1e6,1e6,1e6) BV.Parent=r
 local BG=Instance.new("BodyGyro") BG.Name="PXBG" BG.MaxTorque=Vector3.new(1e6,1e6,1e6) BG.P=1e4 BG.Parent=r
 fc=RUN.Heartbeat:Connect(function()
  if not G.fly then stopFly() return end
  local d=Vector3.zero
  if UIS:IsKeyDown(Enum.KeyCode.W) then d=d+CAM.CFrame.LookVector end
  if UIS:IsKeyDown(Enum.KeyCode.S) then d=d-CAM.CFrame.LookVector end
  if UIS:IsKeyDown(Enum.KeyCode.A) then d=d-CAM.CFrame.RightVector end
  if UIS:IsKeyDown(Enum.KeyCode.D) then d=d+CAM.CFrame.RightVector end
  if UIS:IsKeyDown(Enum.KeyCode.Space) then d=d+Vector3.new(0,1,0) end
  if UIS:IsKeyDown(Enum.KeyCode.LeftShift) then d=d-Vector3.new(0,1,0) end
  BV.Velocity=d.Magnitude>0 and d.Unit*G.spd or Vector3.zero BG.CFrame=CAM.CFrame
 end)
end

RUN.Stepped:Connect(function()
 if G.noclip then pcall(function()local c=LP.Character if not c then return end for _,p in ipairs(c:GetDescendants())do if p:IsA("BasePart")then p.CanCollide=false end end end)end
 if G.hbox and #G.enemies>0 then task.spawn(rfHB)end
end)

local function findPad(mode) local r=rt() if not r then return end local best,bd=nil,math.huge pcall(function()for _,v in ipairs(WS:GetDescendants())do if v:IsA("BasePart")then local n=v.Name:lower() if n:match(mode:lower()) or n:match("queue") or n:match("pad")then local d=(v.Position-r.Position).Magnitude if d<bd then best=v bd=d end end end end end) return best end
local function joinQ() pcall(function()local p=findPad(G.qmode) if p then tp(CFrame.new(p.Position+Vector3.new(0,4,0)))end fra({"JoinQueue","QueueJoin","JoinMatch","EnterQueue"},G.qmode)end)end
local function acceptM() pcall(function()fra({"AcceptMatch","AcceptQueue","ReadyUp"}) for _,v in ipairs(LP.PlayerGui:GetDescendants())do if v:IsA("TextButton")then local t=v.Text:lower() if t:match("accept") or t:match("ready")then v.MouseButton1Click:Fire()end end end end)end
local function voteM() pcall(function()fra({"Vote","VoteMap"},1) for _,v in ipairs(LP.PlayerGui:GetDescendants())do if v:IsA("TextButton") and v.Text:lower():match("vote")then v.MouseButton1Click:Fire() break end end end)end
local function lobbyM() pcall(function()fra({"ReturnToLobby","BackToLobby"}) for _,v in ipairs(LP.PlayerGui:GetDescendants())do if v:IsA("TextButton")then local t=v.Text:lower() if t:match("lobby") or t:match("leave")then v.MouseButton1Click:Fire() break end end end end)end
local function collectC() pcall(function()local r=rt() if not r then return end for _,v in ipairs(WS:GetDescendants())do if v:IsA("BasePart")then local n=v.Name:lower() if n:match("coin") or n:match("gem") or n:match("pickup")then if(v.Position-r.Position).Magnitude<60 then tp(CFrame.new(v.Position+Vector3.new(0,3,0))) task.wait(0.05)end end end end end)end
local function spinC() pcall(function()fra({"Spin","SpinCrate","OpenCrate"}) for _,v in ipairs(LP.PlayerGui:GetDescendants())do if v:IsA("TextButton")then local t=v.Text:lower() if t:match("spin") or t:match("open")then v.MouseButton1Click:Fire() return end end end end)end
local function protect() pcall(function()
 local r=rt() local h=hm() if not r or not h then return end if h.Health/h.MaxHealth>0.3 then return end
 local best,bd=nil,0
 for _,off in ipairs({Vector3.new(30,0,0),Vector3.new(-30,0,0),Vector3.new(0,0,30),Vector3.new(0,0,-30),Vector3.new(22,0,22),Vector3.new(-22,0,-22)})do
  local pos=r.Position+off local mn=math.huge
  for _,e in ipairs(G.enemies)do pcall(function()local ec=e.Character if not ec then return end local eh=ec:FindFirstChild("HumanoidRootPart") if not eh then return end mn=math.min(mn,(pos-eh.Position).Magnitude)end)end
  if mn>bd then bd=mn best=pos end
 end
 if best then tp(CFrame.new(best)) N("Streak Protect","Dodged! Streak:"..G.streak)end
end)end

local lastAfk=tick()
RUN.Heartbeat:Connect(function()
 if G.afk and tick()-lastAfk>55 then lastAfk=tick() pcall(function()local h=hm() if h then h.Jump=true end end)end
 if G.spro then protect()end
end)

task.spawn(function()
 local ls=LP:WaitForChild("leaderstats",15) if not ls then return end
 for _,v in ipairs(ls:GetChildren())do if v:IsA("IntValue") or v:IsA("NumberValue")then v.Changed:Connect(function(val)
  local n=v.Name:lower()
  if n:match("kill")then G.kills=val end
  if n:match("win") and val>G.wins then G.wins=val G.streak=G.streak+1 if G.streak>G.best then G.best=G.streak end N("Win! 🏆","Streak:"..G.streak.." Best:"..G.best)end
  if(n:match("loss") or n:match("death")) and G.streak>0 then local prev=G.streak G.streak=0 G.losses=G.losses+1 if G.sreg then N("Streak Lost","Was "..prev.." — re-queuing…") task.spawn(function()task.wait(2)joinQ()end)end end
  if n:match("coin") or n:match("cash")then G.coins=val end
 end)end end
end)

LP.CharacterAdded:Connect(function(c)
 task.wait(1.5) local h=c:FindFirstChildOfClass("Humanoid") if not h then return end
 h.WalkSpeed=G.ws h.JumpPower=G.jp
 if G.fly then task.wait(0.5) startFly()end
 h.Died:Connect(function()if G.aresp then task.wait(0.4) pcall(function()LP:LoadCharacter()end)end end)
end)

local TM={q=0,a=0,v=0,c=0,s=0}
RUN.Heartbeat:Connect(function()
 local now=tick()
 if G.aq   and now-TM.q>8        then TM.q=now task.spawn(joinQ)end
 if G.aac  and now-TM.a>2        then TM.a=now acceptM()end
 if G.avt  and now-TM.v>3        then TM.v=now voteM()end
 if G.acol and now-TM.c>2        then TM.c=now task.spawn(collectC)end
 if G.aspin and now-TM.s>G.spd2  then TM.s=now spinC()end
 if G.arc  then pcall(function()for _,v in ipairs(LP.PlayerGui:GetDescendants())do if v:IsA("TextButton")then local t=v.Text:lower() if t:match("lobby") or t:match("return")then v.MouseButton1Click:Fire()end end end end)end
end)

-- BUILD TABS
local tH,aH=mkTab("🏠","Home")
local tC,_ =mkTab("⚔️","Combat")
local tF,_ =mkTab("🌾","Farm")
local tS,_ =mkTab("📈","Streak")
local tM,_ =mkTab("✈️","Move")
local tQ,_ =mkTab("🔧","QoL")

-- HOME
local sb=card(tH,"Session Stats","Kills:0  Wins:0  Losses:0  Streak:0  Best:0",Color3.fromRGB(100,140,255))
task.spawn(function()while true do task.wait(3) pcall(function()sb.Text=("Kills:%d  Wins:%d  Losses:%d  Streak:%d  Best:%d  Coins:%d"):format(G.kills,G.wins,G.losses,G.streak,G.best,G.coins)end)end end)
card(tH,"How to use","Tap any tab on the left. Drag the header to move the window. Tap ━ to minimise.",AC)
aH()

-- COMBAT
sect(tC,"Aimbot")
tog(tC,"Auto Shoot","Fires at nearest match enemy.",false,function(v)G.shoot=v if v then stShoot()end end)
sld(tC,"Shoot Distance",50,800,300,10,function(v)G.sdist=v end)
sld(tC,"Shoot Cooldown (s)",0.5,10,2.5,0.5,function(v)G.scd=v end)
tog(tC,"Auto Knife","Throws knife at nearest enemy.",false,function(v)G.knife=v if v then stKnife()end end)
sld(tC,"Knife Distance",20,400,300,10,function(v)G.kdist=v end)
sld(tC,"Knife Cooldown (s)",0.5,8,2,0.5,function(v)G.kcd=v end)
sect(tC,"Misc")
tog(tC,"Trigger Bot","Auto-shoots when crosshair is over enemy.",false,function(v)G.tbot=v end)
tog(tC,"Hitbox Expander","Enlarges enemy hitboxes.",false,function(v)G.hbox=v if not v then clrHB()end end)
sld(tC,"Hitbox Size",5,80,13,1,function(v)G.hsize=v end)
tog(tC,"No Gun Cooldown","Zeroes weapon cooldowns every frame.",false,function(v)G.nocd=v end)

-- FARM
sect(tF,"Auto")
tog(tF,"All-in-One","Enables all farm options.",false,function(v)G.aq=v G.aac=v G.avt=v G.acol=v G.arc=v N("Farm",v and "ON" or "OFF")end)
tog(tF,"Auto Queue","",false,function(v)G.aq=v end)
tog(tF,"Auto Accept","",false,function(v)G.aac=v end)
tog(tF,"Auto Vote","",false,function(v)G.avt=v end)
tog(tF,"Auto Return to Lobby","",false,function(v)G.arc=v end)
tog(tF,"Auto Collect Pickups","",false,function(v)G.acol=v end)
tog(tF,"Auto Spin Crates","",false,function(v)G.aspin=v end)
dd(tF,"Queue Mode",{"1v1","2v2","3v3","4v4"},function(v)G.qmode=v end)
sect(tF,"Manual")
btn(tF,"Join Queue Now","",function()joinQ() N("Queue","Fired!")end)
btn(tF,"Accept Match Now","",function()acceptM()end)
btn(tF,"Vote Map Now","",function()voteM()end)
btn(tF,"Return to Lobby","",function()lobbyM()end)
btn(tF,"Collect Pickups Now","",function()task.spawn(collectC)end)
btn(tF,"Spin Crate Now","",function()spinC()end)

-- STREAK
sect(tS,"Streak")
tog(tS,"Streak Regain","Auto-queues after losing streak.",false,function(v)G.sreg=v end)
tog(tS,"Streak Protect","Teleports away when HP < 30%.",false,function(v)G.spro=v end)
btn(tS,"Force Queue Now","",function()task.spawn(joinQ) N("Queue","Forcing queue!")end)
card(tS,"Streak Protect","Watches HP every frame. Under 30% it teleports you to the safest position from all enemies.",AC)

-- MOVE
sect(tM,"Fly")
tog(tM,"Fly","WASD=dir  Space=up  Shift=down",false,function(v)if v then startFly()else stopFly()end end)
sld(tM,"Fly Speed",10,400,80,5,function(v)G.spd=v end)
sect(tM,"Ground")
tog(tM,"Noclip","",false,function(v)G.noclip=v end)
sld(tM,"Walk Speed",16,300,16,1,function(v)G.ws=v local h=hm() if h then h.WalkSpeed=v end end)
sld(tM,"Jump Power",50,300,50,5,function(v)G.jp=v local h=hm() if h then h.JumpPower=v end end)
btn(tM,"Teleport to Spawn","",function()pcall(function()local sp=WS:FindFirstChildOfClass("SpawnLocation") if sp then tp(sp.CFrame+Vector3.new(0,5,0)) N("Teleport","Done!")end end)end)

-- QOL
sect(tQ,"QoL")
tog(tQ,"Anti-AFK","Jumps every 55s.",true,function(v)G.afk=v end)
tog(tQ,"Auto Respawn","",false,function(v)G.aresp=v end)
tog(tQ,"FPS Boost","Removes shadows, particles, effects.",false,function(v)
 pcall(function()LIG.GlobalShadows=not v
  for _,x in ipairs(LIG:GetChildren())do if x:IsA("PostEffect") or x:IsA("Atmosphere")then pcall(function()x.Enabled=not v end)end end
  for _,x in ipairs(WS:GetDescendants())do if x:IsA("ParticleEmitter") or x:IsA("Fire") or x:IsA("Smoke")then pcall(function()x.Enabled=not v end)end end
 end) N("FPS Boost",v and "ON" or "OFF")
end)
btn(tQ,"Dump Remotes to Console","",function()pcall(function()for _,v in ipairs(RS:GetDescendants())do if v:IsA("RemoteEvent") or v:IsA("RemoteFunction")then print("["..v.ClassName.."] "..v:GetFullName())end end end) N("Remotes","Printed!")end)

N("Phantom X","Loaded!  Drag header to move.",5)
