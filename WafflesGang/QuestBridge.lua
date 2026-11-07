-- Waffle Quest Companion - original presentation using the Blizzard quest log.
-- Optional Questie integration uses only Questie.API.RegisterOnReady and
-- Questie.API.RegisterForQuestUpdates; no Questie/QuestieDB source is bundled.
local WG=_G.WafflesGang
local Q={name='Waffle Quest Companion',rows={},entries={},selected=nil,page=1,questieReady=false,questieHooked=false}
WG.quests=Q
WG.modules[#WG.modules+1]=Q
local function readable(v) return not (issecretvalue and issecretvalue(v)) end
local function safeText(v,otherwise)
  if readable(v) and type(v)=='string' then return v end
  return otherwise or ''
end
local function safeNumber(v)
  if readable(v) and type(v)=='number' then return v end
end
local function questAPI() return C_QuestLog end
local function isCampaign(questID, info)
  if type(info)=='table' and safeNumber(info.campaignID) and info.campaignID>0 then return true end
  if not (C_CampaignInfo and C_CampaignInfo.IsCampaignQuest) then return false end
  local ok,value=pcall(C_CampaignInfo.IsCampaignQuest,questID)
  return ok and readable(value) and value==true
end
function Q:Options()
  if not WG.db then return {tracker=false,showLevels=true} end
  if type(WG.db.questStudio)~='table' then WG.db.questStudio={} end
  local o=WG.db.questStudio
  if o.tracker==nil then o.tracker=false end
  if o.showLevels==nil then o.showLevels=true end
  return o
end
function Q:Scan()
  local quests={}
  local currentZone='Other Quests'
  local api=questAPI()
  if api and api.GetNumQuestLogEntries and api.GetInfo then
    local ok,count=pcall(api.GetNumQuestLogEntries)
    if ok and safeNumber(count) then
      for i=1,math.min(count,250) do
        local got,info=pcall(api.GetInfo,i)
        if got and type(info)=='table' and readable(info.isHeader) then
          if info.isHeader==true then
            currentZone=safeText(info.title,'Other Quests')
          elseif safeNumber(info.questID) and info.questID>0 then
            quests[#quests+1]={id=info.questID,title=safeText(info.title,'Quest '..info.questID),zone=currentZone,
              level=safeNumber(info.level),complete=readable(info.isComplete) and info.isComplete==true,
              campaign=isCampaign(info.questID,info)}
          end
        end
      end
    end
  elseif GetNumQuestLogEntries and GetQuestLogTitle then
    local ok,count=pcall(GetNumQuestLogEntries)
    if ok and safeNumber(count) then
      for i=1,math.min(count,250) do
        local good,title,level,_,isHeader,_,isComplete,_,id=pcall(GetQuestLogTitle,i)
        if good and isHeader and readable(title) and type(title)=='string' then
          currentZone=title
        elseif good and not isHeader and readable(title) and type(title)=='string' then
          quests[#quests+1]={id=safeNumber(id) or i,title=title,zone=currentZone,level=safeNumber(level),complete=isComplete==1 or isComplete==true,
            campaign=isCampaign(safeNumber(id) or i),legacyIndex=i}
        end
      end
    end
  end
  return quests
end
function Q:Objectives(q)
  if not q then return {} end
  local objectives={}
  local api=questAPI()
  if api and api.GetQuestObjectives and not q.legacyIndex then
    local ok,data=pcall(api.GetQuestObjectives,q.id)
    if ok and type(data)=='table' then
      for _,obj in ipairs(data) do
        if type(obj)=='table' then
          local text=safeText(obj.text)
          if text~='' then
            local done=readable(obj.finished) and obj.finished==true
            objectives[#objectives+1]={text=text,done=done,current=safeNumber(obj.numFulfilled),required=safeNumber(obj.numRequired)}
          end
        end
      end
    end
  elseif q.legacyIndex and GetNumQuestLeaderBoards and GetQuestLogLeaderBoard then
    local ok,count=pcall(GetNumQuestLeaderBoards,q.legacyIndex)
    if ok and safeNumber(count) then
      for i=1,math.min(count,8) do
        local good,text,_,done=pcall(GetQuestLogLeaderBoard,i,q.legacyIndex)
        if good and readable(text) and type(text)=='string' then objectives[#objectives+1]={text=text,done=done==true} end
      end
    end
  end
  return objectives
end
function Q:Selected()
  for _,row in ipairs(self.entries) do if row.id==self.selected then return row end end
  local row=self.entries[1]
  if row then self.selected=row.id end
  return row
end
function Q:ConnectQuestie()
  local questie=_G.Questie
  local api=questie and questie.API
  if not api or self.questieHooked then return end
  self.questieHooked=true
  local function ready()
    Q.questieReady=true;Q:UpdateView()
    if type(api.RegisterForQuestUpdates)=='function' then
      pcall(api.RegisterForQuestUpdates,function() Q:UpdateView() end)
    end
  end
  if api.isReady then ready()
  elseif type(api.RegisterOnReady)=='function' then
    local ok=pcall(api.RegisterOnReady,ready)
    if not ok then self.questieHooked=false end
  else self.questieHooked=false end
end
function Q:ClearNavigation()
  local o=self:Options()
  o.navigationQuestID=nil
  if self.waffleWaypoint and _G.TomTom and type(TomTom.RemoveWaypoint)=='function' then
    pcall(TomTom.RemoveWaypoint,TomTom,self.waffleWaypoint)
  end
  self.waffleWaypoint=nil
  self.navWaypoint=nil
  self.questieRouteActive=false
  self.navigationState='Select a quest to follow'
  if self.UpdateArrow then self:UpdateArrow() end
end
-- Questie chooses the nearest still-relevant quest objective with
-- TrackerUtils.SetQuestTomTomTarget(questId). In Questie for Forever it records
-- the TomTom UID in Questie.db.char._tom_waypoint. That UID is a table:
-- {uiMapId, x(0-1), y(0-1), title=...}. A boolean returned by Questie is
-- NOT a coordinate: the old integration stopped there and never fed our arrow.
local function waypointUID()
  local questie=_G.Questie
  local db=questie and questie.db
  local char=db and db.char
  local uid=char and char._tom_waypoint
  if type(uid)~='table' then return end
  if not (safeNumber(uid[1]) and safeNumber(uid[2]) and safeNumber(uid[3])) then return end
  if uid[1]<=0 or uid[2]<0 or uid[2]>1 or uid[3]<0 or uid[3]>1 then return end
  -- A removed Questie waypoint may remain in saved settings temporarily.
  local tomtom=_G.TomTom
  if tomtom and type(tomtom.IsValidWaypoint)=='function' then
    local ok,active=pcall(tomtom.IsValidWaypoint,tomtom,uid)
    if ok and not active then return end
  end
  return uid
end
function Q:SyncQuestieWaypoint(questID)
  local uid=waypointUID()
  if not uid then return false end
  local old=self.navWaypoint
  if old and old.uid==uid and old.questID==questID then return true end
  self.navWaypoint={mapID=uid[1],x=uid[2],y=uid[3],uid=uid,
    questID=questID,label=safeText(uid.title,'Questie objective')}
  self.navigationState='Questie waypoint: '..self.navWaypoint.label
  return true
end
-- Coordinate fallback when Questie has no TomTom waypoint. The modules here
-- are Questie internals, not its guaranteed public API: isolate in pcall.
local function questieObjectiveCoordinates(id)
  local loader=_G.QuestieLoader
  if not loader or type(loader.ImportModule)~='function' then return end
  local ok,map,x,y=pcall(function()
    local eligibility=loader:ImportModule('TrackerMapEligibility')
    local distance=loader:ImportModule('DistanceUtils')
    local zoneDB=loader:ImportModule('ZoneDB')
    if not eligibility or not distance or not zoneDB then return end
    if type(eligibility.RefreshAndGetCapabilities)~='function' or
       type(distance.GetNearestSpawnForQuest)~='function' or
       type(zoneDB.GetUiMapIdByAreaId)~='function' then return end
    local quest,capabilities=eligibility.RefreshAndGetCapabilities(id)
    if not (capabilities and capabilities.canNavigateQuest and quest) then return end
    local spawn,zone=distance.GetNearestSpawnForQuest(quest)
    if type(spawn)~='table' or not safeNumber(spawn[1]) or not safeNumber(spawn[2]) then return end
    return zoneDB:GetUiMapIdByAreaId(zone),spawn[1]/100,spawn[2]/100
  end)
  if ok and safeNumber(map) and map>0 and safeNumber(x) and safeNumber(y)
    and x>=0 and x<=1 and y>=0 and y<=1 then
    return map,x,y
  end
end
function Q:NavigateToQuest(id)
  if type(id)~='number' or not WG.db then return false end
  local options=self:Options()
  options.navigationQuestID=id
  self.selected=id
  local api=C_QuestLog
  if api and api.SetSelectedQuest then pcall(api.SetSelectedQuest,id) end
  if C_SuperTrack and C_SuperTrack.SetSuperTrackedQuestID then
    pcall(C_SuperTrack.SetSuperTrackedQuestID,id)
  end
  -- Remove only Waffles-created waypoints. Questie's waypoint belongs to
  -- Questie and should remain until Questie replaces it.
  if self.waffleWaypoint and _G.TomTom and type(TomTom.RemoveWaypoint)=='function' then
    pcall(TomTom.RemoveWaypoint,TomTom,self.waffleWaypoint)
  end
  self.waffleWaypoint=nil
  self.navWaypoint=nil
  self.questieRouteActive=false
  local title='Waffle Quest '..id
  for _,q in ipairs(self.entries or {}) do
    if q.id==id then title=q.title;break end
  end
  -- Use the same nearest-objective selection as Questie's own tracker.
  -- ImportModule returns a module with the function defined using DOT syntax.
  local loader=_G.QuestieLoader
  if _G.TomTom and loader and type(loader.ImportModule)=='function' then
    local ok,worked=pcall(function()
      local utils=loader:ImportModule('TrackerUtils')
      if utils and type(utils.SetQuestTomTomTarget)=='function' then
        return utils.SetQuestTomTomTarget(id)
      end
    end)
    if ok and worked and self:SyncQuestieWaypoint(id) then
      self.questieRouteActive=true
      if self.UpdateArrow then self:UpdateArrow() end
      return true
    end
  end
  -- Questie without TomTom, or a quest that has no supported TomTom route:
  -- ask its objective-finder for coordinates when that API is available.
  local mapID,x,y=questieObjectiveCoordinates(id)
  if not mapID and api and type(api.GetNextWaypoint)=='function' then
    local ok,a,b,c=pcall(api.GetNextWaypoint,id)
    if ok and safeNumber(a) and safeNumber(b) and safeNumber(c) and a>0
      and b>=0 and b<=1 and c>=0 and c<=1 then mapID,x,y=a,b,c end
  end
  if mapID then
    self.navWaypoint={mapID=mapID,x=x,y=y,questID=id,label=title}
    self.navigationState='Waffles waypoint: '..title
    if _G.TomTom and type(TomTom.AddWaypoint)=='function' then
      local ok,uid=pcall(TomTom.AddWaypoint,TomTom,mapID,x,y,
        {title=title,crazy=true,from='WafflesGang'})
      if ok and uid then
        self.waffleWaypoint=uid
        self.navWaypoint.uid=uid
      end
    end
    if self.UpdateArrow then self:UpdateArrow() end
    return true
  end
  self.navigationState='Quest selected; no valid waypoint found'
  if self.UpdateArrow then self:UpdateArrow() end
  return false
end
function Q:TrackSelected()
  local selected=self:Selected();if not selected then return end
  local routed=self:NavigateToQuest(selected.id)
  if routed then WG:Say('Following '..selected.title..' with the quest arrow.');return end
  local api=questAPI()
  if api and api.SetSelectedQuest then pcall(api.SetSelectedQuest,selected.id) end
  if C_SuperTrack and C_SuperTrack.SetSuperTrackedQuestID then
    local ok=pcall(C_SuperTrack.SetSuperTrackedQuestID,selected.id)
    if ok then WG:Say('Quest focused. No navigation waypoint found; check Questie map.');return end
  end
  if api and api.AddQuestWatch then
    local ok=pcall(api.AddQuestWatch,selected.id)
    if ok then WG:Say('Quest added to watch list.');return end
  end
  WG:Say('Selected in the journal. Quest tracking may be controlled by Questie.')
end
function Q:UpdateView()
  if not WG.db then return end
  self.entries=self:Scan()
  local total=#self.entries
  local maxPage=math.max(1,math.ceil(total/7))
  self.page=math.max(1,math.min(self.page,maxPage))
  if not self.window then return end
  if self.count then self.count:SetText(string.format('%d ACTIVE QUESTS   /   PAGE %d OF %d',total,self.page,maxPage)) end
  if self.questieStatus then
    local ready=self.questieReady or (_G.Questie and _G.Questie.API and _G.Questie.API.isReady)
    self.questieStatus:SetText(ready and 'QUESTIE CONNECTED  /  MAP MARKERS ACTIVE' or
      (_G.Questie and 'QUESTIE LOADING  /  QUEST LOG AVAILABLE' or 'QUESTIE OPTIONAL  /  NOT INSTALLED'))
  end
  for i,row in ipairs(self.rows) do
    local quest=self.entries[(self.page-1)*7+i]
    row.quest=quest
    row.button:SetShown(quest~=nil)
    if quest then
      local level=self:Options().showLevels and quest.level and ('['..quest.level..'] ') or ''
      row.button.label:SetText((quest.id==self.selected and '> ' or '')..level..quest.title)
    end
  end
  local selected=self:Selected()
  if self.detailTitle then
    self.detailTitle:SetText(selected and selected.title or 'No quests in your quest log')
    if self.detailMeta then self.detailMeta:SetText(selected and ((selected.complete and 'READY TO TURN IN' or 'IN PROGRESS')..(selected.level and ('  /  LEVEL '..selected.level) or '')) or '') end
    local objectives=self:Objectives(selected)
    for i,view in ipairs(self.objectiveRows) do
      local obj=objectives[i]
      view:SetText(obj and ((obj.done and '[DONE] ' or '[ ] ')..obj.text) or '')
    end
    if self.info then self.info:SetText(selected and (#objectives==0 and 'No objective details are available from this client.' or
      'Quest progress comes from your in-game journal. Questie manages its map markers.') or
      'Questie can be installed separately to add quest locations and map icons.') end
  end
  self:UpdateTracker()
end
function Q:UpdateTracker()
  if self.RenderTracker then self:RenderTracker() end
end
function Q:Init()
  self:Options()
  local f=WG:Window('quests','Waffle Quest Journal',784,600)
  self.window=f
  WG:Text(f,'QUEST LOG',25,-81,15,'accent')
  self.count=WG:Text(f,'LOADING QUESTS...',25,-108,11,'text',300)
  WG:Divider(f,-134,735,24)
  self.rows={}
  for i=1,7 do
    local b=WG:Button(f,'',25,-154-(i-1)*47,308,39,function()
      local item=Q.rows[i].quest
      if item then Q.selected=item.id;Q:UpdateView() end
    end)
    b.label:SetJustifyH('LEFT')
    self.rows[i]={button=b}
  end
  WG:Button(f,'PREV',25,-497,94,32,function()Q.page=Q.page-1;Q:UpdateView()end)
  WG:Button(f,'NEXT',128,-497,94,32,function()Q.page=Q.page+1;Q:UpdateView()end)
  WG:Text(f,'QUEST DETAILS',360,-157,15,'accent')
  self.detailTitle=WG:Text(f,'',360,-188,14,'text',387)
  self.detailMeta=WG:Text(f,'',360,-237,11,'accent',387)
  self.objectiveRows={}
  for i=1,6 do self.objectiveRows[i]=WG:Text(f,'',360,-272-(i-1)*37,11,'text',376) end
  self.info=WG:Text(f,'',360,-501,10,'text',390)
  WG:Button(f,'TRACK SELECTED',360,-537,181,33,function()Q:TrackSelected()end)
  WG:Button(f,'WORLD MAP',548,-537,194,33,function()
    if ToggleWorldMap then ToggleWorldMap()
    elseif WorldMapFrame then WorldMapFrame:Show() end
  end)
  self.questieStatus=WG:Text(f,'QUESTIE OPTIONAL',25,-547,10,'accent',320)
  f.onOpen=function()Q:ConnectQuestie();Q:UpdateView()end
  if self.InitTracker then self:InitTracker() end
  if self.InitArrow then self:InitArrow() end
  for _,event in ipairs({'QUEST_LOG_UPDATE','QUEST_ACCEPTED','QUEST_REMOVED','QUEST_WATCH_LIST_CHANGED','PLAYER_ENTERING_WORLD'}) do
    WG:On(event,function()Q:UpdateView()end)
  end
  WG:On('ADDON_LOADED',function(name) if name=='Questie' then Q:ConnectQuestie() end end)
  self:ConnectQuestie()
  self:UpdateView()
end
function Q:Refresh()
  self:ConnectQuestie()
  self:UpdateView()
end
