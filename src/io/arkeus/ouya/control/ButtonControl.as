package io.arkeus.ouya.control {
	import flash.events.Event;
	import flash.ui.GameInputControl;

	import io.arkeus.ouya.ControllerInput;
	import io.arkeus.ouya.controller.GameController;

	public class ButtonControl extends GameControl {
		private var changed:Boolean = false;
		private var minimum:Number;
		private var maximum:Number;
		private var lastValue:Boolean = false;
		private var syntheticHeld:Boolean = false;
		private var syntheticPressPending:Boolean = false;
		private var syntheticReleasePending:Boolean = false;

		public function ButtonControl(device:GameController, control:GameInputControl, minimum:Number = 0.5, maximum:Number = 1) {
			super(device, control);
			this.minimum = minimum;
			this.maximum = maximum;
		}

		public function get pressed():Boolean {
			// A mobile-synthesized controller edge must survive until the legacy game
			// actually polls it. ControllerInput's ENTER_FRAME clock can advance between
			// a native TOUCH_BEGIN and the state's update(), so timestamp-only emulation
			// can otherwise disappear before it is observed. Consume exactly one edge.
			if (syntheticPressPending) {
				syntheticPressPending = false;
				return true;
			}
			return updatedAt >= ControllerInput.previous && held && changed;
		}

		public function get released():Boolean {
			if (syntheticReleasePending) {
				syntheticReleasePending = false;
				return true;
			}
			return updatedAt >= ControllerInput.previous && !held && changed;
		}

		public function get held():Boolean {
			return syntheticHeld || (value >= minimum && value <= maximum);
		}

		/**
		 * Mobile compatibility hook: queue one controller transition without a
		 * physical GameInputControl. The edge is consumed by the first legacy poll,
		 * while held remains true until emulateRelease().
		 */
		public function emulatePress():void {
			syntheticHeld = true;
			syntheticPressPending = true;
			syntheticReleasePending = false;
			value = maximum;
			updatedAt = ControllerInput.now;
			changed = true;
		}

		public function emulateRelease():void {
			syntheticHeld = false;
			syntheticReleasePending = true;
			value = 0;
			updatedAt = ControllerInput.now;
			changed = true;
		}

		override public function reset():void {
			super.reset();
			changed = false;
			syntheticHeld = false;
			syntheticPressPending = false;
			syntheticReleasePending = false;
		}

		override protected function onChange(event:Event):void {
			var beforeHeld:Boolean = held;
			super.onChange(event);
			changed = held != beforeHeld;
	}
}
