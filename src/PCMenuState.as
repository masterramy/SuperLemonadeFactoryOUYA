// Modified for the independent Super Limeade Factory Android restoration by Ramy Baheeg, 2026.
package
{
	import org.flixel.*;
	import org.flixel.plugin.photonstorm.*;
	import flash.desktop.NativeApplication;

		

	
	
	public class PCMenuState extends FlxState
	{
		[Embed(source = "../data/largeCrate.png")] private var ImgLargeCrate:Class;
		[Embed(source = "../data/level1/palettes.png")] private var ImgPalettes:Class;
		[Embed(source = "../data/smallCrate.png")] private var ImgSmallCrate:Class;
		[Embed(source = "../data/smallSugarBag.png")] private var ImgSmallSugarBag:Class;
		[Embed(source = "../data/sodaPack.png")] private var ImgSodaPack:Class;
		[Embed(source = "../data/sugarBags.png")] private var ImgSugarBags:Class;
		[Embed(source = "../data/tiles.png")] private var ImgTiles:Class;		
		[Embed(source = "../data/bubble.png")] private var ImgLeaves:Class;
		
		[Embed(source = "../data/level1/sugarBagsAndCrates.png")] private var ImgSugarBagsAndCrate:Class;
		[Embed(source = "../data/level1/L1_Shelf.png")] private var ImgShelf:Class;
		
		[Embed(source = "../data/sfx_128/ping.mp3")] protected var SndPing:Class;		
		[Embed(source = "../data/sfx_128/ping2.mp3")] protected var SndPing2:Class;		
		
		[Embed(source = '../data/SLF_levelEditor/level1.oel', mimeType = 'application/octet-stream')] private var Level1:Class;
		
		
		
		//	Test specific variables
		private var scratch:FlxSprite;
		private var glitchAmount:int;
		
		public var ground:FlxTilemap;
		
		public var collideGroup:FlxGroup;
		
		public var buttonsGroup:FlxGroup;
		
		public var playBtn:FlxButton ;
		public var optionsBtn:FlxButton ;
		public var helpBtn:FlxButton ;
		public var creditsBtn:FlxButton ;
		public var oldSchoolBtn:FlxButton ;
		
		public var txtLevel:FlxText;
		public var txtPlayersNo:FlxText;
		
		private var _bubbles:FlxEmitter;
		
		public var ping:FlxSound;
		public var ping2:FlxSound;
		
		private var bgBags:FlxSprite;
		private var bgShelf:FlxSprite;
		
		private var versionText:FlxText ;
		private var latestText:FlxText ;
		
		
		private var buttonEmitter:FlxEmitter;
		
		
		
		private var headingTxt:FlxText;
		
		
		override public function create():void
		{
			
			Registry.oldSchoolMode = false;
			
			ping = new FlxSound();
			ping.loadEmbedded(Registry.SndBlip);
			ping.volume = 0.5;
			
			ping2 = new FlxSound();
			ping2.loadEmbedded(Registry.SndPing);			
			
			FlxG.playMusic(Registry.SndEcho, 1.0);
			
			FlxG.bgColor = 0xff102a16;
			// Use the same native 640x360 pixel-art branding as the opening screen.
			// This menu variant replaces the decorative TAP TO START area with
			// a dedicated panel for genuine FlxButton controls below.
			add(new FlxSprite(0, 0, Registry.ImgTitleMenu));

			if (Registry.mouseEnabled)
				FlxG.mouse.show();
			else
				FlxG.mouse.hide();
			
			buttonsGroup = new FlxGroup();
			
			playBtn = new FlxButton(120, 291, "Play", this.onLevelSelect);
			playBtn.soundOver = ping;
			playBtn.soundDown = ping2;
			playBtn.color = 0x48A936;
			playBtn.label.color = 0xffffff;
			buttonsGroup.add(playBtn);
			
			playBtn.highlightedText = "Play";
			
			playBtn.status = FlxButton.HIGHLIGHT;
			
			optionsBtn = new FlxButton(224, 291, "options", this.onOptions );
			optionsBtn.soundOver = ping;
			optionsBtn.soundDown = ping2;
			optionsBtn.color = 0x48A936;
			optionsBtn.label.color = 0xffffff;
			buttonsGroup.add(optionsBtn);	
			optionsBtn.highlightedText = "Options";

			helpBtn = new FlxButton(328, 291, "help", this.onHelp);
			helpBtn.soundOver = ping;
			helpBtn.soundDown = ping2;			
			helpBtn.color = 0x48A936;
			helpBtn.label.color = 0xffffff;
			buttonsGroup.add(helpBtn);			
			helpBtn.highlightedText = "Help";

			creditsBtn = new FlxButton(432, 291, "credits", this.onCredits);
			creditsBtn.soundOver = ping;
			creditsBtn.soundDown = ping2;
			creditsBtn.color = 0x48A936;
			creditsBtn.label.color = 0xffffff;
			buttonsGroup.add(creditsBtn);
			creditsBtn.highlightedText = "Credits";
			
			
			//oldSchoolBtn = new FlxButton(FlxG.width / 2 - 40, FlxG.height / 2 + 130, "old school", this.onOldSchool);
			//oldSchoolBtn.soundOver = ping;
			//oldSchoolBtn.soundDown = ping2;
			//oldSchoolBtn.color = 0x48A936;
			//oldSchoolBtn.label.color = 0xffffff;
			//buttonsGroup.add(oldSchoolBtn);
			//oldSchoolBtn.highlightedText = "3 Lives";
			
			add(buttonsGroup);
			
			var save:FlxSave = new FlxSave();
			if(save.bind("SLF"))
			{
				// Register defaults for level progress.
				
				var ar1:Array = new Array("wh   ", "1", "1", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0");
				var ar2:Array = new Array("fc   ", "1", "1", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0");
				var ar3:Array = new Array("mgmt ", "1", "1", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0");
				var ar4:Array = new Array("xwh  ", "1", "1", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0");
				var ar5:Array = new Array("xfc  ", "1", "1", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0");
				var ar6:Array = new Array("xmgmt", "1", "1", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0");
				

				if(save.data.warehouseLevelsComplete == null) 
					save.data.warehouseLevelsComplete = ar1 as Array;
				if(save.data.factoryLevelsComplete == null) 
					save.data.factoryLevelsComplete = ar2 as Array;
				if(save.data.mgmtLevelsComplete == null) 
					save.data.mgmtLevelsComplete = ar3 as Array;
				if(save.data.hcwarehouseLevelsComplete == null) 
					save.data.hcwarehouseLevelsComplete = ar4 as Array;
				if(save.data.hcfactoryLevelsComplete == null) 
					save.data.hcfactoryLevelsComplete = ar5 as Array;
				if(save.data.hcmgmtLevelsComplete == null) 
					save.data.hcmgmtLevelsComplete = ar6 as Array;
					
				//register defaults for talking progress
					
				var tar1:Array = new Array("wh-talk   ", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0");
				var tar2:Array = new Array("fc-talk   ", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0");
				var tar3:Array = new Array("mgmt-talk ", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0");
				var tar4:Array = new Array("xwh-talk  ", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0");
				var tar5:Array = new Array("xfc-talk  ", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0");
				var tar6:Array = new Array("xmgmt-talk", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0");
				

				if(save.data.warehouseLevelsTalk == null) 
					save.data.warehouseLevelsTalk = tar1 as Array;
				if(save.data.factoryLevelsTalk == null) 
					save.data.factoryLevelsTalk= tar2 as Array;
				if(save.data.mgmtLevelsTalk == null) 
					save.data.mgmtLevelsTalk = tar3 as Array;
				if(save.data.hcwarehouseLevelsTalk == null) 
					save.data.hcwarehouseLevelsTalk = tar4 as Array;
				if(save.data.hcfactoryLevelsTalk == null) 
					save.data.hcfactoryLevelsTalk = tar5 as Array;
				if(save.data.hcmgmtLevelsTalk == null) 
					save.data.hcmgmtLevelsTalk = tar6 as Array;					

					
				//register defaults for talking t0 Andre progress
					
				var taar1:Array = new Array("wh-talk-andre   ", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0");
				var taar2:Array = new Array("fc-talk-andre   ", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0");
				var taar3:Array = new Array("mgmt-talk-andre ", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0");
				var taar4:Array = new Array("xwh-talk-andre  ", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0");
				var taar5:Array = new Array("xfc-talk-andre  ", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0");
				var taar6:Array = new Array("xmgmt-talk-andre", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0");
				

				if(save.data.warehouseLevelsTalkAndre == null) 
					save.data.warehouseLevelsTalkAndre = taar1 as Array;
				if(save.data.factoryLevelsTalkAndre == null) 
					save.data.factoryLevelsTalkAndre= taar2 as Array;
				if(save.data.mgmtLevelsTalkAndre == null) 
					save.data.mgmtLevelsTalkAndre = taar3 as Array;
				if(save.data.hcwarehouseLevelsTalkAndre == null) 
					save.data.hcwarehouseLevelsTalkAndre = taar4 as Array;
				if(save.data.hcfactoryLevelsTalkAndre == null) 
					save.data.hcfactoryLevelsTalkAndre = taar5 as Array;
				if(save.data.hcmgmtLevelsTalkAndre == null) 
					save.data.hcmgmtLevelsTalkAndre = taar6 as Array;	
					
					
				// register defaults for caps
				
				var car1:Array = new Array("whcap   ", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0");
				var car2:Array = new Array("fccap   ", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0");
				var car3:Array = new Array("mgmtcap ", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0");
				var car4:Array = new Array("xwhcap  ", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0");
				var car5:Array = new Array("xfccap  ", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0");
				var car6:Array = new Array("xmgmtcap", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0");
				

				if(save.data.warehouseCap == null) 
					save.data.warehouseCap = car1 as Array;
				if(save.data.factoryCap == null) 
					save.data.factoryCap = car2 as Array;
				if(save.data.mgmtCap == null) 
					save.data.mgmtCap = car3 as Array;
				if(save.data.hcwarehouseCap == null) 
					save.data.hcwarehouseCap = car4 as Array;
				if(save.data.hcfactoryCap == null) 
					save.data.hcfactoryCap = car5 as Array;
				if(save.data.hcmgmtCap == null) 
					save.data.hcmgmtCap = car6 as Array;
					
                if(save.data.plays == null)
                    save.data.plays = 0 as Number;

                else
                    save.data.plays++;

                //FlxG.log("Number of plays:       " + save.data.plays );
                //save.erase();
                // Canonicalize malformed/short legacy progress arrays before any
                // customer navigation state or completion writer consumes them.
                Registry.normaliseProgressSave(save);

                save.close();
			}
			
			headingTxt = new FlxText(FlxG.width/2 - 40 , FlxG.height-50, FlxG.width/2, "", true);
			headingTxt.color = 0xffffff;
			headingTxt.size = 8;
			headingTxt.alignment = "left";
			add(headingTxt);
			
			headingTxt.text = "";
			
//Get the version number
			var xml : XML = NativeApplication.nativeApplication.applicationDescriptor;
			var ns : Namespace = xml.namespace();
			var version : String = xml.ns::versionNumber;
			Registry.version = version;
			////FlxG.log("Version " + version);
			
			versionText = new FlxText(-60 , FlxG.height-34, FlxG.width, "", true);
			versionText.color = 0xffffff;
			versionText.size = 8;
			versionText.alignment = "right";
			versionText.text = "Version: " + version;
			versionText.visible = false; // artwork already carries unobtrusive v1.9 identity
			add(versionText);	
			
			//latestText = new FlxText(0 , FlxG.height-22, FlxG.width, Registry.newVersionText, true);
/*			latestText = new FlxText(0 , FlxG.height-22, FlxG.width, "", true);
			latestText.color = 0x8000FF;
			latestText.size = 8;
			latestText.alignment = "right";
			add(latestText);	*/		
			
			if (FlxG.ouyaController != null)
			{
				FlxG.ouyaController.o.reset();
			}
			
			// The legacy floating bubble particles obscure the real Play label.
			// Keep the new title/menu controls readable; no particle emitter here.
			
			
			//if ( FlxG.debug) FlxG.showDebugger();
			
			
		}

		override public function update():void
		{
			
			
			
			
			if (!fading && !FlxG.mouse.visible )
				this.handleButtons();

			
			//FlxG.collide(collideGroup,ground);
			
			super.update();
			
			//latestText.text = Registry.newVersionText;
			
		}
		
		
		public function handleButtons():void {
			if (FlxG.keys.justPressed(Registry.p1Down)  || FlxG.joystick.j1Stick1DownJustPressed ) {
				currentButton++;
				FlxG.play(Registry.SndBlip, 0.3);
				
			}
			
			else if (FlxG.keys.justPressed(Registry.p1Up) || FlxG.joystick.j1Stick1UpJustPressed ) {
				currentButton--;
				FlxG.play(Registry.SndBlip, 0.3);
			}
			
			if (FlxG.keys.justPressed(Registry.p1Action) || (FlxG.ouyaController != null && FlxG.ouyaController.o.pressed) || FlxG.keys.justPressed(Registry.p1Switch) || FlxG.keys.justPressed(Registry.p1Jump) || FlxG.joystick.j1ButtonAJustPressed  ) {
				FlxG.play(Registry.SndPing, Registry.pingVolume);
				this.beginFade();
			}
			if (currentButton < 0) {
				currentButton = buttonsGroup.length-1;
			}
			else if (currentButton > buttonsGroup.length-1) {
				currentButton = 0;
			}
			
			
			for (var i:int = 0; i < buttonsGroup.length; i++) 
			{ 
				if (i == currentButton) 
				{
					(buttonsGroup.members[i] as FlxButton).status = FlxButton.HIGHLIGHT;
					// No particle effect over the branded menu.
					
				}
				else 
				{
					(buttonsGroup.members[i] as FlxButton).status = FlxButton.NORMAL;
				}
			}
		}
		
		protected function beginFade():void
		{
			fading = true;
			FlxG.fade(0xff000000, 0.4, completeFade);
		}
		
		protected function completeFade():void
		{
			switch(currentButton) {
				case 0:
					Registry.oldSchoolMode = false;
					FlxG.switchState(new PCLevelSelectState());
					break;
				case 1:
					FlxG.switchState(new PCOptionsState());
					break;		
				case 2:
					FlxG.switchState(new PCHelpState());
					break;
				case 3:
					FlxG.switchState(new PCCreditsState());
					break;
				case 5:
					if (Registry.DEMO == true)
					{
						headingTxt.text = "";
					}
					else 
					{
						FlxG.playMusic(Registry.SndMega, 1.0);
						Registry.oldSchoolLivesF = 3;
						Registry.oldSchoolLivesM = 3;
						//Registry.restartMusic = true;
						Registry.oldSchoolMode = true;
						Registry.level = XML(new Registry.Level1);
						Registry.levelType = 1;
						Registry.levelNumber = 1;
						Registry.hardCore = false;
						FlxG.switchState(new PCPlayState());
					}
					break;						
			}
		}		
		
		// Direct tap hit-testing for the four REAL menu buttons. This feeds the
		// existing callbacks and does not modify gameplay touch/control routes.
		public function activateMenuButtonAt(gameX:Number, gameY:Number):Boolean
		{
			if (fading) return true;
			var items:Array = [playBtn, optionsBtn, helpBtn, creditsBtn];
			for (var i:int = 0; i < items.length; i++)
			{
				var b:FlxButton = items[i] as FlxButton;
				if (b != null && gameX >= b.x && gameX <= b.x + b.width &&
					gameY >= b.y && gameY <= b.y + b.height)
				{
					fading = true;
					currentButton = i;
					FlxG.play(Registry.SndPing, Registry.pingVolume);
					switch (i)
					{
						case 0: onLevelSelect(); break;
						case 1: onOptions(); break;
						case 2: onHelp(); break;
						case 3: onCredits(); break;
					}
					return true;
				}
			}
			return false;
		}

		public function onLevelSelect():void 
		{
			//FlxG.switchState(new PCLevelSelectState());
			FlxG.fade(0xff000000, 0.4, completeFade);
			currentButton = 0;
		}
		
		public function onOptions():void 
		{
			FlxG.fade(0xff000000, 0.4, completeFade);
			currentButton = 1;
		}
		
		public function onHelp():void 
		{
			//FlxG.switchState(new PCHelpState());
			FlxG.fade(0xff000000, 0.4, completeFade);
			currentButton = 2;
		}
		
		public function onCredits():void 
		{
			//FlxG.switchState(new PCCreditsState());
			FlxG.fade(0xff000000, 0.4, completeFade);
			currentButton = 3;
		}		
		

		
		public function onOldSchool():void 
		{
			//FlxG.switchState(new PCCustomLevelState());
			FlxG.fade(0xff000000, 0.4, completeFade);
			currentButton = 5;
		}	
		
		override public function destroy():void
		{
			super.destroy();
		}
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		


		
	}
}
