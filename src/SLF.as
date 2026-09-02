package
{
	import flash.display.Shape;
	import flash.events.Event;
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
		private var gate2aDisplayProbe:Shape;

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

			// Gate 2A TEMPORARY DIAGNOSTIC ONLY: prove whether the modern AIR root
			// display list can present a raw Flash shape independently of Flixel's
			// BitmapData camera pipeline. Keep it above cameras for the screenshot.
			gate2aDisplayProbe = new Shape();
			gate2aDisplayProbe.graphics.beginFill(0xFF0000, 1.0);
			gate2aDisplayProbe.graphics.drawRect(30, 30, 360, 180);
			gate2aDisplayProbe.graphics.endFill();
			addChild(gate2aDisplayProbe);
			addEventListener(Event.ENTER_FRAME, keepGate2aProbeOnTop);
		}

		private function keepGate2aProbeOnTop(event:Event):void
		{
			if (gate2aDisplayProbe != null && contains(gate2aDisplayProbe))
				setChildIndex(gate2aDisplayProbe, numChildren - 1);
		}
	}
}
