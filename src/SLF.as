package
{
	import org.flixel.*;
	import io.arkeus.ouya.ControllerInput;
	import io.arkeus.ouya.controller.OuyaController;

	[SWF(width = "1920", height = "1080", backgroundColor = "#d3bdb2")]
	[Frame(factoryClass = "Preloader")]

	public class SLF extends FlxGame
	{
		private var mobileControls:MobileControls;

		public function SLF()
		{
			// QA-only branch: boot state-matrix launcher.
			super(640, 360, QAStateBoot, 3, 60, 30);
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
	}
}