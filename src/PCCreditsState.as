/*
 * Copyright (c) 2009 Initials Video Games
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

package
{
	import org.flixel.*;
	import org.flixel.plugin.photonstorm.*;

	public class PCCreditsState extends FlxState
	{
		public var portInfoStr:String =
			"SUPER LEMONADE FACTORY PORT\n\n" +
			"Independent Android port published by Ramy Baheeg\n" +
			"Based on the GPLv3-released OUYA source\n" +
			"Original game by Shane Brouwer / Initials\n" +
			"Not an official Initials publication or endorsement.\n" +
			"Source: github.com/masterramy/SuperLemonadeFactoryOUYA";

		public var creditsStr:String =
			"ORIGINAL GAME CREDITS\n\n" +
			"A Game By Shane Brouwer\n\nArt\nMiguelito\n\nMusic\nEasyname\n\nMarketing\nSurprise Attack\n\nIllustration\ndoggerland.deviantart.com\n\nIn Game Voice Talent\nRoy Kelly\nKellyCommaRoy {a} gmail.com\n\nTrailer Voice Talent\nTom Mitchell\n\nAdditional Art and Copywriting\nElizabeth Docking\n\nEngine\nFlixel\n\nLevel Editor\nOgmo Editor\n\nSound Effects\nbfxr\n\nSpecial Thanks\nAdam Atomic and Semi Secret Software. Thank you for Flixel.\n\nHokori Interactive - Brett Chalupa\nTonnes of help with this version.\n\nIQPierce\nCracked the code to allow custom fonts.\nCheck out his Flixel game Connectrode.\n\nScott Rapson\nThanks for your in depth beta testing.\n\nMatt Thorson\nFor the Ogmo Editor\n\nJon K\nFlixel iOS template.\n\naxcho\nThanks for the retina help.\n\nChevy Ray\nGot me interested in the Ogmo Editor with the source code to the Ludum Dare winning game Flee Buster.\n\nAny resemblance to real persons, living or dead is purely coincidental.\n\nDedicated to Marten and Gerardus.\n\nOriginal/historical contact: initials {a} initialsgames.com\n";

		public var portInfoText:FlxText;
		public var creditsText:FlxText;

		override public function create():void
		{
			FlxG.bgColor = 0xffF8CB8F;

			var gradient2:FlxSprite = FlxGradient.createGradientFlxSprite(FlxG.width, FlxG.height, [0xffcac5ac, 0xffdedbc3, 0xffdfdcc4], 10);
			gradient2.x = 0;
			gradient2.y = 0;
			add(gradient2);

			var portPanel:FlxSprite = new FlxSprite(20, 42);
			portPanel.makeGraphic(FlxG.width - 40, 116, 0x99eeeccd);
			add(portPanel);

			portInfoText = new FlxText(30, 50, FlxG.width - 60, portInfoStr, true);
			portInfoText.setFormat("commodore", 8, 0xff7725a1, "center");
			add(portInfoText);

			creditsText = new FlxText(20, 190, FlxG.width - 40, creditsStr, true);
			creditsText.setFormat("commodore", 8, 0xff7725a1, "center");
			creditsText.velocity.y = -18;
			add(creditsText);

			var borderTop:FlxTileblock = new FlxTileblock(0, 0, FlxG.width, 30);
			borderTop.loadTiles(Registry.ImgLevel1Tiles, 10, 10, 0, true);
			add(borderTop);

			var borderBottom:FlxTileblock = new FlxTileblock(0, FlxG.height - 30, FlxG.width, 30);
			borderBottom.loadTiles(Registry.ImgLevel1Tiles, 10, 10, 0, true);
			add(borderBottom);

			var headingTxt:FlxText = new FlxText(0, 8, FlxG.width, "Credits / Port Info", true);
			headingTxt.color = 0xffffffff;
			headingTxt.size = 8;
			headingTxt.alignment = "center";
			add(headingTxt);

			var footerTxt:FlxText = new FlxText(0, FlxG.height - 22, FlxG.width, "X / BACK TO RETURN", true);
			footerTxt.setFormat("commodore", 8, 0xffffffff, "center");
			add(footerTxt);

			var backBtn:FlxButton = new FlxButton(8, FlxG.height - 27, "back", this.onQuit);
			backBtn.status = FlxButton.HIGHLIGHT;
			backBtn.color = Registry.WAREHOUSE_PURPLE;
			backBtn.label.color = 0xffffff;
			add(backBtn);
		}

		override public function update():void
		{
			if (FlxG.keys.any()) {
				creditsText.velocity.y = -36;
			}
			else {
				creditsText.velocity.y = -18;
			}

			super.update();

			if ((FlxG.keys.justPressed(Registry.homeKey) ||
			FlxG.keys.justPressed(Registry.p1Jump) ||
			FlxG.keys.justPressed(Registry.p1Action) ||
			FlxG.joystick.j1ButtonBackJustPressed ||
			FlxG.joystick.j1ButtonAJustPressed || FlxG.ouyaController.o.pressed) && !fading) {
				FlxG.play(Registry.SndPing, Registry.pingVolume);
				onQuit();
			}

			if (FlxG.ouyaController.a.pressed) onQuit();
		}

		protected function onQuit():void
		{
			FlxG.switchState(new PCMenuState());
		}
	}
}
