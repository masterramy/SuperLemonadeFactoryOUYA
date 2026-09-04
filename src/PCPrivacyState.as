/*
 * Super Lemonade Factory Port - privacy/about surface
 * Android port publication work by Ramy Baheeg, 2026.
 * Original game by Shane Brouwer / Initials.
 * This file is distributed with the project under GPLv3.
 */

package
{
	import org.flixel.*;
	import org.flixel.plugin.photonstorm.*;

	public class PCPrivacyState extends FlxState
	{
		public var policyStr:String =
			"SUPER LEMONADE FACTORY PORT\n\n" +
			"Independent Android port published by Ramy Baheeg.\n" +
			"Original game by Shane Brouwer / Initials. Built from the GPLv3-released OUYA source.\n" +
			"This is not an official Initials publication or endorsement.\n\n" +
			"PRIVACY POLICY\n" +
			"Developer: Ramy Baheeg\n" +
			"Privacy contact: ramy.baheeg@gmail.com\n\n" +
			"This game does not collect, transmit, sell, or share personal or sensitive user data. " +
			"It requires no account and uses no advertising or analytics services.\n\n" +
			"Game progress is stored only on this device in app-private local storage. " +
			"Ramy Baheeg does not receive or have access to that progress. Clearing app data or uninstalling may remove it.\n\n" +
			"The game does not require an internet connection for normal play. No server-side user data is retained, so there is no remote user-data deletion process.\n\n" +
			"Privacy inquiries: ramy.baheeg@gmail.com\n" +
			"Source: github.com/masterramy/SuperLemonadeFactoryOUYA";

		override public function create():void
		{
			FlxG.bgColor = 0xffF8CB8F;

			var gradient2:FlxSprite = FlxGradient.createGradientFlxSprite(FlxG.width, FlxG.height, [0xffcac5ac, 0xffdedbc3, 0xffdfdcc4], 10);
			gradient2.x = 0;
			gradient2.y = 0;
			add(gradient2);

			var borderTop:FlxTileblock = new FlxTileblock(0, 0, FlxG.width, 30);
			borderTop.loadTiles(Registry.ImgLevel1Tiles, 10, 10, 0, true);
			add(borderTop);

			var borderBottom:FlxTileblock = new FlxTileblock(0, FlxG.height - 30, FlxG.width, 30);
			borderBottom.loadTiles(Registry.ImgLevel1Tiles, 10, 10, 0, true);
			add(borderBottom);

			var headingTxt:FlxText = new FlxText(0, 8, FlxG.width, "Privacy / About", true);
			headingTxt.color = 0xffffffff;
			headingTxt.size = 8;
			headingTxt.alignment = "center";
			add(headingTxt);

			var policyTxt:FlxText = new FlxText(40, 40, FlxG.width - 80, policyStr);
			policyTxt.size = 8;
			policyTxt.setFormat("commodore", 8);
			policyTxt.alignment = "left";
			policyTxt.color = 0x8000FF;
			add(policyTxt);

			var backBtn:FlxButton = new FlxButton(40, Registry.ySmallPos7, "back", this.onQuit);
			backBtn.y = FlxG.height - backBtn.height - 60;
			backBtn.status = FlxButton.HIGHLIGHT;
			backBtn.color = Registry.WAREHOUSE_PURPLE;
			backBtn.label.color = 0xffffff;
			add(backBtn);
		}

		override public function update():void
		{
			if ((FlxG.keys.justPressed(Registry.homeKey) || FlxG.keys.justPressed(Registry.p1Jump) || FlxG.keys.justPressed(Registry.p1Action) || FlxG.joystick.j1ButtonBackJustPressed || FlxG.joystick.j1ButtonAJustPressed || FlxG.ouyaController.o.pressed) && !fading) {
				FlxG.play(Registry.SndPing, Registry.pingVolume);
				onQuit();
			}

			if (FlxG.ouyaController.a.pressed) onQuit();
			super.update();
		}

		protected function onQuit():void
		{
			FlxG.switchState(new PCHelpState());
		}
	}
}
