-- Waffles Gang | non-destructive quest choice advisor.
local WG=_G.WafflesGang
local R={name='Quest Reward Advisor',rows={}}
WG.rewards=R
table.insert(WG.modules,R)
local function info(link)
  local f=C_Item and C_Item.GetItemInfo or GetItemInfo
  if not f or not link then return end
  local ok,name,_,_,_,_,_,_,_,_,_,sell=pcall(f,link)
  if ok and name then return name,type(sell)=='number' and sell or nil end
end
local function fmtMoney(copper)
  if type(copper)~='number' then return 'price unavailable' end
  return ('%dg %ds %dc'):format(math.floor(copper/10000),math.floor(copper/100)%100,copper%100)
end
function R:Choices()
  local list={}
  local count=GetNumQuestChoices and GetNumQuestChoices() or 0
  if type(count)~='number' then return list end
  for i=1,math.min(count,20) do
    local itemName,_,quantity,_,usable,itemID
    if GetQuestItemInfo then
      local ok,n,_,q,_,u,id=pcall(GetQuestItemInfo,'choice',i)
      if ok then itemName=n;quantity=q;usable=u;itemID=id end
    end
    local link
    if GetQuestItemLink then
      local ok,result=pcall(GetQuestItemLink,'choice',i)
      if ok then link=result end
    end
    local resolved,value=info(link)
    local total=value and value*math.max(1,type(quantity)=='number' and quantity or 1) or nil
    local c=WG.gear and WG.gear:CompareLink(link) or nil
    list[#list+1]={index=i,name=itemName or resolved or ('Reward '..i),value=total,
      upgrade=c and c.eligible and c.percent or nil,newSlot=c and c.newSlot or false,usable=usable,link=link,itemID=itemID}
  end
  return list
end
function R:Best(list)
  local profitable,upgrade
  for _,v in ipairs(list) do
    if v.value and (not profitable or v.value>profitable.value) then profitable=v end
    if (v.newSlot or (v.upgrade and v.upgrade>0)) and (not upgrade or
        (v.newSlot and not upgrade.newSlot) or
        (not v.newSlot and not upgrade.newSlot and v.upgrade>(upgrade.upgrade or 0))) then upgrade=v end
  end
  local choice=profitable
  local preference=WG.db.rewardPreference or 'Upgrade or Value'
  if preference=='Upgrade or Value' and upgrade and (upgrade.newSlot or (upgrade.upgrade and upgrade.upgrade>=3)) then choice=upgrade end
  return choice,profitable,upgrade
end
function R:Update()
  if not self.window then return end
  local list=self:Choices()
  self.choices=list
  local best,profit,upgrade=self:Best(list)
  self.best=best
  if #list==0 then
    self.header:SetText('Open a completed quest with reward choices to compare them.')
  else
    self.header:SetText(('%d choices  /  preference: %s'):format(#list,WG.db.rewardPreference or 'Upgrade or Value'))
  end
  self.note:SetText(best and ('SUGGESTED: '..best.name..'  •  '..(best==upgrade and 'estimated gear upgrade' or 'vendor value')) or
    'No supported reward data. Make your choice in the original quest window.')
  for i,row in ipairs(self.rows) do
    local reward=list[i]
    if reward then
      local v=reward.value and fmtMoney(reward.value) or 'vendor value unknown'
      local up=reward.newSlot and '  •  fills empty slot' or
        (reward.upgrade and ('  •  %+.1f%% model score'):format(reward.upgrade) or '')
      row.label:SetText((best==reward and '★  ' or '    ')..reward.name..'  /  '..v..up)
      row:Show()
    else row:Hide() end
  end
end
function R:Init()
  local f=WG:Window('rewards','Quest Reward Advisor',729,504)
  self.window=f
  WG:Text(f,'CHOOSE UPGRADES OR SELL FOR MORE',22,-81,14,'accent')
  self.header=WG:Text(f,'',22,-108,11,'text',685)
  WG:Divider(f,-129,676,22)
  WG:Text(f,'RECOMMENDATION MODE',22,-144,12,'accent')
  WG:Button(f,'UPGRADE IF USEFUL',22,-172,219,36,function()
    WG.db.rewardPreference='Upgrade or Value';R:Update()
  end)
  WG:Button(f,'HIGHEST SELL VALUE',249,-172,214,36,function()
    WG.db.rewardPreference='Highest Value';R:Update()
  end)
  WG:Button(f,'RECHECK',471,-172,234,36,function()R:Update()end)
  self.note=WG:Text(f,'',22,-217,12,'accent',682)
  self.rows={}
  for i=1,5 do
    local row=WG:Button(f,'',22,-251-(i-1)*39,681,34,function()
      WG:Say('Select the desired reward in Blizzard\'s quest window; Waffles Gang does not claim it for you.')
    end)
    row.label:SetJustifyH('LEFT');row.label:ClearAllPoints()
    row.label:SetPoint('LEFT',row,'LEFT',10,0);row.label:SetWidth(655)
    self.rows[i]=row
  end
  WG:Text(f,'Estimated upgrade is stat-weighted, not simulated DPS. Missing price data is shown as unknown.',22,-454,10,'text',681)
  f.onOpen=function() R:Update() end
  WG:On('QUEST_COMPLETE',function()
    if WG:Enabled('questrewardadvisor') and (GetNumQuestChoices and (GetNumQuestChoices() or 0)>1) then
      WG:Open('rewards')
    end
  end)
  WG:On('GET_ITEM_INFO_RECEIVED',function()if f:IsShown() then R:Update()end end)
end
function R:Refresh()
  if self.window and not WG:Enabled('questrewardadvisor') then self.window:Hide() end
end
