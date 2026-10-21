"""Draws every boss design, writes a preview sheet and src/realm/BossArt.as."""
import sys, os
sys.path.insert(0, os.path.dirname(__file__))
from designs import DESIGNS
from monsters_a import MONSTERS as MA
from monsters_b import MONSTERS as MB
from monsters_c import MONSTERS as MC
from raidprops import PROPS
# bosses first, then every monster that used to share another's drawing, then the raids' objectives
DESIGNS = DESIGNS + MA + MB + MC + PROPS
from canvas import preview
from animate import frames as animate

out = []
for name, fn, pal, scale in DESIGNS:
    frames, pal = animate(fn, pal)
    out.append((name, frames, pal, scale))
# Vorgath: an animation for each of his attacks (see vorgath.py)
from vorgath import sequences
out += sequences()
# the Dark Elder: the same (see elder.py)
import elder
out += elder.sequences()
# the Abyssal Herald and its spawn (see herald.py)
import herald
out += herald.sequences()
# Tempestus, Heart of the Storm (see tempestus.py)
import tempestus
out += tempestus.sequences()
# Archon Vesper, Architect of Void-Time (see vesper.py)
import vesper
out += vesper.sequences()
# Nerezza, the Tide Empress: the user's own art, kept as drawn (see nerezza.py)
import nerezza
out += nerezza.sequences()
# Gorehorn the Behemoth: the user's own art, kept as drawn (see gorehorn.py)
import gorehorn
out += gorehorn.sequences()
# sprites that reuse another's frames with a palette of their own (Nerezza's and Gorehorn's attacks in their rage colours)
RECOLORS = nerezza.recolors() + gorehorn.recolors()

if len(sys.argv) > 1:
    preview([(n, f, p) for n, f, p, s in out], sys.argv[1])

def as3_rows(rows):
    return '[' + ', '.join('"' + r + '"' for r in rows) + ']'


def rle(row):
    """Runs of three or more of a letter written as count + letter (big sprites only; their palettes have no digits)."""
    out, i = [], 0
    while i < len(row):
        j = i
        while j < len(row) and row[j] == row[i]:
            j += 1
        n = j - i
        out.append(row[i] * n if n < 3 else str(n) + row[i])
        i = j
    return ''.join(out)


# a later design of the same name replaces an earlier one (Nerezza's own art over her old drawing)
latest = {}
for i, d in enumerate(out):
    latest[d[0]] = i
out = [d for i, d in enumerate(out) if latest[d[0]] == i]

lines = []
for name, frames, pal, scale in out:
    packed = len(frames[0][0]) > 120
    if packed:
        frames = [[rle(r) for r in f] for f in frames]
    lines.append('\t\t\t' + name + ': [[' + ', '.join(as3_rows(f) for f in frames) + '], {' +
                 ', '.join('"%s": 0x%06x' % (k, v) for k, v in pal.items()) + '}, ' + str(scale) + (', 1' if packed else '') + ']')
src = '''package realm {
	/**
	 * Boss art drawn by tools/bossart (python3 tools/bossart/build.py): every boss
	 * gets a design of its own, bigger and more detailed than the old 16x16 ones.
	 * Generated: edit the designs there, not this file.
	 */
	public class BossArt {
		public static const ART:Object = {
''' + ',\n'.join(lines) + '''
		};

		/** Sprites drawn from another's frames with a palette of their own: name -> [base, palette]. */
		public static const RECOLORS:Object = {
''' + ',\n'.join('\t\t\t' + n + ': ["' + b + '", {' + ', '.join('"%s": 0x%06x' % (k, v) for k, v in pal.items()) + '}]' for n, b, pal in RECOLORS) + '''
		};

		/** Puts every design in place (over any older recoloured art of the same name). */
		public static function register():void {
			for (var name:String in ART) Sprites.define(name, ART[name][3] ? unpack(ART[name][0]) : ART[name][0], ART[name][1], ART[name][2]);
			// smaller copies: the little slimes that big ones split into
			Sprites.define("slimelet", ART.slime[0], ART.slime[1], 2);
			Sprites.define("green_slimelet", ART.green_slime[0], ART.green_slime[1], 2);
			Sprites.define("ooze", ART.slime_god[0], ART.slime_god[1], 2);
			for (var rc:String in RECOLORS) Sprites.recolor(rc, RECOLORS[rc][0], RECOLORS[rc][1]);
		}

		/** Big sprites' rows are run-length packed ("12." is twelve dots): unpacks every frame. */
		private static function unpack(frames:Array):Array {
			var out:Array = [];
			for each (var f:Array in frames) {
				var rows:Array = [];
				for each (var r:String in f) {
					var parts:Array = [], n:int = 0;
					for (var i:int = 0; i < r.length; i++) {
						var c:int = r.charCodeAt(i);
						if (c >= 48 && c <= 57) { n = n * 10 + (c - 48); continue; }
						var ch:String = r.charAt(i);
						if (n > 0) { for (var k:int = 0; k < n; k++) parts.push(ch); n = 0; }
						else parts.push(ch);
					}
					rows.push(parts.join(""));
				}
				out.push(rows);
			}
			return out;
		}
	}
}
'''
root = os.path.join(os.path.dirname(__file__), '..', '..')
open(os.path.join(root, 'src', 'realm', 'BossArt.as'), 'w').write(src)
print('wrote', len(out), 'designs')
