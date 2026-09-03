package
{
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.events.Event;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.system.Capabilities;
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
		private var qaFrame:int = 0;
		private var qaLastSignature:String = "";
		private var qaTelemetryFile:File;

		public function SLF()
		{
			super(640, 360, PCIntroState, 3, 60, 30);

			// Modern Android can resize the AIR stage while the app remains alive
			// (for example when a foldable changes posture). Keep the legacy canvas
			// aspect-fitted to the current stage on every resize.
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
			stage.addEventListener(Event.RESIZE, onModernStageResize, false, 0, true);
			stage.addEventListener(Event.ENTER_FRAME, monitorViewport, false, 0, true);
			qaResetTelemetry();
			qaRecordViewport("ADDED_TO_STAGE");
			fitModernStage();
			qaRecordViewport("AFTER_INITIAL_FIT");
		}

		private function onModernStageResize(event:Event):void
		{
			qaRecordViewport("RESIZE_EVENT_BEFORE_FIT");
			fitModernStage(event);
			qaRecordViewport("RESIZE_EVENT_AFTER_FIT");
		}

		private function monitorViewport(event:Event):void
		{
			qaFrame++;
			if (stage == null) return;
			var signature:String = viewportSignature();
			if (signature != qaLastSignature || qaFrame % 120 == 0)
			{
				qaLastSignature = signature;
				qaRecordViewport("FRAME=" + qaFrame);
			}
		}

		private function viewportSignature():String
		{
			if (stage == null) return "stage=null";
			return "stage=" + stage.stageWidth + "x" + stage.stageHeight +
				" fullscreen=" + stage.fullScreenWidth + "x" + stage.fullScreenHeight +
				" screen=" + Capabilities.screenResolutionX + "x" + Capabilities.screenResolutionY +
				" rootXY=" + x.toFixed(3) + "," + y.toFixed(3) +
				" rootScale=" + scaleX.toFixed(6) + "," + scaleY.toFixed(6) +
				" stageAlign=" + stage.align + " stageScaleMode=" + stage.scaleMode;
		}

		private function qaResetTelemetry():void
		{
			try
			{
				qaTelemetryFile = File.applicationStorageDirectory.resolvePath("resize_telemetry.txt");
				var stream:FileStream = new FileStream();
				stream.open(qaTelemetryFile, FileMode.WRITE);
				stream.writeUTFBytes("");
				stream.close();
			}
			catch (error:Error)
			{
				trace("[GATE2A_RESIZE] TELEMETRY_RESET_ERROR " + error.message);
			}
		}

		private function qaRecordViewport(label:String):void
		{
			var line:String = "[GATE2A_RESIZE] " + label + " " + viewportSignature();
			trace(line);
			try
			{
				if (qaTelemetryFile == null)
					qaTelemetryFile = File.applicationStorageDirectory.resolvePath("resize_telemetry.txt");
				var stream:FileStream = new FileStream();
				stream.open(qaTelemetryFile, FileMode.APPEND);
				stream.writeUTFBytes(line + "\n");
				stream.close();
			}
			catch (error:Error)
			{
				trace("[GATE2A_RESIZE] TELEMETRY_WRITE_ERROR " + error.message);
			}
		}

		private function fitModernStage(event:Event = null):void
		{
			if (stage == null) return;

			// stageWidth/stageHeight track the live Android content surface. The
			// fullscreen dimensions can remain stale across an in-process resize.
			var displayW:Number = stage.stageWidth;
			var displayH:Number = stage.stageHeight;
			if (!isFinite(displayW) || displayW <= 0) displayW = stage.fullScreenWidth;
			if (!isFinite(displayH) || displayH <= 0) displayH = stage.fullScreenHeight;
			if (!isFinite(displayW) || !isFinite(displayH) || displayW <= 0 || displayH <= 0) return;

			var fit:Number = Math.min(displayW / CANVAS_WIDTH, displayH / CANVAS_HEIGHT);
			if (!isFinite(fit) || fit <= 0) fit = 1;
			scaleX = fit;
			scaleY = fit;
			x = (displayW - CANVAS_WIDTH * fit) * 0.5;
			y = (displayH - CANVAS_HEIGHT * fit) * 0.5;
		}
	}
}
