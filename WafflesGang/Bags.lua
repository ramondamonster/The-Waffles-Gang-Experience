local WG=_G.WafflesGang
local B={name='Waffle Pantry',buttons={},filter='',category='All'}
table.insert(WG.modules,B)
WG.pantry=B
local function cAPI(field,legacy,...)
  local f=C_Container and C_Container[field] or _G[legacy]
  if type(f)~='function' then return nil end
  local ok,result=pcall(f,...)
  if ok then return result end
end
local function slots(bag) return cAPI('GetContainerNumSlots','GetContainerNumSlots',bag) or 0 end
local function entry(bag,slot)
  local item=cAPI('GetContainerItemInfo','GetContainerItemInfo',bag,slot)
  local link=cAPI('GetContainerItemLink','GetContainerItemLink',bag,slot)
  local d={bag=bag,slot=slot,link=link}
  if type(item)=='table' then
    d.itemID=item.itemID; d.icon=item.iconFileID; d.count=item.stackCount; d.quality=item.quality
  elseif item then
    -- Older variants provide multiple values, but Forever should use the modern table.
    d.icon=item
  end
  if not d.itemID and link and C_Item and C_Item.GetItemInfoInstant then
    d.itemID=C_Item.GetItemInfoInstant(link)
  end
  if not d.icon and d.itemID and C_Item and C_Item.GetItemIconByID then
    d.icon=C_Item.GetItemIconByID(d.itemID)
  end
  if not d.icon and not d.link then d.empty=true; return d end
  d.count=d.count or 1
  d.name=(C_Item and C_Item.GetItemInfo and C_Item.GetItemInfo(link or d.itemID)) or (GetItemInfo and GetItemInfo(link or d.itemID)) or ('Item '..tostring(d.itemID or ''))
  local classID, equipLoc
  if C_Item and C_Item.GetItemInfoInstant then
    local _,_,_,equip,_,class=C_Item.GetItemInfoInstant(link or d.itemID)
    classID=class; equipLoc=equip
  end
  -- Quest markers are a bag-slot property, not always an item-class property.
  -- Recognize quest-related loot even when its item class is equipment/materials.
  local questInfo=cAPI('GetContainerItemQuestInfo','GetContainerItemQuestInfo',bag,slot)
  d.quest=(type(item)=='table' and item.isQuestItem==true)
    or (type(questInfo)=='table' and (questInfo.isQuestItem==true or (type(questInfo.questID)=='number' and questInfo.questID>0)))
    or (questInfo==true) or classID==12
  if d.quest then d.category='Quest'
  elseif equipLoc and equipLoc~='' then d.category='Gear'
  elseif classID==0 then d.category='Consumables'
  elseif classID==7 or classID==5 or classID==6 then d.category='Materials'
  else d.category='Other' end
  return d
