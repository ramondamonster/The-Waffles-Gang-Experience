-- Waffles Gang | Quest turn-in, junk selling, bag space assistance
-- Blizzard protects DeleteCursorItem behind a real hardware event. No silent deletion.
local WG=_G.WafflesGang
local A={name='Quest & Junk Automation',candidate=nil}
table.insert(WG.modules,A)
local function slots(bag)
  if C_Container and C_Container.GetContainerNumSlots then return C_Container.GetContainerNumSlots(bag) or 0 end
  if GetContainerNumSlots then return GetContainerNumSlots(bag) or 0 end
  return 0
end
local function playerBags() return {0,1,2,3,4} end
local function bagItem(bag,slot)
  if C_Container and C_Container.GetContainerItemInfo then return C_Container.GetContainerItemInfo(bag,slot) end
  if GetContainerItemInfo then
    local icon,count,locked,quality,_,_,link,_,noValue,id,bound=GetContainerItemInfo(bag,slot)
    if icon then return {iconFileID=icon,stackCount=count,isLocked=locked,quality=quality,
      hyperlink=link,hasNoValue=noValue,itemID=id,isBound=bound} end
  end
end
local function questItem(bag,slot)
  if C_Container and C_Container.GetContainerItemQuestInfo then
    local info=C_Container.GetContainerItemQuestInfo(bag,slot)
    return info and (info.isQuestItem or info.questID~=nil)
  end
  if GetContainerItemQuestInfo then
    local isQuest,questID=GetContainerItemQuestInfo(bag,slot)
    return isQuest or questID~=nil
  end
  return false
end
local function worth(item)
  local id=item.itemID
  if not id then return nil end
  local link=item.hyperlink or id
  if C_Item and C_Item.GetItemInfo then
    local _,_,_,_,_,_,_,_,equipLoc,_,sellPrice=C_Item.GetItemInfo(link)
    if equipLoc and equipLoc~='' then return nil end
    return sellPrice
  elseif GetItemInfo then
    local _,_,_,_,_,_,_,_,equipLoc,_,sellPrice=GetItemInfo(link)
    if equipLoc and equipLoc~='' then return nil end
    return sellPrice
  end
end
local function safeJunk(bag,slot)
  local item=bagItem(bag,slot)
  if not item or not item.itemID or item.quality~=0 then return nil end
  if item.isLocked or item.isBound or item.hasLoot or item.hasNoValue then return nil end
  if questItem(bag,slot) then return nil end
  if WG.db and WG.db.pins and WG.db.pins[item.itemID] then return nil end
  local price=worth(item)
  if type(price)~='number' or price<=0 then return nil end
  local quantity=item.stackCount or 1
  if type(quantity)~='number' or quantity<1 then return nil end
  return {bag=bag,slot=slot,id=item.itemID,quantity=quantity,price=price,loss=price*quantity,
    name=(C_Item and C_Item.GetItemInfo and C_Item.GetItemInfo(item.itemID))
      or (GetItemInfo and GetItemInfo(item.itemID)) or ('Item '..tostring(item.itemID))}
end
local function freeSlots()
  local free,total=0,0
  for _,bag in ipairs(playerBags()) do
    local n=slots(bag)
    total=total+n
    if n>0 then
      local empty=nil
      if C_Container and C_Container.GetContainerNumFreeSlots then empty=C_Container.GetContainerNumFreeSlots(bag)
      elseif GetContainerNumFreeSlots then empty=GetContainerNumFreeSlots(bag) end
      if type(empty)=='number' then free=free+empty
      else
        for slot=1,n do if not bagItem(bag,slot) then free=free+1 end end
      end
    end
  end
  return free,total
end
local function findCheapestJunk()
  local best
  for _,bag in ipairs(playerBags()) do
    for slot=1,slots(bag) do
      local e=safeJunk(bag,slot)
      if e and (not best or e.loss<best.loss) then best=e end
    end
  end
  return best
end
local function pickup(bag,slot)
  if C_Container and C_Container.PickupContainerItem then return C_Container.PickupContainerItem(bag,slot) end
  if PickupContainerItem then return PickupContainerItem(bag,slot) end
end
local function sell(bag,slot)
  if C_Container and C_Container.UseContainerItem then return C_Container.UseContainerItem(bag,slot) end
  if UseContainerItem then return UseContainerItem(bag,slot) end
end
function A:AutoSell()
  if not WG:Enabled('autoselljunk') or WG:Protected() then return end
  if not MerchantFrame or not MerchantFrame:IsShown() then return end
  if not ((C_Container and C_Container.UseContainerItem) or UseContainerItem) then
    return WG:Say('Merchant selling API is unavailable in this client.')
  end
  local count=0
  -- Limit one merchant visit to the 12-item buyback window. This helps recover mistakes.
  for _,bag in ipairs(playerBags()) do
    for slot=1,slots(bag) do
      if count>=12 then break end
      if safeJunk(bag,slot) then
        local ok=pcall(sell,bag,slot)
        if ok then count=count+1 end
      end
    end
    if count>=12 then break end
  end
  if count>0 then WG:Say('Vendor sale requested for '..count..' safe gray junk stacks (12 maximum per visit).') end
end
function A:TurnInProgress()
  if not WG:Enabled('autoquest') or WG:Protected() then return end
  if not IsQuestCompletable or not CompleteQuest then return end
  local ok,ready=pcall(IsQuestCompletable)
  if ok and ready then
    local done,err=pcall(CompleteQuest)
    if not done then WG:Say('Quest progression blocked: '..tostring(err)) end
  end
