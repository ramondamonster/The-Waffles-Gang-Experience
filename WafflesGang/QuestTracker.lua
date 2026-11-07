-- Waffle Tracker 2: original Waffles Gang presentation built from native quest log.
-- Questie remains an optional, independently installed map/quest provider.
-- Inspired by general UI patterns (pooling, responsive rows) but no Questie code/assets copied.
local WG=_G.WafflesGang
local Q=WG.quests
if not Q then return end

local min,max,ceil=math.min,math.max,math.ceil
local function isReadable(v) return not (issecretvalue and issecretvalue(v)) end
local function clamp(n,lo,hi) return max(lo,min(hi,n)) end
local function color(name)
  local c=WG:Color(name)
  if type(c)=='table' then return c[1] or 1,c[2] or 1,c[3] or 1 end
  return 1,1,1
end
local function safeProgress(obj)
  local current,required=obj.current,obj.required
  if not (isReadable(current) and type(current)=='number' and isReadable(required) and type(required)=='number' and required>0) then
    local a,b=(obj.text or ''):match('(%d+)%s*/%s*(%d+)')
    current,required=tonumber(a),tonumber(b)
  end
  if required and required>0 and required<100000 and current and current>=0 then
    return clamp(current,0,required),required
  end
end
local function setFont(label,size)
  local f=WG:StyleFont(size)
  local ok=pcall(label.SetFont,label,f,size,WG:StyleName()=='Modern' and '' or 'OUTLINE')
  if not ok then label:SetFont(STANDARD_TEXT_FONT or 'Fonts\\FRIZQT__.TTF',size,'') end
end

function Q:TrackerOptions()
  local o=self:Options()
  local defaults={width=355,opacity=.58,fontSize=13,maxQuests=9,maxHeight=490,
    groupZones=true,showBars=true,watchedOnly=false,showCompleted=true,compact=false,
    campaignFirst=true,readyLast=true,autoHeight=true,showArrow=true,navigationStyle='compact'}
  for k,v in pairs(defaults) do if o[k]==nil then o[k]=v end end
  o.width=clamp(tonumber(o.width) or 340,250,480)
  o.opacity=clamp(tonumber(o.opacity) or .35,0,.95)
  o.fontSize=clamp(tonumber(o.fontSize) or 11,9,16)
  o.maxQuests=clamp(tonumber(o.maxQuests) or 9,1,20)
  o.maxHeight=clamp(tonumber(o.maxHeight) or 490,70,750)
  if o.navigationStyle~='classic' then o.navigationStyle='compact' end
  -- One-time Modern legibility upgrade for existing users, preserving all
  -- subsequent manual font-size choices and Classic's historical defaults.
  if WG:StyleName()=='Modern' and not o.modernLegibilityApplied then
    if o.fontSize<13 then o.fontSize=13 end
    if o.opacity<.50 then o.opacity=.50 end
    o.modernLegibilityApplied=true
  end
  -- The navigation choice is independent of Questie's own tracker. Persisting
  -- only a quest ID avoids invalidating saved data on log rearrangement.
  if o.navigationQuestID~=nil and type(o.navigationQuestID)~='number' then o.navigationQuestID=nil end
  if type(o.collapsedQuests)~='table' then o.collapsedQuests={} end
  if type(o.collapsedZones)~='table' then o.collapsedZones={} end
  return o
end

local function makeLabel(parent,width,size)
  local label=parent:CreateFontString(nil,'OVERLAY','GameFontHighlightSmall')
  label:SetPoint('TOPLEFT',parent,'TOPLEFT',7,-3)
  label:SetWidth(width-14)
  label:SetJustifyH('LEFT');label:SetJustifyV('TOP');label:SetWordWrap(true)
  setFont(label,size)
  return label
end

