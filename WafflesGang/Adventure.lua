-- Waffles Gang Adventure Center
-- Optional information-only module. Does not alter action bars, quests, the
-- theme system, unit frames, bag contents, or protected combat actions.
local WG=_G.WafflesGang
local Adventure={name='Adventure Center'}
table.insert(WG.modules,Adventure)
WG.adventure=Adventure

local function numberFrom(fn,...)
  if type(fn)~='function' then return nil end
  local ok,value=pcall(fn,...)
  if not ok or type(value)~='number' then return nil end
  local valid=pcall(function()
    if value~=value or value<0 or value>100000000000000 then error('invalid numeric value') end
  end)
  return valid and value or nil
end
local function since(start)
  local now=numberFrom(GetTime) or start
  return math.max(0,now-start)
end
local function duration(seconds)
  seconds=math.max(0,math.floor(seconds or 0))
  return string.format('%02d:%02d:%02d',math.floor(seconds/3600),math.floor(seconds/60)%60,seconds%60)
end
local function compact(n)
  if type(n)~='number' then return 'Unavailable' end
  if n>=1000000 then return string.format('%.2fm',n/1000000) end
  if n>=10000 then return string.format('%.1fk',n/1000) end
  return tostring(math.floor(n+0.5))
end
local function gold(copper)
  if type(copper)~='number' then return 'Unavailable' end
  local sign=copper<0 and '-' or (copper>0 and '+' or '')
  copper=math.abs(math.floor(copper))
  return string.format('%s%dg %ds %dc',sign,math.floor(copper/10000),math.floor(copper/100)%100,copper%100)
end
local function currentXP()
  return numberFrom(GetXP),numberFrom(GetXPMax),numberFrom(UnitLevel,'player')
end
local function freeBagSlots()
  local fn=C_Container and C_Container.GetContainerNumFreeSlots or GetContainerNumFreeSlots
  if type(fn)~='function' then return nil end
  local free=0
  local found=false
  for bag=0,4 do
    local n=numberFrom(fn,bag)
    if n then free=free+n;found=true end
  end
  return found and free or nil
end
local function minimumDurability()
  local fn=GetInventoryItemDurability
  if type(fn)~='function' then return nil end
  local least=nil
  for slot=1,19 do
    local ok,current,maximum=pcall(fn,slot)
    if ok and type(current)=='number' and type(maximum)=='number' then
      -- WoW Forever can return protected values for some combat data. Treat
      -- those as unavailable instead of interpreting them in an addon.
      local good,pct=pcall(function()
        if maximum<=0 or current<0 then return nil end
        return math.floor(100*current/maximum+0.5)
      end)
      if good and type(pct)=='number' then
        if not least or pct<least then least=pct end
      end
    end
  end
  return least
end
local function currentParty()
  local raid=(IsInRaid and IsInRaid()) or false
  local inGroup=(IsInGroup and IsInGroup()) or false
  if not inGroup then return 'SOLO' end
  local size=numberFrom(GetNumGroupMembers) or 0
  return (raid and 'RAID' or 'PARTY')..' / '..tostring(size)..' members'
end
function Adventure:ResetSession(silent)
  local xp,xpmax,level=currentXP()
  self.startTime=numberFrom(GetTime) or 0
  self.startMoney=numberFrom(GetMoney)
  self.currentMoney=self.startMoney
  self.lastXP=xp
  self.lastXPMax=xpmax
  self.lastLevel=level
  self.xpGained=0
  self.quests=0
  self.deaths=0
  if not silent then WG:Say('Adventure session restarted. Your HUD and profiles were not changed.') end
  self:UpdateText()
end
function Adventure:OnXP()
  local xp,maxxp,level=currentXP()
  if xp==nil or level==nil then return end
  if self.lastXP~=nil and self.lastLevel~=nil then
    local delta=0
    if level==self.lastLevel and xp>=self.lastXP then
      delta=xp-self.lastXP
    elseif level>self.lastLevel and self.lastXPMax and self.lastXPMax>=self.lastXP then
      -- Includes remaining XP before a level-up and XP already earned in
      -- the new level. Sessions spanning multiple level-ups are estimates.
      delta=(self.lastXPMax-self.lastXP)+xp
    end
    if delta>0 and delta<100000000 then self.xpGained=self.xpGained+delta end
  end
  self.lastXP=xp;self.lastXPMax=maxxp;self.lastLevel=level
  self:UpdateText()
end
function Adventure:OnMoney()
  local amount=numberFrom(GetMoney)
  if amount~=nil then
    if self.startMoney==nil then self.startMoney=amount end
    self.currentMoney=amount
  end
  self:UpdateText()
