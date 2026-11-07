-- Waffles Gang | Guild Manager
-- Extends Rain's original guild window without touching HUD positions or art.
-- Guild invites, party invites and guild chat are only attempted on a user click.
local WG=_G.WafflesGang
local GM={name='Guild Manager',roster={},page=1,pageSize=11,query='',onlineOnly=false,sortMode=1}
table.insert(WG.modules,GM)
WG.guildManager=GM

local sorts={'ONLINE FIRST','NAME A-Z','HIGHEST LEVEL','GUILD RANK'}
local function guilded() return type(IsInGuild)=='function' and IsInGuild() end
local function shortName(s) return type(s)=='string' and (s:gsub('%-.+$','')) or '' end
local function selectedPlayer()
  if UnitExists and UnitExists('target') and UnitIsPlayer and UnitIsPlayer('target') and not (UnitIsUnit and UnitIsUnit('player','target')) then
    return (GetUnitName and GetUnitName('target',true)) or (UnitName and UnitName('target'))
  end
end
local function inviteAllowed()
  local checker=(C_GuildInfo and C_GuildInfo.CanGuildInvite) or CanGuildInvite
  if type(checker)=='function' then
    local ok,allowed=pcall(checker)
    if ok then return allowed~=false end
  end
  return true -- Unknown locally; the WoW server is still authoritative.
end
local function requestGuildRoster()
  if C_GuildInfo and type(C_GuildInfo.GuildRoster)=='function' then return C_GuildInfo.GuildRoster() end
  if type(GuildRoster)=='function' then return GuildRoster() end
end
local function guildName()
  if not guilded() then return nil end
  return GetGuildInfo and GetGuildInfo('player')
end
local function motd()
  if C_GuildInfo and C_GuildInfo.GetMOTD then
    local ok,value=pcall(C_GuildInfo.GetMOTD)
    if ok then return value end
  end
  if GetGuildRosterMOTD then
    local ok,value=pcall(GetGuildRosterMOTD)
    if ok then return value end
  end
  return nil
end
local function GuildInput(parent,width,height)
  local e=CreateFrame('EditBox',nil,parent)
  e:SetSize(width,height)
  e:SetFontObject(ChatFontNormal or GameFontHighlight)
  e:SetTextColor(.94,.96,.99)
  e:SetAutoFocus(false)
  e:SetTextInsets(9,9,1,1)
  WG:Surface(e,'guildRowOdd','guildBorder')
  return e
end
local function RowFont(parent,x,width,align)
  local f=parent:CreateFontString(nil,'OVERLAY','GameFontHighlightSmall')
  f:SetFont(STANDARD_TEXT_FONT or 'Fonts\\FRIZQT__.TTF',11,'OUTLINE')
  f:SetPoint('LEFT',parent,'LEFT',x,0)
  f:SetWidth(width);f:SetJustifyH(align or 'LEFT')
  if f.SetWordWrap then f:SetWordWrap(false) end
  f:SetTextColor(.94,.96,.99)
  return f
end
function GM:RequestRoster(force)
  if not guilded() then return end
  local now=GetTime and GetTime() or 0
  -- WoW throttles roster requests to roughly 10s. Even when force is requested,
  -- don't fire a new server request before the throttle expires.
  if not self.lastRequest or now-self.lastRequest>=11 then
    self.lastRequest=now
    self.pending=true
    WG:Safe('Guild roster request',requestGuildRoster)
  elseif force then
    WG:Say('Roster refresh already requested. Waiting for the guild server.')
  end
end
function GM:ReadRoster()
  local list={}
  if not guilded() or type(GetNumGuildMembers)~='function' or type(GetGuildRosterInfo)~='function' then
    self.roster=list;return
  end
  local ok,total=pcall(GetNumGuildMembers)
  if not ok or type(total)~='number' then return end
  for index=1,math.min(total,1000) do
    -- The 11th return is the locale-independent class token, not the 5th.
    local good,name,rank,rankIndex,level,classDisplay,zone,publicNote,_,online,_,class=pcall(GetGuildRosterInfo,index)
    if good and type(name)=='string' and name~='' then
      list[#list+1]={name=name,rank=rank or 'Member',rankIndex=rankIndex or 99,
        level=type(level)=='number' and level or 0,zone=zone or '',note=publicNote or '',
        online=online==true,class=class or '',classDisplay=classDisplay or '',index=index}
    end
  end
  self.roster=list