function Q:NewTrackerRow()
  local row=CreateFrame('Button',nil,self.trackerContent)
  row:EnableMouse(true)
  row:RegisterForClicks('LeftButtonUp','RightButtonUp')
  row.back=row:CreateTexture(nil,'BACKGROUND')
  row.back:SetAllPoints()
  row.mark=row:CreateTexture(nil,'ARTWORK')
  row.mark:SetPoint('TOPLEFT',row,'TOPLEFT',0,0)
  row.mark:SetWidth(2)
  row.mark:SetHeight(10)
  row.label=makeLabel(row,290,11)
  row.info=row:CreateFontString(nil,'OVERLAY','GameFontHighlightSmall')
  row.info:SetPoint('TOPRIGHT',row,'TOPRIGHT',-4,-4)
  row.info:SetJustifyH('RIGHT')
  row.track=row:CreateTexture(nil,'BACKGROUND')
  row.track:SetPoint('BOTTOMLEFT',row,'BOTTOMLEFT',12,4)
  row.track:SetHeight(3)
  row.fill=row:CreateTexture(nil,'ARTWORK')
  row.fill:SetPoint('LEFT',row.track,'LEFT',0,0)
  row.fill:SetHeight(3)
  row:SetScript('OnClick',function(btn,button)
    if btn.kind=='zone' then
      local o=Q:TrackerOptions()
      o.collapsedZones[btn.zone]=not o.collapsedZones[btn.zone]
    elseif btn.kind=='quest' then
      if button=='RightButton' then
        local o=Q:TrackerOptions()
        o.collapsedQuests[btn.questId]=not o.collapsedQuests[btn.questId]
      else
        Q.selected=btn.questId
        Q:NavigateToQuest(btn.questId)
      end
    end
    Q:UpdateTracker()
  end)
  row:SetScript('OnEnter',function(btn)
    if btn.kind=='zone' or btn.kind=='quest' then
      btn.hovered=true;Q:RepaintTracker()
      GameTooltip:SetOwner(btn,'ANCHOR_LEFT')
      GameTooltip:AddLine(btn.kind=='zone' and 'Click to expand/collapse the zone' or
        'Left-click: Follow quest (navigation arrow)    Right-click: Fold quest',1,.9,.65)
      GameTooltip:Show()
    end
  end)
  row:SetScript('OnLeave',function(btn)
    btn.hovered=false;Q:RepaintTracker();GameTooltip:Hide()
  end)
  row:Hide()
  return row
end

