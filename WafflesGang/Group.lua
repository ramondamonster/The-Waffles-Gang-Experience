local WG=_G.WafflesGang
local G={name='Party / Group Tools'}; table.insert(WG.modules,G)
local function inGroup() return IsInGroup and IsInGroup() end
local function leader() return UnitIsGroupLeader and UnitIsGroupLeader('player') end
local function canInvite() return not inGroup() or leader() or (UnitIsGroupAssistant and UnitIsGroupAssistant('player')) end
local function targetName()
  if UnitExists and UnitExists('target') and UnitIsPlayer and UnitIsPlayer('target') and not (UnitIsUnit and UnitIsUnit('target','player')) then
    if GetUnitName then return GetUnitName('target',true) end
    return UnitName('target')
  end
end
local function action(label,fn)
  if WG:Protected() then WG:Say(label..' is unavailable during combat.'); return end
  WG:Safe(label,fn)
end
function G:FillTarget()
  if not self.inviteEdit then return end
  local name=targetName()
  if name and name~='' then self.inviteEdit:SetText(name); self.inviteEdit:HighlightText(0,0) end
end
function G:Invite()
  if not WG:Enabled('party') then return WG:Say('Enable Party Manager in Settings.') end
  local name=self.inviteEdit:GetText():match('^%s*(.-)%s*$')
  if name=='' then name=targetName() or '' end
  if name=='' then return WG:Say('Select a player or enter a character name.') end
  if not canInvite() then return WG:Say('Only the party leader or assistant can invite.') end
  action('Invite',function()
    if C_PartyInfo and C_PartyInfo.InviteUnit then C_PartyInfo.InviteUnit(name)
    elseif InviteUnit then InviteUnit(name)
    else WG:Say('This client has no supported invite API.') end
  end)
