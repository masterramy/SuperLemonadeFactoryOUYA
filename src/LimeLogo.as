// Modified for the independent Super Limeade Factory Android restoration by Ramy Baheeg, 2026.
package
{
	import flash.display.Bitmap;
	import flash.display.BitmapData;

	/**
	 * Canonical Super Limeade Factory Android-edition logo.
	 *
	 * The original Super Lemonade Factory logo remains preserved separately in
	 * the corresponding source history. The release logo is a deliberately
	 * modified lime-green treatment with the Android-edition title baked into
	 * its own source asset so the public identity does not depend on a runtime
	 * palette heuristic.
	 */
	public class LimeLogo extends Bitmap
	{
		[Embed(source = "../data/logo_limeade.png")] private static var SourceLogo:Class;

		public function LimeLogo()
		{
			var source:Bitmap = new SourceLogo() as Bitmap;
			super(source.bitmapData.clone());
			smoothing = false;
		}
	}
}
