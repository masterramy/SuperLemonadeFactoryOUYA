package
{
	import org.flixel.*;
	import io.arkeus.ouya.ControllerInput;

	//WINNITRON : 
	//[SWF(width="1024", height="768", backgroundColor="#000000")]
	
	//PC Version:
	//[SWF(width = "1024", height = "780", backgroundColor = "#d3bdb2")]
	
	// Ouya
	[SWF(width = "1920", height = "1080", backgroundColor = "#d3bdb2")]
	

	[Frame(factoryClass = "Preloader")]


	public class SLF extends FlxGame
	{
		public function SLF()
		{
			
			
			//WINNITRON
			//super(512, 384, WinniMenuState, 2, 60, 30);
			//Registry.isPCVersion = false;
			//Registry.isWinnitron = true;		
			
			//PC Version:
			//super(520, 390, LicenseKeyState, 2, 60, 30);
			
			// RIGHT ONE
			super(640, 360, PCIntroState, 3, 60, 30);
			
			FlxG.debug = forceDebugger = false;
			Registry.isPCVersion = true;
			Registry.isWinnitron = false;
			Registry.DEMO = false;
			FlxG.usingJoystick = false;

			// Modern AIR/Android needs the camera BitmapData changes committed each
			// frame. Flixel 2.55 already contains the lock/unlock path; enable it.
			FlxG.useBufferLocking = true;
		}
	}
}
