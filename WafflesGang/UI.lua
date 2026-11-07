-- Waffles Gang Guild Edition UI.  Presentation only: the original gameplay modules remain separate.
local WG=_G.WafflesGang
local U={name='Guild Interface'}
table.insert(WG.modules,U)
local media='Interface\\AddOns\\WafflesGang\\Media\\'
local function rgb(v) return WG.unpack(v) end
local function tint(texture,key,alpha)
  local function repaint()
    local c=WG:Color(key)
    texture:SetVertexColor(c[1],c[2],c[3],alpha or 1)
  end
  table.insert(WG.surfaces,{repaint=repaint});repaint()
end
local function textured(parent,file,layer,point,relative,relativePoint,x,y,w,h)
  local t=parent:CreateTexture(nil,layer or 'ARTWORK')
  t:SetTexture(media..file)
  t:SetSize(w,h)
  t:SetPoint(point,relative or parent,relativePoint or point,x or 0,y or 0)
  return t
end
local nativeIcons={}
for _,key in ipairs({'hub','party','loot','guild','group','frames','bars','bags','autoloot','appearance','settings','setup','layout','profiles','help'}) do
  nativeIcons[key]=media..'Icons\\'..key
end
nativeIcons.guild=media..'guild_crest'
nativeIcons.automation=nativeIcons.autoloot
nativeIcons.chat=nativeIcons.party
nativeIcons.professions=nativeIcons.guild
nativeIcons.gear=nativeIcons.bags
nativeIcons.rewards=nativeIcons.loot
nativeIcons.adventure=nativeIcons.bags
nativeIcons.guildboard=nativeIcons.guild
nativeIcons.recruitment=nativeIcons.guild
nativeIcons.threat=nativeIcons.group
nativeIcons.auras=nativeIcons.frames
nativeIcons.studio=nativeIcons.settings
nativeIcons.quests=nativeIcons.rewards

-- Soft, scalable 9-slice panels for Modern. Corners stay round even when
-- the player resizes a window. Unlike stretched full images, these preserve
-- their corner geometry at every supported window size.
local function modernNineSlice(frame,file,size)
  local container={}
  local uv={0,.25,.75,1}
  local parts={
    {'TOPLEFT',0,0,size,size}, {'TOP',size,0,-size,size}, {'TOPRIGHT',0,0,size,size},
    {'LEFT',0,-size,size,-size}, {'CENTER',size,-size,-size,-size}, {'RIGHT',0,-size,size,-size},
    {'BOTTOMLEFT',0,0,size,size}, {'BOTTOM',size,0,-size,size}, {'BOTTOMRIGHT',0,0,size,size}
  }
  for i=1,9 do
    local row=math.floor((i-1)/3)+1
    local col=((i-1)%3)+1
    local t=frame:CreateTexture(nil,'BACKGROUND',nil,2)
    t:SetTexture(file)
    t:SetTexCoord(uv[col],uv[col+1],uv[row],uv[row+1])
    if row==1 and col==1 then t:SetSize(size,size);t:SetPoint('TOPLEFT',frame,'TOPLEFT',0,0)
    elseif row==1 and col==2 then t:SetPoint('TOPLEFT',frame,'TOPLEFT',size,0);t:SetPoint('TOPRIGHT',frame,'TOPRIGHT',-size,0);t:SetHeight(size)
    elseif row==1 then t:SetSize(size,size);t:SetPoint('TOPRIGHT',frame,'TOPRIGHT',0,0)
    elseif row==2 and col==1 then t:SetPoint('TOPLEFT',frame,'TOPLEFT',0,-size);t:SetPoint('BOTTOMLEFT',frame,'BOTTOMLEFT',0,size);t:SetWidth(size)
    elseif row==2 and col==2 then t:SetPoint('TOPLEFT',frame,'TOPLEFT',size,-size);t:SetPoint('BOTTOMRIGHT',frame,'BOTTOMRIGHT',-size,size)
    elseif row==2 then t:SetPoint('TOPRIGHT',frame,'TOPRIGHT',0,-size);t:SetPoint('BOTTOMRIGHT',frame,'BOTTOMRIGHT',0,size);t:SetWidth(size)
    elseif col==1 then t:SetSize(size,size);t:SetPoint('BOTTOMLEFT',frame,'BOTTOMLEFT',0,0)
    elseif col==2 then t:SetPoint('BOTTOMLEFT',frame,'BOTTOMLEFT',size,0);t:SetPoint('BOTTOMRIGHT',frame,'BOTTOMRIGHT',-size,0);t:SetHeight(size)
    else t:SetSize(size,size);t:SetPoint('BOTTOMRIGHT',frame,'BOTTOMRIGHT',0,0) end
    container[i]=t
  end
  return {
    SetShown=function(_,shown) for _,t in ipairs(container) do t:SetShown(shown) end end,
    SetColor=function(_,r,g,b,a) for _,t in ipairs(container) do t:SetVertexColor(r,g,b,a or 1) end end,
  }
end
function WG:TacticalPlate(frame,kind)
  return modernNineSlice(frame,media..'Tactical\\'..(kind or 'Plate'),12)
end
function WG:ModernRounded(frame,kind)
  local file=media..'Modern\\'..(kind or 'SoftPanel')
  return modernNineSlice(frame,file,12)
end
function WG:AdventurePanel(frame,size)
  return modernNineSlice(frame,media..'Adventure\\JournalPanel',size or 18)
