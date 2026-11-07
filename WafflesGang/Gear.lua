-- Waffles Gang | advisory gear comparisons, never an automatic equipment swap.
-- Stat weights are transparent heuristics, NOT a DPS/healing simulation.
local WG=_G.WafflesGang
local G={name='Gear Advisor',profileNames={},rows={}}
WG.gear=G
table.insert(WG.modules,G)

local SLOT={
 INVTYPE_HEAD={1},INVTYPE_NECK={2},INVTYPE_SHOULDER={3},INVTYPE_CHEST={5},INVTYPE_ROBE={5},
 INVTYPE_WAIST={6},INVTYPE_LEGS={7},INVTYPE_FEET={8},INVTYPE_WRIST={9},INVTYPE_HAND={10},
 INVTYPE_CLOAK={15},INVTYPE_FINGER={11,12},INVTYPE_TRINKET={13,14},
 INVTYPE_WEAPON={16,17},INVTYPE_WEAPONMAINHAND={16},INVTYPE_2HWEAPON={16},
 INVTYPE_WEAPONOFFHAND={17},INVTYPE_SHIELD={17},INVTYPE_HOLDABLE={17},
 INVTYPE_RANGED={18},INVTYPE_RANGEDRIGHT={18},INVTYPE_THROWN={18},INVTYPE_RELIC={18},
}
local function itemInfo(link)
  if not link then return end
  local api=C_Item and C_Item.GetItemInfo or GetItemInfo
  if type(api)~='function' then return end
  local ok,name,_,quality,level,required,_,_,_,equip,_,value=pcall(api,link)
  if not ok then return end
  if not name or not equip or equip=='' then
    local instant=(C_Item and C_Item.GetItemInfoInstant) or GetItemInfoInstant
    if type(instant)=='function' then
      local yes,_,_,_,instantEquip=pcall(instant,link)
      if yes and instantEquip then equip=instantEquip end
    end
  end
  if not name and type(link)=='string' then name=link:match('%[([^%]]+)%]') end
  if not name and type(link)=='number' then name='Item '..link end
  if not name then return end
  return {name=name,quality=quality,itemLevel=level,required=required or 0,equip=equip or '',vendor=value or 0}
end
local function stats(link)
  local fn=C_Item and C_Item.GetItemStats or GetItemStats
  if not link or type(fn)~='function' then return end
  local ok,result=pcall(fn,link)
  if ok and type(result)=='table' then return result end
end
-- Forever has nine class talent sets, each with three talent trees. The
-- specialization API can expose names and spent points; keep class-backed
-- fallbacks so the interface never shows another class's builds.
-- Weighting is a transparent heuristic, not a damage or healing simulation.
local CLASSES={
  WARRIOR={
    {'Arms','Strength',.92,.56,.51,.65},
    {'Fury','Strength',.78,.90,.48,.52},
    {'Protection','Strength',.46,.58,.81,.89},
  },
  PALADIN={
    {'Holy','Intellect',.58,.87,.70,.62},
    {'Protection','Strength',.51,.61,.79,.86},
    {'Retribution','Strength',.85,.77,.52,.64},
  },
  HUNTER={
    {'Beast Mastery','Agility',.65,.85,.72,.50},
    {'Marksmanship','Agility',.94,.61,.55,.59},
    {'Survival','Agility',.80,.72,.65,.60},
  },
  ROGUE={
    {'Assassination','Agility',.87,.73,.58,.62},
    {'Combat','Agility',.69,.91,.58,.59},
    {'Subtlety','Agility',.88,.70,.64,.55},
  },
  PRIEST={
    {'Discipline','Intellect',.60,.78,.71,.64},
    {'Holy','Intellect',.60,.83,.69,.60},
    {'Shadow','Intellect',.77,.90,.58,.51},
  },
  SHAMAN={
    {'Elemental','Intellect',.78,.83,.68,.58},
    {'Enhancement','Agility',.75,.91,.57,.60},
    {'Restoration','Intellect',.57,.85,.69,.64},
  },
  MAGE={
    {'Arcane','Intellect',.67,.91,.64,.54},
    {'Fire','Intellect',.98,.69,.55,.52},
    {'Frost','Intellect',.79,.79,.67,.53},
  },
  WARLOCK={
    {'Affliction','Intellect',.68,.92,.65,.55},
    {'Demonology','Intellect',.73,.78,.77,.54},
    {'Destruction','Intellect',.92,.71,.55,.60},
  },
  DRUID={
    {'Balance','Intellect',.71,.85,.66,.55},
    {'Feral Combat','Agility',.81,.76,.65,.62},
    {'Restoration','Intellect',.58,.84,.75,.62},
  },
}
local function apiSpec(index)
  local fn=(C_SpecializationInfo and C_SpecializationInfo.GetSpecializationInfo) or GetSpecializationInfo
  if type(fn)~='function' then return end
  local ok,id,name,description,icon,role,primary,points=pcall(fn,index)
  if ok and type(name)=='string' and name~='' then
    return {name=name,role=role,primary=primary,points=type(points)=='number' and points or 0}
  end
