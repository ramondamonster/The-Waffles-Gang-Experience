-- Waffles Gang chat skin: cosmetic only, never replaces Blizzard chat input or routing.
local WG=_G.WafflesGang
local Chat={name='Chat Theme',skins={}}
table.insert(WG.modules,Chat)

local function color(c,alpha)
  return c[1],c[2],c[3],alpha or 1
end
local function rectangle(frame,layer,sublevel)
  local t=frame:CreateTexture(nil,layer or 'BACKGROUND',nil,sublevel)
  return t
end
local function trim(parent, edge, thickness)
  local t={}
  for i=1,4 do
    t[i]=rectangle(parent,'BORDER',1)
  end
  t[1]:SetPoint('TOPLEFT',parent,'TOPLEFT',0,0)
  t[1]:SetPoint('TOPRIGHT',parent,'TOPRIGHT',0,0)
  t[1]:SetHeight(thickness)
  t[2]:SetPoint('BOTTOMLEFT',parent,'BOTTOMLEFT',0,0)
  t[2]:SetPoint('BOTTOMRIGHT',parent,'BOTTOMRIGHT',0,0)
  t[2]:SetHeight(thickness)
  t[3]:SetPoint('TOPLEFT',parent,'TOPLEFT',0,0)
  t[3]:SetPoint('BOTTOMLEFT',parent,'BOTTOMLEFT',0,0)
  t[3]:SetWidth(thickness)
  t[4]:SetPoint('TOPRIGHT',parent,'TOPRIGHT',0,0)
  t[4]:SetPoint('BOTTOMRIGHT',parent,'BOTTOMRIGHT',0,0)
  t[4]:SetWidth(thickness)
  return t
