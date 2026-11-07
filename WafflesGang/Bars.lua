-- Waffles Gang action buttons. Keeps the original secure action assignments.
local WG=_G.WafflesGang
local A={name='Action Bars / XP',slots={},hidden={}}
table.insert(WG.modules,A)
local media='Interface\\AddOns\\WafflesGang\\Media\\'
-- Per-interface rendering, saved independently of Rain's food theme/colorway.
function A:ModernSettings()
  if not WG.db then return {gap=8,iconSize=40,xpWidth=455,xpOpacity=.98,xpText=true,xpHeight=12} end
  if type(WG.db.modernHUD)~='table' then WG.db.modernHUD={} end
  local o=WG.db.modernHUD
  local defaults={gap=8,iconSize=40,xpWidth=455,xpOpacity=.98,xpText=true,xpHeight=12,chatOpacity=.39}
  for k,v in pairs(defaults) do if o[k]==nil then o[k]=v end end
  o.gap=math.max(2,math.min(15,tonumber(o.gap) or 8))
  o.iconSize=math.max(34,math.min(48,tonumber(o.iconSize) or 40))
  o.xpWidth=math.max(250,math.min(650,tonumber(o.xpWidth) or 455))
  o.xpOpacity=math.max(.5,math.min(1,tonumber(o.xpOpacity) or .98))
  o.xpHeight=math.max(8,math.min(18,tonumber(o.xpHeight) or 12))
  o.chatOpacity=math.max(.12,math.min(.85,tonumber(o.chatOpacity) or .39))
  return o
end

local function bindingFor(action)
  local binding=(action<=12) and ('ACTIONBUTTON'..action) or ('MULTIACTIONBAR1BUTTON'..(action-60))
  if not GetBindingKey then return '' end
  local ok,key=pcall(GetBindingKey,binding)
  if not ok or not key then return '' end
  key=key:gsub('SHIFT%-','S-'):gsub('CTRL%-','C-'):gsub('ALT%-','A-')
  return key