end
function A:TurnInReward()
  if not WG:Enabled('autoquest') or WG:Protected() then return end
  if not GetNumQuestChoices or not GetQuestReward then return end
  local ok,choices=pcall(GetNumQuestChoices)
  -- No automatic choice among multiple rewards: player retains the decision.
  if not ok or type(choices)~='number' or choices>1 then return end
  local done,err=pcall(GetQuestReward,1)
  if not done then WG:Say('Quest turn-in blocked by client: '..tostring(err)) end
end
function A:InspectBags()
  if not WG.db or not WG:Enabled('bagcleanup') then
    self.candidate=nil;self.warnedFull=false
    return
  end
  local free,total=freeSlots()
  self.free=free;self.total=total
  self.candidate=(total>0 and free==0) and findCheapestJunk() or nil
  if total>0 and free==0 then
    if not self.warnedFull then
      if self.candidate then
        WG:Say('Bags full. Type /wg automation to review a one-click junk cleanup.')
      else
        WG:Say('Bags full. No eligible gray junk could be identified safely.')
      end
      self.warnedFull=true
    end
  else self.warnedFull=false end
  if self.status then self:UpdateStatus() end
end
function A:UpdateStatus()
  if not self.status then return end
  if not WG:Enabled('bagcleanup') then
    self.status:SetText('Full-bag assistance is disabled.')
  elseif not self.candidate then
    self.status:SetText(self.free==0 and 'Bags full: no eligible gray junk found.' or 'Inventory has free room, or no eligible junk is present.')
  else
    self.status:SetText(('BAGS FULL • Free one slot by deleting: %s (x%d)'):format(self.candidate.name,self.candidate.quantity))
  end
  if self.freeButton then self.freeButton:SetAlpha(self.candidate and 1 or .45) end
end
function A:FreeSlotByClick()
  if not WG:Enabled('bagcleanup') then return WG:Say('Enable full-bag assistance first.') end
  if WG:Protected() then return WG:Say('Cannot delete items during combat.') end
  if not DeleteCursorItem or not GetCursorInfo then return WG:Say('Item deletion API unavailable.') end
  local free,total=freeSlots()
  if total==0 or free>0 then return WG:Say('You already have a free inventory slot.') end
  local recommended=findCheapestJunk()
  if not recommended then return WG:Say('No safe gray-quality junk to delete.') end
  if GetCursorInfo() then return WG:Say('Clear your cursor before freeing a slot.') end
  -- Validate every condition immediately before the hardware-triggered deletion.
  local fresh=safeJunk(recommended.bag,recommended.slot)
  if not fresh or fresh.id~=recommended.id or fresh.quantity~=recommended.quantity then
    return WG:Say('Inventory changed. Please review the junk candidate again.')
  end
  local picked,err=pcall(pickup,fresh.bag,fresh.slot)
  if not picked then return WG:Say('Unable to pick up junk: '..tostring(err)) end
  local kind,id=GetCursorInfo()
  if kind~='item' or (id and type(id)=='number' and id~=fresh.id) then
    if ClearCursor then pcall(ClearCursor) end
    return WG:Say('Item did not match the candidate. No deletion requested.')
  end
  local ok,msg=pcall(DeleteCursorItem)
  if not ok then
    if ClearCursor then pcall(ClearCursor) end
    WG:Say('Game blocked item deletion: '..tostring(msg))
    return
  end
  self:InspectBags()
  WG:Say('Requested deletion of one gray-quality junk stack. Verify your bag slot.')
end
function A:Init()
  local f=WG:Window('automation','Quest & Junk Automation',620,480)
  self.window=f
  WG:Text(f,'AUTOMATION • SELECT EACH FEATURE',24,-81,15,'accent')
  WG:Text(f,'All three options default OFF; enabled only at your request.',24,-109,11,'text',565)
  WG:Divider(f,-129,575,23)
  WG:Check(f,'autoquest','AUTO TURN-IN COMPLETED QUESTS',23,-151)
  WG:Text(f,'Only when a quest NPC offers completion. Multiple rewards require your choice.',57,-179,10,'text',530)
  WG:Check(f,'autoselljunk','SELL GRAY JUNK AT MERCHANTS',23,-215)
  WG:Text(f,'Only vendorable, non-quest, non-favorite gray-quality items.',57,-243,10,'text',530)
  WG:Check(f,'bagcleanup','WARN WHEN BAGS ARE FULL',23,-279)
  WG:Text(f,'Deletion requires a click; the game prohibits silent item destruction.',57,-307,10,'text',530)
  WG:Divider(f,-346,575,23)
  self.status=WG:Text(f,'',25,-366,11,'accent',565)
  self.freeButton=WG:Button(f,'FREE ONE SLOT (GRAY JUNK)',24,-407,336,40,function() A:FreeSlotByClick() end)
  WG:Button(f,'OPEN PANTRY',371,-407,226,40,function() WG:Open('bags') end)
  f.onOpen=function() A:InspectBags();A:UpdateStatus() end
  WG:On('MERCHANT_SHOW',function()
    if C_Timer and C_Timer.After then C_Timer.After(0.1,function() A:AutoSell() end)
    else A:AutoSell() end
  end)
  WG:On('QUEST_PROGRESS',function() A:TurnInProgress() end)
  WG:On('QUEST_COMPLETE',function() A:TurnInReward() end)
  WG:On('BAG_UPDATE_DELAYED',function() A:InspectBags() end)
  WG:On('PLAYER_REGEN_ENABLED',function() A:InspectBags() end)
end
function A:Refresh()
  self:InspectBags()
  if self.window and self.window:IsShown() then self:UpdateStatus() end
end
