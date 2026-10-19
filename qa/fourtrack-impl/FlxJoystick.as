package org.flixel.system.input
{
	import flash.ui.GameInput;
	import flash.ui.GameInputControl;
	import flash.ui.GameInputDevice;
    import flash.utils.getTimer;
	import org.flixel.FlxG;

	/**
	 * A Flixel Wrapper for joyquery
	 * 
	 * @author Initials
	 */
	public class FlxJoystick
	{
			private var j1Button0Pressed:Boolean;
		private var j1Button1Pressed:Boolean;
		private var j1Button2Pressed:Boolean;
		private var j1Button3Pressed:Boolean;
		private var j1Button4Pressed:Boolean;		
		private var j1Button5Pressed:Boolean;
		private var j1Button6Pressed:Boolean;
		private var j1Button7Pressed:Boolean;
		private var j1Button8Pressed:Boolean;
		private var j1Button9Pressed:Boolean;
		
		private var j1Button0JustPressed:Boolean;
		private var j1Button1JustPressed:Boolean;
		private var j1Button2JustPressed:Boolean;
		private var j1Button3JustPressed:Boolean;
		private var j1Button4JustPressed:Boolean;		
		private var j1Button5JustPressed:Boolean;
		private var j1Button6JustPressed:Boolean;
		private var j1Button7JustPressed:Boolean;
		private var j1Button8JustPressed:Boolean;
		private var j1Button9JustPressed:Boolean;
		
		public var j1ButtonAPressed:Boolean;
		public var j1ButtonBPressed:Boolean;
		public var j1ButtonXPressed:Boolean;
		public var j1ButtonYPressed:Boolean;
		public var j1ButtonLBPressed:Boolean;		
		public var j1ButtonRBPressed:Boolean;
		public var j1ButtonBackPressed:Boolean;
		public var j1ButtonStartPressed:Boolean;
		public var j1ButtonLeftStickClickPressed:Boolean;
		public var j1ButtonRightStickClickPressed:Boolean;
		
		public var j1ButtonAJustPressed:Boolean;
		public var j1ButtonBJustPressed:Boolean;
		public var j1ButtonXJustPressed:Boolean;
		public var j1ButtonYJustPressed:Boolean;
		public var j1ButtonLBJustPressed:Boolean;		
		public var j1ButtonRBJustPressed:Boolean;
		public var j1ButtonBackJustPressed:Boolean;
		public var j1ButtonStartJustPressed:Boolean;
		public var j1ButtonLeftStickClickJustPressed:Boolean;
		public var j1ButtonRightStickClickJustPressed:Boolean;		
		
		public var j1Stick1X:Number;
		public var j1Stick1Y:Number;	
		/*
		 * The angle of the stick 1
		 */
		public var j1Stick1Angle:Number;
		
		public var j1Stick2X:Number;
		public var j1Stick2Y:Number;
		/*
		 * The angle of the stick 2
		 */
		public var j1Stick2Angle:Number;		
		public var j1Trigger:Number;
		
		public var j1Stick1DownPressed:Boolean;
		public var j1Stick1UpPressed:Boolean;
		public var j1Stick1LeftPressed:Boolean;
		public var j1Stick1RightPressed:Boolean;
		
		public var j1Stick1DownJustPressed:Boolean;
		public var j1Stick1UpJustPressed:Boolean;
		public var j1Stick1LeftJustPressed:Boolean;
		public var j1Stick1RightJustPressed:Boolean;	
		
		public var j1Stick2DownPressed:Boolean;
		public var j1Stick2UpPressed:Boolean;
		public var j1Stick2LeftPressed:Boolean;
		public var j1Stick2RightPressed:Boolean;
		
		public var j1Stick2DownJustPressed:Boolean;
		public var j1Stick2UpJustPressed:Boolean;
		public var j1Stick2LeftJustPressed:Boolean;
		public var j1Stick2RightJustPressed:Boolean;
		
		// JOYSTICK 2
		
		private var j2Button0Pressed:Boolean;
		private var j2Button1Pressed:Boolean;
		private var j2Button2Pressed:Boolean;
		private var j2Button3Pressed:Boolean;
		private var j2Button4Pressed:Boolean;		
		private var j2Button5Pressed:Boolean;
		private var j2Button6Pressed:Boolean;
		private var j2Button7Pressed:Boolean;
		private var j2Button8Pressed:Boolean;
		private var j2Button9Pressed:Boolean;
		
		private var j2Button0JustPressed:Boolean;
		private var j2Button1JustPressed:Boolean;
		private var j2Button2JustPressed:Boolean;
		private var j2Button3JustPressed:Boolean;
		private var j2Button4JustPressed:Boolean;		
		private var j2Button5JustPressed:Boolean;
		private var j2Button6JustPressed:Boolean;
		private var j2Button7JustPressed:Boolean;
		private var j2Button8JustPressed:Boolean;
		private var j2Button9JustPressed:Boolean;
		
		public var j2ButtonAPressed:Boolean;
		public var j2ButtonBPressed:Boolean;
		public var j2ButtonXPressed:Boolean;
		public var j2ButtonYPressed:Boolean;
		public var j2ButtonLBPressed:Boolean;		
		public var j2ButtonRBPressed:Boolean;
		public var j2ButtonBackPressed:Boolean;
		public var j2ButtonStartPressed:Boolean;
		public var j2ButtonLeftStickClickPressed:Boolean;
		public var j2ButtonRightStickClickPressed:Boolean;
		
		public var j2ButtonAJustPressed:Boolean;
		public var j2ButtonBJustPressed:Boolean;
		public var j2ButtonXJustPressed:Boolean;
		public var j2ButtonYJustPressed:Boolean;
		public var j2ButtonLBJustPressed:Boolean;		
		public var j2ButtonRBJustPressed:Boolean;
		public var j2ButtonBackJustPressed:Boolean;
		public var j2ButtonStartJustPressed:Boolean;
		public var j2ButtonLeftStickClickJustPressed:Boolean;
		public var j2ButtonRightStickClickJustPressed:Boolean;	
		
		public var j2Stick1X:Number;
		public var j2Stick1Y:Number;		
		public var j2Stick2X:Number;
		public var j2Stick2Y:Number;
		public var j2Trigger:Number;
		
		/*
		 * The angle of the stick 1
		 */
		public var j2Stick1Angle:Number;
		/*
		 * The angle of the stick 2
		 */
		public var j2Stick2Angle:Number;		
		
		public var j2Stick1DownPressed:Boolean;
		public var j2Stick1UpPressed:Boolean;
		public var j2Stick1LeftPressed:Boolean;
		public var j2Stick1RightPressed:Boolean;
		
		public var j2Stick1DownJustPressed:Boolean;
		public var j2Stick1UpJustPressed:Boolean;
		public var j2Stick1LeftJustPressed:Boolean;
		public var j2Stick1RightJustPressed:Boolean;	
		
		public var j2Stick2DownPressed:Boolean;
		public var j2Stick2UpPressed:Boolean;
		public var j2Stick2LeftPressed:Boolean;
		public var j2Stick2RightPressed:Boolean;
		
		public var j2Stick2DownJustPressed:Boolean;
		public var j2Stick2UpJustPressed:Boolean;
		public var j2Stick2LeftJustPressed:Boolean;
		public var j2Stick2RightJustPressed:Boolean;	
		
		// Independent Android post-launch input bridge. Does not change gameplay
		// physics or remove the existing touch and keyboard control paths.
		// AIR's GameInput IDs differ by device/OS. Only enable mappings for
		// known Android or legacy indexed layouts; unknown layouts fail closed.
		private var gameInput:GameInput;
		private var active:GameInputDevice;
        private var secondary:GameInputDevice;
        private var secondaryControls:Object = {};
        private var secondaryModernButtons:Boolean = false;
        private var last2A:Boolean = false;
        private var last2B:Boolean = false;
        private var last2X:Boolean = false;
        private var last2Y:Boolean = false;
        private var last2Start:Boolean = false;
        private var last2Back:Boolean = false;
        private var last2Left:Boolean = false;
        private var last2Right:Boolean = false;
        private var last2Up:Boolean = false;
        private var last2Down:Boolean = false;
		private var controls:Object = {};
		private var modernButtons:Boolean = false;
		private var lastA:Boolean = false;
		private var lastB:Boolean = false;
		private var lastX:Boolean = false;
		private var lastY:Boolean = false;
		private var lastBack:Boolean = false;
		private var lastStart:Boolean = false;
		private var lastLeft:Boolean = false;
		private var lastRight:Boolean = false;
		private var lastUp:Boolean = false;
		private var lastDown:Boolean = false;

        // Diagnostic strings contain only controller-reported product names,
        // never persistent hardware IDs or player/account information.
        private var qaDeviceName:String = "none";
        private var qaMapping:String = "unmapped";
        private var qaLastInput:String = "none";
        private var qaLastInputTime:int = 0;
        private var qaEventCount:int = 0;
        public function qaStatus():String
        {
            // Show latest recognized action even AFTER release so a screenshot
            // can prove button mappings; never store an identifying device ID.
            var held:String = (j1ButtonAPressed ? "A " : "") +
                (j1ButtonBPressed ? "B " : "") +
                (j1ButtonXPressed ? "X " : "") +
                (j1ButtonYPressed ? "Y " : "") +
                (j1Stick1LeftPressed ? "LEFT " : "") +
                (j1Stick1RightPressed ? "RIGHT " : "") +
                (j1Stick1UpPressed ? "UP " : "") +
                (j1Stick1DownPressed ? "DOWN " : "");
            if (held.length == 0) held = "none";
            var last:String = qaLastInput;
            if (qaLastInputTime > 0 && getTimer() - qaLastInputTime > 120000)
                last = "expired";
            return "Pad: " + qaDeviceName + " / " + qaMapping + "\n" +
                "Held: " + held + "\n" +
                "Last: " + last + "  Count: " + qaEventCount;
        }

        private function noteQAEdge(key:String):void
        {
            qaLastInput = key;
            qaLastInputTime = getTimer();
            if (qaEventCount < 999999) qaEventCount++;
        }

		public function FlxJoystick()
		{
			try { gameInput = new GameInput(); } catch (error:Error) { gameInput = null; }
		}

		private function valueFor(id:String):Number
		{
			var c:GameInputControl = controls[id] as GameInputControl;
			if (c == null) return 0;
			try { return c.value; } catch (error:Error) { return 0; }
		}

		private function down(ids:Array):Boolean
		{
			for each (var id:String in ids) if (valueFor(id) > 0.5) return true;
			return false;
		}

        private function secondaryValueFor(id:String):Number
        {
            var c:GameInputControl = secondaryControls[id] as GameInputControl;
            if (c == null) return 0;
            try { return c.value; } catch (error:Error) { return 0; }
        }

        private function secondaryDown(ids:Array):Boolean
        {
            for each (var id:String in ids)
                if (secondaryValueFor(id) > 0.5) return true;
            return false;
        }

        private function clearSecondaryState():void
        {
            last2A = last2B = last2X = last2Y = false;
            last2Start = last2Back = false;
            last2Left = last2Right = last2Up = last2Down = false;
            j2ButtonAPressed = j2ButtonBPressed = j2ButtonXPressed = j2ButtonYPressed = false;
            j2ButtonAJustPressed = j2ButtonBJustPressed = j2ButtonXJustPressed = j2ButtonYJustPressed = false;
            j2ButtonStartPressed = j2ButtonBackPressed = false;
            j2ButtonStartJustPressed = j2ButtonBackJustPressed = false;
            j2Stick1LeftPressed = j2Stick1RightPressed = j2Stick1UpPressed = j2Stick1DownPressed = false;
            j2Stick1LeftJustPressed = j2Stick1RightJustPressed = false;
            j2Stick1UpJustPressed = j2Stick1DownJustPressed = false;
            j2Stick1X = j2Stick1Y = 0;
        }

		private function clearState():void
		{
			lastA = lastB = lastX = lastY = lastBack = lastStart = false;
			lastLeft = lastRight = lastUp = lastDown = false;
			j1ButtonAPressed = j1ButtonBPressed = j1ButtonXPressed = j1ButtonYPressed = false;
			j1ButtonAJustPressed = j1ButtonBJustPressed = j1ButtonXJustPressed = j1ButtonYJustPressed = false;
			j1ButtonBackPressed = j1ButtonStartPressed = false;
			j1ButtonBackJustPressed = j1ButtonStartJustPressed = false;
			j1Stick1LeftPressed = j1Stick1RightPressed = j1Stick1UpPressed = j1Stick1DownPressed = false;
			j1Stick1LeftJustPressed = j1Stick1RightJustPressed = false;
			j1Stick1UpJustPressed = j1Stick1DownJustPressed = false;
			j1Stick1X = j1Stick1Y = 0;
		}

		// Android may report an Xbox, DualSense, generic HID gamepad or
		// localized name without the English word "controller".  Device
		// capability, not product branding, determines whether its input
		// can safely control a character. Keyboards lacking a pad topology
		// remain excluded.
		private function isGamepadTopology(device:GameInputDevice):Boolean
		{
			var ids:Object = {};
			try {
				for (var i:int = 0; i < device.numControls; i++) {
					var candidate:GameInputControl = device.getControlAt(i);
					if (candidate != null) ids[candidate.id] = true;
				}
			} catch (error:Error) { return false; }
			var modernFaces:Boolean = ids["BUTTON_96"] && ids["BUTTON_97"] &&
				ids["BUTTON_99"] && ids["BUTTON_100"];
			var legacyFaces:Boolean = ids["BUTTON_4"] && ids["BUTTON_5"] &&
				ids["BUTTON_6"] && ids["BUTTON_7"];
			var hasFaceButtons:Boolean = modernFaces || legacyFaces;
			var hasDirectionControl:Boolean =
				(ids["AXIS_0"] && ids["AXIS_1"]) ||
				(ids["AXIS_15"] && ids["AXIS_16"]) ||
				(ids["BUTTON_19"] && ids["BUTTON_20"] &&
				 ids["BUTTON_21"] && ids["BUTTON_22"]) ||
				(ids["BUTTON_16"] && ids["BUTTON_17"] &&
				 ids["BUTTON_18"] && ids["BUTTON_19"]);
			return hasFaceButtons && hasDirectionControl;
		}

        private function selectDevice():void
        {
            // Keep each physical GameInputDevice assigned to just one player.
            // Enumeration order is stable within a frame and hot-unplug clears
            // its previous pressed edges rather than sticking movement on.
            var found:GameInputDevice = null;
            var foundSecondary:GameInputDevice = null;
            var name:String = "";
            try
            {
                var eligible:Array = [];
                for (var i:int = 0; i < GameInput.numDevices; i++)
                {
                    var d:GameInputDevice = GameInput.getDeviceAt(i);
                    if (d != null && isGamepadTopology(d)) eligible.push(d);
                }
                // Preserve physical identities regardless of enumeration order.
                // If one controller disconnects, its surviving partner remains
                // assigned to its original player, never silently promoted.
                for each (d in eligible)
                {
                    if (d == active) found = d;
                    else if (d == secondary) foundSecondary = d;
                }
                // Fill vacant slots only from devices not already assigned.
                for each (d in eligible)
                {
                    if (d == found || d == foundSecondary) continue;
                    if (found == null) found = d;
                    else if (foundSecondary == null) foundSecondary = d;
                }
                if (found != null)
                    name = found.name == null ? "unnamed" : found.name.toLowerCase();
            }
            catch (error:Error) { found = null; foundSecondary = null; }
            if (found != active)
            {
                active = found;
                controls = {};
                clearState();
                if (active == null)
                {
                    qaDeviceName = "none";
                    qaMapping = "disconnected";
                }
                else try
                {
                    active.enabled = true;
                    for (var j:int = 0; j < active.numControls; j++)
                    {
                        var c:GameInputControl = active.getControlAt(j);
                        if (c != null) controls[c.id] = c;
                    }
                    modernButtons = controls["BUTTON_96"] != null;
                    qaDeviceName = name.substr(0, 26);
                    qaMapping = modernButtons ? "android" : "legacy";
                }
                catch (error2:Error)
                {
                    active = null;
                    controls = {};
                    qaDeviceName = "none";
                    qaMapping = "device error";
                    clearState();
                }
            }
            if (foundSecondary != secondary)
            {
                secondary = foundSecondary;
                secondaryControls = {};
                clearSecondaryState();
                if (secondary != null) try
                {
                    secondary.enabled = true;
                    for (var k:int = 0; k < secondary.numControls; k++)
                    {
                        var secondaryControl:GameInputControl = secondary.getControlAt(k);
                        if (secondaryControl != null) secondaryControls[secondaryControl.id] = secondaryControl;
                    }
                    secondaryModernButtons = secondaryControls["BUTTON_96"] != null;
                }
                catch (error3:Error)
                {
                    secondary = null;
                    secondaryControls = {};
                    clearSecondaryState();
                }
            }
        }

        private function updateSecondary():void
        {
            if (secondary == null) { clearSecondaryState(); return; }
            var a:Boolean = secondaryDown(secondaryModernButtons ? ["BUTTON_96"] : ["BUTTON_4"]);
            var b:Boolean = secondaryDown(secondaryModernButtons ? ["BUTTON_97"] : ["BUTTON_5"]);
            var x:Boolean = secondaryDown(secondaryModernButtons ? ["BUTTON_99"] : ["BUTTON_6"]);
            var y:Boolean = secondaryDown(secondaryModernButtons ? ["BUTTON_100"] : ["BUTTON_7"]);
            var start:Boolean = secondaryDown(secondaryModernButtons ? ["BUTTON_108"] : ["BUTTON_13"]);
            var back:Boolean = secondaryDown(secondaryModernButtons ? ["BUTTON_109"] : ["BUTTON_12"]);
            var axisX:Number = secondaryValueFor("AXIS_0");
            var axisY:Number = secondaryValueFor("AXIS_1");
            var hatX:Number = secondaryValueFor("AXIS_15");
            var hatY:Number = secondaryValueFor("AXIS_16");
            var left:Boolean = axisX < -0.30 || hatX < -0.50 || secondaryDown(secondaryModernButtons ? ["BUTTON_21"] : ["BUTTON_16"]);
            var right:Boolean = axisX > 0.30 || hatX > 0.50 || secondaryDown(secondaryModernButtons ? ["BUTTON_22"] : ["BUTTON_17"]);
            var up:Boolean = axisY < -0.30 || hatY < -0.50 || secondaryDown(secondaryModernButtons ? ["BUTTON_19"] : ["BUTTON_18"]);
            var downHeld:Boolean = axisY > 0.30 || hatY > 0.50 || secondaryDown(secondaryModernButtons ? ["BUTTON_20"] : ["BUTTON_19"]);
            j2Stick1X = axisX;
            j2Stick1Y = axisY;
            j2ButtonAPressed = a; j2ButtonBPressed = b; j2ButtonXPressed = x; j2ButtonYPressed = y;
            j2ButtonAJustPressed = a && !last2A; j2ButtonBJustPressed = b && !last2B;
            j2ButtonXJustPressed = x && !last2X; j2ButtonYJustPressed = y && !last2Y;
            j2ButtonStartPressed = start; j2ButtonBackPressed = back;
            j2ButtonStartJustPressed = start && !last2Start;
            j2ButtonBackJustPressed = back && !last2Back;
            j2Stick1LeftPressed = left; j2Stick1RightPressed = right;
            j2Stick1UpPressed = up; j2Stick1DownPressed = downHeld;
            j2Stick1LeftJustPressed = left && !last2Left;
            j2Stick1RightJustPressed = right && !last2Right;
            j2Stick1UpJustPressed = up && !last2Up;
            j2Stick1DownJustPressed = downHeld && !last2Down;
            last2A = a; last2B = b; last2X = x; last2Y = y;
            last2Start = start; last2Back = back;
            last2Left = left; last2Right = right; last2Up = up; last2Down = downHeld;
        }

		public function update():void
		{
			selectDevice();
			if (active == null) { clearState(); clearSecondaryState(); return; }
			var a:Boolean = down(modernButtons ? ["BUTTON_96"] : ["BUTTON_4"]);
			var b:Boolean = down(modernButtons ? ["BUTTON_97"] : ["BUTTON_5"]);
			var x:Boolean = down(modernButtons ? ["BUTTON_99"] : ["BUTTON_6"]);
			var y:Boolean = down(modernButtons ? ["BUTTON_100"] : ["BUTTON_7"]);
			var start:Boolean = down(modernButtons ? ["BUTTON_108"] : ["BUTTON_13"]);
			var back:Boolean = down(modernButtons ? ["BUTTON_109"] : ["BUTTON_12"]);
			var axisX:Number = valueFor("AXIS_0");
			var axisY:Number = valueFor("AXIS_1");
			// Android AXIS_HAT_X=15 and AXIS_HAT_Y=16 are frequently used by
			// wireless-controller D-pads, independently of left-stick axes.
			// Require a clear threshold so neutral hat values do not drift.
			var hatX:Number = valueFor("AXIS_15");
			var hatY:Number = valueFor("AXIS_16");
			var left:Boolean = axisX < -0.30 || hatX < -0.50 || down(modernButtons ? ["BUTTON_21"] : ["BUTTON_16"]);
			var right:Boolean = axisX > 0.30 || hatX > 0.50 || down(modernButtons ? ["BUTTON_22"] : ["BUTTON_17"]);
			var up:Boolean = axisY < -0.30 || hatY < -0.50 || down(modernButtons ? ["BUTTON_19"] : ["BUTTON_18"]);
			var downHeld:Boolean = axisY > 0.30 || hatY > 0.50 || down(modernButtons ? ["BUTTON_20"] : ["BUTTON_19"]);
			j1Stick1X = axisX;
			j1Stick1Y = axisY;
			j1ButtonAPressed = a; j1ButtonBPressed = b; j1ButtonXPressed = x; j1ButtonYPressed = y;
			j1ButtonAJustPressed = a && !lastA; j1ButtonBJustPressed = b && !lastB;
			j1ButtonXJustPressed = x && !lastX; j1ButtonYJustPressed = y && !lastY;
			j1ButtonStartPressed = start; j1ButtonBackPressed = back;
			j1ButtonStartJustPressed = start && !lastStart;
			j1ButtonBackJustPressed = back && !lastBack;
			j1Stick1LeftPressed = left; j1Stick1RightPressed = right;
			j1Stick1UpPressed = up; j1Stick1DownPressed = downHeld;
			j1Stick1LeftJustPressed = left && !lastLeft;
			j1Stick1RightJustPressed = right && !lastRight;
			j1Stick1UpJustPressed = up && !lastUp;
			j1Stick1DownJustPressed = downHeld && !lastDown;
			if (j1ButtonAJustPressed) noteQAEdge("A");
            else if (j1ButtonBJustPressed) noteQAEdge("B");
            else if (j1ButtonXJustPressed) noteQAEdge("X");
            else if (j1ButtonYJustPressed) noteQAEdge("Y");
            else if (j1Stick1LeftJustPressed) noteQAEdge("LEFT");
            else if (j1Stick1RightJustPressed) noteQAEdge("RIGHT");
            else if (j1Stick1UpJustPressed) noteQAEdge("UP");
            else if (j1Stick1DownJustPressed) noteQAEdge("DOWN");
            else if (j1ButtonStartJustPressed) noteQAEdge("START");
            else if (j1ButtonBackJustPressed) noteQAEdge("BACK");
            lastA = a; lastB = b; lastX = x; lastY = y; lastStart = start; lastBack = back;
			lastLeft = left; lastRight = right; lastUp = up; lastDown = downHeld;
            updateSecondary();
		}
	}
}
//package org.flixel.system.input
//{
	//import flash.display.Sprite;
	//import flash.display.StageAlign;
	//import flash.display.StageScaleMode;
	//import flash.events.Event;
	//import flash.events.GameInputEvent;
	//import flash.text.TextField;
	//import flash.ui.GameInput;
	//import flash.ui.GameInputControl;
	//import flash.ui.GameInputDevice;
	//import flash.utils.ByteArray;
	//import flash.utils.Timer;
	//
	//import org.flixel.*;
	//
	 //
	//public class FlxJoystick
	//{
		//private var j1Button0Pressed:Boolean;
		//private var j1Button1Pressed:Boolean;
		//private var j1Button2Pressed:Boolean;
		//private var j1Button3Pressed:Boolean;
		//private var j1Button4Pressed:Boolean;		
		//private var j1Button5Pressed:Boolean;
		//private var j1Button6Pressed:Boolean;
		//private var j1Button7Pressed:Boolean;
		//private var j1Button8Pressed:Boolean;
		//private var j1Button9Pressed:Boolean;
		//
		//private var j1Button0JustPressed:Boolean;
		//private var j1Button1JustPressed:Boolean;
		//private var j1Button2JustPressed:Boolean;
		//private var j1Button3JustPressed:Boolean;
		//private var j1Button4JustPressed:Boolean;		
		//private var j1Button5JustPressed:Boolean;
		//private var j1Button6JustPressed:Boolean;
		//private var j1Button7JustPressed:Boolean;
		//private var j1Button8JustPressed:Boolean;
		//private var j1Button9JustPressed:Boolean;
		//
		//public var j1ButtonAPressed:Boolean;
		//public var j1ButtonBPressed:Boolean;
		//public var j1ButtonXPressed:Boolean;
		//public var j1ButtonYPressed:Boolean;
		//public var j1ButtonLBPressed:Boolean;		
		//public var j1ButtonRBPressed:Boolean;
		//public var j1ButtonBackPressed:Boolean;
		//public var j1ButtonStartPressed:Boolean;
		//public var j1ButtonLeftStickClickPressed:Boolean;
		//public var j1ButtonRightStickClickPressed:Boolean;
		//
		//public var j1ButtonAJustPressed:Boolean;
		//public var j1ButtonBJustPressed:Boolean;
		//public var j1ButtonXJustPressed:Boolean;
		//public var j1ButtonYJustPressed:Boolean;
		//public var j1ButtonLBJustPressed:Boolean;		
		//public var j1ButtonRBJustPressed:Boolean;
		//public var j1ButtonBackJustPressed:Boolean;
		//public var j1ButtonStartJustPressed:Boolean;
		//public var j1ButtonLeftStickClickJustPressed:Boolean;
		//public var j1ButtonRightStickClickJustPressed:Boolean;		
		//
		//public var j1Stick1X:Number;
		//public var j1Stick1Y:Number;	
		///*
		 //* The angle of the stick 1
		 //*/
		//public var j1Stick1Angle:Number;
		//
		//public var j1Stick2X:Number;
		//public var j1Stick2Y:Number;
		///*
		 //* The angle of the stick 2
		 //*/
		//public var j1Stick2Angle:Number;		
		//public var j1Trigger:Number;
		//
		//public var j1Stick1DownPressed:Boolean;
		//public var j1Stick1UpPressed:Boolean;
		//public var j1Stick1LeftPressed:Boolean;
		//public var j1Stick1RightPressed:Boolean;
		//
		//public var j1Stick1DownJustPressed:Boolean;
		//public var j1Stick1UpJustPressed:Boolean;
		//public var j1Stick1LeftJustPressed:Boolean;
		//public var j1Stick1RightJustPressed:Boolean;	
		//
		//public var j1Stick2DownPressed:Boolean;
		//public var j1Stick2UpPressed:Boolean;
		//public var j1Stick2LeftPressed:Boolean;
		//public var j1Stick2RightPressed:Boolean;
		//
		//public var j1Stick2DownJustPressed:Boolean;
		//public var j1Stick2UpJustPressed:Boolean;
		//public var j1Stick2LeftJustPressed:Boolean;
		//public var j1Stick2RightJustPressed:Boolean;
		//
		// JOYSTICK 2
		//
		//private var j2Button0Pressed:Boolean;
		//private var j2Button1Pressed:Boolean;
		//private var j2Button2Pressed:Boolean;
		//private var j2Button3Pressed:Boolean;
		//private var j2Button4Pressed:Boolean;		
		//private var j2Button5Pressed:Boolean;
		//private var j2Button6Pressed:Boolean;
		//private var j2Button7Pressed:Boolean;
		//private var j2Button8Pressed:Boolean;
		//private var j2Button9Pressed:Boolean;
		//
		//private var j2Button0JustPressed:Boolean;
		//private var j2Button1JustPressed:Boolean;
		//private var j2Button2JustPressed:Boolean;
		//private var j2Button3JustPressed:Boolean;
		//private var j2Button4JustPressed:Boolean;		
		//private var j2Button5JustPressed:Boolean;
		//private var j2Button6JustPressed:Boolean;
		//private var j2Button7JustPressed:Boolean;
		//private var j2Button8JustPressed:Boolean;
		//private var j2Button9JustPressed:Boolean;
		//
		//public var j2ButtonAPressed:Boolean;
		//public var j2ButtonBPressed:Boolean;
		//public var j2ButtonXPressed:Boolean;
		//public var j2ButtonYPressed:Boolean;
		//public var j2ButtonLBPressed:Boolean;		
		//public var j2ButtonRBPressed:Boolean;
		//public var j2ButtonBackPressed:Boolean;
		//public var j2ButtonStartPressed:Boolean;
		//public var j2ButtonLeftStickClickPressed:Boolean;
		//public var j2ButtonRightStickClickPressed:Boolean;
		//
		//public var j2ButtonAJustPressed:Boolean;
		//public var j2ButtonBJustPressed:Boolean;
		//public var j2ButtonXJustPressed:Boolean;
		//public var j2ButtonYJustPressed:Boolean;
		//public var j2ButtonLBJustPressed:Boolean;		
		//public var j2ButtonRBJustPressed:Boolean;
		//public var j2ButtonBackJustPressed:Boolean;
		//public var j2ButtonStartJustPressed:Boolean;
		//public var j2ButtonLeftStickClickJustPressed:Boolean;
		//public var j2ButtonRightStickClickJustPressed:Boolean;	
		//
		//public var j2Stick1X:Number;
		//public var j2Stick1Y:Number;		
		//public var j2Stick2X:Number;
		//public var j2Stick2Y:Number;
		//public var j2Trigger:Number;
		//
		///*
		 //* The angle of the stick 1
		 //*/
		//public var j2Stick1Angle:Number;
		///*
		 //* The angle of the stick 2
		 //*/
		//public var j2Stick2Angle:Number;		
		//
		//public var j2Stick1DownPressed:Boolean;
		//public var j2Stick1UpPressed:Boolean;
		//public var j2Stick1LeftPressed:Boolean;
		//public var j2Stick1RightPressed:Boolean;
		//
		//public var j2Stick1DownJustPressed:Boolean;
		//public var j2Stick1UpJustPressed:Boolean;
		//public var j2Stick1LeftJustPressed:Boolean;
		//public var j2Stick1RightJustPressed:Boolean;	
		//
		//public var j2Stick2DownPressed:Boolean;
		//public var j2Stick2UpPressed:Boolean;
		//public var j2Stick2LeftPressed:Boolean;
		//public var j2Stick2RightPressed:Boolean;
		//
		//public var j2Stick2DownJustPressed:Boolean;
		//public var j2Stick2UpJustPressed:Boolean;
		//public var j2Stick2LeftJustPressed:Boolean;
		//public var j2Stick2RightJustPressed:Boolean;	
		//
		//private var gameInput:GameInput;
		//private var _device:GameInputDevice;
		//private var ba:ByteArray;
		//
		//
		//public function FlxJoystick()
		//{
			//super();
			//
			//ba = new ByteArray();
			//
			//gameInput = new GameInput();
			//gameInput.addEventListener(GameInputEvent.DEVICE_ADDED, handleDeviceAttached);
			//gameInput.addEventListener(GameInputEvent.DEVICE_REMOVED, handleDeviceRemoved);
			//
			//FlxG.log("start joystick");
		//}
		//
		//public function update():void
		//{
			//
			//
			//FlxG.log("Ok joystick");
		//}
		//
		//protected function handleDeviceRemoved(event:GameInputEvent):void
		//{
			//tf.appendText("Device is removed\n");
			//FlxG.log("Device is removed");
			//
		//}
		//
		//protected function handleDeviceAttached(e:GameInputEvent):void
		//{
			//FlxG.log("Device is added\n");
			//
			//
			//GameInputControlName.initialize(e.device);
			//
			//
			//for(var k:Number=0;k<GameInput.numDevices;k++){
				//_device = GameInput.getDeviceAt(k);
				//var _controls:Vector.<String> = new Vector.<String>;
				//_device.enabled = true;
				//
				//for (var i:Number = 0; i < _device.numControls; i++) {
					//var control:GameInputControl = _device.getControlAt(i);
					//control.addEventListener(Event.CHANGE,onChange);
					//_controls[i] = control.id;
				//}
				//
				//_device.startCachingSamples(30, _controls);
				//
				//
			//}
			//
			//for(var j:int=0; j<_controls.length; j++)
			//{
				//FlxG.log(_controls[j]);
			//}
			//
			//FlxG.stage.addEventListener(Event.ENTER_FRAME, getCachedSamples);
			//
		//}	
		//
		//protected function onChange(event:Event):void
		//{
			//var control:GameInputControl = event.target as GameInputControl;
			//
			//FlxG.log("The pressed control is " +control.name+" with value "+control.value+" \n");
		//}
		//
		//protected function getCachedSamples(event:Event):void
		//{
			//var data:ByteArray = new ByteArray();
			//var _device:GameInputDevice;
			//_device = GameInput.getDeviceAt(0);
			//
			//try
			//{
				//var completed:int = _device.getCachedSamples(data, true);
			//} 
			//catch(e:Error)
			//{
				//FlxG.log("FAIL \n");
			//}
			//
			//if(completed > 0 && data.length > 0)
			//{
				//
				//FlxG.log("Number of samples are "+completed+" and byte length is "+data.length+" \n");
			//}
		//}
		//
		//
		//
	//}
//}