// Usage: node tools/check-infinity.mjs <absolute path to luau-web/src/index.js>
import fs from 'node:fs';
import { pathToFileURL } from 'node:url';
const { LuauState } = await import(pathToFileURL(process.argv[2]).href);
const state = await LuauState.createAsync();
try {
    const file = new URL('../projects/infinity-universe/InfinityUniverse.lua', import.meta.url);
    state.loadstring(fs.readFileSync(file, 'utf8'), 'InfinityUniverse.lua', true);
    console.log('PASS: Luau compilation (not a Roblox gameplay test)');
} finally { state.destroy(); }