function Q:InitTracker()
  local o=self:TrackerOptions()
  local tracker=CreateFrame('Frame','WGQuestTracker',UIParent)
  tracker:SetSize(o.width,160)
  tracker:SetPoint('RIGHT',UIParent,'RIGHT',-40,-60)
  tracker:SetFrameStrata('MEDIUM')
  tracker:SetMovable(true)
  tracker:SetResizable(true)
  tracker:SetClampedToScreen(true)
  if tracker.SetResizeBounds then tracker:SetResizeBounds(250,145,480,840)
  else
    if tracker.SetMinResize then tracker:SetMinResize(250,145) end
    if tracker.SetMaxResize then tracker:SetMaxResize(480,840) end
  end
  self.tracker=tracker
  local back=tracker:CreateTexture(nil,'BACKGROUND')
  back:SetAllPoints()
  self.trackerBack=back
  -- Modern's rounded translucent quest card is separate from the classic tracker art.
  self.trackerRound=WG.ModernRounded and WG:ModernRounded(tracker) or nil
  self.trackerTactical=WG.TacticalPlate and WG:TacticalPlate(tracker) or nil
  self.trackerTacticalEdge=WG.TacticalPlate and WG:TacticalPlate(tracker,'PlateBorder') or nil
  local edge=tracker:CreateTexture(nil,'BORDER')
  edge:SetPoint('TOPLEFT',tracker,'TOPLEFT',0,0)
  edge:SetPoint('BOTTOMLEFT',tracker,'BOTTOMLEFT',0,0)
  edge:SetWidth(2)
  self.trackerEdge=edge
  local header=CreateFrame('Button',nil,tracker)
  header:SetPoint('TOPLEFT',tracker,'TOPLEFT',2,-2)
  header:SetPoint('TOPRIGHT',tracker,'TOPRIGHT',-2,-2)
  header:SetHeight(36)
  header:RegisterForClicks('LeftButtonUp','RightButtonUp')
  self.trackerHeader=header
  local headerBack=header:CreateTexture(nil,'BACKGROUND')
  headerBack:SetAllPoints()
  self.trackerHeaderBack=headerBack
  self.headerRound=WG.ModernRounded and WG:ModernRounded(header) or nil
  self.headerTactical=WG.TacticalPlate and WG:TacticalPlate(header) or nil
  local hTitle=header:CreateFontString(nil,'OVERLAY','GameFontHighlight')
  hTitle:SetPoint('LEFT',header,'LEFT',10,0)
  hTitle:SetJustifyH('LEFT')
  self.trackerHeaderTitle=hTitle
  local count=header:CreateFontString(nil,'OVERLAY','GameFontHighlightSmall')
  count:SetPoint('RIGHT',header,'RIGHT',-10,0)
  count:SetJustifyH('RIGHT')
  self.trackerCount=count
  header:SetScript('OnClick',function(_,button)
    if button=='RightButton' then
      if WG.studio then WG:Open('studio');WG.studio:Select('QUESTS') end
    else
      local cfg=Q:TrackerOptions()
      cfg.collapsed=not cfg.collapsed
      Q:UpdateTracker()
    end
  end)
  header:SetScript('OnEnter',function()
    GameTooltip:SetOwner(header,'ANCHOR_LEFT')
    GameTooltip:AddLine('Left-click: Collapse quests',1,.9,.6)
    GameTooltip:AddLine('Right-click: Waffle Tracker settings',.9,.9,.9)
    GameTooltip:Show()
  end)
  header:SetScript('OnLeave',function()GameTooltip:Hide()end)
  local nav=CreateFrame('Button',nil,tracker)
  nav:SetPoint('TOPLEFT',header,'BOTTOMLEFT',4,-2)
  nav:SetPoint('TOPRIGHT',header,'BOTTOMRIGHT',-4,-2)
  nav:SetHeight(25)
  nav:RegisterForClicks('LeftButtonUp','RightButtonUp')
  local navLabel=nav:CreateFontString(nil,'OVERLAY','GameFontHighlightSmall')
  navLabel:SetPoint('LEFT',nav,'LEFT',7,0)
  navLabel:SetPoint('RIGHT',nav,'RIGHT',-7,0)
  navLabel:SetJustifyH('LEFT')
  self.trackerNav=nav
  self.trackerNavLabel=navLabel
  nav:SetScript('OnClick',function(_,button)
    local opt=Q:TrackerOptions()
    if button=='RightButton' then
      Q:ClearNavigation()
    elseif opt.navigationQuestID then
      Q:NavigateToQuest(opt.navigationQuestID)
    end
    Q:UpdateTracker()
  end)
  nav:SetScript('OnEnter',function()
    GameTooltip:SetOwner(nav,'ANCHOR_LEFT')
    GameTooltip:AddLine('Click to refresh the selected quest route',1,.9,.65)
    GameTooltip:AddLine('Right-click to clear this route',.8,.8,.8)
    GameTooltip:Show()
  end)
  nav:SetScript('OnLeave',function() GameTooltip:Hide() end)
  local scroll=CreateFrame('ScrollFrame',nil,tracker)
  scroll:SetPoint('TOPLEFT',nav,'BOTTOMLEFT',-2,-3)
  scroll:SetPoint('TOPRIGHT',header,'BOTTOMRIGHT',0,-3)
  scroll:SetHeight(100)
  scroll:EnableMouseWheel(true)
  self.trackerScroll=scroll
  local content=CreateFrame('Frame',nil,scroll)
  content:SetSize(o.width-4,100)
  scroll:SetScrollChild(content)
  self.trackerContent=content
  scroll:SetScript('OnMouseWheel',function(f,delta)
    local current=f:GetVerticalScroll()
    local maxScroll=max(0,content:GetHeight()-f:GetHeight())
    f:SetVerticalScroll(clamp(current-delta*40,0,maxScroll))
  end)
  local footer=tracker:CreateFontString(nil,'OVERLAY','GameFontHighlightSmall')
  footer:SetPoint('BOTTOMLEFT',tracker,'BOTTOMLEFT',11,7)
  footer:SetJustifyH('LEFT')
  self.trackerFooter=footer
  self.trackerRows={}
  WG:RegisterHUDFrame('questtracker',tracker,'Quest Tracker')
  -- Use Waffle Edit Mode to reveal this handle; the normal tracker remains clean.
  -- Manually resizing switches Auto Height off and saves both dimensions.
  local grip=CreateFrame('Button',nil,UIParent)
  grip:SetSize(27,27)
  grip:SetFrameStrata('FULLSCREEN_DIALOG')
  grip:SetPoint('BOTTOMRIGHT',tracker,'BOTTOMRIGHT',0,0)
  local gripMark=grip:CreateTexture(nil,'OVERLAY')
  gripMark:SetPoint('BOTTOMRIGHT',grip,'BOTTOMRIGHT',-4,4)
  gripMark:SetSize(15,15)
  gripMark:SetTexture('Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up')
  if gripMark.SetVertexColor then gripMark:SetVertexColor(1,.8,.4,1) end
  grip:SetScript('OnEnter',function()
    GameTooltip:SetOwner(grip,'ANCHOR_TOP')
    GameTooltip:AddLine('Drag to resize Waffle Quests',1,.87,.59)
    GameTooltip:AddLine('Resizing turns Auto Height off. Turn it on in Studio to fit content.',.82,.82,.82)
    GameTooltip:Show()
  end)
  grip:SetScript('OnLeave',function()GameTooltip:Hide()end)
  grip:SetScript('OnMouseDown',function(_,button)
    if button~='LeftButton' or WG:Protected() or not WG.editMode then return end
    Q.trackerResizing=true
    tracker:StartSizing('BOTTOMRIGHT')
  end)
  grip:SetScript('OnMouseUp',function()
    if not Q.trackerResizing then return end
    tracker:StopMovingOrSizing()
    Q.trackerResizing=false
    local w,h=tracker:GetSize()
    local opts=Q:TrackerOptions()
    opts.width=clamp(math.floor(w+.5),250,480)
    local plain=(WG:StyleName()=='Tactical' and WG:TacticalSettings().questMinimal) or (WG:StyleName()=='Adventure' and WG:ExpeditionSettings().journalMinimal)
    opts.maxHeight=clamp(math.floor(h-(plain and 0 or 85)+.5),70,750)
    opts.autoHeight=false
    WG:SaveHUDPosition('questtracker',tracker)
    Q:UpdateTracker()
    if WG.studio and WG.studio.Refresh then WG.studio:Refresh() end
  end)
  self.trackerResizeGrip=grip
  grip:Hide()
  tracker:SetScript('OnUpdate',function(_,elapsed)
    Q._editElapsed=(Q._editElapsed or 0)+elapsed
    if Q._editElapsed>.2 then
      Q._editElapsed=0
      grip:SetShown(WG.editMode==true)
    end
  end)
  tracker:Hide()
  self:UpdateTracker()