end
function WG:Surface(frame,kind,border)
  -- Keep bg/edge fields used by Bags.lua and its quality-colored borders.
  local edge=frame:CreateTexture(nil,'BACKGROUND',nil,-2)
  edge:SetPoint('TOPLEFT',frame,'TOPLEFT',-2,2)
  edge:SetPoint('BOTTOMRIGHT',frame,'BOTTOMRIGHT',2,-2)
  local back=frame:CreateTexture(nil,'BACKGROUND',nil,-1);back:SetAllPoints()
  -- Keep small bag items and icon slots lightweight. They do not need grain.
  local grain
  if frame:GetWidth()>=80 or frame:GetHeight()>=60 then
    grain=frame:CreateTexture(nil,'BACKGROUND',nil,0)
    grain:SetAllPoints();grain:SetTexture(self:CurrentThemeTexture('panel'))
    self.themeTextures[#self.themeTextures+1]={texture=grain,kind='panel'}
  end
  -- Modern rounded chrome is only allocated for full panels, sizeable buttons
  -- and unit windows. Small inventory slots remain lightweight.
  local rounded,roundBorder,adventurePanel,tacticalPlate,tacticalBorder,tacticalStroke,tacticalNotch
  local fname=frame.GetName and frame:GetName() or ''
  if (frame:GetWidth()>=80 and frame:GetHeight()>=24 and fname~='WGExperienceBar'
      and fname~='WG_ActionBars' and not fname:match('^WG_Action_')) then
    rounded=modernNineSlice(frame,media..'Modern\\SoftPanel',12)
    roundBorder=modernNineSlice(frame,media..'Modern\\SoftOutline',12)
    if not fname:match('^WGUnit_') then adventurePanel=self:AdventurePanel(frame,18) end
    -- Tactical uses a hairline rectangular panel, not Classic's decorative
    -- panels or Modern's rounded nine-slice. It can scale freely.
    tacticalStroke={}
    for _,side in ipairs({'TOP','BOTTOM','LEFT','RIGHT'}) do
      local line=frame:CreateTexture(nil,'BORDER')
      if side=='TOP' then
        line:SetPoint('TOPLEFT',frame,'TOPLEFT',0,0);line:SetPoint('TOPRIGHT',frame,'TOPRIGHT',0,0);line:SetHeight(1)
      elseif side=='BOTTOM' then
        line:SetPoint('BOTTOMLEFT',frame,'BOTTOMLEFT',0,0);line:SetPoint('BOTTOMRIGHT',frame,'BOTTOMRIGHT',0,0);line:SetHeight(1)
      elseif side=='LEFT' then
        line:SetPoint('TOPLEFT',frame,'TOPLEFT',0,0);line:SetPoint('BOTTOMLEFT',frame,'BOTTOMLEFT',0,0);line:SetWidth(1)
      else
        line:SetPoint('TOPRIGHT',frame,'TOPRIGHT',0,0);line:SetPoint('BOTTOMRIGHT',frame,'BOTTOMRIGHT',0,0);line:SetWidth(1)
      end
      tacticalStroke[#tacticalStroke+1]=line
    end
    tacticalNotch=frame:CreateTexture(nil,'ARTWORK')
    tacticalNotch:SetPoint('TOPLEFT',frame,'TOPLEFT',0,0)
    tacticalNotch:SetSize(17,2)
  end
  local entry={bg=back,edge=edge,grain=grain,rounded=rounded,roundedBorder=roundBorder,adventurePanel=adventurePanel,tacticalPlate=tacticalPlate,tacticalBorder=tacticalBorder,tacticalStroke=tacticalStroke,tacticalNotch=tacticalNotch}
  entry.repaint=function()
    local c,e=WG:Color(kind or 'panel'),WG:Color(border or 'edge')
    local modern=WG:StyleName()=='Modern'
    local tactical=WG:StyleName()=='Tactical'
    local adventure=WG:StyleName()=='Adventure'
    back:SetColorTexture(c[1],c[2],c[3],modern and 0 or (adventure and (adventurePanel and 0 or .78) or 1))
    if adventurePanel then
      adventurePanel:SetShown(adventure)
      if adventure then adventurePanel:SetColor(1,1,1,.96) end
    end
    edge:SetColorTexture(e[1],e[2],e[3],(modern or tactical or adventure) and 0 or 1)
    if tacticalStroke then
      for _,line in ipairs(tacticalStroke) do
        line:SetShown(tactical)
        line:SetColorTexture(e[1],e[2],e[3],.53)
      end
      tacticalNotch:SetShown(tactical)
      local ac=WG:Color('accent')
      tacticalNotch:SetColorTexture(ac[1],ac[2],ac[3],.9)
    end
    if tacticalPlate then
      tacticalPlate:SetShown(false)
      tacticalBorder:SetShown(false)
      if tactical then
        tacticalPlate:SetColor(c[1],c[2],c[3],.99)
        tacticalBorder:SetColor(e[1],e[2],e[3],.70)
      end
    end
    if rounded then
      rounded:SetShown(modern)
      roundBorder:SetShown(modern)
      if modern then
        rounded:SetColor(c[1],c[2],c[3],.91)
        roundBorder:SetColor(e[1],e[2],e[3],.53)
      end
    end
    if grain then
      local style=WG:StyleName()
      if style=='Modern' or style=='Tactical' then
        grain:SetTexture(nil) -- Modern is intentionally flat, no waffle lattice.
        grain:SetAlpha(0)
      elseif style=='Classic' then
        grain:SetTexture(WG:CurrentThemeTexture('panel'))
        grain:SetAlpha(.68)
      else
        grain:SetTexture(WG:StyleTexture('Panel') or WG:CurrentThemeTexture('panel'))
        grain:SetAlpha(style=='Adventure' and 0 or .56)
      end
    end
  end
  table.insert(self.surfaces,entry);entry.repaint()
  return entry
end
function WG:Text(parent,value,x,y,size,col,width)
  local f=parent:CreateFontString(nil,'OVERLAY','GameFontNormal')
  f:SetFont(WG:StyleFont(size or 12),size or 12,'OUTLINE')
  f:SetPoint('TOPLEFT',parent,'TOPLEFT',x,y)
  if width then f:SetWidth(width);f:SetJustifyH('LEFT') end
  f:SetText(value or '')
  local function repaint()
    local sizeNow=size or 12
    local font=WG:StyleFont(sizeNow)
    local modern=WG:StyleName()=='Modern'
    local ok=pcall(f.SetFont,f,font,sizeNow,(modern or WG:StyleName()=='Tactical') and '' or 'OUTLINE')
    if not ok then f:SetFont(STANDARD_TEXT_FONT or 'Fonts\\FRIZQT__.TTF',sizeNow,(modern or WG:StyleName()=='Tactical') and '' or 'OUTLINE') end
    f:SetTextColor(rgb(WG:Color(col or 'text')))
  end
  table.insert(self.surfaces,{repaint=repaint});repaint()
  return f
end
function WG:Logo(parent,sz,point,relative,relativePoint,x,y)
  local t=parent:CreateTexture(nil,'ARTWORK')
  t:SetSize(sz,sz)
  t:SetPoint(point,relative or parent,relativePoint or point,x or 0,y or 0)
  t:SetTexture(self:CurrentLogo())
  table.insert(self.themeLogoTextures,t)
  return t
end
function WG:IconFrame(parent,icon,x,y,size)
  local f=CreateFrame('Frame',nil,parent)
  f:SetSize(size,size);f:SetPoint('TOPLEFT',parent,'TOPLEFT',x,y)
  local edge=self:Surface(f,'bg','edge')
  local t=f:CreateTexture(nil,'ARTWORK')
  local pad=size<30 and 2 or 3
  t:SetPoint('TOPLEFT',f,'TOPLEFT',pad,-pad)
  t:SetPoint('BOTTOMRIGHT',f,'BOTTOMRIGHT',-pad,pad)
  t:SetTexture(icon or nativeIcons.help);t:SetTexCoord(0,1,0,1)
  local top=f:CreateTexture(nil,'OVERLAY');top:SetColorTexture(1,1,1,.14)
  top:SetPoint('TOPLEFT',f,'TOPLEFT',2,-2);top:SetPoint('TOPRIGHT',f,'TOPRIGHT',-2,-2);top:SetHeight(1)
  return f,t,edge
end
function WG:Divider(parent,y,width,x)
  local w=width or parent:GetWidth()-48
  local d=textured(parent,'divider_chrome','ARTWORK','TOPLEFT',parent,'TOPLEFT',x or 24,y,w,19)
  tint(d,'accent',.8)
  table.insert(WG.surfaces,{repaint=function()
    if WG:StyleName()=='Modern' or WG:StyleName()=='Tactical' or WG:StyleName()=='Adventure' then
      d:SetTexture('Interface\\Buttons\\WHITE8X8')
      d:SetHeight(1)
      local c=WG:Color('edge');d:SetVertexColor(c[1],c[2],c[3],.55)
    else
      d:SetTexture(media..'divider_chrome');d:SetHeight(19)
      local c=WG:Color('accent');d:SetVertexColor(c[1],c[2],c[3],.8)
    end
  end})
  return d
end
function WG:Button(parent,label,x,y,w,h,clicked)
  local b=CreateFrame('Button',nil,parent)
  b:SetSize(w,h);b:SetPoint('TOPLEFT',parent,'TOPLEFT',x,y)
  local face=self:Surface(b,'panel','edge')
  local chrome=b:CreateTexture(nil,'ARTWORK')
  chrome:SetTexture(WG:StyleTexture('Button') or media..'button_chrome');chrome:SetAllPoints()
  tint(chrome,'accent',.65)
  table.insert(WG.surfaces,{repaint=function()
    chrome:SetTexture(WG:StyleTexture('Button') or media..'button_chrome')
    chrome:SetAlpha((WG:StyleName()~='Classic') and 0 or .8)
  end})
  local title=b:CreateFontString(nil,'OVERLAY','GameFontNormal')
  title:SetFont(WG:StyleFont(h>=42 and 12 or 11),h>=42 and 12 or 11,'OUTLINE')
  title:SetPoint('CENTER',b,'CENTER',0,0);title:SetText(label or '')
  title:SetWidth(w-14)
  local function recolor()
    pcall(title.SetFont,title,WG:StyleFont(h>=42 and 12 or 11),h>=42 and 12 or 11,(WG:StyleName()=='Modern' or WG:StyleName()=='Tactical') and '' or 'OUTLINE')
    title:SetTextColor(rgb(WG:Color('text')))
  end
  table.insert(self.surfaces,{repaint=recolor});recolor()
  b.label=title;b.face=face;b.chrome=chrome
  b:SetScript('OnEnter',function()
    local c=WG:Color('edge')
    local modern=WG:StyleName()=='Modern'
    face.bg:SetColorTexture(c[1],c[2],c[3],modern and 0 or 1)
    if modern and face.rounded then face.rounded:SetColor(c[1],c[2],c[3],.72) end
    if WG:StyleName()=='Tactical' then face.bg:SetColorTexture(c[1],c[2],c[3],1) end
    chrome:SetAlpha((modern or WG:StyleName()=='Tactical' or WG:StyleName()=='Adventure') and 0 or 1)
  end)
  b:SetScript('OnLeave',function()
    local c=WG:Color('panel')
    local modern=WG:StyleName()=='Modern'
    face.bg:SetColorTexture(c[1],c[2],c[3],modern and 0 or 1)
    if modern and face.rounded then face.rounded:SetColor(c[1],c[2],c[3],.91) end
    if WG:StyleName()=='Tactical' then face.bg:SetColorTexture(c[1],c[2],c[3],1) end
    chrome:SetAlpha((modern or WG:StyleName()=='Tactical' or WG:StyleName()=='Adventure') and 0 or .8)
  end)
  b:SetScript('OnMouseDown',function() b:SetAlpha(.82) end)
  b:SetScript('OnMouseUp',function() b:SetAlpha(1) end)
  b:SetScript('OnClick',function() if clicked then WG:Safe(label,clicked) end end)
  chrome:SetAlpha((WG:StyleName()~='Classic') and 0 or .8)
  return b
end
function WG:Check(parent,key,label,x,y)
  local c=CreateFrame('CheckButton',nil,parent,'UICheckButtonTemplate')
  c:SetSize(24,24);c:SetPoint('TOPLEFT',parent,'TOPLEFT',x,y)
  c:SetChecked(self:Enabled(key))
  self:Text(parent,label,x+32,y-4,12,'text',430)
  self.checks=self.checks or {};self.checks[#self.checks+1]={key=key,button=c}
  c:SetScript('OnClick',function(btn) WG:Feature(key,btn:GetChecked()) end)
  return c
end
function WG:WindowScale(key)
  if not self.db then return 1 end
  local values=self.db.windowScales or {}
  local scale=tonumber(values[key]) or 1
  return math.max(.7,math.min(1.45,scale))
end
function WG:ApplyWindowScale(key,frame)
  if not frame or not self.db then return end
  local global=self.db.windowScale or 1
  local scale=self:WindowScale(key)
  if UIParent and UIParent.GetWidth and UIParent.GetHeight then
    local width,height=frame:GetWidth(),frame:GetHeight()
    if type(width)=='number' and type(height)=='number' and width>0 and height>0 then
      local fit=math.min((UIParent:GetWidth()-24)/(width*global),(UIParent:GetHeight()-24)/(height*global))
      if fit>0 then scale=math.min(scale,fit) end
    end
  end
  frame:SetScale(global*math.max(.5,scale))
end
function WG:SaveWindowScale(key,frame,scale)
  if not self.db or self:Protected() or self.db.lockWindows then return end
  self.db.windowScales=self.db.windowScales or {}
  self.db.windowScales[key]=math.floor(math.max(.7,math.min(1.45,scale))*100+.5)/100
  self:ApplyWindowScale(key,frame)
end
-- Low-overhead slider for continuous, precise controls. The label and current
-- value remain visible instead of requiring 10+ clicks to change a size.
function WG:Slider(parent,label,x,y,width,minValue,maxValue,step,initial,onChanged,formatValue)
  local host=CreateFrame('Frame',nil,parent)
  host:SetSize(width,48);host:SetPoint('TOPLEFT',parent,'TOPLEFT',x,y)
  self:Text(host,label,0,0,11,'text',width-64)
  local valueText=self:Text(host,'',width-76,0,11,'accent',76)
  valueText:SetJustifyH('RIGHT')
  local slider=CreateFrame('Slider',nil,host)
  slider:SetOrientation('HORIZONTAL')
  slider:SetSize(width-16,17)
  slider:SetPoint('TOPLEFT',host,'TOPLEFT',8,-20)
  slider:SetMinMaxValues(minValue,maxValue)
  slider:SetValueStep(step)
  if slider.SetObeyStepOnDrag then slider:SetObeyStepOnDrag(true) end
  local track=slider:CreateTexture(nil,'BACKGROUND')
  track:SetPoint('LEFT',slider,'LEFT',0,0);track:SetPoint('RIGHT',slider,'RIGHT',0,0)
  track:SetHeight(5)
  local fill=slider:CreateTexture(nil,'ARTWORK')
  fill:SetPoint('LEFT',slider,'LEFT',0,0);fill:SetHeight(5)
  local thumb=slider:CreateTexture(nil,'OVERLAY')
  thumb:SetSize(13,18);thumb:SetTexture('Interface\\Buttons\\WHITE8X8')
  slider:SetThumbTexture(thumb)
  local function colorize()
    local c,e=WG:Color('accent'),WG:Color('edge')
    track:SetColorTexture(e[1],e[2],e[3],.7)
    thumb:SetColorTexture(c[1],c[2],c[3],1)
    fill:SetColorTexture(c[1],c[2],c[3],.9)
  end
  table.insert(self.surfaces,{repaint=colorize});colorize()
  slider:SetScript('OnValueChanged',function(_,raw)
    if type(raw)~='number' then return end
    local value=math.floor((raw-minValue)/step+.5)*step+minValue
    value=math.max(minValue,math.min(maxValue,value))
    valueText:SetText(formatValue and formatValue(value) or tostring(value))
    fill:SetWidth((width-16)*((value-minValue)/(maxValue-minValue)))
    if not slider.silent and onChanged then onChanged(value) end
  end)
  slider.silent=true;slider:SetValue(initial or minValue);slider.silent=nil
  host.slider=slider
  host.SetDisplayValue=function(_,value)
    slider.silent=true;slider:SetValue(value);slider.silent=nil
  end
  return host
end
function WG:SaveWindowPosition(key,frame)
  if not self.db or self:Protected() then return end
  local x,y=frame:GetCenter();local mx,my=UIParent:GetCenter()
  if x and y and mx and my then
    self.db.windowPositions=self.db.windowPositions or {}
    self.db.windowPositions[key]={x=x-mx,y=y-my}
  end
end
function WG:RestoreWindowPosition(key,frame,bag)
  frame:ClearAllPoints()
  local saved=self.db and self.db.windowPositions and self.db.windowPositions[key]
  if type(saved)=='table' and type(saved.x)=='number' and type(saved.y)=='number' and
    math.abs(saved.x)<(UIParent:GetWidth() or 3000) and math.abs(saved.y)<(UIParent:GetHeight() or 1800) then
    frame:SetPoint('CENTER',UIParent,'CENTER',saved.x,saved.y)
  elseif bag then frame:SetPoint('RIGHT',UIParent,'RIGHT',-28,0)
  else frame:SetPoint('CENTER',UIParent,'CENTER',0,24) end
end
-- Custom Edit Mode for addon-owned HUD elements. Drag handles are separate
-- UIParent children so secure unit/action buttons retain their click attributes.
WG.hudFrames,WG.hudHandles,WG.hudDefaults={},{},{}
function WG:SaveHUDPosition(key,frame)
  if not self.db or self:Protected() then return end
  local x,y=frame:GetCenter()
  local cx,cy=UIParent:GetCenter()
  if x and y and cx and cy then
    self.db.hudPositions=self.db.hudPositions or {}
    self.db.hudPositions[key]={x=x-cx,y=y-cy}
  end
end
function WG:RegisterHUDFrame(key,frame,title)
  if not self.db or not frame then return end
  self.hudFrames[key]=frame
  if not self.hudDefaults[key] and frame.GetPoint then
    local point,relative,relPoint,x,y=frame:GetPoint(1)
    self.hudDefaults[key]={point or 'CENTER',relative or UIParent,relPoint or point or 'CENTER',x or 0,y or 0}
  end
  frame:SetMovable(true)
  frame:SetClampedToScreen(true)
  local saved=self.db.hudPositions and self.db.hudPositions[key]
  if type(saved)=='table' and type(saved.x)=='number' and type(saved.y)=='number' then
    frame:ClearAllPoints()
    frame:SetPoint('CENTER',UIParent,'CENTER',saved.x,saved.y)
  end
  local overlay=CreateFrame('Frame',nil,UIParent)
  overlay:SetAllPoints(frame)
  overlay:SetFrameStrata('DIALOG')
  overlay:EnableMouse(true)
  overlay:RegisterForDrag('LeftButton')
  local tint=overlay:CreateTexture(nil,'BACKGROUND')
  tint:SetAllPoints()
  tint:SetColorTexture(0.14,0.08,0.03,0.7)
  local caption=overlay:CreateFontString(nil,'OVERLAY','GameFontNormal')
  caption:SetPoint('CENTER',overlay,'CENTER',0,0)
  caption:SetText('MOVE  '..string.upper(title or key))
  caption:SetTextColor(1,.86,.54)
  overlay:SetScript('OnDragStart',function()
    if WG.editMode and not WG:Protected() then frame:StartMoving() end
  end)
  overlay:SetScript('OnDragStop',function()
    frame:StopMovingOrSizing()
    WG:SaveHUDPosition(key,frame)
  end)
  overlay:Hide()
  self.hudHandles[key]=overlay
  -- Compact grab tab outside the frame so the normal gameplay buttons and
  -- their mouse bindings remain usable. No edit mode is needed to move it.
  local grip=CreateFrame('Button',nil,UIParent)
  grip:SetSize(17,17)
  grip:SetPoint('BOTTOMRIGHT',frame,'TOPLEFT',0,0)
  grip:SetFrameStrata('HIGH')
  grip:RegisterForClicks('LeftButtonUp','RightButtonUp')
  grip:RegisterForDrag('LeftButton')
  local fill=grip:CreateTexture(nil,'BACKGROUND')
  fill:SetAllPoints();fill:SetTexture('Interface\\Buttons\\WHITE8X8')
  local label=grip:CreateFontString(nil,'OVERLAY','GameFontNormalSmall')
  label:SetPoint('CENTER',grip,'CENTER',0,0)
  label:SetText('+')
  grip:SetScript('OnEnter',function(self)
    self:SetAlpha(1)
    if GameTooltip then
      GameTooltip:SetOwner(self,'ANCHOR_RIGHT')
      GameTooltip:AddLine(title or key)
      GameTooltip:AddLine('Left-drag: move frame (out of combat)',1,1,1)
      GameTooltip:AddLine('Right-click: lock/unlock this frame',1,1,1)
      GameTooltip:Show()
    end
  end)
  grip:SetScript('OnLeave',function(self)
    self:SetAlpha(.45)
    if GameTooltip then GameTooltip:Hide() end
  end)
  grip:SetScript('OnDragStart',function()
    local locked=WG.db.hudDragLocked or (WG.db.hudElementLocks and WG.db.hudElementLocks[key])
    if not WG:Protected() and not locked and not WG.editMode then
      grip.dragging=true
      frame:StartMoving()
    end
  end)
  grip:SetScript('OnDragStop',function()
    if grip.dragging then
      frame:StopMovingOrSizing()
      grip.dragging=false
      WG:SaveHUDPosition(key,frame)
    end
  end)
  grip:SetScript('OnClick',function(_,button)
    if button=='RightButton' and not WG:Protected() then
      WG.db.hudElementLocks=WG.db.hudElementLocks or {}
      WG.db.hudElementLocks[key]=not WG.db.hudElementLocks[key]
      WG:UpdateHUDGrips()
    end
  end)
  self.hudGrips=self.hudGrips or {}
  self.hudGrips[key]={button=grip,fill=fill,label=label,frame=frame}
  if not self.hudGripWatcher then
    -- A watcher independent of the grips is required: a hidden target frame
    -- would otherwise stop its grip's own OnUpdate and never reappear.
    local watcher=CreateFrame('Frame',nil,UIParent)
    local elapsed=0
    watcher:SetScript('OnUpdate',function(_,delta)
      elapsed=elapsed+(delta or 0)
      if elapsed<.4 then return end
      elapsed=0
      WG:UpdateHUDGrips()
    end)
    self.hudGripWatcher=watcher
  end
  self:UpdateHUDGrip(key)
  return overlay
end
function WG:UpdateHUDGrip(key)
  if not self.db or not self.hudGrips then return end
  local item=self.hudGrips[key]
  if not item then return end
  local grip=item.button
  local visible=not self.editMode and not self:Protected() and item.frame:IsShown()
  grip:SetShown(visible)
  if not visible then return end
  local locked=self.db.hudDragLocked or (self.db.hudElementLocks and self.db.hudElementLocks[key])
  local c=self:Color('accent')
  item.fill:SetVertexColor(c[1],c[2],c[3],locked and .27 or .75)
  item.label:SetText(locked and 'L' or '+')
  item.label:SetTextColor(1,1,1,locked and .65 or 1)
  if not grip:IsMouseOver() then grip:SetAlpha(locked and .28 or .45) end
end
function WG:UpdateHUDGrips()
  for key in pairs(self.hudGrips or {}) do self:UpdateHUDGrip(key) end
end
function WG:EditMode(enabled)
  if self:Protected() then
    self:Say('Edit Mode is unavailable during combat.')
    return
  end
  self.editMode=enabled == true
  for _,handle in pairs(self.hudHandles) do handle:SetShown(self.editMode) end
  self:UpdateHUDGrips()
  if self.editMode then
    self:Say('Edit Mode: drag labeled HUD elements. Click SAVE & LOCK when finished.')
  else
    for key,frame in pairs(self.hudFrames) do self:SaveHUDPosition(key,frame) end
    self:Say('HUD locations saved and locked.')
  end
  self:Refresh()
end
function WG:ToggleEditMode()
  self:EditMode(not self.editMode)
end
function WG:ResetHUDPositions()
  if self:Protected() then return self:Say('Reset HUD outside combat.') end
  self.db.hudPositions={}
  for key,frame in pairs(self.hudFrames) do
    local d=self.hudDefaults[key]
    if d then
      frame:ClearAllPoints()
      frame:SetPoint(d[1],d[2],d[3],d[4],d[5])
    end
  end
  self:Say('HUD elements restored to default locations.')
end
function WG:ResetLayout()
  if self:Protected() then return self:Say('Reset positions outside combat.') end
  self.db.windowPositions={}
  for key,f in pairs(self.windows) do self:RestoreWindowPosition(key,f,f.isBag) end
  if self.launcher then self.launcher:ClearAllPoints();self.launcher:SetPoint('CENTER',UIParent,'CENTER',-330,-160) end
  if self.db then self.db.launcherPos=nil end
  self:ResetHUDPositions()
  self.db.hudElementLocks={}
  self:UpdateHUDGrips()
  self:Say('Window positions restored to defaults.')
end
function WG:Window(key,title,width,height,bag)
  local f=CreateFrame('Frame','WGWindow_'..key,UIParent,'BackdropTemplate')
  f:SetSize(width,height);f.isBag=bag
  self:RestoreWindowPosition(key,f,bag)
  f:SetFrameStrata('DIALOG');f:SetClampedToScreen(true)
  f:EnableMouse(true);f:SetMovable(true)
  self:Surface(f,'bg','edge')
  -- Thin, reusable guild-quality trim.  The chrome never shares text space.
  local header=CreateFrame('Frame',nil,f)
  header:SetPoint('TOPLEFT',f,'TOPLEFT',2,-2)
  header:SetPoint('TOPRIGHT',f,'TOPRIGHT',-2,-2)
  header:SetHeight(63)
  self:Surface(header,'panel','edge')
  local topChrome=header:CreateTexture(nil,'ARTWORK')
  topChrome:SetAllPoints();topChrome:SetTexture(media..'header_chrome')
  tint(topChrome,'edge',.72)
  table.insert(self.surfaces,{repaint=function()
    topChrome:SetTexture(WG:StyleTexture('Header') or media..'header_chrome')
    topChrome:SetAlpha(WG:StyleName()=='Classic' and 1 or 0)
  end})
  local themedBanner=header:CreateTexture(nil,'ARTWORK')
  themedBanner:SetAllPoints()
  themedBanner:SetTexture(self:CurrentThemeTexture('header'))
  themedBanner:SetVertexColor(1,1,1,.70)
  self.themeTextures[#self.themeTextures+1]={texture=themedBanner,kind='header'}
  table.insert(WG.surfaces,{repaint=function()
    themedBanner:SetShown(WG:StyleName()=='Classic')
  end})
  local accentRule=header:CreateTexture(nil,'OVERLAY')
  accentRule:SetPoint('BOTTOMLEFT',header,'BOTTOMLEFT',0,1)
  accentRule:SetPoint('BOTTOMRIGHT',header,'BOTTOMRIGHT',0,1)
  accentRule:SetHeight(2)
  tint(accentRule,'accent',.9)
  table.insert(WG.surfaces,{repaint=function()
    accentRule:SetHeight(WG:StyleName()=='Tactical' and 1 or 2)
  end})
  local icon=nativeIcons[key] or nativeIcons.hub
  local headerArt
  if key=='hub' then headerArt=self:Logo(header,48,'TOPLEFT',header,'TOPLEFT',8,-7)
  else
    local iconFrame,themeIcon=self:IconFrame(header,icon,12,-12,39)
    headerArt=iconFrame
    self.themeIconPairs=self.themeIconPairs or {}
    self.themeIconPairs[#self.themeIconPairs+1]={icon=themeIcon,original=icon}
  end
  local compactBrand=header:CreateTexture(nil,'ARTWORK')
  compactBrand:SetPoint('TOPLEFT',header,'TOPLEFT',11,-10)
  compactBrand:SetSize(27,27)
  table.insert(WG.surfaces,{repaint=function()
    local style=WG:StyleName()
    if headerArt then headerArt:SetShown(style=='Classic') end
    compactBrand:SetShown(style~='Classic')
    compactBrand:SetTexture(WG:CurrentLogo())
    compactBrand:SetAlpha(style=='Tactical' and .73 or .86)
  end})
  if key=='hub' then
    self:Text(header,'WAFFLES GANG',76,-9,23,'accent',width-170)
    self:Text(header,'GUILD CONTROL CENTER',77,-39,10,'text',width-170)
  else
    self.themeCaptions=self.themeCaptions or {}
    local tag=self:Text(header,'WAFFLES GANG  /  GUILD INTERFACE',66,-10,9,'text')
    self.themeCaptions[#self.themeCaptions+1]=tag
    local heading=self:Text(header,string.upper(title),66,-28,width<555 and 14 or 16,'accent',width-246)
    table.insert(WG.surfaces,{repaint=function()
      local modern=WG:StyleName()=='Modern'
      local tactical=WG:StyleName()=='Tactical'
      local adventure=WG:StyleName()=='Adventure'
      tag:ClearAllPoints();tag:SetPoint('TOPLEFT',header,'TOPLEFT',(modern or tactical or adventure) and 48 or 66,(modern or tactical) and -7 or -10)
      tag:SetText(modern and ('WAFFLES GANG  /  '..WG:ThemeName()..' WORKSPACE') or (tactical and ('W/G  //  '..string.upper(WG:ThemeName())..'  /  '..string.upper(WG:CurrentPaletteName())) or (adventure and ('EXPEDITION  /  '..string.upper(WG:ThemeName())) or 'WAFFLES GANG  /  GUILD INTERFACE')))
      heading:ClearAllPoints();heading:SetPoint('TOPLEFT',header,'TOPLEFT',(modern or tactical or adventure) and 48 or 66,(modern or tactical) and -23 or -28)
      pcall(heading.SetFont,heading,WG:StyleFont((modern or tactical or adventure) and 15 or (width<555 and 14 or 16)),(modern or tactical or adventure) and 15 or (width<555 and 14 or 16),(modern or tactical) and '' or 'OUTLINE')
    end})
    f.backButton=self:Button(header,'BACK',width-141,-13,91,29,function()
      if key=='studio' then
        if WG.studio and WG.studio.Back then WG.studio:Back() else f:Hide() end
      else
        f:Hide()
        WG:Open('studio')
      end
    end)
    f.backButton:ClearAllPoints()
    f.backButton:SetPoint('TOPRIGHT',header,'TOPRIGHT',-50,-13)
  end
  f.closeButton=self:Button(header,'X',width-40,-13,29,29,function()f:Hide()end)
  f.closeButton:ClearAllPoints()
  f.closeButton:SetPoint('TOPRIGHT',header,'TOPRIGHT',-11,-13)
  -- Different visual hierarchy by style, not merely a tint change.
  -- The Classic header, exact icons, and original wood art are untouched.
  local styleRail=f:CreateTexture(nil,'ARTWORK')
  styleRail:SetPoint('TOPLEFT',f,'TOPLEFT',3,-68)
  styleRail:SetPoint('BOTTOMLEFT',f,'BOTTOMLEFT',3,6)
  styleRail:SetWidth(16)
  table.insert(WG.surfaces,{repaint=function()
    local style=WG:StyleName()
    styleRail:SetShown(style=='Adventure' or style=='Modern')
    if style~='Classic' and style~='Tactical' then styleRail:SetTexture(media..'UIStyles\\'..style..'Rail')end
    if style=='Modern' then header:SetHeight(53)
    elseif style=='Tactical' then header:SetHeight(49)
    elseif style=='Adventure' then header:SetHeight(72)
    else header:SetHeight(63) end
  end})
  header:EnableMouse(true);header:RegisterForDrag('LeftButton')
  header:SetScript('OnDragStart',function()
    if not WG:Protected() and not WG.db.lockWindows then f:StartMoving() end
  end)
  header:SetScript('OnDragStop',function()
    f:StopMovingOrSizing();WG:SaveWindowPosition(key,f)
  end)
  -- Quiet themed lattice corners, wholly inside the frame.
  local left=textured(f,'lattice','OVERLAY','BOTTOMLEFT',f,'BOTTOMLEFT',4,4,28,28)
  tint(left,'accent',.67)
  local right=textured(f,'lattice','OVERLAY','BOTTOMRIGHT',f,'BOTTOMRIGHT',-4,4,28,28)
  right:SetTexCoord(1,0,0,1);tint(right,'accent',.67)
  table.insert(self.surfaces,{repaint=function()
    local path=WG:StyleTexture('Corner') or media..'lattice'
    left:SetTexture(path);right:SetTexture(path)
    left:SetShown(WG:StyleName()=='Classic')
    right:SetShown(WG:StyleName()=='Classic')
  end})
  -- The content is fixed-layout in the original modules. Scaling the whole
  -- pane preserves readability and aspect ratio, unlike SetSize clipping text.
  self:ApplyWindowScale(key,f)
  do
    local grip=CreateFrame('Button',nil,f)
    grip:SetSize(25,25);grip:SetPoint('BOTTOMRIGHT',f,'BOTTOMRIGHT',-1,1)
    grip:SetFrameLevel(f:GetFrameLevel()+14)
    grip:RegisterForClicks('AnyUp')
    local dot=grip:CreateTexture(nil,'OVERLAY')
    dot:SetPoint('BOTTOMRIGHT',grip,'BOTTOMRIGHT',-3,3);dot:SetSize(15,15)
    dot:SetTexture(media..'lattice')
    table.insert(WG.surfaces,{repaint=function()
      if WG:StyleName()=='Tactical' then dot:SetTexture('Interface\\Buttons\\WHITE8X8') else dot:SetTexture(WG:StyleTexture('Corner') or media..'lattice') end
      local c=WG:Color('accent');dot:SetVertexColor(c[1],c[2],c[3],.9)
    end})
    grip:SetScript('OnEnter',function()
      GameTooltip:SetOwner(grip,'ANCHOR_TOP')
      GameTooltip:SetText('Drag to resize this window',1,.92,.7)
      GameTooltip:AddLine('Proportional resize keeps the contents aligned.',.8,.8,.8)
      GameTooltip:Show()
      dot:SetAlpha(1)
    end)
    grip:SetScript('OnLeave',function()GameTooltip:Hide();dot:SetAlpha(.65)end)
    grip:SetScript('OnMouseDown',function()
      if WG:Protected() or WG.db.lockWindows then return end
      local x,y=GetCursorPosition()
      grip.startX=x;grip.startY=y;grip.startScale=WG:WindowScale(key)
      grip:SetScript('OnUpdate',function()
        local mx,my=GetCursorPosition()
        local pixels=(mx-grip.startX)+(grip.startY-my)
        local newScale=grip.startScale+pixels/((width+height)*.5)
        WG:SaveWindowScale(key,f,newScale)
      end)
    end)
    grip:SetScript('OnMouseUp',function()
      grip:SetScript('OnUpdate',nil)
      WG:SaveWindowPosition(key,f)
      if GameTooltip:IsOwned(grip) then GameTooltip:Hide() end
    end)
    f.resizeGrip=grip
  end
  f:Hide();self.windows[key]=f
  return f
end
function WG:Open(key)
  if key=='threat' and self.studio and self.studio.pages and self.studio.pages.THREAT then
    self:Open('studio');self.studio:Select('THREAT');return
  end
  local needs={party='party',loot='loot',group='grouptools',guild='guild',guildboard='guild',recruitment='guild',bags='bags',professions='guildprofessions',gear='gearsuggestions',rewards='questrewardadvisor'}
  if needs[key] and not self:Enabled(needs[key]) then
    self:Say('Enable '..key..' in Settings first.');return
  end
  local f=self.windows[key]
  if not f then return self:Say('This window is unavailable: '..tostring(key)) end
  if self.db and self.db.oneWindow~=false then
    for id,other in pairs(self.windows) do if id~=key and other:IsShown() then other:Hide() end end
  end
  f:Show();f:Raise()
  if f.onOpen then f:onOpen() end
end
function WG:Toggle(key)
  local f=self.windows[key]
  if f and f:IsShown() then f:Hide() else self:Open(key) end
end
function WG:DropdownFake(parent,title,values,x,y,handler)
  self:Text(parent,title,x,y,12,'accent')
  for i,v in ipairs(values) do
    self:Button(parent,v,x,y-24-(i-1)*37,160,30,function()handler(v)end)
  end
end
function WG:Card(parent,title,description,icon,x,y,width,height,clicked)
  local b=CreateFrame('Button',nil,parent)
  b:SetSize(width,height);b:SetPoint('TOPLEFT',parent,'TOPLEFT',x,y)
  local base=self:Surface(b,'panel','edge')
  local chrome=b:CreateTexture(nil,'ARTWORK');chrome:SetAllPoints()
  chrome:SetTexture(media..'button_chrome')
  tint(chrome,'accent',.47)
  self:IconFrame(b,nativeIcons[icon] or nativeIcons.hub,11,-13,38)
  self:Text(b,title,61,-13,13,'text',width-75)
  self:Text(b,description,61,-37,10,'text',width-75)
  b:SetScript('OnEnter',function()
    base.bg:SetColorTexture(rgb(WG:Color('edge')))
    chrome:SetAlpha((WG:StyleName()=='Modern' or WG:StyleName()=='Tactical') and 0 or 1)
  end)
  b:SetScript('OnLeave',function()
    base.bg:SetColorTexture(rgb(WG:Color('panel')))
    chrome:SetAlpha((WG:StyleName()=='Modern' or WG:StyleName()=='Tactical') and 0 or .75)
  end)
  b:SetScript('OnClick',function() WG:Safe(title,clicked) end)
  chrome:SetAlpha((WG:StyleName()=='Modern' or WG:StyleName()=='Tactical') and 0 or .75)
  return b
end
local menus={
  {key='studio',label='Waffle Studio',desc='One place to personalize everything'},
  {key='quests',label='Waffle Quests',desc='Quest journal with optional Questie bridge'},
  {key='guild',label='Guild Manager',desc='Members, invites and guild chat'},
  {key='professions',label='Guild Professions',desc='Members, skills and shared recipes'},
  {key='gear',label='Gear Advisor',desc='Talents, upgrades and stat scores'},
  {key='adventure',label='Adventure Center',desc='XP, gold, quests and readiness'},
  {key='rewards',label='Quest Rewards',desc='Upgrade versus vendor value'},
  {key='party',label='Party Manager',desc='Roster, invites and ready checks'},
  {key='loot',label='Loot Manager',desc='Distribution and group loot'},
  {key='group',label='Group Tools',desc='Raid and party organization'},
  {key='autoloot',label='Auto Loot',desc='Pickup rules and filters'},
  {key='automation',label='Automation',desc='Quest turn-ins and safe junk cleanup'},
  {key='frames',label='Unit / Raid Frames',desc='Health, target and raid displays'},
  {key='bars',label='Action Bars / XP',desc='Actions and experience'},
  {key='bags',label='Waffle Pantry',desc='Inventory and sorting'},
  {key='appearance',label='Appearance',desc='Theme and accents'},
  {key='settings',label='Settings',desc='All feature controls'},
  {key='setup',label='Run Setup',desc='Guided configuration'},
  {key='chat',label='Chat Appearance',desc='Themed chat and input field'},
}
function U:Init()
  local hub=WG:Window('hub','Guild Control Center',844,660)
  -- Sidebar, the same destinations as the existing dashboard, with real spacing.
  WG:Surface(hub,'bg','edge')
  local sidebar=CreateFrame('Frame',nil,hub)
  sidebar:SetSize(186,546);sidebar:SetPoint('TOPLEFT',hub,'TOPLEFT',15,-104)
  WG:Surface(sidebar,'panel','edge')
  WG:Text(sidebar,'NAVIGATION',15,-12,11,'accent')
  for i,entry in ipairs(menus) do
    local y=-27-(i-1)*27
    local item=WG:Button(sidebar,entry.label,10,y,166,26,function()WG:Open(entry.key)end)
    item.label:ClearAllPoints();item.label:SetPoint('LEFT',item,'LEFT',41,0)
    item.label:SetJustifyH('LEFT');item.label:SetWidth(118)
    WG:IconFrame(item,nativeIcons[entry.key],7,-4,22)
  end
  -- Dashboard content is independent of sidebar. Text never overlaps button art.
  WG:Text(hub,'Welcome to the Gang',231,-112,23,'accent')
  WG:Text(hub,'Everything in one place: use Waffle Studio to personalize your experience.',231,-149,12,'text',575)
  local lookup={}
  for _,entry in ipairs(menus) do lookup[entry.key]=entry end
  local groups={
    {label='GUILD & COMMUNITY',items={lookup.guild,{key='guildboard',label='Discord Events',desc='Synced community event calendar'},lookup.professions}},
    {label='GEAR & REWARDS',items={lookup.bags,lookup.gear,lookup.rewards}},
    {label='PARTY & QUESTS',items={lookup.party,lookup.quests,lookup.automation}},
    {label='UI & THEMES',items={lookup.studio,lookup.frames,lookup.appearance}},
  }
  for r,group in ipairs(groups) do
    local labelY=-179-(r-1)*99
    WG:Text(hub,group.label,231,labelY,13,'accent')
    -- Consistent cards, 3-column; no overlapping headers or cropped icon boards.
    local cardY=labelY-27
    for i,item in ipairs(group.items) do
      WG:Card(hub,item.label,item.desc,item.key,231+(i-1)*198,cardY,187,61,function() WG:Open(item.key) end)
    end
  end
  WG:Button(hub,'WAFFLE STUDIO',231,-567,137,35,function()WG:Open('studio')end)
  WG:Button(hub,'PROFILES',378,-567,137,35,function()WG:Open('profiles')end)
  WG:Button(hub,'CHAT THEME',525,-567,137,35,function()WG:Open('chat')end)
  WG:Button(hub,'HELP',672,-567,145,35,function()WG:Open('help')end)
  WG:Divider(hub,-602,588,228)
  WG:Text(hub,'/wg  •  /wg bags  •  /wg settings  •  /wg recover',231,-618,10,'text')
  WG:Text(hub,'GUILD EDITION  /  3.5 STUDIO',622,-618,10,'accent')
  -- Persistent waffle emblem launcher from the ORIGINAL art.
  local launch=CreateFrame('Button','WafflesGangLauncher',UIParent)
  launch:SetSize(57,57);launch:SetMovable(true);launch:SetClampedToScreen(true)
  launch:RegisterForDrag('LeftButton')
  local pos=WG.db.launcherPos
  if type(pos)=='table' and type(pos.x)=='number' and type(pos.y)=='number' then
    launch:SetPoint('CENTER',UIParent,'CENTER',pos.x,pos.y)
  else launch:SetPoint('CENTER',UIParent,'CENTER',-330,-160) end
  launch:SetScript('OnDragStart',function(self)
    if not WG:Protected() and not WG.db.lockWindows then self:StartMoving() end
  end)
  launch:SetScript('OnDragStop',function(self)
    self:StopMovingOrSizing()
    local x,y=self:GetCenter();local px,py=UIParent:GetCenter()
    if x and y and px and py then WG.db.launcherPos={x=x-px,y=y-py} end
  end)
  WG:Logo(launch,54,'CENTER',launch,'CENTER',0,0)
  launch:SetScript('OnClick',function()WG:Toggle('studio')end)
  launch:SetScript('OnEnter',function(self)
    GameTooltip:SetOwner(self,'ANCHOR_RIGHT');GameTooltip:AddLine('Waffles Gang')
    GameTooltip:AddLine('Click for Waffle Studio  |  Drag to move',1,1,1);GameTooltip:Show()
  end)
  launch:SetScript('OnLeave',function()GameTooltip:Hide()end)
  self.launcher=launch;WG.launcher=launch
  WG:RegisterHUDFrame('launcher',launch,'Launcher')
  self:Options('setup',true)
  self:Options('settings',false)
  self:Appearance()
  self:Layout()
  self:Profiles()
  self:Help()
  WG:On('PLAYER_REGEN_DISABLED',function()
    -- Do not leave drag overlays above combat buttons when combat begins.
    if WG.editMode then
      WG.editMode=false
      for _,handle in pairs(WG.hudHandles) do pcall(handle.Hide,handle) end
      WG:Say('Edit Mode locked automatically for combat.')
    end
    WG:UpdateHUDGrips()
  end)
  WG:On('PLAYER_REGEN_ENABLED',function()WG:UpdateHUDGrips()end)
end
function U:Options(key,isSetup)
  local f=WG:Window(key,isSetup and 'Welcome / Setup' or 'Feature Settings',622,620)
  WG:Text(f,isSetup and 'WELCOME TO WAFFLES GANG' or 'CUSTOMIZE YOUR WAFFLES',24,-80,16,'accent')
  WG:Text(f,'Each option has an independent on/off switch.',24,-106,11,'text',570)
  WG:Divider(f,-123,565,24)
  local search=CreateFrame('EditBox',nil,f,'InputBoxTemplate')
  search:SetSize(391,29);search:SetPoint('TOPLEFT',f,'TOPLEFT',70,-138)
  search:SetAutoFocus(false)
  search:SetText('')
  WG:Text(f,'FIND',24,-147,10,'accent')
  WG:Button(f,'CLEAR',488,-137,106,29,function()search:SetText('')end)
  search:SetScript('OnEscapePressed',function(self)self:ClearFocus()end)
  local scroll=CreateFrame('ScrollFrame',nil,f,'UIPanelScrollFrameTemplate')
  scroll:SetPoint('TOPLEFT',f,'TOPLEFT',21,-185)
  scroll:SetPoint('BOTTOMRIGHT',f,'BOTTOMRIGHT',-38,65)
  local inside=CreateFrame('Frame',nil,scroll)
  inside:SetSize(546,#WG.features*48+12);scroll:SetScrollChild(inside)
  local rows={}
  for i,feature in ipairs(WG.features) do
    local line=CreateFrame('Frame',nil,inside)
    line:SetSize(525,48)
    line:SetPoint('TOPLEFT',inside,'TOPLEFT',0,-((i-1)*48))
    WG:Check(line,feature[1],feature[2],7,-5)
    WG:Text(line,feature[3],40,-29,10,'text',480)
    rows[#rows+1]={frame=line,label=(feature[1]..' '..feature[2]..' '..feature[3]):lower()}
  end
  self.options=self.options or {}
  self.options[key]={search=search,scroll=scroll,inside=inside,rows=rows}
  local noMatches=WG:Text(inside,'No matching settings.',18,-15,12,'accent')
  local function filterOptions()
    local query=(search:GetText() or ''):lower():match('^%s*(.-)%s*$')
    local shown=0
    for _,item in ipairs(rows) do
      local matched=query=='' or item.label:find(query,1,true)~=nil
      item.frame:SetShown(matched)
      if matched then
        item.frame:ClearAllPoints()
        item.frame:SetPoint('TOPLEFT',inside,'TOPLEFT',0,-shown*48)
        shown=shown+1
      end
    end
    inside:SetHeight(math.max(60,shown*48+12))
    noMatches:SetShown(shown==0)
    if scroll.SetVerticalScroll then scroll:SetVerticalScroll(0) end
  end
  search:SetScript('OnTextChanged',filterOptions)
  filterOptions()
  WG:Button(f,isSetup and 'FINISH SETUP' or 'SAVE & CLOSE',412,-569,181,36,function()
    if isSetup then WG.db.setupComplete=true end
    f:Hide();WG:Refresh()
    if isSetup then WG:Open('hub') end
  end)
  WG:Button(f,'APPEARANCE',23,-569,132,36,function()WG:Open('appearance')end)
  WG:Button(f,'LAYOUT',165,-569,108,36,function()WG:Open('layout')end)
  local edit=WG:Button(f,'EDIT MODE',282,-569,121,36,function()WG:ToggleEditMode()end)
  self.editButtons=self.editButtons or {};self.editButtons[#self.editButtons+1]=edit
end
function U:Appearance()
  local f=WG:Window('appearance','Appearance & Themes',575,558)
  WG:Text(f,'CHOOSE YOUR GANG THEME',23,-79,14,'accent')
  self.themeDescriptionLabel=WG:Text(f,'',23,-106,11,'text',520)
  WG:Divider(f,-128,525,23)
  self.themeButtons={}
  for i,name in ipairs({'Waffles','Cake','Pie','Pizza','Samurai'}) do
    local x=24+((i-1)%3)*174
    local y=-145-math.floor((i-1)/3)*67
    local btn=WG:Button(f,name,x,y,163,57,function()
      WG:SetTheme(name)
      WG:Say(name..' theme applied with its own colorways.')
    end)
    self.themeButtons[name]=btn
    local tex=btn:CreateTexture(nil,'OVERLAY')
    tex:SetSize(43,43);tex:SetPoint('LEFT',btn,'LEFT',7,0)
    tex:SetTexture(WG.themeLogos[name])
    btn.label:ClearAllPoints();btn.label:SetPoint('LEFT',btn,'LEFT',55,0)
    btn.label:SetWidth(102);btn.label:SetJustifyH('LEFT')
  end
  WG:Divider(f,-286,525,23)
  WG:Text(f,'THEME COLORWAYS',23,-302,14,'accent')
  self.paletteButtons={}
  for i=1,4 do
    local x=24+((i-1)%2)*265; local y=-333-math.floor((i-1)/2)*69
    local item=WG:Button(f,'',x,y,254,60,function()
      local current=WG:ThemePaletteOptions()[i]
      if current then
        WG:SetThemeColor(current[1])
        WG:Say(current[1]..' colorway selected for '..WG:ThemeName()..'.')
      end
    end)
    item.swatches={}
    for j,key in ipairs({'bg','panel','edge','accent'}) do
      local swatch=item:CreateTexture(nil,'OVERLAY')
      swatch:SetSize(31,9);swatch:SetPoint('BOTTOMLEFT',item,'BOTTOMLEFT',14+(j-1)*37,7)
      item.swatches[j]=swatch
    end
    self.paletteButtons[i]=item
  end
  self.paletteLabel=WG:Text(f,'',25,-490,12,'accent')
  self.themeLabel=WG:Text(f,'',285,-490,12,'accent')
  WG:Text(f,'Themes and colorways work with all four interfaces.',25,-509,10,'text',347)
  WG:Button(f,'FOUR UI STYLES',379,-498,170,34,function()WG:Open('studio');if WG.studio then WG.studio:Select('STYLES')end end)
end
function U:Layout()
  local f=WG:Window('layout','Layout & Recovery',565,561)
  WG:Text(f,'MOVE, SCALE AND RECOVER',24,-82,15,'accent')
  WG:Text(f,'HUD: left-drag the small + tab. Right-click it to lock one frame.',24,-110,12,'text',520)
  WG:Divider(f,-137,517,24)
  WG:Text(f,'WINDOW SCALE',24,-165,13,'accent')
  for i,pct in ipairs({90,100,110}) do
    WG:Button(f,tostring(pct)..'%',24+(i-1)*177,-194,161,41,function()
      WG.db.windowScale=pct/100
      for key,w in pairs(WG.windows) do WG:ApplyWindowScale(key,w) end
      WG:Say('Window scale: '..pct..'%')
    end)
  end
  self:LayoutToggle(f,'lockWindows','LOCK WINDOW POSITIONS',-251)
  self:LayoutToggle(f,'hudDragLocked','LOCK ALL HUD DRAG HANDLES',-360)
  self:LayoutToggle(f,'oneWindow','ONE WINDOW AT A TIME',-290)
  self:LayoutToggle(f,'bagKeyOverride','USE B KEY FOR WAFFLE PANTRY',-329)
  WG:Divider(f,-401,517,24)
  local edit=WG:Button(f,'EDIT MODE - MOVE HUD FRAMES',24,-414,513,35,function()WG:ToggleEditMode()end)
  self.editButtons=self.editButtons or {};self.editButtons[#self.editButtons+1]=edit
  WG:Button(f,'RESET ALL POSITIONS',24,-466,247,35,function()WG:ResetLayout()end)
  WG:Button(f,'RESTORE BLIZZARD UI',288,-466,249,35,function()WG:RecoverUI()end)
end
function U:LayoutToggle(f,key,text,y)
  local box=CreateFrame('CheckButton',nil,f,'UICheckButtonTemplate')
  box:SetSize(25,25);box:SetPoint('TOPLEFT',f,'TOPLEFT',24,y)
  WG:Text(f,text,60,y-4,12,'text')
  box:SetChecked(WG.db[key] == true)
  self.layoutChecks=self.layoutChecks or {};self.layoutChecks[#self.layoutChecks+1]={key=key,box=box}
  box:SetScript('OnClick',function()WG.db[key]=box:GetChecked();WG:Refresh()end)
end
function U:Profiles()
  local f=WG:Window('profiles','Saved Profiles',535,425)
  WG:Text(f,'YOUR GUILD LOADOUTS',24,-83,16,'accent')
  WG:Text(f,'Save features, themes, window positions and HUD layouts.',24,-109,11,'text')
  WG:Divider(f,-135,489,24)
  self.profileLabels={}
  for i,name in ipairs({'SOLO','GROUP','RAID'}) do
    local y=-159-(i-1)*75
    self.profileLabels[name]=WG:Text(f,name..'  /  NOT SAVED',26,y,13,'text')
    WG:Button(f,'SAVE CURRENT',252,y-8,119,39,function()WG:SaveProfile(name)end)
    WG:Button(f,'LOAD',386,y-8,121,39,function()WG:LoadProfile(name)end)
  end
  WG:Text(f,'Older profiles without positions still preserve your current layout.',26,-393,11,'text')
end
-- Return a distinct copy; profiles must never share mutable position tables.
local function copyLayout(source)
  local result={}
  for key,point in pairs(source or {}) do
    if type(point)=='table' and type(point.x)=='number' and type(point.y)=='number' then
      result[key]={x=point.x,y=point.y}
    end
  end
  return result
end
-- Copy plain configuration only; never copy frames or saved data by reference.
local function copyConfig(source,depth)
  if type(source)~='table' or (depth or 0)>4 then return {} end
  local result={}
  for k,v in pairs(source) do
    if type(k)=='string' and type(v)=='table' then result[k]=copyConfig(v,(depth or 0)+1)
    elseif type(k)=='string' and (type(v)=='string' or type(v)=='number' or type(v)=='boolean') then
      result[k]=v
    end
  end
  return result
end
function WG:SaveProfile(name)
  if self:Protected() then return self:Say('Save profiles after leaving combat.') end
  -- Read the actual onscreen positions so a profile matches the layout the
  -- player is using, including an independently positioned XP bar.
  for key,frame in pairs(self.hudFrames or {}) do self:SaveHUDPosition(key,frame) end
  local features={}
  for id,value in pairs(self.db.features) do features[id]=value end
  local themeColors={}
  for k,v in pairs(self.db.themeColors or {}) do themeColors[k]=v end
  self.db.profiles[name]={
    features=features,palette=self.db.palette,visualTheme=self.db.visualTheme,uiStyle=self:StyleName(),
    themeColors=themeColors,styleThemeChoices=copyConfig(self.db.styleThemeChoices),windowScale=self.db.windowScale,windowScales=copyConfig(self.db.windowScales),
    lockWindows=self.db.lockWindows,hudDragLocked=self.db.hudDragLocked,
    hudElementLocks=copyConfig(self.db.hudElementLocks),oneWindow=self.db.oneWindow,
    hudPositions=copyLayout(self.db.hudPositions),
    windowPositions=copyLayout(self.db.windowPositions),
    auraStudio=copyConfig(self.db.auraStudio),
    threatWatch=copyConfig(self.db.threatWatch),
    threatWatch2=copyConfig(self.db.threatWatch2),
    partyStudio=copyConfig(self.db.partyStudio),
    questStudio=copyConfig(self.db.questStudio),
    modernHUD=copyConfig(self.db.modernHUD),
    tacticalHUD=copyConfig(self.db.tacticalHUD),
    expeditionHUD=copyConfig(self.db.expeditionHUD),
    threatCompanion=copyConfig(self.db.threatCompanion),
    questieSkin=copyConfig(self.db.questieSkin),
  }
  self:Refresh();self:Say(name..' profile saved with HUD and window positions.')
end
function WG:LoadProfile(name)
  local profile=self.db.profiles and self.db.profiles[name]
  if not profile then return self:Say('Save a '..name..' profile first.') end
  if self:Protected() then return self:Say('Load profiles after leaving combat.') end
  if self.editMode then self:EditMode(false) end
  for id,v in pairs(profile.features or {}) do if self.db.features[id]~=nil then self.db.features[id]=v end end
  self.db.palette=self.palettes[profile.palette] and profile.palette or 'Maple'
  self.db.visualTheme=self.themeLogos[profile.visualTheme] and profile.visualTheme or 'Waffles'
  if profile.uiStyle then
    for _,style in ipairs(self.uiStyles) do if style==profile.uiStyle then self.db.uiStyle=style;break end end
  end
  self.db.themeColors={}
  if type(profile.themeColors)=='table' then
    for key,color in pairs(profile.themeColors) do self.db.themeColors[key]=color end
  end
  if type(profile.styleThemeChoices)=='table' then
    self.db.styleThemeChoices=copyConfig(profile.styleThemeChoices)
    -- The profile's active colors take precedence over a stored style entry.
    self:RememberStyleTheme(self:StyleName())
  else
    self:RememberStyleTheme(self:StyleName())
  end
  -- Older profiles do not carry combat-tool settings. Preserve current values.
  if type(profile.auraStudio)=='table' then self.db.auraStudio=copyConfig(profile.auraStudio) end
  if type(profile.threatWatch)=='table' then self.db.threatWatch=copyConfig(profile.threatWatch) end
  if type(profile.threatWatch2)=='table' then self.db.threatWatch2=copyConfig(profile.threatWatch2) end
  if type(profile.partyStudio)=='table' then self.db.partyStudio=copyConfig(profile.partyStudio) end
  if type(profile.questStudio)=='table' then self.db.questStudio=copyConfig(profile.questStudio) end
  for _,key in ipairs({'modernHUD','tacticalHUD','expeditionHUD','threatCompanion','questieSkin'}) do
    if type(profile[key])=='table' then self.db[key]=copyConfig(profile[key]) end
  end
  self.db.windowScale=profile.windowScale or 1
  if type(profile.windowScales)=='table' then self.db.windowScales=copyConfig(profile.windowScales) end
  self.db.lockWindows=profile.lockWindows or false
  self.db.hudDragLocked=profile.hudDragLocked==true
  self.db.hudElementLocks=copyConfig(profile.hudElementLocks)
  self.db.oneWindow=profile.oneWindow~=false
  -- Pre-v3.1 profiles had no positions. Never reset a user's carefully moved
  -- HUD when loading one of those older profiles.
  if type(profile.hudPositions)=='table' then
    self.db.hudPositions=copyLayout(profile.hudPositions)
    for key,frame in pairs(self.hudFrames or {}) do
      local point=self.db.hudPositions[key]
      frame:ClearAllPoints()
      if point then
        frame:SetPoint('CENTER',UIParent,'CENTER',point.x,point.y)
      elseif self.hudDefaults and self.hudDefaults[key] then
        local d=self.hudDefaults[key]
        frame:SetPoint(d[1],d[2],d[3],d[4],d[5])
      end
    end
    if self.db.hudPositions.launcher then
      self.db.launcherPos={x=self.db.hudPositions.launcher.x,y=self.db.hudPositions.launcher.y}
    end
  end
  if type(profile.windowPositions)=='table' then
    self.db.windowPositions=copyLayout(profile.windowPositions)
    for key,frame in pairs(self.windows or {}) do
      self:RestoreWindowPosition(key,frame,frame.isBag)
    end
  end
  self:Refresh();self:UpdateHUDGrips();self:Say(name..' profile loaded.')
end
function U:Help()
  local f=WG:Window('help','Help & About',560,585)
  WG:Text(f,'WAFFLES GANG  /  GUILD EDITION',25,-82,16,'accent')
  WG:Text(f,'Your original codebase, with a redesigned modular interface.',25,-112,12,'text',512)
  WG:Divider(f,-141,510,25)
  local help={
    {'/wg','Open Waffle Studio'},{'/wg studio','Unified settings + party preview'},{'/wg quests','Simple quest journal / Questie status'},{'/wg adventure','Session stats and readiness'},{'/wg party','Party manager'},
    {'/wg loot','Loot methods'},{'/wg guild','Guild Manager'},
    {'/wg guildboard','Read Discord events synced from deputywaffles.com'},{'/wg recruitment','Recruitment and welcome drafts'},
    {'/wg automation','Quest, junk and full-bag options'},{'/wg bags','Waffle Pantry'},
    {'/wg threat','Threat Watch meter and options'},{'/wg auras','Buff/debuff controls'},
    {'/wg settings','Feature settings'},{'/wg chat','Chat and native menu colors'},{'/wg appearance','Color palettes'},
    {'/wg layout','Drag HUD grips / lock / scale'},{'/wg profiles','Solo / Group / Raid'},{'/wg recover','Restore Blizzard bars and frames'},
  }
  for i,row in ipairs(help) do
    local col=(i-1)%2;local n=math.floor((i-1)/2)
    local x=25+col*268;local y=-156-n*30
    WG:Text(f,row[1],x,y,11,'accent')
    WG:Text(f,row[2],x,y-14,9,'text',253)
  end
  WG:Text(f,'Combat-sensitive operations may be deferred until combat ends.',25,-551,10,'text',490)
end
function U:Refresh()
  if self.launcher then self.launcher:SetShown(WG:Enabled('launcher')) end
  if self.paletteLabel then self.paletteLabel:SetText('COLORWAY / '..WG:CurrentPaletteName()) end
  if self.themeLabel then self.themeLabel:SetText('THEME / '..WG:ThemeName()) end
  if self.themeDescriptionLabel then self.themeDescriptionLabel:SetText(WG.themeDescriptions[WG:ThemeName()] or '') end
  for name,b in pairs(self.themeButtons or {}) do if b.label then b.label:SetText((name==WG.db.visualTheme and '●  ' or '')..name) end end
  for _,row in ipairs(self.themeIconPairs or {}) do
    row.icon:SetTexture(WG.db.visualTheme=='Waffles' and row.original or WG:CurrentLogo())
  end
  for _,label in ipairs(self.themeCaptions or {}) do
    label:SetText(WG:StyleName()=='Modern' and ('WAFFLES GANG  /  '..WG:ThemeName()..' WORKSPACE') or
      (WG:StyleName()=='Tactical' and ('W/G  //  '..string.upper(WG:ThemeName())..'  /  '..string.upper(WG:CurrentPaletteName())) or
      (WG:StyleName()=='Adventure' and ('EXPEDITION  /  '..string.upper(WG:ThemeName())) or
      (WG.db.visualTheme=='Waffles' and 'WAFFLES GANG  /  GUILD INTERFACE' or
      ('WAFFLES GANG  /  '..string.upper(WG.db.visualTheme or 'Waffles')..' THEME')))))
  end
  local choices=WG:ThemePaletteOptions()
  for index,b in ipairs(self.paletteButtons or {}) do
    local item=choices[index]
    if b and item then
      local active=WG:CurrentPaletteName()==item[1]
      b.label:SetText((active and '●  ' or '')..item[1])
      local p=item[2]
      for j,key in ipairs({'bg','panel','edge','accent'}) do
        local color=p[key]
        if b.swatches and b.swatches[j] then b.swatches[j]:SetColorTexture(rgb(color)) end
      end
      b:SetAlpha(active and 1 or .90)
    end
  end
  for _,c in ipairs(WG.checks or {}) do c.button:SetChecked(WG:Enabled(c.key)) end
  for _,c in ipairs(self.layoutChecks or {}) do c.box:SetChecked(WG.db[c.key]==true) end
  for n,t in pairs(self.profileLabels or {}) do
    t:SetText(n..(WG.db.profiles and WG.db.profiles[n] and '  /  SAVED' or '  /  NOT SAVED'))
  end
  for key,f in pairs(WG.windows) do WG:ApplyWindowScale(key,f) end
  for _,btn in ipairs(self.editButtons or {}) do btn.label:SetText(WG.editMode and 'SAVE & LOCK' or 'EDIT MODE') end
  WG:UpdateHUDGrips()
end