end
function Chat:MakeSkin(host,withLogo)
  if not host or not host.CreateTexture then return end
  local skin={host=host,lines={}}
  skin.back=rectangle(host,'BACKGROUND',-7)
  skin.back:SetAllPoints(host)
  skin.lines=trim(host,nil,2)
  skin.foot=rectangle(host,'BORDER',2)
  skin.foot:SetPoint('BOTTOMLEFT',host,'BOTTOMLEFT',3,3)
  skin.foot:SetPoint('BOTTOMRIGHT',host,'BOTTOMRIGHT',-3,3)
  skin.foot:SetHeight(3)
  skin.marker=rectangle(host,'OVERLAY',1)
  skin.marker:SetSize(40,3)
  skin.marker:SetPoint('TOPLEFT',host,'TOPLEFT',4,-4)
  skin.rose=rectangle(host,'ARTWORK',0)
  skin.rose:SetTexture('Interface\\AddOns\\WafflesGang\\Media\\Adventure\\CompassRose')
  skin.rose:SetSize(46,46)
  skin.rose:SetPoint('BOTTOMRIGHT',host,'BOTTOMRIGHT',-11,9)
  skin.tag=host:CreateFontString(nil,'OVERLAY','GameFontNormalSmall')
  skin.tag:SetPoint('TOPRIGHT',host,'TOPRIGHT',-9,11)
  skin.tag:SetJustifyH('RIGHT')
  skin.tag:SetWidth(240)
  skin.tag:SetFont(STANDARD_TEXT_FONT or 'Fonts\\FRIZQT__.TTF',9,'')
  skin.modernRound=WG.ModernRounded and WG:ModernRounded(host,'SoftPanel') or nil
  skin.modernEdge=WG.ModernRounded and WG:ModernRounded(host,'SoftOutline') or nil
  skin.tacticalPlate=WG.TacticalPlate and WG:TacticalPlate(host) or nil
  skin.tacticalEdge=WG.TacticalPlate and WG:TacticalPlate(host,'PlateBorder') or nil
  if withLogo then
    skin.logo=WG:Logo(host,25,'RIGHT',host,'LEFT',-8,0)
  end
  self.skins[#self.skins+1]=skin
  return skin
end
function Chat:Setup()
  if not self.messageSkin and ChatFrame1 then
    self.messageSkin=self:MakeSkin(ChatFrame1,false)
  end
  local edit=_G.ChatFrame1EditBox or _G.ChatFrameEditBox
  if not self.inputSkin and edit then
    self.inputSkin=self:MakeSkin(edit,true)
  end
  self:Refresh()
end
function Chat:Refresh()
  if not WG.db then return end
  local modern=WG:StyleName()=='Modern'
  local tactical=WG:StyleName()=='Tactical'
  local adventure=WG:StyleName()=='Adventure'
  local enabled=WG:Enabled('chatstyle') or modern or tactical or adventure
  local bg=WG:Color('bg')
  local edge=WG:Color('edge')
  local gold=WG:Color('accent')
  local modernOpts=WG.db.modernHUD or {}
  local chatOpacity=math.max(.12,math.min(.85,tonumber(modernOpts.chatOpacity) or .39))
  local tacticalOpacity=tactical and WG:TacticalSettings().chatOpacity or .72
  local adventureOpacity=adventure and WG:ExpeditionSettings().chatOpacity or .64
  for _,skin in ipairs(self.skins) do
    -- ColorTextures are owned by the existing Blizzard chat frames, so typing,
    -- tabs, hyperlinks, copy, chat history and message visibility stay native.
    skin.back:SetColorTexture(color(bg,(modern or tactical) and 0 or (adventure and (skin==self.inputSkin and .85 or adventureOpacity) or (skin==self.inputSkin and .96 or .72))))
    if skin.tacticalPlate then
      skin.tacticalPlate:SetShown(tactical)
      skin.tacticalEdge:SetShown(tactical)
      if tactical then
        skin.tacticalPlate:SetColor(bg[1],bg[2],bg[3],skin==self.inputSkin and .96 or tacticalOpacity)
        skin.tacticalEdge:SetColor(gold[1],gold[2],gold[3],.39)
      end
    end
    skin.back:SetShown(enabled and not modern)
    local style=WG:StyleName()
    skin.marker:SetShown(enabled)
    skin.marker:SetColorTexture(gold[1],gold[2],gold[3],.95)
    skin.marker:SetWidth(style=='Tactical' and 27 or (style=='Modern' and 55 or (style=='Adventure' and 67 or 40)))
    skin.foot:SetShown(enabled)
    skin.foot:SetColorTexture(edge[1],edge[2],edge[3],style=='Adventure' and .52 or (style=='Modern' and .35 or .7))
    skin.foot:SetHeight(style=='Classic' and 3 or 1)
    skin.rose:SetShown(adventure and enabled and skin==self.messageSkin)
    skin.rose:SetVertexColor(gold[1],gold[2],gold[3],.28)
    skin.tag:SetShown(enabled and skin==self.messageSkin)
    skin.tag:SetText(style=='Adventure' and 'FIELD NOTES  /  PARTY COMMS' or
      (style=='Tactical' and 'COMMS  //  LIVE' or (style=='Modern' and 'COMMS / CHANNEL 01' or 'WAFFLES GANG / CHAT')))
    skin.tag:SetFont(WG:StyleFont(9),9,'')
    skin.tag:SetTextColor(gold[1],gold[2],gold[3],.78)
    if skin.modernRound then
      skin.modernRound:SetShown(modern)
      skin.modernRound:SetColor(bg[1],bg[2],bg[3],skin==self.inputSkin and .76 or chatOpacity)
    end
    if skin.modernEdge then
      skin.modernEdge:SetShown(modern)
      skin.modernEdge:SetColor(edge[1],edge[2],edge[3],skin==self.inputSkin and .33 or .20)
    end
    for i,line in ipairs(skin.lines) do
      line:SetColorTexture(color(i==2 and gold or edge,tactical and (i==1 and .58 or i==3 and .80 or .12) or .85))
      line:SetShown(enabled and not modern)
    end
    if skin.logo then skin.logo:SetShown(enabled and not modern and not tactical) end
  end
end
function Chat:Init()
  local f=WG:Window('chat','Waffle Chat & Menu Appearance',510,342)
  WG:Text(f,'CHAT STYLE',24,-81,16,'accent')
  WG:Text(f,'Keep Blizzard chat features with Waffles Gang colors.',24,-112,11,'text',460)
  WG:Divider(f,-129,463,24)
  WG:Check(f,'chatstyle','Enable waffle chat and input bar',24,-151)
  WG:Check(f,'menutheme','Theme Blizzard Game Menu (buttons stay native)',24,-191)
  WG:Text(f,'Uses matching colors from your currently selected Gang theme.',24,-239,11,'text',455)
  WG:Text(f,'without replacing chat, tabs, channels or message controls.',24,-259,11,'text',455)
  WG:Text(f,'Adventure: field notes | Tactical: signal rail | Modern: clean trace.',24,-291,10,'accent',470)
  self:Setup()
  WG:On('PLAYER_ENTERING_WORLD',function()Chat:Setup()end)
end