end

function Q:RepaintTracker()
  if not self.tracker then return end
  local o=self:TrackerOptions()
  local br,bg,bb=color('bg')
  local ar,ag,ab=color('accent')
  local pr,pg,pb=color('panel')
  local tr,tg,tb=color('text')
  local modern=WG:StyleName()=='Modern'
  local tactical=WG:StyleName()=='Tactical'
  local adventure=WG:StyleName()=='Adventure'
  local t=tactical and WG:TacticalSettings() or nil
  local exp=adventure and WG:ExpeditionSettings() or nil
  local fontSize=tactical and t.questFont or o.fontSize
  local minimal=(tactical and t.questMinimal) or (adventure and exp.journalMinimal)
  self.trackerBack:SetColorTexture(br,bg,bb,minimal and 0 or (modern and 0 or (tactical and t.questOpacity or o.opacity)))
  if self.trackerTactical then
    self.trackerTactical:SetShown(false)
    self.trackerTacticalEdge:SetShown(false)
    if tactical then
      self.trackerTactical:SetColor(br,bg,bb,t.questOpacity)
      self.trackerTacticalEdge:SetColor(ar,ag,ab,.63)
    end
  end
  self.trackerHeaderBack:SetColorTexture(pr,pg,pb,minimal and 0 or (modern and 0 or (tactical and .90 or (adventure and .26 or clamp(o.opacity+.30,.24,.91)))))
  self.trackerHeader:SetShown(not minimal)
  self.trackerNav:SetShown(not minimal and not o.collapsed)
  self.trackerFooter:SetShown(not minimal and not o.collapsed)
  if self.headerTactical then
    self.headerTactical:SetShown(false)
    if tactical then self.headerTactical:SetColor(pr,pg,pb,.97) end
  end
  if self.trackerRound then
    self.trackerRound:SetShown(modern)
    if modern then self.trackerRound:SetColor(br,bg,bb,clamp(o.opacity+.30,.66,.94)) end
  end
  if self.headerRound then
    self.headerRound:SetShown(modern)
    if modern then self.headerRound:SetColor(pr,pg,pb,clamp(o.opacity+.32,.38,.82)) end
  end
  self.trackerEdge:SetColorTexture(ar,ag,ab,minimal and 0 or (tactical and 1 or (modern and .84 or .65)))
  if self.trackerNavLabel then
    setFont(self.trackerNavLabel,tactical and 12 or (modern and 12 or 10))
    self.trackerNavLabel:SetTextColor(ar,ag,ab)
  end
  setFont(self.trackerHeaderTitle,(modern and max(12,fontSize) or fontSize)+3)
  self.trackerHeaderTitle:SetTextColor(ar,ag,ab)
  setFont(self.trackerCount,fontSize)
  self.trackerCount:SetTextColor(tr,tg,tb)
  setFont(self.trackerFooter,9)
  self.trackerFooter:SetTextColor(tr,tg,tb)
  for _,row in ipairs(self.trackerRows or {}) do
    if row:IsShown() then
      local kind=row.kind
      local hovered=row.hovered
      local a=kind=='zone' and .19 or (kind=='quest' and .12 or .02)
      local selected=kind=='quest' and row.questId==self:TrackerOptions().navigationQuestID
      row.back:SetColorTexture(pr,pg,pb,minimal and (hovered and .22 or (selected and .12 or 0))
        or (tactical and (selected and .68 or hovered and .44 or (kind=='zone' and .48 or (kind=='quest' and .28 or .14)))
        or (modern and (selected and .41 or hovered and .31 or (kind=='zone' and .16 or .095)) or (hovered and .50 or a))))
      if kind=='quest' and row.questId==o.navigationQuestID then
        row.mark:SetColorTexture(ar,ag,ab,1)
      elseif kind=='zone' then
        row.mark:SetColorTexture(ar,ag,ab,minimal and 0 or .8)
      else row.mark:SetColorTexture(ar,ag,ab,0) end
      local sz=(modern and max(fontSize,13) or fontSize)+(kind=='zone' and (minimal and -1 or 0) or kind=='quest' and 1 or -1)
      setFont(row.label,sz)
      if kind=='zone' then row.label:SetTextColor(ar,ag,ab)
      elseif kind=='quest' and (modern or tactical or adventure) and selected then row.label:SetTextColor(1,1,.96)
      elseif kind=='quest' then row.label:SetTextColor(tr,tg,tb)
      elseif row.done then row.label:SetTextColor(.49,.82,.51)
      else row.label:SetTextColor(tr*.85,tg*.85,tb*.85) end
      setFont(row.info,max(9,sz-1))
      row.info:SetTextColor(kind=='quest' and ar or .56,kind=='quest' and ag or .75,kind=='quest' and ab or .70)
      row.label:ClearAllPoints()
      row.label:SetPoint('TOPLEFT',row,'TOPLEFT',minimal and (kind=='objective' and 21 or kind=='quest' and 10 or 2) or 7,minimal and -2 or -3)
      row.track:SetColorTexture(pr,pg,pb,tactical and .95 or (modern and .52 or .88))
      row.track:SetHeight((modern or tactical) and 4 or 3)
      row.fill:SetHeight((modern or tactical) and 4 or 3)
      row.fill:SetColorTexture(row.done and .44 or ar,row.done and .78 or ag,row.done and .48 or ab,modern and .88 or 1)
    end
  end
