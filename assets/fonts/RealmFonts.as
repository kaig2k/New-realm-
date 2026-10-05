package {
	import flash.display.Sprite;
	import flash.text.Font;

	/**
	 * Font library. Compiled separately (needs the Apache Flex SDK's mxmlc,
	 * because the AIR SDK compiler can't transcode TTF files) into
	 * RealmFonts.swf, which the game embeds and loads at startup.
	 *
	 *   mxmlc -source-path=. -output=RealmFonts.swf RealmFonts.as
	 */
	public class RealmFonts extends Sprite {
		[Embed(source="SourceSansPro-Semibold.ttf", fontName="Realm", fontWeight="normal", embedAsCFF="false", mimeType="application/x-font-truetype", unicodeRange="U+0020-U+007E,U+00B7,U+2013,U+2014,U+2022")]
		public static const Regular:Class;

		[Embed(source="SourceSansPro-Bold.ttf", fontName="Realm", fontWeight="bold", embedAsCFF="false", mimeType="application/x-font-truetype", unicodeRange="U+0020-U+007E,U+00B7,U+2013,U+2014,U+2022")]
		public static const Bold:Class;

		public function RealmFonts() {
			Font.registerFont(Regular);
			Font.registerFont(Bold);
		}
	}
}