end
function A:MakeSlot(parent,action,row,col)
  local b=CreateFrame('Button','WG_Action_'..action,parent,'SecureActionButtonTemplate')
  b:SetSize(39,39)
  b:SetPoint('BOTTOMLEFT',parent,'BOTTOMLEFT',18+col*43,25+row*44)
  b:RegisterForClicks('AnyUp','AnyDown')
  b:SetAttribute('type','action');b:SetAttribute('action',action)
  b:SetAttribute('useOnKeyDown',GetCVar and GetCVar('ActionButtonUseKeyDown')=='1' or false)
  local frameSurface=WG:Surface(b,'panel','edge')
  -- Modern keeps secure buttons in their slots for keybindings and drag/drop,
  -- while hiding the 24 empty square frames and showing a soft shell only for
  -- populated slots. This is presentation only and never changes action IDs.
  local softShell=WG.ModernRounded and WG:ModernRounded(b,'SoftPanel') or nil
  local softEdge=WG.ModernRounded and WG:ModernRounded(b,'SoftOutline') or nil
  local tacticalBase=b:CreateTexture(nil,'BACKGROUND',nil,3)
  tacticalBase:SetAllPoints();tacticalBase:SetTexture('Interface\\Buttons\\WHITE8X8')
  local tacticalEdge=b:CreateTexture(nil,'OVERLAY',nil,5)
  tacticalEdge:SetAllPoints();tacticalEdge:SetTexture('Interface\\Buttons\\WHITE8X8')
  local occupied=false
  local function paintSlot()
    local modern=WG:StyleName()=='Modern'
    local tactical=WG:StyleName()=='Tactical'
    local adventure=WG:StyleName()=='Adventure'
    local c=WG:Color('edge')
    local accent=WG:Color('accent')
    tacticalBase:SetShown((tactical or adventure) and occupied)
    tacticalEdge:SetShown((tactical or adventure) and occupied)
    tacticalBase:SetVertexColor(adventure and .05 or .014,adventure and .10 or .018,
      adventure and .09 or .024,adventure and .36 or WG:TacticalSettings().barOpacity*.55)
    tacticalEdge:SetVertexColor(accent[1],accent[2],accent[3],adventure and .18 or .09)
    if softShell then
      softShell:SetShown(modern and occupied)
      softShell:SetColor(.025,.038,.056,.55)
    end
    if softEdge then
      softEdge:SetShown(modern and occupied)
      softEdge:SetColor(c[1],c[2],c[3],.29)
    end
  end
  local modernAccent=b:CreateTexture(nil,'OVERLAY')
  modernAccent:SetPoint('BOTTOMLEFT',b,'BOTTOMLEFT',0,0)
  modernAccent:SetPoint('BOTTOMRIGHT',b,'BOTTOMRIGHT',0,0)
  modernAccent:SetHeight(2)
  table.insert(WG.surfaces,{repaint=function()
    local modern=WG:StyleName()=='Modern'
    local tactical=WG:StyleName()=='Tactical'
    modernAccent:SetShown(false)
    local c=WG:Color('accent')
    modernAccent:SetColorTexture(c[1],c[2],c[3],.87)
    -- Truly floating icons in Modern: no solid cell background, just
    -- an optional hairline and a tiny color-keyed underline.
    frameSurface.bg:SetAlpha((modern or tactical or WG:StyleName()=='Adventure') and 0 or 1)
    frameSurface.edge:SetAlpha((modern or tactical or WG:StyleName()=='Adventure') and 0 or 1)
    paintSlot()
  end})
  local icon=b:CreateTexture(nil,'ARTWORK')
  icon:SetPoint('TOPLEFT',b,'TOPLEFT',3,-3)
  icon:SetPoint('BOTTOMRIGHT',b,'BOTTOMRIGHT',-3,3)
  icon:SetTexCoord(.07,.93,.07,.93)
  if b.CreateMaskTexture and icon.AddMaskTexture then
    local mask=b:CreateMaskTexture(nil,'ARTWORK')
    mask:SetAllPoints(icon)
    local ok=pcall(icon.AddMaskTexture,icon,mask)
    if ok then
      table.insert(WG.surfaces,{repaint=function()
        mask:SetTexture(media..'Modern\\'..(WG:StyleName()=='Modern' and 'SoftIcon' or 'SquarePortrait'))
      end})
    end
  end
  local sheen=b:CreateTexture(nil,'OVERLAY')
  sheen:SetPoint('TOPLEFT',b,'TOPLEFT',3,-3)
  sheen:SetPoint('TOPRIGHT',b,'TOPRIGHT',-3,-3)
  sheen:SetHeight(2);sheen:SetColorTexture(1,1,1,.38)
  table.insert(WG.surfaces,{repaint=function()
    sheen:SetShown(WG:StyleName()=='Classic')
  end})
  local key=WG:Text(b,'',3,-3,9,'accent')
  local qty=WG:Text(b,'',22,-27,10,'text')
  local cooldown=CreateFrame('Cooldown',nil,b,'CooldownFrameTemplate')
  cooldown:SetAllPoints(icon)
  -- Readable cooldown text and swipe are ON by default. Only the dedicated
  -- action-cooldown feature can disable them.
  if cooldown.SetDrawSwipe then cooldown:SetDrawSwipe(true) end
  if cooldown.SetDrawEdge then cooldown:SetDrawEdge(true) end
  if cooldown.SetSwipeColor then cooldown:SetSwipeColor(.05,.025,.01,.72) end
  if cooldown.SetHideCountdownNumbers then cooldown:SetHideCountdownNumbers(false) end
  if cooldown.GetCountdownFontString then
    local ok,font=pcall(cooldown.GetCountdownFontString,cooldown)
    if ok and font then
      font:SetFont(STANDARD_TEXT_FONT or 'Fonts\\FRIZQT__.TTF',14,'OUTLINE')
      font:SetTextColor(1,.97,.81)
    end
  end
  b:SetScript('OnEnter',function(self)
    if GameTooltip then
      GameTooltip:SetOwner(self,'ANCHOR_RIGHT')
      if GameTooltip.SetAction then GameTooltip:SetAction(action) end
      GameTooltip:Show()
    end
  end)
  b:SetScript('OnLeave',function()if GameTooltip then GameTooltip:Hide()end end)
  b:RegisterForDrag('LeftButton')
  b:SetScript('OnDragStart',function()
    if WG:Protected() then return end
    if PickupAction then PickupAction(action) end
  end)
  b:SetScript('OnReceiveDrag',function()
    if WG:Protected() then return end
    if PlaceAction then PlaceAction(action) end
    A:UpdateIcons()
  end)
  return {button=b,icon=icon,qty=qty,key=key,cooldown=cooldown,
    action=action,secondary=row==1,setOccupied=function(value)
      occupied=value==true
      paintSlot()
      modernAccent:SetShown(false)
      sheen:SetShown(WG:StyleName()=='Classic')
    end}
