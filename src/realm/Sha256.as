package realm {
	import flash.utils.ByteArray;

	/** SHA-256 (used to store account passwords as salted hashes). */
	public class Sha256 {
		private static const K:Array = [
			0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5, 0x3956c25b, 0x59f111f1, 0x923f82a4, 0xab1c5ed5,
			0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3, 0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174,
			0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc, 0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da,
			0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7, 0xc6e00bf3, 0xd5a79147, 0x06ca6351, 0x14292967,
			0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13, 0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85,
			0xa2bfe8a1, 0xa81a664b, 0xc24b8b70, 0xc76c51a3, 0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070,
			0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5, 0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f, 0x682e6ff3,
			0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208, 0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2];

		public static function hash(s:String):String {
			var msg:ByteArray = new ByteArray();
			msg.writeUTFBytes(s);
			var bitLen:Number = msg.length * 8;
			msg.writeByte(0x80);
			while (msg.length % 64 != 56) msg.writeByte(0);
			msg.writeUnsignedInt(uint(bitLen / 4294967296));
			msg.writeUnsignedInt(uint(bitLen));

			var h0:uint = 0x6a09e667, h1:uint = 0xbb67ae85, h2:uint = 0x3c6ef372, h3:uint = 0xa54ff53a;
			var h4:uint = 0x510e527f, h5:uint = 0x9b05688c, h6:uint = 0x1f83d9ab, h7:uint = 0x5be0cd19;
			var w:Vector.<uint> = new Vector.<uint>(64, true);
			msg.position = 0;
			for (var chunk:int = 0; chunk < msg.length; chunk += 64) {
				var i:int;
				for (i = 0; i < 16; i++) w[i] = msg.readUnsignedInt();
				for (i = 16; i < 64; i++) {
					var x:uint = w[i - 15], y:uint = w[i - 2];
					var s0:uint = rotr(x, 7) ^ rotr(x, 18) ^ (x >>> 3);
					var s1:uint = rotr(y, 17) ^ rotr(y, 19) ^ (y >>> 10);
					w[i] = uint(w[i - 16] + s0 + w[i - 7] + s1);
				}
				var a:uint = h0, b:uint = h1, c:uint = h2, d:uint = h3, e:uint = h4, f:uint = h5, g:uint = h6, h:uint = h7;
				for (i = 0; i < 64; i++) {
					var S1:uint = rotr(e, 6) ^ rotr(e, 11) ^ rotr(e, 25);
					var ch:uint = (e & f) ^ (~e & g);
					var t1:uint = uint(h + S1 + ch + uint(K[i]) + w[i]);
					var S0:uint = rotr(a, 2) ^ rotr(a, 13) ^ rotr(a, 22);
					var maj:uint = (a & b) ^ (a & c) ^ (b & c);
					var t2:uint = uint(S0 + maj);
					h = g; g = f; f = e; e = uint(d + t1);
					d = c; c = b; b = a; a = uint(t1 + t2);
				}
				h0 = uint(h0 + a); h1 = uint(h1 + b); h2 = uint(h2 + c); h3 = uint(h3 + d);
				h4 = uint(h4 + e); h5 = uint(h5 + f); h6 = uint(h6 + g); h7 = uint(h7 + h);
			}
			return hex(h0) + hex(h1) + hex(h2) + hex(h3) + hex(h4) + hex(h5) + hex(h6) + hex(h7);
		}

		private static function rotr(x:uint, n:int):uint {
			return (x >>> n) | (x << (32 - n));
		}

		private static function hex(v:uint):String {
			var s:String = v.toString(16);
			while (s.length < 8) s = "0" + s;
			return s;
		}
	}
}
