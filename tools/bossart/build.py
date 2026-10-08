"""Draws every boss design, writes a preview sheet and src/realm/BossArt.as."""
import sys, os
sys.path.insert(0, os.path.dirname(__file__))
from designs import DESIGNS
from canvas import preview
from animate import frames as animate

out = []
for name, fn, pal, scale in DESIGNS:
    frames, pal = animate(fn, pal)
    out.append((name, frames, pal, scale))

if len(sys.argv) > 1:
    preview([(n, f, p) for n, f, p, s in out], sys.argv[1])

def as3_rows(rows):
    return '[' + ', '.join('"' + r + '"' for r in rows) + ']'

lines = []
for name, frames, pal, scale in out:
    lines.append('\t\t\t' + name + ': [[' + ', '.join(as3_rows(f) for f in frames) + '], {' +
                 ', '.join('"%s": 0x%06x' % (k, v) for k, v in pal.items()) + '}, ' + str(scale) + ']')
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

		/** Puts every design in place (over any older recoloured art of the same name). */
		public static function register():void {
			for (var name:String in ART) Sprites.define(name, ART[name][0], ART[name][1], ART[name][2]);
		}
	}
}
'''
root = os.path.join(os.path.dirname(__file__), '..', '..')
open(os.path.join(root, 'src', 'realm', 'BossArt.as'), 'w').write(src)
print('wrote', len(out), 'designs')
