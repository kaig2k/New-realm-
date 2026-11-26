# Promo screenshots

What `tools/promo/cards.py` builds the website's image cards from (`python3 tools/promo/cards.py` writes `promo/*.png`).

- `fight_*.png`, `lighthouse.png`: the real game at 1100 x 640, taken in the test player against a test server. An
  admin hero (`/maxhero`, `/gear`, `/guide off`), `/glands`, then `/aevent <boss>` (the boss just north of you, arena
  and all) or `/adungeon drowned_lighthouse`. A slow test player needs the `maxdt=0.45` flashvar, or bullets pile up.
- `roster_*.png`: every boss's sprite, from `tools/realmview` (`roster=0` .. `roster=6`).

Better shots from the real client can replace any of these: keep the names and the 1100 x 640 size.
