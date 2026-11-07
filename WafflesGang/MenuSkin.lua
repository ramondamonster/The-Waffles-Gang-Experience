-- ForeverUI native Game Menu cosmetic layer.
-- Reads labels from Blizzard buttons. Never hooks clicks, reparents buttons,
-- modifies their texture objects, or replaces secure actions.
local WG=_G.WafflesGang
local M={name='Game Menu Colorways',elapsed=0,buttons={},menu=nil}
WG.modules[#WG.modules+1]=M
local function white(parent,layer)
  local t=parent:CreateTexture(nil,layer or 'ARTWORK')
  t:SetTexture('Interface\\Buttons\\WHITE8X8')
  return t
end
local function validButton(child)
  if not child or not child.GetObjectType or child:GetObjectType()~='Button' then return false end
  if not child.GetText or not child.GetWidth or not child.GetHeight then return false end
  local ok,label=pcall(child.GetText,child)
  if not ok or type(label)~='string' or label=='' then return false end
  local w,h=child:GetWidth(),child:GetHeight()
  return type(w)=='number' and type(h)=='number' and w>48 and h>14
end
function M:MakeOverlay(button)
  local f=CreateFrame('Frame',nil,self.menu)
  f:SetAllPoints(button)
  f:SetFrameLevel(button:GetFrameLevel()+5)
  f:EnableMouse(false)
  if f.EnableMouseWheel then f:EnableMouseWheel(false) end
  local bg=white(f,'ARTWORK');bg:SetAllPoints(f)
  local top=white(f,'OVERLAY')
  top:SetPoint('TOPLEFT',f,'TOPLEFT',2,-1)
  top:SetPoint('TOPRIGHT',f,'TOPRIGHT',-2,-1)
  top:SetHeight(1)
  local side=white(f,'OVERLAY')
  side:SetPoint('TOPLEFT',f,'TOPLEFT',1,-2)
  side:SetPoint('BOTTOMLEFT',f,'BOTTOMLEFT',1,2)
  side:SetWidth(2)
  local text=f:CreateFontString(nil,'OVERLAY','GameFontNormal')
  text:SetPoint('CENTER',f,'CENTER',0,0)
  text:SetWidth(math.max(20,button:GetWidth()-12))
  text:SetJustifyH('CENTER')
  self.buttons[button]={frame=f,bg=bg,top=top,side=side,label=text}
end
function M:Ensure()
  if not _G.GameMenuFrame then return false end
  if WG:Protected() and not self.menu then return false end
  if self.menu~=_G.GameMenuFrame then
    self.menu=_G.GameMenuFrame
    self.buttons={}
    local header=CreateFrame('Frame',nil,self.menu)
    header:SetPoint('TOPLEFT',self.menu,'TOPLEFT',0,6)
    header:SetPoint('TOPRIGHT',self.menu,'TOPRIGHT',0,6)
    header:SetHeight(18)
    header:SetFrameLevel(self.menu:GetFrameLevel()+2)
    header:EnableMouse(false)
    local label=header:CreateFontString(nil,'OVERLAY','GameFontNormalSmall')
    label:SetPoint('CENTER',header,'CENTER',0,0)
    self.header=label
  end
  local children={self.menu:GetChildren()}
  for _,button in ipairs(children) do
    if not WG:Protected() and validButton(button) and not self.buttons[button] then
      self:MakeOverlay(button)
    end
  end
  return true
end
function M:Refresh()
  if not WG.db or not self:Ensure() then return end
  local active=WG:Enabled('menutheme')
  local style=WG:StyleName()
  local accent=WG:Color('accent')
  local bg=WG:Color('bg')
  local edge=WG:Color('edge')
  local words=WG:Color('text')
  for button,item in pairs(self.buttons) do
    local visible=active and button:IsShown()
    item.frame:SetShown(visible)
    if visible then
      item.bg:SetColorTexture(bg[1],bg[2],bg[3],style=='Adventure' and .97 or .98)
      item.top:SetColorTexture(edge[1],edge[2],edge[3],.85)
      item.side:SetColorTexture(accent[1],accent[2],accent[3],style=='Tactical' and 1 or .76)
      local ok,label=pcall(button.GetText,button)
      if ok and type(label)=='string' then item.label:SetText(label) end
      pcall(item.label.SetFont,item.label,WG:StyleFont(12),12,(style=='Modern' or style=='Tactical') and '' or 'OUTLINE')
      item.label:SetTextColor(words[1],words[2],words[3])
    end
  end
  if self.header then
    self.header:SetShown(active)
    self.header:SetText('FOREVERUI   /   '..string.upper(style)..'   /   '..string.upper(WG:ThemeName()))
    self.header:SetTextColor(accent[1],accent[2],accent[3])
    pcall(self.header.SetFont,self.header,WG:StyleFont(10),10,'')
  end
end
function M:Init()
  local watcher=CreateFrame('Frame',nil,UIParent)
  watcher:SetScript('OnUpdate',function(_,dt)
    M.elapsed=M.elapsed+(dt or 0)
    if M.elapsed<.4 then return end
    M.elapsed=0
    if _G.GameMenuFrame and _G.GameMenuFrame:IsShown() then M:Refresh() end
  end)
  self.watcher=watcher
  self:Refresh()
end
