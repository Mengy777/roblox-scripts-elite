// Actual entrypoint with mocked Roblox/WindUI services; no network or physics.
import fs from 'node:fs';
import {pathToFileURL} from 'node:url';
const {LuauState} = await import(pathToFileURL(process.argv[2]).href);
const source = fs.readFileSync(new URL('../projects/infinity-universe/InfinityUniverse.lua', import.meta.url), 'utf8');
const fixture = `
local savedEnv, tabs, links = {}, {}, {}
function loadstring(_) return function() return TEST_WIND end end
function getgenv() return savedEnv end
local function signal()
 return {Connect=function(_,fn)
  local c={Connected=true, fn=fn}
  function c:Disconnect() self.Connected=false end
  table.insert(links,c) return c
 end}
end
Enum={KeyCode={RightShift=1}}
UDim2={fromOffset=function() return {} end}
local player={CharacterRemoving=signal()}
local services={Players={LocalPlayer=player},RunService={Heartbeat=signal()},UserInputService={}}
game={GetService=function(_,k) return services[k] end,HttpGet=function() return 'return TEST_WIND' end}
local destroyed=0
local win={}
function win:OnDestroy(fn) self.onDestroy=fn end
function win:Destroy() self.Destroyed=true destroyed+=1 self.onDestroy() end
local function widget(config)
 local w={config=config,Value=config.Value}
 function w:Set(v) self.Value=v self.config.Callback(v) end
 return w
end
function win:Tab(config)
 local t={Title=config.Title,widgets={}}
 for _,kind in ipairs({'Toggle','Slider','Input','Button'}) do
  t[kind]=function(self,c) local w=widget(c) self.widgets[kind]=w return w end
 end
 table.insert(tabs,t) return t
end
TEST_WIND={CreateWindow=function() return win end,Notify=function() end}
`;
const tests = `
local app=savedEnv.InfinityUniverse
assert(#tabs==2 and tabs[2].Title=='Настройки')
local toggle=tabs[1].widgets.Toggle
local input=tabs[1].widgets.Input
local slider=tabs[1].widgets.Slider
toggle:Set(true) input:Set('1200')
assert(app.enabled and app.speed==1200)
app.Reset()
assert(not app.enabled and app.speed==60)
assert(toggle.Value==false and slider.Value==60 and input.Value=='60')
app.Reset() assert(app.speed==60)
tabs[2].widgets.Button.config.Callback()
assert(not app.alive and not app.enabled and savedEnv.InfinityUniverse==nil)
assert(destroyed==1)
for _,c in ipairs(links) do assert(not c.Connected) end
toggle:Set(true) input:Set('2000') slider:Set(200)
assert(not app.enabled and app.speed==60)
app.Unload() assert(destroyed==1)
return 'PASS: Settings last, reset state/UI, unload, disconnected callbacks, idempotence'
`;
const state=await LuauState.createAsync();
try { console.log(await state.loadstring(fixture+'\ndo\n'+source+'\nend\n'+tests,'lifecycle',true)()); }
finally { state.destroy(); }
