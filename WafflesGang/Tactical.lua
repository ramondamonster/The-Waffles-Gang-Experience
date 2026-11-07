-- ForeverUI Tactical / Field Console.
-- A deliberately flat, independently movable read-only intelligence strip.
-- Never creates protected unit buttons or changes secure combat layouts.
local WG=_G.WafflesGang
local M={name='Tactical Field Console',elapsed=0}
WG.modules[#WG.modules+1]=M
local function trusted(v)
  return (not issecretvalue or not issecretvalue(v)) and v or nil
end
local function safeNumber(fn,...)
  if type(fn)~='function' then return nil end
  local ok,v=pcall(fn,...)
  return ok and type(trusted(v))=='number' and v or nil
end
local function safeText(fn,...)
  if type(fn)~='function' then return nil end
  local ok,v=pcall(fn,...)
  return ok and type(trusted(v))=='string' and v~='' and v or nil
end
local function currentTarget()
  if not UnitExists then return 'NONE' end
  local ok,exists=pcall(UnitExists,'target')
  if not ok or trusted(exists)~=true then return 'NONE' end
  local name=safeText(GetUnitName,'target',false) or safeText(UnitName,'target') or 'TARGET'
  local level=safeNumber(UnitLevel,'target')
  local classification=safeText(UnitClassification,'target')
  local suffix=(level and level>0 and ('  '..level) or '')
  if classification=='elite' then suffix=suffix..' ELITE'
  elseif classification=='worldboss' then suffix=suffix..' BOSS'
  elseif classification=='rare' or classification=='rareelite' then suffix=suffix..' RARE' end
  return (name..suffix):sub(1,31)
end
local function currentZone()
  local sub=safeText(GetSubZoneText)
  local zone=safeText(GetZoneText)
  if sub and sub~=zone then return sub end
  return zone or 'UNKNOWN'
end
local function coords()
  if not C_Map or not C_Map.GetBestMapForUnit or not C_Map.GetPlayerMapPosition then return nil end
  local map=safeNumber(C_Map.GetBestMapForUnit,'player')
  if not map then return nil end
  local ok,pos=pcall(C_Map.GetPlayerMapPosition,map,'player')
  if not ok or not pos then return nil end
  local good,x,y=pcall(function()return pos:GetXY()end)
  if not good or type(trusted(x))~='number' or type(trusted(y))~='number' then return nil end
  return string.format('%02d.%d / %02d.%d',math.floor(x*100),math.floor(x*1000)%10,math.floor(y*100),math.floor(y*1000)%10)
end
local function bagSlots()
  local free,total=0,0
  for bag=0,4 do
    local fn=C_Container and C_Container.GetContainerNumSlots or GetContainerNumSlots
    local count=safeNumber(fn,bag)
    if count and count>0 then
      total=total+count
      local getFree=C_Container and C_Container.GetContainerNumFreeSlots or GetContainerNumFreeSlots
      local n=safeNumber(getFree,bag)
      free=free+(n or 0)
    end
  end
  return total>0 and (free..' FREE / '..total) or 'N/A'
end
local function durability()
  if type(GetInventoryItemDurability)~='function' then return 'N/A' end
  local current,maximum=0,0
  for i=1,18 do
    local ok,a,b=pcall(GetInventoryItemDurability,i)
    if ok and type(trusted(a))=='number' and type(trusted(b))=='number' and b>0 then
      current=current+a;maximum=maximum+b
    end
  end
  return maximum>0 and (math.floor(current/maximum*100+.5)..'%') or 'N/A'
end
local function latency()
  if not GetNetStats then return 'N/A' end
  local ok,_,_,home,world=pcall(GetNetStats)
  if not ok then return 'N/A' end
  local lag=type(trusted(world))=='number' and world or (type(trusted(home))=='number' and home or nil)
  return lag and (math.floor(lag+.5)..' MS') or 'N/A'
end
local function clock()
  if not GetGameTime then return '--:--' end
  local ok,h,m=pcall(GetGameTime)
  if ok and type(trusted(h))=='number' and type(trusted(m))=='number' then
    return string.format('%02d:%02d',h,m)
  end
  return '--:--'
end
local function combatNow()
  local fn=UnitAffectingCombat
  if not fn then return WG:Protected()==true end
  local ok,flag=pcall(fn,'player')
  return ok and trusted(flag)==true or WG:Protected()==true
end
local function countGroup()
  local n=safeNumber(GetNumGroupMembers)
  return math.max(1,n or 1)
end
-- Narrow signal ribbon, not a dashboard blocking the viewport.
-- Hover for the detailed readouts, left-click to open Tactical settings,
-- right-click to expand/collapse. All of this is read-only and combat-safe.
function M:Init()
  local f=CreateFrame('Button','WGTacticalFieldConsole',UIParent)
  f:SetSize(465,30)
  f:SetPoint('TOP',UIParent,'TOP',0,-11)
  f:SetFrameStrata('MEDIUM')
  f:SetClampedToScreen(true)
  f:RegisterForClicks('LeftButtonUp','RightButtonUp')
  WG:RegisterHUDFrame('tacticalcommand',f,'Tactical Signals')
  self.hud=f
  local base=f:CreateTexture(nil,'BACKGROUND')
  base:SetAllPoints()
  self.base=base
  local rule=f:CreateTexture(nil,'OVERLAY')
  rule:SetPoint('BOTTOMLEFT',f,'BOTTOMLEFT',0,0)
  rule:SetPoint('BOTTOMRIGHT',f,'BOTTOMRIGHT',0,0)
  rule:SetHeight(1)
  self.rule=rule
  local label=f:CreateFontString(nil,'OVERLAY','GameFontNormalSmall')
  label:SetPoint('LEFT',f,'LEFT',10,0)
  label:SetFont(WG:StyleFont(10),10,'')
  label:SetJustifyH('LEFT')
  self.caption=label
  local status=f:CreateFontString(nil,'OVERLAY','GameFontNormalSmall')
  status:SetPoint('RIGHT',f,'RIGHT',-10,0)
  status:SetFont(WG:StyleFont(10),10,'')
  self.state=status
  self.first={};self.second={}
  local categories={'TARGET','GROUP','FPS','PING','ZONE','POSITION','BAGS','GEAR'}
  for i,name in ipairs(categories) do
    local tx=f:CreateFontString(nil,'OVERLAY','GameFontNormalSmall')
    tx:SetJustifyH('LEFT');tx:SetFont(WG:StyleFont(10),10,'')
    self.first[i]={label=name,value=tx}
  end
  WG.surfaces[#WG.surfaces+1]={repaint=function()
    local c=WG:Color('accent')
    local bg=WG:Color('bg')
    base:SetColorTexture(bg[1],bg[2],bg[3],.86)
    rule:SetColorTexture(c[1],c[2],c[3],.57)
    label:SetTextColor(c[1],c[2],c[3])
    for _,item in ipairs(M.first) do item.value:SetTextColor(.91,.94,.92) end
  end}
  f:SetScript('OnClick',function(_,button)
    if button=='RightButton' then
      local o=WG:TacticalSettings();o.compactHUD=not o.compactHUD
      M:Refresh()
      if WG.studio and WG.studio.Refresh then WG.studio:Refresh() end
    else
      WG:Open('studio')
      if WG.studio then WG.studio:Select('TACTICALINTEL') end
    end
  end)
  f:SetScript('OnEnter',function()
    GameTooltip:SetOwner(f,'ANCHOR_BOTTOM')
    GameTooltip:AddLine('TACTICAL SIGNALS',.8,.96,.9)
    for _,v in ipairs(M.first) do GameTooltip:AddDoubleLine(v.label,v.raw or 'N/A',.62,.84,.79,.95,.95,.95) end
    GameTooltip:AddLine('Left: settings    Right: compact / expanded',.75,.75,.75)
    GameTooltip:Show()
  end)
  f:SetScript('OnLeave',function()GameTooltip:Hide()end)
  f:SetScript('OnUpdate',function(_,dt)
    if not WG.db or WG:StyleName()~='Tactical' then return end
    M.elapsed=M.elapsed+(dt or 0)
    if M.elapsed<1 then return end
    M.elapsed=0;M:Update()
  end)
  self:Refresh()
end
function M:Update()
  if not self.hud or not WG.db then return end
  local o=WG:TacticalSettings()
  local engaged=combatNow()
  local visible=WG:StyleName()=='Tactical' and o.showTelemetry and (not o.combatOnly or engaged or WG.editMode)
  self.hud:SetShown(visible)
  if not visible then return end
  local fps=safeNumber(GetFramerate)
  local values={
    o.showTarget and currentTarget() or '--',
    o.showGroup and tostring(countGroup()) or '--',
    o.showPerformance and (fps and (math.floor(fps+.5)..' FPS') or 'N/A') or '--',
    o.showPerformance and latency() or '--',
    o.showLocation and currentZone():sub(1,29) or '--',
    o.showLocation and (coords() or 'N/A') or '--',
    o.showBagSpace and bagSlots() or '--',
    o.showDurability and durability() or '--',
  }
  for i,item in ipairs(self.first) do
    item.raw=values[i]
    item.value:SetText(item.label..'  '..values[i])
  end
  self.state:SetText(engaged and 'IN COMBAT' or (o.showClock and clock() or 'READY'))
  if o.compactHUD then
    local short=string.format('TGT %s   |   %s   |   %s',
      values[1]:sub(1,22),values[3],values[4])
    self.caption:SetText(short)
  else
    self.caption:SetText('FIELD INTEL')
  end
end
function M:Refresh()
  if not self.hud or not WG.db then return end
  local o=WG:TacticalSettings()
  local w=o.telemetryWidth
  local small=o.compactHUD
  self.hud:SetSize(w,small and 28 or 74)
  self.hud:SetAlpha(o.telemetryOpacity)
  self.state:SetShown(small)
  self.caption:SetShown(true)
  for i,item in ipairs(self.first) do
    local tx=item.value
    tx:ClearAllPoints()
    tx:SetShown(not small)
    local col=(i-1)%4
    local row=math.floor((i-1)/4)
    tx:SetPoint('TOPLEFT',self.hud,'TOPLEFT',10+col*(w-20)/4,-26-row*22)
    tx:SetWidth((w-20)/4-4)
  end
  self:Update()
end
