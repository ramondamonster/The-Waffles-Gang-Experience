local name = ...
local WG = CreateFrame('Frame')
_G.WafflesGang = WG
BINDING_HEADER_WAFFLESGANG = 'Waffles Gang'
_G['BINDING_NAME_CLICK WafflesGangPantryKey:LeftButton'] = 'Toggle Waffle Pantry'
WG.addon = name or 'WafflesGang'
WG.windows, WG.modules, WG.events, WG.surfaces = {}, {}, {}, {}
WG.logoPath = 'Interface\\AddOns\\WafflesGang\\Media\\WaffleLogo'
WG.themeLogos = {
  Waffles=WG.logoPath, Cake='Interface\\AddOns\\WafflesGang\\Media\\ThemeCake',
  Pie='Interface\\AddOns\\WafflesGang\\Media\\ThemePie',
  Pizza='Interface\\AddOns\\WafflesGang\\Media\\ThemePizza',
  Samurai='Interface\\AddOns\\WafflesGang\\Media\\ThemeSamurai',
}
-- Fully coordinated palettes for each visual theme.  Old Waffles color names
-- remain valid; Cake / Pie / Pizza / Samurai use their own named colorways.
WG.themeColorways={
  Cake={
    {'Strawberry Cream',{bg={.105,.047,.075},panel={.18,.091,.126},accent={1,.79,.85},edge={.71,.29,.45},text={1,.957,.958}}},
    {'Vanilla Buttercream',{bg={.105,.077,.061},panel={.181,.13,.101},accent={1,.85,.58},edge={.66,.45,.29},text={1,.968,.902}}},
    {'Chocolate Ganache',{bg={.076,.047,.047},panel={.145,.082,.072},accent={1,.73,.51},edge={.57,.36,.29},text={1,.959,.904}}},
    {'Royal Velvet',{bg={.070,.053,.100},panel={.129,.087,.169},accent={.84,.77,1},edge={.50,.35,.66},text={.968,.951,1}}},
  },
  Pie={
    {'Cherry Filling',{bg={.095,.043,.063},panel={.168,.073,.092},accent={1,.69,.57},edge={.68,.23,.32},text={1,.946,.90}}},
    {'Golden Apple',{bg={.107,.068,.034},panel={.191,.119,.056},accent={1,.82,.43},edge={.72,.44,.19},text={1,.961,.858}}},
    {'Blueberry Crust',{bg={.055,.058,.099},panel={.100,.089,.16},accent={.71,.79,1},edge={.37,.41,.67},text={.956,.953,1}}},
    {'Key Lime Slice',{bg={.061,.080,.045},panel={.112,.137,.071},accent={.87,1,.56},edge={.43,.60,.24},text={.954,1,.866}}},
  },
  Pizza={
    {'Tomato Basil',{bg={.091,.046,.038},panel={.164,.075,.053},accent={1,.69,.38},edge={.71,.27,.19},text={1,.95,.88}}},
    {'Pepperoni Heat',{bg={.110,.038,.045},panel={.190,.064,.068},accent={1,.55,.42},edge={.73,.20,.19},text={1,.942,.89}}},
    {'Four Cheese',{bg={.101,.083,.047},panel={.17,.132,.060},accent={1,.88,.46},edge={.64,.49,.19},text={1,.964,.84}}},
    {'Wood-Fired',{bg={.073,.061,.050},panel={.137,.104,.072},accent={1,.73,.44},edge={.56,.37,.25},text={1,.954,.89}}},
  },
  Samurai={
    {'Crimson Ronin',{bg={.054,.047,.055},panel={.100,.070,.081},accent={1,.63,.59},edge={.62,.23,.28},text={.98,.95,.91}}},
    {'Midnight Steel',{bg={.040,.055,.077},panel={.077,.092,.121},accent={.71,.82,1},edge={.28,.43,.57},text={.954,.968,1}}},
    {'Jade Katana',{bg={.040,.064,.061},panel={.068,.114,.095},accent={.70,.96,.79},edge={.27,.52,.43},text={.933,1,.94}}},
    {'Imperial Gold',{bg={.067,.057,.047},panel={.121,.095,.065},accent={1,.81,.49},edge={.61,.44,.23},text={1,.97,.88}}},
  },
}
WG.themeDescriptions={
  Waffles='Toasted waffle lattice / syrup glow / breakfast gold',
  Cake='Strawberry cream / frosting flourishes / gold ribbon',
  Pie='Pastry lattice / orchard and berry shades / warm copper',
  Pizza='Stone oven / pepperoni accents / melted cheese glow',
  Samurai='Indigo lacquer / wave engraving / forged-metal edges',
}
WG.themePatterns={
  Waffles='Interface\\AddOns\\WafflesGang\\Media\\ThemePatternWaffles',
  Cake='Interface\\AddOns\\WafflesGang\\Media\\ThemePatternCake',
  Pie='Interface\\AddOns\\WafflesGang\\Media\\ThemePatternPie',
  Pizza='Interface\\AddOns\\WafflesGang\\Media\\ThemePatternPizza',
  Samurai='Interface\\AddOns\\WafflesGang\\Media\\ThemePatternSamurai',
}
WG.themeHeaders={
  Waffles='Interface\\AddOns\\WafflesGang\\Media\\ThemeHeaderWaffles',
  Cake='Interface\\AddOns\\WafflesGang\\Media\\ThemeHeaderCake',
  Pie='Interface\\AddOns\\WafflesGang\\Media\\ThemeHeaderPie',
  Pizza='Interface\\AddOns\\WafflesGang\\Media\\ThemeHeaderPizza',
  Samurai='Interface\\AddOns\\WafflesGang\\Media\\ThemeHeaderSamurai',
}
-- UI style is independent from Rain's existing Waffles/Cake/Pie/Pizza/Samurai
-- designs and their colorways. Classic deliberately uses their original art.
WG.uiStyles = {'Classic','Modern','Tactical','Adventure'}
WG.styleDescriptions = {
  Classic='Rain original | warm waffle wood, honey, all original colorways',
  Modern='Clean night-glass | cyan illumination, thin circuits, crisp typography',
  Tactical='ForeverUI Tactical | veteran command grid, flat action banks, live field intel and direct system access',
  Adventure='Wayfinder journal | weathered brass, compact expedition deck, field notes and open-road frames',
}
WG.stylePalettes = {
  Modern={bg={.030,.048,.071},panel={.047,.080,.119},accent={.25,.89,1},edge={.085,.55,.77},text={.92,.975,1},
    guildPanel={.033,.056,.079},guildRowOdd={.073,.108,.137},guildRowEven={.046,.078,.103},guildHeader={.085,.169,.203},guildBorder={.19,.46,.58},guildText={.94,.98,1}},
  Tactical={bg={.025,.033,.036},panel={.052,.068,.073},accent={.68,.88,.79},edge={.31,.43,.43},text={.92,.96,.95},
    guildPanel={.030,.044,.047},guildRowOdd={.067,.086,.089},guildRowEven={.043,.063,.067},guildHeader={.075,.115,.113},guildBorder={.29,.47,.43},guildText={.92,.97,.95}},
  Adventure={bg={.042,.076,.072},panel={.084,.123,.108},accent={1,.84,.53},edge={.55,.43,.25},text={1,.965,.85},
    guildPanel={.054,.095,.085},guildRowOdd={.127,.160,.132},guildRowEven={.093,.130,.111},guildHeader={.19,.23,.17},guildBorder={.51,.42,.24},guildText={1,.966,.86}},
}
-- Independent visual compositions and Rain's food/Samurai themes are
-- different layers. Preserve both independently, including per-style picks.
local function cloneColors(colors)
  local result={}
  for k,v in pairs(colors or {}) do if type(k)=='string' and type(v)=='string' then result[k]=v end end
  return result
