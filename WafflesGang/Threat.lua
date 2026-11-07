-- ForeverUI Dual Threat Watch: Waffle visuals with Details! Tiny Threat numbers.
-- Details! owns calculations and ordering whenever its source is selected.
-- The original native threat API is an explicit fallback only. Never fake secret data.
local WG = _G.WafflesGang
local T = { name='Dual Threat Watch', meters={}, selected=1 }
WG.threatWatch=T
WG.modules[#WG.modules+1]=T

local DEFAULT={enabled=false,mode='RELATIVE',source='TARGET',width=252,rowHeight=22,rows=6,
  speed=.5,classColors=true,showPets=false,showOnlyCombat=true,showPlayer=true,
  autoFit=true,hideEmpty=true,unlocked=false,pinPlayer=false,
  showAmounts=false,detailsShowAmounts=true,showTitle=true,compactRows=false,frameOpacity=.52,barOpacity=.80}

local function clamp(n,a,b) return math.max(a,math.min(b,n)) end
local function permitted(v) return not (issecretvalue and issecretvalue(v)) end
local function number(v) return permitted(v) and type(v)=='number' and v==v and v~=math.huge and v~=-math.huge end
local function safeName(unit)
  local ok,n=pcall(function() return (GetUnitName and GetUnitName(unit,true)) or UnitName(unit) end)
  if ok and permitted(n) and type(n)=='string' and n~='' then return n end
end
local function font(parent,size)
  local f=parent:CreateFontString(nil,'OVERLAY','GameFontNormalSmall')
  f:SetFont(STANDARD_TEXT_FONT or 'Fonts\\FRIZQT__.TTF',size,'OUTLINE')
  return f
end

-- Meter 1 keeps the v3.4-v3.5 saved-variable shape and HUD key, so existing
-- settings and screen position are preserved after upgrading.
function T:Settings(index)
  index=index or self.selected or 1
  if not WG.db then return DEFAULT end
  local key=index==2 and 'threatWatch2' or 'threatWatch'
  if type(WG.db[key])~='table' then WG.db[key]={} end
  local o=WG.db[key]
  if not o.v410Migrated then
    -- Change ONLY the untouched factory preset, never an intentionally tuned meter.
    local stock=(o.width==nil or o.width==300) and (o.rows==nil or o.rows==8)
      and (o.rowHeight==nil or o.rowHeight==20)
    if stock then
      if o.width==300 then o.width=252 end
      if o.rowHeight==20 then o.rowHeight=17 end
      if o.rows==8 then o.rows=6 end
      if o.hideEmpty==false and o.autoFit~=false then o.hideEmpty=true end
    end
    o.v410Migrated=true
  end
  if not o.v450ThickBars then
    -- Existing stock 17px rows were difficult to distinguish in motion.
    -- Only upgrade that factory combination; leave customized row sizes alone.
    if o.rowHeight==17 and o.compactRows~=false then
      o.rowHeight=22
      o.compactRows=false
    end
    o.v450ThickBars=true
  end
  for k,v in pairs(DEFAULT) do if o[k]==nil then o[k]=v end end
  return o
end
function T:GetTarget(index)
  local o=self:Settings(index)
  if o.source=='FOCUS' and UnitExists and UnitExists('focus') then return 'focus' end
  return 'target'
end
function T:GetMembers(index)
  local list={}
  if IsInRaid and IsInRaid() and GetNumGroupMembers then
    local count=GetNumGroupMembers() or 0
    for i=1,math.min(count,40) do list[#list+1]='raid'..i end
  elseif IsInGroup and IsInGroup() and GetNumSubgroupMembers then
    list[#list+1]='player'
    local count=GetNumSubgroupMembers() or 0
    for i=1,math.min(count,4) do list[#list+1]='party'..i end
  else list[1]='player' end
  if self:Settings(index).showPets and UnitExists and UnitExists('pet') then list[#list+1]='pet' end
  return list
end
-- Player row is reserved at the top whenever Show Own Character is enabled.
-- A blank threat reading is rendered as WAITING, never as fabricated 0%.
function T:WaitingRow()
  return {name=safeName('player') or 'You',unit='player',waiting=true}
end
function T:Collect(index)
  local options=self:Settings(index)
  local function idle(message)
    if options.showPlayer and not options.hideEmpty then return {self:WaitingRow()},message end
    return {},message
  end
  local target=self:GetTarget(index)
  if not UnitExists or not UnitExists(target) then return idle('Select an enemy to measure threat') end
  local okFriend,isFriend=pcall(UnitIsFriend,'player',target)
  if okFriend and permitted(isFriend) and isFriend then return idle('Select a hostile target') end
  if not UnitDetailedThreatSituation then return idle('Threat API unavailable') end
  local others,playerRow,restricted={},nil,false
  for _,unit in ipairs(self:GetMembers(index)) do
    if UnitExists(unit) then
      local name=safeName(unit)
      if name then
        local ok,tanking,status,scaled,raw,amount=pcall(UnitDetailedThreatSituation,unit,target)
        if not ok then restricted=true
        elseif (scaled~=nil and not number(scaled)) or (amount~=nil and not number(amount))
          or (raw~=nil and not number(raw)) then
          restricted=true
        elseif number(scaled) then
          local percent=(options.mode=='ABSOLUTE' and number(raw) and raw) or scaled
          if number(percent) then
            local cOK,_,class=pcall(UnitClass,unit)
            local role='NONE'
            if UnitGroupRolesAssigned then
              local rOK,r=pcall(UnitGroupRolesAssigned,unit)
              if rOK and permitted(r) and type(r)=='string' then role=r end
            end
            local item={name=name,unit=unit,percent=percent,
              amount=number(amount) and amount or nil,tanking=permitted(tanking) and tanking==true,
              class=cOK and permitted(class) and class or nil,role=role}
            local isSelf=unit=='player'
            if not isSelf and UnitIsUnit then
              local equalOK,equal=pcall(UnitIsUnit,unit,'player')
              isSelf=equalOK and permitted(equal) and equal==true
            end
            if isSelf then playerRow=item else others[#others+1]=item end
          else restricted=true end
        end
      end
    end
  end
  table.sort(others,function(a,b)
    if options.mode=='ABSOLUTE' and number(a.amount) and number(b.amount) then
      return a.amount>b.amount
    end
    return a.percent>b.percent
  end)
  if options.showPlayer and playerRow then
    if options.pinPlayer then table.insert(others,1,playerRow)
    else
      others[#others+1]=playerRow
      table.sort(others,function(a,b)return (a.percent or 0)>(b.percent or 0)end)
    end
  elseif options.showPlayer and #others==0 and not options.hideEmpty then
    others[1]=self:WaitingRow()
  end
  if #others==0 or (#others==1 and others[1].waiting) then
    return others,restricted and 'Threat data restricted by WoW' or 'Waiting for threat data'
  end
  return others,restricted and 'Some values restricted by WoW' or nil
end
function T:MakeRow(m,i)
  local r=CreateFrame('StatusBar',nil,m.hud)
  r:SetStatusBarTexture('Interface\\Buttons\\WHITE8X8')
  r:SetMinMaxValues(0,100)
  local bg=r:CreateTexture(nil,'BACKGROUND');bg:SetAllPoints();bg:SetColorTexture(.04,.04,.04,.84)
  r.track=bg
  r.left=font(r,11);r.left:SetPoint('LEFT',r,'LEFT',5,0);r.left:SetJustifyH('LEFT');r.left:SetWordWrap(false)
  r.right=font(r,10);r.right:SetPoint('RIGHT',r,'RIGHT',-5,0);r.right:SetJustifyH('RIGHT');r.right:SetWidth(90)
  r.left:SetTextColor(1,.95,.85);r.right:SetTextColor(1,.95,.85)
  m.rows[i]=r
end
function T:MakeHUD(index)
  local name=index==1 and 'WGThreatWatch' or 'WGThreatWatch2'
  local f=CreateFrame('Frame',name,UIParent)
  f:SetSize(300,65)
  if index==1 then f:SetPoint('LEFT',UIParent,'LEFT',405,-100)
  else f:SetPoint('RIGHT',UIParent,'RIGHT',-85,-155) end
  local meterSkin=WG:Surface(f,'panel','edge')
  local title=font(f,12)
  title:SetPoint('TOPLEFT',f,'TOPLEFT',8,-6)
  title:SetText(index==1 and 'WAFFLES / THREAT 1' or 'WAFFLES / THREAT 2')
  local info=font(f,10)
  info:SetPoint('TOPLEFT',f,'TOPLEFT',8,-24)
  local m={hud=f,title=title,info=info,rows={},elapsed=0,preview=false,
    resizing=false,dragging=false,visibleCount=0}
  self.meters[index]=m
  local hudKey=index==1 and 'threatwatch' or 'threatwatch2'
  WG:RegisterHUDFrame(hudKey,f,'Threat Watch '..index)
  f:SetMovable(true)
  f:SetClampedToScreen(true)
  f:SetResizable(true)
  if f.SetResizeBounds then f:SetResizeBounds(180,46,540,550)
  else
    if f.SetMinResize then f:SetMinResize(180,46) end
    if f.SetMaxResize then f:SetMaxResize(540,550) end
  end
  -- Standalone, Tiny Threat-style lock/unlock: no global Edit Mode required.
  local handle=CreateFrame('Button',nil,f)
  handle:SetPoint('TOPLEFT',f,'TOPLEFT',0,0)
  handle:SetPoint('TOPRIGHT',f,'TOPRIGHT',0,0)
  handle:SetHeight(22)
  handle:EnableMouse(true)
  handle:RegisterForDrag('LeftButton')
  handle:SetScript('OnDragStart',function()
    if not WG:Protected() and T:Settings(index).unlocked then
      m.dragging=true;f:StartMoving()
    end
  end)
  handle:SetScript('OnDragStop',function()
    if m.dragging then
      f:StopMovingOrSizing();m.dragging=false
      WG:SaveHUDPosition(hudKey,f)
    end
  end)
  local grip=CreateFrame('Button',nil,f)
  grip:SetSize(24,24)
  grip:SetPoint('BOTTOMRIGHT',f,'BOTTOMRIGHT',0,0)
  grip:SetFrameLevel(f:GetFrameLevel()+10)
  local line1=grip:CreateTexture(nil,'OVERLAY')
  line1:SetColorTexture(.92,.69,.31,1)
  line1:SetPoint('BOTTOMRIGHT',grip,'BOTTOMRIGHT',-3,4)
  line1:SetSize(13,2)
  local line2=grip:CreateTexture(nil,'OVERLAY')
  line2:SetColorTexture(.92,.69,.31,1)
  line2:SetPoint('BOTTOMRIGHT',grip,'BOTTOMRIGHT',-3,4)
  line2:SetSize(2,13)
  grip:SetScript('OnEnter',function()
    GameTooltip:SetOwner(grip,'ANCHOR_TOP')
    GameTooltip:SetText('Drag to resize Threat Watch',1,.9,.7)
    GameTooltip:AddLine('Width and maximum row count are saved independently.',.8,.8,.8)
    GameTooltip:Show()
  end)
  grip:SetScript('OnLeave',function()GameTooltip:Hide()end)
  grip:SetScript('OnMouseDown',function()
    if WG:Protected() or not T:Settings(index).unlocked then return end
    m.resizing=true
    f:StartSizing('BOTTOMRIGHT')
  end)
  grip:SetScript('OnMouseUp',function()
    if not m.resizing then return end
    f:StopMovingOrSizing()
    local o=T:Settings(index)
    local w,h=f:GetSize()
    o.width=clamp(math.floor(w+.5),180,540)
    -- The grip sets the maximum rows, not the row height. This avoids the
    -- old 8-row minimum that made small/empty meters impossible to resize.
    o.rows=clamp(math.floor((h-24)/(o.rowHeight+2)+.5),1,12)
    m.resizing=false
    WG:SaveHUDPosition(hudKey,f)
    T:Update(index)
    if WG.studio and WG.studio.Refresh then WG.studio:Refresh() end
  end)
  m.dragHandle=handle
  m.resizeGrip=grip
  f:SetScript('OnUpdate',function(_,dt)
    if not WG.db or m.resizing or m.dragging then return end
    m.elapsed=m.elapsed+dt
    local o=T:Settings(index)
    local speed=clamp(tonumber(o.speed) or .5,.2,2)
    if m.elapsed>=speed then m.elapsed=0;T:Update(index) end
  end)
  for i=1,12 do self:MakeRow(m,i) end
  WG.surfaces[#WG.surfaces+1]={repaint=function()
    local style=WG:StyleName()
    local o=T:Settings(index)
    local modern=style=='Modern'
    local tactical=style=='Tactical'
    local adventure=style=='Adventure'
    local c=WG:Color('accent')
    local panelOpacity=math.max(0,math.min(1,tonumber(o.frameOpacity) or .52))
    -- Four visual skins with a shared data source: Details! Tiny Threat when enabled.
    meterSkin.bg:SetAlpha((tactical and .12 or (modern and .24 or (adventure and .42 or panelOpacity)))*panelOpacity/.52)
    meterSkin.edge:SetAlpha(tactical and .06 or (modern and .18 or (adventure and .35 or .64)))
    if meterSkin.grain then meterSkin.grain:SetAlpha(style=='Classic' and .24 or 0) end
    title:SetText(style=='Classic' and (index==1 and 'WAFFLES THREAT' or 'WAFFLES THREAT 2')
      or style=='Modern' and (index==1 and 'THREAT / ONE' or 'THREAT / TWO')
      or style=='Tactical' and (index==1 and 'AGGRO 01' or 'AGGRO 02')
      or (index==1 and 'THREAT LEDGER' or 'THREAT LEDGER II'))
    local headerY=tactical and -3 or (modern and -4 or (adventure and -5 or -6))
    title:ClearAllPoints();title:SetPoint('TOPLEFT',m.hud,'TOPLEFT',6,headerY)
    title:SetFont(WG:StyleFont(11),11,style=='Classic' and 'OUTLINE' or '')
    title:SetTextColor(c[1],c[2],c[3])
    title:SetShown(o.showTitle~=false)
    info:ClearAllPoints()
    info:SetPoint('TOPRIGHT',m.hud,'TOPRIGHT',-6,tactical and -3 or -5)
    info:SetWidth((o.width or 252)*.62);info:SetJustifyH('RIGHT')
    info:SetFont(WG:StyleFont(9),9,'')
    info:SetTextColor(.70,.76,.73)
    for _,r in ipairs(m.rows) do
      r.track:SetAlpha(tactical and .10 or (modern and .17 or (adventure and .25 or .48)))
      r.left:SetFont(WG:StyleFont(11),11,style=='Classic' and 'OUTLINE' or '')
      r.right:SetFont(WG:StyleFont(10),10,'')
      r.left:SetTextColor(1,.98,.93);r.right:SetTextColor(1,.98,.93)
      r:SetAlpha(math.max(.25,math.min(1,tonumber(o.barOpacity) or .80)))
    end
  end}
  self:Arrange(index,0)
  f:Hide()
end
function T:Arrange(index,visibleRows)
  if not index then for i=1,2 do self:Arrange(i) end;return end
  local m=self.meters[index]
  if not m or m.resizing then return end
  local o=self:Settings(index)
  o.width=clamp(tonumber(o.width) or 252,180,540)
  o.rows=clamp(tonumber(o.rows) or 6,1,12)
  o.rowHeight=clamp(tonumber(o.rowHeight) or 17,14,30)
  local style=WG:StyleName()
  local lineHeight=o.compactRows and math.min(o.rowHeight,18) or o.rowHeight
  if style=='Tactical' and WG:TacticalSettings().compactThreat then lineHeight=math.min(lineHeight,20) end
  local top=(o.showTitle==false) and 5 or ((style=='Classic') and 24 or (style=='Adventure' and 23 or 20))
  local pad=style=='Tactical' and 3 or 5
  local visible=math.min(o.rows,math.max(0,tonumber(visibleRows) or m.visibleCount or 0))
  local rendered=o.autoFit and visible or o.rows
  local targetHeight=math.max(top+3,top+rendered*(lineHeight+2)+4)
  m.hud:SetSize(o.width,targetHeight)
  m.title:SetShown(o.showTitle~=false)
  m.info:SetShown(o.showTitle~=false)
  for i,r in ipairs(m.rows) do
    r:ClearAllPoints()
    r:SetPoint('TOPLEFT',m.hud,'TOPLEFT',pad,-top-(i-1)*(lineHeight+2))
    r:SetSize(o.width-2*pad,lineHeight)
    r.left:SetWidth(math.max(70,o.width-118))
    r:SetShown(i<=visible)
  end
end
function T:Update(index)
  if not index then for i=1,2 do self:Update(i) end;return end
  local m=self.meters[index]
  if not m or not WG.db or m.resizing or m.dragging then return end
  local o=self:Settings(index)
  -- Keep our own Waffle panels visible; replace the data, not the artwork.
  local detailsSource=WG.threatCompanion and WG.threatCompanion:UsingTinyThreat()
  local testing=m.preview or o.unlocked or WG.editMode
  m.dragHandle:SetShown(o.unlocked and not WG.editMode)
  m.resizeGrip:SetShown(o.unlocked and not WG.editMode)
  if not o.enabled and not testing then m.hud:Hide();return end
  local outOfCombat=o.showOnlyCombat and not testing and UnitAffectingCombat
    and not UnitAffectingCombat('player')
  if outOfCombat and (not o.showPlayer or o.hideEmpty) then
    m.hud:Hide();return
  end
  local rows,info
  if outOfCombat then
    rows={self:WaitingRow()}
    info='No combat threat'
  elseif m.preview then
    rows={}
    -- Editing shows the configured maximum, so the resize grip can change
    -- capacity precisely; ordinary play shows ONLY actual populated rows.
    for n=1,clamp(tonumber(o.rows) or 8,1,12) do
      rows[n]={name=n==1 and 'Deputy Waffles' or ('Preview member '..n),
        percent=math.max(10,110-n*11),amount=100-n,tanking=n==1,role='DAMAGER'}
    end
    info='PREVIEW DATA - lock meter for live Details values'
  elseif detailsSource then
    rows,info=WG.threatCompanion:ReadThreatRows(index)
  else
    rows,info=self:Collect(index)
  end
  local count=math.min(#rows,clamp(tonumber(o.rows) or 8,1,12))
  m.visibleCount=count
  if o.hideEmpty and (count==0 or (#rows==1 and rows[1].waiting)) and not testing then m.hud:Hide();return end
  m.hud:Show()
  local targetName=safeName(self:GetTarget(index))
  m.info:SetText(info or ((detailsSource and 'DETAILS / ' or 'NATIVE / ')..
    (targetName and (targetName:sub(1,17)) or 'NO TARGET')))
  self:Arrange(index,count)
  local maxValue=100
  for i=1,count do
    local item=rows[i]
    if number(item.percent) and item.percent>maxValue then maxValue=item.percent end
  end
  for i,r in ipairs(m.rows) do
    local item=i<=count and rows[i] or nil
    if item then
      r:Show()
      r.left:SetText(item.name)
      if item.waiting then
        r.right:SetText('WAITING')
        r:SetValue(0) -- a visually empty bar; no numeric threat is claimed
        r:SetStatusBarColor(.35,.39,.45)
      else
        if item.fromDetails then
          r.right:SetText(o.detailsShowAmounts~=false and item.label or string.format('%.1f%%',item.percent))
          -- Details! provides the displayed percentage; don't normalize against
          -- our own highest player, which was causing a divergent bar length.
          r:SetValue(clamp(item.percent,0,100))
        else
          r.right:SetText(o.showAmounts and number(item.amount)
            and string.format('%.0f%% / %.0f',item.percent,item.amount) or string.format('%.0f%%',item.percent))
          r:SetValue(clamp(item.percent/maxValue*100,0,100))
        end
      end
      if item.waiting then
        -- Keep a neutral bar until the game exposes real threat.
      elseif o.classColors and item.class and RAID_CLASS_COLORS and RAID_CLASS_COLORS[item.class] then
        local c=RAID_CLASS_COLORS[item.class]
        r:SetStatusBarColor(c.r,c.g,c.b)
      elseif item.tanking then r:SetStatusBarColor(.29,.82,.34)
      elseif item.percent>=90 then r:SetStatusBarColor(1,.3,.24)
      elseif item.percent>=70 then r:SetStatusBarColor(1,.74,.24)
      else
        local c=WG:Color('accent')
        r:SetStatusBarColor(c[1],c[2],c[3])
      end
    else r:Hide() end
  end
end
-- The single Waffle Studio editor owns Threat Watch settings. There is no
-- second, inconsistent set of controls in a separate pop-up window.
function T:RefreshOptions()
  if WG.studio and WG.studio.current=='THREAT' and WG.studio.Refresh then
    WG.studio:Refresh()
  end
end
function T:Init()
  self:Settings(1);self:Settings(2)
  self:MakeHUD(1);self:MakeHUD(2)
  for _,event in ipairs({'PLAYER_TARGET_CHANGED','PLAYER_FOCUS_CHANGED','GROUP_ROSTER_UPDATE','PLAYER_REGEN_DISABLED','PLAYER_REGEN_ENABLED'}) do
    WG:On(event,function()T:Update()end)
  end
end
function T:Refresh()
  if not WG.db or not self.meters[1] then return end
  self:Arrange();self:Update();self:RefreshOptions()
end