end
function GM:FilteredRoster()
  local shown={}
  local query=(self.query or ''):lower()
  for _,m in ipairs(self.roster) do
    local matching=query==''
    if not matching then
      for _,field in ipairs({m.name,m.rank,m.class,m.classDisplay,m.zone,m.note}) do
        if tostring(field or ''):lower():find(query,1,true) then matching=true;break end
      end
    end
    if matching and (not self.onlineOnly or m.online) then shown[#shown+1]=m end
  end
  local mode=self.sortMode
  table.sort(shown,function(a,b)
    if mode==1 and a.online~=b.online then return a.online end
    if mode==3 and a.level~=b.level then return a.level>b.level end
    if mode==4 and a.rankIndex~=b.rankIndex then return a.rankIndex<b.rankIndex end
    if mode==1 and a.rankIndex~=b.rankIndex then return a.rankIndex<b.rankIndex end
    return a.name:lower()<b.name:lower()
  end)
  return shown
end
function GM:GetSelected()
  if not self.selectedName then return nil end
  for _,m in ipairs(self.roster) do if m.name==self.selectedName then return m end end
end
function GM:SelectedOrInput()
  local person=(self.invite and self.invite:GetText() or ''):match('^%s*(.-)%s*$')
  return person~='' and person or selectedPlayer() or ''
end
function GM:FillTarget()
  if not self.invite then return end
  local target=selectedPlayer()
  if target and target~='' then self.invite:SetText(target) end
end
function GM:Invite()
  if WG:Protected() then return WG:Say('Guild invitations are unavailable during combat.') end
  if not guilded() then return WG:Say('You must belong to a guild to invite players.') end
  if not inviteAllowed() then return WG:Say('Your guild rank cannot invite players.') end
  local person=self:SelectedOrInput()
  if person=='' then return WG:Say('Select a player or enter a name to invite.') end
  local invite=(C_GuildInfo and C_GuildInfo.Invite) or GuildInvite
  if type(invite)~='function' then return WG:Say('Guild invitation API is unavailable.') end
  local ok=WG:Safe('Guild invite',function() invite(person) end)
  if ok then
    WG.db.guildInviteAttempts=WG.db.guildInviteAttempts or {}
    table.insert(WG.db.guildInviteAttempts,1,{name=person,at=time and time() or 0, guild=(guildName() or '')..'@'..((GetRealmName and GetRealmName()) or 'Realm')})
    if #WG.db.guildInviteAttempts>20 then table.remove(WG.db.guildInviteAttempts) end
    WG:Say('Guild invite requested for '..person..'. The player/server determines acceptance.')
  end
end
function GM:InviteParty()
  if WG:Protected() then return WG:Say('Party invitations are unavailable during combat.') end
  local who=self:SelectedOrInput()
  if who=='' then return WG:Say('Choose a guild member or target a player first.') end
  if IsInGroup and IsInGroup() and not ((UnitIsGroupLeader and UnitIsGroupLeader('player')) or
    (UnitIsGroupAssistant and UnitIsGroupAssistant('player'))) then
    return WG:Say('Group leader or assistant permission is required.')
  end
  local invite=(C_PartyInfo and C_PartyInfo.InviteUnit) or InviteUnit
  if type(invite)~='function' then return WG:Say('Party invite API unavailable.') end
  if WG:Safe('Invite to party',function() invite(who) end) then WG:Say('Party invite requested for '..who..'.') end
end
function GM:Whisper()
  local who=self:SelectedOrInput()
  if who=='' then return WG:Say('Select a guild member first.') end
  if type(ChatFrame_OpenChat)=='function' then ChatFrame_OpenChat('/w '..who..' ')
  else WG:Say('Use /w '..who..' to whisper.') end
end
function GM:SendGuildMessage()
  if not guilded() then return WG:Say('You are not in a guild.') end
  local message=self.chat:GetText() or ''
  if not message:match('%S') then return end
  if #message>255 then message=message:sub(1,255) end
  if type(SendChatMessage)~='function' then return WG:Say('Guild chat API unavailable.') end
  if WG:Safe('Guild chat',function() SendChatMessage(message,'GUILD') end) then
    self.chat:SetText('');self.chat:ClearFocus()
  end
end
function GM:Update()
  if not self.window then return end
  local name=guildName()
  local inGuild=not not name
  self.guildTitle:SetText(inGuild and string.upper(name) or 'NO GUILD JOINED')
  local notice=motd() or ''
  self.motdText:SetText(notice~='' and notice or 'No guild message of the day is available.')
  self:ReadRoster()
  local filtered=self:FilteredRoster()
  local online=0
  for _,member in ipairs(self.roster) do if member.online then online=online+1 end end
  local status=inGuild and ('%d MEMBERS  /  %d ONLINE'):format(#self.roster,online) or 'JOIN A GUILD TO USE THIS WINDOW'
  if inGuild and #self.roster==0 then status='ROSTER LOADING  /  CLICK REFRESH IF NEEDED' end
  self.status:SetText(status)
  local pages=math.max(1,math.ceil(#filtered/self.pageSize))
  self.page=math.min(math.max(1,self.page or 1),pages)
  self.pages:SetText(('PAGE %d / %d   •   %d RESULTS'):format(self.page,pages,#filtered))
  self.onlineButton.label:SetText(self.onlineOnly and 'ONLINE ONLY' or 'ALL MEMBERS')
  self.sortButton.label:SetText('SORT: '..sorts[self.sortMode])
  for i,row in ipairs(self.rows) do
    local item=filtered[(self.page-1)*self.pageSize+i]
    row.entry=item
    if item then
      row.name:SetText(shortName(item.name))
      row.level:SetText(tostring(item.level))
      row.rank:SetText(item.rank)
      row.status:SetText(item.online and 'ONLINE' or 'OFFLINE')
      local classKey=tostring(item.class or ''):upper():gsub('%s','')
      local tint=RAID_CLASS_COLORS and RAID_CLASS_COLORS[classKey]
      if tint then row.name:SetTextColor(tint.r,tint.g,tint.b)
      else row.name:SetTextColor(.95,.97,1) end
      row.level:SetTextColor(.83,.88,.93)
      row.rank:SetTextColor(.91,.94,.98)
      row.status:SetTextColor(item.online and .39 or .59,item.online and .94 or .65,item.online and .62 or .72)
      row.selected=GM.selectedName==item.name
      row.bar:SetShown(row.selected)
      local bg=row.selected and {.18,.245,.275} or row.odd and WG:Color('guildRowOdd') or WG:Color('guildRowEven')
      row.face.bg:SetColorTexture(WG.unpack(bg))
      row:SetAlpha(item.online and 1 or .78)
      row:Show()
    else row:Hide() end
  end
  local selected=self:GetSelected()
  if selected then
    self.selection:SetText(('SELECTED: %s  •  LVL %d %s  •  %s'):format(shortName(selected.name),selected.level,selected.classDisplay,selected.rank))
    self.memberDetail:SetText(('ZONE: %s   |   NOTE: %s'):format(selected.zone~='' and selected.zone or 'Unknown',selected.note~='' and selected.note or 'None'))
  else
    self.selection:SetText('SELECT A GUILD MEMBER TO WHISPER OR INVITE')
    self.memberDetail:SetText('Search by name, class, rank, zone, or public note.')
  end
  self.chat:SetEnabled(inGuild)
  self.invite:SetEnabled(inGuild)
end
function GM:Init()
  local f=WG:Window('guild','Guild Manager',792,700)
  self.window=f
  self.guildTitle=WG:Text(f,'GUILD MANAGER',23,-78,17,'accent',480)
  self.status=WG:Text(f,'',25,-103,11,'text',420)
  WG:Button(f,'REFRESH ROSTER',618,-82,149,34,function()self:RequestRoster(true);self:Update()end)
  WG:Divider(f,-130,742,23)
  WG:Text(f,'MEMBERS',25,-146,13,'accent')
  local search=GuildInput(f,211,28)
  search:SetPoint('TOPLEFT',f,'TOPLEFT',24,-170)
  search:SetScript('OnTextChanged',function(self)
    GM.query=(self:GetText() or ''):lower()
    GM.page=1;GM:Update()
  end)
  search:SetScript('OnEscapePressed',function(self) self:ClearFocus() end)
  self.search=search
  self.sortButton=WG:Button(f,'SORT: ONLINE FIRST',243,-172,149,27,function()
    GM.sortMode=(GM.sortMode % #sorts)+1;GM.page=1;GM:Update()
  end)
  self.onlineButton=WG:Button(f,'ALL MEMBERS',398,-172,100,27,function()
    GM.onlineOnly=not GM.onlineOnly;GM.page=1;GM:Update()
  end)
  local tableHeader=CreateFrame('Frame',nil,f)
  tableHeader:SetSize(474,22)
  tableHeader:SetPoint('TOPLEFT',f,'TOPLEFT',24,-201)
  WG:Surface(tableHeader,'guildHeader','guildBorder')
  local nameH=RowFont(tableHeader,9,169);nameH:SetText('NAME')
  local levelH=RowFont(tableHeader,188,37);levelH:SetText('LVL')
  local rankH=RowFont(tableHeader,232,128);rankH:SetText('RANK')
  local statusH=RowFont(tableHeader,363,98);statusH:SetText('STATUS')
  self.rows={}
  for i=1,self.pageSize do
    local row=CreateFrame('Button',nil,f)
    row:SetSize(474,25)
    row:SetPoint('TOPLEFT',f,'TOPLEFT',24,-226-(i-1)*26)
    row.odd=i%2==1
    row.face=WG:Surface(row,row.odd and 'guildRowOdd' or 'guildRowEven','guildBorder')
    row.name=RowFont(row,9,169)
    row.level=RowFont(row,188,37)
    row.rank=RowFont(row,232,128)
    row.status=RowFont(row,363,104)
    local stripe=row:CreateTexture(nil,'OVERLAY')
    stripe:SetSize(3,21);stripe:SetPoint('LEFT',row,'LEFT',1,0)
    local function accentStripe() stripe:SetColorTexture(WG.unpack(WG:Color('accent'))) end
    WG.surfaces[#WG.surfaces+1]={repaint=accentStripe}
    accentStripe()
    row.bar=stripe
    row:SetScript('OnClick',function()
      if row.entry then
        GM.selectedName=row.entry.name
        GM.invite:SetText(row.entry.name)
        GM.invite:ClearFocus()
        GM:Update()
      end
    end)
    row:SetScript('OnEnter',function()
      row.face.bg:SetColorTexture(.20,.24,.28)
      row.bar:Show()
    end)
    row:SetScript('OnLeave',function()
      local c=row.selected and {.18,.245,.275} or WG:Color(row.odd and 'guildRowOdd' or 'guildRowEven')
      row.face.bg:SetColorTexture(WG.unpack(c))
      row.bar:SetShown(row.selected)
    end)
    self.rows[i]=row
  end
  self.pages=WG:Text(f,'PAGE 1 / 1',26,-521,11,'text',248)
  WG:Button(f,'PREVIOUS',285,-517,103,30,function()self.page=math.max(1,self.page-1);self:Update()end)
  WG:Button(f,'NEXT',394,-517,104,30,function()self.page=self.page+1;self:Update()end)
  self.selection=WG:Text(f,'SELECT A MEMBER',25,-560,11,'accent',477)
  self.memberDetail=WG:Text(f,'',25,-582,10,'text',473)
  WG:Button(f,'GUILD EVENT BOARD',24,-628,225,36,function()WG:Open('guildboard')end)
  WG:Button(f,'RECRUITMENT TOOLS',260,-628,238,36,function()WG:Open('recruitment')end)

  local side=CreateFrame('Frame',nil,f)
  side:SetSize(245,518);side:SetPoint('TOPLEFT',f,'TOPLEFT',521,-139)
  WG:Surface(side,'guildPanel','guildBorder')
  WG:Text(side,'GUILD INVITE',15,-13,13,'accent')
  local invite=GuildInput(side,210,29)
  invite:SetPoint('TOPLEFT',side,'TOPLEFT',18,-43)
  invite:SetMaxLetters(80)
  invite:SetScript('OnEnterPressed',function(self)self:ClearFocus();GM:Invite()end)
  invite:SetScript('OnEscapePressed',function(self)self:ClearFocus()end)
  self.invite=invite
  WG:Button(side,'INVITE',16,-89,101,31,function()GM:Invite()end)
  WG:Button(side,'USE TARGET',126,-89,104,31,function()GM:FillTarget()end)
  WG:Divider(side,-135,215,15)
  WG:Text(side,'MESSAGE OF THE DAY',15,-151,12,'accent',215)
  self.motdText=WG:Text(side,'',16,-177,11,'text',211)
  WG:Divider(side,-258,215,15)
  WG:Text(side,'GUILD CHAT',15,-274,12,'accent',215)
  local chat=GuildInput(side,210,29)
  chat:SetPoint('TOPLEFT',side,'TOPLEFT',18,-307)
  chat:SetMaxLetters(255)
  chat:SetScript('OnEnterPressed',function(self)self:ClearFocus();GM:SendGuildMessage()end)
  chat:SetScript('OnEscapePressed',function(self)self:ClearFocus()end)
  self.chat=chat
  WG:Button(side,'SEND TO /G',15,-350,214,35,function()GM:SendGuildMessage()end)
  WG:Button(side,'WHISPER MEMBER',15,-390,214,31,function()GM:Whisper()end)
  WG:Button(side,'INVITE TO PARTY',15,-426,214,31,function()GM:InviteParty()end)
  WG:Button(side,'GUILD PROFESSIONS',15,-463,214,35,function()WG:Open('professions')end)
  f.onOpen=function()GM:RequestRoster();GM:FillTarget();GM:Update()end
  WG:On('GUILD_ROSTER_UPDATE',function() GM.pending=false;GM:Update() end)
  WG:On('PLAYER_GUILD_UPDATE',function()GM.lastRequest=nil;GM:RequestRoster();GM:Update()end)
  WG:On('GUILD_MOTD',function()GM:Update()end)
  WG:On('PLAYER_TARGET_CHANGED',function()GM:FillTarget()end)
end
function GM:Refresh()
  if self.window and not WG:Enabled('guild') then self.window:Hide() end
  if self.window and self.window:IsShown() then self:Update() end
end