end
function WG:RememberStyleTheme(style)
  if not self.db then return end
  self.db.styleThemeChoices=self.db.styleThemeChoices or {}
  self.db.styleThemeChoices[style or self:StyleName()]={
    visualTheme=self:ThemeName(),palette=self.db.palette or 'Maple',
    themeColors=cloneColors(self.db.themeColors),
  }
end
function WG:RestoreStyleTheme(style)
  if not self.db then return end
  local stored=self.db.styleThemeChoices and self.db.styleThemeChoices[style]
  if type(stored)~='table' then
    self:RememberStyleTheme(style)
    return
  end
  self.db.visualTheme=self.themeLogos[stored.visualTheme] and stored.visualTheme or 'Waffles'
  self.db.palette=self.palettes[stored.palette] and stored.palette or 'Maple'
  self.db.themeColors=cloneColors(stored.themeColors)
end
local function blend(a,b,mix)
  return {a[1]*(1-mix)+b[1]*mix,a[2]*(1-mix)+b[2]*mix,a[3]*(1-mix)+b[3]*mix}
end
function WG:StyleName()
  local name=self.db and self.db.uiStyle or 'Classic'
  for _,option in ipairs(self.uiStyles) do if option==name then return name end end
  return 'Classic'
end
function WG:StyleTexture(part)
  local style=self:StyleName()
  if style=='Classic' then return nil end
  return 'Interface\\AddOns\\WafflesGang\\Media\\UIStyles\\'..style..part