end
-- Apply usability colors with a single client API read per button. In newer
-- clients an action's usability can be a protected/secret value; keep both the
-- read and tint inside pcall, and never compare the result elsewhere in Lua.
-- A failed read leaves the icon normal instead of breaking all action bars.
function A:UpdateUsable()
  for _,p in ipairs(self.slots) do
    local tex=p.icon
    if not WG:Enabled('greyunusable') then
      tex:SetDesaturated(false)
      tex:SetVertexColor(1,1,1,1)
    else
      local source=(C_ActionBar and C_ActionBar.IsUsableAction) or IsUsableAction
      if not source then
        tex:SetDesaturated(false)
        tex:SetVertexColor(1,1,1,1)
      else
        local ok=pcall(function()
          local usable=source(p.action)
          -- Distinguish an unused/empty action slot from an unusable skill.
          -- The icon itself is hidden when the slot has no texture.
          tex:SetDesaturated(not usable)
          if usable then tex:SetVertexColor(1,1,1,1)
          else tex:SetVertexColor(.58,.58,.58,1) end
        end)
        if not ok then
          tex:SetDesaturated(false)
          tex:SetVertexColor(1,1,1,1)
        end
      end
    end
  end
end
function A:UpdateIcons()
  for _,p in ipairs(self.slots) do
    local getTexture=(C_ActionBar and C_ActionBar.GetActionTexture) or GetActionTexture
    if getTexture then
      local ok,texture=pcall(getTexture,p.action)
      if ok then
        -- The icon's texture can be protected; never branch on it in combat.
        pcall(p.icon.SetTexture,p.icon,texture)
      end
      local hasFn=HasAction or (C_ActionBar and C_ActionBar.HasAction)
      if not WG:Protected() and hasFn then
        local good,has=pcall(hasFn,p.action)
        if good and (not issecretvalue or not issecretvalue(has)) then
          p.setOccupied(has==true)
        end
      elseif not WG:Protected() and ok and (not issecretvalue or not issecretvalue(texture)) then
        -- Fallback for clients without HasAction. No secret data is inspected.
        p.setOccupied(texture~=nil and texture~=0)
      end
    end
    -- Never branch on secret action counts in combat.
    if GetActionCount and not WG:Protected() then
      local ok,count=pcall(GetActionCount,p.action)
      if ok and type(count)=='number' and count>1 then p.qty:SetText(count)
      else p.qty:SetText('') end
    end
    if not WG:Protected() then p.key:SetText(bindingFor(p.action)) end
  end
  self:UpdateUsable()
end
function A:UpdateCooldowns()
  local enabled=WG:Enabled('actioncooldowns')
  for _,p in ipairs(self.slots) do
    local frame=p.cooldown
    if frame.SetHideCountdownNumbers then frame:SetHideCountdownNumbers(not enabled) end
    if frame.SetDrawSwipe then frame:SetDrawSwipe(enabled) end
    if frame.SetDrawEdge then frame:SetDrawEdge(enabled) end
    if not enabled then
      -- Clearing is only done with ordinary literal values, never secret data.
      if frame.SetCooldown then pcall(frame.SetCooldown,frame,0,0) end
      frame:Hide()
    else
      frame:Show()
      local applied=false
      -- Forever's supported duration object avoids secret numeric cooldowns.
      if C_ActionBar and C_ActionBar.GetActionCooldownDuration and frame.SetCooldownFromDurationObject then
        local ok,duration=pcall(C_ActionBar.GetActionCooldownDuration,p.action)
        if ok and duration then
          applied=pcall(frame.SetCooldownFromDurationObject,frame,duration,true)
        end
      end
      -- Legacy fallback only if the duration-object API isn't available.
      if not applied then
        if C_ActionBar and C_ActionBar.GetActionCooldown and frame.SetCooldown then
          local ok,info=pcall(C_ActionBar.GetActionCooldown,p.action)
          if ok and info then
            applied=pcall(frame.SetCooldown,frame,info.startTime,info.duration,info.modRate or 1)
          end
        elseif GetActionCooldown and frame.SetCooldown then
          local ok,started,duration,_,rate=pcall(GetActionCooldown,p.action)
          if ok then applied=pcall(frame.SetCooldown,frame,started,duration,rate or 1) end
        end
      end
      -- An empty slot / no duration should never retain an old timer.
      if not applied and frame.SetCooldown then pcall(frame.SetCooldown,frame,0,0) end
    end
  end
end
function A:UpdateXP()
  if not self.xp or not WG.db then return end
  local show=WG:Enabled('xpbar')
  if WG:Protected() then return end
  self.xp:SetShown(show)
  if not show or not UnitXP or not UnitXPMax then return end
  local xp=UnitXP('player') or 0;local cap=UnitXPMax('player') or 0
  if cap==0 then
    self.xpBar:SetMinMaxValues(0,1);self.xpBar:SetValue(1)
    self.xpText:SetText('MAX LEVEL')
  else
    self.xpBar:SetMinMaxValues(0,cap);self.xpBar:SetValue(xp)
    if WG:StyleName()=='Modern' or WG:StyleName()=='Tactical' then
      self.xpText:SetText(('LEVEL %d  /  %d%%'):format(UnitLevel and (UnitLevel('player') or 0) or 0,math.floor(xp/cap*100+.5)))
    else
      self.xpText:SetText(('XP  %d / %d'):format(xp,cap))
    end
  end
  self.xpBar:SetStatusBarColor(WG.unpack(WG:Color('accent')))
