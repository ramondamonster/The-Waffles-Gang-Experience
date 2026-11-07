-- Waffles Gang: professions are personal data; guild members participate only if
-- they choose to share. Guild roster APIs do NOT reveal other players' recipes.
local WG=_G.WafflesGang
local P={name='Guild Professions',rows={},selected=nil,prefix='WaffleProf1',lastRequest=0,lastReply=0}
WG.guildProfessions=P
table.insert(WG.modules,P)
local function pname()
  local name=GetUnitName and GetUnitName('player',true)
  if not name and UnitName then name=UnitName('player') end
  return name or 'Player'
end
local function safeName(name)
  if type(name)~='string' then return '' end
  return name:gsub('[|\n\r;]',''):sub(1,60)
end
local function send(message,kind,target)
  if not IsInGuild or not IsInGuild() then return false end
  if not P.registered then return false end
  if #message>235 then return false end
  local f=(C_ChatInfo and C_ChatInfo.SendAddonMessage) or SendAddonMessage
  if not f then return false end
  local ok,ret=pcall(f,P.prefix,message,kind or 'GUILD',target)
  return ok and ret~=false and ret~=3
end
local function mine()
  local key=pname()
  WG.db.guildProfessionCache[key]=WG.db.guildProfessionCache[key] or {}
  local m=WG.db.guildProfessionCache[key]
  m.professions=m.professions or {};m.recipes=m.recipes or {}
  return m
