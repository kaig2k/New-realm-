package realm {
	import flash.events.Event;
	import flash.events.SampleDataEvent;
	import flash.media.Sound;
	import flash.media.SoundChannel;
	import flash.utils.ByteArray;

	/**
	 * Procedurally synthesised sound effects (no audio files): each sound is
	 * rendered once into a PCM buffer and streamed through a dynamic Sound.
	 */
	public class Sfx {
		private static const RATE:int = 44100;
		private static const MAX_PLAYING:int = 10;
		private static var buffers:Object;
		private static var playing:int = 0;
		private static var lastPlayed:Object = {};

		public static function get muted():Boolean { return Save.data.muted == true; }
		public static function set muted(v:Boolean):void { Save.data.muted = v; Save.flush(); }

		/** Master volume, 0..1 (saved with the account). */
		public static function get volume():Number { return Save.data.vol == undefined ? 0.8 : Number(Save.data.vol); }
		public static function set volume(v:Number):void { Save.data.vol = Math.max(0, Math.min(1, v)); Save.flush(); }

		private static function init():void {
			buffers = {};
			// tiny laser blip
			buffers.shoot = synth(0.06, function(t:Number, p:Number):Number { return sq(t, 900 - 500 * p) * 0.18 * (1 - p); });
			buffers.hit = synth(0.05, function(t:Number, p:Number):Number { return noise() * 0.25 * (1 - p); });
			buffers.kill = synth(0.18, function(t:Number, p:Number):Number { return (sq(t, 300 - 220 * p) * 0.5 + noise() * 0.5) * 0.3 * (1 - p); });
			buffers.hurt = synth(0.12, function(t:Number, p:Number):Number { return (sin(t, 140 - 60 * p) + noise() * 0.4) * 0.45 * (1 - p); });
			buffers.ability = synth(0.25, function(t:Number, p:Number):Number { return sin(t, 300 + 900 * p) * 0.3 * (1 - p) + sq(t, 150 + 450 * p) * 0.08 * (1 - p); });
			buffers.loot = synth(0.25, function(t:Number, p:Number):Number { return sin(t, p < 0.5 ? 880 : 1320) * 0.25 * (1 - p); });
			buffers.rare = synth(0.8, function(t:Number, p:Number):Number {
				var f:Number = [1046, 1318, 1568, 2093][int(p * 4)];
				return (sin(t, f) + sin(t, f * 2) * 0.3) * 0.25 * (1 - p * 0.8);
			});
			buffers.level = synth(0.5, function(t:Number, p:Number):Number {
				var f:Number = [523, 659, 784, 1046][int(p * 4)];
				return sq(t, f) * 0.12 * (1 - p * 0.5);
			});
			buffers.portal = synth(0.45, function(t:Number, p:Number):Number { return sin(t, 200 + 600 * p * p) * 0.3 * Math.sin(p * Math.PI) + noise() * 0.06; });
			buffers.boss = synth(0.9, function(t:Number, p:Number):Number { return (sin(t, 55) + sin(t, 82) * 0.6 + noise() * 0.2) * 0.4 * (1 - p); });
			buffers.coin = synth(0.2, function(t:Number, p:Number):Number { return sin(t, p < 0.35 ? 1568 : 2093) * 0.22 * (1 - p); });
			buffers.click = synth(0.04, function(t:Number, p:Number):Number { return sq(t, 1200) * 0.1 * (1 - p); });
			buffers.trade = synth(0.5, function(t:Number, p:Number):Number {
				var f:Number = [784, 988, 1175][int(p * 3)];
				return (sin(t, f) + sin(t, f * 1.5) * 0.25) * 0.22 * (1 - p * 0.6);
			});
			// ability sounds
			var lp:Number = 0;
			buffers.boom = synth(0.55, function(t:Number, p:Number):Number {
				lp += (noise() - lp) * (0.25 - p * 0.2);
				return (lp * 1.6 + sin(t, 70 - 40 * p) * 0.5) * 0.55 * Math.pow(1 - p, 1.6);
			});
			var lw:Number = 0;
			buffers.whoosh = synth(0.3, function(t:Number, p:Number):Number {
				lw += (noise() - lw) * (0.05 + Math.sin(p * Math.PI) * 0.3);
				return lw * 0.9 * Math.sin(p * Math.PI);
			});
			buffers.clang = synth(0.6, function(t:Number, p:Number):Number {
				return (sin(t, 523) * 0.5 + sin(t, 787) * 0.35 + sin(t, 1311) * 0.2 + (p < 0.03 ? noise() * 0.6 : 0)) * 0.3 * Math.pow(1 - p, 2.2);
			});
			buffers.holy = synth(0.9, function(t:Number, p:Number):Number {
				return (sin(t, 659) + sin(t, 831) * 0.7 + sin(t, 988) * 0.6 + sin(t, 1318) * 0.3 * (1 - p)) * 0.12 * Math.min(1, p * 12) * (1 - p);
			});
			buffers.arrows = synth(0.5, function(t:Number, p:Number):Number {
				var ph:Number = (p * 6) % 1;
				return (ph < 0.15 ? noise() * (1 - ph / 0.15) : 0) * 0.35 + sin(t, 1800 - 1200 * ph) * 0.05 * (1 - ph);
			});
			var lv:Number = 0;
			buffers.vines = synth(0.6, function(t:Number, p:Number):Number {
				lv += (noise() - lv) * 0.12;
				return lv * 0.8 * (0.6 + 0.4 * Math.sin(t * 60)) * Math.sin(p * Math.PI);
			});
			buffers.status = synth(0.2, function(t:Number, p:Number):Number { return sq(t, 220 + 40 * Math.sin(p * 40)) * 0.15 * (1 - p); });
			bossVoices();
			classSounds();
			monsterSounds();
		}

		// ---------------------------------------------------------------- boss voices
		/** Each boss family has its own voice for its entrance, phase changes and death (see voiceOf). */
		private static function bossVoices():void {
			var a:Number = 0, b:Number = 0;
			// beasts and dragons: a ragged roar that drops in pitch
			buffers.v_beast = synth(1.1, function(t:Number, p:Number):Number {
				a += (noise() - a) * 0.18;
				var f:Number = 150 - 80 * p + Math.sin(t * 38) * 9;
				return (saw(t, f) * 0.55 + saw(t, f * 1.5) * 0.2 + a * 0.6) * 0.42 * env(p, 0.08, 1.4);
			});
			// the undead: two detuned voices that waver, and a cold wind
			buffers.v_undead = synth(1.3, function(t:Number, p:Number):Number {
				a += (noise() - a) * 0.04;
				var trem:Number = 0.6 + 0.4 * Math.sin(t * 22);
				return ((sin(t, 220 - 30 * p) + sin(t, 233 - 34 * p) + sin(t, 330) * 0.3) * 0.22 * trem + a * 0.5) * env(p, 0.25, 1.2);
			});
			// stone and giants: a deep rumble with heavy footfalls
			buffers.v_stone = synth(1.2, function(t:Number, p:Number):Number {
				a += (noise() - a) * 0.03;
				var thud:Number = 0;
				for each (var at:Number in [0, 0.35, 0.7]) if (p >= at && p < at + 0.12) thud = sin(t, 48 - (p - at) * 120) * (1 - (p - at) / 0.12);
				return (a * 1.3 + sin(t, 38) * 0.35 + thud * 0.8) * 0.5 * env(p, 0.02, 1.1);
			});
			// the sea: a gurgling wash with bubbles
			buffers.v_sea = synth(1.1, function(t:Number, p:Number):Number {
				a += (noise() - a) * 0.06;
				var bub:Number = (p * 14) % 1;
				return (a * 0.7 + sin(t, 300 + 900 * bub) * 0.18 * (1 - bub) + sin(t, 70) * 0.3) * 0.5 * env(p, 0.1, 1);
			});
			// fire: a roaring blaze full of crackles
			buffers.v_fire = synth(1.1, function(t:Number, p:Number):Number {
				a += (noise() - a) * (0.1 + 0.15 * Math.sin(p * Math.PI));
				var pop:Number = Math.random() < 0.004 ? noise() * 3 : 0;
				return (a * 1.2 + pop * 0.3 + sin(t, 90 - 30 * p) * 0.25) * 0.45 * env(p, 0.1, 1.2);
			});
			// frost: glassy chimes over a thin wind
			buffers.v_frost = synth(1.2, function(t:Number, p:Number):Number {
				a += (noise() - a) * 0.02;
				var f:Number = [1760, 2349, 2637, 3136][int(p * 8) % 4];
				return (sin(t, f) * 0.18 * (1 - (p * 8) % 1) + sin(t, f * 1.01) * 0.08 + a * 0.6) * env(p, 0.02, 1);
			});
			// stars and seraphs: a bright chord that swells and shimmers
			buffers.v_star = synth(1.3, function(t:Number, p:Number):Number {
				var sh:Number = 0.7 + 0.3 * Math.sin(t * 50);
				return (sin(t, 523) + sin(t, 659) * 0.8 + sin(t, 784) * 0.7 + sin(t, 1046) * 0.5 * sh + sin(t, 1568) * 0.25 * sh) * 0.11 * env(p, 0.3, 1);
			});
			// demons and dark lords: a distorted growl
			buffers.v_demon = synth(1.2, function(t:Number, p:Number):Number {
				b += (noise() - b) * 0.08;
				var g:Number = sq(t, 55 + 10 * Math.sin(t * 9)) * (0.6 + 0.4 * sin(t, 31)) + saw(t, 82 - 20 * p) * 0.5 + b;
				return Math.max(-0.8, Math.min(0.8, g * 0.7)) * 0.5 * env(p, 0.05, 1.2);
			});
		}

		private static const VOICES:Array = [
			["v_beast", ["wyrm", "drake", "dragon", "phoenix", "behemoth", "wolf", "beast", "broodmother", "arachn", "minotaur", "sphinx", "gorehorn", "moth"]],
			["v_undead", ["lich", "hollow", "ghost", "phantom", "regent", "crypt", "warden", "skull", "shrine", "bone", "wraith", "septorius", "soul"]],
			["v_stone", ["golem", "titan", "colossus", "cube", "giant", "stone", "ogre", "ent", "dwarf"]],
			["v_sea", ["tide", "kraken", "sea", "sunken", "hermit", "serpent", "ssythra", "saltbeard", "pirate", "empress"]],
			["v_fire", ["pyre", "ember", "flame", "fire", "ignivar", "vorgath", "sun", "solhar", "blaze"]],
			["v_frost", ["frost", "glacius", "ice", "sylith", "snow", "moon", "lunara"]],
			["v_star", ["star", "seraph", "astr", "sprite", "lumina", "crystal", "tempest", "celest", "vault"]],
			["v_demon", ["demon", "elder", "blood", "hex", "witch", "malgoroth", "abyss", "dark", "sorcerer", "void", "morwyn", "kael"]]
		];
		private static var voiceCache:Object = {};

		/** The voice of a boss family, from its name and sprite ("v_beast", "v_undead"...). */
		public static function voiceOf(def:Object):String {
			if (!def) return "boss";
			var key:String = String(def.spr || "") + "|" + String(def.name || "");
			if (voiceCache[key]) return voiceCache[key];
			var low:String = key.toLowerCase();
			for each (var v:Array in VOICES) for each (var w:String in v[1]) if (low.indexOf(w) >= 0) return voiceCache[key] = v[0];
			return voiceCache[key] = "boss";
		}

		// ---------------------------------------------------------------- the newer classes
		private static function classSounds():void {
			// Bard: Valor, a rising run on the lyre
			buffers.lyre = synth(0.7, function(t:Number, p:Number):Number {
				var k:int = int(p * 6), q:Number = (p * 6) % 1;
				var f:Number = [392, 494, 587, 784, 988, 1175][k];
				return (pluck(t, f, q) + pluck(t, f * 2, q) * 0.3) * 0.3;
			});
			// Lullaby: a soft falling cradle song
			buffers.lull = synth(1.0, function(t:Number, p:Number):Number {
				var k:int = int(p * 4), q:Number = (p * 4) % 1;
				var f:Number = [784, 659, 587, 523][k];
				return (sin(t, f) + sin(t, f / 2) * 0.4) * 0.16 * Math.sin(q * Math.PI) * (1 - p * 0.4);
			});
			// Requiem: a deep minor chord and a toll
			buffers.requiem = synth(1.1, function(t:Number, p:Number):Number {
				var bell:Number = sin(t, 196) * Math.exp(-p * 5) + sin(t, 523) * 0.3 * Math.exp(-p * 9);
				return (sin(t, 98) * 0.5 + sin(t, 117) * 0.4 + sin(t, 147) * 0.35 + bell) * 0.2 * env(p, 0.02, 1);
			});
			// Alchemist: acid bubbling, a potion glug, a fizzing bomb
			buffers.bubble = synth(0.6, function(t:Number, p:Number):Number {
				var q:Number = (p * 11 + Math.sin(p * 30) * 0.3) % 1;
				return sin(t, 260 + 700 * q) * 0.25 * (1 - q) * (1 - p * 0.5);
			});
			buffers.glug = synth(0.5, function(t:Number, p:Number):Number {
				var q:Number = (p * 4) % 1;
				return (sin(t, 180 + 160 * q) * (1 - q) + sin(t, 620 + 300 * p) * 0.15) * 0.3 * (1 - p * 0.5);
			});
			var lf:Number = 0;
			buffers.fizz = synth(0.5, function(t:Number, p:Number):Number {
				lf += (noise() - lf) * 0.7;
				return lf * 0.35 * Math.sin(p * Math.PI) + sin(t, 1400 + 600 * p) * 0.05;
			});
			// Chronomancer: time running backwards, the world stopping, a quickened clock
			buffers.rewind = synth(0.6, function(t:Number, p:Number):Number {
				var q:Number = 1 - p;
				return (sin(t, 300 + 1200 * q * q) * 0.25 + sq(t, 80 + 300 * q) * 0.05) * Math.sin(p * Math.PI);
			});
			buffers.freeze = synth(1.0, function(t:Number, p:Number):Number {
				var tick:Number = p < 0.06 ? noise() * (1 - p / 0.06) : 0;
				return tick * 0.5 + (sin(t, 1318) + sin(t, 1975) * 0.6 + sin(t, 2637) * 0.3) * 0.12 * Math.exp(-p * 2.5);
			});
			buffers.ticks = synth(0.6, function(t:Number, p:Number):Number {
				var q:Number = (p * 8) % 1;
				return (q < 0.08 ? sin(t, 2400) * (1 - q / 0.08) : 0) * 0.35 + sin(t, 880 + 440 * p) * 0.06;
			});
		}

		// ---------------------------------------------------------------- monster families
		private static function monsterSounds():void {
			var ln:Number = 0;
			// a thrown dagger whirring through the air
			buffers.toss = synth(0.25, function(t:Number, p:Number):Number {
				ln += (noise() - ln) * 0.4;
				return ln * 0.4 * (0.5 + 0.5 * Math.sin(t * 160)) * (1 - p);
			});
			// web spit and its wet landing
			buffers.spit = synth(0.18, function(t:Number, p:Number):Number { return (noise() * 0.5 + sin(t, 500 - 300 * p) * 0.4) * 0.35 * (1 - p); });
			buffers.splat = synth(0.25, function(t:Number, p:Number):Number {
				ln += (noise() - ln) * 0.15;
				return (ln * 1.2 + sin(t, 140 - 80 * p) * 0.4) * 0.45 * Math.pow(1 - p, 2);
			});
			// a golem's ground slam: the heavy thud and the shock
			buffers.slam = synth(0.6, function(t:Number, p:Number):Number {
				ln += (noise() - ln) * 0.06;
				return (sin(t, 55 - 25 * p) * 0.9 + ln * 1.4) * 0.6 * Math.pow(1 - p, 1.8);
			});
			// a slime bursting into little ones
			buffers.squish = synth(0.3, function(t:Number, p:Number):Number {
				var q:Number = (p * 3) % 1;
				return sin(t, 200 + 500 * q) * 0.3 * (1 - q) * (1 - p * 0.5);
			});
			// a ghost slipping through a wall
			buffers.wail = synth(0.7, function(t:Number, p:Number):Number {
				return (sin(t, 440 + 120 * Math.sin(p * 7)) + sin(t, 445 + 120 * Math.sin(p * 7)) * 0.7) * 0.12 * Math.sin(p * Math.PI);
			});
			// a fanfare for earned titles, banners and seasons
			buffers.fanfare = synth(1.0, function(t:Number, p:Number):Number {
				var k:int = int(p * 5), f:Number = [523, 659, 784, 659, 1046][k];
				return (sq(t, f) * 0.1 + sin(t, f) * 0.2 + sin(t, f * 2) * 0.06) * (k == 4 ? 1 - (p * 5 - 4) * 0.7 : 1);
			});
		}

		private static function saw(t:Number, f:Number):Number { return ((t * f) % 1) * 2 - 1; }
		/** A plucked string: bright at first, fading fast. q: 0..1 through the note. */
		private static function pluck(t:Number, f:Number, q:Number):Number { return (sin(t, f) + sin(t, f * 2) * 0.4 * (1 - q)) * Math.exp(-q * 5); }
		/** Fades in over `att` (fraction of the sound) and out with power `rel`. */
		private static function env(p:Number, att:Number, rel:Number):Number { return Math.min(1, p / Math.max(0.001, att)) * Math.pow(1 - p, rel); }

		private static function sin(t:Number, f:Number):Number { return Math.sin(t * f * Math.PI * 2); }
		private static function sq(t:Number, f:Number):Number { return (t * f) % 1 < 0.5 ? 1 : -1; }
		private static function noise():Number { return Math.random() * 2 - 1; }

		/** fn(timeSeconds, progress0to1) -> sample in -1..1 */
		private static function synth(dur:Number, fn:Function):ByteArray {
			var n:int = Math.max(2048, int(dur * RATE));
			var b:ByteArray = new ByteArray();
			for (var i:int = 0; i < n; i++) {
				var t:Number = i / RATE;
				var v:Number = t < dur ? fn(t, t / dur) : 0;
				if (v > 1) v = 1; else if (v < -1) v = -1;
				b.writeFloat(v);
			}
			return b;
		}

		/** Play a named effect; rapid repeats of the same sound are throttled. */
		public static function play(name:String, vol:Number = 1, minGap:Number = 0.05):void {
			if (muted || playing >= MAX_PLAYING) return;
			vol *= volume;
			if (vol <= 0.001) return;
			try {
				if (!buffers) init();
				var buf:ByteArray = buffers[name];
				if (!buf) return;
				var now:Number = new Date().time / 1000;
				if (lastPlayed[name] && now - lastPlayed[name] < minGap) return;
				lastPlayed[name] = now;
				var pos:int = 0;
				var snd:Sound = new Sound();
				snd.addEventListener(SampleDataEvent.SAMPLE_DATA, function(e:SampleDataEvent):void {
					buf.position = pos;
					var n:int = 0;
					while (n < 4096 && buf.bytesAvailable >= 4) {
						var v:Number = buf.readFloat() * vol;
						e.data.writeFloat(v);
						e.data.writeFloat(v);
						n++;
					}
					pos = buf.position;
				});
				var ch:SoundChannel = snd.play();
				if (ch) {
					playing++;
					ch.addEventListener(Event.SOUND_COMPLETE, function(e:Event):void { playing--; });
				}
			} catch (err:Error) {
				// audio unavailable: stay silent
			}
		}
	}
}
