package
{
	import flash.display.Bitmap;
	import flash.display.BitmapData;

	/**
	 * Android-edition logo treatment. Only the embedded Super Lemonade Factory
	 * logo is processed; no shared level/UI palettes are touched.
	 *
	 * The source PNG remains unchanged in the repository. Warm lemon-yellow
	 * pixels are shifted into a lime-green range while alpha, black lettering,
	 * whites, and non-yellow artwork are preserved.
	 */
	public class LimeLogo extends Bitmap
	{
		[Embed(source = "../data/logo.png")] private static var SourceLogo:Class;

		public function LimeLogo()
		{
			super(buildLimeLogo());
			smoothing = false;
		}

		private static function buildLimeLogo():BitmapData
		{
			var source:Bitmap = new SourceLogo() as Bitmap;
			var output:BitmapData = source.bitmapData.clone();
			var x:int;
			var y:int;
			var pixel:uint;
			var alpha:uint;
			var red:uint;
			var green:uint;
			var blue:uint;
			var limeRed:uint;
			var limeGreen:uint;
			var limeBlue:uint;

			output.lock();
			for (y = 0; y < output.height; y++)
			{
				for (x = 0; x < output.width; x++)
				{
					pixel = output.getPixel32(x, y);
					alpha = (pixel >>> 24) & 0xff;
					if (alpha == 0) continue;

					red = (pixel >>> 16) & 0xff;
					green = (pixel >>> 8) & 0xff;
					blue = pixel & 0xff;

					// Restrict the conversion to warm yellow/orange logo pixels.
					// Dark outlines, black type, white highlights and neutral tones stay put.
					if (red >= 110 && green >= 75 && blue <= 130 &&
						red > blue + 35 && green > blue + 25)
					{
						limeRed = uint(Math.min(255, red * 0.28 + green * 0.18));
						limeGreen = uint(Math.min(255, green * 0.80 + red * 0.08 + 20));
						limeBlue = uint(Math.min(255, blue * 0.50 + green * 0.06));
						output.setPixel32(x, y, uint((alpha << 24) | (limeRed << 16) | (limeGreen << 8) | limeBlue));
					}
				}
			}
			output.unlock();
			return output;
		}
	}
}