end
function P:ScanSelf()
  local m=mine()
  m.professions={}
  if GetProfessions and GetProfessionInfo then
    local indices={GetProfessions()}
    for _,index in pairs(indices) do
      if type(index)=='number' then
        local ok,name,_,level,maxLevel=pcall(GetProfessionInfo,index)
        if ok and type(name)=='string' and name~='' then
          m.professions[#m.professions+1]={name=safeName(name),level=type(level)=='number' and level or 0,max=type(maxLevel)=='number' and maxLevel or 0}
        end
      end
    end
  end
  m.updated=time and time() or 0
  self:ScanOpenRecipes()
  self:Update()
end
function P:ScanOpenRecipes()
  if not C_TradeSkillUI or not C_TradeSkillUI.GetAllRecipeIDs or not C_TradeSkillUI.GetRecipeInfo then return false end
  local line,profession
  if C_TradeSkillUI.GetTradeSkillLine then
    local ok,a,b,_,_,_,_,parent=pcall(C_TradeSkillUI.GetTradeSkillLine)
    if ok then line=a;profession=parent or b end
  end
  if not line then return false end
  local ok,all=pcall(C_TradeSkillUI.GetAllRecipeIDs)
  if not ok or type(all)~='table' then return false end
  local m=mine()
  local known={}
  for _,id in ipairs(all) do
    if type(id)=='number' then
      local good,info=pcall(C_TradeSkillUI.GetRecipeInfo,id)
      if good and info and info.learned==true then
        known[#known+1]={id=id,name=safeName(info.name or tostring(id))}
      end
    end
  end
  table.sort(known,function(a,b) return a.name<b.name end)
  m.recipes[safeName(profession or tostring(line))]=known
  m.updated=time and time() or 0
  return true
end
function P:SendSummary()
  if not WG:Enabled('shareprofessions') then return end
  local m=mine()
  local parts={}
  for _,prof in ipairs(m.professions or {}) do
    parts[#parts+1]=('%s,%d,%d'):format(safeName(prof.name),prof.level or 0,prof.max or 0)
  end
  send('P|'..table.concat(parts,';'),'GUILD')
end
function P:RequestGuild()
  if not IsInGuild or not IsInGuild() then return WG:Say('You must be in a guild.') end
  local now=GetTime and GetTime() or 0
  if now-self.lastRequest<15 then return WG:Say('Guild scan can be requested every 15 seconds.') end
  self.lastRequest=now
  self:ScanSelf()
  send('Q','GUILD')
  WG:Say('Guild profession request sent. Only guildmates with Waffles Gang sharing enabled will reply.')
end
function P:SendRecipes()
  if not WG:Enabled('shareprofessions') then return WG:Say('Enable Share My Professions first.') end
  local m=mine()
  local chunks=0
  for prof,recipes in pairs(m.recipes or {}) do
    local name=safeName(prof)
    local part=1
    for first=1,#recipes,25 do
      if chunks>=4 then break end
      local ids={}
      for i=first,math.min(first+24,#recipes) do
        local id=recipes[i].id
        if type(id)=='number' then ids[#ids+1]=tostring(id) end
      end
      if #ids>0 then
        if send(('R|%s|%d|%s'):format(name,part,table.concat(ids,',')),'GUILD') then chunks=chunks+1 end
      end
      part=part+1
    end
    if chunks>=4 then break end
  end
  WG:Say(('Shared %d recipe batches (up to 100 IDs) from opened professions.'):format(chunks))
end
function P:ReadMessage(prefix,msg,channel,sender)
  if prefix~=self.prefix or channel~='GUILD' or type(msg)~='string' or type(sender)~='string' then return end
  if not IsInGuild or not IsInGuild() then return end
  if msg=='Q' then
    if WG:Enabled('shareprofessions') then
      local now=GetTime and GetTime() or 0
      if now-self.lastReply>=12 then
        self.lastReply=now
        self:ScanSelf()
        -- Respond to guild scan without a broadcast storm at log-in.
        if C_Timer and C_Timer.After then C_Timer.After(1.5,function()P:SendSummary()end)
        else self:SendSummary() end
      end
    end
    return
  end
  -- Accept self-declared reports only from guild characters we have seen in
  -- the roster, when available. Remote data is never used as executable Lua.
  local roster=WG.guildManager and WG.guildManager.roster
  if roster and #roster>0 then
    local found=false
    local short=sender:gsub('%-.*$','')
    for _,member in ipairs(roster) do
      if member.name==sender or member.name:gsub('%-.*$','')==short then found=true break end
    end
    if not found and sender~=pname() then return end
  end
  local cache=WG.db.guildProfessionCache
  local m=cache[sender] or {professions={},recipes={}}
  cache[sender]=m
  if msg:sub(1,2)=='P|' then
    m.professions={}
    for part in msg:sub(3):gmatch('[^;]+') do
      local n,l,max=part:match('^([^,]+),(%d+),(%d+)$')
      if n and #m.professions<8 then
        m.professions[#m.professions+1]={name=safeName(n),level=tonumber(l),max=tonumber(max)}
      end
    end
    m.updated=time and time() or 0
  elseif msg:sub(1,2)=='R|' then
    local profession,piece,raw=msg:match('^R|([^|]+)|(%d+)|([%d,]+)$')
    if not profession or #profession>60 then return end
    m.recipes=m.recipes or {}
    profession=safeName(profession)
    if piece=='1' then m.recipes[profession]={} end
    m.recipes[profession]=m.recipes[profession] or {}
    for id in raw:gmatch('%d+') do
      if #m.recipes[profession]>=100 then break end
      local display
      if C_Spell and C_Spell.GetSpellName then
        local ok,n=pcall(C_Spell.GetSpellName,tonumber(id));if ok then display=n end
      end
      m.recipes[profession][#m.recipes[profession]+1]={id=tonumber(id),name=safeName(display or 'Recipe #'..id)}
    end
    m.updated=time and time() or 0
  end
  if self.window and self.window:IsShown() then self:Update() end
end
function P:Update()
  if not self.window then return end
  local cache=WG.db.guildProfessionCache or {}
  local keys={}
  for name in pairs(cache) do keys[#keys+1]=name end
  table.sort(keys)
  local visible={}
  local q=(self.query or ''):lower()
  for _,name in ipairs(keys) do
    local found=q=='' or name:lower():find(q,1,true)~=nil
    if not found then
      for _,prof in ipairs((cache[name] or {}).professions or {}) do
        if (prof.name or ''):lower():find(q,1,true) then found=true break end
      end
    end
    if found then visible[#visible+1]=name end
  end
  self.page=math.max(1,math.min(self.page or 1,math.max(1,math.ceil(#visible/10))))
  if self.pageLabel then self.pageLabel:SetText(('PAGE %d / %d'):format(self.page,math.max(1,math.ceil(#visible/10)))) end
  if not self.selected or not cache[self.selected] then self.selected=pname() end
  self.status:SetText('Guild members with data: '..#keys..'  •  Others must install Waffles Gang and opt in.')
  for i,row in ipairs(self.rows) do
    local name=visible[(self.page-1)*10+i]
    if name then
      local m=cache[name] or {}
      local profs={}
      for _,prof in ipairs(m.professions or {}) do
        profs[#profs+1]=prof.name..' '..(prof.level or 0)..'/'..(prof.max or 0)
      end
      row.label:SetText(name..'  |  '..(#profs>0 and table.concat(profs,', ') or 'No profession data'))
      row.member=name
      row:Show()
    else row:Hide() end
  end
  self.share:SetChecked(WG:Enabled('shareprofessions'))
  local selected=cache[self.selected]
  local recipes={}
  if selected then
    for prof,items in pairs(selected.recipes or {}) do
      recipes[#recipes+1]=prof..' ('..#items..' known recipes cached)'
      for i=1,#items do
        local name=items[i].name or tostring(items[i].id)
        local recipeQuery=(self.recipeQuery or ''):lower()
        if recipeQuery=='' or name:lower():find(recipeQuery,1,true) then
          recipes[#recipes+1]='  '..name
        end
      end
    end
  end
  self.recipeTitle:SetText('RECIPES: '..(self.selected or '-'))
  self.recipeDetails:SetText(#recipes>0 and table.concat(recipes,'\n') or 'Open your profession window and press SCAN SELF.\nOther members must explicitly share their recipes.')
  if self.recipeContent then self.recipeContent:SetHeight(math.max(100,#recipes*17+28)) end
end
function P:Init()
  local f=WG:Window('professions','Guild Professions & Recipes',820,800)
  self.window=f
  WG:Text(f,'PROFESSION DIRECTORY  /  OPT-IN GUILD DATA',22,-80,14,'accent')
  self.status=WG:Text(f,'',22,-108,11,'text',780)
  WG:Button(f,'SCAN MY PROFESSIONS',22,-141,185,36,function()
    P:ScanSelf();WG:Say('Your current professions scanned. Open a crafting profession to scan known recipes.')
  end)
  WG:Button(f,'ASK GUILD',214,-141,150,36,function()P:RequestGuild()end)
  WG:Button(f,'SHARE MY RECIPES',371,-141,177,36,function()P:ScanOpenRecipes();P:SendRecipes()end)
  WG:Button(f,'REFRESH',555,-141,237,36,function()P:Update()end)
  self.share=CreateFrame('CheckButton',nil,f,'UICheckButtonTemplate')
  self.share:SetSize(24,24);self.share:SetPoint('TOPLEFT',f,'TOPLEFT',24,-186)
  WG:Text(f,'Allow other Waffles Gang guildmates to request my professions (OFF by default)',56,-190,11,'text',715)
  self.share:SetScript('OnClick',function(self)WG:Feature('shareprofessions',self:GetChecked())end)
  WG:Text(f,'FIND MEMBER',23,-231,10,'accent')
  local find=CreateFrame('EditBox',nil,f,'InputBoxTemplate')
  find:SetSize(259,27);find:SetPoint('TOPLEFT',f,'TOPLEFT',113,-221)
  find:SetAutoFocus(false)
  find:SetScript('OnTextChanged',function(self)
    P.query=(self:GetText() or ''):lower();P.page=1;P:Update()
  end)
  find:SetScript('OnEscapePressed',function(self)self:ClearFocus()end)
  WG:Button(f,'PREV',411,-220,87,29,function()P.page=math.max(1,(P.page or 1)-1);P:Update()end)
  WG:Button(f,'NEXT',507,-220,87,29,function()P.page=(P.page or 1)+1;P:Update()end)
  self.pageLabel=WG:Text(f,'PAGE 1 / 1',621,-227,11,'accent')
  WG:Divider(f,-258,770,22)
  self.rows={}
  for i=1,10 do
    local row=WG:Button(f,'',24,-275-(i-1)*29,772,27,function()
      local member=P.rows[i].member
      if member then P.selected=member;P:Update() end
    end)
    row.label:SetJustifyH('LEFT');row.label:ClearAllPoints();row.label:SetPoint('LEFT',row,'LEFT',8,0)
    row.label:SetWidth(755)
    self.rows[i]=row
  end
  WG:Divider(f,-571,768,22)
  self.recipeTitle=WG:Text(f,'RECIPES',23,-590,11,'accent')
  WG:Text(f,'FILTER RECIPES',410,-590,10,'accent')
  local rf=CreateFrame('EditBox',nil,f,'InputBoxTemplate')
  rf:SetSize(245,27);rf:SetPoint('TOPLEFT',f,'TOPLEFT',516,-583)
  rf:SetAutoFocus(false)
  rf:SetScript('OnTextChanged',function(self)P.recipeQuery=(self:GetText() or ''):lower();P:Update()end)
  rf:SetScript('OnEscapePressed',function(self)self:ClearFocus()end)
  self.recipeSearch=rf
  local scroll=CreateFrame('ScrollFrame',nil,f,'UIPanelScrollFrameTemplate')
  scroll:SetPoint('TOPLEFT',f,'TOPLEFT',23,-623)
  scroll:SetPoint('BOTTOMRIGHT',f,'BOTTOMRIGHT',-35,22)
  local inside=CreateFrame('Frame',nil,scroll)
  inside:SetSize(745,120);scroll:SetScrollChild(inside)
  self.recipeContent=inside
  self.recipeDetails=WG:Text(inside,'',2,-5,10,'text',724)
  f.onOpen=function()P:ScanSelf();P:Update()end
  WG:On('CHAT_MSG_ADDON',function(prefix,msg,channel,sender)P:ReadMessage(prefix,msg,channel,sender)end)
  WG:On('TRADE_SKILL_SHOW',function()P:ScanOpenRecipes();P:Update()end)
  WG:On('TRADE_SKILL_UPDATE',function()P:ScanOpenRecipes();P:Update()end)
  WG:On('GUILD_ROSTER_UPDATE',function()if f:IsShown() then P:Update()end end)
  local register=(C_ChatInfo and C_ChatInfo.RegisterAddonMessagePrefix) or RegisterAddonMessagePrefix
  if type(register)=='function' then
    local ok,ret=pcall(register,self.prefix)
    self.registered=ok and ret~=false and ret~=2 and ret~=3
  end
end
function P:Refresh()
  if self.window and not WG:Enabled('guildprofessions') then self.window:Hide() end
  if self.window and self.window:IsShown() then self:Update() end
end
