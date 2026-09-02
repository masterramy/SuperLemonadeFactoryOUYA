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

		public function ButtonControl(device:GameController, control:GameInputControl, minimum:Number = 0.5, maximum:Number = 1) {
			super(device, control);
			this.minimum = minimum;
			this.maximum = maximum;
		}

		public function get pressed():Boolean {
			return updatedAt >= ControllerInput.previous && held && changed;
		}

		public function get released():Boolean {
			return updatedAt >= ControllerInput.previous && !held && changed;
		}

		public function get held():Boolean {
			return value >= minimum && value <= maximum;
		}

		/**
		 * Mobile compatibility hook: emulate one controller transition without a
		 * physical GameInputControl. This keeps legacy state logic authoritative
		 * while allowing an explicit touchscreen affordance to invoke it.
		 */
		public function emulatePress():void {
			value = maximum;
			updatedAt = ControllerInput.now;
			changed = true;
		}

		public function emulateRelease():void {
			value = 0;
			updatedAt = ControllerInput.now;
			changed = true;
		}

		override public function reset():void {
			super.reset();
			changed = false;
		}

		override protected function onChange(event:Event):void {
			var beforeHeld:Boolean = held;
			super.onChange(event);
			changed = held != beforeHeld;
		}
	}
}
