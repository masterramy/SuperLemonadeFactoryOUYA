// Modified for the independent Super Limeade Factory Android restoration by Ramy Baheeg, 2026.
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
    import flash.desktop.NativeApplication;



	public class PCOptionsState extends FlxState
	{
		
		
		public var eraseBtn:FlxButton;
        public var graphicsBtn:FlxButton;
        public var graphicsText:FlxText;
        private var qaPadText:FlxText;
        // Compile the safe, opt-in cloud transport boundary but do not run it.
        private var cloudSyncContract:CloudSyncCoordinator;
        private var cloudProvider:PGSNativeTransport;
        private var cloudButton:FlxButton;
        private var cloudStatusText:FlxText;

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
			
            GraphicsMode.load();
            graphicsBtn = new FlxButton(Registry.xPos1, Registry.ySmallPos6, "graphics", this.changeGraphics);
            graphicsBtn.soundOver = ping;
            graphicsBtn.color = Registry.WAREHOUSE_PURPLE;
            graphicsBtn.label.color = 0xffffff;
            buttonsGroup.add(graphicsBtn);
            graphicsText = new FlxText(Registry.xPos1 + graphicsBtn.width, Registry.ySmallPos6,
                FlxG.width/2, GraphicsMode.remastered ? "Remastered (preview)" : "Classic");
            graphicsText.size = 8;
            graphicsText.alignment = "left";
            graphicsText.color = 0x8000FF;
            add(graphicsText);

            // Never offer cloud controls when there is no correctly installed
            // native PGS provider. This does not authorize any network traffic:
            // only the player's deliberate button action below can do that.
            cloudProvider = new PGSNativeTransport();
            if (cloudProvider.supported)
            {
                cloudSyncContract = new CloudSyncCoordinator(cloudProvider);
                cloudButton = new FlxButton(Registry.xPos1, Registry.ySmallPos8,
                    "cloud save", this.beginCloudSync);
                cloudButton.soundOver = ping;
                cloudButton.color = Registry.WAREHOUSE_PURPLE;
                cloudButton.label.color = 0xffffff;
                cloudStatusText = new FlxText(Registry.xPos1 + cloudButton.width,
                    Registry.ySmallPos8, FlxG.width/2, "Cloud: tap to sync");
                cloudStatusText.size = 8;
                cloudStatusText.alignment = "left";
                cloudStatusText.color = 0x8000FF;
            }

			backBtn = new FlxButton(Registry.xPos1, Registry.ySmallPos7 , "back", this.onQuit);
			backBtn.soundOver = ping;
			backBtn.color = Registry.WAREHOUSE_PURPLE;
			backBtn.label.color = 0xffffff;
			buttonsGroup.add(backBtn);
            if (cloudButton != null)
            {
                buttonsGroup.add(cloudButton);
                add(cloudStatusText);
            }
			
            add(buttonsGroup);

            // Only the separately installed QA package exposes controller
            // diagnostics; the real paid app cannot display a debug panel.
            if (NativeApplication.nativeApplication.applicationID == "com.ramybaheeg.slfport.dev")
            {
                qaPadText = new FlxText(12, Registry.ySmallPos9, FlxG.width-24,
                    "Gamepad QA: pair controller, press A and arrows");
                qaPadText.size = 8;
                qaPadText.color = 0xff333333;
                add(qaPadText);
            }
        }

        // Direct Android touch hit-testing must address the intended button.
        // Previously MobileControls pulsed generic Action for every tap here,
        // allowing Graphics taps to advance the DELETE confirmation instead.
        // Unmatched taps are ignored rather than selecting a destructive item.
        public function activateOptionsButtonAt(gameX:Number, gameY:Number):Boolean
        {
            if (fading) return true;
            var items:Array = [eraseBtn, graphicsBtn, backBtn];
            if (cloudButton != null) items.push(cloudButton);
            for (var i:int = 0; i < items.length; i++)
            {
                var button:FlxButton = items[i] as FlxButton;
                if (button != null && gameX >= button.x && gameX <= button.x + button.width &&
                    gameY >= button.y && gameY <= button.y + button.height)
                {
                    currentButton = buttonsGroup.members.indexOf(button);
                    if (button == eraseBtn) deleteHistory();
                    else if (button == graphicsBtn) changeGraphics();
                    else if (button == cloudButton) beginCloudSync();
                    else onQuit();
                    return true;
                }
            }
            return false;
        }

        private function beginCloudSync():void
        {
            // This method is only reachable through a visible, deliberate tap
            // or a controller/keyboard selection. No sync at app startup.
            if (cloudButton == null || cloudProvider == null ||
                !cloudProvider.supported || cloudSyncContract == null ||
                cloudSyncContract.isBusy) return;
            cloudStatusText.text = "Cloud: connecting...";
            if (!cloudSyncContract.sync(true, function(status:String):void {
                if (cloudStatusText == null) return;
                if (status == "synced") cloudStatusText.text = "Cloud: synced";
                else if (status == "authentication_failed")
                    cloudStatusText.text = "Cloud: sign-in failed";
                else if (status == "malformed_remote")
                    cloudStatusText.text = "Cloud: save rejected";
                else cloudStatusText.text = "Cloud: offline/error";
            })) cloudStatusText.text = "Cloud: unavailable";
        }

        private function changeGraphics():void
        {
            if (GraphicsMode.toggle())
                graphicsText.text = GraphicsMode.remastered ? "Remastered (preview)" : "Classic";
        }

		override public function update():void
		{
			if (!fading && !FlxG.mouse.visible)
				this.handleButtons();
				
			
			if ( (FlxG.keys.justPressed(Registry.homeKey) || FlxG.joystick.j1ButtonBackJustPressed ) && !fading) {
				onQuit();			
				
			}
			
			
            super.update();
            if (qaPadText != null && FlxG.joystick != null)
                qaPadText.text = FlxG.joystick.qaStatus();

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
		
		
		
		
        private function activateSelectedOption():void
        {
            if (currentButton < 0 || currentButton >= buttonsGroup.length) return;
            var selected:FlxButton = buttonsGroup.members[currentButton] as FlxButton;
            if (selected == eraseBtn) deleteHistory();
            else if (selected == graphicsBtn) changeGraphics();
            else if (selected == cloudButton && cloudButton != null) beginCloudSync();
            else if (selected == backBtn) onQuit();
        }

        protected function beginFade():void
        {
            // Legacy keyboard/controller activation follows the SAME target
            // as a direct touch, irrespective of optional provider availability.
            activateSelectedOption();
        }

        protected function completeFade():void
        {
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