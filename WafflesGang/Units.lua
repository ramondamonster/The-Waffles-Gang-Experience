-- Original secure unit buttons, redesigned shell. Secrets are sent straight to bars.
local WG=_G.WafflesGang
local U={name='Unit Frames',units={},raid={},byUnit={}}
table.insert(WG.modules,U)
local media='Interface\\AddOns\\WafflesGang\\Media\\'
local function classColor(unit)
  if not WG:Enabled('classcolors') then return WG:Color('accent') end
  local _,class=UnitClass(unit)
  local t=class and RAID_CLASS_COLORS and RAID_CLASS_COLORS[class]
  if t then return {t.r,t.g,t.b} end
  return WG:Color('accent')
end
local function chrome(parent,scale)
  local t=parent:CreateTexture(nil,'OVERLAY')
  t:SetAllPoints();t:SetTexture(media..'unit_chrome')
  local function repaint()
    local style=WG:StyleName()
    t:SetTexture(style=='Classic' and media..'unit_chrome' or (media..'UIStyles\\'..style..'Unit'))
    local c=WG:Color('accent')
    t:SetVertexColor(c[1],c[2],c[3],style=='Classic' and .65 or ((style=='Modern' or style=='Tactical') and 0 or .9))
  end
  table.insert(WG.surfaces,{repaint=repaint});repaint()
  return t
