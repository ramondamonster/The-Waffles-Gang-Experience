-- Waffle Studio: simplified, centralized access to Rain's original modules.
-- Designed as a controller; the existing themed windows and gameplay code remain.
local WG=_G.WafflesGang
local S={name='Waffle Studio',current='HOME',advanced=false,pages={},tabs={},dynamic={},lastStyle=nil}
WG.studio=S
WG.modules[#WG.modules+1]=S
local tabs={
  {'HOME','Start Here'}, {'GROUP','Party & Raid'}, {'AURAS','Buffs & Debuffs'},
  {'THREAT','Threat Watch'}, {'QUESTS','Quests & Maps'}, {'GUILD','Guild & Events'},
  {'PANTRY','Pantry & Gear'}, {'PROFILES','Profiles & Layout'}, {'STYLES','UI Styles'},
  {'ADDONS','Other Addons'},
}
local function clamp(n,a,b)return math.max(a,math.min(b,n))end
local studioArt='Interface\\AddOns\\WafflesGang\\Media\\StudioArt\\'
local function addPageIllustration(page,key)
  if key=='DIRECTORY' or key=='TACTICALINTEL' or key=='TACTICALLOOK' then return nil end
  local art=page:CreateTexture(nil,'ARTWORK')
  art:SetTexture(studioArt..key)
  art:SetSize(146,73)
  art:SetPoint('TOPRIGHT',page,'TOPRIGHT',-1,2)
  WG.surfaces[#WG.surfaces+1]={repaint=function()
    art:SetShown(WG:StyleName()~='Tactical')
    art:SetAlpha(WG:StyleName()=='Modern' and .74 or .94)
  end}
  return art
end
local function safeCall(fn)
  if WG.db then fn();WG:Refresh() end
end
function S:Group()
  for _,m in ipairs(WG.modules) do if m.PartySettings and m.ApplyPartyLayout then return m,m:PartySettings() end end
  return nil,{}
end
function S:Auras()
  return WG.auras,WG.auras and WG.auras:Options(self.auraGroup or 'party') or {}
end
function S:Threat() return WG.threatWatch,WG.threatWatch and WG.threatWatch:Settings(self.threatMeter or 1) or {} end
function S:Quest() return WG.quests,WG.quests and WG.quests:Options() or {} end
function S:MakePage(key,title,desc)
  local f=CreateFrame('Frame',nil,self.window)
  f:SetPoint('TOPLEFT',self.window,'TOPLEFT',217,-105)
  f:SetSize(584,540);f:Hide();self.pages[key]=f
  WG:Text(f,title,4,-2,19,'accent',410)
  local subtitle=WG:Text(f,desc,4,-40,10,'text',418)
  subtitle:SetWordWrap(false)
  addPageIllustration(f,key)
  -- Tactical has an actual live visual-theme identity instead of a fixed black
  -- placeholder, including on Addons and every other editor page.
  local signature=WG:Text(f,'',422,-8,10,'accent',139)
  signature:SetJustifyH('RIGHT')
  WG.surfaces[#WG.surfaces+1]={repaint=function()
    signature:SetShown(WG:StyleName()=='Tactical')
    signature:SetText(string.upper(WG:ThemeName())..' / '..string.upper(WG:CurrentPaletteName()))
  end}
  WG:Divider(f,-61,566,3)
  return f
end
function S:Label(p,text,x,y,size,color,width)
  return WG:Text(p,text,x,y,size or 11,color or 'text',width)
end
function S:Button(p,label,x,y,w,h,fn,caption,advanced)
  local b=WG:Button(p,label,x,y,w,h,function()
    if fn then safeCall(fn) end
  end)
  self.dynamic[#self.dynamic+1]={button=b,caption=caption,advanced=advanced}
  return b
end
function S:Switch(p,label,x,y,w,fn,on,advanced)
  return self:Button(p,label,x,y,w,35,fn,function()
    return label..': '..(on() and 'ON' or 'OFF')
  end,advanced)
end
function S:Check(p,label,x,y,w,get,set,advanced)
  local btn=CreateFrame('Button',nil,p)
  btn:SetSize(w,29)
  btn:SetPoint('TOPLEFT',p,'TOPLEFT',x,y)
  local border=btn:CreateTexture(nil,'BACKGROUND')
  border:SetPoint('LEFT',btn,'LEFT',1,0)
  border:SetSize(19,19)
  local fill=btn:CreateTexture(nil,'ARTWORK')
  fill:SetPoint('CENTER',border,'CENTER',0,0)
  fill:SetSize(13,13)
  local labelText=WG:Text(btn,label,29,-5,11,'text',w-34)
  btn:SetScript('OnEnter',function()labelText:SetTextColor(1,1,1)end)
  btn:SetScript('OnLeave',function()
    local c=WG:Color('text');labelText:SetTextColor(c[1],c[2],c[3])
  end)
  btn:SetScript('OnClick',function()
    if not WG.db then return end
    safeCall(function()set(not get())end)
    S:Refresh()
  end)
  self.checkControls=self.checkControls or {}
  self.checkControls[#self.checkControls+1]={button=btn,border=border,fill=fill,get=get,advanced=advanced}
  return btn
end
function S:Open(name)WG:Open(name)end
function S:BuildHome()
  local p=self:MakePage('HOME','WELCOME TO WAFFLE STUDIO','Choose a tool below. All your existing windows, artwork and layouts are preserved.')
  S:Label(p,'ONE CLICK TO GET STARTED',5,-83,13,'accent')
  local links={
    {'Party frames','GROUP','Change size, roles and aggro alerts'},
    {'Buffs & debuffs','AURAS','Configure aura displays by frame'},
    {'Threat meter','THREAT','Combat display and warning options'},
    {'Waffle quests','QUESTS','Questie connection and quest tracker'},
    {'Guild & events','GUILD','Roster and Discord events'},
    {'Bags & equipment','PANTRY','Inventory, gear and shortcuts'},
    {'Profiles & layout','PROFILES','Save configurations; move your HUD'},
    {'Four UI styles','STYLES','Modern, Tactical, Adventure or Rain Classic'},
  }
  for i,e in ipairs(links) do
    local x=5+((i-1)%2)*289;local y=-110-math.floor((i-1)/2)*79
    self:Button(p,e[1],x,y,273,41,function()
      S:Select(e[2])
    end)
    S:Label(p,e[3],x+4,y-47,10,'text',270)
  end
  S:Label(p,'TIP: Search every editor in ALL DEEP CONTROLS. Use Advanced for precision settings.',5,-475,11,'accent',560)
  self:Button(p,'ORIGINAL DASHBOARD',5,-504,271,32,function()S:Open('hub')end)
  self:Button(p,'ALL DEEP CONTROLS',294,-504,266,32,function()S:Select('DIRECTORY')end)
end
function S:Preset(name)
  local _,g=self:Group()
  if name=='TANK' then g.roles=true;g.levels=true;g.status=true;g.threat=true;g.scale=1;g.spacing=6;g.growth='VERTICAL'
  elseif name=='HEALER' then g.roles=true;g.levels=true;g.status=true;g.threat=true;g.scale=1.12;g.spacing=7;g.growth='VERTICAL'
  elseif name=='DPS' then g.roles=true;g.levels=true;g.status=true;g.threat=false;g.scale=.95;g.spacing=5;g.growth='VERTICAL'
  else g.roles=false;g.levels=false;g.status=false;g.threat=false;g.scale=.78;g.spacing=3;g.growth='VERTICAL' end
  WG.db.features.partyframes=true
  if WG.auras then
    local o=WG.auras:Options('party')
    o.enabled=name~='MINIMAL';o.debuffs=name~='MINIMAL';o.buffs=name=='HEALER'
    o.size=name=='HEALER' and 22 or 18
  end
end
function S:BuildGroup()
  local p=self:MakePage('GROUP','PARTY FRAME STUDIO','Start with a preset, then change only the details you care about.')
  S:Label(p,'START WITH A PLAYSTYLE',5,-84,12,'accent')
  for i,name in ipairs({'TANK','HEALER','DPS','MINIMAL'}) do
    self:Button(p,name,5+(i-1)*144,-107,137,37,function()S:Preset(name)end)
  end
  S:Label(p,'WHAT SHOULD YOUR PARTY FRAMES SHOW?',5,-159,12,'accent')
  local function flip(k)local _,o=S:Group();o[k]=not o[k]end
  self:Switch(p,'Names + levels',5,-187,184,function()flip('levels')end,function()local _,o=S:Group();return o.levels end)
  self:Switch(p,'Role icons',199,-187,181,function()flip('roles')end,function()local _,o=S:Group();return o.roles end)
  self:Switch(p,'Group status',390,-187,181,function()flip('status')end,function()local _,o=S:Group();return o.status end)
  self:Switch(p,'Aggro warning',5,-228,184,function()flip('threat')end,function()local _,o=S:Group();return o.threat end)
  self:Button(p,'DRAG FRAMES',199,-228,181,35,function()WG:ToggleEditMode()end)
  self:Button(p,'MORE FRAME OPTIONS',390,-228,181,35,function()S:Open('frames')end)
  S:Label(p,'ADVANCED LAYOUT',5,-277,12,'accent')
  self:Button(p,'SIZE -',5,-303,136,33,function()local _,o=S:Group();o.scale=clamp((o.scale or 1)-.05,.65,1.4)end,function()local _,o=S:Group();return 'SIZE - ('..math.floor((o.scale or 1)*100+.5)..'%)'end,true)
  self:Button(p,'SIZE +',150,-303,136,33,function()local _,o=S:Group();o.scale=clamp((o.scale or 1)+.05,.65,1.4)end,nil,true)
  self:Button(p,'GAP -',295,-303,133,33,function()local _,o=S:Group();o.spacing=clamp((o.spacing or 5)-1,1,20)end,function()local _,o=S:Group();return 'GAP - ('..o.spacing..')'end,true)
  self:Button(p,'GAP +',437,-303,134,33,function()local _,o=S:Group();o.spacing=clamp((o.spacing or 5)+1,1,20)end,nil,true)
  self:Button(p,'LAYOUT DIRECTION',5,-343,280,33,function()local _,o=S:Group();o.growth=o.growth=='VERTICAL' and 'HORIZONTAL' or 'VERTICAL' end,function()local _,o=S:Group();return 'DIRECTION: '..(o.growth or 'VERTICAL')end,true)
  self:Button(p,'AURA DETAILS',295,-343,275,33,function()S:Select('AURAS')end,nil,true)
  S:Label(p,'LIVE SAMPLE (NOT ACTUAL PARTY MEMBERS)',5,-388,11,'accent')
  self.preview={}
  for i,name in ipairs({'Deputy Waffles','Rain','Party Member'}) do
    local line=CreateFrame('Frame',nil,p);line:SetSize(558,38);line:SetPoint('TOPLEFT',p,'TOPLEFT',5,-412-(i-1)*41)
    WG:Surface(line,'panel','edge')
    local t=WG:Text(line,'',9,-7,12,'text',535)
    local hp=line:CreateTexture(nil,'ARTWORK')
    hp:SetPoint('BOTTOMLEFT',line,'BOTTOMLEFT',8,5);hp:SetSize((i==1 and 480 or (i==2 and 385 or 425)),5)
    local c=WG:Color('accent');hp:SetColorTexture(c[1],c[2],c[3],.9)
    self.preview[i]=t
  end
end
function S:BuildAuras()
  local p=self:MakePage('AURAS','BUFFS & DEBUFFS','Choose a frame, toggle icons and customize the layout without complex filters.')
  S:Label(p,'WHICH FRAMES?',5,-82,12,'accent')
  local names={'party','player','target','focus','raid'}
  for i,name in ipairs(names) do
    self:Button(p,name:upper(),5+(i-1)*114,-106,109,36,function()S.auraGroup=name;if WG.auras then WG.auras.selected=name end end,
      function()return (S.auraGroup==name and '[ ' or '')..name:upper()..(S.auraGroup==name and ' ]' or '')end)
  end
  local function auraChange(k) local _,o=S:Auras();o[k]=not o[k]end
  self:Switch(p,'Show auras',5,-170,181,function()auraChange('enabled')end,function()local _,o=S:Auras();return o.enabled end)
  self:Switch(p,'Buffs',199,-170,181,function()auraChange('buffs')end,function()local _,o=S:Auras();return o.buffs end)
  self:Switch(p,'Debuffs',393,-170,177,function()auraChange('debuffs')end,function()local _,o=S:Auras();return o.debuffs end)
  self:Button(p,'SMALL ICONS',5,-220,181,37,function()local _,o=S:Auras();o.size=16 end)
  self:Button(p,'MEDIUM ICONS',199,-220,181,37,function()local _,o=S:Auras();o.size=22 end)
  self:Button(p,'LARGE ICONS',393,-220,177,37,function()local _,o=S:Auras();o.size=28 end)
  self:Button(p,'PLACEMENT',5,-273,273,37,function()local _,o=S:Auras();o.side=o.side=='RIGHT' and 'BOTTOM' or 'RIGHT' end,
    function()local _,o=S:Auras();return 'PLACE ICONS: '..o.side end)
  self:Button(p,'OPEN FULL AURA EDITOR',291,-273,280,37,function()if WG.auras then WG.auras.selected=S.auraGroup end;S:Open('auras')end)
  S:Label(p,'ADVANCED AURA COUNTS',5,-327,12,'accent')
  self:Button(p,'BUFF COUNT -',5,-355,131,34,function()local _,o=S:Auras();o.buffCount=clamp(o.buffCount-1,0,10)end,nil,true)
  self:Button(p,'BUFF COUNT +',146,-355,131,34,function()local _,o=S:Auras();o.buffCount=clamp(o.buffCount+1,0,10)end,nil,true)
  self:Button(p,'DEBUFF COUNT -',290,-355,133,34,function()local _,o=S:Auras();o.debuffCount=clamp(o.debuffCount-1,0,10)end,nil,true)
  self:Button(p,'DEBUFF COUNT +',433,-355,138,34,function()local _,o=S:Auras();o.debuffCount=clamp(o.debuffCount+1,0,10)end,nil,true)
  self.auraInfo=S:Label(p,'',5,-414,12,'accent',561)
  S:Label(p,'Icons appear only when WoW exposes aura data. Raid icons default off.',5,-461,11,'text',565)
  self:Button(p,'OPEN ADVANCED AURA STUDIO',5,-501,557,34,function()if WG.auras then WG.auras.selected=S.auraGroup end;S:Open('auras')end,nil,true)
end
function S:BuildThreat()
  local p=self:MakePage('THREAT','THREAT WATCH','Waffle threat bars now use Tiny Threat numbers and ordering. Native API is optional.')
  self.threatMeter=1
  self:Button(p,'01  THREAT METER',5,-86,273,38,function()S.threatMeter=1 end,
    function()return (S.threatMeter==1 and '[ SELECTED ]  ' or '')..'METER 1' end)
  self:Button(p,'02  THREAT METER',293,-86,273,38,function()S.threatMeter=2 end,
    function()return (S.threatMeter==2 and '[ SELECTED ]  ' or '')..'METER 2' end)
  S:Label(p,'DISPLAY & VISIBILITY',5,-142,12,'accent')
  local function opt(key,value)
    local _,o=S:Threat()
    if key=='unlocked' and value and WG:Protected() then
      WG:Say('Unlock your threat meter outside combat.');return
    end
    o[key]=value
  end
  local function check(label,x,y,key,advanced)
    return self:Check(p,label,x,y,265,
      function()local _,o=S:Threat();return o[key] end,
      function(v)opt(key,v)end,advanced)
  end
  check('Enable this meter',5,-166,'enabled')
  check('Combat only',294,-166,'showOnlyCombat')
  check('Auto-fit to active players',5,-202,'autoFit')
  check('Hide when empty',294,-202,'hideEmpty')
  check('Show my character',5,-238,'showPlayer')
  check('Class-colored bars',294,-238,'classColors')
  check('Include pets',5,-274,'showPets',true)
  check('Unlocked for drag + resize',294,-274,'unlocked')
  S:Label(p,'WHAT TO TRACK',5,-319,12,'accent')
  self:Button(p,'TARGET / FOCUS',5,-341,269,33,function()
    if WG.threatCompanion and WG.threatCompanion:UsingTinyThreat() then
      WG:Say('Details is the active source. Set target/focus inside Tiny Threat.');return
    end
    local _,o=S:Threat();o.source=o.source=='TARGET' and 'FOCUS' or 'TARGET'
  end,function()
    if WG.threatCompanion and WG.threatCompanion:UsingTinyThreat() then return 'TARGET: CONTROLLED BY DETAILS' end
    local _,o=S:Threat();return 'NATIVE TRACKING: '..o.source
  end)
  self:Button(p,'NATIVE MODE: RELATIVE / ABSOLUTE',295,-341,270,33,function()
    if WG.threatCompanion and WG.threatCompanion:UsingTinyThreat() then
      WG:Say('Details is the active source. Set relative/absolute inside Tiny Threat.');return
    end
    local _,o=S:Threat();o.mode=o.mode=='RELATIVE' and 'ABSOLUTE' or 'RELATIVE'
  end,function()
    if WG.threatCompanion and WG.threatCompanion:UsingTinyThreat() then return 'THREAT MODE: DETAILS' end
    local _,o=S:Threat();return 'NATIVE MODE: '..o.mode
  end)
  self.threatLiveStatus=S:Label(p,'Checking Tiny Threat data...',5,-385,10,'accent',558)
  S:Label(p,'SIZE & LIMITS',5,-398,12,'accent')
  local defs={
    {'width','Window width',5,-421,268,180,540,5,false,function(v)return math.floor(v+.5)..' px'end},
    {'rows','Maximum players',294,-421,269,1,12,1,false,function(v)return math.floor(v+.5)..' max'end},
    {'rowHeight','Bar height',5,-477,268,14,30,1,true,function(v)return math.floor(v+.5)..' px'end},
    {'speed','Refresh interval',294,-477,269,.2,2,.1,true,function(v)return string.format('%.1f s',v)end},
  }
  self.threatSliders={}
  for _,r in ipairs(defs) do
    local key=r[1]
    local _,o=S:Threat()
    local slider=WG:Slider(p,r[2],r[3],r[4],r[5],r[6],r[7],r[8],o[key] or r[6],function(v)
      local t,opts=S:Threat()
      opts[key]=v
      if t then t:Update(S.threatMeter) end
    end,r[10])
    self.threatSliders[key]={widget=slider,advanced=r[9]}
  end
  self:Button(p,'DETAILS THREAT DATA',5,-535,271,34,function()S:Select('THREATSOURCE')end)
  self:Button(p,'WAFFLE METER DESIGN',295,-535,271,34,function()S:Select('THREATDETAILS')end)
end
function S:BuildThreatDetails()
  local p=self:MakePage('THREATDETAILS','THREAT  /  METER DESIGN',
    'Waffle threat bar styling; Details! Tiny Threat supplies live values when connected.')
  self:Label(p,'ROW PRESENTATION',5,-82,13,'accent')
  local opts={
    {'Show compact player rows','compactRows',5,-115},
    {'Show threat title','showTitle',292,-115},
    {'Show Details amounts + percentages','detailsShowAmounts',5,-151},
    {'Keep my player at top','pinPlayer',292,-151},
    {'Show class-colored bars','classColors',5,-187},
    {'Hide empty meter','hideEmpty',292,-187},
    {'Fit height to members','autoFit',5,-223},
    {'Include pets','showPets',292,-223},
  }
  for _,v in ipairs(opts) do
    self:Check(p,v[1],v[3],v[4],265,
      function()local _,o=S:Threat();return o[v[2]]==true end,
      function(value)local _,o=S:Threat();o[v[2]]=value end)
  end
  self:Label(p,'METER DENSITY',5,-266,13,'accent')
  self.threatDetailsSliders={}
  local sliders={
    {'rowHeight','Row height',5,-296,268,14,30,1,function(n)return math.floor(n)..' px' end},
    {'width','Meter width',294,-296,268,180,540,5,function(n)return math.floor(n)..' px' end},
    {'frameOpacity','Backdrop opacity',5,-371,268,.1,1,.05,function(n)return math.floor(n*100)..'%' end},
    {'barOpacity','Bar opacity',294,-371,268,.2,1,.05,function(n)return math.floor(n*100)..'%' end},
  }
  for _,v in ipairs(sliders) do
    local key=v[1]
    local _,o=S:Threat()
    local ctl=WG:Slider(p,v[2],v[3],v[4],v[5],v[6],v[7],v[8],o[key] or v[6],function(n)
      local t,settings=S:Threat();settings[key]=n
      if t then t:Update(S.threatMeter) end
    end,v[9])
    self.threatDetailsSliders[key]=ctl
  end
  self:Button(p,'PREVIEW PLAYER ROWS',5,-462,273,38,function()
    local t=WG.threatWatch
    if t and t.meters[S.threatMeter] then
      local m=t.meters[S.threatMeter];m.preview=not m.preview;t:Update(S.threatMeter)
    end
  end,function()
    local t=WG.threatWatch;local m=t and t.meters[S.threatMeter]
    return m and m.preview and 'HIDE PREVIEW ROWS' or 'SHOW PLAYER ROW PREVIEW'
  end)
  self:Button(p,'BACK TO THREAT METERS',294,-462,270,38,function()S:Select('THREAT')end)
  self:Button(p,'TINY THREAT SOURCE SETTINGS',5,-517,556,33,function()S:Select('THREATSOURCE')end)
end
-- Directly controls whether real Tiny Threat, or our independent fallback, is shown.
function S:BuildThreatSource()
  local p=self:MakePage('THREATSOURCE','THREAT / DATA & APPEARANCE',
    'ForeverUI bars read Tiny Threat live numbers. Details! remains the calculation engine.')
  self:Label(p,'CHOOSE WAFFLES THREAT DATA',5,-84,13,'accent')
  local options={{'AUTO: DETAILS FIRST','auto'},{'DETAILS DATA ONLY','tiny'},{'NATIVE API','waffle'}}
  for i,item in ipairs(options) do
    self:Button(p,item[1],5+(i-1)*190,-116,177,39,function()
      if WG.threatCompanion then WG.threatCompanion:Settings().source=item[2] end
    end,function()
      local v=WG.threatCompanion and WG.threatCompanion:Settings().source or 'auto'
      return (v==item[2] and '[X] ' or '')..item[1]
    end)
  end
  self.threatSourceInfo=self:Label(p,'',5,-181,11,'accent',561)
  self:Label(p,'AUTO uses Tiny Threat when installed; never silently falls back if it is loaded but broken.',5,-216,11,'text',559)
  self:Label(p,'DETAILS DATA ONLY never invents values when Tiny Threat is not running.',5,-245,11,'text',559)
  self:Label(p,'OPTIONAL DETAILS WINDOW BACKING',5,-296,13,'accent')
  self:Check(p,'Theme behind Tiny Threat',5,-329,272,
    function()return WG.threatCompanion and WG.threatCompanion:Settings().skin end,
    function(v)WG.threatCompanion:Settings().skin=v end)
  self:Check(p,'Color-matched side accent',294,-329,271,
    function()return WG.threatCompanion and WG.threatCompanion:Settings().accentLine end,
    function(v)WG.threatCompanion:Settings().accentLine=v end)
  local s=WG.threatCompanion and WG.threatCompanion:Settings() or {opacity=.26}
  self.threatSourceOpacity=WG:Slider(p,'Background opacity',5,-393,562,0,1,.05,s.opacity,function(v)
    if WG.threatCompanion then WG.threatCompanion:Settings().opacity=v;WG.threatCompanion:Refresh() end
  end,function(n)return math.floor(n*100+.5)..'%'end)
  self:Button(p,'OPEN TINY THREAT OPTIONS',5,-460,271,34,function()
    local companion=WG.threatCompanion
    local plugin=companion and companion:Plugin()
    if plugin and type(plugin.OpenOptionsPanel)=='function' then
      plugin:OpenOptionsPanel()
    else WG:Say('Open Details! and enable Tiny Threat as a plugin first.') end
  end)
  self:Button(p,'NATIVE METER SETTINGS',295,-460,271,34,function()S:Select('THREAT')end)
  self:Label(p,'Keep Details! Tiny Threat enabled. Both Waffle meters share the target selected in Tiny Threat.',5,-515,10,'text',560)
end

function S:BuildQuests()
  local p=self:MakePage('QUESTS','QUESTS & TRACKER OPTIONS','Questie is the primary quest list. These controls customize the Waffle fallback tracker.')
  self.questInfo=S:Label(p,'QUESTIE: CHECKING...',5,-84,11,'accent',272)
  self.openMapStatus=S:Label(p,'OPENMAP: CHECKING...',294,-84,10,'text',265)
  self:Button(p,'QUEST JOURNAL',5,-114,178,37,function()S:Open('quests')end)
  self:Button(p,'QUESTIE SKIN / SOURCE',193,-114,187,37,function()S:Select('QUESTIESKIN')end)
  self:Button(p,'MOVE WAFFLE TRACKER',392,-114,175,37,function()WG:ToggleEditMode()end)
  S:Label(p,'WAFFLE FALLBACK DISPLAY',5,-161,12,'accent')
  local function configure(k,v)
    local q,o=S:Quest()
    if not q then return end
    o[k]=v
    if q.UpdateTracker then q:UpdateTracker() end
  end
  local function isSet(k) local _,o=S:Quest();return o[k]==true end
  self:Check(p,'Enable Waffle fallback',5,-188,276,function()return isSet('tracker')end,
    function(v)configure('tracker',v)end)
  self:Check(p,'Show quest levels',292,-188,268,function()return isSet('showLevels')end,
    function(v)configure('showLevels',v)end)
  self:Check(p,'Group quests by zone',5,-221,276,function()return isSet('groupZones')end,
    function(v)configure('groupZones',v)end)
  self:Check(p,'Objective progress bars',292,-221,268,function()return isSet('showBars')end,
    function(v)configure('showBars',v)end)
  self:Check(p,'Only watched quests',5,-254,276,function()return isSet('watchedOnly')end,
    function(v)configure('watchedOnly',v)end)
  self:Check(p,'Show completed quests',292,-254,268,function()return isSet('showCompleted')end,
    function(v)configure('showCompleted',v)end)
  S:Label(p,'QUEST PRIORITY',5,-290,12,'accent')
  self:Check(p,'Campaign quests first',5,-314,268,
    function()return isSet('campaignFirst')end,function(v)configure('campaignFirst',v)end)
  self:Check(p,'Ready quests in own group',292,-314,268,
    function()return isSet('readyLast')end,function(v)configure('readyLast',v)end)
  S:Label(p,'APPEARANCE',5,-354,12,'accent')
  local q,o=self:Quest()
  if q and q.TrackerOptions then o=q:TrackerOptions() end
  local function slider(label,x,y,key,lo,hi,step,format)
    local ctl=WG:Slider(p,label,x,y,268,lo,hi,step,o[key] or lo,function(v)
      configure(key,v)
    end,format)
    self.questSliders=self.questSliders or {}
    self.questSliders[#self.questSliders+1]={key=key,widget=ctl}
  end
  slider('Tracker width',5,-375,'width',250,480,10,function(v)return math.floor(v)..' px' end)
  slider('Background opacity',294,-375,'opacity',0,.95,.05,function(v)return math.floor(v*100+.5)..'%' end)
  slider('Maximum visible quests',5,-421,'maxQuests',1,20,1,function(v)return tostring(math.floor(v))end)
  slider('Text size',294,-421,'fontSize',9,16,1,function(v)return math.floor(v)..' px'end)
  self:Check(p,'Auto-fit tracker height',5,-449,269,
    function()return isSet('autoHeight')end,function(v)configure('autoHeight',v)end)
  self:Check(p,'Show Waffle quest arrow',292,-449,269,
    function()return isSet('showArrow')end,function(v)
      configure('showArrow',v)
      if WG.quests and WG.quests.UpdateArrow then WG.quests:UpdateArrow() end
    end)
  S:Label(p,'MAPS & NAVIGATION',5,-487,12,'accent')
  self:Button(p,'WORLD MAP',5,-505,274,30,function()
    if ToggleWorldMap then ToggleWorldMap() end
  end)
  self:Button(p,'CENTER OPENMAP',291,-505,274,30,function()
    if WG.openMap then WG.openMap:CenterOnPlayer()end
  end)
end
-- No Questie code is copied here: all controls affect our visual backing or
-- tracker selection only. Questie's own quest-list settings stay in Questie.
function S:BuildQuestieSkin()
  local p=self:MakePage('QUESTIESKIN','QUESTIE / FOREVERUI COMPANION',
    'Questie owns the quest list. ForeverUI provides the optional styling behind it.')
  self.questieSkinInfo=S:Label(p,'Checking Questie...',5,-89,11,'accent',552)
  S:Label(p,'TRACKER SOURCE',5,-119,12,'accent')
  local function selectSource(mode)
    local q=WG.quests
    if not q then return end
    local o=q:Options()
    o.trackerSource=mode
    if mode=='waffle' then o.tracker=true end
    if q.UpdateTracker then q:UpdateTracker() end
    if WG.questieSkin then WG.questieSkin:Refresh() end
  end
  local function sourceCaption(mode,title)
    local o=WG.quests and WG.quests:Options() or {}
    return ((o.trackerSource or 'auto')==mode and '[X] ' or '[ ] ')..title
  end
  S:Button(p,'',5,-141,177,38,function()selectSource('auto')end,function()return sourceCaption('auto','AUTO')end)
  S:Button(p,'',194,-141,177,38,function()selectSource('questie')end,function()return sourceCaption('questie','QUESTIE')end)
  S:Button(p,'',383,-141,181,38,function()selectSource('waffle')end,function()return sourceCaption('waffle','WAFFLE')end)
  S:Label(p,'Auto uses Questie when its tracker is enabled, otherwise falls back to your Waffle tracker.',5,-194,10,'text',555)
  S:Label(p,'FOREVERUI BACKING',5,-229,12,'accent')
  local function opts()return WG.questieSkin and WG.questieSkin:Settings() or {} end
  local function change(k,v)
    local o=opts();o[k]=v
    if WG.questieSkin then WG.questieSkin:Refresh() end
  end
  S:Check(p,'Style Questie tracker',5,-250,268,
    function()return opts().enabled end,function(v)change('enabled',v)end)
  S:Check(p,'Show theme accent',294,-250,269,
    function()return opts().accentLine end,function(v)change('accentLine',v)end)
  S:Label(p,'BACKING STYLE',5,-301,11,'accent')
  for i,entry in ipairs({{'minimal','MINIMAL'}, {'panel','PANEL'}, {'clear','CLEAR'}}) do
    local mode,label=entry[1],entry[2]
    S:Button(p,'',5+(i-1)*189,-320,177,34,function()change('mode',mode)end,
      function()return (opts().mode==mode and '[X] ' or '[ ] ')..label end)
  end
  local opacity=WG:Slider(p,'Backdrop opacity',5,-381,270,0,1,.05,opts().opacity or .28,function(v)change('opacity',v)end,
    function(v)return math.floor(v*100+.5)..'%'end)
  local padding=WG:Slider(p,'Panel padding',294,-381,268,0,22,1,opts().padding or 8,function(v)change('padding',v)end,
    function(v)return math.floor(v)..' px'end)
  self.questieSkinSliders={opacity=opacity,padding=padding}
  S:Label(p,'Keep Questie installed and its tracker enabled. Move/resize it using Questie itself.',5,-443,10,'text',557)
  S:Label(p,'For a clean result, turn OFF Questie\'s own backdrop in /questie. No Questie setting is overwritten.',5,-463,10,'text',557)
  S:Button(p,'QUEST SETTINGS',5,-495,267,35,function()S:Select('QUESTS')end)
  S:Button(p,'ADDON CONNECTIONS',294,-495,268,35,function()S:Select('ADDONS')end)
end

function S:BuildGuild()
  local p=self:MakePage('GUILD','WAFFLES GANG COMMUNITY','Your actual WoW guild roster and your Discord event feed in one place.')
  local links={{'GUILD ROSTER','guild'},{'DISCORD EVENTS','guildboard'},{'RECRUITMENT','recruitment'},
    {'GUILD PROFESSIONS','professions'},{'PARTY MANAGER','party'},{'GROUP TOOLS','group'}}
  for i,row in ipairs(links) do
    self:Button(p,row[1],5+((i-1)%2)*288,-101-math.floor((i-1)/2)*67,274,49,function()S:Open(row[2])end)
  end
  S:Label(p,'EVENTS FLOW',5,-334,12,'accent')
  S:Label(p,'Discord Scheduled Events -> deputywaffles.com -> PC sync -> WoW',5,-374,11,'text',566)
  S:Label(p,'Event creation stays in Discord. Guildmates can request synced events in-game.',5,-410,11,'text',562)
  S:Label(p,'The companion must be run again to fetch changed events from the website.',5,-448,11,'text',559)
  self:Button(p,'OPEN EVENTS BOARD',5,-492,556,38,function()S:Open('guildboard')end)
end
function S:BuildPantry()
  local p=self:MakePage('PANTRY','WAFFLE PANTRY & GEAR','Your original Pantry, equipped-bag strip and inventory tools remain unchanged.')
  self:Button(p,'OPEN WAFFLE PANTRY',5,-97,273,45,function()S:Open('bags')end)
  self:Button(p,'GEAR ADVISOR',291,-97,275,45,function()S:Open('gear')end)
  self:Button(p,'REPAIR BAG SHORTCUT (B)',5,-163,563,38,function()
    WG.db.bagKeyOverride=true
    if WG.pantry and WG.pantry.Binding then WG.pantry:Binding()end
  end)
  local function feature(k)WG.db.features[k]=not WG.db.features[k]end
  self:Switch(p,'Search items',5,-224,272,function()feature('bagsearch')end,function()return WG:Enabled('bagsearch')end)
  self:Switch(p,'Category filters',291,-224,275,function()feature('bagcategories')end,function()return WG:Enabled('bagcategories')end)
  self:Switch(p,'Item levels',5,-273,272,function()feature('bagitemlevel')end,function()return WG:Enabled('bagitemlevel')end)
  self:Switch(p,'New item markers',291,-273,275,function()feature('bagrecent')end,function()return WG:Enabled('bagrecent')end)
  self:Button(p,'JUNK & AUTOMATION',5,-345,272,40,function()S:Open('automation')end)
  self:Button(p,'REWARD ADVISOR',291,-345,275,40,function()S:Open('rewards')end)
  S:Label(p,'If B opens another bag window, disable competing bag addons first.',5,-425,11,'accent',560)
  S:Label(p,'Use /wg diag to view keybinding and Pantry initialization details.',5,-461,11,'text',556)
end
function S:BuildProfiles()
  local p=self:MakePage('PROFILES','SAVE YOUR SETUP','Different combat, aura and HUD layouts for solo play, groups and raids.')
  local names={'SOLO','GROUP','RAID'}
  for i,name in ipairs(names) do
    local y=-104-(i-1)*82
    S:Label(p,name..' PROFILE',5,y,14,'accent')
    self:Button(p,'SAVE CURRENT',215,y+5,163,37,function()WG:SaveProfile(name)end)
    self:Button(p,'LOAD PROFILE',390,y+5,177,37,function()WG:LoadProfile(name)end)
  end
  S:Label(p,'LAYOUT & THEME',5,-359,12,'accent')
  self:Button(p,'MOVE HUD ELEMENTS',5,-394,273,38,function()WG:ToggleEditMode()end)
  self:Button(p,'FOUR UI STYLES',292,-394,274,38,function()S:Select('STYLES')end)
  self:Button(p,'WINDOW LAYOUT',5,-444,273,38,function()S:Open('layout')end)
  self:Button(p,'THEME COLORS',292,-444,274,38,function()S:Open('appearance')end)
  S:Label(p,'Profiles keep saved frame positions and combat-tool settings.',5,-499,11,'text',553)
end
function S:BuildStyles()
  local p=self:MakePage('STYLES','INTERFACES + THEMES','First choose the interface, then apply any Rain theme and its colorways.')
  S:Label(p,'1  /  INTERFACE DESIGN',5,-83,12,'accent')
  self.styleButtons={}
  for i,style in ipairs({'Classic','Modern','Tactical','Adventure'}) do
    local x=5+(i-1)*143
    self.styleButtons[style]=self:Button(p,style:upper(),x,-108,136,43,
      function() WG:SetUIStyle(style) end,
      function()return (WG:StyleName()==style and '● ' or '')..style:upper()end)
  end
  self.styleDescription=S:Label(p,'',5,-164,11,'text',561)
  self:Button(p,'TACTICAL DECK',194,-477,183,37,function()
    if WG:StyleName()~='Tactical' then WG:SetUIStyle('Tactical') end
    S:Select('TACTICALHUD')
  end)
  S:Label(p,'2  /  RAIN ORIGINAL THEMES',5,-202,12,'accent')
  self.themeChoices={}
  for i,theme in ipairs({'Waffles','Cake','Pie','Pizza','Samurai'}) do
    self.themeChoices[theme]=self:Button(p,theme:upper(),5+(i-1)*114,-229,108,44,
      function()WG:SetTheme(theme)end,
      function()return (WG:ThemeName()==theme and '● ' or '')..theme:upper()end)
  end
  S:Label(p,'3  /  THEME COLORWAYS',5,-299,12,'accent')
  self.colorwayChoices={}
  for i=1,4 do
    local x=5+((i-1)%2)*286
    local y=-329-math.floor((i-1)/2)*58
    self.colorwayChoices[i]=self:Button(p,'',x,y,277,47,function()
      local choice=WG:ThemePaletteOptions()[i]
      if choice then WG:SetThemeColor(choice[1]) end
    end,function()
      local choice=WG:ThemePaletteOptions()[i]
      if not choice then return '' end
      return (WG:CurrentPaletteName()==choice[1] and '● ' or '')..choice[1]
    end)
    local swatch=self.colorwayChoices[i]:CreateTexture(nil,'OVERLAY')
    swatch:SetSize(17,26)
    swatch:SetPoint('RIGHT',self.colorwayChoices[i],'RIGHT',-13,0)
    self.colorwayChoices[i].swatch=swatch
  end
  S:Label(p,'Each interface remembers its own theme and colorway.',5,-453,11,'text',560)
  self:Button(p,'MODERN CONTROLS',5,-477,183,37,
    function()S:Select('MODERNHUD')end)
  self:Button(p,'ADVENTURE STUDIO',384,-477,183,37,
    function()S:Select('EXPEDITION')end)
  S:Label(p,'Classic is untouched. Modern, Tactical and Adventure each have separate HUD controls.',5,-518,10,'accent',566)
end
function S:BuildModernHUD()
  local p=self:MakePage('MODERNHUD','MODERN HUD','Floating skills, low-profile XP, and clear readable frames. Classic is unchanged.')
  local bar
  for _,m in ipairs(WG.modules) do if m.ModernSettings and m.ApplyModernLayout then bar=m;break end end
  local o=bar and bar:ModernSettings() or {gap=8,iconSize=40,xpWidth=455,xpOpacity=.84,xpText=true}
  S:Label(p,'FLOATING ACTION ICONS',5,-91,13,'accent')
  self:Check(p,'Show XP label',5,-125,276,
    function()return bar and bar:ModernSettings().xpText~=false end,
    function(v)if bar then bar:ModernSettings().xpText=v end end)
  self:Button(p,'EDIT HUD POSITIONS',293,-125,271,34,function()WG:ToggleEditMode()end)
  local defs={
    {'iconSize','Action icon size',5,-185,268,34,48,1,function(v)return math.floor(v)..' px' end},
    {'gap','Space between buttons',294,-185,268,2,15,1,function(v)return math.floor(v)..' px' end},
    {'xpWidth','XP bar width',5,-257,268,250,650,10,function(v)return math.floor(v)..' px' end},
    {'xpHeight','XP bar thickness',294,-257,268,8,18,1,function(v)return math.floor(v)..' px' end},
    {'xpOpacity','XP bar opacity',5,-329,268,.5,1,.05,function(v)return math.floor(v*100+.5)..'%' end},
    {'chatOpacity','Chat background opacity',294,-329,268,.12,.85,.05,function(v)return math.floor(v*100+.5)..'%' end},
  }
  self.modernSliders={}
  for _,d in ipairs(defs) do
    local key=d[1]
    local ctl=WG:Slider(p,d[2],d[3],d[4],d[5],d[6],d[7],d[8],o[key],function(v)
      if bar then bar:ModernSettings()[key]=v end
    end,d[9])
    self.modernSliders[#self.modernSliders+1]={key=key,widget=ctl}
  end
  S:Label(p,'MODERN NAVIGATION',5,-398,12,'accent')
  self:Button(p,'',5,-421,267,35,function()
    local q=WG.quests
    if q and q.TrackerOptions then
      local opt=q:TrackerOptions()
      opt.navigationStyle=(opt.navigationStyle=='compact') and 'classic' or 'compact'
      if q.UpdateArrow then q:UpdateArrow() end
    end
  end,function()
    local q=WG.quests
    local style=q and q.TrackerOptions and q:TrackerOptions().navigationStyle or 'compact'
    return 'ARROW: '..(style=='classic' and 'ORIGINAL' or 'COMPACT COMPASS')
  end)
  self:Button(p,'QUEST TRACKER SETTINGS',294,-421,268,35,function()S:Select('QUESTS')end)
  S:Label(p,'Rounded glass controls, legible quests and independently movable navigation.',5,-467,11,'text',560)
  self:Button(p,'RETURN TO UI STYLES',5,-503,556,36,function()S:Select('STYLES')end)
end

-- Configuration directory: direct links to every deep editor in this addon.
-- No fake destinations and no assumed external-addon integration.
function S:BuildDirectory()
  local p=self:MakePage('DIRECTORY','CONTROL DIRECTORY','Search real modules, then open the exact editor. The original settings remain available.')
  local search=CreateFrame('EditBox',nil,p,'InputBoxTemplate')
  search:SetSize(349,26)
  search:SetPoint('TOPLEFT',p,'TOPLEFT',96,-95)
  search:SetAutoFocus(false)
  search:SetText('')
  search:SetScript('OnEscapePressed',function(box)box:ClearFocus()end)
  self:Label(p,'FIND TOOL',5,-101,11,'accent')
  self:Button(p,'CLEAR',461,-95,103,29,function()search:SetText('')end)
  local scroll=CreateFrame('ScrollFrame',nil,p,'UIPanelScrollFrameTemplate')
  scroll:SetPoint('TOPLEFT',p,'TOPLEFT',4,-141)
  scroll:SetPoint('BOTTOMRIGHT',p,'BOTTOMRIGHT',-23,12)
  local content=CreateFrame('Frame',nil,scroll)
  content:SetSize(529,1300)
  scroll:SetScrollChild(content)
  local entries={
    {'GET STARTED','Feature toggles','Search every on/off switch in the original settings','settings'},
    {'GET STARTED','Guided setup','First-run or reconfiguration wizard','setup'},
    {'GET STARTED','Original control hub','Classic all-module launch panel','hub'},
    {'INTERFACE','Tactical deck layout','Skill bars, widths, density, HUD positions','TACTICALHUD','page'},
    {'INTERFACE','Tactical field readouts','Contacts, latency, location, bags and condition','TACTICALINTEL','page'},
    {'INTERFACE','Tactical finish and colors','Signal accent, opacity and quest/comms polish','TACTICALLOOK','page'},
    {'INTERFACE','Modern HUD layout','Floating actions and navigation controls','MODERNHUD','page'},
    {'INTERFACE','Four interface styles','Classic, Modern, Tactical and Adventure','STYLES','page'},
    {'INTERFACE','Appearance and themes','Rain art, textures and custom color palettes','appearance'},
    {'INTERFACE','Window layout','Scale, positions and window lock behavior','layout'},
    {'INTERFACE','HUD positioning','Drag owned HUD elements, save and lock','EDIT','action'},
    {'COMBAT','Unit and raid frames','Scale, role icons, target and frame visibility','frames'},
    {'COMBAT','Action bars and experience','Bars, button binds, cooldowns and XP display','bars'},
    {'COMBAT','Threat meters','Waffle bars with Details numbers by default','THREAT','page'},
    {'COMBAT','Threat visuals','Fallback meter density, title and colors','THREATDETAILS','page'},
    {'COMBAT','Tiny Threat source and skin','Feed Details values into your Waffle meters','THREATSOURCE','page'},
    {'COMBAT','Auras and indicators','Per-unit buffs, debuffs, size and placement','auras'},
    {'COMBAT','Party setup','Tank, healer, DPS presets and party layout','GROUP','page'},
    {'COMBAT','Raid and group tools','Invites and organization','group'},
    {'COMBAT','Loot rules','Rolls and loot distribution settings','loot'},
    {'QUESTING','Waffle fallback tracker','Watch list, markers, ordering and opacity','QUESTS','page'},
    {'QUESTING','Questie native tracker skin','Questie first, Waffle fallback, backing appearance','QUESTIESKIN','page'},
    {'QUESTING','Quest journal','Detailed Waffle quest list','quests'},
    {'QUESTING','Adventure overview','XP, objectives and readiness','adventure'},
    {'QUESTING','Adventure HUD studio','Trail ledger, floating kit and journal','EXPEDITION','page'},
    {'QUESTING','Reward advisor','Reward comparisons and vendor value','rewards'},
    {'INVENTORY','Waffle Pantry','Inventory, categories and search','bags'},
    {'INVENTORY','Gear advisor','Upgrade suggestions and stat scores','gear'},
    {'INVENTORY','Auto-loot rules','Automatic pickup filters and options','autoloot'},
    {'INVENTORY','Automation and cleanup','Safe selling and turn-in helpers','automation'},
    {'COMMUNITY','Guild roster','Members, search and invites','guild'},
    {'COMMUNITY','Discord event board','Synced events and participation','guildboard'},
    {'COMMUNITY','Guild recruitment','Invite and recruiting tools','recruitment'},
    {'COMMUNITY','Guild professions','Shared recipes and known crafters','professions'},
    {'CUSTOMIZATION','Chat appearance','Chat backdrop and appearance','chat'},
    {'CUSTOMIZATION','Profiles and layout','Solo, group and raid snapshots','PROFILES','page'},
    {'CUSTOMIZATION','Original profile manager','Saved profiles and switching','profiles'},
    {'CUSTOMIZATION','External addon directory','Integration status and optional slash commands','ADDONS','page'},
    {'CUSTOMIZATION','Help and troubleshooting','Commands, help and recovery','help'},
  }
  local rows={}
  for _,entry in ipairs(entries) do
    local line=CreateFrame('Frame',nil,content)
    line:SetSize(522,55)
    WG:Surface(line,'panel','edge')
    self:Label(line,entry[1]..'  /  '..entry[2],9,-8,12,'accent',365)
    self:Label(line,entry[3],9,-29,10,'text',371)
    local dest=entry[4];local kind=entry[5]
    self:Button(line,'OPEN',399,-11,110,31,function()
      if kind=='page' then S:Select(dest)
      elseif kind=='action' then WG:ToggleEditMode()
      else S:Open(dest)end
    end)
    rows[#rows+1]={frame=line,haystack=(entry[1]..' '..entry[2]..' '..entry[3]..' '..dest):lower()}
  end
  local none=self:Label(content,'No matching controls. Try "combat", "HUD", "quests", or "guild".',5,-10,12,'accent',510)
  local function filter()
    local query=(search:GetText() or ''):lower():match('^%s*(.-)%s*$')
    local count=0
    for _,entry in ipairs(rows) do
      local match=query=='' or entry.haystack:find(query,1,true)~=nil
      entry.frame:SetShown(match)
      if match then
        entry.frame:ClearAllPoints()
        entry.frame:SetPoint('TOPLEFT',content,'TOPLEFT',0,-count*59)
        count=count+1
      end
    end
    content:SetHeight(math.max(80,count*59+10))
    none:SetShown(count==0)
    if scroll.SetVerticalScroll then scroll:SetVerticalScroll(0)end
  end
  search:SetScript('OnTextChanged',filter)
  filter()
  self.directorySearch=search
  self.directoryRows=rows
end
function S:TacticalNavigation(p)
  for i,link in ipairs({
    {'01 / DECK','TACTICALHUD'},
    {'02 / FIELD INTEL','TACTICALINTEL'},
    {'03 / FINISH','TACTICALLOOK'},
  }) do
    local key=link[2]
    self:Button(p,link[1],5+(i-1)*189,-88,182,35,
      function()S:Select(key)end,
      function()return (S.current==key and '> ' or '')..link[1]end)
  end
end
function S:BuildTacticalHUD()
  local p=self:MakePage('TACTICALHUD','TACTICAL  /  DECK','Flat command-bar geometry and precise, independent HUD sizing. No Classic decoration.')
  self:TacticalNavigation(p)
  self:Label(p,'DISPLAY DENSITY',5,-139,12,'accent')
  self:Check(p,'Compact field console',5,-168,269,
    function()return WG:TacticalSettings().compactHUD==true end,
    function(v)WG:TacticalSettings().compactHUD=v end)
  self:Check(p,'Show action bank labels',292,-168,269,
    function()return WG:TacticalSettings().showActionLabels~=false end,
    function(v)WG:TacticalSettings().showActionLabels=v end)
  self:Check(p,'Display unit portraits',5,-203,269,
    function()return WG:TacticalSettings().showPortraits==true end,
    function(v)WG:TacticalSettings().showPortraits=v end)
  self:Check(p,'Dense threat rows',292,-203,269,
    function()return WG:TacticalSettings().compactThreat~=false end,
    function(v)WG:TacticalSettings().compactThreat=v end)
  self:Label(p,'PRECISE BAR GEOMETRY',5,-246,12,'accent')
  local defs={
    {'iconSize','Action icon size',5,-276,267,26,48,1,function(v)return math.floor(v)..' px'end},
    {'gap','Action button spacing',295,-276,267,0,12,1,function(v)return math.floor(v)..' px'end},
    {'xpWidth','Experience strip width',5,-338,267,190,720,10,function(v)return math.floor(v)..' px'end},
    {'xpHeight','Experience thickness',295,-338,267,3,18,1,function(v)return math.floor(v)..' px'end},
    {'barOpacity','Action cell opacity',5,-400,267,.20,1,.04,function(v)return math.floor(v*100+.5)..'%'end},
    {'telemetryWidth','Signal ribbon width',295,-400,267,330,810,10,function(v)return math.floor(v)..' px'end},
  }
  self.tacticalSliders={}
  for _,d in ipairs(defs) do
    local key=d[1];local o=WG:TacticalSettings()
    local slider=WG:Slider(p,d[2],d[3],d[4],d[5],d[6],d[7],d[8],o[key],function(v)
      WG:TacticalSettings()[key]=v
      WG:Refresh()
    end,d[9])
    self.tacticalSliders[#self.tacticalSliders+1]={key=key,widget=slider}
  end
  self:Button(p,'CHANGE BAR GRID',5,-472,271,36,function()
    local o=WG:TacticalSettings();o.actionColumns=(o.actionColumns==12) and 6 or 12
  end,function()return 'GRID: '..(WG:TacticalSettings().actionColumns==12 and '12 WIDE' or '6 x 2')end)
  self:Button(p,'DEEP ACTION BAR OPTIONS',294,-472,269,36,function()S:Open('bars')end)
  self:Label(p,'Action buttons remain secure. Geometry changes wait until combat ends.',5,-517,10,'text',558)
end
function S:BuildTacticalIntel()
  local p=self:MakePage('TACTICALINTEL','TACTICAL  /  FIELD INTEL','Control each genuine data source independently. Readouts are informational, not combat automation.')
  self:TacticalNavigation(p)
  self:Label(p,'FIELD CONSOLE',5,-139,12,'accent')
  local checks={
    {'Enable tactical console','showTelemetry',5,-171},
    {'Only show during combat','combatOnly',292,-171},
    {'Target name / level / elite','showTarget',5,-207},
    {'Party and raid count','showGroup',292,-207},
    {'FPS and world latency','showPerformance',5,-243},
    {'Zone and map position','showLocation',292,-243},
    {'Free bag slots','showBagSpace',5,-279},
    {'Equipped durability','showDurability',292,-279},
    {'Server clock in status','showClock',5,-315},
  }
  for _,entry in ipairs(checks) do
    local key=entry[2]
    self:Check(p,entry[1],entry[3],entry[4],269,
      function()return WG:TacticalSettings()[key]==true end,
      function(v)WG:TacticalSettings()[key]=v end)
  end
  self:Label(p,'NAVIGATION / ONLY SHOW VALID ROUTES',5,-357,12,'accent')
  for i,style in ipairs({'waffle','text','off'}) do
    self:Button(p,style:upper(),5+(i-1)*190,-380,179,33,function()
      WG:TacticalSettings().navStyle=style
      if WG.quests and WG.quests.UpdateArrow then WG.quests:UpdateArrow()end
    end,function()return (WG:TacticalSettings().navStyle==style and '● ' or '')..style:upper()end)
  end
  self:Check(p,'Show inactive route placeholder',5,-424,285,
    function()return WG:TacticalSettings().showNoRoute end,
    function(v)WG:TacticalSettings().showNoRoute=v end)
  self:Button(p,'MOVE HUD',5,-468,177,31,function()WG:ToggleEditMode()end)
  self:Button(p,'THREAT OPTIONS',197,-468,177,31,function()S:Select('THREAT')end)
  self:Button(p,'AURA OPTIONS',389,-468,174,31,function()S:Select('AURAS')end)
  self:Label(p,'When Questie has no waypoint the tactical arrow stays hidden by default.',5,-512,10,'text',558)
end
function S:BuildTacticalLook()
  local p=self:MakePage('TACTICALLOOK','TACTICAL  /  FINISH','Independent signal colors, typography and panel density. Does not restyle Classic or Modern.')
  self:TacticalNavigation(p)
  self:Label(p,'SIGNAL ACCENT',5,-142,12,'accent')
  local choices={'Theme','Sage','Arctic','Amber','White'}
  for i,color in ipairs(choices) do
    self:Button(p,color:upper(),5+(i-1)*114,-170,108,37,
      function()WG:TacticalSettings().signalColor=color end,
      function()return (WG:TacticalSettings().signalColor==color and '> ' or '')..color:upper()end)
  end
  self:Label(p,'CONSOLE / COMMS / OBJECTIVES',5,-228,12,'accent')
  local defs={
    {'telemetryOpacity','Console opacity',5,-261,267,.35,1,.05,function(v)return math.floor(v*100+.5)..'%'end},
    {'questOpacity','Quest panel if enabled',294,-261,267,0,.98,.03,function(v)return math.floor(v*100+.5)..'%'end},
    {'questFont','Quest text size',5,-328,267,10,17,1,function(v)return math.floor(v)..' pt'end},
    {'questWidth','Quest list width',294,-328,267,250,460,5,function(v)return math.floor(v)..' px'end},
  }
  self.tacticalLookSliders={}
  for _,d in ipairs(defs) do
    local key=d[1]
    local slider=WG:Slider(p,d[2],d[3],d[4],d[5],d[6],d[7],d[8],WG:TacticalSettings()[key],function(v)
      WG:TacticalSettings()[key]=v;WG:Refresh()
    end,d[9])
    self.tacticalLookSliders[#self.tacticalLookSliders+1]={key=key,widget=slider}
  end
  self:Check(p,'Questie-like text tracker',5,-401,270,
    function()return WG:TacticalSettings().questMinimal end,
    function(v)WG:TacticalSettings().questMinimal=v end)
  self:Check(p,'Objective progress bars',294,-401,265,
    function()return WG:TacticalSettings().questProgressBars end,
    function(v)WG:TacticalSettings().questProgressBars=v end)
  self:Button(p,'QUEST SETTINGS',5,-441,177,27,function()S:Select('QUESTS')end)
  self:Button(p,'THEMES & COLORS',197,-441,177,27,function()S:Select('STYLES')end)
  self:Button(p,'NAV SETTINGS',389,-441,174,27,function()S:Select('TACTICALINTEL')end)
  self:Button(p,'RESTORE TACTICAL DEFAULTS',5,-474,270,33,function()
    WG.db.tacticalHUD={};WG:TacticalSettings()
  end)
  self:Button(p,'ALL ADVANCED MODULES',294,-474,268,33,function()S:Select('DIRECTORY')end)
  self:Label(p,'Restoring Tactical defaults leaves your Classic, Modern and Rain themes intact.',5,-518,10,'text',559)
end

-- Optional addon directory: simple discoverability without invasive hooks or copied code.
-- A button opens the chat edit box with the addon's slash command. User presses Enter.
function S:BuildExpedition()
  local p=self:MakePage('EXPEDITION','ADVENTURE  /  TRAIL STUDIO',
    'The Explorer HUD, floating spell kit, trail journal and navigation share one style.')
  self:Label(p,'EXPLORATION OVERLAY',5,-86,13,'accent')
  local checks={
    {'Show Trail Ledger HUD','showHUD',5,-120},
    {'Compact field ledger','compactHUD',294,-120},
    {'Show level and XP','showXP',5,-157},
    {'Show session progress','showSession',294,-157},
    {'Show map coordinates','showLocation',5,-194},
    {'Show bag readiness','showReadiness',294,-194},
    {'Text-first trail journal','journalMinimal',5,-231},
  }
  for _,row in ipairs(checks) do
    self:Check(p,row[1],row[3],row[4],265,
      function()return WG:ExpeditionSettings()[row[2]]==true end,
      function(v)WG:ExpeditionSettings()[row[2]]=v end)
  end
  self:Label(p,'WAYFINDER ACTION DECK',5,-270,13,'accent')
  local defs={
    {'iconSize','Ability icon size',5,-300,268,28,45,1,function(v)return math.floor(v)..' px'end},
    {'gap','Spell spacing',295,-300,268,1,12,1,function(v)return math.floor(v)..' px'end},
    {'hudOpacity','Field ledger opacity',5,-367,268,.1,1,.05,function(v)return math.floor(v*100)..'%'end},
    {'xpWidth','Travel XP line width',295,-367,268,260,650,10,function(v)return math.floor(v)..' px'end},
  }
  self.expeditionSliders={}
  for _,v in ipairs(defs) do
    local k=v[1]
    local ctl=WG:Slider(p,v[2],v[3],v[4],v[5],v[6],v[7],v[8],WG:ExpeditionSettings()[k],function(n)
      WG:ExpeditionSettings()[k]=n;WG:Refresh()
    end,v[9])
    self.expeditionSliders[k]=ctl
  end
  self:Button(p,'ACTION DECK: 6 OR 12 WIDE',5,-415,273,30,function()
    local o=WG:ExpeditionSettings();o.actionColumns=o.actionColumns==6 and 12 or 6
  end,function()return 'ACTION DECK: '..WG:ExpeditionSettings().actionColumns..' WIDE'end)
  self:Button(p,'MOVE EXPLORER HUD',5,-449,179,35,function()WG:ToggleEditMode()end)
  self:Button(p,'QUEST JOURNAL',197,-449,179,35,function()S:Select('QUESTS')end)
  self:Button(p,'ADVENTURE CENTER',389,-449,177,35,function()S:Open('adventure')end)
  self:Label(p,'TIP: drag the small + tab anytime; right-click to lock one HUD frame.',5,-480,10,'text',565)
  self:Button(p,'RESTORE ADVENTURE DEFAULTS',5,-500,273,30,function()
    WG.db.expeditionHUD={};WG:ExpeditionSettings()
  end)
  self:Button(p,'INTERFACES & COLORWAYS',294,-500,270,30,function()S:Select('STYLES')end)
end

-- Native integration page follows ForeverUI's four styles. Supported public
-- bridges open OUR settings; external-only addons open THEIR commands without
-- modifying protected third-party windows or promising unsupported reskins.
function S:BuildAddons()
  local p=self:MakePage('ADDONS','CONNECTED ADDONS & BRIDGES',
    'ForeverUI controls for supported integrations. External addon windows keep their own skins.')
  local entries={
    {'Questie','Questie','/questie','Native quest list and ForeverUI skin','QUESTIESKIN','BRIDGE'},
    {'TomTom','TomTom','/tomtom','Active waypoint / arrow','QUESTS','BRIDGE'},
    {'OpenMap','OpenMap','/openmap','Map and quest overlays','QUESTS','BRIDGE'},
    {'HandyNotes','HandyNotes','/handynotes','Map pin providers','QUESTS','COMPANION'},
    {'Details! Tiny Threat','Details_TinyThreat',nil,'Live source for Waffle threat rows','THREATSOURCE','BRIDGE'},
    {'Clique','Clique','/clique','Mouseover click casting',nil,'EXTERNAL'},
    {'Capping','Capping','/capping','PvP queues and timers',nil,'EXTERNAL'},
    {"What's Training",'WhatsTraining','/wt','Class spells and trainers',nil,'EXTERNAL'},
    {'GTFO','GTFO','/gtfo','Ground danger sounds',nil,'EXTERNAL'},
    {'Deadly Boss Mods','DBM-Core','/dbm','Raid and dungeon alerts',nil,'EXTERNAL'},
  }
  local function addonLoaded(id)
    if id=='WafflesGang' then return true end
    if C_AddOns and C_AddOns.IsAddOnLoaded then
      local ok,value=pcall(C_AddOns.IsAddOnLoaded,id)
      if ok then return value end
    end
    if IsAddOnLoaded then
      local ok,value=pcall(IsAddOnLoaded,id)
      if ok then return value end
    end
    return false
  end
  self.addonStatus={}
  for i,e in ipairs(entries) do
    local col=(i-1)%2;local row=math.floor((i-1)/2)
    local x=4+col*286;local y=-87-row*85
    local tile=CreateFrame('Frame',nil,p)
    tile:SetSize(278,78);tile:SetPoint('TOPLEFT',p,'TOPLEFT',x,y)
    local skin=WG:Surface(tile,'panel','edge')
    WG.surfaces[#WG.surfaces+1]={repaint=function()
      local style=WG:StyleName()
      skin.bg:SetAlpha(style=='Tactical' and .20 or (style=='Modern' and .18 or (style=='Adventure' and .32 or .65)))
      skin.edge:SetAlpha(style=='Classic' and .5 or 0)
      if skin.grain then skin.grain:SetAlpha(style=='Classic' and .22 or 0) end
    end}
    local title=self:Label(tile,e[1]:upper(),10,-6,11,'accent',262)
    title:SetWordWrap(false)
    local note=self:Label(tile,e[4],10,-26,9,'text',256)
    note:SetWordWrap(false)
    local status=self:Label(tile,'',10,-48,9,'accent',158)
    self.addonStatus[#self.addonStatus+1]={text=status,id=e[2],name=e[1],command=e[3],loaded=addonLoaded,kind=e[6]}
    self:Button(tile,e[5] and 'OUR CONTROLS' or 'OPEN ADDON',165,-44,107,27,function()
      if e[5] then S:Select(e[5])
      elseif e[3] and ChatFrame_OpenChat then ChatFrame_OpenChat(e[3])
      else WG:Say('Use '..(e[3] or 'addon settings')..' to open '..e[1]) end
    end)
  end
  self:Label(p,'BRIDGE: uses supported APIs. EXTERNAL: command launcher only. No third-party code or skins copied.',5,-523,10,'text',563)
end
-- Style architecture: four different ways of arranging the same tools.
-- Controls and all their callbacks stay shared. Only their visual/navigation
-- shells change. Existing Classic structure is deliberately preserved.
function S:ApplyLayout()
  if not self.window or not self.nav then return end
  local style=WG:StyleName()
  if self.lastStyle==style then return end
  self.lastStyle=style
  local f,nav=self.window,self.nav
  local function anchor(frame,relative,x,y,width,height)
    frame:ClearAllPoints()
    frame:SetPoint('TOPLEFT',relative,'TOPLEFT',x,y)
    if width and height then frame:SetSize(width,height) end
  end
  local schemes={
    Classic={width=836,height=688,navX=17,navY=-98,navW=187,navH=544,pageX=217,pageY=-105,tabW=170,tabH=37,modeX=608,modeY=-69,modeW=209,modeH=31,dirX=414,dirY=-69,dirW=180},
    Modern={width=652,height=796,navX=24,navY=-84,navW=604,navH=126,pageX=31,pageY=-233,tabW=114,tabH=42,modeX=428,modeY=-57,modeW=198,modeH=29,dirX=244,dirY=-57,dirW=171},
    Tactical={width=960,height=712,navX=13,navY=-88,navW=151,navH=594,pageX=177,pageY=-105,tabW=136,tabH=39,modeX=731,modeY=-69,modeW=203,modeH=32,dirX=537,dirY=-69,dirW=182},
    Adventure={width=895,height=746,navX=17,navY=-97,navW=218,navH=604,pageX=254,pageY=-106,tabW=98,tabH=47,modeX=657,modeY=-69,modeW=210,modeH=32,dirX=463,dirY=-69,dirW=179},
  }
  local c=schemes[style] or schemes.Classic
  f:SetSize(c.width,c.height)
  WG:ApplyWindowScale('studio',f)
  anchor(nav,f,c.navX,c.navY,c.navW,c.navH)
  anchor(self.modeButton,f,c.modeX,c.modeY,c.modeW,c.modeH)
  if self.directoryButton then anchor(self.directoryButton,f,c.dirX,c.dirY,c.dirW,c.modeH);self.directoryButton.label:SetWidth(c.dirW-10) end
  if self.modeButton.label then self.modeButton.label:SetWidth(c.modeW-12) end
  self.navTitle:SetShown(style~='Modern')
  self.navSubtitle:SetShown(style~='Modern')
  for i,tab in ipairs(tabs) do
    local b=self.tabs[tab[1]]
    if b then
      local x,y
      if style=='Modern' then
        x=10+((i-1)%5)*118
        y=-12-math.floor((i-1)/5)*52
      elseif style=='Tactical' then
        x=7;y=-76-(i-1)*47
      elseif style=='Adventure' then
        x=8+((i-1)%2)*103;y=-81-math.floor((i-1)/2)*70
      else
        x=8;y=-68-(i-1)*44
      end
      anchor(b,nav,x,y,c.tabW,c.tabH)
      if b.label then b.label:SetWidth(c.tabW-10) end
      if style=='Tactical' then b.tabLabel=string.format('%02d  %s',i,tab[2])
      elseif style=='Adventure' then
        local short={'WELCOME','GROUP','AURAS','THREAT','QUESTS','GUILD','PANTRY','PROFILES','STYLES','ADDONS'}
        b.tabLabel=string.format('%02d  %s',i,short[i] or tab[2])
      else b.tabLabel=tab[2] end
    end
  end
  for _,page in pairs(self.pages) do
    page:ClearAllPoints()
    page:SetPoint('TOPLEFT',f,'TOPLEFT',c.pageX,c.pageY)
  end
  if self.sideRail then self.sideRail:SetShown(style=='Tactical') end
  if self.trailButtons then for _,button in ipairs(self.trailButtons) do button:SetShown(style=='Adventure') end end
  if self.sideRail then
    if style=='Modern' then anchor(self.sideRail,f,642,-252,225,437)
    elseif style=='Tactical' then anchor(self.sideRail,f,772,-123,163,511) end
  end
  if self.sideRailTitle then
    self.sideRailTitle:SetText(style=='Tactical' and 'FIELD / SHORTCUTS' or 'QUICK ACCESS')
  end
  if self.sideRailDescription then
    self.sideRailDescription:SetText(style=='Tactical' and
      'Target, latency, position and gear status.\nOpen a deep editor below.' or
      'A streamlined workspace with quick actions beside the editor.')
  end
  if self.sideButtons then
    local positions=style=='Tactical' and {144,203,262,321} or {152,211,270,329}
    local width=style=='Tactical' and 139 or 195
    for i,b in ipairs(self.sideButtons) do
      anchor(b,self.sideRail,12,-positions[i],width,42)
      b.label:SetWidth(width-10)
    end
  end
end
function S:BuildSideRail()
  local rail=CreateFrame('Frame',nil,self.window)
  self.sideRail=rail
  rail:SetSize(225,460)
  WG:Surface(rail,'panel','edge')
  self.sideRailTitle=WG:Text(rail,'QUICK ACCESS',13,-16,12,'accent',139)
  self.sideRailDescription=WG:Text(rail,'Your tools, at a glance.',13,-57,10,'text',139)
  self.sideRailDescription:SetJustifyH('LEFT')
  self.sideRailDescription:SetWordWrap(true)
  local actions={
    {'QUESTS',function()S:Select('QUESTS')end},
    {'THREAT WATCH',function()S:Select('THREAT')end},
    {'FIELD CONSOLE',function()S:Select('TACTICALINTEL')end},
    {'ALL TOOLS',function()S:Select('DIRECTORY')end},
  }
  self.sideButtons={}
  for i,row in ipairs(actions) do
    self.sideButtons[i]=WG:Button(rail,row[1],12,-110-(i-1)*58,195,42,row[2])
  end
  WG:Text(rail,'STYLE  /  LOCAL SETTINGS',13,-413,10,'accent',150)
  WG:Text(rail,'No Classic ornament. Drag a + tab anytime outside combat.',13,-441,10,'text',147)
  rail:Hide()
end
function S:BuildTrailShortcuts()
  local nav=self.nav
  self.trailButtons={}
  local links={
    {'TRAIL LEDGER SETTINGS','EXPEDITION'},
    {'QUEST JOURNAL','QUESTS'},
    {'THREAT METER DESIGN','THREATDETAILS'},
  }
  for i,row in ipairs(links) do
    local b=WG:Button(nav,row[1],8,-458-(i-1)*43,202,35,function()S:Select(row[2])end)
    self.trailButtons[#self.trailButtons+1]=b
    b:Hide()
  end
end
function S:Select(key,fromBack)
  if not self.pages[key] then return end
  if self.current~=key and not fromBack and self.pages[self.current] then
    self.history=self.history or {}
    self.history[#self.history+1]=self.current
    if #self.history>15 then table.remove(self.history,1) end
  end
  self.current=key
  for name,page in pairs(self.pages) do page:SetShown(key==name) end
  self:Refresh()
end
function S:Back()
  if not self.window then return end
  local previous=self.history and table.remove(self.history)
  if previous and self.pages[previous] then self:Select(previous,true)
  elseif self.current~='HOME' then self:Select('HOME',true)
  else self.window:Hide() end
end
function S:Refresh()
  if not self.window then return end
  self:ApplyLayout()
  local _,group=self:Group()
  for _,d in ipairs(self.dynamic) do
    if d.caption then
      local ok,caption=pcall(d.caption)
      if ok and type(caption)=='string' and d.button.label then d.button.label:SetText(caption)end
    end
    if d.advanced then d.button:SetShown(self.advanced) end
  end
  for _,ctrl in ipairs(self.checkControls or {}) do
    local c=WG:Color('accent')
    ctrl.border:SetColorTexture(c[1],c[2],c[3],.90)
    local checked=false
    local ok,val=pcall(ctrl.get)
    if ok then checked=val==true end
    ctrl.fill:SetColorTexture(checked and c[1] or .06,
      checked and c[2] or .06,checked and c[3] or .07,1)
    ctrl.button:SetShown(not ctrl.advanced or self.advanced)
  end
  if self.modeButton then self.modeButton.label:SetText('CONTROLS: '..(self.advanced and 'EXPERT' or 'QUICK')) end
  if self.styleDescription then
    self.styleDescription:SetText((WG.styleDescriptions and WG.styleDescriptions[WG:StyleName()] or '')..
      '  /  '..WG:ThemeName()..'  /  '..WG:CurrentPaletteName())
  end
  for i,b in ipairs(self.colorwayChoices or {}) do
    local choice=WG:ThemePaletteOptions()[i]
    if choice and b.swatch then
      local c=choice[2].accent;b.swatch:SetColorTexture(c[1],c[2],c[3],1)
    end
  end
  if self.threatSliders then
    local _,o=self:Threat()
    for key,entry in pairs(self.threatSliders) do
      entry.widget:SetShown(not entry.advanced or self.advanced)
      if entry.widget.SetDisplayValue and o[key] then entry.widget:SetDisplayValue(o[key]) end
    end
  end
  if self.threatDetailsSliders then
    local _,o=self:Threat()
    for k,w in pairs(self.threatDetailsSliders) do
      if w and w.SetDisplayValue and o[k]~=nil then w:SetDisplayValue(o[k]) end
    end
  end
  if self.expeditionSliders then
    local o=WG:ExpeditionSettings()
    for k,w in pairs(self.expeditionSliders) do
      if w and w.SetDisplayValue and o[k]~=nil then w:SetDisplayValue(o[k]) end
    end
  end
  if self.modernSliders then
    local bar
    for _,m in ipairs(WG.modules) do if m.ModernSettings then bar=m;break end end
    local o=bar and bar:ModernSettings() or {}
    for _,entry in ipairs(self.modernSliders) do
      if entry.widget and entry.widget.SetDisplayValue and o[entry.key] then
        entry.widget:SetDisplayValue(o[entry.key])
      end
    end
  end
  if self.tacticalSliders then
    local o=WG:TacticalSettings()
    for _,entry in ipairs(self.tacticalSliders) do
      if entry.widget and entry.widget.SetDisplayValue and o[entry.key] then entry.widget:SetDisplayValue(o[entry.key]) end
    end
  end
  if self.tacticalLookSliders then
    local o=WG:TacticalSettings()
    for _,entry in ipairs(self.tacticalLookSliders) do
      if entry.widget and entry.widget.SetDisplayValue and o[entry.key] then entry.widget:SetDisplayValue(o[entry.key]) end
    end
  end
  if self.questieSkinSliders and WG.questieSkin then
    local o=WG.questieSkin:Settings()
    for key,slider in pairs(self.questieSkinSliders) do
      if slider and slider.SetDisplayValue then slider:SetDisplayValue(o[key]) end
    end
  end
  if self.questSliders then
    local _,o=self:Quest()
    for _,entry in ipairs(self.questSliders) do
      if entry.widget and entry.widget.SetDisplayValue and o[entry.key] then
        entry.widget:SetDisplayValue(o[entry.key])
      end
    end
  end
  for name,b in pairs(self.tabs) do
    local selected=self.current==name
    local modern=WG:StyleName()=='Modern'
    b.label:SetText((selected and not modern and '> ' or '')..b.tabLabel)
    if b.modernMarker then b.modernMarker:SetShown(modern and selected) end
  end
  if self.preview then
    for i,t in ipairs(self.preview) do
      local names={'Deputy Waffles','Rain','Party Member'}
      local role={'TANK','HEALER','DPS'}
      local status=group.status and (i==3 and ' / READY' or '') or ''
      local aggro=group.threat and i==3 and ' / ! AGGRO !' or ''
      local lev=group.levels and ('   LV '..(10+i)) or ''
      t:SetText(names[i]..lev..(group.roles and (' / '..role[i]) or '')..status..aggro)
    end
  end
  if self.auraInfo then
    local _,o=self:Auras()
    self.auraInfo:SetText((self.auraGroup or 'party'):upper()..'  /  '..(o.buffCount or 0)..' buffs  /  '..(o.debuffCount or 0)..' debuffs  /  '..(o.size or 18)..'px')
  end
  if self.addonStatus then
    for _,item in ipairs(self.addonStatus) do
      local ok,value=pcall(item.loaded,item.id)
      local state=(ok and value) and (item.kind=='BRIDGE' and 'BRIDGE READY' or 'LOADED') or 'NOT LOADED'
      item.text:SetText(state)
    end
  end
  if self.openMapStatus then
    local om=WG.openMap
    self.openMapStatus:SetText((om and om:IsConnected()) and 'OPENMAP: CONNECTED TO PUBLIC API' or
      'OPENMAP: NOT CONNECTED. Install the Forever version of OpenMap.')
  end
  if WG.threatCompanion then
    local status=WG.threatCompanion:Status()
    if self.threatSourceInfo then self.threatSourceInfo:SetText(status) end
    if self.threatLiveStatus then self.threatLiveStatus:SetText(status) end
  end
  if self.threatSourceOpacity and WG.threatCompanion and self.threatSourceOpacity.SetDisplayValue then
    self.threatSourceOpacity:SetDisplayValue(WG.threatCompanion:Settings().opacity)
  end
  if self.questieSkinInfo then
    local q=WG.quests
    local qs=WG.questieSkin
    local available=qs and qs:QuestieIsAvailable()
    local active=q and q.UsingQuestieTracker and q:UsingQuestieTracker()
    self.questieSkinInfo:SetText(available and (active and 'QUESTIE ACTIVE / WAFFLE DUPLICATE HIDDEN' or 'QUESTIE AVAILABLE / WAFFLE TRACKER SELECTED')
      or (_G.Questie and 'QUESTIE TRACKER DISABLED / CHECK QUESTIE SETTINGS' or 'QUESTIE NOT INSTALLED / WAFFLE FALLBACK'))
  end
  if self.questInfo then
    local q=WG.quests
    local connected=q and (q.questieReady or (_G.Questie and _G.Questie.API and _G.Questie.API.isReady))
    self.questInfo:SetText(connected and 'QUESTIE: CONNECTED TO PUBLIC API' or
      (_G.Questie and 'QUESTIE: WAITING FOR READY' or 'QUESTIE: NOT INSTALLED (OPTIONAL)'))
  end
end
function S:Init()
  self.auraGroup='party'
  local f=WG:Window('studio','Waffle Studio: Customization Center',836,688)
  self.window=f
  local nav=CreateFrame('Frame',nil,f)
  self.nav=nav
  nav:SetSize(187,544);nav:SetPoint('TOPLEFT',f,'TOPLEFT',17,-98)
  WG:Surface(nav,'panel','edge')
  self.navTitle=WG:Text(nav,'WAFFLE STUDIO',11,-10,13,'accent')
  self.navSubtitle=WG:Text(nav,'ALL TOOLS IN ONE PLACE',11,-35,9,'text',160)
  for i,tab in ipairs(tabs) do
    local b=WG:Button(nav,tab[2],8,-68-(i-1)*44,170,37,function()S:Select(tab[1])end)
    b.tabLabel=tab[2]
    local marker=b:CreateTexture(nil,'OVERLAY')
    marker:SetHeight(3)
    marker:SetPoint('BOTTOMLEFT',b,'BOTTOMLEFT',2,2)
    marker:SetPoint('BOTTOMRIGHT',b,'BOTTOMRIGHT',-2,2)
    b.modernMarker=marker
    WG.surfaces[#WG.surfaces+1]={repaint=function()
      local c=WG:Color('accent');marker:SetColorTexture(c[1],c[2],c[3],1)
    end}
    self.tabs[tab[1]]=b
  end
  self.modeButton=WG:Button(f,'CONTROLS: QUICK',608,-69,209,31,function()
    S.advanced=not S.advanced;S:Refresh()
  end)
  self.directoryButton=WG:Button(f,'FIND ALL CONTROLS',414,-69,180,31,function()S:Select('DIRECTORY')end)
  self:BuildHome();self:BuildGroup();self:BuildAuras();self:BuildThreat();self:BuildThreatDetails();self:BuildThreatSource()
  self:BuildQuests();self:BuildQuestieSkin();self:BuildGuild();self:BuildPantry();self:BuildProfiles();self:BuildStyles();self:BuildModernHUD();self:BuildTacticalHUD();self:BuildTacticalIntel();self:BuildTacticalLook();self:BuildExpedition();self:BuildAddons();self:BuildDirectory()
  self:BuildSideRail()
  self:BuildTrailShortcuts()
  f.onOpen=function()S:Refresh()end
  self:Select('HOME',true)
end
