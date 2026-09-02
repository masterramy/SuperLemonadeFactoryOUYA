package
{
	import flash.display.StageScaleMode;
	import flash.events.Event;
	import org.flixel.*;
	import io.arkeus.ouya.ControllerInput;
	import io.arkeus.ouya.controller.OuyaController;

	//WINNITRON : 
	//[SWF(width="1024", height="768", backgroundColor="#000000")]
	
	//PC Version:
	//[SWF(width = "1024", height = "780", backgroundColor = "#d3bdb2")]
	
	// Ouya
	[SWF(width = "1920", height = "1080", backgroundColor = "#d3bdb2")]
	

	[Frame(factoryClass = "Preloader")]


	public class SLF extends FlxGame
	{
		private var mobileControls:MobileControls;

		public function SLF()
		{
			// RIGHT ONE
			super(640, 360, PCIntroState, 3, 60, 30);

			// Modern Android screens can be much larger than the historical 1920x1080
			// SWF stage. Scale the complete title uniformly to the largest 16:9 area
			// instead of leaving the original canvas at native pixel size.
			addEventListener(Event.ADDED_TO_STAGE, configureModernStage);

			// Legacy gameplay polls FlxG.ouyaController directly in many states.
			// A modern Android device may have no OUYA/GameInput hardware at all, so
			// install an inert typed controller until PCIntroState discovers real input.
			if (FlxG.ouyaController == null)
				FlxG.ouyaController = new OuyaController(null);

			// Preserve the title's original mobile semantics without rewriting gameplay:
			// native touch zones/gestures translate into the existing keyboard controls.
			mobileControls = new MobileControls(this);
			
			FlxG.debug = forceDebugger = false;
			Registry.isPCVersion = true;
			Registry.isWinnitron = false;
			Registry.DEMO = false;
			FlxG.usingJoystick = false;

			// Run 22 falsified the buffer-locking hypothesis; restore historical setting.
			FlxG.useBufferLocking = false;
		}

		private function configureModernStage(event:Event):void
		{
			removeEventListener(Event.ADDED_TO_STAGE, configureModernStage);
			stage.scaleMode = StageScaleMode.SHOW_ALL;
			stage.align = "";
		}
	}
}