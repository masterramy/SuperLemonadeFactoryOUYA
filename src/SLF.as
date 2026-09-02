package
{
	import flash.events.Event;
	import flash.text.TextField;
	import flash.text.TextFormat;
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
		private var gate2aDiag:TextField;
		private var gate2aFrames:uint = 0;

		public function SLF()
		{
			// RIGHT ONE
			super(640, 360, PCIntroState, 3, 60, 30);

			// Legacy gameplay polls FlxG.ouyaController directly in many states.
			// A modern Android device may have no OUYA/GameInput hardware at all, so
			// install an inert typed controller until PCIntroState discovers real input.
			if (FlxG.ouyaController == null)
				FlxG.ouyaController = new OuyaController(null);
			
			FlxG.debug = forceDebugger = false;
			Registry.isPCVersion = true;
			Registry.isWinnitron = false;
			Registry.DEMO = false;
			FlxG.usingJoystick = false;

			// Run 22 falsified the buffer-locking hypothesis; restore historical setting.
			FlxG.useBufferLocking = false;

			// Gate 2A TEMPORARY DIAGNOSTIC ONLY. Surface the exact boundary between
			// PCIntroState.create(), the first update, and Flixel camera drawing.
			gate2aDiag = new TextField();
			gate2aDiag.width = 1860;
			gate2aDiag.height = 250;
			gate2aDiag.x = 30;
			gate2aDiag.y = 30;
			gate2aDiag.multiline = true;
			gate2aDiag.wordWrap = true;
			gate2aDiag.selectable = false;
			gate2aDiag.background = true;
			gate2aDiag.backgroundColor = 0x000000;
			gate2aDiag.defaultTextFormat = new TextFormat("_sans", 26, 0xffffff);
			gate2aDiag.text = "Gate2A: SLF constructed; waiting for Flixel frame";
			addChild(gate2aDiag);
		}

		override protected function onEnterFrame(event:Event=null):void
		{
			gate2aFrames++;
			try
			{
				super.onEnterFrame(event);
				var cameraState:String = "camera=null";
				if (FlxG.camera != null)
				{
					cameraState = "camera=yes bg=0x" + FlxG.camera.bgColor.toString(16)
						+ " attached=" + (FlxG.camera.getContainerSprite().parent != null);
					if (FlxG.camera.buffer != null)
						cameraState += " pixel00=0x" + FlxG.camera.buffer.getPixel32(0,0).toString(16);
				}
				gate2aDiag.text = "Gate2A frame=" + gate2aFrames + " super.onEnterFrame=OK\n" + cameraState
					+ "\nstate alive; if camera pixel is nonzero but game is blank, presentation is at fault.";
			}
			catch (e:Error)
			{
				gate2aDiag.text = "Gate2A frame=" + gate2aFrames + " UNCAUGHT AS3 ERROR\n" + e.toString()
					+ "\n" + (e.getStackTrace() == null ? "(no release stack trace)" : e.getStackTrace());
			}

			if (gate2aDiag != null && contains(gate2aDiag))
				setChildIndex(gate2aDiag, numChildren - 1);
		}
	}
}
