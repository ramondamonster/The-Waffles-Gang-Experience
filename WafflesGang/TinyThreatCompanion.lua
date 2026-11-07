-- ForeverUI / Details! Tiny Threat companion.
-- Tiny Threat retains ownership of its threat calculation, target, sorting, and data.
-- Waffles meters consume its live player_list_indexes without copying its formulas.
-- Keep all percentage displays synchronized with the registered Details plugin.
-- This is an optional compatibility bridge into Details! internals, not a public API.
local WG = _G.WafflesGang
local C = {name='Tiny Threat Companion',elapsed=0}
WG.threatCompanion=C
WG.modules[#WG.modules+1]=C
local function clamp(n,lo,hi) return math.max(lo,math.min(hi,tonumber(n) or lo)) end
local function solid(frame,layer)
  local tex=frame:CreateTexture(nil,layer)
  tex:SetTexture('Interface\\Buttons\\WHITE8X8')
  return tex
end
function C:Settings()
  if not WG.db then return {source='auto',skin=true,opacity=.26,accentLine=true} end
  if type(WG.db.threatCompanion)~='table' then WG.db.threatCompanion={} end
  local s=WG.db.threatCompanion
  if s.source~='auto' and s.source~='tiny' and s.source~='waffle' then s.source='auto' end
  if s.skin==nil then s.skin=true end
  if s.opacity==nil then s.opacity=.26 end
  s.opacity=clamp(s.opacity,0,1)
  if s.accentLine==nil then s.accentLine=true end
  return s
end
-- GetPlugin is provided by Details!, while player_list_indexes is internal to
-- Tiny Threat. Read-only access avoids maintaining a second threat algorithm.
-- Details! registers the plugin under DETAILS_PLUGIN_TINY_THREAT, NOT its
-- addon folder/frame name Details_TinyThreat. The old lookup silently missed
-- the plugin, making Auto fall back to the unrelated native threat percentages.
-- Keep the old alias as a compatibility fallback for alternative forks.
function C:Plugin()
  local details=_G.Details
  if details and type(details.GetPlugin)=='function' then
    for _,key in ipairs({'DETAILS_PLUGIN_TINY_THREAT','Details_TinyThreat'}) do
      local ok,plugin=pcall(details.GetPlugin,details,key)
      if ok and plugin and plugin.Frame then return plugin end
    end
  end
  -- The supplied Details! source also exports its plugin by registered name.
  -- This covers clients/forks where GetPlugin has not initialized its tables.
  local direct=_G.DETAILS_PLUGIN_TINY_THREAT
  if direct and direct.Frame then return direct end
  return nil
end
function C:AddonLoaded()
  local check=(C_AddOns and C_AddOns.IsAddOnLoaded) or IsAddOnLoaded
  if type(check)~='function' then return false end
  local ok,loaded=pcall(check,'Details_TinyThreat')
  return ok and loaded==true
end
function C:IsShowing()
  local plugin=self:Plugin()
  if not plugin or plugin.__enabled==false then return false end
  local ok,visible=pcall(function()return plugin.Frame:IsShown()end)
  return ok and visible==true
end
-- 'auto' prefers Details-backed Waffle bars if the plugin is enabled;
-- 'tiny' requires it (no independent API fallback); 'waffle' is legacy API.
-- Do NOT require the Details frame to be visible: the plugin can continue its
-- timer updates while its own window is visually hidden by other UI settings.
function C:UsingTinyThreat()
  local source=self:Settings().source
  if source=='waffle' then return false end
  if source=='tiny' then return true end
  local plugin=self:Plugin()
  -- Once the Details Tiny Threat addon has loaded, NEVER silently show native
  -- values under Auto. If the plugin couldn't register, explain the missing
  -- source instead of displaying a mismatched percent on Meter 1 or Meter 2.
  return (plugin~=nil and plugin.__enabled~=false) or self:AddonLoaded()
end
local function validNumber(v)
  if issecretvalue and issecretvalue(v) then return false end
  return type(v)=='number' and v==v and v~=math.huge and v~=-math.huge
end
local function validString(v)
  if issecretvalue and issecretvalue(v) then return false end
  return type(v)=='string' and v~=''
end
-- Tiny Threat data layout is defined by the supplied Details_TinyThreat.lua:
-- [1] full name, [2] relative %, [3] tank, [4] role, [5] class,
-- [6] threat amount (Classic-scaled), [7] raw/absolute % with tank correction.
-- Details! sorts the table itself. Never re-sort or recompute percentages.
function C:ReadThreatRows(index)
  local plugin=self:Plugin()
  if not plugin then return {},'DETAILS PLUGIN NOT REGISTERED' end
  if plugin.__enabled==false then return {},'DETAILS TINY THREAT DISABLED' end
  if plugin.Actived~=true then return {},'WAITING FOR DETAILS THREAT' end
  local unit='target'
  if type(plugin.GetUnitId)=='function' then
    local ok,result=pcall(plugin.GetUnitId,plugin)
    if ok and validString(result) then unit=result end
  end
  if not UnitExists or not UnitExists(unit) then return {},'NO DETAILS TARGET' end
  if UnitIsFriend then
    local ok,friendly=pcall(UnitIsFriend,'player',unit)
    if ok and friendly then return {},'SELECT A HOSTILE TARGET' end
  end
  local actors=plugin.player_list_indexes
  if type(actors)~='table' or #actors==0 then return {},'WAITING FOR DETAILS ROWS' end
  -- Same no-threat rule used by Tiny Threat itself (player_list_indexes[1][7] < 1).
  if type(actors[1])~='table' or not validNumber(actors[1][7]) or actors[1][7]<1 then
    return {},'WAITING FOR DETAILS THREAT'
  end
  local saved=plugin.saveddata or {}
  -- Tiny Threat may override absolute mode for specific gouge mechanics. Its
  -- rendered text, when accessible, is preferred for an exact percentage match.
  local useAbsolute=saved.absolute_mode==true
  local drawn={}
  if type(plugin.ShownRows)=='table' and plugin.Frame and plugin.Frame.IsShown and plugin.Frame:IsShown() then
    for _,bar in ipairs(plugin.ShownRows) do
      if bar and bar.IsShown and bar:IsShown() then
        local left=bar.lefttext or (bar.textleft and bar.textleft.GetText and bar.textleft:GetText())
        local right=bar.righttext or (bar.textright and bar.textright.GetText and bar.textright:GetText())
        if validString(left) and validString(right) then
          drawn[left]=right
        end
      end
    end
  end
  local out={}
  for _,actor in ipairs(actors) do
    if type(actor)=='table' then
      local name,amount=actor[1],actor[6]
      local pct=actor[useAbsolute and 7 or 2]
      if validString(name) and validNumber(pct) and validNumber(amount) and pct>0 then
        local short=name:match('^([^%-]+)') or name
        local amountText
        if type(plugin.ToK2)=='function' then
          local ok,txt=pcall(plugin.ToK2,plugin,amount)
          if ok and validString(txt) then amountText=txt end
        end
        amountText=amountText or string.format('%.0f',amount)
        local label=amountText..' ('..string.format('%.1f',pct)..'%)'
        -- When available, use text written by Tiny Threat to its real row.
        -- Details rows can include pull-threshold rows; only match actors here.
        local rowLabel=drawn[short] or drawn[name]
        if rowLabel then
          local visiblePct=tonumber(rowLabel:match('%(([%-%.%d]+)%%%)'))
          if validNumber(visiblePct) then pct=visiblePct;label=rowLabel end
        end
        out[#out+1]={name=short,percent=pct,amount=amount,
          label=label,role=actor[4],class=actor[5],tanking=actor[3]==true,
          fromDetails=true}
      end
    end
  end
  return out, 'DETAILS / '..(UnitName and (UnitName(unit) or 'TARGET') or 'TARGET')
end
function C:Status()
  local plugin=self:Plugin()
  local mode=self:Settings().source
  if mode=='waffle' then return 'SOURCE: NATIVE API / INDEPENDENT VALUES (NOT DETAILS)' end
  if plugin and plugin.__enabled==false then return 'ERROR: TINY THREAT PLUGIN DISABLED / NO NATIVE FALLBACK' end
  if plugin then
    if plugin.Actived then return 'SOURCE: DETAILS TINY THREAT / LIVE TO BOTH WAFFLE METERS' end
    return 'SOURCE: DETAILS TINY THREAT CONNECTED / WAITING FOR COMBAT'
  end
  if self:AddonLoaded() then return 'ERROR: TINY THREAT LOADED BUT NOT REGISTERED / NO NATIVE FALLBACK' end
  if mode=='tiny' then return 'ERROR: TINY THREAT REQUIRED / INSTALL AND ENABLE DETAILS' end
  return 'SOURCE: NATIVE API / DETAILS TINY THREAT NOT INSTALLED'
end
function C:Ensure()
  local plugin=self:Plugin()
  if not plugin or not plugin.Frame or not plugin.Frame.CreateTexture then return false end
  if self.owner==plugin.Frame and self.bg then return true end
  self.owner=plugin.Frame
  -- Create textures on the original plugin frame, below its existing status
  -- bars. We do not reparent, hide or modify Tiny Threat's internal rows.
  local bg=solid(self.owner,'BACKGROUND')
  bg:SetAllPoints(self.owner)
  self.bg=bg
  local edge=solid(self.owner,'OVERLAY')
  edge:SetPoint('TOPLEFT',self.owner,'TOPLEFT',0,0)
  edge:SetPoint('BOTTOMLEFT',self.owner,'BOTTOMLEFT',0,0)
  self.edge=edge
  local top=solid(self.owner,'OVERLAY')
  top:SetPoint('TOPLEFT',self.owner,'TOPLEFT',0,0)
  top:SetPoint('TOPRIGHT',self.owner,'TOPRIGHT',0,0)
  top:SetHeight(1)
  self.top=top
  local bottom=solid(self.owner,'OVERLAY')
  bottom:SetPoint('BOTTOMLEFT',self.owner,'BOTTOMLEFT',0,0)
  bottom:SetPoint('BOTTOMRIGHT',self.owner,'BOTTOMRIGHT',0,0)
  bottom:SetHeight(1)
  self.bottom=bottom
  if self.owner.HookScript then
    self.owner:HookScript('OnShow',function()C:Refresh()end)
    self.owner:HookScript('OnHide',function()C:Refresh()end)
    self.owner:HookScript('OnSizeChanged',function()C:Paint()end)
  end
  return true
end
function C:Paint()
  if not self.bg then return end
  local s=self:Settings()
  local style=WG:StyleName()
  local bg=WG:Color('panel')
  local edge=WG:Color('edge')
  local accent=WG:Color('accent')
  local enabled=s.skin and s.source~='waffle'
  local alpha=s.opacity
  -- Each style inherits its real ForeverUI theme and selected colorway.
  local multiplier=style=='Tactical' and .36 or (style=='Modern' and .68 or
    (style=='Adventure' and .82 or 1.0))
  self.bg:SetColorTexture(bg[1],bg[2],bg[3],enabled and alpha*multiplier or 0)
  local line=enabled and s.accentLine
  self.edge:SetWidth(style=='Classic' and 3 or (style=='Adventure' and 3 or 2))
  self.edge:SetColorTexture(accent[1],accent[2],accent[3],line and
    (style=='Tactical' and .68 or .76) or 0)
  local border=enabled and (style=='Classic' or style=='Adventure')
  self.top:SetColorTexture(edge[1],edge[2],edge[3],border and .38 or 0)
  self.bottom:SetColorTexture(edge[1],edge[2],edge[3],border and .30 or 0)
end
function C:Sync(force)
  local active=self:IsShowing()
  local source=self:Settings().source
  if force or self.lastActive~=active or self.lastSource~=source then
    self.lastActive=active;self.lastSource=source
    if WG.threatWatch and WG.threatWatch.Update then WG.threatWatch:Update() end
    if WG.studio and WG.studio.window and WG.studio.current=='THREATSOURCE' then
      WG.studio:Refresh()
    end
  end
end
function C:Refresh()
  if not WG.db then return end
  self:Ensure()
  self:Paint()
  self:Sync(false)
end
function C:Init()
  self:Settings()
  local pump=CreateFrame('Frame')
  pump:SetScript('OnUpdate',function(_,dt)
    if not WG.db then return end
    C.elapsed=C.elapsed+dt
    if C.elapsed<.5 then return end
    C.elapsed=0
    if C.owner==nil and C:Plugin() then C:Ensure();C:Paint() end
    C:Sync(false)
  end)
  WG:On('ADDON_LOADED',function(name)
    if name=='Details' or name=='Details_TinyThreat' then C:Refresh() end
  end)
  WG:On('PLAYER_ENTERING_WORLD',function()C:Refresh()end)
  self:Refresh()
end