end
function WG:StyleFont(size)
  local style=self:StyleName()
  if style=='Modern' or style=='Tactical' then return 'Fonts\\ARIALN.TTF'
  elseif style=='Adventure' and (size or 12)>=17 then return 'Fonts\\MORPHEUS.TTF'
  end
  return STANDARD_TEXT_FONT or 'Fonts\\FRIZQT__.TTF'
end
-- Saved per-style values. The tactical dashboard only uses safe read-only APIs;
-- changes never move Blizzard secure buttons while the player is in combat.
local tacticalDefaults={
  iconSize=34,gap=3,xpWidth=310,xpHeight=5,barOpacity=.62,
  chatOpacity=.45,questFont=12,questOpacity=.60,
  showTelemetry=true,showPortraits=false,showActionLabels=false,compactThreat=true,
  showPerformance=true,showLocation=true,showTarget=true,showGroup=true,
  showDurability=true,showBagSpace=true,showClock=true,signalColor='Theme',
  combatOnly=false,compactHUD=true,telemetryOpacity=.87,telemetryWidth=465,
  questMinimal=true,questProgressBars=false,questWidth=315,navStyle='waffle',showNoRoute=false,actionColumns=6,
}
function WG:TacticalSettings()
  if not self.db then return tacticalDefaults end
  if type(self.db.tacticalHUD)~='table' then self.db.tacticalHUD={} end
  local o=self.db.tacticalHUD
  -- v4 refresh of the prior *stock* layout; respect values already changed.
  if not o.v400Migrated then
    local old={iconSize=38,gap=5,xpWidth=540,xpHeight=10,barOpacity=.88,
      chatOpacity=.72,questFont=13,questOpacity=.92,showActionLabels=true,
      compactHUD=false,telemetryOpacity=.94,telemetryWidth=760,signalColor='Sage'}
    for key,val in pairs(old) do
      if o[key]==nil or o[key]==val then o[key]=tacticalDefaults[key] end
    end
    o.v400Migrated=true
  end
  for k,v in pairs(tacticalDefaults) do if o[k]==nil then o[k]=v end end
  local function limit(k,a,b) o[k]=math.max(a,math.min(b,tonumber(o[k]) or tacticalDefaults[k])) end
  limit('iconSize',26,48);limit('gap',0,12);limit('xpWidth',190,720);limit('xpHeight',3,18)
  limit('barOpacity',.20,1);limit('chatOpacity',0,.98);limit('questFont',10,17)
  limit('questOpacity',0,.98);limit('telemetryOpacity',.25,1);limit('telemetryWidth',330,810)
  limit('questWidth',250,460)
  if o.actionColumns~=12 then o.actionColumns=6 end
  if o.navStyle=='needle' then o.navStyle='waffle' end
  if o.navStyle~='waffle' and o.navStyle~='text' and o.navStyle~='off' then o.navStyle='waffle' end
  return o
end

local expeditionDefaults={showHUD=true,compactHUD=false,showXP=true,showLocation=true,
  showSession=true,showReadiness=true,journalMinimal=true,iconSize=35,gap=5,
  actionColumns=6,dockOpacity=.94,unitPanels=false,
  xpWidth=470,xpHeight=6,xpText=true,xpOpacity=.90,hudOpacity=.78,chatOpacity=.27}