end
local function playerClass()
  local name,token
  if UnitClass then name,token=UnitClass('player') end
  return token or 'WARRIOR',name or 'Warrior'
end
function G:ClassBuilds()
  local token,name=playerClass()
  local base=CLASSES[token]
  if not base then
    -- A future custom client class remains auto-detected, not mislabeled as Warrior.
    return token,name,{{'General','Strength',.7,.7,.6,.6}}
  end
  return token,name,base
end
function G:AutoTreeIndex()
  local _,_,builds=self:ClassBuilds()
  local chosen,points=1,0
  for i=1,#builds do
    local info=apiSpec(i)
    if info and info.points>points then chosen=i;points=info.points end
  end
  if points>0 then return chosen,'most points invested' end
  local getCurrent=(C_SpecializationInfo and C_SpecializationInfo.GetSpecialization) or GetSpecialization
  if type(getCurrent)=='function' then
    local ok,index=pcall(getCurrent)
    if ok and type(index)=='number' and index>=1 and index<=#builds then
      return index,'active specialization'
    end
  end
  return 1,'first tree (no committed points detected)'
end
function G:SelectedBuild()
  local token,className,builds=self:ClassBuilds()
  local selected=(WG.db and WG.db.gearProfile) or 'Auto'
  local index=tonumber(tostring(selected):match('^Tree(%d+)$'))
  local source='manually selected'
  if not index or index<1 or index>#builds then
    index,source=self:AutoTreeIndex()
  end
  local tree=builds[index] or builds[1]
  local reported=apiSpec(index)
  -- Use Forever's localized tree name only when available.
  local label=(reported and reported.name) or tree[1]
  return {
    class=token,className=className,index=index,name=label,source=source,
    primary=tree[2],crit=tree[3],haste=tree[4],mastery=tree[5],vers=tree[6],
  }
