'use strict';
/*
 * Eldmere's web pages, served by the game server on its own port:
 *
 *   /            the landing page: what the game is, the promo images, live
 *                numbers (players online, the season and its leader), and how
 *                to play (in the browser, or the launcher)
 *   /play        the game in the browser (Ruffle runs it), already pointed at
 *                this server
 *   /logo.png, /promo/<name>.png, /EldmereLauncher.swf
 *
 * Nothing here can reach any other file on the server.
 */
const fs = require('fs');
const path = require('path');

const ROOT = path.join(__dirname, '..');
const LOGO = path.join(ROOT, 'assets', 'branding', 'eldmere_logo_castle.png');
const PROMO = path.join(ROOT, 'promo');
const LAUNCHER = path.join(ROOT, 'bin', 'EldmereLauncher.swf');
/** The browser player (Ruffle), a fixed version from a public CDN. */
const RUFFLE = 'https://unpkg.com/@ruffle-rs/ruffle@0.6.0/ruffle.js';

const esc = (s) => String(s).replace(/[&<>"']/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]));

const FEATURES = [
  ['47 hand-drawn bosses', 'Each with its own attacks, phases, arena and loot, and animations for every move.'],
  ['Realm events that reshape the world', 'The land turns into the boss\'s arena, and changes again as the fight goes on.'],
  ['11 classes', 'Including the Bard, Alchemist and Chronomancer, found only in Eldmere.'],
  ['Guild Halls', 'Your guild\'s own hall: a shared bank, weekly goals, and banners you design yourselves.'],
  ['Monthly seasons', 'A ladder every month, with titles and dyes for the top ten.'],
  ['Ironman and Hardcore', 'No trading, more luck. Hardcore makes you climb the gear tiers one at a time.'],
  ['Dungeons and raids', 'From early dungeons to multi-stage raids, and a Starfall Vault that changes every week.'],
  ['Fair play', 'The server runs the monsters and the loot: nobody can cheat their way to the top.']
];

/** Which promo images to show, in order (those that exist). */
const SHOTS = [['eldmere_bosses_fight.png', 'Every boss fights differently'], ['eldmere_events.png', 'Realm events'],
  ['eldmere_bosses.png', '47 bosses'], ['eldmere_guilds.png', 'Guild Halls'], ['eldmere_classes.png', '11 classes']];

/** info: {name, online, season: {name, leader}, discord, launcher} */
function landing(info) {
  const shots = SHOTS.filter(([f]) => fs.existsSync(path.join(PROMO, f)));
  const hero = fs.existsSync(path.join(PROMO, 'eldmere_hero.png')) ? '/promo/eldmere_hero.png' : '';
  const video = fs.existsSync(path.join(PROMO, 'eldmere_gameplay.mp4'));
  return `<!doctype html>
<html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>${esc(info.name)}: a bullet-hell MMO</title>
<meta name="description" content="A pixel-art bullet-hell MMO inspired by Realm of the Mad God: 47 hand-drawn bosses, raids, guilds and monthly seasons.">
<meta property="og:title" content="${esc(info.name)}"><meta property="og:description" content="Dodge. Loot. Survive. A bullet-hell MMO where every boss fights differently.">
${hero ? '<meta property="og:image" content="' + hero + '">' : ''}
<link rel="icon" href="/logo.png">
<style>
:root{--bg:#0e0a16;--panel:#1a1226;--line:#3a2450;--pink:#ff4dff;--gold:#ffcd46;--text:#eee6ff;--muted:#b9a9d4}
*{box-sizing:border-box}body{margin:0;background:var(--bg);color:var(--text);font:17px/1.55 system-ui,-apple-system,"Segoe UI",sans-serif}
a{color:var(--gold)}.wrap{max-width:1120px;margin:0 auto;padding:0 20px}
header{text-align:center;padding:48px 0 24px;background:radial-gradient(ellipse at 50% 30%,#3a1858 0,var(--bg) 70%)}
header img{width:min(560px,90%);image-rendering:pixelated}
.tag{font-size:26px;font-weight:700;color:var(--gold);margin:18px 0 6px}.sub{color:var(--muted);max-width:720px;margin:0 auto}
.live{display:flex;gap:14px;justify-content:center;flex-wrap:wrap;margin:22px 0}
.pill{background:var(--panel);border:1px solid var(--line);border-radius:999px;padding:6px 16px;color:var(--muted)}.pill b{color:var(--text)}
.dot{display:inline-block;width:9px;height:9px;border-radius:50%;background:#5ae06a;margin-right:6px;box-shadow:0 0 8px #5ae06a}
.cta{display:flex;gap:14px;justify-content:center;flex-wrap:wrap;margin:10px 0 8px}
.btn{display:inline-block;padding:14px 28px;border-radius:10px;font-weight:700;text-decoration:none;font-size:18px;border:2px solid var(--pink)}
.btn.main{background:var(--pink);color:#1a0a24}.btn.alt{color:var(--text);background:transparent}
.note{color:var(--muted);font-size:14px;text-align:center}
h2{color:var(--gold);font-size:28px;margin:48px 0 18px}
.grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(240px,1fr));gap:14px}
.card{background:var(--panel);border:1px solid var(--line);border-radius:12px;padding:16px 18px}.card b{color:var(--gold);display:block;margin-bottom:4px}
.shots img{width:100%;border-radius:10px;border:2px solid var(--line);margin-bottom:18px;display:block}
footer{color:var(--muted);text-align:center;padding:40px 0 60px;font-size:14px}
</style></head><body>
<header><div class="wrap">
<img src="/logo.png" alt="${esc(info.name)}">
<div class="tag">Dodge. Loot. Survive.</div>
<p class="sub">A pixel-art bullet-hell MMO inspired by Realm of the Mad God. Team up in shared realms, battle 47 hand-drawn bosses, raid the Starfall Vault, and build your guild a home.</p>
<div class="live"><span class="pill"><span class="dot"></span><b>${info.online}</b> playing now</span>
${info.season ? '<span class="pill">' + esc(info.season.name) + (info.season.leader ? ': led by <b>' + esc(info.season.leader) + '</b>' : '') + '</span>' : ''}</div>
<div class="cta"><a class="btn main" href="/play">Play in your browser</a>
${info.launcher ? '<a class="btn alt" href="/EldmereLauncher.swf" download>Download the launcher</a>' : ''}
${info.discord ? '<a class="btn alt" href="' + esc(info.discord) + '">Join the Discord</a>' : ''}</div>
<p class="note">Browser play runs through Ruffle and is in beta.${info.launcher ? ' The launcher (a small Flash file) always runs the latest version.' : ''}</p>
</div></header>
<main class="wrap">
${video ? '<div class="shots"><video src="/promo/eldmere_gameplay.mp4" autoplay muted loop playsinline' + (hero ? ' poster="' + hero + '"' : '') + ' style="width:100%;border-radius:10px;border:2px solid var(--line);display:block;margin-bottom:18px"></video></div>'
  : hero ? '<div class="shots"><img src="' + hero + '" alt="A boss fight in Eldmere"></div>' : ''}
<h2>What's in Eldmere</h2>
<div class="grid">${FEATURES.map(([t, d]) => '<div class="card"><b>' + esc(t) + '</b>' + esc(d) + '</div>').join('')}</div>
${shots.length ? '<h2>Screenshots</h2><div class="shots">' + shots.map(([f, a]) => '<img loading="lazy" src="/promo/' + f + '" alt="' + esc(a) + '">').join('') + '</div>' : ''}
</main>
<footer>${esc(info.name)}${info.discord ? ' · <a href="' + esc(info.discord) + '">Discord</a>' : ''}</footer>
</body></html>`;
}

/** The game in the browser, pointed at this server (host and port as the page was reached). */
function play(info) {
  return `<!doctype html>
<html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Play ${esc(info.name)}</title><link rel="icon" href="/logo.png">
<style>html,body{margin:0;height:100%;background:#0e0a16;color:#eee6ff;font:15px system-ui,sans-serif}
#game{width:100vw;height:calc(100vh - 34px)}#bar{height:34px;display:flex;align-items:center;justify-content:space-between;padding:0 14px;background:#1a1226}
a{color:#ffcd46}</style></head><body>
<div id="bar"><a href="/">&larr; ${esc(info.name)}</a><span>Browser play (beta). Click the game once to give it the keyboard.</span></div>
<div id="game"></div>
<script>
var host = location.hostname, port = Number(location.port) || (location.protocol === 'https:' ? 443 : 80);
window.RufflePlayer = window.RufflePlayer || {};
window.RufflePlayer.config = { autoplay: 'on', unmuteOverlay: 'hidden', splashScreen: false, letterbox: 'on',
  socketProxy: [{ host: host, port: port, proxyUrl: (location.protocol === 'https:' ? 'wss://' : 'ws://') + location.host }] };
</script>
<script src="${RUFFLE}"></script>
<script>
var player = window.RufflePlayer.newest().createPlayer();
player.style.width = '100%'; player.style.height = '100%';
document.getElementById('game').appendChild(player);
player.load({ url: '/NewRealm.swf', parameters: { server: host + ':' + port } });
</script></body></html>`;
}

/** Static files the pages use: [path on disk, type] or null. */
function file(urlPath) {
  if (urlPath === '/logo.png') return [LOGO, 'image/png'];
  if (urlPath === '/EldmereLauncher.swf') return fs.existsSync(LAUNCHER) ? [LAUNCHER, 'application/x-shockwave-flash'] : null;
  const m = /^\/promo\/([a-z0-9_]+)\.(png|gif|mp4)$/.exec(urlPath);
  if (m) return [path.join(PROMO, m[1] + '.' + m[2]), { png: 'image/png', gif: 'image/gif', mp4: 'video/mp4' }[m[2]]];
  return null;
}

module.exports = { landing, play, file, hasLauncher: () => fs.existsSync(LAUNCHER) };
