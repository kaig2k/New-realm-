package realm {
	import flash.display.Bitmap;
	import flash.display.Sprite;
	import flash.text.TextField;

	/** Party and guild window (L, or the people button in the sidebar). */
	public class SocialWindow extends Sprite {
		public static const W:int = 440, H:int = 540;
		private static const PER_PAGE:int = 8;

		private var g:Game;
		public var tab:int = 0;
		private var page:int = 0;
		private var body:Sprite = new Sprite();
		private var tabBtns:Sprite = new Sprite();

		public function SocialWindow(g:Game) {
			this.g = g;
			Ui.panel(graphics, 0, 0, W, H, 0x1c1c22, 0x6a8aff, 0.97);
			tabBtns.y = 12;
			addChild(tabBtns);
			body.y = 56;
			addChild(body);
			var close:Sprite = Ui.button("X", 30, 28, function():void { g.toggleSocial(); }, 14);
			close.x = W - 42; close.y = 12;
			addChild(close);
			show(0);
		}

		public function show(t:int):void {
			if (t != tab) page = 0;
			tab = t;
			refresh();
		}

		public function refresh():void {
			tabBtns.removeChildren();
			var names:Array = ["Party", "Guild"];
			for (var i:int = 0; i < 2; i++) {
				var b:Sprite = Ui.button((i == tab ? "> " : "") + names[i], 130, 30, tabFn(i), 15);
				b.x = 14 + i * 136;
				b.alpha = i == tab ? 1 : 0.7;
				tabBtns.addChild(b);
			}
			body.removeChildren();
			if (tab == 0) buildParty(); else buildGuild();
		}

		private function tabFn(i:int):Function { return function():void { show(i); }; }

		private function text(html:String, x:int, y:int, size:int = 14, w:int = 400):TextField {
			var tf:TextField = Ui.text(size, 0xdddddd, true, "left", w, true);
			tf.htmlText = html;
			tf.x = x; tf.y = y;
			body.addChild(tf);
			return tf;
		}

		private function btn(label:String, x:int, y:int, w:int, fn:Function, h:int = 26, size:int = 12):Sprite {
			var b:Sprite = Ui.button(label, w, h, fn, size);
			b.x = x; b.y = y;
			body.addChild(b);
			return b;
		}

		private function face(spr:String, x:int, y:int):void {
			var bm:Bitmap = new Bitmap(Sprites.get(spr));
			bm.scaleX = bm.scaleY = 0.6;
			bm.x = x; bm.y = y;
			body.addChild(bm);
		}

		// ------------------------------------------------------------ party
		private function buildParty():void {
			var net:Net = g.net;
			text("<font color='#7fd8ff'>Party</font>  <font color='#9a9aaa'>" + (net.party.length ? net.party.length + 1 : 1) + "/" + Net.PARTY_MAX + "</font>", 16, 0, 20);
			var y:int = 38;
			face(g.player.spriteId, 16, y);
			text(g.player.name + " <font color='#9a9aaa' size='12'>(you)  Lv " + g.player.level + " " + g.player.cls.name + "</font>", 52, y + 4);
			y += 40;
			for each (var rp:RemotePlayer in net.party) {
				face(rp.spriteId, 16, y);
				text("<font color='#7fd8ff'>" + rp.name + "</font> <font color='#9a9aaa' size='12'>Lv " + rp.profile.level + " " + rp.cls.name + "</font>", 52, y + 4, 14, 220);
				btn("Teleport", 262, y + 2, 76, tpFn(rp));
				btn("Kick", 344, y + 2, 76, kickFn(rp));
				y += 40;
			}
			if (!net.party.length) {
				text("<font color='#9a9aaa' size='13'>You're not in a party. Click a player and choose <b>Invite to party</b>, " +
					"or type /party invite name. Party members follow you into realms and dungeons and fight beside you.</font>", 16, y + 4, 13, W - 32);
			} else {
				btn("Leave party", 16, H - 56 - 78, 140, function():void { net.leaveParty(); }, 32, 14);
			}
			text("<font color='#8a8a9a' size='12'>/p message: party chat.  Party members show in blue.  Max " + Net.PARTY_MAX + " players.</font>", 16, H - 56 - 34, 12, W - 32);
		}

		private function tpFn(rp:RemotePlayer):Function { return function():void { g.teleportTo(rp); }; }
		private function kickFn(rp:RemotePlayer):Function { return function():void { g.net.kickParty(rp); }; }

		// ------------------------------------------------------------ guild
		private function buildGuild():void {
			var net:Net = g.net;
			var gd:Object = net.guild;
			if (!gd) {
				text("<font color='#80ff80'>Guild</font>", 16, 0, 20);
				text("<font color='#cccccc' size='13'>You're not in a guild.\n\nFound your own for " + Ui.commas(Net.GUILD_COST) +
					" gold, then invite players from their menu (click a player, <b>Invite to guild</b>). Guilds hold up to " + Net.GUILD_MAX +
					" members, have their own chat (/g) and you can teleport to guild members.</font>", 16, 40, 13, W - 32);
				btn("Create a guild (" + Ui.commas(Net.GUILD_COST) + "g)", 16, 190, 240, function():void { g.toggleSocial(); g.chatWith("/guild create "); }, 34, 14);
				return;
			}
			var members:Array = gd.members.concat();
			members.sortOn(["rank", "name"], [Array.NUMERIC | Array.DESCENDING, 0]);
			text("<font color='#80ff80'>" + gd.name + "</font>  <font color='#9a9aaa'>" + (members.length + 1) + "/" + Net.GUILD_MAX + "</font>", 16, 0, 20);
			text("<font color='#9a9aaa' size='12'>You are " + Net.RANKS[gd.myRank] + "</font>", 16, 26, 12);
			var pages:int = Math.max(1, Math.ceil(members.length / PER_PAGE));
			if (page >= pages) page = pages - 1;
			var y:int = 50;
			for (var i:int = page * PER_PAGE; i < Math.min(members.length, (page + 1) * PER_PAGE); i++) {
				var m:Object = members[i];
				var st:String = net.guildStatus(m.name);
				var dot:String = st == "here" ? "#5ae06a" : st == "online" ? "#e0d060" : "#666666";
				face(m.cls, 16, y - 2);
				text("<font color='" + dot + "'>●</font> " + m.name + "  <font size='11' color='#9a9aaa'>" + Net.RANKS[m.rank] +
					(st == "here" ? ", here" : st == "online" ? ", online" : "") + "</font>", 48, y + 2, 13, 220);
				if (gd.myRank >= Net.OFFICER && m.rank < gd.myRank) {
					if (m.rank + 1 < gd.myRank) btn("+", 268, y, 30, rankFn(m.name, m.rank + 1));
					if (m.rank > 0) btn("-", 302, y, 30, rankFn(m.name, m.rank - 1));
					btn("Kick", 336, y, 70, gkickFn(m.name));
				}
				y += 38;
			}
			if (!members.length) text("<font color='#9a9aaa' size='13'>No members yet. Click a player and choose <b>Invite to guild</b>.</font>", 16, y, 13, W - 32);
			if (pages > 1) {
				btn("<", 16, H - 56 - 118, 40, function():void { page = (page + pages - 1) % pages; refresh(); });
				text("Page " + (page + 1) + "/" + pages, 64, H - 56 - 114, 13, 100);
				btn(">", 150, H - 56 - 118, 40, function():void { page = (page + 1) % pages; refresh(); });
			}
			btn(gd.myRank == Net.FOUNDER ? "Disband guild" : "Leave guild", 16, H - 56 - 78, 150, function():void { net.leaveGuild(); }, 32, 14);
			text("<font color='#8a8a9a' size='12'>/g message: guild chat.  Guild members show in green.  Officers can invite; + / - change ranks.</font>", 16, H - 56 - 34, 12, W - 32);
		}

		private function rankFn(name:String, r:int):Function { return function():void { g.net.setRank(name, r); }; }
		private function gkickFn(name:String):Function { return function():void { g.net.kickGuild(name); }; }
	}
}
