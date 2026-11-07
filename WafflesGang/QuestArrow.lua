-- Waffle Quest Navigation Arrow (original artwork; no dependency on TomTom).
-- Rotates only when a selected quest supplies numeric, map-local waypoint coordinates.
local WG=_G.WafflesGang
local Q=WG.quests
if not Q then return end
local sqrt,abs,pi=math.sqrt,math.abs,math.pi
local function valid(v)
  return not (issecretvalue and issecretvalue(v)) and type(v)=='number' and v==v
    and v~=math.huge and v~=-math.huge
end
local function bearing(y,x)
  if math.atan2 then return math.atan2(y,x) end
  if x>0 then return math.atan(y/x) end
  if x<0 then return math.atan(y/x)+(y>=0 and pi or -pi) end
  return y>=0 and pi/2 or -pi/2
end
local function pointXY(v)
  if not v or (issecretvalue and issecretvalue(v)) then return end
  local ok,x,y=pcall(function()
    if v.GetXY then return v:GetXY() end
    return v.x,v.y
  end)
  if ok and valid(x) and valid(y) then return x,y end
end
local function playerPosition(map)
  if not (C_Map and C_Map.GetPlayerMapPosition) then return end
  local ok,v=pcall(C_Map.GetPlayerMapPosition,map,'player')
  if ok then return pointXY(v) end
end
local function distanceYards(map,x,y,px,py)
  if not (C_Map and C_Map.GetWorldPosFromMapPos and CreateVector2D) then return end
  -- The method returns continentID, worldPos, so fetch both without losing the second value.
  local ok1,continent1,v1=pcall(C_Map.GetWorldPosFromMapPos,map,CreateVector2D(x,y))
  local ok2,continent2,v2=pcall(C_Map.GetWorldPosFromMapPos,map,CreateVector2D(px,py))
  if ok1 and ok2 and valid(continent1) and continent1==continent2 then
    local ax,ay=pointXY(v1)
    local bx,by=pointXY(v2)
    if ax and bx then
      local n=sqrt((ax-bx)^2+(ay-by)^2)
      if valid(n) and n<200000 then return math.floor(n+.5) end
    end
  end
end
function Q:InitArrow()
  if self.arrowHUD then return end
  local f=CreateFrame('Frame','WaffleQuestNavArrow',UIParent)
  f:SetSize(240,66)
  f:SetPoint('BOTTOM',UIParent,'BOTTOM',0,275)
  f:SetClampedToScreen(true)
  f:SetFrameStrata('MEDIUM')
  local bg=f:CreateTexture(nil,'BACKGROUND')
  bg:SetAllPoints()
  self.arrowBg=bg
  self.arrowRound=WG.ModernRounded and WG:ModernRounded(f) or nil
  self.arrowOutline=WG.ModernRounded and WG:ModernRounded(f,'SoftOutline') or nil
  self.arrowTactical=WG.TacticalPlate and WG:TacticalPlate(f) or nil
  self.arrowTacticalEdge=WG.TacticalPlate and WG:TacticalPlate(f,'PlateBorder') or nil
  local icon=f:CreateTexture(nil,'ARTWORK')
  icon:SetTexture('Interface\\AddOns\\WafflesGang\\Media\\Icons\\WaffleCompassArrow')
  icon:SetPoint('LEFT',f,'LEFT',18,0)
  icon:SetSize(29,29)
  self.arrowIcon=icon
  local ring=f:CreateTexture(nil,'ARTWORK')
  ring:SetTexture('Interface\\AddOns\\WafflesGang\\Media\\Icons\\WaffleCompassRing')
  ring:SetSize(48,48)
  ring:SetPoint('CENTER',icon,'CENTER',0,0)
  self.arrowRing=ring
  local title=f:CreateFontString(nil,'OVERLAY','GameFontNormal')
  title:SetPoint('TOPLEFT',f,'TOPLEFT',69,-14)
  title:SetPoint('TOPRIGHT',f,'TOPRIGHT',-8,-13)
  title:SetJustifyH('LEFT')
  title:SetWordWrap(false)
  self.arrowTitle=title
  local note=f:CreateFontString(nil,'OVERLAY','GameFontHighlightSmall')
  note:SetPoint('TOPLEFT',title,'BOTTOMLEFT',0,-6)
  note:SetPoint('TOPRIGHT',title,'BOTTOMRIGHT',0,-8)
  note:SetJustifyH('LEFT')
  note:SetWordWrap(false)
  self.arrowNote=note
  WG:RegisterHUDFrame('questarrow',f,'Quest Arrow')
  f:SetScript('OnUpdate',function(_,elapsed)
    Q._arrowElapsed=(Q._arrowElapsed or 0)+elapsed
    if Q._arrowElapsed>=.15 then Q._arrowElapsed=0;Q:UpdateArrow() end
  end)
  self.arrowHUD=f
  f:Hide()
