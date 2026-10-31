// Executes the actual runtime parser in Luau, without Roblox or network.
import fs from 'node:fs';
import {pathToFileURL} from 'node:url';
const {LuauState} = await import(pathToFileURL(process.argv[2]).href);
const source = fs.readFileSync(new URL('../projects/infinity-universe/InfinityUniverse.lua', import.meta.url), 'utf8');
const start = source.indexOf('local MAX_FLIGHT_SPEED');
const end = source.indexOf('local connections,', start);
if (start < 0 || end < 0) throw Error('Runtime parser not found');
const tests = `
assert(parseSpeed('5') == 5)
assert(parseSpeed('500') == 500)
assert(parseSpeed('1200') == 1200)
assert(parseSpeed('0') == 0)
assert(parseSpeed(' 0.25 ') == 0.25)
assert(parseSpeed('1e6') == 1000000)
assert(parseSpeed('99999999999999999999999999') == 1e18)
assert(parseSpeed('1e999') == 1e18)
assert(parseSpeed('-1') == nil)
assert(parseSpeed('nan') == nil)
assert(parseSpeed('inf') == nil)
assert(parseSpeed('') == nil)
assert(parseSpeed('hello') == nil)
return 'PASS: 13 actual Luau parser assertions'
`;
const state = await LuauState.createAsync();
try { console.log(await state.loadstring(source.slice(start, end) + tests, 'speed-tests', true)()); }
finally { state.destroy(); }