end
-- Forever uses several action-bar frame families.  Edit Mode can create new
-- bars, bag widgets, and artwork after PLAYER_LOGIN, so collect by frame name
-- each time the replacement is applied rather than assuming the 2019 layout.
-- Do not Hide(), reparent, or unregister events on Blizzard secure frames:
-- alpha keeps Blizzard bindings/state handlers alive and is safely reversible.
local xpBlizzardFrames={MainStatusTrackingBarContainer=true,StatusTrackingBarManager=true,MainMenuExpBar=true,ReputationWatchBar=true}
local actionBarFrames={
  'MainActionBar','MainActionBarFrame','MainMenuBar','MainMenuBarArtFrame',
  'MainMenuBarLeftEndCap','MainMenuBarRightEndCap',
  'MultiBarBottomLeft','MultiBarBottomRight','MultiBarLeft','MultiBarRight',
  'MultiBar5','MultiBar6','MultiBar7','MultiBar8',
  'MainStatusTrackingBarContainer','StatusTrackingBarManager',
  'MainMenuExpBar','ReputationWatchBar',
}
local actionButtonPrefixes={
  'ActionButton','MultiBarBottomLeftButton','MultiBarBottomRightButton',
  'MultiBarLeftButton','MultiBarRightButton','MultiBar5Button',
  'MultiBar6Button','MultiBar7Button','MultiBar8Button',
}
local bagBarFrames={
  'BagsBar','BagsBarFrame','BagBar','BagBarFrame','BagBarExpandToggle',
  'MainMenuBarBackpackButton','MainMenuBarBagButton',
  'MainMenuBarBackpackButtonCount',
  'CharacterBag0Slot','CharacterBag1Slot','CharacterBag2Slot',
  'CharacterBag3Slot','CharacterReagentBag0Slot',
  'BackpackButton','BackpackTokenFrame',
}
local function collectBagFrames()
  local result={}
  for _,name in ipairs(bagBarFrames) do result[#result+1]=name end
  -- Some Forever builds put the bag widgets directly under this shared
  -- container. If no independent BagsBar exists, hide the shared parent as a
  -- fallback (this may hide the stock micro menu as well).
  if not (_G.BagsBar or _G.BagsBarFrame or _G.BagBar or _G.BagBarFrame) then
    result[#result+1]='MicroButtonAndBagsBar'
  end
  return result
end
function A:SetBlizzardAlpha(frame,hide)
  if not frame or not frame.SetAlpha then return end
  if frame.IsForbidden then
    local ok,forbidden=pcall(frame.IsForbidden,frame)
    if ok and forbidden then return end
  end
  -- Keep a snapshot only for frames we actually changed. This allows toggle
  -- off /wg recover to restore the alpha that was there before Waffles Gang.
  if hide then
    if self.hidden[frame]==nil then
      local ok,old=pcall(frame.GetAlpha,frame)
      self.hidden[frame]=ok and old or 1
    end
    local ok=pcall(frame.SetAlpha,frame,0)
    if not ok then self.hidden[frame]=nil end
  elseif self.hidden[frame]~=nil then
    local ok=pcall(frame.SetAlpha,frame,self.hidden[frame])
    if ok then self.hidden[frame]=nil end
  end
end
function A:Blizzard()
  if WG:Protected() then return end
  local replaceBars=WG:Enabled('actionbars')
  -- Pantry is its own replacement; it must NOT depend on the advanced
  -- 'replaceui' toggle for unit frames. This was the previous bag-bar bug.
  local replaceBags=WG:Enabled('bags')
  for _,name in ipairs(actionBarFrames) do
    self:SetBlizzardAlpha(_G[name],replaceBars or (WG:Enabled('xpbar') and xpBlizzardFrames[name]))
  end
  local mouseTargets=self.mouseOriginal or {}
  self.mouseOriginal=mouseTargets
  for _,prefix in ipairs(actionButtonPrefixes) do
    for i=1,12 do
      local button=_G[prefix..i]
      if button then
        self:SetBlizzardAlpha(button,replaceBars)
        if button.EnableMouse then
          if replaceBars then
            if mouseTargets[button]==nil then
              mouseTargets[button]=(not button.IsMouseEnabled) or button:IsMouseEnabled()
            end
            pcall(button.EnableMouse,button,false)
          elseif mouseTargets[button]~=nil then
            if pcall(button.EnableMouse,button,mouseTargets[button]) then mouseTargets[button]=nil end
          end
        end
      end
    end
  end
  for _,name in ipairs(collectBagFrames()) do
    local frame=_G[name]
    self:SetBlizzardAlpha(frame,replaceBags)
    if frame and frame.EnableMouse then
      if replaceBags then
        if mouseTargets[frame]==nil then
          mouseTargets[frame]=(not frame.IsMouseEnabled) or frame:IsMouseEnabled()
        end
        pcall(frame.EnableMouse,frame,false)
      elseif mouseTargets[frame]~=nil then
        if pcall(frame.EnableMouse,frame,mouseTargets[frame]) then mouseTargets[frame]=nil end
      end
    end
  end
end
-- Some Blizzard edit-mode updates repaint/restore these frames after login.
-- A lightweight watch checks both independent replacement states, including
-- the bag bar. No secure UI attributes or CVar assignments are changed here.
function A:BlizzardNeedsRefresh()
  local function visible(name)
    local f=_G[name]
    if f and f.IsShown and not f:IsShown() then return false end
    return f and f.GetAlpha and f:GetAlpha()>0
  end
  if WG:Enabled('actionbars') or WG:Enabled('xpbar') then
    for _,name in ipairs(actionBarFrames) do
      if (WG:Enabled('actionbars') or xpBlizzardFrames[name]) and visible(name) then return true end
    end
    for _,prefix in ipairs(actionButtonPrefixes) do
      for i=1,12 do if visible(prefix..i) then return true end end
    end
  end
  if WG:Enabled('bags') then
    for _,name in ipairs(collectBagFrames()) do if visible(name) then return true end end
  end
  return false
end
function A:Init()
  local strip=CreateFrame('Frame','WG_ActionBars',UIParent)
  strip:SetSize(553,115);strip:SetPoint('BOTTOM',UIParent,'BOTTOM',0,31)
  strip:SetFrameStrata('MEDIUM')
  self.strip=strip
  WG:RegisterHUDFrame('actionbars',strip,'Action Bars')
  local stripSkin=WG:Surface(strip,'bg','edge')
  self.stripSkin=stripSkin
  table.insert(WG.surfaces,{repaint=function()
    local floating=WG:StyleName()=='Modern'
    local bare=floating or WG:StyleName()=='Tactical' or WG:StyleName()=='Adventure'
    stripSkin.bg:SetAlpha(bare and 0 or 1)
    stripSkin.edge:SetAlpha(bare and 0 or 1)
    if stripSkin.grain then stripSkin.grain:SetAlpha(bare and 0 or .68) end
  end})
  local actionShell=strip:CreateTexture(nil,'ARTWORK')
  actionShell:SetAllPoints()
  table.insert(WG.surfaces,{repaint=function()
    local style=WG:StyleName()
    actionShell:SetShown(false)
    -- Adventure uses a scalable journal dock rather than a stretched Classic-like panel.
    -- The legacy full-bleed action-shell texture is intentionally retired.
  end})
  local travelDock=WG:AdventurePanel(strip,19)
  WG.surfaces[#WG.surfaces+1]={repaint=function()
    local adventure=WG:StyleName()=='Adventure'
    travelDock:SetShown(adventure)
    if adventure then travelDock:SetColor(1,1,1,WG:ExpeditionSettings().dockOpacity) end
  end}
  local northRule=strip:CreateTexture(nil,'OVERLAY')
  northRule:SetPoint('TOPLEFT',strip,'TOPLEFT',20,-18)
  northRule:SetPoint('TOPRIGHT',strip,'TOPRIGHT',-20,-18)
  northRule:SetHeight(1)
  WG.surfaces[#WG.surfaces+1]={repaint=function()
    local c=WG:Color('accent');northRule:SetColorTexture(c[1],c[2],c[3],.51)
    northRule:SetShown(WG:StyleName()=='Adventure')
  end}
  -- Plain machined seam and bank separator, never the Classic waffle dock.
  local tacticalSeam=strip:CreateTexture(nil,'OVERLAY')
  tacticalSeam:SetPoint('TOPLEFT',strip,'TOPLEFT',6,-3)
  tacticalSeam:SetPoint('TOPRIGHT',strip,'TOPRIGHT',-6,-3)
  tacticalSeam:SetHeight(1)
  local tacticalBank=strip:CreateTexture(nil,'OVERLAY')
  tacticalBank:SetPoint('TOP',strip,'TOP',0,-14)
  tacticalBank:SetPoint('BOTTOM',strip,'BOTTOM',0,6)
  tacticalBank:SetWidth(1)
  WG.surfaces[#WG.surfaces+1]={repaint=function()
    local active=WG:StyleName()=='Tactical'
    local c=WG:Color('accent')
    tacticalSeam:SetShown(false)
    tacticalBank:SetShown(false)
  end}
  local centerLogo=WG:Logo(strip,42,'LEFT',strip,'LEFT',-29,0)
  table.insert(WG.surfaces,{repaint=function()
    centerLogo:SetShown(WG:StyleName()=='Classic')
  end})
  local trailKit=strip:CreateFontString(nil,'OVERLAY','GameFontNormalSmall')
  trailKit:SetPoint('TOPLEFT',strip,'TOPLEFT',8,-4)
  trailKit:SetText('THE WAYFINDER KIT    /    FIELD SPELLS & SUPPLIES')
  WG.surfaces[#WG.surfaces+1]={repaint=function()
    local adventure=WG:StyleName()=='Adventure'
    local c=WG:Color('accent')
    trailKit:SetShown(adventure)
    trailKit:SetTextColor(c[1],c[2],c[3],.74)
    trailKit:SetFont(WG:StyleFont(9),9,'')
  end}
  local tacticalTitle=strip:CreateFontString(nil,'OVERLAY','GameFontNormalSmall')
  tacticalTitle:SetPoint('TOPLEFT',strip,'TOPLEFT',14,-8)
  tacticalTitle:SetText('ACTION BANK    /    PRIMARY                                  UTILITY    //    24 DIRECT BINDS')
  self.tacticalTitle=tacticalTitle
  WG.surfaces[#WG.surfaces+1]={repaint=function()
    local active=WG:StyleName()=='Tactical'
    tacticalTitle:SetShown(active and WG:TacticalSettings().showActionLabels)
    local a=WG:Color('accent')
    tacticalTitle:SetTextColor(a[1],a[2],a[3])
    tacticalTitle:SetFont(WG:StyleFont(10),10,'')
  end}
  for i=1,12 do self.slots[#self.slots+1]=self:MakeSlot(strip,i,0,i-1) end
  for i=1,12 do self.slots[#self.slots+1]=self:MakeSlot(strip,60+i,1,i-1) end
  local xp=CreateFrame('Frame','WGExperienceBar',UIParent)
  xp:SetSize(553,18);xp:SetPoint('BOTTOM',UIParent,'BOTTOM',0,10)
  WG:RegisterHUDFrame('xpbar',xp,'XP Bar')
  local xpSkin=WG:Surface(xp,'bg','edge')
  self.xpSkin=xpSkin
  local status=CreateFrame('StatusBar',nil,xp)
  status:SetPoint('TOPLEFT',xp,'TOPLEFT',3,-3)
  status:SetPoint('BOTTOMRIGHT',xp,'BOTTOMRIGHT',-3,3)
  status:SetStatusBarTexture('Interface\\Buttons\\WHITE8X8')
  status:SetStatusBarColor(WG.unpack(WG:Color('accent')))
  status:SetMinMaxValues(0,1);status:SetValue(0)
  local modernTrack=xp:CreateTexture(nil,'BACKGROUND')
  modernTrack:SetTexture(media..'Modern\\SoftBar')
  modernTrack:SetVertexColor(.07,.09,.12,.88)
  modernTrack:Hide()
  status:SetStatusBarTexture(media..'Modern\\SoftBar')
  self.xpTrack=modernTrack
  local txt=status:CreateFontString(nil,'OVERLAY','GameFontNormalSmall')
  txt:SetFont(STANDARD_TEXT_FONT or 'Fonts\\FRIZQT__.TTF',10,'OUTLINE')
  txt:SetPoint('CENTER',status,'CENTER',0,0)
  self.xp=xp;self.xpBar=status;self.xpText=txt
  xp:EnableMouse(true)
  xp:SetScript('OnEnter',function()if WG:StyleName()=='Modern' then txt:SetAlpha(1) end end)
  xp:SetScript('OnLeave',function()if WG:StyleName()=='Modern' then txt:SetAlpha(.72) end end)
  table.insert(WG.surfaces,{repaint=function()
    local modern=WG:StyleName()=='Modern'
    local tactical=WG:StyleName()=='Tactical'
    local adventure=WG:StyleName()=='Adventure'
    xpSkin.bg:SetAlpha((modern or tactical or adventure) and 0 or 1)
    xpSkin.edge:SetAlpha((modern or tactical or adventure) and 0 or 1)
    if xpSkin.grain then xpSkin.grain:SetAlpha((modern or tactical or adventure) and 0 or .68) end
    modernTrack:SetShown(modern or tactical or adventure)
    local c=WG:Color('accent')
    status:SetStatusBarTexture(modern and (media..'Modern\\SoftBar') or 'Interface\\Buttons\\WHITE8X8')
    status:SetStatusBarColor(c[1],c[2],c[3])
  end})
  local opts=WG:Window('bars','Action Bars / Experience',510,472)
  WG:Text(opts,'YOUR CUSTOM ACTION BAR',24,-82,15,'accent')
  WG:Text(opts,'Native secure action buttons with themed trim.',24,-108,11,'text',465)
  WG:Check(opts,'actionbars','Enable the Waffle action bar',24,-142)
  WG:Check(opts,'secondbar','Show the second row of actions',24,-182)
  WG:Check(opts,'actioncooldowns','Show ability cooldowns and countdown numbers',24,-222)
  WG:Check(opts,'greyunusable','Gray out unusable abilities',24,-262)
  WG:Check(opts,'xpbar','Independent experience bar (movable in Edit Mode)',24,-302)
  WG:Check(opts,'replaceui','Hide Blizzard unit frames too (advanced)',24,-342)
  WG:Button(opts,'EDIT MODE - MOVE ACTIONS / XP',24,-379,462,35,function()WG:ToggleEditMode()end)
  WG:Text(opts,'Cooldown countdowns and gray unusable icons default to ON.',24,-426,10,'text',465)
  WG:Text(opts,'Waffle bars hide Blizzard bars. /wg recover restores them.',24,-447,10,'text',465)
  WG:On('ACTIONBAR_SLOT_CHANGED',function()A:UpdateIcons();A:UpdateCooldowns()end)
  WG:On('ACTIONBAR_UPDATE_USABLE',function()A:UpdateUsable()end)
  WG:On('ACTIONBAR_UPDATE_COOLDOWN',function()A:UpdateCooldowns()end)
  WG:On('SPELL_UPDATE_COOLDOWN',function()A:UpdateCooldowns()end)
  WG:On('SPELL_UPDATE_CHARGES',function()A:UpdateCooldowns()end)
  WG:On('PLAYER_TARGET_CHANGED',function()A:UpdateUsable()end)
  WG:On('UNIT_POWER_UPDATE',function(unit) if unit=='player' then A:UpdateUsable() end end)
  WG:On('UPDATE_BINDINGS',function()A:UpdateIcons()end)
  WG:On('PLAYER_XP_UPDATE',function()A:UpdateXP()end)
  WG:On('UPDATE_EXHAUSTION',function()A:UpdateXP()end)
  WG:On('PLAYER_LEVEL_UP',function()A:UpdateXP()end)
  WG:On('PLAYER_REGEN_ENABLED',function()A:Refresh()end)
  WG:On('PLAYER_ENTERING_WORLD',function()A:Blizzard();A:UpdateIcons();A:UpdateCooldowns()end)
  -- Edit Mode or Blizzard startup may reassert alpha. Reapply outside combat
  -- for action AND bag bars; the previous watcher only checked action frames.
  local watcher=CreateFrame('Frame',nil,UIParent)
  local elapsed=0
  watcher:SetScript('OnUpdate',function(_,dt)
    if not WG.db or WG:Protected() then return end
    if not (WG:Enabled('actionbars') or WG:Enabled('bags') or WG:Enabled('xpbar')) then return end
    elapsed=elapsed+(dt or 0)
    if elapsed<.5 then return end
    elapsed=0
    if A:BlizzardNeedsRefresh() then A:Blizzard() end
  end)
  self.watcher=watcher
  -- An enabled Pantry is a bar replacement, even if the advanced unit-frame
  -- replacement option is OFF.  Refresh runs when either feature changes.
  self:UpdateIcons();self:UpdateCooldowns()
end
-- Apply one cohesive Modern HUD geometry without moving any saved anchors.
-- Secure buttons are only laid out out of combat, so spell bindings stay safe.
function A:ApplyModernLayout()
  if not self.strip or not self.xp or WG:Protected() then return end
  local style=WG:StyleName()
  local modern=style=='Modern'
  local tactical=style=='Tactical'
  local adventure=style=='Adventure'
  local o=tactical and WG:TacticalSettings() or (adventure and WG:ExpeditionSettings() or self:ModernSettings())
  local size=(modern or tactical or adventure) and o.iconSize or 39
  local gap=(modern or tactical or adventure) and o.gap or 4
  local mid=modern and 18 or 0
  local padding=modern and 10 or (tactical and 4 or (adventure and 7 or 18))
  local second=WG:Enabled('secondbar')
  -- Tactical bank: two short six-slot rows per bar, primary left, secondary right.
  -- A single primary bar now occupies ~224 px instead of a 600 px shell.
  local cols=tactical and o.actionColumns or 6
  local tacticalBankWidth=cols*size+(cols-1)*gap
  local tacticalBankGap=second and (cols==6 and 18 or 0) or 0
  local adventureCols=adventure and o.actionColumns or 12
  local advRows=adventure and (12/adventureCols) or 1
  local barWidth=tactical and (padding*2+tacticalBankWidth*(second and cols==6 and 2 or 1)+tacticalBankGap)
    or (adventure and (36+adventureCols*size+(adventureCols-1)*gap)
    or (modern and (2*padding+12*size+11*gap+mid) or 553))
  self.strip:SetWidth(barWidth)
  self.strip:SetHeight(tactical and ((12/cols)*(size+gap)-gap+padding*2+(second and cols==12 and (size+gap) or 0))
    or (adventure and ((advRows*(size+gap)-gap)*(second and 2 or 1)+(second and gap or 0)+34) or (second and (modern and (2*size+37) or 115) or (modern and (size+26) or 72))))
  for _,slot in ipairs(self.slots) do
    local button=slot.button
    button:SetSize(size,size)
    button:ClearAllPoints()
    local column=(slot.action<=12 and slot.action or slot.action-60)-1
    local row=slot.secondary and 1 or 0
    local x,y
    if tactical then
      local bank=slot.secondary and 1 or 0
      local inBank=column%cols
      x=padding+inBank*(size+gap)+(cols==6 and bank*(tacticalBankWidth+tacticalBankGap) or 0)
      y=padding+math.floor(column/cols)*(size+gap)+(cols==12 and bank*(size+gap) or 0)
    elseif adventure then
      -- A 6x4 field kit, not Classic's full-width 12x2 action slab.
      x=18+(column%adventureCols)*(size+gap)
      y=13+(math.floor(column/adventureCols)+row*advRows)*(size+gap)
    elseif modern then
      x=padding+column*(size+gap)+(column>=6 and mid or 0)
      y=18+row*(size+10)
    else
      x=18+column*43
      y=25+row*44
    end
    button:SetPoint('BOTTOMLEFT',self.strip,'BOTTOMLEFT',x,y)
    slot.icon:ClearAllPoints()
    slot.icon:SetPoint('TOPLEFT',button,'TOPLEFT',(modern or tactical or adventure) and 1 or 3,(modern or tactical or adventure) and -1 or -3)
    slot.icon:SetPoint('BOTTOMRIGHT',button,'BOTTOMRIGHT',(modern or tactical or adventure) and -1 or -3,(modern or tactical or adventure) and 1 or 3)
  end
  self.xp:SetWidth(tactical and math.min(o.xpWidth,math.max(barWidth,190)) or ((modern or adventure) and o.xpWidth or 553))
  self.xp:SetHeight((modern or tactical or adventure) and (o.xpHeight+10) or 18)
  self.xpBar:ClearAllPoints()
  self.xpText:ClearAllPoints()
  self.xpTrack:ClearAllPoints()
  if modern or tactical or adventure then
    local thick=o.xpHeight
    self.xpBar:SetPoint('BOTTOMLEFT',self.xp,'BOTTOMLEFT',0,5)
    self.xpBar:SetPoint('BOTTOMRIGHT',self.xp,'BOTTOMRIGHT',0,5)
    self.xpBar:SetHeight(thick)
    self.xpTrack:SetPoint('BOTTOMLEFT',self.xp,'BOTTOMLEFT',0,5)
    self.xpTrack:SetPoint('BOTTOMRIGHT',self.xp,'BOTTOMRIGHT',0,5)
    self.xpTrack:SetHeight(thick)
    self.xpText:SetPoint('BOTTOM',self.xp,'TOP',0,1)
    self.xpText:SetFont(WG:StyleFont(tactical and 10 or 11),tactical and 10 or 11,'')
    self.xpText:SetAlpha(.95)
    self.xpText:SetShown(o.xpText~=false)
    self.xpBar:SetAlpha(tactical and o.barOpacity or o.xpOpacity)
    self.xpTrack:SetAlpha(tactical and o.barOpacity or o.xpOpacity)
  else
    self.xpBar:SetPoint('TOPLEFT',self.xp,'TOPLEFT',3,-3)
    self.xpBar:SetPoint('BOTTOMRIGHT',self.xp,'BOTTOMRIGHT',-3,3)
    self.xpText:SetPoint('CENTER',self.xpBar,'CENTER',0,0)
    self.xpText:SetFont(STANDARD_TEXT_FONT or 'Fonts\\FRIZQT__.TTF',10,'OUTLINE')
    self.xpText:SetAlpha(1);self.xpText:Show()
    self.xpBar:SetAlpha(1)
    self.xpTrack:Hide()
  end
end
function A:Refresh()
  if not WG.db or WG:Protected() then return end
  local shown=WG:Enabled('actionbars')
  self.strip:SetShown(shown)
  self:ApplyModernLayout()
  if self.tacticalTitle then self.tacticalTitle:SetShown(WG:StyleName()=='Tactical' and WG:TacticalSettings().showActionLabels) end
  for _,slot in ipairs(self.slots) do
    if slot.secondary then slot.button:SetShown(shown and WG:Enabled('secondbar')) end
  end
  self:Blizzard();self:UpdateXP();self:UpdateIcons();self:UpdateCooldowns()
end
