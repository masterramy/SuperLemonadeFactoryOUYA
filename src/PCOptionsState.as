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
 * PCOptionsState.as
 * Created On: 14/04/2012 11:18 AM
 */
 
package 
{
	import org.flixel.*;
	import org.flixel.plugin.photonstorm.*;
	import flash.filesystem.*;



	public class PCOptionsState extends FlxState
	{
		
		
		public var eraseBtn:FlxButton;

		public var eraseText:FlxText;		
		
		public var backBtn:FlxButton;
		
		public var buttonsGroup:FlxGroup;
		
		public var ping:FlxSound;
		
override public function create():void
		{
			
			FlxG.bgColor = 0xffF8CB8F;
			
			//	Make the gradient retro looking and "chunky" with the chucnkSize parameter (here set to 4)
			var gradient2:FlxSprite = FlxGradient.createGradientFlxSprite(FlxG.width, FlxG.height, [0xffcac5ac, 0xffdedbc3 , 0xffdfdcc4], 10 ); //0xffd6d3ba
			gradient2.x = 0;
			gradient2.y = 0;
			add(gradient2);
			
			var borderTop:FlxTileblock = new FlxTileblock(0, 0, FlxG.width, 30);
			borderTop.loadTiles(Registry.ImgLevel1Tiles, 10, 10, 0,true);
			add(borderTop);
			
			var borderBottom:FlxTileblock = new FlxTileblock(0, FlxG.height-30, FlxG.width, 30);
			borderBottom.loadTiles(Registry.ImgLevel1Tiles, 10, 10, 0,true);
			add(borderBottom);		
			
			var headingTxt:FlxText = new FlxText(0, 8, FlxG.width, "Options", true);
			headingTxt.color = 0xffffffff;
			headingTxt.size = 8;
			headingTxt.alignment = "center";
			add(headingTxt);
			
			
			
			
			ping = new FlxSound();
			ping.loadEmbedded(Registry.SndBlip);
			ping.volume = 0.5;
			
			buttonsGroup = new FlxGroup();
			
			eraseBtn = new FlxButton(Registry.xPos1, Registry.ySmallPos5, "delete", this.deleteHistory);
			eraseBtn.soundOver = ping;
			eraseBtn.color = Registry.WAREHOUSE_PURPLE;
			eraseBtn.label.color = 0xffffff;
			buttonsGroup.add(eraseBtn);	
			
			eraseBtn.status = FlxButton.HIGHLIGHT;
			
			eraseText = new FlxText(Registry.xPos1+eraseBtn.width,Registry.ySmallPos5,FlxG.width/2,"Erase progress.");
			eraseText.size = 8;
			eraseText.alignment = "left";
			eraseText.color = 0x8000FF;
			add(eraseText);
			
			backBtn = new FlxButton(Registry.xPos1, Registry.ySmallPos7 , "back", this.onQuit);
			backBtn.soundOver = ping;
			backBtn.color = Registry.WAREHOUSE_PURPLE;
			backBtn.label.color = 0xffffff;
			buttonsGroup.add(backBtn);
			
			add(buttonsGroup);
			
			
		}

		override public function update():void
		{
			if (!fading && !FlxG.mouse.visible)
				this.handleButtons();
				
			
			if ( (FlxG.keys.justPressed(Registry.homeKey) || FlxG.joystick.j1ButtonBackJustPressed ) && !fading) {
				onQuit();			
				
			}
			
			
			super.update();
			
			if (FlxG.ouyaController.a.pressed) onQuit();
			
			FlxG.ouyaController.o.reset();
			

		}
		
		protected function onQuit():void
		{
			FlxG.switchState(new PCMenuState());
			return;
		}
		
		public function handleButtons():void {
			
			
			
			if (FlxG.keys.justPressed(Registry.p1Down)  || FlxG.joystick.j1Stick1DownJustPressed ) {
				currentButton++;
				FlxG.play(Registry.SndBlip, 0.3);
				
				//FlxG.log("pressedDown");
				
			}
			else if (FlxG.keys.justPressed(Registry.p1Up) || FlxG.joystick.j1Stick1UpJustPressed ) {
				currentButton--;
				FlxG.play(Registry.SndBlip, 0.3);
			}
			
			if (FlxG.keys.justPressed(Registry.p1Action) ||  FlxG.keys.justPressed(Registry.p1Switch) || FlxG.keys.justPressed(Registry.p1Jump) || FlxG.joystick.j1ButtonAJustPressed || FlxG.ouyaController.o.pressed ) {
				FlxG.play(Registry.SndPing,Registry.pingVolume);
				this.beginFade();
			}
			
			if (currentButton < 0) {
				currentButton = buttonsGroup.length-1;
			}
			else if (currentButton > buttonsGroup.length-1) {
				currentButton = 0;
			}
			
			
			for (var i:int = 0; i < buttonsGroup.length; i++) { 
				if (i == currentButton) {
					(buttonsGroup.members[i] as FlxButton).status = FlxButton.HIGHLIGHT;
					
					
				}
				else {
					(buttonsGroup.members[i] as FlxButton).status = FlxButton.NORMAL;
				}
			}
			
			
		}
		
		
		
		
		
		
		



		
		protected function deleteHistory():void
		{			
			
			if (eraseBtn.label.text == "delete") {
				eraseBtn.label.text = "are you sure";
			}
			else if (eraseBtn.label.text == "are you sure") {
				eraseBtn.label.text = "really?";
			}
			else if (eraseBtn.label.text == "really?") {
				FlxG.shake(0.01, 0.1);
				var save:FlxSave = new FlxSave();
				var primaryErased:Boolean = false;
				if(save.bind("SLF"))
				{
					try {
						primaryErased = save.erase();
					}
					catch (saveError:Error) {
						primaryErased = false;
					}
					save.destroy();
				}

				var backupErased:Boolean = true;
				var backupFile:File = File.applicationStorageDirectory;
				backupFile = backupFile.resolvePath("SUPERLEMONADEFACTORY/progress_backup.slf");
				try {
					if (backupFile.exists)
						backupFile.deleteFile();
				}
				catch (backupError:Error) {
					backupErased = false;
				}

				// Report complete deletion only when both local progress stores were
				// actually cleared. A SharedObject bind failure must not look successful.
				eraseBtn.label.text = (primaryErased && backupErased) ? "erased" : "not erased";
			}
		}


/*		protected function importProgress():void
		{			
			
			this.onLoadFileClick();
			
			var saves:Array = saveData.toString().split(".");
			
		
			var save:FlxSave = new FlxSave();
			if(save.bind("SLF"))
			{
				save.data.warehouseLevelsComplete = saves[0];
				save.data.hcwarehouseLevelsComplete = saves[1];					
				save.data.factoryLevelsComplete = saves[2];					
				save.data.hcfactoryLevelsComplete = saves[3];					
				save.data.mgmtLevelsComplete = saves[4];					
				save.data.hcmgmtLevelsComplete = saves[5];	
				
				save.data.warehouseLevelsTalk = saves[6];
				save.data.hcwarehouseLevelsTalk = saves[7];					
				save.data.factoryLevelsTalk = saves[8];					
				save.data.hcfactoryLevelsTalk = saves[9];					
				save.data.mgmtLevelsTalk = saves[10];					
				save.data.hcmgmtLevelsTalk = saves[11];
				
				save.data.warehouseLevelsTalkAndre = saves[12];
				save.data.hcwarehouseLevelsTalkAndre = saves[13];					
				save.data.factoryLevelsTalkAndre = saves[14];					
				save.data.hcfactoryLevelsTalkAndre = saves[15];					
				save.data.mgmtLevelsTalkAndre = saves[16];					
				save.data.hcmgmtLevelsTalkAndre = saves[17];				
				
				save.data.warehouseCap = saves[18];
				save.data.hcwarehouseCap = saves[19];					
				save.data.factoryCap = saves[20];					
				save.data.hcfactoryCap = saves[21];					
				save.data.mgmtCap = saves[22];					
				save.data.hcmgmtCap = saves[23];				
				
				save.close();
			}
		
			
		}*/
		
		
		
		
		protected function beginFade():void
		{
			if (currentButton == 0) {
				this.deleteHistory();
				return;
			}
			if (currentButton == 1) {
				fading = true;
				FlxG.fade(0xff000000, 0.4, completeFade);
			}
		}
		
		protected function completeFade():void
		{
			if (currentButton == 1)
				FlxG.switchState(new PCMenuState());
		}		
		

		
		
		//IMPORT FILE HELPERS
		
		//called when the user clicks the load file button

		/************ Browse Event Handlers **************/

		//called when the user selects a file from the browse dialog

		//called when the user cancels out of the browser dialog

		/************ Select Event Handlers **************/

		//called when the file has completed loading

		//called if an error occurs while loading the file contents
		
		/*
		 * Saves the progress file without asking the location. 
		 */ 
		
		
		
		
	}
}