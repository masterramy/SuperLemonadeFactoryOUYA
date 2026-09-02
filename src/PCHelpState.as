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
 
 /*
 * PCHelpState.as
 * Created On: 14/04/2012 11:18 AM
 */
 
package 
{
	import org.flixel.*;
	import org.flixel.plugin.photonstorm.*;

	public class PCHelpState extends FlxState
	{
		public var helpStr:String =	"How to play (touch):\n\nMenus\nSwipe up, down, left, or right to move the selection. Tap to choose.\n\nGameplay\nUse LEFT and RIGHT to move.\nACTION makes Andre dash and lets Liselot talk or push crates.\nJUMP jumps; Liselot can jump again in the air.\nSWITCH changes between Andre and Liselot.\nPIGGY carries or releases a character when they are touching.\nPAUSE pauses or resumes; while paused, use the controls to restart or return to the menu.\nYou can also swipe up/down in the upper play area for vertical movement and swipe sideways there for piggyback.\n\nGet both Andre and Liselot to the exit to finish the level.\n\nScoring:\nCollect the bottle to receive a bottle cap badge. Talk to Andre and to a co-worker to receive the speech badges for the level.\n\nHave fun and get to know everyone. ";		
		
		public var helpTxt:FlxText;
		
		override public function create():void
		{
			FlxG.bgColor = 0xffF8CB8F;
			
			var gradient2:FlxSprite = FlxGradient.createGradientFlxSprite(FlxG.width, FlxG.height, [0xffcac5ac, 0xffdedbc3 , 0xffdfdcc4], 10 );
			gradient2.x = 0;
			gradient2.y = 0;
			add(gradient2);
			
			var borderTop:FlxTileblock = new FlxTileblock(0, 0, FlxG.width, 30);
			borderTop.loadTiles(Registry.ImgLevel1Tiles, 10, 10, 0,true);
			add(borderTop);
			
			var borderBottom:FlxTileblock = new FlxTileblock(0, FlxG.height-30, FlxG.width, 30);
			borderBottom.loadTiles(Registry.ImgLevel1Tiles, 10, 10, 0,true);
			add(borderBottom);	
			
			if (Registry.mouseEnabled) {
				FlxG.mouse.show();
			}
			else if (!Registry.mouseEnabled) {
				FlxG.mouse.hide();
			}
			
			helpTxt = new FlxText(40, 40, FlxG.width-80, helpStr);
			helpTxt.size = 8;
			helpTxt.setFormat("commodore", 8);
			helpTxt.alignment = "left";
			helpTxt.color = 0x8000FF;
			add(helpTxt);
			
			var backBtn:FlxButton = new FlxButton(40, Registry.ySmallPos7 , "back", this.onQuit);
			backBtn.y = FlxG.height - backBtn.height - 60;
			backBtn.status = FlxButton.HIGHLIGHT;
			backBtn.color = Registry.WAREHOUSE_PURPLE;
			backBtn.label.color = 0xffffff;
			add(backBtn);
		}

		override public function update():void
		{
			if ((FlxG.keys.justPressed(Registry.homeKey)||FlxG.keys.justPressed(Registry.p1Jump)||FlxG.keys.justPressed(Registry.p1Action) || FlxG.joystick.j1ButtonBackJustPressed || FlxG.joystick.j1ButtonAJustPressed || FlxG.ouyaController.o.pressed) && !fading) {
				FlxG.play(Registry.SndPing,Registry.pingVolume);
				onQuit();			
			}
			
			if (FlxG.ouyaController.a.pressed) onQuit();
			super.update();
		}
		
		protected function onQuit():void
		{
			FlxG.switchState(new PCMenuState());
		}
	}
}
