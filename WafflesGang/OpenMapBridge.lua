-- Waffles Gang / OpenMap bridge. OpenMap itself is NOT bundled.
-- Documented OpenMapAPI (major 1): https://github.com/openmap-world/openmap/blob/main/docs/api.md
local WG=_G.WafflesGang
local M={name='OpenMap Bridge',connected=false}
WG.openMap=M
WG.modules[#WG.modules+1]=M
function M:API()
  local api=_G.OpenMapAPI
  if type(api)=='table' and api.major==1 then return api end
end
function M:IsConnected() return self:API()~=nil end
function M:Connect()
  local api=self:API()
  if not api or (self.connected and self.api==api) then return end
  self.api=api
  if type(api.RegisterMenuToggle)=='function' then
    local ok=pcall(api.RegisterMenuToggle,'WafflesGang',{
      id='waffle-quest-tracker',label='Waffle Quest Tracker',
      section='Waffles Gang',tab='show',
      get=function()
        return WG.quests and WG.quests:Options().tracker or false
      end,
      set=function(enabled)
        if WG.quests and WG.db then
          WG.quests:Options().tracker=not not enabled
          WG:Refresh()
        end
      end,
    })
    self.menuRegistered=ok
  end
  self.connected=true
end
function M:CenterOnPlayer()
  local api=self:API()
  if not api then return WG:Say('Install or enable OpenMap for seamless navigation. Type /openmap after installing.') end
  if ToggleWorldMap and (not WorldMapFrame or not WorldMapFrame:IsShown()) then ToggleWorldMap() end
  local mapID=C_Map and C_Map.GetBestMapForUnit and C_Map.GetBestMapForUnit('player')
  local pos=mapID and C_Map.GetPlayerMapPosition and C_Map.GetPlayerMapPosition(mapID,'player')
  if not pos or not pos.GetXY or type(api.WorldFromMap)~='function' or type(api.ShowWorld)~='function' then
    return WG:Say('OpenMap is ready. Use its Find Me button on the world map.')
  end
  local good,x,y=pcall(pos.GetXY,pos)
  if not good or type(x)~='number' or type(y)~='number' then return end
  local ok,u,v=pcall(api.WorldFromMap,mapID,x,y)
  if ok and type(u)=='number' and type(v)=='number' then
    local moved,result=pcall(api.ShowWorld,u,v)
    if moved and result~=false then return end
  end
  WG:Say('Map is open. Use OpenMap Find Me to center your position.')
end
function M:Init()
  self:Connect()
  WG:On('ADDON_LOADED',function(name)
    if name=='OpenMap' then M:Connect() end
  end)
  if C_Timer and C_Timer.After then
    C_Timer.After(2,function()M:Connect()end)
  end
end
function M:Refresh()
  if WG.db and not self.connected then self:Connect() end
end
