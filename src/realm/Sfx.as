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
			buffers.status = synth(0.2, function(t:Number, p:Number):Number { return sq(t, 220 + 40 * Math.sin(p * 40)) * 0.15 * (1 - p); });
		}

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