function WG:ExpeditionSettings()
  if not self.db then return expeditionDefaults end
  if type(self.db.expeditionHUD)~='table' then self.db.expeditionHUD={} end
  local o=self.db.expeditionHUD
  for k,v in pairs(expeditionDefaults) do if o[k]==nil then o[k]=v end end
  local function cap(k,low,high)o[k]=math.max(low,math.min(high,tonumber(o[k]) or expeditionDefaults[k]))end
  cap('iconSize',28,45);cap('gap',1,12);cap('xpWidth',260,650)
  cap('xpHeight',3,16);cap('xpOpacity',.2,1);cap('hudOpacity',.1,1);cap('chatOpacity',0,.98)
  cap('dockOpacity',.25,1)
  if o.actionColumns~=12 then o.actionColumns=6 end
  return o
end

function WG:SetUIStyle(name)
  if not self.db then return end
  local found=false
  for _,style in ipairs(self.uiStyles) do if style==name then found=true;break end end
  if not found then return end
  if self:Protected() then self:Say('Change UI style after combat ends.');return end
  local old=self:StyleName()
  if old~=name then
    self:RememberStyleTheme(old)
    self.db.uiStyle=name
    self:RestoreStyleTheme(name)
  end
  self:Refresh()
end

WG.themeTextures={}
WG.themeLogoTextures={}

WG.unpack = unpack or table.unpack
WG.palettes = {
  Maple     = {bg={.075,.052,.039}, panel={.14,.090,.052}, accent={1,.75,.34}, edge={.56,.30,.12}, text={1,.95,.82}},
  Blueberry = {bg={.064,.069,.11}, panel={.105,.108,.17}, accent={.65,.77,1}, edge={.32,.42,.67}, text={.91,.94,1}},
  Cherry    = {bg={.105,.048,.054}, panel={.17,.077,.091}, accent={1,.61,.63}, edge={.60,.18,.24}, text={1,.91,.91}},
  ['Key Lime']={bg={.054,.080,.056}, panel={.095,.135,.085}, accent={.75,.93,.50}, edge={.39,.57,.22}, text={.94,1,.84}},
}
WG.features = {
  {'launcher','Waffle launcher','Movable waffle logo opens the dashboard.',true},
  {'party','Party manager','Invite your selected player, group roster and tools.',true},
  {'guild','Guild manager','Guild roster, member search, party invites and chat.',true},
  {'guildprofessions','Guild professions','Share and request guild professions / known recipes from addon users.',true},
  {'shareprofessions','Share my professions','Allow guild members using Waffles Gang to request your professions and saved recipe list.',false},
  {'loot','Loot method manager','Leader-controlled group loot method buttons.',true},
  {'grouptools','Group tools','Ready check, role poll and raid controls.',true},
  {'playerframe','Player frame','Custom player health and resource frame.',true},
  {'targetframe','Target frame','Custom target health and resource frame.',true},
  {'focusframe','Focus frame','Optional clickable focus frame.',false},
  {'partyframes','Party frames','Compact class-colored party frames.',true},
  {'raidframes','Raid frames','40-unit compact raid grid.',true},
  {'classcolors','Class health colors','Apply class colors to unit health bars.',true},
  {'healthpercent','Party health percentages','Show a numeric health percentage on party and raid frames.',true},
  {'unitpercent','Player and target percentages','Show HP% on player / target / focus, plus MP or resource% on your player frame.',true},
  {'unitpower','Unit resource bars','Show mana, rage and other resources.',true},
  {'auras','Aura Studio','Custom buffs and debuffs for each unit frame type.',true},
  {'wafflequests','Waffle Quest Companion','Simplified quest journal alongside optional Questie map markers.',true},
  {'actionbars','Waffle action bars','Secure action buttons for standard action slots.',true},
  {'actioncooldowns','Action cooldown countdowns','Show the cooldown sweep and remaining seconds on abilities (on by default).',true},
  {'greyunusable','Gray unusable abilities','Desaturate Waffle action icons when the game reports the ability cannot be used (on by default).',true},
  {'secondbar','Second action bar','Additional 12 secure slots (61–72).',false},
  {'xpbar','Waffle XP bar','Movable independent experience display; Edit Mode saves its position.',true},
  {'chatstyle','Waffle chat theme','Optional matching chat background and message input styling.',false},
  {'menutheme','Theme the Blizzard Game Menu','Cosmetic, click-through skin that preserves every Blizzard menu action.',true},
  {'replaceui','Replace Blizzard unit frames','Blizzard action and bag bars hide with their Waffle replacements. This toggle additionally hides Blizzard unit frames.',false},
  {'bags','Waffle Pantry','One inventory window showing every equipped bag.',true},
  {'bagsearch','Pantry search','Search the contents of your inventory.',true},
  {'bagcategories','Pantry filters','Filter by item type.',true},
  {'bagpins','Pantry favorites','Alt-click items to highlight favorites.',true},
  {'bagitemlevel','Pantry item level','Overlay equipment item levels.',true},
  {'bagrecent','Pantry new-item marks','Mark newly obtained items when supported.',true},
  {'goldtracking','Gold display','Show current character money in the Pantry.',true},
  {'gearsuggestions','Gear upgrades','Show estimated stat-based upgrades for your selected specialization.',true},
  {'questrewardadvisor','Quest reward advisor','Compare quest reward item upgrades and vendor prices; do not auto-select rewards.',true},
  {'autoloot','Auto loot','Off / Everything / Quest items / Gear filter.',false},
  {'autoquest','Auto turn in quests','Turn in completed quests at NPCs, except reward choices.',false},
  {'autoselljunk','Auto sell junk','Sell safe gray quality junk at merchants.',false},
  {'bagcleanup','Full bag cleanup','Offer one-click gray junk deletion when bags are full.',false},
  {'levelcelebration','Level-up waffle celebration','Dance and send a burst of waffles across the screen when you level up (off by default).',false},
  {'banner','Welcome message','Print a short Waffles Gang greeting on login.',true},
}
function WG:ThemeName()
  local name=self.db and self.db.visualTheme or 'Waffles'
  return self.themeLogos[name] and name or 'Waffles'
