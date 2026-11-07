-- Original Waffles Gang level-up celebration: a native UI texture burst.
-- Disabled by default. Uses WaffleLogo.tga already included in the addon.
local WG=_G.WafflesGang
local C={name='Level-up Celebration',particles={},lifetime=2.65}
table.insert(WG.modules,C)
local logo='Interface\\AddOns\\WafflesGang\\Media\\WaffleLogo'
local tau=math.pi*2
local particleCount=30

function C:Init()
  local frame=CreateFrame('Frame','WafflesGangLevelUpBurst',UIParent)
  frame:SetAllPoints(UIParent)
  frame:SetFrameStrata('HIGH')
  frame:EnableMouse(false)
  frame:Hide()
  self.frame=frame
  self.title=frame:CreateFontString(nil,'OVERLAY','GameFontNormalLarge')
  self.title:SetFont(STANDARD_TEXT_FONT or 'Fonts\\FRIZQT__.TTF',27,'OUTLINE')
  self.title:SetPoint('CENTER',UIParent,'CENTER',0,105)
  self.title:SetTextColor(1,.87,.38)
  self.title:Hide()
  for i=1,particleCount do
    local icon=frame:CreateTexture(nil,'ARTWORK')
    icon:SetTexture(logo)
    icon:SetSize(44,44)
    icon:SetPoint('CENTER',UIParent,'CENTER',0,0)
    icon:Hide()
    self.particles[i]={icon=icon}
  end
  frame:SetScript('OnUpdate',function(_,elapsed)C:Update(elapsed)end)
  WG:On('PLAYER_LEVEL_UP',function(level)C:LevelUp(level)end)
end

function C:Start(level)
  if not self.frame then return end
  self.age=0
  self.tick=0
  self.lastLevel=level
  self.title:SetText(level and ('SWEET WAFFLES!  LEVEL '..tostring(level)) or 'SWEET WAFFLES!')
  self.title:Show()
  self.title:SetAlpha(1)
  self.frame:Show()
  for i,p in ipairs(self.particles) do
    local angle=(i-1)/particleCount*tau + math.random()*0.24
    local speed=135+math.random()*260
    p.x=math.random(-20,20)
    p.y=math.random(-16,16)
    p.vx=math.cos(angle)*speed
    p.vy=math.sin(angle)*speed+105
    p.spin=(math.random()*2-1)*5
    p.angle=math.random()*tau
    p.size=math.random(32,71)
    p.icon:SetSize(p.size,p.size)
    p.icon:SetAlpha(1)
    p.icon:ClearAllPoints()
    p.icon:SetPoint('CENTER',UIParent,'CENTER',p.x,p.y)
    p.icon:Show()
  end
end

function C:Update(elapsed)
  if not self.frame or not self.frame:IsShown() then return end
  -- Bound updates to 30 fps even if a client sends very frequent OnUpdate calls.
  self.tick=(self.tick or 0)+elapsed
  if self.tick<.03 then return end
  local dt=math.min(self.tick,.09)
  self.tick=0
  self.age=(self.age or 0)+dt
  local alpha=math.max(0,math.min(1,(self.lifetime-self.age)/.85))
  self.title:SetAlpha(alpha)
  if self.age>=self.lifetime then
    self.frame:Hide()
    self.title:Hide()
    for _,p in ipairs(self.particles) do p.icon:Hide() end
    return
  end
  for _,p in ipairs(self.particles) do
    p.x=p.x+p.vx*dt
    p.y=p.y+p.vy*dt
    p.vy=p.vy-185*dt
    p.icon:ClearAllPoints()
    p.icon:SetPoint('CENTER',UIParent,'CENTER',p.x,p.y)
    p.icon:SetAlpha(alpha)
    p.angle=p.angle+p.spin*dt
    if p.icon.SetRotation then p.icon:SetRotation(p.angle) end
  end
end

function C:LevelUp(level)
  if not WG:Enabled('levelcelebration') then return end
  -- The server can suppress dance while the player is moving or fighting.
  if C_ChatInfo and C_ChatInfo.PerformEmote then
    WG:Safe('Level-up dance',function()C_ChatInfo.PerformEmote('DANCE')end)
  elseif DoEmote then
    WG:Safe('Level-up dance',function()DoEmote('DANCE')end)
  end
  self:Start(level)
end
function WG:PreviewCelebration()
  C:Start(UnitLevel and UnitLevel('player') or nil)
end
function C:Refresh() end