end
function G:GetProfiles()
  local token,className,builds=self:ClassBuilds()
  local active=self:AutoTreeIndex()
  local list={{label='AUTO  /  '..(builds[active] and builds[active][1] or 'Current'),value='Auto'}}
  for index,tree in ipairs(builds) do
    local reported=apiSpec(index)
    list[#list+1]={label=className..'  /  '..(reported and reported.name or tree[1]),value='Tree'..index}
  end
  return list
end
function G:PrimaryStat()
  return self:SelectedBuild().primary
end
-- Do not silently drop equipment when older Forever items have no modern
-- GetItemStats result. Fall back to item level for BOTH sides of a comparison,
-- never compare a weighted-stat score with a completely different unit.
function G:ItemLevel(link,info)
  if C_Item and C_Item.GetDetailedItemLevelInfo then
    local ok,value=pcall(C_Item.GetDetailedItemLevelInfo,link)
    if ok and type(value)=='number' and value>0 then return value end
  end
  if type(GetDetailedItemLevelInfo)=='function' then
    local ok,value=pcall(GetDetailedItemLevelInfo,link)
    if ok and type(value)=='number' and value>0 then return value end
  end
  if info and type(info.itemLevel)=='number' and info.itemLevel>0 then return info.itemLevel end
end
function G:Score(link,forceLevel)
  if not link or WG:Protected() then return end
  local info=itemInfo(link)
  if not info or not SLOT[info.equip] then return end
  if not forceLevel then
    local values=stats(link)
    if values then
      local build=self:SelectedBuild()
      local primary=build.primary
      local weight={
        ITEM_MOD_STAMINA_SHORT=.20,
        ITEM_MOD_CRIT_RATING_SHORT=build.crit,
        ITEM_MOD_HASTE_RATING_SHORT=build.haste,
        ITEM_MOD_MASTERY_RATING_SHORT=build.mastery,
        ITEM_MOD_VERSATILITY=build.vers,
        ITEM_MOD_VERSATILITY_SHORT=build.vers,
        ITEM_MOD_ATTACK_POWER_SHORT=.32,ITEM_MOD_SPELL_POWER_SHORT=.32,
        ITEM_MOD_HEALTH_SHORT=.08,
      }
      weight['ITEM_MOD_'..string.upper(primary)..'_SHORT']=1.4
      weight.ITEM_MOD_AGILITY_SHORT=primary=='Agility' and 1.4 or .05
      weight.ITEM_MOD_STRENGTH_SHORT=primary=='Strength' and 1.4 or .05
      weight.ITEM_MOD_INTELLECT_SHORT=primary=='Intellect' and 1.4 or .05
      local score=0;local found=false
      for k,value in pairs(values) do
        if type(value)=='number' and weight[k] then
          score=score+math.max(0,value)*weight[k]
          found=true
        end
      end
      if found and score>0 then return score,info,'weighted stats' end
    end
  end
  local level=self:ItemLevel(link,info)
  if level then return level,info,'item level only' end
end
function G:CompareLink(link)
  if not link or WG:Protected() then return end
  local candidate,info,basis=self:Score(link)
  if not candidate or not info then
    -- It may not be cached yet: return explicit status instead of no label.
    return {name=(itemInfo(link) or {}).name,reason='Item stats not yet loaded',eligible=false,loading=true}
  end
  local playerLevel=UnitLevel and UnitLevel('player') or 0
  if type(playerLevel)=='number' and type(info.required)=='number' and info.required>playerLevel then
    return {reason='Requires level '..info.required,eligible=false,name=info.name}
  end
  local equipSlots=SLOT[info.equip]
  if not equipSlots then return end
  local forceLevel=(basis=='item level only')
  for _,slot in ipairs(equipSlots) do
    local equipped=GetInventoryItemLink and GetInventoryItemLink('player',slot)
    if equipped and not forceLevel then
      local prior,_,priorBasis=self:Score(equipped)
      if not prior or priorBasis~=basis then forceLevel=true end
    end
  end
  if forceLevel then
    candidate=self:ItemLevel(link,info)
    basis='item level only'
    if not candidate then return {name=info.name,reason='Cannot compare item levels',eligible=false,loading=true} end
  end
  local bestSlot,oldScore,oldName
  for _,slot in ipairs(equipSlots) do
    local equipped=GetInventoryItemLink and GetInventoryItemLink('player',slot)
    local prior,priorInfo
    if equipped then
      prior,priorInfo=self:Score(equipped,forceLevel)
    else prior=0 end
    if prior and (oldScore==nil or prior<oldScore) then
      oldScore,bestSlot=prior,slot
      oldName=equipped and ((priorInfo or itemInfo(equipped) or {}).name) or 'Empty slot'
    end
  end
  if oldScore==nil then return {name=info.name,reason='Equipped item data not available',eligible=false,loading=true} end
  local newSlot=oldScore<=0
  local percent=not newSlot and oldScore>0 and (candidate-oldScore)/oldScore*100 or nil
  return {name=info.name,score=candidate,oldScore=oldScore,oldName=oldName,slot=bestSlot,
          percent=percent,newSlot=newSlot,eligible=true,primary=self:PrimaryStat(),basis=basis}
end
function G:AppendTooltip(link)
  if not WG:Enabled('gearsuggestions') or not GameTooltip then return end
  local c=self:CompareLink(link)
  if not c then return end
  GameTooltip:AddLine('Waffles Gear Advisor',1,.77,.38)
  if c.eligible then
    if c.newSlot then GameTooltip:AddLine('NEW SLOT - nothing equipped for comparison',.3,1,.4)
    else GameTooltip:AddLine(('%+.1f%% estimated stat score (%s)'):format(c.percent,c.primary),c.percent>=0 and .3 or 1,c.percent>=0 and 1 or .45,.4) end
    GameTooltip:AddLine('Compared with '..(c.oldName or 'equipped item'),.8,.8,.8)
    GameTooltip:AddLine('Estimate method: '..(c.basis or 'unknown'),.8,.7,.5)
    GameTooltip:AddLine('Not a DPS/HPS prediction; effects and weapon DPS are not modeled.',.65,.65,.65)
  else GameTooltip:AddLine(c.reason or 'Cannot equip yet',1,.45,.35) end
  GameTooltip:Show()
end
function G:ReadBagUpgrades()
  local result={}
  if WG:Protected() then return result end
  local getSlots=(C_Container and C_Container.GetContainerNumSlots) or GetContainerNumSlots
  local getLink=(C_Container and C_Container.GetContainerItemLink) or GetContainerItemLink
  if not getSlots or not getLink then return result end
  local bags={0,1,2,3,4}
  if Enum and Enum.BagIndex and Enum.BagIndex.ReagentBag then bags[#bags+1]=Enum.BagIndex.ReagentBag end
  for _,bag in ipairs(bags) do
    local ok,n=pcall(getSlots,bag)
    if ok and type(n)=='number' then
      for slot=1,n do
        local got,link=pcall(getLink,bag,slot)
        if got and link then
          local c=self:CompareLink(link)
          if c and c.eligible and (c.newSlot or type(c.percent)=='number') then
            c.bag=bag;c.bagSlot=slot; c.link=link
            result[#result+1]=c
          end
        end
      end
    end
  end
  table.sort(result,function(a,b) return (a.newSlot and 100000 or a.percent or 0)>(b.newSlot and 100000 or b.percent or 0) end)
  return result
end
function G:Update()
  if not self.window then return end
  local build=self:SelectedBuild()
  self.summary:SetText((build.className..' / '..build.name..' / '..build.primary..'  ('..build.source..')'))
  local upgrades=self:ReadBagUpgrades()
  self.count:SetText(#upgrades..' comparable bag items (positive and negative estimates; not DPS)')
  for i,row in ipairs(self.rows) do
    local c=upgrades[i]
    if c then
      row.link=c.link
      row.label:SetText(('%s  %s  |cffc7b99c(vs %s / %s)|r'):format(c.newSlot and 'NEW SLOT' or ('%+.1f%%'):format(c.percent),c.name,c.oldName or 'empty',c.basis or 'stats'))
      row:Show()
    else row:Hide() end
  end
end
function G:Init()
  local f=WG:Window('gear','Gear & Talent Advisor',715,615)
  self.window=f
  WG:Text(f,'YOUR CLASS / TALENT TREES',25,-79,14,'accent')
  WG:Text(f,'Class detected automatically. Auto picks the tree with the most committed points.',25,-105,11,'text',660)
  local classKey=self:ClassBuilds()
  if WG.db.gearClass~=classKey then
    WG.db.gearProfile='Auto' -- account-wide SavedVariables must not carry another class's selected tree
    WG.db.gearClass=classKey
  end
  if not tostring(WG.db.gearProfile or ''):match('^Tree%d+$') then WG.db.gearProfile='Auto' end
  self.profileButtons={}
  local profiles=self:GetProfiles()
  for i,option in ipairs(profiles) do
    local row=math.floor((i-1)/3); local col=(i-1)%3
    local btn=WG:Button(f,option.label,24+col*224,-141-row*41,214,35,function()
      WG.db.gearProfile=option.value;self:Update();WG:Refresh()
    end)
    self.profileButtons[#self.profileButtons+1]={button=btn,option=option}
  end
  local rowCount=math.ceil(#profiles/3)
  self.summary=WG:Text(f,'',25,-155-rowCount*41,12,'accent',630)
  WG:Divider(f,-182-rowCount*41,654,25)
  self.count=WG:Text(f,'',25,-198-rowCount*41,12,'text')
  self.rows={}
  for i=1,7 do
    local y=-227-rowCount*41-(i-1)*36
    local button=WG:Button(f,'',24,y,663,31,function()
      local selected=G.rows[i]
      if selected and selected.link then
        WG:Open('bags')
        if WG.pantry and WG.pantry.search then
          local name=(itemInfo(selected.link) or {}).name
          if name then WG.pantry.search:SetText(name) end
        end
      end
    end)
    button.label:SetJustifyH('LEFT')
    button.label:ClearAllPoints();button.label:SetPoint('LEFT',button,'LEFT',10,0)
    button.label:SetWidth(640)
    self.rows[#self.rows+1]=button
  end
  f.onOpen=function()G:Update()end
  WG:On('PLAYER_EQUIPMENT_CHANGED',function()if f:IsShown() then G:Update()end end)
  WG:On('BAG_UPDATE_DELAYED',function()if f:IsShown() then G:Update()end end)
  WG:On('GET_ITEM_INFO_RECEIVED',function()if f:IsShown() then G:Update()end end)
  for _,event in ipairs({'TRAIT_CONFIG_UPDATED','PLAYER_TALENT_UPDATE','ACTIVE_TALENT_GROUP_CHANGED'}) do
    WG:On(event,function()if f:IsShown() then G:Update();G:Refresh() end end)
  end
end
function G:Refresh()
  if not self.window then return end
  local profiles=self:GetProfiles()
  for i,row in ipairs(self.profileButtons or {}) do
    local option=profiles[i] or row.option
    row.option=option
    row.button.label:SetText((WG.db.gearProfile==option.value and '●  ' or '')..option.label)
  end
  if self.window:IsShown() then self:Update() end
end