end
function WG:ThemePaletteOptions(name)
  local theme=name or self:ThemeName()
  if theme=='Waffles' then
    local list={}
    for _,label in ipairs({'Maple','Blueberry','Cherry','Key Lime'}) do
      list[#list+1]={label,self.palettes[label]}
    end
    return list
  end
  return self.themeColorways[theme] or self:ThemePaletteOptions('Waffles')
end
function WG:CurrentPaletteName()
  local name=self:ThemeName()
  if name=='Waffles' then return (self.db and self.db.palette) or 'Maple' end
  local list=self:ThemePaletteOptions(name)
  local selected=self.db and self.db.themeColors and self.db.themeColors[name]
  for _,row in ipairs(list) do if row[1]==selected then return selected end end
  return list[1][1]
end
function WG:CurrentColorSet()
  local current=self:CurrentPaletteName()
  for _,row in ipairs(self:ThemePaletteOptions()) do
    if row[1]==current then return row[2] end
  end
  return self.palettes.Maple
end
function WG:SetTheme(name)
  if not self.themeLogos[name] or not self.db then return end
  self.db.visualTheme=name
  self:RememberStyleTheme()
  self:Refresh()
end
function WG:SetThemeColor(name)
  if not self.db then return end
  local theme=self:ThemeName()
  for _,row in ipairs(self:ThemePaletteOptions()) do
    if row[1]==name then
      if theme=='Waffles' then self.db.palette=name
      else self.db.themeColors[theme]=name end
      self:RememberStyleTheme()
      self:Refresh()
      return true
    end
  end
end
function WG:TacticalAccent()
  local mode=self.db and self.db.tacticalHUD and self.db.tacticalHUD.signalColor or 'Theme'
  local colors={Sage={.67,.89,.78},Arctic={.45,.82,.94},Amber={1,.71,.39},White={.88,.94,.95}}
  local theme=self:CurrentColorSet().accent
  -- Theme/colorway always affects Tactical, even when a signal accent is selected.
  if mode=='Theme' then return theme end
  return blend(colors[mode] or theme,theme,.38)
end
function WG:Color(kind)
  -- Tactical has its own low-distraction signal accent. Other styles retain
  -- Rain's independent food themes and colorways without visual changes.
  local palette=self:CurrentColorSet()
  local style=self:StyleName()
  if style=='Classic' then
    local classicGuild={
      guildPanel={.055,.064,.079},guildRowOdd={.105,.121,.143},
      guildRowEven={.079,.095,.114},guildHeader={.155,.176,.196},
      guildBorder={.24,.29,.33},guildText={.95,.96,.98},
    }
    return classicGuild[kind] or palette[kind] or palette.accent
  end
  local base=self.stylePalettes[style] or self.stylePalettes.Modern
  if kind=='accent' then return style=='Tactical' and (self:TacticalAccent()) or palette.accent end
  if kind=='bg' or kind=='panel' then
    local influence=style=='Modern' and .22 or (style=='Tactical' and .20 or .41)
    return blend(base[kind],palette[kind],influence)
  end
  if kind=='edge' then return style=='Tactical' and blend(base.edge,self:TacticalAccent(),.49) or blend(base.edge,palette.edge,style=='Modern' and .57 or .44) end
  if kind=='guildBorder' then return style=='Tactical' and blend(base.guildBorder,self:TacticalAccent(),.28) or blend(base.guildBorder,palette.accent,.36) end
  if kind=='guildHeader' then return style=='Tactical' and blend(base.guildHeader,palette.panel,.24) or blend(base.guildHeader,palette.accent,.15) end
  if kind=='guildText' then return base.guildText or base.text end
  return base[kind] or palette[kind] or palette.accent
end
function WG:CurrentThemeTexture(kind)
  -- Only the ornaments use the original artwork. Tactical keeps the geometry
  -- flat but can adopt the chosen theme's subtle pattern/identity.
  if self:StyleName()=='Tactical' then
    return (kind=='header' and self.themeHeaders or self.themePatterns)[self:ThemeName()]
  end
  local custom=self:StyleTexture(kind=='header' and 'Header' or 'Panel')
  if custom then return custom end
  return (kind=='header' and self.themeHeaders or self.themePatterns)[self:ThemeName()]
end
function WG:CurrentLogo()
  return self.themeLogos[(self.db and self.db.visualTheme) or 'Waffles'] or self.logoPath
end
function WG:Say(str)
  if DEFAULT_CHAT_FRAME and DEFAULT_CHAT_FRAME.AddMessage then
    DEFAULT_CHAT_FRAME:AddMessage('|cffffc65aWaffles Gang|r  '..tostring(str))
  end
end
function WG:Enabled(id) return self.db and self.db.features and self.db.features[id] == true end
function WG:Feature(id,value)
  if not self.db then return end
  self.db.features[id] = not not value
  self:Refresh()
end
function WG:On(event, callback)
  if type(event)~='string' or type(callback)~='function' then return end
  if not self.events[event] then
    -- WoW Forever does not expose every event in older profession APIs.
    -- One unsupported optional event must not abort the module's Init().
    local ok=pcall(self.RegisterEvent,self,event)
    if not ok then
      self.unavailableEvents=self.unavailableEvents or {}
      self.unavailableEvents[event]=true
      return false
    end
    self.events[event]={}
  end
  table.insert(self.events[event],callback)
  return true
end
function WG:Protected() return InCombatLockdown and InCombatLockdown() end
function WG:Safe(label, fn)
  local ok, result=pcall(fn)
  if not ok then self:Say(label..': '..tostring(result)); return false end
  return true,result
end
function WG:Refresh()
  if not self.db then return end
  for _,surface in ipairs(self.surfaces) do
    if surface.repaint then self:Safe('Theme',surface.repaint) end
  end
  for _,texture in ipairs(self.themeLogoTextures) do texture:SetTexture(self:CurrentLogo()) end
  for _,art in ipairs(self.themeTextures) do
    art.texture:SetTexture(self:CurrentThemeTexture(art.kind))
  end
  for _,mod in ipairs(self.modules) do
    if mod.Refresh then self:Safe('Refresh '..(mod.name or '?'),function() mod:Refresh() end) end
  end
end
function WG:Init()
  if self.db then return end
  WafflesGangDB = type(WafflesGangDB)=='table' and WafflesGangDB or {}
  self.db = WafflesGangDB
  self.db.features = type(self.db.features)=='table' and self.db.features or {}
  for _,row in ipairs(self.features) do
    if self.db.features[row[1]]==nil then self.db.features[row[1]]=row[4] end
  end
  self.db.uiStyle=self:StyleName()
  self.db.palette = self.palettes[self.db.palette] and self.db.palette or 'Maple'
  self.db.visualTheme=self.themeLogos[self.db.visualTheme] and self.db.visualTheme or 'Waffles'
  self.db.themeColors=type(self.db.themeColors)=='table' and self.db.themeColors or {}
  self.db.styleThemeChoices=type(self.db.styleThemeChoices)=='table' and self.db.styleThemeChoices or {}
  if not self.db.styleThemeChoices[self.db.uiStyle] then self:RememberStyleTheme(self.db.uiStyle) end
  self.db.gearProfile=self.db.gearProfile or 'Current'
  self.db.rewardPreference=self.db.rewardPreference or 'Upgrade or Value'
  self.db.guildProfessionCache=type(self.db.guildProfessionCache)=='table' and self.db.guildProfessionCache or {}
  self.db.autoLootMode = self.db.autoLootMode or 'all'
  self.db.pins = type(self.db.pins)=='table' and self.db.pins or {}
  self.db.windowPositions=type(self.db.windowPositions)=='table' and self.db.windowPositions or {}
  self.db.hudPositions=type(self.db.hudPositions)=='table' and self.db.hudPositions or {}
  self.db.profiles=type(self.db.profiles)=='table' and self.db.profiles or {}
  self.db.windowScale=type(self.db.windowScale)=='number' and math.max(.7,math.min(1.45,self.db.windowScale)) or 1
  self.db.windowScales=type(self.db.windowScales)=='table' and self.db.windowScales or {}
  if self.db.oneWindow==nil then self.db.oneWindow=true end
  if self.db.lockWindows==nil then self.db.lockWindows=false end
  if self.db.bagKeyOverride==nil then self.db.bagKeyOverride=true end
  -- One-time v2.9 repair: older /wg recover operations can leave the B
  -- override disabled after Pantry is reenabled. User can turn it off in Layout.
  if not self.db.pantryBinding29Migrated then
    self.db.bagKeyOverride=true
    self.db.pantryBinding29Migrated=true
  end
  -- One-time v3 repair: a previous recovery may have saved the override OFF.
  -- Preserve an intentionally disabled Pantry feature; restore its B key only
  -- while the user has the Waffle Pantry feature enabled.
  if not self.db.pantryBinding30Migrated then
    if self.db.features.bags then self.db.bagKeyOverride=true end
    self.db.pantryBinding30Migrated=true
  end
  for _,mod in ipairs(self.modules) do
    if mod.Init then self:Safe('Initialize '..(mod.name or '?'),function() mod:Init() end) end
  end
  self:Refresh()
  if not self.db.setupComplete then self:Open('setup')
  elseif self:Enabled('banner') then self:Say('Fresh waffles! Type /wg to open the dashboard.') end
end
-- Emergency escape hatch. Never hide the Blizzard fallback without a way back.
function WG:RecoverUI()
  if not self.db then return end
  for _,key in ipairs({'replaceui','actionbars','bags','playerframe','targetframe','focusframe','partyframes','raidframes'}) do
    self.db.features[key]=false
  end
  self.db.bagKeyOverride=false
  self:Refresh()
  if self:Protected() then
    self:Say('Blizzard bar and frame restoration requested. Leave combat to finish restoring UI.')
  else
    self:Say('Blizzard action bars, bag bar, and unit frames restored. Open /wg settings to enable Waffles Gang again.')
  end
end
WG:RegisterEvent('PLAYER_LOGIN')
WG:SetScript('OnEvent',function(self,event,...)
  if event=='PLAYER_LOGIN' then self:Init() end
  local group=self.events[event]
  if group and self.db then
    local args={...}
    for _,func in ipairs(group) do self:Safe(event, function() func(self.unpack(args)) end) end
  end
end)
SLASH_WAFFLESGANG1='/wg'
SLASH_WAFFLESGANG2='/waffles'
SlashCmdList.WAFFLESGANG=function(message)
  if not WG.db then return end
  local cmd=(message or ''):lower():match('^%s*(.-)%s*$')
  local map={['']='studio',styles='studio',themes='studio',map='studio',maps='studio',hub='hub',dashboard='hub',studio='studio',control='studio',customize='studio',questlog='quests',quests='quests',questie='quests',adventure='adventure',session='adventure',stats='adventure',guild='guild',guildboard='guildboard',events='guildboard',event='guildboard',recruitment='recruitment',recruit='recruitment',automation='automation',junk='automation',quest='quests',setup='setup',settings='settings',options='settings',party='party',loot='loot',group='group',frames='frames',units='frames',raid='frames',auras='auras',buffs='auras',debuffs='auras',threat='threat',threatwatch='threat',bars='bars',chat='chat',chatstyle='chat',menu='chat',bags='bags',bag='bags',pantry='bags',appearance='appearance',autoloot='autoloot',layout='layout',profiles='profiles',help='help',about='help',professions='professions',recipes='professions',gear='gear',rewards='rewards'}
  local target=map[cmd]
  if cmd=='tools' or cmd=='directory' or cmd=='all' then
    WG:Open('studio');if WG.studio then WG.studio:Select('DIRECTORY') end;return
  end
  if cmd=='tactical' or cmd=='deck' then
    WG:Open('studio');if WG.studio then WG.studio:Select('TACTICALHUD') end;return
  end
  if cmd=='recover' then WG:RecoverUI(); return end
  if cmd=='edit' or cmd=='editmode' then WG:ToggleEditMode();return end
  if cmd=='lock' or cmd=='unlock' then
    WG.db.hudDragLocked=(cmd=='lock')
    if WG.UpdateHUDGrips then WG:UpdateHUDGrips() end
    WG:Say('HUD drag handles '..(WG.db.hudDragLocked and 'locked' or 'unlocked')..'. Right-click a handle to lock one frame.')
    return
  end
  if cmd=='reset' then WG:ResetLayout();return end
  if cmd=='bind' or cmd=='bindbags' then
    -- An explicit /wg bindbags is a request to turn the shortcut on.
    WG.db.bagKeyOverride=true
    local pantry=WG.pantry
    if pantry and pantry.Binding then pantry:Binding() end
    WG:Say('Waffle Pantry B key enabled and rebound. Press B outside chat; try /wg bags if needed.')
    return
  end
  if cmd=='diag' or cmd=='diagnostics' then
    local B=WG.pantry
    local bindAction=(GetBindingAction and GetBindingAction('B')) or 'unknown'
    local override=(GetBindingAction and GetBindingAction('B',true)) or 'unknown'
    WG:Say('Diagnostics: version 3.9.0-four-styles-restored-theme-choices, class '..tostring((UnitClass and select(2,UnitClass('player'))) or 'unknown'))
    WG:Say('Pantry: '..tostring(WG:Enabled('bags'))..' | key override: '..tostring(WG.db.bagKeyOverride)..' | active: '..tostring(B and B.bindingActive)..' | B action: '..tostring(bindAction))
    WG:Say('Pantry UI: counter '..tostring(B and B.counter~=nil)..' | item buttons: '..tostring(B and B.itemButtonCount or 0)..' | key owner: '..tostring(B and B.bindOwner~=nil))
    if B and B.itemBuildError then WG:Say('Pantry slot creation error: '..tostring(B.itemBuildError)) end
    WG:Say('Effective B action: '..tostring(override)..' | Pantry key presses: '..tostring(B and B.keyPresses or 0))
    WG:Say('XP bar enabled: '..tostring(WG:Enabled('xpbar'))..' | edit registered: '..tostring(WG.hudFrames and WG.hudFrames.xpbar~=nil))
    WG:Say('Gear: '..tostring(WG:Enabled('gearsuggestions'))..' | talent: '..tostring(WG.db.gearProfile))
    return
  end
  if not target then WG:Say('Commands: /wg studio, tools, tactical, edit, quests, guild, party, threat, auras, bags, settings, profiles, recover'); return end
  WG:Toggle(target)
end
