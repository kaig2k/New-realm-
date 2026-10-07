'use strict';
// Prints map fingerprints (same format as the game's /thash test command) so the
// server's generated worlds can be compared with the game's, tile for tile.
const { Bosses, Data, World } = require('./gen/game');
Bosses.init();
function hash(w) {
  let h = 2166136261;
  for (let i = 0; i < w.N * w.N; i++) {
    h = (h * 31 + w.tiles[i] + 1) % 4294967296;
    h = (h * 31 + w.objs[i] + 7) % 4294967296;
    h = (h * 31 + w.zones[i] + 11) % 4294967296;
  }
  return h + '|' + w.spawnX + ',' + w.spawnY + '|' + w.sites.length + '|' + w.shrines.length + '|' + w.rooms.length;
}
const out = [];
for (const s of [12345, 999, 7, 3141592]) out.push('realm ' + s + ' ' + hash(new World('realm', 'T', null, s)));
Data.DUNGEONS.forEach((d, i) => out.push('dg ' + i + ' ' + hash(new World('dungeon', d.name, d, 4242 + i))));
Bosses.RAIDS.forEach((r, i) => out.push('raid ' + i + ' ' + hash(new World('dungeon', r.name, r.theme, 777 + i))));
out.push('nexus ' + hash(new World('nexus', 'Nexus')));
out.push('arena ' + hash(new World('arena', 'A')));
console.log(out.join('\n'));
