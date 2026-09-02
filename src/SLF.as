package
{
	import flash.display.Bitmap;
	import flash.display.BitmapData;
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
		private var gate2aVectorProbe:Shape;
		private var gate2aBitmapProbe:Bitmap;
		private var gate2aCameraBacking:Shape;
		private var gate2aCameraMirror:Bitmap;

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

			// Gate 2A TEMPORARY DIAGNOSTIC ONLY. Three probes divide the blank-screen
			// problem into: raw vector display list, BitmapData->Bitmap presentation,
			// and the live Flixel camera buffer mirrored without FlxCamera transforms.
			gate2aVectorProbe = new Shape();
			gate2aVectorProbe.graphics.beginFill(0xFF0000, 1.0);
			gate2aVectorProbe.graphics.drawRect(30, 30, 200, 100);
			gate2aVectorProbe.graphics.endFill();
			addChild(gate2aVectorProbe);

			gate2aBitmapProbe = new Bitmap(new BitmapData(200, 100, false, 0x00FF00));
			gate2aBitmapProbe.x = 260;
			gate2aBitmapProbe.y = 30;
			addChild(gate2aBitmapProbe);

			gate2aCameraBacking = new Shape();
			gate2aCameraBacking.graphics.beginFill(0x0000FF, 1.0);
			gate2aCameraBacking.graphics.drawRect(480, 20, 180, 110);
			gate2aCameraBacking.graphics.endFill();
			addChild(gate2aCameraBacking);

			addEventListener(Event.ENTER_FRAME, updateGate2aRenderProbes);
		}

		private function updateGate2aRenderProbes(event:Event):void
		{
			if (gate2aCameraMirror == null && FlxG.camera != null && FlxG.camera.buffer != null)
			{
				gate2aCameraMirror = new Bitmap(FlxG.camera.buffer);
				gate2aCameraMirror.x = 490;
				gate2aCameraMirror.y = 30;
				gate2aCameraMirror.scaleX = 0.25;
				gate2aCameraMirror.scaleY = 0.25;
				addChild(gate2aCameraMirror);
			}

			// Keep the diagnostic strip above Flixel so screenshots can distinguish
			// root presentation from the engine's normal camera sprite.
			if (gate2aVectorProbe != null && contains(gate2aVectorProbe))
				setChildIndex(gate2aVectorProbe, numChildren - 1);
			if (gate2aBitmapProbe != null && contains(gate2aBitmapProbe))
				setChildIndex(gate2aBitmapProbe, numChildren - 1);
			if (gate2aCameraBacking != null && contains(gate2aCameraBacking))
				setChildIndex(gate2aCameraBacking, numChildren - 1);
			if (gate2aCameraMirror != null && contains(gate2aCameraMirror))
				setChildIndex(gate2aCameraMirror, numChildren - 1);
		}
	}
}