end
function U:Unit(parent,unit,width,height,where,x,y)
  local button=CreateFrame('Button','WGUnit_'..unit,parent or UIParent,'SecureUnitButtonTemplate')
  button:SetSize(width,height)
  button:SetPoint(where or 'CENTER',parent or UIParent,where or 'CENTER',x or 0,y or 0)
  button:SetAttribute('unit',unit);button:SetAttribute('type1','target');button:SetAttribute('type2','menu')
  button:RegisterForClicks('AnyUp','AnyDown')
  local unitSkin=WG:Surface(button,'bg','edge')
  -- An actual unit portrait, a real health display and a narrow resource bar.
  local raid=unit:match('^raid')~=nil
  local party=unit:match('^party')~=nil
  local large=height>=62
  local portrait,portraitEdges
  if not raid then
    portraitEdges={}
    portrait=button:CreateTexture(nil,'ARTWORK')
    local inset=large and 5 or 3
    local sz=large and height-12 or height-6
    portrait:SetPoint('TOPLEFT',button,'TOPLEFT',inset,-inset)
    portrait:SetSize(sz,sz)
    portrait:SetTexture('Interface\\Icons\\INV_Misc_QuestionMark')
    portrait:SetTexCoord(.08,.92,.08,.92)
    -- Keep the actual live unit portrait in both looks. Modern uses a soft
    -- circular mask rather than removing the portrait altogether.
    if button.CreateMaskTexture and portrait.AddMaskTexture then
      local portraitMask=button:CreateMaskTexture(nil,'ARTWORK')
      portraitMask:SetAllPoints(portrait)
      if pcall(portrait.AddMaskTexture,portrait,portraitMask) then
        table.insert(WG.surfaces,{repaint=function()
          portraitMask:SetTexture(media..'Modern\\'..(WG:StyleName()=='Modern' and 'CirclePortrait' or 'SquarePortrait'))
        end})
      end
    end
    local edges={
      {'TOPLEFT','TOPLEFT',-2,2,sz+4,2},
      {'BOTTOMLEFT','BOTTOMLEFT',-2,-2,sz+4,2},
      {'TOPLEFT','TOPLEFT',-2,2,2,sz+4},
      {'TOPRIGHT','TOPRIGHT',2,2,2,sz+4},
    }
    for _,e in ipairs(edges) do
      local edge=button:CreateTexture(nil,'OVERLAY')
      edge:SetPoint(e[1],portrait,e[2],e[3],e[4]);edge:SetSize(e[5],e[6])
      local function repaint()
        local c=WG:Color('accent');edge:SetColorTexture(c[1],c[2],c[3],.82)
      end
      table.insert(WG.surfaces,{repaint=repaint});repaint()
      portraitEdges[#portraitEdges+1]=edge
    end
  end
  local offset=raid and 5 or (large and height-2 or height+3)
  local barWidth=width-offset-7
  local health=CreateFrame('StatusBar',nil,button)
  health:SetStatusBarTexture('Interface\\Buttons\\WHITE8X8')
  health:SetPoint('TOPLEFT',button,'TOPLEFT',offset,large and -26 or (party and -23 or -5))
  health:SetSize(barWidth,large and 21 or (party and 16 or (raid and 24 or 19)))
  health:SetMinMaxValues(0,1);health:SetValue(1)
  local hb=health:CreateTexture(nil,'BACKGROUND')
  hb:SetAllPoints();hb:SetColorTexture(.08,.08,.08,.82)
  local mana=CreateFrame('StatusBar',nil,button)
  mana:SetStatusBarTexture('Interface\\Buttons\\WHITE8X8')
  mana:SetPoint('TOPLEFT',health,'BOTTOMLEFT',0,-3)
  mana:SetSize(barWidth,raid and 5 or (large and 12 or (party and 5 or 6)))
  mana:SetStatusBarColor(.22,.43,.82)
  mana:SetMinMaxValues(0,1);mana:SetValue(1)
  local powerBg=mana:CreateTexture(nil,'BACKGROUND');powerBg:SetAllPoints()
  powerBg:SetColorTexture(.07,.10,.17,.8)
  local name=button:CreateFontString(nil,'OVERLAY','GameFontNormalSmall')
  name:SetFont(STANDARD_TEXT_FONT or 'Fonts\\FRIZQT__.TTF',large and 13 or (raid and 10 or 11),'OUTLINE')
  if large or party then
    name:SetPoint('TOPLEFT',button,'TOPLEFT',offset,party and -6 or -7)
  else
    name:SetPoint('LEFT',health,'LEFT',5,0)
  end
  name:SetJustifyH('LEFT');name:SetWidth(large and barWidth-45 or barWidth-50)
  -- Party/raid and the larger player/target/focus bars use native percentage
  -- APIs. Never divide combat-sensitive raw health/power values in Lua.
  local healthPercent=health:CreateFontString(nil,'OVERLAY','GameFontNormalSmall')
  healthPercent:SetFont(STANDARD_TEXT_FONT or 'Fonts\\FRIZQT__.TTF',large and 11 or 10,'OUTLINE')
  healthPercent:SetPoint('RIGHT',health,'RIGHT',-5,0)
  healthPercent:SetJustifyH('RIGHT')
  healthPercent:SetWidth(large and 67 or 44)
  healthPercent:SetTextColor(1,.96,.83)
  local powerPercent
  if unit=='player' then
    powerPercent=mana:CreateFontString(nil,'OVERLAY','GameFontNormalSmall')
    powerPercent:SetFont(STANDARD_TEXT_FONT or 'Fonts\\FRIZQT__.TTF',9,'OUTLINE')
    powerPercent:SetPoint('RIGHT',mana,'RIGHT',-5,0)
    powerPercent:SetJustifyH('RIGHT')
    powerPercent:SetWidth(85)
    powerPercent:SetTextColor(1,1,1)
  end
  local level
  if large or party then
    level=button:CreateFontString(nil,'OVERLAY','GameFontNormalSmall')
    level:SetPoint('TOPRIGHT',button,'TOPRIGHT',-10,party and -6 or -8)
    level:SetFont(STANDARD_TEXT_FONT or 'Fonts\\FRIZQT__.TTF',10,'OUTLINE')
    level:SetTextColor(.95,.86,.56)
  end
  chrome(button)
  local groupLabel,aggroEdges
  if party then
    groupLabel=button:CreateFontString(nil,'OVERLAY','GameFontNormalSmall')
    groupLabel:SetFont(STANDARD_TEXT_FONT or 'Fonts\\FRIZQT__.TTF',9,'OUTLINE')
    groupLabel:SetPoint('BOTTOMRIGHT',button,'BOTTOMRIGHT',-7,4)
    groupLabel:SetTextColor(1,.86,.55)
    aggroEdges={}
    for _,edge in ipairs({'TOP','BOTTOM','LEFT','RIGHT'}) do
      local line=button:CreateTexture(nil,'OVERLAY')
      line:SetColorTexture(1,.21,.12,.94)
      if edge=='TOP' then line:SetPoint('TOPLEFT',button,'TOPLEFT',0,0);line:SetPoint('TOPRIGHT',button,'TOPRIGHT',0,0);line:SetHeight(2)
      elseif edge=='BOTTOM' then line:SetPoint('BOTTOMLEFT',button,'BOTTOMLEFT',0,0);line:SetPoint('BOTTOMRIGHT',button,'BOTTOMRIGHT',0,0);line:SetHeight(2)
      elseif edge=='LEFT' then line:SetPoint('TOPLEFT',button,'TOPLEFT',0,0);line:SetPoint('BOTTOMLEFT',button,'BOTTOMLEFT',0,0);line:SetWidth(2)
      else line:SetPoint('TOPRIGHT',button,'TOPRIGHT',0,0);line:SetPoint('BOTTOMRIGHT',button,'BOTTOMRIGHT',0,0);line:SetWidth(2) end
      line:Hide();aggroEdges[#aggroEdges+1]=line
    end
  end
  -- Modern is a completely different HUD composition, not a recolored
  -- portrait frame. It uses full-width flush bars, a typography-first header,
  -- and no portrait or ornamental frame. The secure unit button, health API,
  -- click behavior and saved screen position remain exactly the same.
  local tacticalAccent=button:CreateTexture(nil,'OVERLAY')
  tacticalAccent:SetPoint('TOPLEFT',button,'TOPLEFT',3,-3)
  tacticalAccent:SetWidth(3)
  tacticalAccent:SetPoint('BOTTOMLEFT',button,'BOTTOMLEFT',3,3)
  local tacticalTag=button:CreateFontString(nil,'OVERLAY','GameFontNormalSmall')
  tacticalTag:SetPoint('TOPLEFT',button,'TOPLEFT',raid and 7 or (portrait and (large and height-3 or height+4) or 10),-6)
  tacticalTag:SetJustifyH('LEFT')
  tacticalTag:SetFont(WG:StyleFont(9),9,'')
  local unitType=unit=='player' and 'P / OPERATIVE' or unit=='target' and 'T / CONTACT'
    or unit=='focus' and 'F / PRIORITY' or party and 'SQUAD / '..unit:sub(6)
    or raid and 'RAID / '..unit:sub(5) or 'UNIT'
  tacticalTag:SetText(unitType)
  local wayfinderRule=button:CreateTexture(nil,'OVERLAY')
  wayfinderRule:SetPoint('TOPLEFT',button,'TOPLEFT',9,-2)
  wayfinderRule:SetPoint('TOPRIGHT',button,'TOPRIGHT',-8,-2)
  wayfinderRule:SetHeight(1)
  local wayfinderMark=button:CreateTexture(nil,'OVERLAY')
  wayfinderMark:SetPoint('TOPLEFT',button,'TOPLEFT',0,-5)
  wayfinderMark:SetSize(6,25)
  wayfinderMark:SetTexture('Interface\\Buttons\\WHITE8X8')
  local modernLabel=button:CreateTexture(nil,'OVERLAY')
  modernLabel:SetPoint('TOPLEFT',button,'TOPLEFT',10,-3)
  modernLabel:SetSize(2,13)
  local function layoutStyle()
    if WG:Protected() then return end
    local style=WG:StyleName()
    local modern=style=='Modern'
    local tactical=style=='Tactical'
    local adventure=style=='Adventure'
    local tc=tactical and WG:TacticalSettings() or nil
    if portrait then portrait:SetShown(not adventure and (not tactical or tc.showPortraits~=false)) end
    if portraitEdges then
      for _,border in ipairs(portraitEdges) do border:SetShown(not modern and not tactical and not adventure) end
    end
    local accent=WG:Color('accent')
    tacticalAccent:SetColorTexture(accent[1],accent[2],accent[3],.95)
    tacticalAccent:SetShown(tactical)
    tacticalTag:SetShown(tactical and not raid)
    wayfinderRule:SetShown(adventure)
    wayfinderRule:SetColorTexture(accent[1],accent[2],accent[3],.75)
    wayfinderMark:SetShown(adventure and not raid)
    wayfinderMark:SetVertexColor(accent[1],accent[2],accent[3],.85)
    tacticalTag:SetTextColor(accent[1],accent[2],accent[3])
    unitSkin.bg:SetAlpha((modern or adventure) and 0 or (tactical and .97 or 1))
    unitSkin.edge:SetAlpha((modern or tactical or adventure) and 0 or 1)
    health:ClearAllPoints()
    mana:ClearAllPoints()
    name:ClearAllPoints()
    local tex=modern and (media..'Modern\\SoftBar') or 'Interface\\Buttons\\WHITE8X8'
    health:SetStatusBarTexture(tex)
    mana:SetStatusBarTexture(tex)
    local portraitOffset=portrait and (large and height-5 or height+1) or 12
    local startX=adventure and 10 or (modern and portraitOffset or (tactical and (raid and 8 or (portrait and tc.showPortraits~=false and portraitOffset or 12)) or offset))
    local w=(modern or tactical or adventure) and math.max(35,width-startX-11) or barWidth
    local top=adventure and (raid and -22 or (large and -31 or (party and -26 or -22))) or (tactical and (raid and -17 or (large and -30 or -26)) or (large and -26 or (party and -23 or -5)))
    local hh=large and 21 or (party and 16 or (raid and 24 or 19))
    health:SetPoint('TOPLEFT',button,'TOPLEFT',startX,top)
    health:SetSize(w,adventure and (raid and 12 or (large and 16 or 12)) or (tactical and (raid and 19 or (large and 18 or 14)) or (modern and (raid and 15 or math.max(8,hh-4)) or hh)))
    mana:SetPoint('TOPLEFT',health,'BOTTOMLEFT',0,(modern or tactical or adventure) and -2 or -3)
    mana:SetSize(w,adventure and (raid and 3 or (large and 5 or 4)) or (tactical and (raid and 4 or (large and 7 or 5)) or (modern and (raid and 3 or (large and 5 or 4)) or (raid and 5 or (large and 12 or (party and 5 or 6))))))
    if adventure then
      name:SetPoint('TOPLEFT',button,'TOPLEFT',12,large and -11 or -7)
      name:SetWidth(math.max(42,w-(raid and 8 or 48)))
    elseif tactical then
      name:SetPoint('TOPLEFT',button,'TOPLEFT',startX,large and -16 or -12)
      name:SetWidth(w-47)
    elseif modern then
      name:SetPoint('TOPLEFT',button,'TOPLEFT',startX,large and -8 or (party and -6 or -5))
      name:SetWidth(w-50)
    elseif large or party then
      name:SetPoint('TOPLEFT',button,'TOPLEFT',offset,party and -6 or -7)
      name:SetWidth(large and barWidth-45 or barWidth-50)
    else
      name:SetPoint('LEFT',health,'LEFT',5,0)
      name:SetWidth(barWidth-50)
    end
    local c=WG:Color('accent')
    modernLabel:SetColorTexture(c[1],c[2],c[3],1)
    modernLabel:SetShown(modern and not raid and not portrait)
    local font=WG:StyleFont(12)
    pcall(name.SetFont,name,font,adventure and (large and 13 or 11) or (tactical and (large and 13 or 11) or (large and 12 or 10)),(modern or tactical) and '' or 'OUTLINE')
    if level then
      pcall(level.SetFont,level,font,10,modern and '' or 'OUTLINE')
    end
    pcall(healthPercent.SetFont,healthPercent,font,tactical and 11 or (modern and 10 or (large and 11 or 10)),(modern or tactical) and '' or 'OUTLINE')
    if powerPercent then
      pcall(powerPercent.SetFont,powerPercent,font,9,modern and '' or 'OUTLINE')
    end
    if adventure then
      hb:SetColorTexture(.06,.075,.06,.84)
      powerBg:SetColorTexture(.06,.09,.07,.73)
    elseif tactical then
      hb:SetColorTexture(.015,.020,.023,.94)
      powerBg:SetColorTexture(.018,.035,.044,.90)
    elseif modern then
      -- Small, understated track for light-on-dark raid clarity.
      hb:SetColorTexture(.08,.10,.14,.36)
      powerBg:SetColorTexture(.04,.08,.13,.43)
    else
      hb:SetColorTexture(.08,.08,.08,.82)
      powerBg:SetColorTexture(.07,.10,.17,.8)
    end
  end
  table.insert(WG.surfaces,{repaint=layoutStyle})
  layoutStyle()
  local p={button=button,unit=unit,health=health,mana=mana,name=name,portrait=portrait,level=level,healthPercent=healthPercent,powerPercent=powerPercent,groupLabel=groupLabel,aggroEdges=aggroEdges}
  table.insert(self.units,p);self.byUnit[unit]=p
  return p
end
-- Percent APIs yield display-scaled values on Forever. Passing the result
-- straight to a FontString formatter avoids manipulating protected raw values.
local function displayHealthPercent(p)
  local f=p.healthPercent
  if not f then return end
  local isGroup=p.unit:match('^party') or p.unit:match('^raid')
  local formatString=isGroup and '%.0f%%' or 'HP %.0f%%'
  local enabled=WG:Enabled(isGroup and 'healthpercent' or 'unitpercent')
  f:SetShown(enabled)
  if not enabled then return end
  if UnitHealthPercent and CurveConstants and CurveConstants.ScaleTo100 then
    local ok,value=pcall(UnitHealthPercent,p.unit,true,CurveConstants.ScaleTo100)
    if ok then
      local formatted=pcall(f.SetFormattedText,f,formatString,value)
      if formatted then return end
    end
  end
  -- Older clients without UnitHealthPercent: calculate only outside combat,
  -- and only if neither number is protected/secret.
  if not WG:Protected() and UnitHealth and UnitHealthMax then
    local ok,h,m=pcall(function()return UnitHealth(p.unit),UnitHealthMax(p.unit)end)
    if ok and not (issecretvalue and (issecretvalue(h) or issecretvalue(m)))
       and type(h)=='number' and type(m)=='number' and m>0 then
      f:SetFormattedText(formatString,h*100/m)
      return
    end
  end
  f:SetText(isGroup and '--%' or 'HP --%')
end
local powerLabels={[0]='MP',[1]='RAGE',[2]='FOCUS',[3]='ENERGY',[6]='RUNIC'}
local function displayPlayerPowerPercent(p)
  local f=p.powerPercent
  if not f then return end
  local enabled=WG:Enabled('unitpercent') and WG:Enabled('unitpower')
  f:SetShown(enabled)
  if not enabled then return end
  local label='MP'
  if UnitPowerType then
    local ok,kind=pcall(UnitPowerType,p.unit)
    if ok and not (issecretvalue and issecretvalue(kind)) then
      label=powerLabels[kind] or 'POWER'
    end
  end
  if UnitPowerPercent then
    local curve=CurveConstants and CurveConstants.ScaleTo100 or nil
    -- Modern Forever signature: (unit, powerType, unmodified, curve).
    local ok,value=pcall(UnitPowerPercent,p.unit,nil,false,curve)
    if ok and pcall(f.SetFormattedText,f,label..' %.0f%%',value) then return end
  end
  if not WG:Protected() and UnitPower and UnitPowerMax then
    local ok,n,m=pcall(function()return UnitPower(p.unit),UnitPowerMax(p.unit)end)
    if ok and not (issecretvalue and (issecretvalue(n) or issecretvalue(m)))
       and type(n)=='number' and type(m)=='number' and m>0 then
      f:SetFormattedText(label..' %.0f%%',n*100/m)
      return
    end
  end
  f:SetText(label..' --%')
end
local function readable(v) return not (issecretvalue and issecretvalue(v)) end
local partyDefaults={scale=1,spacing=5,growth='VERTICAL',roles=true,levels=true,status=true,threat=true}
function U:PartySettings()
  if not WG.db then return partyDefaults end
  if type(WG.db.partyStudio)~='table' then WG.db.partyStudio={} end
  local o=WG.db.partyStudio
  for k,v in pairs(partyDefaults) do if o[k]==nil then o[k]=v end end
  return o
end
function U:ApplyPartyLayout()
  if WG:Protected() or not self.partyAnchor then return end
  local o=self:PartySettings()
  local spacing=math.max(1,math.min(20,tonumber(o.spacing) or 5))
  local scale=math.max(.65,math.min(1.4,tonumber(o.scale) or 1))
  local horizontal=o.growth=='HORIZONTAL'
  self.partyAnchor:SetSize(horizontal and (4*248+3*spacing) or 258,horizontal and 54 or (4*54+3*spacing))
  self.partyAnchor:SetScale(scale)
  for i=1,4 do
    local row=self.byUnit['party'..i]
    if row then
      row.button:ClearAllPoints()
      row.button:SetPoint('TOPLEFT',self.partyAnchor,'TOPLEFT',horizontal and ((i-1)*(248+spacing)) or 0,horizontal and 0 or -((i-1)*(54+spacing)))
    end
  end
end
local function callBool(fn,...)
  if not fn then return false end
  local ok,val=pcall(fn,...)
  return ok and readable(val) and val==true
end
function U:UpdateGroupIndicators(p)
  if not p.groupLabel then return end
  local opts=self:PartySettings()
  local status={}
  local offline=false
  if opts.status and UnitIsConnected then
    local ok,connected=pcall(UnitIsConnected,p.unit)
    offline=ok and readable(connected) and connected==false
  end
  if offline then
    status[#status+1]='OFFLINE'
  elseif opts.status and callBool(UnitIsDeadOrGhost,p.unit) then status[#status+1]='DEAD'
  elseif opts.status and GetReadyCheckStatus then
    local ok,ready=pcall(GetReadyCheckStatus,p.unit)
    if ok and readable(ready) and ready=='ready' then status[#status+1]='READY'
    elseif ok and readable(ready) and ready=='notready' then status[#status+1]='NOT READY' end
  end
  if opts.status and callBool(UnitIsGroupLeader,p.unit) then status[#status+1]='LEADER' end
  local alert=false
  if opts.threat and UnitThreatSituation and UnitExists and UnitExists('target') and callBool(UnitCanAttack,'player','target') then
    local ok,val=pcall(UnitThreatSituation,p.unit,'target')
    alert=ok and readable(val) and type(val)=='number' and val>=2
  end
  if alert then status[#status+1]='AGGRO' end
  p.groupLabel:SetText(table.concat(status,' / '))
  p.groupLabel:SetShown(opts.status or opts.threat)
  if p.aggroEdges then for _,edge in ipairs(p.aggroEdges) do edge:SetShown(alert) end end
  if p.level and not WG:Protected() then p.level:SetShown(opts.levels) end
  if p.level and opts.roles then
    local role=''
    if UnitGroupRolesAssigned then
      local ok,val=pcall(UnitGroupRolesAssigned,p.unit)
      if ok and readable(val) then role=({TANK='T',HEALER='H',DAMAGER='D'})[val] or '' end
    end
    if role~='' then
      local lev=''
      if opts.levels and UnitLevel then
        local ok,l=pcall(UnitLevel,p.unit);if ok and readable(l) and type(l)=='number' and l>0 then lev=' '..l end
      end
      p.level:SetText(role..lev)
      if not WG:Protected() then p.level:Show() end
    end
  elseif p.level and not opts.levels and not WG:Protected() then p.level:Hide() end
end
function U:UpdateOne(p)
  if not p or not UnitExists(p.unit) then return end
  -- Direct widget setters accept secret values; no arithmetic or branching on health.
  p.health:SetStatusBarColor(WG.unpack(classColor(p.unit)))
  p.health:SetMinMaxValues(0,UnitHealthMax(p.unit))
  p.health:SetValue(UnitHealth(p.unit))
  p.mana:SetMinMaxValues(0,UnitPowerMax(p.unit))
  p.mana:SetValue(UnitPower(p.unit))
  if not WG:Protected() then p.mana:SetShown(WG:Enabled('unitpower')) end
  local name=GetUnitName and GetUnitName(p.unit,false) or p.unit
  p.name:SetText(name or p.unit)
  p.name:SetTextColor(WG.unpack(WG:Color('text')))
  displayHealthPercent(p)
  displayPlayerPowerPercent(p)
  if p.portrait and SetPortraitTexture then
    pcall(SetPortraitTexture,p.portrait,p.unit)
  end
  if p.level and not WG:Protected() and UnitLevel then
    local ok,lev=pcall(UnitLevel,p.unit)
    if ok and readable(lev) and type(lev)=='number' and lev>0 then p.level:SetText('LV '..lev)
    else p.level:SetText('') end
  end
  if p.groupLabel then self:UpdateGroupIndicators(p) end
end
function U:Update(unit)
  if not WG.db then return end
  if unit then
    self:UpdateOne(self.byUnit[unit]);return
  end
  for _,p in ipairs(self.units) do self:UpdateOne(p) end
end
function U:Visibility()
  if WG:Protected() then return end
  local exists=UnitExists or function()return true end
  for _,p in ipairs(self.units) do
    local unit=p.unit
    local enabled
    if unit=='player' then enabled=WG:Enabled('playerframe')
    elseif unit=='target' then enabled=WG:Enabled('targetframe')
    elseif unit=='focus' then enabled=WG:Enabled('focusframe')
    elseif unit:match('^party') then
      enabled=WG:Enabled('partyframes') and (IsInGroup and IsInGroup()) and not (IsInRaid and IsInRaid())
    elseif unit:match('^raid') then enabled=WG:Enabled('raidframes') and (IsInRaid and IsInRaid()) end
    p.button:SetShown(not not enabled and exists(unit))
  end
end
function U:Blizzard()
  if WG:Protected() then return end
  if not self.original then self.original={} end
  local names={
    {'PlayerFrame','playerframe'},{'TargetFrame','targetframe'},{'FocusFrame','focusframe'},
    {'CompactPartyFrame','partyframes'},{'PartyFrame','partyframes'},
    {'CompactRaidFrameContainer','raidframes'},
  }
  for _,entry in ipairs(names) do
    local frame=_G[entry[1]]
    if frame and frame.SetAlpha then
      if self.original[frame]==nil then self.original[frame]=frame:GetAlpha() end
      local hide=WG:Enabled('replaceui') and WG:Enabled(entry[2])
      frame:SetAlpha(hide and 0 or (self.original[frame] or 1))
    end
  end
end
function U:Init()
  local player=self:Unit(UIParent,'player',274,72,'CENTER',-289,-220)
  local target=self:Unit(UIParent,'target',274,72,'CENTER',289,-220)
  local focus=self:Unit(UIParent,'focus',245,62,'CENTER',289,-306)
  WG:RegisterHUDFrame('playerframe',player.button,'Player Frame')
  WG:RegisterHUDFrame('targetframe',target.button,'Target Frame')
  WG:RegisterHUDFrame('focusframe',focus.button,'Focus Frame')
  local anchor=CreateFrame('Frame','WGPartyAnchor',UIParent)
  self.partyAnchor=anchor
  anchor:SetSize(258,234);anchor:SetPoint('LEFT',UIParent,'LEFT',36,0)
  WG:RegisterHUDFrame('partyframes',anchor,'Party Frames')
  for i=1,4 do self:Unit(anchor,'party'..i,248,54,'TOPLEFT',0,-(i-1)*59) end
  self:ApplyPartyLayout()
  local raid=CreateFrame('Frame','WGRaidAnchor',UIParent)
  raid:SetSize(565,406);raid:SetPoint('LEFT',UIParent,'LEFT',32,52)
  WG:RegisterHUDFrame('raidframes',raid,'Raid Frames')
  for i=1,40 do
    self:Unit(raid,'raid'..i,107,42,'TOPLEFT',((i-1)%5)*112,-math.floor((i-1)/5)*49)
  end
  local f=WG:Window('frames','Unit / Party / Raid Frames',518,684)
  WG:Text(f,'YOUR COMBAT FRAMES',24,-84,15,'accent')
  WG:Text(f,'A unified shell with portraits, health and resource bars.',24,-110,11,'text',455)
  local options={
    {'playerframe','Player frame'},{'targetframe','Target frame'},
    {'focusframe','Focus frame'},{'partyframes','Compact party frames'},
    {'raidframes','Raid frames (up to 40)'},{'classcolors','Class-colored health'},
    {'unitpower','Resource bars'},{'healthpercent','Party / raid health percentages'},
    {'unitpercent','Player HP / MP and target HP percentages'},
    {'levelcelebration','Dance + exploding waffles on level-up (OFF by default)'},
  }
  for i,opt in ipairs(options) do WG:Check(f,opt[1],opt[2],24,-145-(i-1)*37) end
  WG:Button(f,'PREVIEW WAFFLE BURST',24,-528,220,36,function()
    if WG.PreviewCelebration then WG:PreviewCelebration() end
  end)
  WG:Button(f,'BUFFS / DEBUFFS',24,-576,225,35,function()WG:Open('auras')end)
  WG:Button(f,'THREAT WATCH',264,-576,227,35,function()WG:Open('threat')end)
  WG:Text(f,'Aura controls are configured independently for each unit type.',24,-626,10,'text',465)
  WG:Text(f,'Protected frame layout changes wait until combat ends.',24,-649,10,'text',466)
  for _,event in ipairs({'GROUP_ROSTER_UPDATE','PLAYER_TARGET_CHANGED','PLAYER_FOCUS_CHANGED'}) do
    WG:On(event,function()U:Visibility();U:Update()end)
  end
  WG:On('UNIT_HEALTH',function(unit)U:Update(unit)end)
  WG:On('UNIT_MAXHEALTH',function(unit)U:Update(unit)end)
  WG:On('UNIT_POWER_UPDATE',function(unit)U:Update(unit)end)
  WG:On('UNIT_DISPLAYPOWER',function(unit)U:Update(unit)end)
  WG:On('UNIT_PORTRAIT_UPDATE',function(unit)U:Update(unit)end)
  for _,event in ipairs({'READY_CHECK','READY_CHECK_CONFIRM','READY_CHECK_FINISHED','UNIT_THREAT_LIST_UPDATE','UNIT_THREAT_SITUATION_UPDATE'}) do
    WG:On(event,function()U:Update()end)
  end
  WG:On('PLAYER_ENTERING_WORLD',function()U:Refresh()end)
  WG:On('PLAYER_REGEN_ENABLED',function()U:Refresh()end)
end
function U:Refresh()
  if not WG.db then return end
  self:ApplyPartyLayout();self:Visibility();self:Blizzard();self:Update()
end
