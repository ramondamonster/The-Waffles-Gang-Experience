-- Waffles Gang Aura Studio: per-unit buff/debuff overlays, editable independently.
-- The WoW 12+ secret-value rules are observed: no filtering or calculations
-- based on protected aura identity, durations, or stack counts.
local WG=_G.WafflesGang
local A={name='Aura Studio',groups={'party','player','target','focus','raid'},selected='party',attached={}}
WG.auras=A
WG.modules[#WG.modules+1]=A
local defaults={
  party ={enabled=true,buffs=true,debuffs=true,buffCount=4,debuffCount=4,size=18,gap=2,side='RIGHT',tooltips=true,stacks=true},
  player={enabled=false,buffs=true,debuffs=true,buffCount=5,debuffCount=5,size=22,gap=2,side='BOTTOM',tooltips=true,stacks=true},
  target={enabled=false,buffs=true,debuffs=true,buffCount=5,debuffCount=5,size=22,gap=2,side='BOTTOM',tooltips=true,stacks=true},
  focus ={enabled=false,buffs=true,debuffs=true,buffCount=4,debuffCount=4,size=19,gap=2,side='RIGHT',tooltips=true,stacks=true},
  raid  ={enabled=false,buffs=false,debuffs=true,buffCount=2,debuffCount=3,size=14,gap=1,side='RIGHT',tooltips=true,stacks=false},
}
local function nonsecret(v) return not (issecretvalue and issecretvalue(v)) end
local function clamp(v,lo,hi) return math.max(lo,math.min(hi,v)) end
local function groupOf(unit)
  if unit:match('^party') then return 'party' end
  if unit:match('^raid') then return 'raid' end
  return unit
end
function A:Options(group)
  if not WG.db then return defaults[group] or defaults.party end
  if type(WG.db.auraStudio)~='table' then WG.db.auraStudio={} end
  local root=WG.db.auraStudio
  if type(root[group])~='table' then root[group]={} end
  local o=root[group]
  for k,v in pairs(defaults[group]) do if o[k]==nil then o[k]=v end end
  if o.blocked==nil then o.blocked='' end
  if o.onlyMine==nil then o.onlyMine=false end
  return o
end
local function newIcon(parent,unit,index,kind)
  local f=CreateFrame('Frame',nil,UIParent)
  f:SetSize(18,18);f:Hide()
  local edge=f:CreateTexture(nil,'BACKGROUND');edge:SetAllPoints()
  if kind=='HARMFUL' then edge:SetColorTexture(.65,.12,.15,.9)
  else edge:SetColorTexture(.28,.55,.3,.85) end
  local texture=f:CreateTexture(nil,'ARTWORK')
  texture:SetPoint('TOPLEFT',f,'TOPLEFT',2,-2)
  texture:SetPoint('BOTTOMRIGHT',f,'BOTTOMRIGHT',-2,2)
  texture:SetTexture('Interface\\Icons\\INV_Misc_QuestionMark')
  local stacks=f:CreateFontString(nil,'OVERLAY','GameFontNormalSmall')
  stacks:SetPoint('BOTTOMRIGHT',f,'BOTTOMRIGHT',1,-1)
  stacks:SetFont(STANDARD_TEXT_FONT or 'Fonts\\FRIZQT__.TTF',10,'OUTLINE')
  stacks:SetTextColor(1,1,1)
  f:EnableMouse(true)
  f:SetScript('OnEnter',function()
    local o=A:Options(groupOf(unit))
    if not o.tooltips or not GameTooltip then return end
    GameTooltip:SetOwner(f,'ANCHOR_RIGHT')
    if GameTooltip.SetUnitAura then
      pcall(GameTooltip.SetUnitAura,GameTooltip,unit,index,kind)
    elseif kind=='HELPFUL' and GameTooltip.SetUnitBuff then
      pcall(GameTooltip.SetUnitBuff,GameTooltip,unit,index)
    elseif kind=='HARMFUL' and GameTooltip.SetUnitDebuff then
      pcall(GameTooltip.SetUnitDebuff,GameTooltip,unit,index)
    end
    GameTooltip:Show()
  end)
  f:SetScript('OnLeave',function()if GameTooltip then GameTooltip:Hide()end end)
  return {frame=f,texture=texture,stack=stacks,kind=kind,index=index}
end
function A:Attach(p)
  if not p or self.attached[p.unit] then return end
  local group=groupOf(p.unit)
  local o=self:Options(group)
  if group=='raid' and not o.enabled then return end
  local r={unit=p.unit,unitFrame=p.button,buffs={},debuffs={}}
  for i=1,(group=='raid' and 5 or 10) do
    r.buffs[i]=newIcon(p.button,p.unit,i,'HELPFUL')
    r.debuffs[i]=newIcon(p.button,p.unit,i,'HARMFUL')
  end
  self.attached[p.unit]=r
  self:Layout(r)
end
function A:Layout(r)
  if WG:Protected() then return end
  local group=groupOf(r.unit);local o=self:Options(group)
  local size=clamp(tonumber(o.size) or 18,12,32)
  local gap=clamp(tonumber(o.gap) or 2,0,10)
  local mx=(group=='raid') and 5 or 10
  local activeBuff=math.min(clamp(tonumber(o.buffCount) or 0,0,10),mx)
  local activeDebuff=math.min(clamp(tonumber(o.debuffCount) or 0,0,10),mx)
  for _,entry in ipairs({{r.buffs,activeBuff,1},{r.debuffs,activeDebuff,2}}) do
    local collection,count,line=entry[1],entry[2],entry[3]
    for i,icon in ipairs(collection) do
      icon.frame:ClearAllPoints();icon.frame:SetSize(size,size)
      if o.side=='BOTTOM' then
        icon.frame:SetPoint('TOPLEFT',r.unitFrame,'BOTTOMLEFT',(i-1)*(size+gap)+2,-(line-1)*(size+gap)-3)
      else
        icon.frame:SetPoint('TOPLEFT',r.unitFrame,'TOPRIGHT',6+(i-1)*(size+gap),-(line-1)*(size+gap))
      end
      if i>count then icon.frame:Hide() end
    end
  end
end
-- Return the aura record. Do not derive data from protected fields in Lua.
function A:Data(unit,index,filter)
  if C_UnitAuras and C_UnitAuras.GetAuraDataByIndex then
    local ok,data=pcall(C_UnitAuras.GetAuraDataByIndex,unit,index,filter)
    if ok then return data end
  elseif UnitAura then
    local ok,name,icon,count=pcall(UnitAura,unit,index,filter)
    if ok and name and nonsecret(name) then
      return {name=name,icon=icon,applications=count}
    end
  end
  return nil
end
function A:UpdateOne(r)
  local group=groupOf(r.unit);local o=self:Options(group)
  local exists=UnitExists and UnitExists(r.unit)
  local shown=(not r.unitFrame.IsShown) or r.unitFrame:IsShown()
  if not WG:Enabled('auras') or not o.enabled or not exists or not shown then
    for _,icon in ipairs(r.buffs) do icon.frame:Hide() end
    for _,icon in ipairs(r.debuffs) do icon.frame:Hide() end
    return
  end
  local cap=(group=='raid') and 5 or 10
  for _,which in ipairs({{'buffs','buffCount','HELPFUL'},{'debuffs','debuffCount','HARMFUL'}}) do
    local icons,limitKey,kind=r[which[1]],which[2],which[3]
    local limit=o[which[1]] and math.min(cap,clamp(tonumber(o[limitKey]) or 0,0,10)) or 0
    for i,view in ipairs(icons) do
      if i<=limit then
        local data=self:Data(r.unit,i,kind)
        local blocked=false
        if data and type(o.blocked)=='string' and o.blocked~='' and nonsecret(data.spellId) and type(data.spellId)=='number' then
          for number in o.blocked:gmatch('%d+') do
            if tonumber(number)==data.spellId then blocked=true;break end
          end
        end
        if data and o.onlyMine and nonsecret(data.isFromPlayerOrPlayerPet) and
           data.isFromPlayerOrPlayerPet==false then
          blocked=true
        end
        if data and not blocked then
          -- Accept native protected icon data only through native widget setters.
          -- If the client rejects it, use the generic aura artwork instead.
          local ok=pcall(view.texture.SetTexture,view.texture,data.icon)
          if not ok then view.texture:SetTexture('Interface\\Icons\\INV_Misc_QuestionMark') end
          view.stack:SetText('')
          if o.stacks and nonsecret(data.applications) and type(data.applications)=='number' and data.applications>1 then
            view.stack:SetText(data.applications)
          end
          view.frame:Show()
        else view.frame:Hide() end
      else view.frame:Hide() end
    end
  end
end
function A:Update(unit)
  if unit then
    local r=self.attached[unit];if r then self:UpdateOne(r) end
  else for _,r in pairs(self.attached) do self:UpdateOne(r) end end
end
function A:Prepare()
  if not WG.db then return end
  local unitMod=nil
  for _,mod in ipairs(WG.modules) do if mod.byUnit and mod.units then unitMod=mod;break end end
  if not unitMod then return end
  for _,p in ipairs(unitMod.units) do self:Attach(p) end
end
function A:MakeOptions()
  local f=WG:Window('auras','Aura Studio: Buffs & Debuffs',592,744)
  self.config=f
  WG:Text(f,'CONFIGURE BY FRAME TYPE',25,-84,15,'accent')
  WG:Text(f,'Change each frame independently. Other addons remain available.',25,-108,11,'text',541)
  self.groupButtons={}
  for i,key in ipairs(self.groups) do
    local b=WG:Button(f,key:upper(),24+(i-1)*112,-140,104,33,function()
      A.selected=key;A:SyncControls()
    end)
    self.groupButtons[key]=b
  end
  WG:Divider(f,-178,540,23)
  self.controls={}
  local function optButton(key,x,y,w,fn)
    self.controls[key]=WG:Button(f,'',x,y,w,34,function()
      fn(A:Options(A.selected));A:Refresh();A:SyncControls()
    end)
  end
  optButton('enabled',25,-211,260,function(o)o.enabled=not o.enabled end)
  optButton('side',301,-211,261,function(o)o.side=o.side=='RIGHT' and 'BOTTOM' or 'RIGHT' end)
  optButton('buffs',25,-253,260,function(o)o.buffs=not o.buffs end)
  optButton('debuffs',301,-253,261,function(o)o.debuffs=not o.debuffs end)
  optButton('bminus',25,-313,125,function(o)o.buffCount=clamp(o.buffCount-1,0,10)end)
  optButton('bplus',160,-313,125,function(o)o.buffCount=clamp(o.buffCount+1,0,10)end)
  optButton('dminus',301,-313,125,function(o)o.debuffCount=clamp(o.debuffCount-1,0,10)end)
  optButton('dplus',436,-313,125,function(o)o.debuffCount=clamp(o.debuffCount+1,0,10)end)
  optButton('sminus',25,-366,125,function(o)o.size=clamp(o.size-2,12,32)end)
  optButton('splus',160,-366,125,function(o)o.size=clamp(o.size+2,12,32)end)
  optButton('gminus',301,-366,125,function(o)o.gap=clamp(o.gap-1,0,10)end)
  optButton('gplus',436,-366,125,function(o)o.gap=clamp(o.gap+1,0,10)end)
  optButton('tip',25,-420,260,function(o)o.tooltips=not o.tooltips end)
  optButton('stack',301,-420,261,function(o)o.stacks=not o.stacks end)
  WG:Text(f,'RIGHT: two horizontal aura rows beside frame.',25,-482,11,'text',533)
  WG:Text(f,'BOTTOM: two horizontal aura rows below frame.',25,-502,11,'text',533)
  WG:Text(f,'Raid auras are OFF by default. Turning them on may affect FPS.',25,-524,11,'text',537)
  WG:Text(f,'Secret combat data may hide counts/tooltips on this client.',25,-544,11,'text',537)
  WG:Text(f,'BLOCK SPELL IDS (COMMA SEPARATED; ADVANCED)',25,-564,11,'accent',535)
  local edit=CreateFrame('EditBox',nil,f,'InputBoxTemplate')
  edit:SetSize(465,28);edit:SetPoint('TOPLEFT',f,'TOPLEFT',38,-589)
  edit:SetAutoFocus(false);edit:SetMaxLetters(160)
  edit:SetScript('OnEscapePressed',function(self)self:ClearFocus()end)
  self.blockEdit=edit
  local function saveBlock()
    local value=edit:GetText() or ''
    local parts={};local found={}
    for spell in value:gmatch('%d+') do
      if not found[spell] and #parts<35 then found[spell]=true;parts[#parts+1]=spell end
    end
    A:Options(A.selected).blocked=table.concat(parts,',')
    edit:ClearFocus();A:Refresh()
  end
  edit:SetScript('OnEnterPressed',saveBlock)
  WG:Button(f,'SAVE BLOCK LIST',25,-629,255,32,saveBlock)
  self.mineButton=WG:Button(f,'',300,-629,262,32,function()
    local o=A:Options(A.selected);o.onlyMine=not o.onlyMine;A:Refresh()
  end)
  WG:Button(f,'REFRESH AURA DISPLAY',25,-683,539,34,function()A:Refresh()end)
  f.onOpen=function()A:SyncControls()end
end
function A:SyncControls()
  if not self.controls then return end
  local o=self:Options(self.selected);local c=self.controls
  for key,b in pairs(self.groupButtons) do b.label:SetText((key==self.selected and '[ ' or '')..key:upper()..(key==self.selected and ' ]' or '')) end
  c.enabled.label:SetText('Display: '..(o.enabled and 'ON' or 'OFF'))
  c.side.label:SetText('Placement: '..o.side)
  c.buffs.label:SetText('Buffs: '..(o.buffs and 'ON' or 'OFF'))
  c.debuffs.label:SetText('Debuffs: '..(o.debuffs and 'ON' or 'OFF'))
  c.bminus.label:SetText('BUFFS -');c.bplus.label:SetText('BUFFS + ('..o.buffCount..')')
  c.dminus.label:SetText('DEBUFFS -');c.dplus.label:SetText('DEBUFFS + ('..o.debuffCount..')')
  c.sminus.label:SetText('SIZE -');c.splus.label:SetText('SIZE + ('..o.size..')')
  c.gminus.label:SetText('GAP -');c.gplus.label:SetText('GAP + ('..o.gap..')')
  c.tip.label:SetText('Tooltips: '..(o.tooltips and 'ON' or 'OFF'))
  c.stack.label:SetText('Stack counts: '..(o.stacks and 'ON' or 'OFF'))
  if self.blockEdit and not self.blockEdit:HasFocus() then self.blockEdit:SetText(o.blocked or '') end
  if self.mineButton then self.mineButton.label:SetText('Only my auras: '..(o.onlyMine and 'ON' or 'OFF')) end
end
function A:Init()
  for _,group in ipairs(self.groups) do self:Options(group) end
  self:Prepare();self:MakeOptions()
  WG:On('UNIT_AURA',function(unit)A:Update(unit)end)
  for _,event in ipairs({'GROUP_ROSTER_UPDATE','PLAYER_TARGET_CHANGED','PLAYER_FOCUS_CHANGED'}) do
    WG:On(event,function()A:Update()end)
  end
  WG:On('PLAYER_REGEN_ENABLED',function()A:Refresh()end)
  WG:On('PLAYER_ENTERING_WORLD',function()A:Refresh()end)
end
function A:Refresh()
  if not WG.db then return end
  if not WG:Protected() then
    self:Prepare()
    for _,r in pairs(self.attached) do self:Layout(r) end
  end
  self:Update();self:SyncControls()
end
