local WG=_G.WafflesGang
local AL={name='Auto Loot', modes={'off','all','quest','gear'}}
table.insert(WG.modules,AL)
local labels={off='Off',all='Everything',quest='Quest items only',gear='Gear only'}
local function cvar(value)
  if SetCVar then return pcall(SetCVar,'autoLootDefault',value) end
  if C_CVar and C_CVar.SetCVar then return pcall(C_CVar.SetCVar,'autoLootDefault',value) end
  return false
end
local function getCVar()
  if GetCVar then return GetCVar('autoLootDefault') end
  if C_CVar and C_CVar.GetCVar then return C_CVar.GetCVar('autoLootDefault') end
end
function AL:Mode(mode)
  if mode=='off' then WG.db.features.autoloot=false
  else WG.db.features.autoloot=true end
  WG.db.autoLootMode=mode
  WG:Refresh()
  WG:Say('Auto loot: '..(labels[mode] or mode))
end
function AL:ApplyCVar()
  if WG:Protected() then return end
  local enabled=WG:Enabled('autoloot')
  local mode=WG.db.autoLootMode
  if enabled then
    if WG.db.previousAutoLoot==nil then WG.db.previousAutoLoot=getCVar() or '0' end
    local required=(mode=='all') and '1' or '0'
    if self.lastMode~=required then
      local ok=cvar(required)
      if not ok and not self.warned then WG:Say('Client did not permit automatic loot CVar change.'); self.warned=true end
      self.lastMode=required
    end
  elseif WG.db.previousAutoLoot~=nil then
    cvar(WG.db.previousAutoLoot)
    WG.db.previousAutoLoot=nil
    self.lastMode=nil
  end
end
local function itemType(link)
  if not link then return nil end
  local _,_,_,equip,_,classID
  if C_Item and C_Item.GetItemInfoInstant then
    _,_,_,equip,_,classID=C_Item.GetItemInfoInstant(link)
  elseif GetItemInfoInstant then
    _,_,_,equip,_,classID=GetItemInfoInstant(link)
  end
  return equip,classID
end
function AL:LootOpened()
  if not WG:Enabled('autoloot') then return end
  local mode=WG.db.autoLootMode
  if mode=='off' or mode=='all' then return end
  if not GetNumLootItems or not LootSlot then return end
  local n=GetNumLootItems() or 0
  for i=n,1,-1 do
    local should=false
    if LootSlotIsCoin and LootSlotIsCoin(i) then should=true
    else
      local link=GetLootSlotLink and GetLootSlotLink(i)
      local equip,classID=itemType(link)
      if mode=='gear' then
        should=not not (equip and equip~='')
      elseif mode=='quest' then
        local questFlag
        if GetLootSlotInfo then
          local ok,icon,itemName,qty,currencyID,quality,locked,isQuestItem=pcall(GetLootSlotInfo,i)
          if ok then questFlag=isQuestItem end
        end
        should=(questFlag==true) or classID==12
      end
    end
    if should then
      local ok=pcall(LootSlot,i)
      if not ok and not self.warnedLoot then
        WG:Say('The client blocked selective automatic looting; use the normal loot window.')
        self.warnedLoot=true
      end
    end
  end
end
function AL:Init()
  local f=WG:Window('autoloot','Auto Loot',475,379)
  WG:Text(f,'PICK UP EXACTLY WHAT YOU WANT',24,-81,14,'accent')
  WG:Text(f,'Choose a mode. The main Settings list has a master on/off switch.',24,-106,11,'text',420)
  for i,mode in ipairs(self.modes) do
    WG:Button(f,labels[mode],25,-147-(i-1)*47,420,38,function() AL:Mode(mode) end)
  end
  self.status=WG:Text(f,'',24,-344,12,'accent')
  WG:On('LOOT_OPENED',function() AL:LootOpened() end)
  WG:On('PLAYER_REGEN_ENABLED',function() AL:ApplyCVar() end)
end
function AL:Refresh()
  self:ApplyCVar()
  if self.status then
    local name=WG:Enabled('autoloot') and (labels[WG.db.autoLootMode] or 'Everything') or 'Off'
    self.status:SetText('Current mode: '..name)
  end
end