end
function G:UpdateParty()
  if not self.partyWindow then return end
  self:FillTarget()
  local names={}
  local count=(GetNumGroupMembers and GetNumGroupMembers()) or 0
  local raid=IsInRaid and IsInRaid()
  local pages=raid and math.max(1,math.ceil(count/5)) or 1
  self.page=math.min(math.max(self.page or 1,1),pages)
  if raid then
    local first=(self.page-1)*5+1
    for i=first,math.min(first+4,count) do
      names[#names+1]={index=i,name=(GetUnitName and GetUnitName('raid'..i,true)) or 'Unknown member'}
    end
  else
    names[1]={index=1,name=(GetUnitName and GetUnitName('player',true)) or 'You'}
    if inGroup() then
      for i=1,math.min(count-1,4) do
        names[#names+1]={index=i+1,name=(GetUnitName and GetUnitName('party'..i,true)) or 'Unknown member'}
      end
    end
  end
  if not inGroup() then self.partyStatus:SetText('SOLO  /  READY TO INVITE')
  else self.partyStatus:SetText((raid and 'RAID' or 'PARTY')..'  /  '..count..' MEMBERS') end
  for i,t in ipairs(self.partyRows) do
    local n=names[i]
    t:SetText(n and string.format('%02d   %s',n.index,n.name) or string.format('%02d   EMPTY SLOT',i))
  end
  if self.pageLabel then
    self.pageLabel:SetText(raid and ('PAGE '..self.page..' / '..pages) or 'PARTY ROSTER')
    if self.prev then self.prev:SetAlpha(raid and self.page>1 and 1 or .45) end
    if self.next then self.next:SetAlpha(raid and self.page<pages and 1 or .45) end
  end
end
local modes={
  {'Free for all',0,'freeforall'}, {'Round robin',1,'roundrobin'},
  {'Master looter',2,'master'}, {'Group loot',3,'group'},
  {'Need before greed',4,'needbeforegreed'}, {'Personal loot',5,'personalloot'},
}
function G:SetLoot(method,legacy)
  if not WG:Enabled('loot') then return WG:Say('Loot Manager is disabled.') end
  if not inGroup() or not leader() then return WG:Say('Only the group leader can change the loot method.') end
  action('Loot method',function()
    if C_PartyInfo and C_PartyInfo.IsLootMethodAvailable then
      local ok,available=pcall(C_PartyInfo.IsLootMethodAvailable,method)
      if ok and available==false then WG:Say('This loot method is unavailable for the current group.'); return end
    end
    if C_PartyInfo and C_PartyInfo.SetLootMethod then
      local master=(method==2 and ((GetUnitName and GetUnitName('player',true)) or UnitName('player'))) or nil
      local ok,result=pcall(C_PartyInfo.SetLootMethod,method,master)
      if not ok or result==false then WG:Say('Loot method rejected by this game/group.')
      else WG:Say('Loot method requested.') end
    elseif SetLootMethod then
      if legacy=='master' then SetLootMethod(legacy,UnitName('player')) else SetLootMethod(legacy) end
    else WG:Say('No loot method API is available.') end
  end)
end
function G:Init()
  local party=WG:Window('party','Party Manager',510,484)
  self.partyWindow=party
  WG:Text(party,'INVITE A PLAYER',23,-80,14,'accent')
  WG:Text(party,'Select another player: their name fills automatically.',23,-104,11,'text')
  local edit=CreateFrame('EditBox',nil,party,'InputBoxTemplate')
  edit:SetSize(280,30); edit:SetPoint('TOPLEFT',party,'TOPLEFT',35,-135)
  edit:SetAutoFocus(false); edit:SetMaxLetters(80)
  edit:SetScript('OnEnterPressed',function(self) self:ClearFocus(); G:Invite() end)
  edit:SetScript('OnEscapePressed',function(self) self:ClearFocus() end)
  self.inviteEdit=edit
  WG:Button(party,'INVITE',336,-134,147,33,function() self:Invite() end)
  WG:Text(party,'YOUR GROUP',23,-192,14,'accent')
  self.partyStatus=WG:Text(party,'',298,-193,11,'text')
  self.partyRows={}
  for i=1,5 do
    local row=CreateFrame('Frame',nil,party)
    row:SetSize(458,30); row:SetPoint('TOPLEFT',party,'TOPLEFT',24,-220-(i-1)*34)
    WG:Surface(row,i%2==0 and 'panel' or 'bg','edge')
    self.partyRows[i]=WG:Text(row,'',14,-7,12,'text')
  end
  self.pageLabel=WG:Text(party,'PARTY ROSTER',23,-392,11,'text')
  self.prev=WG:Button(party,'PREVIOUS',261,-386,105,27,function()
    if self.page and self.page>1 then self.page=self.page-1;self:UpdateParty() end
  end)
  self.next=WG:Button(party,'NEXT',375,-386,105,27,function()
    self.page=(self.page or 1)+1;self:UpdateParty()
  end)
  WG:Button(party,'LOOT METHODS',24,-426,217,35,function() WG:Open('loot') end)
  WG:Button(party,'GROUP TOOLS',256,-426,228,35,function() WG:Open('group') end)
  party.onOpen=function() G:UpdateParty() end
  local loot=WG:Window('loot','Loot Methods',480,364)
  WG:Text(loot,'GROUP LOOT',24,-82,14,'accent')
  WG:Text(loot,'Leader only • Group and client restrictions apply.',24,-105,11,'text')
  for i,m in ipairs(modes) do
    local col=(i-1)%2; local row=math.floor((i-1)/2)
    WG:Button(loot,m[1],24+col*224,-142-row*53,207,44,function() self:SetLoot(m[2],m[3]) end)
  end
  self.lootCurrent=WG:Text(loot,'CURRENT  /  NOT IN A GROUP',24,-314,11,'accent')
  WG:Text(loot,'Method availability depends on your group and game client.',24,-341,10,'text')
  loot.onOpen=function() G:UpdateLoot() end
  local group=WG:Window('group','Group Tools',480,343)
  WG:Text(group,'GROUP CONTROLS',24,-83,14,'accent')
  local actions={
    {'Invite Target',function() self:FillTarget(); WG:Open('party') end},
    {'Ready Check',function()
      if not inGroup() or not canInvite() then WG:Say('Leader/assistant and group required.'); return end
      if C_PartyInfo and C_PartyInfo.DoReadyCheck then C_PartyInfo.DoReadyCheck()
      elseif DoReadyCheck then DoReadyCheck() end
    end},
    {'Role Poll',function()
      if not inGroup() or not canInvite() then WG:Say('Leader/assistant and group required.'); return end
      if C_PartyInfo and C_PartyInfo.InitiateRolePoll then C_PartyInfo.InitiateRolePoll()
      elseif InitiateRolePoll then InitiateRolePoll() end
    end},
    {'Convert to Raid',function()
      if not inGroup() or not leader() then WG:Say('Party leader required.'); return end
      if C_PartyInfo and C_PartyInfo.ConvertToRaid then C_PartyInfo.ConvertToRaid()
      elseif ConvertToRaid then ConvertToRaid() end
    end},
    {'Leave Group',function()
      if not inGroup() then WG:Say('You are not grouped.'); return end
      if C_PartyInfo and C_PartyInfo.LeaveParty then C_PartyInfo.LeaveParty()
      elseif LeaveParty then LeaveParty() end
    end},
  }
  for i,cmd in ipairs(actions) do
    local col=(i-1)%2; local row=math.floor((i-1)/2)
    WG:Button(group,cmd[1],24+col*225,-132-row*56,207,43,function() action(cmd[1],cmd[2]) end)
  end
  WG:On('PLAYER_TARGET_CHANGED',function() G:FillTarget() end)
  WG:On('GROUP_ROSTER_UPDATE',function() G:UpdateParty();G:UpdateLoot() end)
  WG:On('PARTY_LOOT_METHOD_CHANGED',function() G:UpdateLoot() end)
end
function G:UpdateLoot()
  if not self.lootCurrent then return end
  if not inGroup() then self.lootCurrent:SetText('CURRENT  /  NOT IN A GROUP');return end
  local method
  if C_PartyInfo and C_PartyInfo.GetLootMethod then
    local ok,val=pcall(C_PartyInfo.GetLootMethod)
    if ok then method=val end
  end
  local selected='UNKNOWN'
  for _,row in ipairs(modes) do if row[2]==method then selected=string.upper(row[1]) end end
  self.lootCurrent:SetText('CURRENT  /  '..selected)
end
function G:Refresh()
  self:UpdateLoot()
  if WG.windows.party and not WG:Enabled('party') then WG.windows.party:Hide() end
  if WG.windows.loot and not WG:Enabled('loot') then WG.windows.loot:Hide() end
  if WG.windows.group and not WG:Enabled('grouptools') then WG.windows.group:Hide() end
end
