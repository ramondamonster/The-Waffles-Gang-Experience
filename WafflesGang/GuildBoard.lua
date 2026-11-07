-- Waffles Gang | Discord Events (read-only guild board)
-- Discord scheduled events are published by Waffles Bot to deputywaffles.com.
-- A local companion populates EventFeed.lua; compatible guildmates may receive
-- short event listings over the Blizzard GUILD addon channel. No HTTP calls,
-- automated guild chat, calendar mutations, or auto-invites happen here.
local WG=_G.WafflesGang
local B={name='Discord Guild Events',page=1,pageSize=6,selected=nil,prefix='WGDE1',lastRequest=0,lastReply=0}
table.insert(WG.modules,B)
WG.guildBoard=B

local function guildName()
  if not (IsInGuild and IsInGuild()) then return nil end
  return GetGuildInfo and GetGuildInfo('player')
end
local function guildKey()
  local name=guildName()
  if not name then return nil end
  return name..'@'..((GetRealmName and GetRealmName()) or 'Realm')
end
local function playerName()
  return (GetUnitName and GetUnitName('player',true)) or (UnitName and UnitName('player')) or 'Player'
end
local function clean(value,limit)
  local s=type(value)=='string' and value or ''
  return (s:gsub('[|\r\n\t]',' '):gsub('[%c]',''):sub(1,limit or 100))
end
-- Most WoW fonts do not contain modern emoji glyphs. Strip their UTF-8
-- byte sequences in the displayed event copy, including copies synchronized
-- before the companion was updated. Source files and event IDs are unchanged.
local function eventText(value)
  local s=type(value)=='string' and value or ''
  s=s:gsub('[\240-\244][\128-\191][\128-\191][\128-\191]',' ')
  s=s:gsub('\226[\152-\155][\128-\191]',' ')
  s=s:gsub('\239\184[\142\143]','')
  s=s:gsub('\226\128\141','')
  return (s:gsub('%s+',' '):gsub('^%s+',''):gsub('%s+$',''))
end
local function integer(n)
  n=tonumber(n)
  if not n or n~=n then return 0 end
  return math.floor(n)
end
local function normalEvent(e)
  if type(e)~='table' then return nil end
  local id=clean(tostring(e.id or ''),32)
  local title=clean(eventText(e.title),80)
  local starts=integer(e.starts)
  if id=='' or title=='' or starts<1577836800 or starts>4102444800 then return nil end
  return {
    id=id,title=title,starts=starts,ends=integer(e.ends),
    description=clean(eventText(e.description),450),location=clean(eventText(e.location),90),
    url=clean(e.url,180),rsvp=math.max(0,math.min(99999,integer(e.rsvp))),
  }
end
local function localFeed()
  local feed=_G.WafflesGangDiscordEvents
  if type(feed)~='table' or integer(feed.schema)~=1 or type(feed.events)~='table' then return nil end
  return feed
end
function B:SharedFeed()
  local key=guildKey()
  if not key or not WG.db then return nil end
  WG.db.discordGuildFeeds=WG.db.discordGuildFeeds or {}
  local feed=WG.db.discordGuildFeeds[key]
  if type(feed)~='table' or type(feed.events)~='table' then return nil end
  if integer(feed.receivedAt)<(time and time() or 0)-86400 then return nil end
  return feed
end
function B:Feed()
  local localData=localFeed()
  local shared=self:SharedFeed()
  if localData and integer(localData.syncedAt)>0 then
    return localData,'WEBSITE COPY',true
  end
  if shared then return shared,'FROM GUILD MEMBER (UNVERIFIED)',false end
  return {events={},syncedAt=0},'NOT SYNCED',false