end
function Q:UpdateArrow()
  local f=self.arrowHUD
  if not f or not WG.db then return end
  local o=self:TrackerOptions()
  -- When Questie owns the visible tracker, follow Questie/TomTom's active
  -- waypoint automatically; there is no Waffle row to click anymore.
  local questieMode=self.UsingQuestieTracker and self:UsingQuestieTracker()
  if questieMode then
    local synced=self.SyncQuestieWaypoint and self:SyncQuestieWaypoint(nil)
    if synced then
      self.questieRouteActive=true
    else
      self.navWaypoint=nil
      self.questieRouteActive=false
    end
  end
  local qid=questieMode and nil or o.navigationQuestID
  local selectedRoute=questieMode and self.questieRouteActive and self.navWaypoint
  if not o.showArrow or (not qid and not selectedRoute) then f:Hide();return end
  local title=selectedRoute and (selectedRoute.label or 'Questie waypoint') or 'Selected quest'
  if not selectedRoute then
    for _,q in ipairs(self.entries or {}) do
      if q.id==qid then title=q.title;break end
    end
  end
  local modern=WG:StyleName()=='Modern'
  local tactical=WG:StyleName()=='Tactical'
  local adventure=WG:StyleName()=='Adventure'
  local compact=modern and o.navigationStyle~='classic'
  local t=tactical and WG:TacticalSettings() or nil
  if tactical and t.navStyle=='off' then f:Hide();return end
  local c=WG:Color('accent')
  local panel=WG:Color('panel')
  local dark=WG:Color('bg')
  f:SetSize(tactical and 202 or (adventure and 218 or (compact and 210 or 232)),tactical and 40 or (adventure and 49 or (compact and 51 or 63)))
  self.arrowBg:SetColorTexture(panel[1],panel[2],panel[3],(compact or tactical) and 0 or (adventure and .18 or .82))
  if self.arrowTactical then
    self.arrowTactical:SetShown(false)
    self.arrowTacticalEdge:SetShown(false)
    if tactical then
      self.arrowTactical:SetColor(dark[1],dark[2],dark[3],.97)
      self.arrowTacticalEdge:SetColor(c[1],c[2],c[3],.58)
    end
  end
  if self.arrowRound then
    self.arrowRound:SetShown(compact)
    if compact then self.arrowRound:SetColor(dark[1],dark[2],dark[3],.78) end
  end
  if self.arrowOutline then
    self.arrowOutline:SetShown(compact)
    if compact then self.arrowOutline:SetColor(c[1],c[2],c[3],.39) end
  end
  self.arrowRing:SetShown((compact or adventure) and not tactical)
  if tactical then
    self.arrowIcon:SetTexture('Interface\\AddOns\\WafflesGang\\Media\\Icons\\GuideNavArrow')
    self.arrowIcon:SetSize(33,33)
    self.arrowIcon:ClearAllPoints()
    self.arrowIcon:SetPoint('LEFT',f,'LEFT',3,0)
    self.arrowIcon:SetShown(t.navStyle~='text')
    self.arrowTitle:ClearAllPoints()
    self.arrowTitle:SetPoint('TOPLEFT',f,'TOPLEFT',t.navStyle=='text' and 4 or 38,-4)
    self.arrowTitle:SetPoint('TOPRIGHT',f,'TOPRIGHT',-3,-4)
    self.arrowNote:ClearAllPoints()
    self.arrowNote:SetPoint('TOPLEFT',self.arrowTitle,'BOTTOMLEFT',0,-2)
    self.arrowNote:SetPoint('TOPRIGHT',self.arrowTitle,'BOTTOMRIGHT',0,-2)
  elseif adventure then
    self.arrowIcon:Show()
    self.arrowIcon:SetTexture('Interface\\AddOns\\WafflesGang\\Media\\Icons\\GuideNavArrow')
    self.arrowIcon:SetSize(41,41)
    self.arrowIcon:ClearAllPoints();self.arrowIcon:SetPoint('LEFT',f,'LEFT',8,0)
    self.arrowTitle:ClearAllPoints();self.arrowTitle:SetPoint('TOPLEFT',f,'TOPLEFT',58,-9)
    self.arrowTitle:SetPoint('TOPRIGHT',f,'TOPRIGHT',-5,-9)
    self.arrowNote:ClearAllPoints();self.arrowNote:SetPoint('TOPLEFT',self.arrowTitle,'BOTTOMLEFT',0,-4)
    self.arrowNote:SetPoint('TOPRIGHT',self.arrowTitle,'BOTTOMRIGHT',0,-4)
    self.arrowRing:SetVertexColor(c[1],c[2],c[3],.55)
  elseif compact then
    self.arrowIcon:Show()
    self.arrowIcon:SetTexture('Interface\\AddOns\\WafflesGang\\Media\\Icons\\GuideNavArrow')
    self.arrowIcon:SetSize(29,29)
    self.arrowIcon:ClearAllPoints()
    self.arrowIcon:SetPoint('LEFT',f,'LEFT',18,0)
    self.arrowRing:SetVertexColor(c[1],c[2],c[3],.82)
    self.arrowTitle:ClearAllPoints()
    self.arrowTitle:SetPoint('TOPLEFT',f,'TOPLEFT',69,-14)
    self.arrowTitle:SetPoint('TOPRIGHT',f,'TOPRIGHT',-10,-14)
    self.arrowNote:ClearAllPoints()
    self.arrowNote:SetPoint('TOPLEFT',self.arrowTitle,'BOTTOMLEFT',0,-6)
    self.arrowNote:SetPoint('TOPRIGHT',self.arrowTitle,'BOTTOMRIGHT',0,-6)
  else
    self.arrowIcon:Show()
    self.arrowIcon:SetTexture('Interface\\AddOns\\WafflesGang\\Media\\Icons\\GuideNavArrow')
    self.arrowIcon:SetSize(58,58)
    self.arrowIcon:ClearAllPoints()
    self.arrowIcon:SetPoint('LEFT',f,'LEFT',8,0)
    self.arrowTitle:ClearAllPoints()
    self.arrowTitle:SetPoint('TOPLEFT',f,'TOPLEFT',72,-13)
    self.arrowTitle:SetPoint('TOPRIGHT',f,'TOPRIGHT',-8,-13)
    self.arrowNote:ClearAllPoints()
    self.arrowNote:SetPoint('TOPLEFT',self.arrowTitle,'BOTTOMLEFT',0,-8)
    self.arrowNote:SetPoint('TOPRIGHT',self.arrowTitle,'BOTTOMRIGHT',0,-8)
  end
  self.arrowIcon:SetVertexColor(1,1,1,1)
  local fs=compact and 13 or (tactical and 13 or 12)
  local ft=WG:StyleFont(fs)
  self.arrowTitle:SetFont(ft,fs,compact and '' or 'OUTLINE')
  self.arrowTitle:SetTextColor(1,.97,.92)
  self.arrowTitle:SetText(tactical and (title:sub(1,20)) or title)
  self.arrowNote:SetFont(WG:StyleFont(compact and 12 or 11),compact and 12 or 11,compact and '' or 'OUTLINE')
  self.arrowNote:SetTextColor(c[1],c[2],c[3])
  -- Questie can change its own waypoint after we select a quest (e.g. when
  -- objective progress updates). Follow its active TomTom UID, not stale map
  -- coordinates. Never adopt an unrelated waypoint created by Waffles.
  if not questieMode and self.questieRouteActive and not self.waffleWaypoint and self.SyncQuestieWaypoint then
    if not self:SyncQuestieWaypoint(qid) then
      self.navWaypoint=nil
      self.navigationState='Questie waypoint expired; select quest again'
    end
  end
  local wp=self.navWaypoint
  if not wp or wp.questID~=qid or not valid(wp.mapID) then
    self.arrowIcon:SetAlpha(.35)
    self.arrowIcon:SetRotation(0)
    self.arrowNote:SetText('No waypoint')
    if tactical and not t.showNoRoute then f:Hide() else f:Show() end
    return
  end
  -- TomTom's public distance/direction methods resolve world coordinates,
  -- including across connected maps. Reuse them for Questie's exact UID.
  local tomtom=_G.TomTom
  if wp.uid and tomtom then
    local dist,angle
    if type(tomtom.GetDistanceToWaypoint)=='function' then
      local ok,v=pcall(tomtom.GetDistanceToWaypoint,tomtom,wp.uid)
      if ok and valid(v) and v>=0 then dist=v end
    end
    if type(tomtom.GetDirectionToWaypoint)=='function' then
      local ok,v=pcall(tomtom.GetDirectionToWaypoint,tomtom,wp.uid)
      if ok and valid(v) then angle=v end
    end
    if dist or angle then
      local face
      if GetPlayerFacing then
        local ok,v=pcall(GetPlayerFacing)
        if ok and valid(v) then face=v end
      end
      if angle and face then
        self.arrowIcon:SetRotation(angle-face)
        self.arrowIcon:SetAlpha(1)
      else
        self.arrowIcon:SetRotation(0)
        self.arrowIcon:SetAlpha(.50)
      end
      self.arrowNote:SetText(dist and (math.floor(dist+.5)..' yards'..(not angle and ' / direction unavailable' or ''))
        or (face and 'Follow the waypoint' or 'Direction unavailable'))
      f:Show()
      return
    end
  end
  -- Keep a map-coordinate fallback for an unlinked Waffles waypoint.
  local x,y=playerPosition(wp.mapID)
  if not x then
    self.arrowIcon:SetAlpha(.48)
    self.arrowIcon:SetRotation(0)
    self.arrowNote:SetText('Waypoint in another zone or map')
    f:Show();return
  end
  local dx,dy=wp.x-x,wp.y-y
  local facing
  if GetPlayerFacing then
    local ok,v=pcall(GetPlayerFacing)
    if ok and valid(v) then facing=v end
  end
  if facing then
    -- Map X increases east and Y increases south. Character facing grows CCW
    -- from north; convert to the same reference before rotating the chevron.
    local offset=bearing(-dx,-dy)-facing
    self.arrowIcon:SetRotation(offset)
    self.arrowIcon:SetAlpha(1)
  else
    self.arrowIcon:SetRotation(0)
    self.arrowIcon:SetAlpha(.5)
  end
  local yards=distanceYards(wp.mapID,wp.x,wp.y,x,y)
  if yards then
    self.arrowNote:SetText(yards..' yards'..(not facing and ' / direction unavailable' or ''))
  else
    self.arrowNote:SetText(facing and 'Follow the arrow' or 'Direction unavailable here')
  end
  f:Show()
end
WG.surfaces[#WG.surfaces+1]={repaint=function()
  if Q.arrowHUD then Q:UpdateArrow() end
end}