end
function Adventure:UpdateText()
  if not self.textFields or not self.startTime then return end
  local elapsed=since(self.startTime)
  local xpNow,xpMax=currentXP()
  local rate=elapsed>=30 and (self.xpGained or 0)*3600/elapsed or nil
  self.textFields.elapsed:SetText('TIME PLAYED THIS SESSION  /  '..duration(elapsed))
  self.textFields.xp:SetText('XP EARNED  /  '..compact(self.xpGained or 0))
  self.textFields.rate:SetText('LEVELING SPEED  /  '..(rate and compact(rate)..' XP/hr' or 'Calculating...'))
  local eta='Not enough session data yet'
  if rate and rate>0 and xpNow and xpMax and xpMax>xpNow then
    eta=duration((xpMax-xpNow)/rate*3600)
  end
  self.textFields.eta:SetText('ESTIMATED TIME TO LEVEL  /  '..eta)
  local net=nil
  if self.startMoney and self.currentMoney then net=self.currentMoney-self.startMoney end
  self.textFields.money:SetText('NET GOLD CHANGE  /  '..gold(net))
  self.textFields.quests:SetText('QUESTS TURNED IN  /  '..tostring(self.quests or 0))
  self.textFields.deaths:SetText('DEATHS THIS SESSION  /  '..tostring(self.deaths or 0))
  local free=freeBagSlots()
  self.textFields.bags:SetText('FREE BAG SLOTS  /  '..(free and tostring(free) or 'Unavailable'))
  local durability=minimumDurability()
  local durabilityText=durability and (tostring(durability)..'% minimum remaining') or 'Not reported by client'
  self.textFields.durability:SetText('EQUIPMENT DURABILITY  /  '..durabilityText)
  self.textFields.party:SetText('GROUP STATUS  /  '..currentParty())
end
function Adventure:Init()
  local panel=WG:Window('adventure','Adventure Center',620,575)
  self.panel=panel
  WG:Text(panel,'YOUR ADVENTURE, AT A GLANCE',24,-85,15,'accent')
  WG:Text(panel,'Stats reset at login or when you choose New Session.',24,-114,11,'text',555)
  WG:Divider(panel,-136,565,24)
  local rows={
    {'elapsed',-153},{'xp',-182},{'rate',-211},{'eta',-240},
    {'money',-274},{'quests',-303},{'deaths',-332},
  }
  self.textFields={}
  for _,v in ipairs(rows) do
    self.textFields[v[1]]=WG:Text(panel,'',30,v[2],12,'text',550)
  end
  WG:Divider(panel,-357,565,24)
  WG:Text(panel,'EXPEDITION READINESS',24,-381,14,'accent')
  self.textFields.bags=WG:Text(panel,'',30,-412,12,'text',550)
  self.textFields.durability=WG:Text(panel,'',30,-440,12,'text',550)
  self.textFields.party=WG:Text(panel,'',30,-468,12,'text',550)
  WG:Button(panel,'NEW SESSION',24,-503,173,39,function()self:ResetSession(false)end)
  WG:Button(panel,'OPEN PANTRY',207,-503,173,39,function()WG:Open('bags')end)
  WG:Button(panel,'GEAR ADVISOR',390,-503,205,39,function()WG:Open('gear')end)
  WG:Text(panel,'Informational only. XP/hour and level ETA are estimates, not a guide route.',25,-553,10,'text',560)
  panel.onOpen=function()self:OnXP();self:OnMoney();self:UpdateText()end
  panel:SetScript('OnUpdate',function(_,elapsed)
    self.tick=(self.tick or 0)+elapsed
    if self.tick>=5 then self.tick=0;self:UpdateText() end
  end)
  self:ResetSession(true)
  WG:On('PLAYER_XP_UPDATE',function()self:OnXP()end)
  WG:On('PLAYER_LEVEL_UP',function()self:OnXP()end)
  WG:On('PLAYER_MONEY',function()self:OnMoney()end)
  WG:On('QUEST_TURNED_IN',function()
    self.quests=(self.quests or 0)+1
    self:OnXP()
  end)
  WG:On('PLAYER_DEAD',function()
    self.deaths=(self.deaths or 0)+1
    self:UpdateText()
  end)
  WG:On('BAG_UPDATE_DELAYED',function()self:UpdateText()end)
  WG:On('UPDATE_INVENTORY_DURABILITY',function()self:UpdateText()end)
  WG:On('GROUP_ROSTER_UPDATE',function()self:UpdateText()end)
end
function Adventure:Refresh()
  self:UpdateText()
end
