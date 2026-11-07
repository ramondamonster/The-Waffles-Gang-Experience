-- ForeverUI / Questie companion. Original glue code, no Questie source/assets.
-- Questie owns quest rows, clicks, data, positioning, collapsing and all navigation.
-- This module ONLY draws a non-interactive themed plate BEHIND Questie_BaseFrame.
-- No Questie profile options are overwritten and Questie's frame is never reparented.
local WG=_G.WafflesGang
local Q=WG.quests
if not Q then return end

local QS={name='Questie Tracker Styling',elapsed=0}
WG.questieSkin=QS
WG.modules[#WG.modules+1]=QS
local min,max=math.min,math.max
local function clamp(n,lo,hi) return max(lo,min(hi,tonumber(n) or lo)) end

function QS:Settings()
  if not WG.db then return {source='auto',enabled=true,mode='minimal',opacity=.28,padding=8,accentLine=true} end
  local o=Q:Options()
  -- AUTO uses Questie if installed and enabled; otherwise the existing Waffle preference.
  if o.trackerSource~='auto' and o.trackerSource~='questie' and o.trackerSource~='waffle' then
    o.trackerSource='auto'
  end
  if type(o.questieSkin)~='table' then o.questieSkin={} end
  local skin=o.questieSkin
  if skin.enabled==nil then skin.enabled=true end
  if skin.mode~='minimal' and skin.mode~='panel' and skin.mode~='clear' then skin.mode='minimal' end
  if skin.opacity==nil then skin.opacity=.28 end
  skin.opacity=clamp(skin.opacity,0,1)
  if skin.padding==nil then skin.padding=8 end
  skin.padding=clamp(skin.padding,0,22)
  if skin.accentLine==nil then skin.accentLine=true end
  return skin
end
function Q:UsingQuestieTracker()
  if not WG.db then return false end
  local o=Q:Options()
  local mode=o.trackerSource or 'auto'
  if mode=='waffle' then return false end
  if mode=='questie' then return true end
  local questie=_G.Questie
  -- If Questie is disabled by its owner, native fallback still works.
  return questie~=nil and questie.db~=nil and questie.db.profile~=nil
    and questie.db.profile.trackerEnabled~=false
end
function QS:QuestieIsAvailable()
  local questie=_G.Questie
  return questie and questie.db and questie.db.profile and questie.db.profile.trackerEnabled~=false
end
local function solid(parent,layer)
  local t=parent:CreateTexture(nil,layer or 'ARTWORK')
  t:SetTexture('Interface\\Buttons\\WHITE8X8')
  return t
end
function QS:Ensure()
  local target=_G.Questie_BaseFrame
  if not target or not target.GetWidth then return false end
  if target==self.target and self.plate then return true end
  if self.plate then self.plate:Hide() end
  self.target=target
  local p=CreateFrame('Frame',nil,UIParent)
  p:SetFrameStrata('LOW') -- Always below Questie's own MEDIUM-strata tracker.
  p:SetFrameLevel(1)
  p:EnableMouse(false)
  self.plate=p
  p.bg=solid(p,'BACKGROUND');p.bg:SetAllPoints()
  p.pattern=p:CreateTexture(nil,'BORDER');p.pattern:SetAllPoints()
  p.rail=solid(p);p.rail:SetPoint('TOPLEFT',p,'TOPLEFT',0,0);p.rail:SetPoint('BOTTOMLEFT',p,'BOTTOMLEFT',0,0)
  p.top=solid(p);p.top:SetPoint('TOPLEFT',p,'TOPLEFT',0,0);p.top:SetPoint('TOPRIGHT',p,'TOPRIGHT',0,0)
  p.bottom=solid(p);p.bottom:SetPoint('BOTTOMLEFT',p,'BOTTOMLEFT',0,0);p.bottom:SetPoint('BOTTOMRIGHT',p,'BOTTOMRIGHT',0,0)
  p.right=solid(p);p.right:SetPoint('TOPRIGHT',p,'TOPRIGHT',0,0);p.right:SetPoint('BOTTOMRIGHT',p,'BOTTOMRIGHT',0,0)
  if target.HookScript then
    target:HookScript('OnShow',function()QS:UpdatePlate()end)
    target:HookScript('OnHide',function()QS:UpdatePlate()end)
    target:HookScript('OnSizeChanged',function()QS:UpdatePlate()end)
  end
  return true
end
function QS:UpdatePlate()
  if not self.plate or not self.target or not WG.db then return end
  local skin=self:Settings()
  local show=(skin.enabled and skin.mode~='clear' and Q:UsingQuestieTracker()
    and self:QuestieIsAvailable() and self.target:IsShown())
  self.plate:SetShown(show and true or false)
  if not show then return end
  local style=WG:StyleName()
  local bg,accent,edge=WG:Color('panel'),WG:Color('accent'),WG:Color('edge')
  local p=self.plate
  local pad=skin.padding
  p:ClearAllPoints()
  p:SetPoint('TOPLEFT',self.target,'TOPLEFT',-pad,pad)
  p:SetPoint('BOTTOMRIGHT',self.target,'BOTTOMRIGHT',pad,-pad)
  -- Minimal style defaults to almost-transparent framing. Questie rows remain untouched.
  local alpha=skin.opacity*(skin.mode=='minimal' and .38 or 1)
  local styleMultiplier=style=='Tactical' and .54 or (style=='Modern' and .85 or (style=='Adventure' and 1.05 or 1.15))
  p.bg:SetColorTexture(bg[1],bg[2],bg[3],clamp(alpha*styleMultiplier,0,.88))
  local detail=(skin.mode=='panel')
  local borderAlpha=detail and .45 or .0
  p.top:SetColorTexture(edge[1],edge[2],edge[3],borderAlpha)
  p.bottom:SetColorTexture(edge[1],edge[2],edge[3],borderAlpha*.65)
  p.right:SetColorTexture(edge[1],edge[2],edge[3],style=='Classic' and borderAlpha or 0)
  p.top:SetHeight(style=='Tactical' and 1 or 2)
  p.bottom:SetHeight(1);p.right:SetWidth(1)
  local line=skin.accentLine and skin.mode~='clear'
  p.rail:SetWidth(style=='Classic' and 3 or (style=='Tactical' and 2 or 2))
  p.rail:SetColorTexture(accent[1],accent[2],accent[3],line and (style=='Tactical' and .60 or .48) or 0)
  p.pattern:SetTexture(WG:CurrentThemeTexture('panel'))
  p.pattern:SetVertexColor(accent[1],accent[2],accent[3])
  p.pattern:SetAlpha((detail and (style=='Classic' or style=='Adventure')) and .045 or 0)
end
function QS:Refresh()
  if not WG.db then return end
  self:Settings()
  if not self:Ensure() then
    if self.plate then self.plate:Hide() end
    if self.pump and _G.Questie then self.pump:Show() end
    return
  end
  self:UpdatePlate()
end
function QS:Init()
  self:Settings()
  local watcher=CreateFrame('Frame')
  self.pump=watcher
  watcher:Hide()
  watcher:SetScript('OnUpdate',function(_,elapsed)
    QS.elapsed=QS.elapsed+elapsed
    if QS.elapsed<.9 then return end
    QS.elapsed=0
    if QS:Ensure() then
      QS:UpdatePlate()
      watcher:Hide()
    elseif not _G.Questie then watcher:Hide() end
  end)
  WG:On('ADDON_LOADED',function(name)
    if name=='Questie' then QS.elapsed=0;watcher:Show() end
  end)
  WG:On('PLAYER_ENTERING_WORLD',function()
    QS:Refresh()
    if _G.Questie and not QS.target then watcher:Show() end
  end)
  self:Refresh()
end
