package
{
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.events.Event;
	import flash.system.Capabilities;
	import flash.text.TextField;
	import flash.text.TextFormat;
	import org.flixel.*;
	import io.arkeus.ouya.ControllerInput;
	import io.arkeus.ouya.controller.OuyaController;

	[SWF(width = "1920", height = "1080", backgroundColor = "#d3bdb2")]
	[Frame(factoryClass = "Preloader")]

	public class SLF extends FlxGame
	{
		private static const CANVAS_WIDTH:Number = 1920;
		private static const CANVAS_HEIGHT:Number = 1080;
		private var mobileControls:MobileControls;
		private var geometryText:TextField;

		public function SLF()
		{
			super(640, 360, PCIntroState, 3, 60, 30);
			addEventListener(Event.ADDED_TO_STAGE, configureModernStage);
			if (FlxG.ouyaController == null) FlxG.ouyaController = new OuyaController(null);
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

			geometryText = new TextField();
			geometryText.mouseEnabled = false;
			geometryText.selectable = false;
			geometryText.background = true;
			geometryText.backgroundColor = 0x000000;
			geometryText.textColor = 0xffffff;
			geometryText.width = 2400;
			geometryText.height = 180;
			geometryText.defaultTextFormat = new TextFormat("_sans", 28, 0xffffff, true);
			geometryText.x = 10;
			geometryText.y = 10;
			stage.addChild(geometryText);
			stage.addEventListener(Event.ENTER_FRAME, updateGeometryText, false, 0, true);
			updateGeometryText();
		}

		private function updateGeometryText(event:Event = null):void
		{
			if (stage == null || geometryText == null) return;
			geometryText.text =
				"stage=" + stage.stageWidth + "x" + stage.stageHeight +
				" full=" + stage.fullScreenWidth + "x" + stage.fullScreenHeight +
				" cap=" + Capabilities.screenResolutionX + "x" + Capabilities.screenResolutionY +
				" dpi=" + Capabilities.screenDPI + "\n" +
				"root x=" + x.toFixed(2) + " y=" + y.toFixed(2) +
				" scale=" + scaleX.toFixed(5) + "x" + scaleY.toFixed(5) +
				" local1920->global=" + localToGlobal(new flash.geom.Point(1920,1080)).toString();
			stage.setChildIndex(geometryText, stage.numChildren - 1);
		}

		private function fitModernStage(event:Event = null):void
		{
			if (stage == null) return;
			var displayW:Number = stage.fullScreenWidth;
			var displayH:Number = stage.fullScreenHeight;
			if (!isFinite(displayW) || displayW <= 0) displayW = stage.stageWidth;
			if (!isFinite(displayH) || displayH <= 0) displayH = stage.stageHeight;
			if (!isFinite(displayW) || !isFinite(displayH) || displayW <= 0 || displayH <= 0) return;
			if (stage.stageWidth > stage.stageHeight && displayW < displayH)
			{
				var swap:Number = displayW; displayW = displayH; displayH = swap;
			}
			var fit:Number = Math.min(displayW / CANVAS_WIDTH, displayH / CANVAS_HEIGHT);
			if (!isFinite(fit) || fit <= 0) fit = 1;
			scaleX = fit; scaleY = fit;
			x = (displayW - CANVAS_WIDTH * fit) * 0.5;
			y = (displayH - CANVAS_HEIGHT * fit) * 0.5;
		}
	}
}
