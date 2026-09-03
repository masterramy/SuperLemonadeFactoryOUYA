package
{
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.events.Event;
	import org.flixel.*;
	import io.arkeus.ouya.ControllerInput;
	import io.arkeus.ouya.controller.OuyaController;

	//WINNITRON : 
	//[SWF(width="1024", height="768", backgroundColor="#000000")]
	
	//PC Version:
	//[SWF(width = "1024", height = "780", backgroundColor = "#d3bdb2")]
	
	// Ouya / canonical rendered canvas
	[SWF(width = "1920", height = "1080", backgroundColor = "#d3bdb2")]

	[Frame(factoryClass = "Preloader")]

	public class SLF extends FlxGame
	{
		private static const CANVAS_WIDTH:Number = 1920;
		private static const CANVAS_HEIGHT:Number = 1080;
		private var mobileControls:MobileControls;

		public function SLF()
		{
			super(640, 360, PCIntroState, 3, 60, 30);

			// Modern AIR/Android can report a Stage width that is larger than the
			// visible framebuffer after rotation/density transforms. Keep the stage
			// unscaled and fit the historical canvas against the actual fullscreen
			// display dimensions instead.
			addEventListener(Event.ADDED_TO_STAGE, configureModernStage);

			// Legacy gameplay polls FlxG.ouyaController directly in many states.
			// A modern Android device may have no OUYA/GameInput hardware at all, so
			// install an inert typed controller until PCIntroState discovers real input.
			if (FlxG.ouyaController == null)
				FlxG.ouyaController = new OuyaController(null);

			mobileControls = new MobileControls(this);
			
			FlxG.debug = forceDebugger = false;
			Registry.isPCVersion = true;
			Registry.isWinnitron = false;
			Registry.DEMO = false;
			FlxG.usingJoystick = false;
			FlxG.useBufferLocking = false;
		}

		private function configureModernStage(event:Event):void
		{
			removeEventListener(Event.ADDED_TO_STAGE, configureModernStage);
			stage.scaleMode = StageScaleMode.NO_SCALE;
			stage.align = StageAlign.TOP_LEFT;
			stage.addEventListener(Event.RESIZE, fitModernStage, false, 0, true);
			fitModernStage();
		}

		private function fitModernStage(event:Event = null):void
		{
			if (stage == null) return;

			var displayW:Number = stage.fullScreenWidth;
			var displayH:Number = stage.fullScreenHeight;
			if (!isFinite(displayW) || displayW <= 0) displayW = stage.stageWidth;
			if (!isFinite(displayH) || displayH <= 0) displayH = stage.stageHeight;
			if (!isFinite(displayW) || !isFinite(displayH) || displayW <= 0 || displayH <= 0) return;

			// Some Android builds expose fullscreen dimensions in the device's
			// natural portrait order even after AIR has entered landscape.
			if (stage.stageWidth > stage.stageHeight && displayW < displayH)
			{
				var swap:Number = displayW;
				displayW = displayH;
				displayH = swap;
			}

			var fit:Number = Math.min(displayW / CANVAS_WIDTH, displayH / CANVAS_HEIGHT);
			if (!isFinite(fit) || fit <= 0) fit = 1;
			scaleX = fit;
			scaleY = fit;
			x = (displayW - CANVAS_WIDTH * fit) * 0.5;
			y = (displayH - CANVAS_HEIGHT * fit) * 0.5;
		}
	}
}