end
local function bags()
  local list={0}
  local index=Enum and Enum.BagIndex
  for i=1,4 do list[#list+1]=(index and index['Bag_'..i]) or i end
  if index and index.ReagentBag then list[#list+1]=index.ReagentBag end
  return list
end
-- Bag 0 is the permanent backpack. Equipped bag item links live in the
-- player's inventory slots, not in bag 1-4's container item slots.
-- Forever uses the modern container mapping, with guarded legacy fallbacks.
local function equippedInventorySlot(bag)
  if bag==0 then return nil end
  local toInventory=(C_Container and C_Container.ContainerIDToInventoryID) or ContainerIDToInventoryID
  if type(toInventory)=='function' then
    local ok,id=pcall(toInventory,bag)
    if ok and type(id)=='number' and id>0 then return id end
  end
  if type(GetInventorySlotInfo)=='function' then
    local slotName=(bag==5) and 'ReagentBagSlot' or ('Bag'..tostring(bag-1)..'Slot')
    local ok,id=pcall(GetInventorySlotInfo,slotName)
    if ok and type(id)=='number' and id>0 then return id end
  end
end
local function displayBagName(bag)
  if bag==0 then return 'BACKPACK' end
  if Enum and Enum.BagIndex and Enum.BagIndex.ReagentBag==bag then return 'REAGENT BAG' end
  return 'BAG '..tostring(bag)
end
local function bagTextureAndLink(bag)
  if bag==0 then return 'Interface\\Icons\\INV_Misc_Bag_08',nil,nil end
  local slot=equippedInventorySlot(bag)
  local icon,link
  if slot then
    if type(GetInventoryItemTexture)=='function' then
      local ok,result=pcall(GetInventoryItemTexture,'player',slot)
      if ok then icon=result end
    end
    if type(GetInventoryItemLink)=='function' then
      local ok,result=pcall(GetInventoryItemLink,'player',slot)
      if ok then link=result end
    end
  end
  if not icon and link and type(GetItemIcon)=='function' then
    local ok,result=pcall(GetItemIcon,link)
    if ok then icon=result end
  end
  return icon or 'Interface\\Icons\\INV_Misc_Bag_08',link,slot
end
local VIEW_ORDERS={'Quest First','Gear First','Bag Order'}
local function sortPriority(e,mode)
  if e.empty then return 9 end
  if mode=='Quest First' and e.quest then return 0 end
  if mode=='Gear First' and e.category=='Gear' then return 0 end
  return 1
end
function B:SetViewOrder(mode)
  if mode~='Quest First' and mode~='Gear First' and mode~='Bag Order' then mode='Quest First' end
  self.viewOrder=mode
  if WG.db then WG.db.bagViewOrder=mode end
  if self.viewButton and self.viewButton.label then self.viewButton.label:SetText('VIEW: '..mode:upper()) end
  self:Update()
end
function B:CycleViewOrder()
  local index=1
  for i,v in ipairs(VIEW_ORDERS) do if self.viewOrder==v then index=i break end end
  self:SetViewOrder(VIEW_ORDERS[index%#VIEW_ORDERS+1])
end
function B:UpdateMoney()
  if not self.coins then return end
  local gold,silver,copper=0,0,0
  if GetMoney then
    local ok,cents=pcall(GetMoney)
    if ok and type(cents)=='number' then
      gold=math.floor(cents/10000)
      silver=math.floor(cents/100)%100
      copper=cents%100
    end
  end
  local values={gold,silver,copper}
  local colors={'|cffffd473','|cffd4d9df','|cffd69e71'}
  local icons={'Gold','Silver','Copper'}
  for i,label in ipairs(self.coins) do
    if WG:Enabled('goldtracking') then
      label:SetText(colors[i]..tostring(values[i])..'|r |TInterface\\MoneyFrame\\UI-'..icons[i]..'Icon:13:13:0:0|t')
    else label:SetText('') end
  end
end
-- This is intentionally a display/filter strip, not a replacement for secure
-- Blizzard character bag-equipping slots. Tooltips show the equipped bag's
-- real item; the client handles drag/equip through its own protected UI.
function B:BuildEquippedBagStrip(window)
  self.bagStrip={}
  self.bagStripTitle=WG:Text(window,'EQUIPPED BAGS  |  CLICK A BAG TO FILTER',17,-543,11,'accent',390)
  WG:Button(window,'SHOW ALL',415,-541,92,22,function()
    B.selectedBag=nil
    B:Update()
  end)
  local list=bags()
  local count=#list
  local step=math.floor(493/count)
  local width=math.min(90,step-6)
  for i,bagID in ipairs(list) do
    local btn=CreateFrame('Button',nil,window)
    btn:SetSize(width,56)
    btn:SetPoint('TOPLEFT',window,'TOPLEFT',17+(i-1)*step,-566)
    local frame=WG:Surface(btn,'panel','edge')
    local icon=btn:CreateTexture(nil,'ARTWORK')
    icon:SetSize(34,34)
    icon:SetPoint('TOPLEFT',btn,'TOPLEFT',4,-7)
    local title=WG:Text(btn,bagID==0 and 'PACK' or (bagID==5 and 'REAG.' or 'BAG '..bagID),40,-8,9,'text',width-42)
    local capacity=WG:Text(btn,'',40,-28,9,'accent',width-42)
    local slot={button=btn,bag=bagID,surface=frame,icon=icon,title=title,capacity=capacity}
    self.bagStrip[#self.bagStrip+1]=slot
    btn:SetScript('OnClick',function()
      if WG:Protected() then return WG:Say('Change bag view after combat.') end
      if B.selectedBag==bagID then B.selectedBag=nil else B.selectedBag=bagID end
      B:Update()
    end)
    btn:SetScript('OnEnter',function()
      if not GameTooltip then return end
      GameTooltip:SetOwner(btn,'ANCHOR_RIGHT')
      local hasItem=false
      if slot.inventoryID and slot.link and GameTooltip.SetInventoryItem then
        local ok,result=pcall(GameTooltip.SetInventoryItem,GameTooltip,'player',slot.inventoryID)
        hasItem=ok and result~=false
      end
      if not hasItem then
        GameTooltip:SetText(displayBagName(bagID))
        if bagID~=0 and not slot.link then GameTooltip:AddLine('No bag equipped',1,.55,.4) end
      end
      GameTooltip:AddLine(('Inventory: %d / %d slots'):format(slot.used or 0,slot.total or 0),1,.8,.5)
      GameTooltip:AddLine(B.selectedBag==bagID and 'Click to show all bags' or 'Click to view this bag only',.8,.8,.8)
      GameTooltip:Show()
    end)
    btn:SetScript('OnLeave',function() if GameTooltip then GameTooltip:Hide() end end)
  end
end
function B:UpdateEquippedBagStrip(stats)
  if not self.bagStrip then return end
  for _,p in ipairs(self.bagStrip) do
    local bag=p.bag
    local info=stats[bag] or {used=0,total=0}
    local icon,link,inventoryID=bagTextureAndLink(bag)
    p.link,p.inventoryID=link,inventoryID
    p.used,p.total=info.used,info.total
    p.icon:SetTexture(icon)
    -- Empty slots remain visible, but are dimmed until a bag is equipped.
    p.icon:SetAlpha((bag==0 or info.total>0) and 1 or .42)
    p.capacity:SetText(info.total>0 and (info.used..'/'..info.total) or 'EMPTY')
    local r,g,b=WG.unpack(WG:Color(self.selectedBag==bag and 'accent' or 'edge'))
    p.surface.edge:SetColorTexture(r,g,b)
  end
  if self.bagStripTitle then
    self.bagStripTitle:SetText(self.selectedBag and
      (displayBagName(self.selectedBag)..' SELECTED  |  CLICK AGAIN OR SHOW ALL') or
      'EQUIPPED BAGS  |  CLICK A BAG TO FILTER')
  end
end
-- Item use/equip is a protected action on Forever. Never call
-- C_Container.UseContainerItem from addon Lua: secure right-click below
-- delegates to the game's SecureActionButtonTemplate instead.
local function pickup(bag,slot)
  if C_Container and C_Container.PickupContainerItem then C_Container.PickupContainerItem(bag,slot)
  elseif PickupContainerItem then PickupContainerItem(bag,slot) end
end
-- Native Blizzard container buttons preserve actual use/equip, sale, split,
-- drag and modified-click behavior.  The prior SecureActionButton-only design
-- could show an item while failing to perform the actual equip operation.
function B:GetBagParent(bag)
  self.bagParents=self.bagParents or {}
  if not self.bagParents[bag] then
    local parent=CreateFrame('Frame',nil,self.content)
    parent:SetAllPoints(self.content)
    parent:SetID(bag)
    self.bagParents[bag]=parent
  end
  return self.bagParents[bag]
end
function B:BuildButton(i,forceSecure)
  local holder=self:GetBagParent(0)
  local b,native
  local ok,created=false,nil
  if not forceSecure then
    ok,created=pcall(CreateFrame,'ItemButton','WG_PantryItemNative'..i,holder,'ContainerFrameItemButtonTemplate')
  end
  if ok and created then b=created;native=true
  else
    b=CreateFrame('Button','WG_PantryItemSecure'..i,holder,'SecureActionButtonTemplate')
    b:RegisterForClicks('AnyUp');b:SetAttribute('type2','item')
  end
  b:SetSize(43,43)
  b:SetPoint('TOPLEFT',self.content,'TOPLEFT',((i-1)%9)*51,-math.floor((i-1)/9)*51)
  -- ItemButton templates use GetID() for the actual slot and parent:GetID() for bag.
  b:SetID(1)
  local surface=WG:Surface(b,'bg','edge')
  if native and b.SetNormalTexture then b:SetNormalTexture(nil) end
  local icon=b:CreateTexture(nil,'OVERLAY',nil,0)
  icon:SetPoint('TOPLEFT',b,'TOPLEFT',3,-3);icon:SetPoint('BOTTOMRIGHT',b,'BOTTOMRIGHT',-3,3)
  local qty=WG:Text(b,'',21,-26,10,'accent')
  local mark=WG:Text(b,'',3,-1,10,'accent')
  local level=WG:Text(b,'',3,-28,9,'text')
  local upgrade=WG:Text(b,'',2,-12,9,'accent')
  local p={button=b,icon=icon,qty=qty,mark=mark,level=level,upgrade=upgrade,surface=surface,native=native}
  -- Never replace the native item's OnClick/OnDragStart scripts: they are the
  -- code which allows using/equipping when the client protects inventory APIs.
  if native then
    if b.HookScript then
      b:HookScript('OnEnter',function(self)
        if p.item and not p.item.empty and WG.gear then WG.gear:AppendTooltip(p.item.link) end
      end)
    end
  else
    b:SetScript('OnEnter',function(self)
      if not p.item or p.item.empty then return end
      GameTooltip:SetOwner(self,'ANCHOR_RIGHT')
      if GameTooltip.SetBagItem then GameTooltip:SetBagItem(p.item.bag,p.item.slot) end
      if WG.gear then WG.gear:AppendTooltip(p.item.link) end
      GameTooltip:Show()
    end)
    b:SetScript('OnLeave',function() if GameTooltip then GameTooltip:Hide() end end)
    b:SetScript('OnMouseUp',function(self,mouse)
      if mouse~='LeftButton' or not p.item or WG:Protected() then return end
      local item=p.item
      if IsModifiedClick and IsModifiedClick('CHATLINK') and item.link and ChatEdit_InsertLink then
        ChatEdit_InsertLink(item.link);return
      end
      if C_Container and C_Container.PickupContainerItem then C_Container.PickupContainerItem(item.bag,item.slot)
      elseif PickupContainerItem then PickupContainerItem(item.bag,item.slot) end
    end)
    b:RegisterForDrag('LeftButton')
    b:SetScript('OnDragStart',function()
      if p.item and not WG:Protected() then
        local item=p.item
        if C_Container and C_Container.PickupContainerItem then C_Container.PickupContainerItem(item.bag,item.slot)
        elseif PickupContainerItem then PickupContainerItem(item.bag,item.slot) end
      end
    end)
    b:SetScript('OnReceiveDrag',b:GetScript('OnDragStart'))
  end
  -- Separate favorite button avoids stealing the secure native item click.
  local pin=CreateFrame('Button',nil,b)
  pin:SetSize(15,15);pin:SetPoint('TOPRIGHT',b,'TOPRIGHT',-1,-1)
  pin:SetFrameLevel(b:GetFrameLevel()+3)
  local star=pin:CreateFontString(nil,'OVERLAY','GameFontNormalSmall')
  star:SetAllPoints();star:SetText('☆');star:SetTextColor(1,.84,.39)
  pin:SetScript('OnClick',function()
    if not p.item or not p.item.itemID or WG:Protected() then return end
    local id=p.item.itemID
    WG.db.pins[id]=not WG.db.pins[id] or nil
    B:Update()
  end)
  p.pin=pin;p.star=star
  b:Hide();self.buttons[i]=p
end
function B:Update()
  if not self.window or not WG.db then return end
  self:UpdateMoney()
  if WG:Protected() then return end
  if not WG:Enabled('bagsearch') then self.filter='' end
  local items,used,total={},0,0
  local bagStats={}
  for _,bag in ipairs(bags()) do
    local n=slots(bag)
    local inBag=0
    for s=1,n do
      local e=entry(bag,s)
      total=total+1
      if not e.empty then used=used+1;inBag=inBag+1 end
      local matches=(self.filter=='' or (not e.empty and (e.name or ''):lower():find(self.filter,1,true)))
      if (self.selectedBag==nil or self.selectedBag==bag) and matches and
        (not WG:Enabled('bagcategories') or self.category=='All' or (not e.empty and e.category==self.category)) then
        items[#items+1]=e
      end
    end
    bagStats[bag]={used=inBag,total=n}
  end
  self:UpdateEquippedBagStrip(bagStats)
  -- This is DISPLAY ordering only. Never swap physical inventory slots here.
  -- Blizzard's native sort can put items toward the far end of the containers;
  -- in a combined Pantry, occupied slots should still appear before empty ones.
  -- Keep the original bag+slot on every entry for using, dragging and linking.
  table.sort(items,function(a,b)
    if a.empty~=b.empty then return not a.empty end
    if WG:Enabled('bagpins') and not a.empty then
      local aa=a.itemID and WG.db.pins[a.itemID] and 1 or 0
      local bb=b.itemID and WG.db.pins[b.itemID] and 1 or 0
      if aa~=bb then return aa>bb end
    end
    local qa,qb=sortPriority(a,self.viewOrder),sortPriority(b,self.viewOrder)
    if qa~=qb then return qa<qb end
    if a.bag~=b.bag then return a.bag<b.bag end
    return a.slot<b.slot
  end)
  for i=1,270 do
    local p=self.buttons[i]
    if p then
    local e=items[i]
    p.item=e
    if e then
      -- SecureActionButtonTemplate parses this as 'bag slot', not a link.
      -- item2 is the right mouse button action. Keep the physical coordinates
      -- even when favorites, searching or quest-first views change icon order.
      -- Out-of-combat only (Update returns before this block in combat).
      if p.button:GetParent()~=self:GetBagParent(e.bag) then
        p.button:SetParent(self:GetBagParent(e.bag))
      end
      p.button:SetID(e.slot)
      p.button.bagID=e.bag
      if p.button.SetBagID then p.button:SetBagID(e.bag) end
      if not p.native then
        p.button:SetAttribute('item2',not e.empty and (e.bag..' '..e.slot) or nil)
      end
      p.button:ClearAllPoints()
      p.button:SetPoint('TOPLEFT',self.content,'TOPLEFT',((i-1)%9)*51,-math.floor((i-1)/9)*51)
      p.icon:SetTexture(e.empty and nil or e.icon)
      if e.quality and ITEM_QUALITY_COLORS and ITEM_QUALITY_COLORS[e.quality] then
        local q=ITEM_QUALITY_COLORS[e.quality]
        p.surface.edge:SetColorTexture(q.r,q.g,q.b)
      else p.surface.edge:SetColorTexture(WG.unpack(WG:Color('edge'))) end
      p.qty:SetText(not e.empty and e.count>1 and tostring(e.count) or '')
      local pinned=WG:Enabled('bagpins') and e.itemID and WG.db.pins[e.itemID]
      p.mark:SetText('')
      p.pin:SetShown(WG:Enabled('bagpins') and not e.empty)
      p.star:SetText(pinned and '★' or '☆')
      p.upgrade:SetText('')
      if WG:Enabled('gearsuggestions') and not e.empty and e.category=='Gear' and WG.gear then
        local compare=WG.gear:CompareLink(e.link)
        if compare and compare.newSlot then p.upgrade:SetText('NEW')
        elseif compare and type(compare.percent)=='number' then
          local change=compare.percent
          if change>0.05 then p.upgrade:SetText(('+%.1f%%'):format(change))
          elseif change<-.05 then p.upgrade:SetText(('%.1f%%'):format(change))
          else p.upgrade:SetText('0.0%') end
        elseif compare and not compare.eligible then p.upgrade:SetText('N/A')
        else p.upgrade:SetText('?') end
      end
      p.level:SetText('')
      if WG:Enabled('bagitemlevel') and e.category=='Gear' and C_Item and C_Item.GetDetailedItemLevelInfo then
        local ok,lvl=pcall(C_Item.GetDetailedItemLevelInfo,e.link or e.itemID)
        if ok and type(lvl)=='number' then p.level:SetText(tostring(lvl)) end
      end
      if WG:Enabled('bagrecent') and not e.empty and C_NewItems and C_NewItems.IsNewItem then
        local ok,new=pcall(C_NewItems.IsNewItem,e.bag,e.slot)
        if ok and new and p.mark:GetText()=='' then p.mark:SetText('NEW') end
      end
      p.button:Show()
    else p.button:Hide();p.pin:Hide() end
    end
  end
  self.content:SetHeight(math.max(300,math.ceil(#items/9)*51+12))
  if self.counter then
    self.counter:SetText(('SLOTS: %d / %d  •  Click ☆ to favorite  •  Right-click gear to equip'):format(used,total))
  end
  if self.search then self.search:SetShown(WG:Enabled('bagsearch')) end
  if self.categoryButtons then
    for _,btn in ipairs(self.categoryButtons) do btn:SetShown(WG:Enabled('bagcategories')) end
  end
  self:UpdateMoney()
end
function B:SortStatus(message)
  if self.sortStatus then self.sortStatus:SetText(message or '') end
end
function B:FinishSort(message)
  if not self.sorting then return end
  self.sorting=false
  if self.sortButton then
    self.sortButton:SetEnabled(true)
    self.sortButton.label:SetText('SORT')
    self.sortButton:SetAlpha(1)
  end
  self:SortStatus(message or 'Physical bags sorted. Quest-first ordering is a Pantry view.')
  self:Update()
end
function B:SortAllBags()
  if WG:Protected() then
    self:SortStatus('Cannot sort bags during combat.')
    return WG:Say('Cannot sort bags during combat.')
  end
  if self.sorting then return end
  if GetCursorInfo then
    local ok,kind=pcall(GetCursorInfo)
    if ok and kind then
      self:SortStatus('Place the item on your cursor before sorting.')
      return WG:Say('Place the held item before sorting your bags.')
    end
  end
  -- Prefer Forever's modern API. Legacy fallback is for transitional clients.
  local sortFn = (C_Container and type(C_Container.SortBags)=='function' and C_Container.SortBags)
    or (type(SortBags)=='function' and SortBags)
  if type(sortFn)~='function' then
    self:SortStatus('Bag sorting is unavailable in this client build.')
    return WG:Say('The game does not provide a bag-sorting function.')
  end
  self.sorting=true
  self.sortRevision=(self.sortRevision or 0)+1
  local revision=self.sortRevision
  self.sortButton:SetEnabled(false)
  self.sortButton.label:SetText('SORTING')
  self.sortButton:SetAlpha(.65)
  self:SortStatus('Sorting physical bags using the game sorter. Quest-first applies to the Pantry view.')
  local ok,result=pcall(sortFn)
  if not ok or result==false then
    self:FinishSort('Bag sorting failed. Your inventory has not been rearranged by Waffles Gang.')
    WG:Say('Bag sorting failed: '..(not ok and tostring(result) or 'game rejected request'))
    return
  end
  -- Bag movements arrive asynchronously. Refresh on BAG_UPDATE_DELAYED, with
  -- a timer fallback when the inventory was already sorted (no event emitted).
  if C_Timer and type(C_Timer.After)=='function' then
    C_Timer.After(2.0,function()
      if B.sorting and B.sortRevision==revision then
        B:FinishSort('Sort requested; no bag changes reported. Already sorted or client did not move items.')
      end
    end)
  else
    -- Old clients may not have timers; leave button usable, and bag events still update.
    self:FinishSort('Sort requested. Item order will refresh with the next bag update.')
  end
end
function B:Toggle(source)
  -- Some addon combinations run both a keybinding click and Blizzard's
  -- ToggleBackpack hook for a single B press. Ignore the second delivery,
  -- otherwise the Pantry opens and immediately closes again.
  local now=GetTime and GetTime() or 0
  if source=='native' and self.lastKeyToggleAt and now-self.lastKeyToggleAt<0.35 then return end
  if source=='key' then
    self.lastKeyToggleAt=now
    self.keyPresses=(self.keyPresses or 0)+1
  end
  if not WG:Enabled('bags') then return WG:Say('Enable Waffle Pantry in Settings.') end
  if not self.window then return WG:Say('Waffle Pantry is not initialized.') end
  if self.window:IsShown() then self.window:Hide(); return end
  -- The window may be shown during combat, but item-slot attributes and
  -- drag/drop remain protected and are refreshed after combat.
  if not WG:Protected() and CloseAllBags then
    self.suppressNativeBagHook=true
    pcall(CloseAllBags)
    self.suppressNativeBagHook=false
  end
  WG:Open('bags')
  self:Update()
end
function B:Binding()
  if WG:Protected() or not self.bindOwner then return end
  if ClearOverrideBindings then pcall(ClearOverrideBindings,self.bindOwner) end
  self.bindingActive=false
  if WG:Enabled('bags') and WG.db.bagKeyOverride and SetOverrideBindingClick and self.toggleButton then
    local ok,result=pcall(SetOverrideBindingClick,self.bindOwner,true,'B',self.toggleButton:GetName(),'LeftButton')
    -- This function returns no success value in some WoW clients.
    self.bindingActive=ok and result~=false
    if not ok then WG:Say('Could not bind B. Use /wg bags or the normal bag key until bindings update.') end
  end
end
-- If a build ignores the priority click override, the ordinary Blizzard B
-- binding still executes ToggleBackpack/ToggleAllBags. Redirect those actions
-- to the Pantry as a fallback, without replacing the secure game functions.
function B:InstallNativeBagFallback()
  if self.nativeHooksInstalled or not hooksecurefunc then return end
  self.nativeHooksInstalled=true
  local function redirected()
    if not WG.db or not WG:Enabled('bags') or not WG.db.bagKeyOverride then return end
    if B.suppressNativeBagHook then return end
    local now=GetTime and GetTime() or nil
    if now and B.nativeLastAt and now-B.nativeLastAt<0.09 then return end
    B.nativeLastAt=now
    if B.nativeFallbackBusy then return end
    B.nativeFallbackBusy=true
    B:Toggle('native')
    if not WG:Protected() and CloseAllBags then
      B.suppressNativeBagHook=true
      pcall(CloseAllBags)
      B.suppressNativeBagHook=false
    end
    B.nativeFallbackBusy=false
  end
  for _,fname in ipairs({'ToggleBackpack','ToggleAllBags'}) do
    if type(_G[fname])=='function' then
      local ok=pcall(hooksecurefunc,fname,redirected)
      if not ok then WG:Say('Bag shortcut fallback unavailable for '..fname) end
    end
  end
end
function B:Init()
  local window=WG:Window('bags','Waffle Pantry',526,724,true)
  self.window=window
  WG:Text(window,'ALL EQUIPPED BAGS',17,-74,13,'accent')
  local search=CreateFrame('EditBox',nil,window,'InputBoxTemplate')
  search:SetSize(267,28); search:SetPoint('TOPLEFT',window,'TOPLEFT',36,-105)
  search:SetAutoFocus(false); search:SetText('')
  search:SetScript('OnTextChanged',function(self)
    B.filter=(self:GetText() or ''):lower()
    if WG.db then B:Update() end
  end)
  search:SetScript('OnEscapePressed',function(self) self:ClearFocus() end)
  self.search=search
  WG:Button(window,'CLEAR',327,-104,88,28,function() search:SetText('') end)
  self.sortButton=WG:Button(window,'SORT',423,-104,83,28,function() B:SortAllBags() end)
  local categories={'All','Gear','Consumables','Materials','Quest','Other'}
  self.categoryButtons={}
  for i,cat in ipairs(categories) do
    self.categoryButtons[i]=WG:Button(window,cat,15+(i-1)*84,-150,80,26,function() B.category=cat; B:Update() end)
  end
  self.viewButton=WG:Button(window,'VIEW: QUEST FIRST',16,-184,190,26,function() B:CycleViewOrder() end)
  WG:Text(window,'Quest first changes display; SORT moves items in actual bags.',215,-189,10,'text',297)
  local scroll=CreateFrame('ScrollFrame',nil,window,'UIPanelScrollFrameTemplate')
  scroll:SetPoint('TOPLEFT',window,'TOPLEFT',15,-222)
  scroll:SetPoint('BOTTOMRIGHT',window,'BOTTOMRIGHT',-38,188)
  local inside=CreateFrame('Frame',nil,scroll)
  inside:SetSize(460,340); scroll:SetScrollChild(inside)
  self.scroll=scroll; self.content=inside
  self:BuildEquippedBagStrip(window)
  self.counter=WG:Text(window,'',17,-631,11,'text',485)
  WG:Text(window,'PURSE',17,-659,11,'accent')
  self.coins={}
  for i,x in ipairs({90,285,405}) do
    self.coins[i]=WG:Text(window,'',x,-659,12,'text',i==1 and 180 or 106)
  end
  self.sortStatus=WG:Text(window,'SORT rearranges actual bags; VIEW changes category order here.',17,-689,10,'text',490)
  window.onOpen=function() B:Update() end
  self.viewOrder=(WG.db and WG.db.bagViewOrder) or 'Quest First'
  if self.viewOrder~='Quest First' and self.viewOrder~='Gear First' and self.viewOrder~='Bag Order' then self.viewOrder='Quest First' end
  self.viewButton.label:SetText('VIEW: '..self.viewOrder:upper())
  self.bindOwner=CreateFrame('Frame',nil,UIParent)
  -- Some Forever builds dispatch binding clicks on DOWN, others on UP.
  -- Handle whichever edge arrives first; discard the matching UP only.
  -- Do not use a timed debounce: it made legitimate quick B presses disappear.
  self.toggleButton=CreateFrame('Button','WafflesGangPantryKey',UIParent)
  self.toggleButton:SetSize(1,1)
  self.toggleButton:SetPoint('BOTTOMLEFT',UIParent,'BOTTOMLEFT',1,1)
  self.toggleButton:RegisterForClicks('AnyDown','AnyUp')
  self.toggleButton:SetScript('OnClick',function(_,mouse,down)
    local now=GetTime and GetTime() or 0
    if down==true then
      -- Key-down can be the only click event on some client configurations.
      B.lastKeyDownAt=now
      B:Toggle('key')
    elseif down==false then
      -- If WoW delivered both edges for this press, the key-down already
      -- toggled the window. A key-up-only configuration still works.
      if B.lastKeyDownAt and now-B.lastKeyDownAt<0.8 then
        B.lastKeyDownAt=nil
        return
      end
      B.lastKeyDownAt=nil
      B:Toggle('key')
    else
      B.lastKeyDownAt=nil
      B:Toggle('key')
    end
  end)
  self:InstallNativeBagFallback()
  -- Build inventory slots after the counter, money, and B-key controls are
  -- ready.  A client update may reject an ItemButton template or one of its
  -- inherited methods.  Do not abandon Pantry initialization in that case.
  -- Retry the affected slot with the existing secure-button implementation.
  local failures=0
  for i=1,270 do
    local ok,err=pcall(self.BuildButton,self,i,false)
    if not ok then
      local fallbackOk,fallbackErr=pcall(self.BuildButton,self,i,true)
      if not fallbackOk then
        failures=failures+1
        if not self.itemBuildError then
          self.itemBuildError='Native: '..tostring(err)..' | secure: '..tostring(fallbackErr)
        end
      end
    end
  end
  self.itemButtonCount=0
  for _,entry in pairs(self.buttons) do
    if entry and entry.button then self.itemButtonCount=self.itemButtonCount+1 end
  end
  if failures>0 then
    WG:Say(('Pantry could not create %d item buttons. Run /wg diag and check BugSack.'):format(failures))
  end
  WG:Button(window,'GEAR ADVISOR',236,-68,136,28,function() WG:Open('gear') end)
  WG:Button(window,'FREE BAG SLOT',383,-68,124,28,function() WG:Open('automation') end)
  WG:On('BAG_UPDATE_DELAYED',function()
    B:Update()
    if B.sorting then B:FinishSort('Bag inventory refreshed. Favorites and filters remain applied.') end
  end)
  WG:On('GET_ITEM_INFO_RECEIVED',function() if B.window and B.window:IsShown() then B:Update() end end)
  WG:On('PLAYER_EQUIPMENT_CHANGED',function() if B.window and B.window:IsShown() then B:Update() end end)
  WG:On('PLAYER_MONEY',function() B:UpdateMoney() end)
  WG:On('PLAYER_ENTERING_WORLD',function() B:UpdateMoney() end)
  WG:On('PLAYER_REGEN_ENABLED',function() B:Update(); B:Binding() end)
  WG:On('PLAYER_ENTERING_WORLD',function()
    B:Binding()
    -- A bag addon may register its own priority B override after we do.
    -- Reassert our enabled preference once, after the login UI settles.
    if C_Timer and C_Timer.After then
      C_Timer.After(2,function() if WG.db and not WG:Protected() then B:Binding() end end)
    end
  end)
  WG:On('UPDATE_BINDINGS',function() B:Binding() end)
end
function B:Refresh()
  self:Binding()
  if self.window and not WG:Enabled('bags') then self.window:Hide() end
  if self.window and self.window:IsShown() then self:Update() end
end
-- Override the slash routing to use the same B-key toggle behavior.
local prevToggle=WG.Toggle
function WG:Toggle(key)
  if key=='bags' and B.window then return B:Toggle() end
  return prevToggle(self,key)
end