end

function Q:BuildTrackerRows()
  local o=self:TrackerOptions()
  local items={}
  local entries=self.entries or self:Scan()
  local watched={}
  local watchesKnown=false
  if o.watchedOnly and C_QuestLog and C_QuestLog.GetNumQuestWatches and C_QuestLog.GetQuestIDForQuestWatchIndex then
    local ok,n=pcall(C_QuestLog.GetNumQuestWatches)
    if ok and isReadable(n) and type(n)=='number' then
      watchesKnown=true
      for i=1,min(n,50) do
        local good,id=pcall(C_QuestLog.GetQuestIDForQuestWatchIndex,i)
        if good and isReadable(id) and type(id)=='number' then watched[id]=true end
      end
    end
  end
  local groups,ordered={},{}
  local questCount=0
  local campaignKey='CAMPAIGN'
  local readyKey='READY TO TURN IN'
  local eligible={}
  local originalOrder={}
  for i,quest in ipairs(entries) do
    originalOrder[quest]=i
    local include=(not o.watchedOnly or not watchesKnown or watched[quest.id]) and (o.showCompleted or not quest.complete)
    if include then eligible[#eligible+1]=quest end
  end
  -- Prioritize the quest the user is actively navigating to. Otherwise a
  -- quest later in the log could disappear when maxQuests truncates the list.
  table.sort(eligible,function(a,b)
    if a.id==o.navigationQuestID then return true end
    if b.id==o.navigationQuestID then return false end
    if o.campaignFirst and (a.campaign==true)~=(b.campaign==true) then return a.campaign==true end
    if o.readyLast and (a.complete==true)~=(b.complete==true) then return b.complete==true end
    return originalOrder[a]<originalOrder[b] -- stable order within each class
  end)
  for _,quest in ipairs(eligible) do
    if questCount<o.maxQuests then
      -- Campaign is only assigned when Forever explicitly identifies the
      -- quest as campaign content. Other quests never get guessed into it.
      local zone
      if o.campaignFirst and quest.campaign then zone=campaignKey
      elseif o.readyLast and quest.complete then zone=readyKey
      else zone=(o.groupZones and quest.zone) or 'QUESTS' end
      if type(zone)~='string' or zone=='' then zone='OTHER QUESTS' end
      if not groups[zone] then groups[zone]={};ordered[#ordered+1]=zone end
      groups[zone][#groups[zone]+1]=quest
      questCount=questCount+1
    end
  end
  -- Pin campaign first, and completed/ready quests last, regardless of zone sort.
  table.sort(ordered,function(a,b)
    if a==campaignKey then return true end
    if b==campaignKey then return false end
    if a==readyKey then return false end
    if b==readyKey then return true end
    return a<b
  end)
  for _,zone in ipairs(ordered) do
    local showHeader=o.groupZones or zone==campaignKey or zone==readyKey
    if showHeader then
      local badge=(zone==campaignKey and '★  ' or zone==readyKey and '✓  ' or '')
      items[#items+1]={kind='zone',text=(o.collapsedZones[zone] and '+  ' or '-  ')..badge..zone:upper(),info=tostring(#groups[zone]),zone=zone}
    end
    if not (showHeader and o.collapsedZones[zone]) then
      for _,quest in ipairs(groups[zone]) do
        local objectives=self:Objectives(quest)
        local completed=0
        for _,obj in ipairs(objectives) do if obj.done then completed=completed+1 end end
        local level=(o.showLevels and quest.level and '['..quest.level..'] ' or '')
        local folded=o.collapsedQuests[quest.id]
        local selected=(o.navigationQuestID==quest.id)
        items[#items+1]={kind='quest',text=(selected and '> ' or folded and '+ ' or '')..level..quest.title,
          info=(quest.complete and 'TURN IN' or (#objectives>0 and (completed..'/'..#objectives) or '')),  
          questId=quest.id}
        if not folded and not quest.complete then
          for _,obj in ipairs(objectives) do
            local cur,req=safeProgress(obj)
            items[#items+1]={kind='objective',text=(obj.done and '✓ ' or '• ')..obj.text,
              done=obj.done,current=cur,required=req}
          end
        end
      end
    end
  end
  if #items==0 then items[1]={kind='empty',text='No quests to show. Check your tracker filters.'} end
  return items,questCount
end

function Q:RenderTracker()
  if not self.tracker or self.trackerResizing then return end
  local o=self:TrackerOptions()
  -- Questie owns the visible list in AUTO/QUESTIE mode. Never create a competing second list.
  if (self.UsingQuestieTracker and self:UsingQuestieTracker()) or not o.tracker or not WG:Enabled('wafflequests') then
    self.tracker:Hide()
    if self.trackerResizeGrip then self.trackerResizeGrip:Hide() end
    return
  end
  local items,count=self:BuildTrackerRows()
  local tactical=WG:StyleName()=='Tactical'
  local t=tactical and WG:TacticalSettings() or nil
  local adventure=WG:StyleName()=='Adventure'
  local plain=(tactical and t.questMinimal) or (adventure and WG:ExpeditionSettings().journalMinimal)
  local tracker,width=self.tracker,(tactical and t.questWidth or (adventure and math.min(o.width,325) or o.width))
  tracker:SetWidth(width)
  self.trackerContent:SetWidth(width-4)
  self.trackerHeaderTitle:SetText(WG:StyleName()=='Tactical' and (o.collapsed and '+  QUESTS' or 'QUESTS') or (adventure and (o.collapsed and '+  TRAIL JOURNAL' or 'TRAIL JOURNAL') or (o.collapsed and '+  WAFFLE QUESTS' or 'WAFFLE QUESTS')))
  self.trackerCount:SetText(tostring(count)..(WG:StyleName()=='Tactical' and ' ACTIVE' or ' QUESTS'))
  if self.trackerNavLabel then
    local id=o.navigationQuestID
    local title
    for _,q in ipairs(self.entries or {}) do
      if q.id==id then title=q.title;break end
    end
    if id and title then
      local route=self.navigationState or 'Click here to refresh the arrow'
      if route:find('no arrow',1,true) then
        self.trackerNavLabel:SetText('SELECTED: '..title..'  /  NO WAYPOINT')
      else
        self.trackerNavLabel:SetText(WG:StyleName()=='Tactical' and ('MISSION SELECTED  //  '..title) or ('NAVIGATING  /  '..title))
      end
    else
      self.trackerNavLabel:SetText(WG:StyleName()=='Tactical' and 'SELECT AN OBJECTIVE TO SET ACTIVE MISSION' or 'SELECT A QUEST BELOW TO NAVIGATE')
    end
  end
  if o.collapsed and not plain then
    if self.trackerNav then self.trackerNav:Hide() end
    self.trackerScroll:Hide()
    self.trackerFooter:Hide()
    tracker:SetHeight(40)
    tracker:Show()
    self:RepaintTracker()
    return
  end
  if self.trackerNav then self.trackerNav:SetShown(not plain) end
  self.trackerHeader:SetShown(not plain)
  self.trackerFooter:SetShown(not plain)
  self.trackerScroll:ClearAllPoints()
  if plain then
    self.trackerScroll:SetPoint('TOPLEFT',tracker,'TOPLEFT',0,0)
    self.trackerScroll:SetPoint('TOPRIGHT',tracker,'TOPRIGHT',0,0)
  else
    self.trackerScroll:SetPoint('TOPLEFT',self.trackerNav,'BOTTOMLEFT',-2,-3)
    self.trackerScroll:SetPoint('TOPRIGHT',self.trackerHeader,'BOTTOMRIGHT',0,-3)
  end
  local y=0
  local rowWidth=width-8
  for i,item in ipairs(items) do
    local row=self.trackerRows[i]
    if not row then row=self:NewTrackerRow();self.trackerRows[i]=row end
    row.kind=item.kind
    row.zone=item.zone
    row.questId=item.questId
    row.done=item.done
    row.hovered=false
    row:ClearAllPoints()
    row:SetPoint('TOPLEFT',self.trackerContent,'TOPLEFT',2,-y)
    row:SetWidth(rowWidth)
    row.label:SetWidth(rowWidth-(item.info and (plain and 54 or 71) or 15)-(plain and (item.kind=='objective' and 13 or 0) or 0))
    row.label:SetText(item.text)
    row.info:SetText(item.info or '')
    row:Show()
    local currentStyle=WG:StyleName()
    local baseSize=currentStyle=='Tactical' and WG:TacticalSettings().questFont or o.fontSize
    local fontSize=(currentStyle=='Modern' and max(13,baseSize) or baseSize)+(item.kind=='quest' and 1 or item.kind=='objective' and -1 or 0)
    setFont(row.label,fontSize)
    local lines=max(1,row.label:GetNumLines() or 1)
    -- Use explicit line-height rather than relying solely on WoW's sometimes-stale font-string heights.
    local height=plain and max(item.kind=='zone' and 20 or item.kind=='quest' and 21 or 16,
      lines*(fontSize+2)+(item.kind=='zone' and 5 or 3))
      or max(item.kind=='zone' and 22 or item.kind=='quest' and 25 or 19,
      lines*(fontSize+3)+(item.kind=='objective' and 6 or 9))
    local bars=(o.showBars and (not plain or (t and t.questProgressBars)))==true
    if item.kind=='objective' and bars and item.required then height=height+6 end
    row:SetHeight(height)
    row.mark:SetHeight(height)
    row.track:SetWidth(rowWidth-26)
    row.track:SetShown(item.kind=='objective' and bars and item.required~=nil)
    row.fill:SetShown(item.kind=='objective' and bars and item.required~=nil)
    if item.required and item.required>0 then row.fill:SetWidth(max(0,(rowWidth-26)*item.current/item.required)) end
    row:Show()
    y=y+height+(plain and 0 or (o.compact and 0 or 2))
  end
  for i=#items+1,#self.trackerRows do self.trackerRows[i]:Hide() end
  self.trackerContent:SetHeight(max(1,y))
  self.trackerScroll:SetHeight(o.autoHeight and min(max(24,y),o.maxHeight)
    or o.maxHeight)
  self.trackerScroll:Show()
  self.trackerScroll:SetVerticalScroll(clamp(self.trackerScroll:GetVerticalScroll(),0,max(0,y-self.trackerScroll:GetHeight())))
  local modern=WG:StyleName()=='Modern'
  self.trackerFooter:SetText((y>o.maxHeight and 'SCROLL  /  ' or '')..(WG:StyleName()=='Tactical' and 'LMB: SET MISSION  /  RMB: COLLAPSE' or 'CLICK QUEST: NAVIGATE     RIGHT CLICK: FOLD'))
  self.trackerFooter:SetShown(not plain)
  tracker:SetHeight(plain and self.trackerScroll:GetHeight() or (36+25+3+self.trackerScroll:GetHeight()+21))
  tracker:Show()
  self:RepaintTracker()
end

-- Existing WG:Refresh recolors only registered theme surfaces. Keep the new
-- tracker in sync whenever someone changes UI style or theme independently.
WG.surfaces[#WG.surfaces+1]={repaint=function()
  if Q.tracker then Q:RepaintTracker() end
end}