end
function B:Events()
  local feed,source,verified=self:Feed()
  local events={}
  local now=time and time() or 0
  for _,raw in ipairs(feed.events or {}) do
    local e=normalEvent(raw)
    if e and (e.ends>0 and e.ends or e.starts)>now-7200 then events[#events+1]=e end
    if #events>=30 then break end
  end
  table.sort(events,function(a,b) if a.starts~=b.starts then return a.starts<b.starts end return a.id<b.id end)
  return events,source,feed,verified
end
local function whenText(stamp)
  if not stamp or stamp<=0 then return 'DATE NOT AVAILABLE' end
  if type(date)=='function' then
    local ok,result=pcall(date,'%a %b %d  %I:%M %p',stamp)
    if ok and type(result)=='string' then return result end
  end
  return tostring(stamp)..' (UNIX TIME)'
end
function B:Selected(events)
  for _,e in ipairs(events or {}) do if e.id==self.selected then return e end end
end
function B:Select(e)
  self.selected=e and e.id or nil
  self:Update()
end
function B:Update()
  if not self.window then return end
  local events,source,feed=self:Events()
  local g=guildName()
  self.guildTitle:SetText(g and ('GUILD: '..clean(g,50)) or 'DISCORD COMMUNITY EVENTS')
  local sync=integer(feed.syncedAt)
  local age=sync>0 and ('FEED UPDATED '..whenText(sync)) or 'NO WEBSITE EVENT FILE LOADED'
  self.summary:SetText(source..'  |  '..#events..' UPCOMING  |  '..age)
  local pages=math.max(1,math.ceil(#events/self.pageSize))
  self.page=math.max(1,math.min(self.page,pages))
  self.pageLabel:SetText(('PAGE %d / %d'):format(self.page,pages))
  for i,row in ipairs(self.rows) do
    local event=events[(self.page-1)*self.pageSize+i]
    row.entry=event
    if event then
      row.label:SetText(clean(event.title,43)..'\n'..whenText(event.starts))
      row:Show()
      row.face.bg:SetColorTexture(WG.unpack(self.selected==event.id and {.18,.245,.275} or WG:Color(i%2==0 and 'guildRowEven' or 'guildRowOdd')))
    else row:Hide() end
  end
  local chosen=self:Selected(events)
  if not chosen then
    self.eventTitle:SetText('SELECT AN EVENT')
    self.eventWhen:SetText(#events==0 and 'No upcoming events in the current feed.' or 'Choose an event from the list.')
    self.eventLocation:SetText('')
    self.eventRsvp:SetText('')
    self.eventNotes:SetText('')
    self.eventLink:SetText('')
    self.selected=nil
  else
    self.eventTitle:SetText(chosen.title)
    self.eventWhen:SetText(whenText(chosen.starts)..'  (YOUR PC TIME)')
    self.eventLocation:SetText(chosen.location~='' and ('LOCATION: '..chosen.location) or 'LOCATION: SEE DISCORD')
    self.eventRsvp:SetText('DISCORD INTERESTED: '..tostring(chosen.rsvp))
    self.eventNotes:SetText(chosen.description~='' and chosen.description or 'Event details are available in Discord.')
    self.eventLink:SetText(chosen.url~='' and chosen.url or 'NO EVENT URL IN FEED')
  end
end
function B:CopyLink()
  local chosen=self:Selected(self:Events())
  if not chosen or chosen.url=='' then return WG:Say('Select an event with a Discord link first.') end
  if type(ChatFrame_OpenChat)=='function' then
    ChatFrame_OpenChat(chosen.url)
    WG:Say('Event link placed in chat edit box. Copy it and press Escape; it was NOT sent.')
  else WG:Say('Event link: '..chosen.url) end
end
local function sendAddon(msg)
  if not B.registered or type(msg)~='string' or #msg>230 then return false end
  local send=(C_ChatInfo and C_ChatInfo.SendAddonMessage) or SendAddonMessage
  if type(send)~='function' then return false end
  local ok,ret=pcall(send,B.prefix,msg,'GUILD')
  return ok and ret~=false and ret~=2 and ret~=3
end
function B:RequestFromGuild(silent)
  if not guildName() then
    if not silent then WG:Say('Join an in-game guild to request event listings from guildmates.') end
    return
  end
  local now=GetTime and GetTime() or 0
  if self.lastRequest>0 and now-self.lastRequest<30 then
    if not silent then WG:Say('Guild sync was requested recently. Check again in a moment.') end
    return
  end
  self.lastRequest=now
  if not sendAddon('Q|1') and not silent then
    WG:Say('In-game guild sync is unavailable. Run the companion on your PC before launching WoW.')
  elseif not silent then WG:Say('Requested the Discord event list from online Waffles Gang users.') end
end
local function packet(e,syncedAt)
  -- One short read-only event per addon message; delimiter, length and types
  -- are validated again by receivers. Description is not broadcast.
  local id=clean(e.id,23)
  local title=clean(e.title,56)
  local loc=clean(e.location,27)
  local url=clean(e.url,90)
  local msg=table.concat({'E',tostring(syncedAt),id,tostring(integer(e.starts)),tostring(integer(e.rsvp)),title,loc,url},'|')
  if #msg>230 then msg=table.concat({'E',tostring(syncedAt),id,tostring(integer(e.starts)),tostring(integer(e.rsvp)),clean(title,34),clean(loc,18),clean(url,75)},'|') end
  return #msg<=230 and msg or nil
end
function B:ShareToGuild(silent)
  if not guildName() then
    if not silent then WG:Say('Join an in-game guild first.') end
    return
  end
  local feed=localFeed()
  if not feed or integer(feed.syncedAt)==0 then
    if not silent then WG:Say('Your client has no website feed yet. Run the companion and reload WoW.') end
    return
  end
  local now=GetTime and GetTime() or 0
  if self.lastReply>0 and now-self.lastReply<45 then
    if not silent then WG:Say('Event list was shared recently. Please wait a moment.') end
    return
  end
  local events=self:Events()
  self.lastReply=now
  -- A header also clears canceled/deleted events on peers, including when the
  -- Discord feed is now empty. Event cards arrive after this reset marker.
  sendAddon('H|'..tostring(integer(feed.syncedAt))..'|'..tostring(math.min(12,#events)))
  local count=0
  -- Stagger to respect WoW addon-message rate limits. No /g chat is sent.
  for _,e in ipairs(events) do
    if count>=12 then break end
    local msg=packet(e,integer(feed.syncedAt))
    if msg then
      count=count+1
      if C_Timer and type(C_Timer.After)=='function' then
        C_Timer.After(count*.35,function() sendAddon(msg) end)
      else sendAddon(msg) end
    end
  end
  if not silent then WG:Say('Shared '..count..' event summaries via guild addon messages, not guild chat.') end
end
function B:ReadMessage(prefix,msg,channel,sender)
  if prefix~=self.prefix or channel~='GUILD' or type(msg)~='string' or type(sender)~='string' then return end
  if not guildName() or #msg>230 or sender==playerName() then return end
  if msg=='Q|1' then
    -- Only clients with a local website feed answer. Relayed guild data is
    -- never further rebroadcast, preventing loops and stale-copy storms.
    if localFeed() and integer(localFeed().syncedAt)>0 then self:ShareToGuild(true) end
    return
  end
  local key=guildKey()
  if not key or not WG.db then return end
  WG.db.discordGuildFeeds=WG.db.discordGuildFeeds or {}
  -- Preserve a locally verified feed; remote messages are never authoritative.
  local localData=localFeed()
  if localData and integer(localData.syncedAt)>0 then return end
  local now=time and time() or 0
  local hrev,total=msg:match('^H|(%d+)|(%d+)$')
  if hrev then
    local stamp=integer(hrev)
    if stamp<1577836800 or stamp>now+86400 or integer(total)>12 then return end
    local previous=WG.db.discordGuildFeeds[key]
    if previous and stamp<integer(previous.syncedAt) then return end
    if previous and stamp==integer(previous.syncedAt) and previous.sender~=sender then return end
    -- A verified website client announcing 0 events clears an older guild list.
    WG.db.discordGuildFeeds[key]={syncedAt=stamp,receivedAt=now,events={},source='guild',sender=sender}
    if self.window and self.window:IsShown() then self:Update() end
    return
  end
  local rev,id,starts,rsvp,title,loc,url=msg:match('^E|([^|]+)|([^|]+)|([^|]+)|([^|]+)|([^|]+)|([^|]*)|([^|]*)$')
  if not rev then return end
  local stamp=integer(rev)
  local stored=WG.db.discordGuildFeeds[key]
  if type(stored)~='table' or stored.sender~=sender or stamp~=integer(stored.syncedAt) then return end
  local e=normalEvent({id=id,starts=starts,rsvp=rsvp,title=title,location=loc,url=url})
  if not e then return end
  stored.receivedAt=now
  for i,existing in ipairs(stored.events) do
    if existing.id==e.id then stored.events[i]=e; if self.window and self.window:IsShown() then self:Update() end;return end
  end
  if #stored.events<12 then stored.events[#stored.events+1]=e end
  if self.window and self.window:IsShown() then self:Update() end
end
function B:Init()
  local f=WG:Window('guildboard','Guild Events from Discord',792,688)
  self.window=f
  self.guildTitle=WG:Text(f,'DISCORD EVENTS',25,-80,17,'accent',728)
  self.summary=WG:Text(f,'',25,-110,10,'text',740)
  WG:Divider(f,-132,745,23)
  WG:Text(f,'UPCOMING EVENTS',25,-150,13,'accent')
  WG:Text(f,'Discord is the source of truth. Listings are read-only in WoW.',25,-173,10,'text',370)
  self.rows={}
  for i=1,self.pageSize do
    local row=WG:Button(f,'',24,-199-(i-1)*53,373,47,function()
      if B.rows[i].entry then B:Select(B.rows[i].entry) end
    end)
    row.label:ClearAllPoints()
    row.label:SetPoint('LEFT',row,'LEFT',10,0)
    row.label:SetJustifyH('LEFT');row.label:SetJustifyV('MIDDLE');row.label:SetWidth(350)
    self.rows[i]=row
  end
  self.pageLabel=WG:Text(f,'PAGE 1 / 1',25,-529,11,'accent',150)
  WG:Button(f,'PREV',193,-522,99,28,function()B.page=math.max(1,B.page-1);B:Update()end)
  WG:Button(f,'NEXT',298,-522,99,28,function()B.page=B.page+1;B:Update()end)
  WG:Text(f,'Update from the website using the companion, then /reload.',25,-566,10,'text',380)
  WG:Button(f,'REQUEST FROM GUILD',24,-590,373,36,function()B:RequestFromGuild(false)end)
  WG:Button(f,'SHARE MY SYNCED LIST',24,-633,180,29,function()B:ShareToGuild(false)end)
  WG:Button(f,'GUILD ROSTER',211,-633,186,29,function()WG:Open('guild')end)
  local side=CreateFrame('Frame',nil,f)
  side:SetSize(350,530);side:SetPoint('TOPLEFT',f,'TOPLEFT',416,-138)
  WG:Surface(side,'guildPanel','guildBorder')
  WG:Text(side,'EVENT DETAILS',17,-13,14,'accent')
  self.eventTitle=WG:Text(side,'SELECT AN EVENT',17,-52,15,'accent',318)
  self.eventWhen=WG:Text(side,'',17,-98,11,'text',319)
  self.eventLocation=WG:Text(side,'',17,-126,10,'text',319)
  self.eventRsvp=WG:Text(side,'',17,-154,10,'text',319)
  WG:Divider(side,-184,313,17)
  WG:Text(side,'DESCRIPTION',17,-199,11,'accent')
  self.eventNotes=WG:Text(side,'',17,-228,11,'text',314)
  self.eventNotes:SetHeight(119);self.eventNotes:SetJustifyV('TOP')
  WG:Text(side,'DISCORD LINK',17,-368,11,'accent')
  self.eventLink=WG:Text(side,'',17,-394,10,'text',311)
  self.eventLink:SetHeight(45);self.eventLink:SetJustifyV('TOP')
  WG:Button(side,'PUT LINK IN CHAT TO COPY',17,-459,315,36,function()B:CopyLink()end)
  WG:Text(side,'Events are managed in Discord, not in-game.',17,-503,10,'text',320)
  f.onOpen=function()
    B:Update()
    local feed=localFeed()
    if not feed or integer(feed.syncedAt)==0 then B:RequestFromGuild(true) end
  end
  WG:On('CHAT_MSG_ADDON',function(prefix,msg,channel,sender) B:ReadMessage(prefix,msg,channel,sender) end)
  WG:On('PLAYER_GUILD_UPDATE',function()if f:IsShown() then B:Update() end end)
  local reg=(C_ChatInfo and C_ChatInfo.RegisterAddonMessagePrefix) or RegisterAddonMessagePrefix
  if type(reg)=='function' then
    local ok,result=pcall(reg,self.prefix)
    self.registered=ok and result~=false and result~=2 and result~=3
  end
end
function B:Refresh()
  if self.window and not WG:Enabled('guild') then self.window:Hide() end
  if self.window and self.window:IsShown() then self:Update() end
end

-- Recruitment planner: drafts are deliberately prepared, never auto-spammed.
local R={name='Guild Recruitment'}
table.insert(WG.modules,R)
WG.guildRecruitment=R
local function defaultPitch()
  return 'Waffles Gang is recruiting! 18+ relaxed gaming, new and returning players welcome. Level together, explore, and enjoy WoW your way. deputywaffles.com'
end
local function defaultWelcome()
  return 'Welcome to Waffles Gang! Glad you are here. Say hi, ask for help, and join us for adventures. Community info: deputywaffles.com'
end
function R:Load()
  local key=guildKey()
  if not key then
    self.info:SetText('Join an in-game guild to save its recruitment draft.')
    return
  end
  WG.db.guildRecruitment=WG.db.guildRecruitment or {}
  local saved=WG.db.guildRecruitment[key] or {}
  self.pitch:SetText(saved.pitch or defaultPitch())
  self.welcome:SetText(saved.welcome or defaultWelcome())
  self.info:SetText('GUILD: '..(guildName() or 'Unknown')..'  |  DRAFTS SAVED LOCALLY')
  local history=WG.db.guildInviteAttempts or {}
  local lines={}
  for i=1,math.min(5,#history) do
    local entry=history[i]
    if type(entry)=='table' and type(entry.name)=='string' and entry.guild==key then
      lines[#lines+1]=entry.name..'  (invite attempted, acceptance unknown)'
    end
  end
  self.history:SetText(#lines>0 and table.concat(lines,'\n') or 'No local invite attempts recorded yet.')
end
function R:Save()
  local key=guildKey()
  if not key then return WG:Say('Join a guild before saving a recruitment draft.') end
  WG.db.guildRecruitment=WG.db.guildRecruitment or {}
  WG.db.guildRecruitment[key]={pitch=clean(self.pitch:GetText(),240),welcome=clean(self.welcome:GetText(),240)}
  WG:Say('Recruitment and welcome drafts saved locally for '..(guildName() or 'your guild')..'.')
end
function R:Prepare(which)
  local edit=(which=='welcome') and self.welcome or self.pitch
  local message=clean(edit:GetText(),240)
  if message=='' then return WG:Say('Write a draft message first.') end
  chatDraft(message)
  WG:Say('Message prepared in your chat box. Choose a channel and press Enter yourself.')
end
function R:Init()
  local f=WG:Window('recruitment','Guild Recruitment',792,642)
  self.window=f
  WG:Text(f,'RECRUITING WITH PERSONALITY',24,-82,16,'accent')
  self.info=WG:Text(f,'',25,-110,11,'text',744)
  WG:Divider(f,-137,745,24)
  WG:Text(f,'RECRUITMENT MESSAGE',24,-157,13,'accent')
  WG:Text(f,'Edit the pitch, then prepare it in chat. Nothing is automatically posted.',24,-183,10,'text',732)
  self.pitch=createInput(f,25,-206,739,68,240,true)
  WG:Button(f,'SAVE MY DRAFTS',25,-293,236,36,function()R:Save()end)
  WG:Button(f,'PREPARE RECRUITMENT CHAT',274,-293,490,36,function()R:Prepare('pitch')end)
  WG:Divider(f,-347,745,24)
  WG:Text(f,'NEW MEMBER WELCOME',24,-368,13,'accent')
  self.welcome=createInput(f,25,-394,739,61,240,true)
  WG:Button(f,'PREPARE WELCOME CHAT',25,-473,357,36,function()R:Prepare('welcome')end)
  WG:Button(f,'GUILD MANAGER',397,-473,367,36,function()WG:Open('guild')end)
  WG:Text(f,'RECENT INVITE REQUESTS (THIS ACCOUNT ONLY)',25,-531,11,'accent')
  self.history=WG:Text(f,'',26,-553,10,'text',730)
  f.onOpen=function()R:Load()end
end
function R:Refresh()
  if self.window and not WG:Enabled('guild') then self.window:Hide() end
end
