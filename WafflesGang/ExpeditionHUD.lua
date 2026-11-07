-- ForeverUI / Trail Ledger. Adventure-only, read-only expedition HUD.
-- Distinct from the Adventure Center stats window. Never manipulates secure actions.
local WG=_G.WafflesGang
local E={name='Adventure Trail Ledger',elapsed=0}
WG.modules[#WG.modules+1]=E
WG.expedition=E
local function safe(fn,...)
  if type(fn)~='function' then return nil end
  local ok,v=pcall(fn,...)
  if ok and (not issecretvalue or not issecretvalue(v)) then return v end
end
local function pct()
  local a=safe(UnitXP,'player') or safe(GetXP)
  local b=safe(UnitXPMax,'player') or safe(GetXPMax)
  if type(a)=='number' and type(b)=='number' and b>0 then
    return string.format('%.1f%%',a/b*100)
  end
  return 'N/A'
end
local function position()
  if not C_Map then return 'POSITION UNKNOWN' end
  local id=safe(C_Map.GetBestMapForUnit,'player')
  if not id or not C_Map.GetPlayerMapPosition then return 'POSITION UNKNOWN' end
  local pos=safe(C_Map.GetPlayerMapPosition,id,'player')
  if not pos then return 'POSITION UNKNOWN' end
  local ok,x,y=pcall(function()return pos:GetXY()end)
  if not ok or type(x)~='number' or type(y)~='number' then return 'POSITION UNKNOWN' end
  if issecretvalue and (issecretvalue(x) or issecretvalue(y)) then return 'POSITION UNKNOWN' end
  return string.format('%.1f / %.1f',x*100,y*100)
end
local function bags()
  local fn=C_Container and C_Container.GetContainerNumFreeSlots or GetContainerNumFreeSlots
  local free=0;local found=false
  for i=0,4 do
    local n=safe(fn,i)
    if type(n)=='number' then free=free+n;found=true end
  end
  return found and (free..' FREE') or 'N/A'
end
function E:Init()
  local f=CreateFrame('Button','WGExpeditionTrailLedger',UIParent)
  f:SetSize(286,106)
  f:SetPoint('TOPLEFT',UIParent,'TOPLEFT',42,-115)
  f:SetClampedToScreen(true)
  f:SetFrameStrata('MEDIUM')
  f:RegisterForClicks('LeftButtonUp')
  WG:RegisterHUDFrame('expeditionledger',f,'Adventure Trail Ledger')
  local back=f:CreateTexture(nil,'BACKGROUND');back:SetAllPoints()
  local rule=f:CreateTexture(nil,'BORDER')
  rule:SetPoint('TOPLEFT',f,'TOPLEFT',1,-1);rule:SetPoint('TOPRIGHT',f,'TOPRIGHT',-1,-1);rule:SetHeight(2)
  local rose=f:CreateTexture(nil,'ARTWORK')
  rose:SetTexture('Interface\\AddOns\\WafflesGang\\Media\\Adventure\\CompassRose')
  rose:SetSize(28,28);rose:SetPoint('TOPLEFT',f,'TOPLEFT',12,-13)
  local kicker=f:CreateFontString(nil,'OVERLAY','GameFontNormalSmall')
  kicker:SetPoint('TOPLEFT',f,'TOPLEFT',49,-12);kicker:SetText('ADVENTURE  /  FIELD JOURNAL')
  local title=f:CreateFontString(nil,'OVERLAY','GameFontNormal')
  title:SetPoint('TOPLEFT',f,'TOPLEFT',49,-30);title:SetWidth(230);title:SetJustifyH('LEFT')
  local xp=f:CreateFontString(nil,'OVERLAY','GameFontHighlightSmall')
  xp:SetPoint('TOPLEFT',f,'TOPLEFT',12,-58);xp:SetWidth(270)
  local progress=f:CreateFontString(nil,'OVERLAY','GameFontHighlightSmall')
  progress:SetPoint('TOPLEFT',f,'TOPLEFT',12,-76);progress:SetWidth(270)
  local foot=f:CreateFontString(nil,'OVERLAY','GameFontHighlightSmall')
  foot:SetPoint('BOTTOMLEFT',f,'BOTTOMLEFT',12,7);foot:SetWidth(265)
  self.hud=f;self.back=back;self.rule=rule;self.kicker=kicker;self.title=title
  self.xp=xp;self.progress=progress;self.foot=foot;self.rose=rose
  f:SetScript('OnClick',function()if WG.Open then WG:Open('adventure')end end)
  f:SetScript('OnEnter',function()
    if GameTooltip then GameTooltip:SetOwner(f,'ANCHOR_RIGHT');GameTooltip:SetText('Trail Ledger',1,.88,.5)
      GameTooltip:AddLine('Left-click: full Adventure Center. Drag the small + tab out of combat; right-click to lock.',1,1,1);GameTooltip:Show()end
  end)
  f:SetScript('OnLeave',function()if GameTooltip then GameTooltip:Hide()end end)
  f:SetScript('OnUpdate',function(_,delta)
    E.elapsed=(E.elapsed or 0)+delta
    if E.elapsed>=2 then E.elapsed=0;E:Refresh()end
  end)
  self:Refresh()
end
function E:Refresh()
  local f=self.hud;if not f then return end
  local o=WG:ExpeditionSettings()
  if WG:StyleName()~='Adventure' or not o.showHUD then f:Hide();return end
  local c=WG:Color('accent');local bg=WG:Color('bg');local text=WG:Color('text')
  local compact=o.compactHUD
  f:SetSize(compact and 270 or 286,compact and 65 or 106)
  self.back:SetColorTexture(bg[1],bg[2],bg[3],o.hudOpacity)
  self.rule:SetColorTexture(c[1],c[2],c[3],.75)
  self.rose:SetVertexColor(c[1],c[2],c[3],1)
  self.kicker:SetFont(WG:StyleFont(10),10,'');self.kicker:SetTextColor(c[1],c[2],c[3])
  self.title:SetFont(WG:StyleFont(16),16,'');self.title:SetTextColor(text[1],text[2],text[3])
  local zone=safe(GetSubZoneText) or safe(GetZoneText) or 'Uncharted territory'
  self.title:SetText(zone)
  self.xp:SetFont(WG:StyleFont(11),11,'')
  self.progress:SetFont(WG:StyleFont(10),10,'')
  self.foot:SetFont(WG:StyleFont(10),10,'')
  self.xp:SetTextColor(text[1],text[2],text[3])
  self.progress:SetTextColor(c[1],c[2],c[3])
  self.foot:SetTextColor(.77,.82,.77)
  self.xp:SetShown(not compact and o.showXP)
  self.progress:SetShown(not compact and o.showSession)
  self.foot:SetShown(not compact and o.showReadiness)
  self.xp:SetText('LEVEL '..tostring(safe(UnitLevel,'player') or '?')..'   |   XP '..pct())
  local a=type(WG.adventure)=='table' and WG.adventure or nil
  self.progress:SetText('SESSION   '..tostring(a and a.quests or 0)..' QUESTS   /   '..tostring(a and a.deaths or 0)..' DEATHS')
  self.foot:SetText((o.showLocation and position()..'     ' or '')..'PACK  '..bags())
  f:Show()
end
