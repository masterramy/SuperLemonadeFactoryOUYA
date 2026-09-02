package
{
	import org.flixel.*;

	public class PrizeState extends FlxState
	{
		private var backBtn:FlxButton;
		private var titleTxt:FlxText;
		private var timeOnScreen:Number;

		override public function create():void
		{
			timeOnScreen = 0;
			FlxG.bgColor = 0xffa5a5ff;

			var bg:FlxSprite = new FlxSprite(20, 20);
			bg.makeGraphic(FlxG.width - 40, FlxG.height - 40, 0xff4343e7, false);
			add(bg);

			titleTxt = new FlxText(24, 70, FlxG.width - 48,
				"OLD SCHOOL COMPLETE!\n\nYou completed every normal and hardcore level in one run.\n\nYou are a real human being and a real hero.");
			titleTxt.setFormat("commodore", 8, 0xDBDBDB, "center");
			add(titleTxt);

			backBtn = new FlxButton(FlxG.width / 2 - 40, FlxG.height - 70, "BACK TO GAME", backToGame);
			backBtn.color = 0xCCEEF9;
			backBtn.label.color = 0xffffff;
			backBtn.status = FlxButton.HIGHLIGHT;
			add(backBtn);

			if (Registry.mouseEnabled)
				FlxG.mouse.show();
			else
				FlxG.mouse.hide();
		}

		override public function update():void
		{
			timeOnScreen += FlxG.elapsed;
			if (timeOnScreen > 0.5 &&
				(FlxG.keys.justPressed(Registry.p1Action) ||
				 FlxG.keys.justPressed(Registry.p1Jump) ||
				 FlxG.keys.justPressed(Registry.p1Switch) ||
				 FlxG.joystick.j1ButtonAJustPressed ||
				 FlxG.ouyaController.o.pressed))
			{
				backToGame();
				return;
			}
			super.update();
		}

		private function backToGame():void
		{
			FlxG.playMusic(Registry.SndEcho, 1.0);
			FlxG.switchState(new PCMenuState());
		}
	}
}
