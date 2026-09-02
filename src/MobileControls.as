package
{
	import flash.display.DisplayObjectContainer;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.events.TouchEvent;
	import flash.geom.Rectangle;
	import flash.text.TextField;
	import flash.text.TextFormat;
	import flash.ui.Multitouch;
	import flash.ui.MultitouchInputMode;
	import flash.utils.setTimeout;
	import org.flixel.FlxG;

	/**
	 * Android/mobile compatibility layer derived from the title's original iOS
	 * control semantics. Native touch is translated into the legacy keyboard
	 * inputs already consumed by the game, leaving state/gameplay logic untouched.
	 */
	public class MobileControls
	{
		private static const KEY_LEFT:uint = 37;
		private static const KEY_UP:uint = 38;
		private static const KEY_RIGHT:uint = 39;
		private static const KEY_DOWN:uint = 40;
		private static const KEY_V:uint = 86;
		private static const KEY_X:uint = 88;
		private static const KEY_Z:uint = 90;

		private var root:DisplayObjectContainer;
		private var overlay:Sprite = new Sprite();
		private var touchKeys:Object = {};
		private var touchStarts:Object = {};
		private var keyCounts:Object = {};
		private var lastX:Number = NaN;
		private var lastY:Number = NaN;
		private var lastW:Number = NaN;
		private var lastH:Number = NaN;
		private var wasGameplay:Boolean = false;

		public function MobileControls(gameRoot:DisplayObjectContainer)
		{
			root = gameRoot;
			overlay.mouseEnabled = false;
			overlay.mouseChildren = false;
			if (root.stage != null)
				attach();
			else
				root.addEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
		}

		private function onAddedToStage(e:Event):void
		{
			root.removeEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
			attach();
		}

		private function attach():void
		{
			if (!Multitouch.supportsTouchEvents)
				return;
			Multitouch.inputMode = MultitouchInputMode.TOUCH_POINT;
			root.stage.addChild(overlay);
			root.stage.addEventListener(TouchEvent.TOUCH_BEGIN, onTouchBegin, false, 0, true);
			root.stage.addEventListener(TouchEvent.TOUCH_MOVE, onTouchMove, false, 0, true);
			root.stage.addEventListener(TouchEvent.TOUCH_END, onTouchEnd, false, 0, true);
			root.addEventListener(Event.ENTER_FRAME, onFrame, false, 0, true);
		}

		private function gameplayActive():Boolean
		{
			return FlxG.state != null && FlxG.state is PlayState;
		}

		private function gameBounds():Rectangle
		{
			if (root.stage == null)
				return new Rectangle();
			var bounds:Rectangle = root.getBounds(root.stage);
			if (bounds.width <= 0 || bounds.height <= 0)
				return new Rectangle(0, 0, root.stage.stageWidth, root.stage.stageHeight);
			return bounds;
		}

		private function onFrame(e:Event):void
		{
			var active:Boolean = gameplayActive();
			if (!active && wasGameplay)
				releaseAll();
			wasGameplay = active;
			overlay.visible = active;
			if (!active || root.stage == null)
				return;

			var bounds:Rectangle = gameBounds();
			if (lastX != bounds.x || lastY != bounds.y || lastW != bounds.width || lastH != bounds.height)
				drawOverlay(bounds);
			if (overlay.parent == root.stage)
				root.stage.setChildIndex(overlay, root.stage.numChildren - 1);
		}

		private function controlKey(x:Number, y:Number):uint
		{
			var bounds:Rectangle = gameBounds();
			var zoneY:Number = bounds.y + bounds.height * 0.75;
			if (!bounds.contains(x, y) || y < zoneY)
				return 0;
			var nx:Number = (x - bounds.x) / bounds.width;
			if (nx < 1.0 / 6.0) return KEY_LEFT;
			if (nx < 2.0 / 6.0) return KEY_RIGHT;
			if (nx >= 4.0 / 6.0 && nx < 5.0 / 6.0) return KEY_X;
			if (nx >= 5.0 / 6.0) return KEY_Z;
			return 0;
		}

		private function onTouchBegin(e:TouchEvent):void
		{
			var id:String = String(e.touchPointID);
			var bounds:Rectangle = gameBounds();
			if (!bounds.contains(e.stageX, e.stageY)) return;

			// Menus/cinematics already understand arrows + X. Capture the gesture and
			// translate it on TOUCH_END so Android never depends on touch-to-mouse synthesis.
			if (!gameplayActive())
			{
				touchStarts[id] = {x:e.stageX, y:e.stageY, navigation:true};
				return;
			}

			var key:uint = controlKey(e.stageX, e.stageY);
			touchKeys[id] = key;
			if (key != 0)
				pressKey(key);
			else if (e.stageY < bounds.y + bounds.height * 0.75)
				touchStarts[id] = {x:e.stageX, y:e.stageY, navigation:false};
		}

		private function onTouchMove(e:TouchEvent):void
		{
			if (!gameplayActive()) return;
			var id:String = String(e.touchPointID);
			if (touchKeys[id] === undefined) return;
			var oldKey:uint = uint(touchKeys[id]);
			if (oldKey == 0) return;
			var newKey:uint = controlKey(e.stageX, e.stageY);
			if (newKey == oldKey) return;
			releaseKey(oldKey);
			touchKeys[id] = newKey;
			if (newKey != 0) pressKey(newKey);
		}

		private function onTouchEnd(e:TouchEvent):void
		{
			var id:String = String(e.touchPointID);
			if (touchKeys[id] !== undefined)
			{
				var key:uint = uint(touchKeys[id]);
				if (key != 0) releaseKey(key);
				delete touchKeys[id];
			}

			if (touchStarts[id] === undefined || root.stage == null)
				return;

			var start:Object = touchStarts[id];
			delete touchStarts[id];
			var dx:Number = e.stageX - Number(start.x);
			var dy:Number = e.stageY - Number(start.y);
			var ax:Number = Math.abs(dx);
			var ay:Number = Math.abs(dy);
			var bounds:Rectangle = gameBounds();

			if (Boolean(start.navigation))
			{
				var threshold:Number = Math.min(bounds.width, bounds.height) * 0.08;
				if (Math.max(ax, ay) < threshold)
					pulseKey(KEY_X);
				else if (ax >= ay)
					pulseKey(dx < 0 ? KEY_LEFT : KEY_RIGHT);
				else
					pulseKey(dy < 0 ? KEY_UP : KEY_DOWN);
				return;
			}

			// Gameplay upper-area gestures preserve the previously validated semantics.
			if (!gameplayActive()) return;
			if (ax > ay && ax >= bounds.width * 0.12)
				pulseKey(KEY_V);
			else if (ay > ax && ay >= bounds.height * 0.12)
				pulseKey(dy < 0 ? KEY_UP : KEY_DOWN);
		}

		private function pressKey(key:uint):void
		{
			var k:String = String(key);
			var count:int = keyCounts[k] === undefined ? 0 : int(keyCounts[k]);
			keyCounts[k] = count + 1;
			if (count == 0) dispatchKey(KeyboardEvent.KEY_DOWN, key);
		}

		private function releaseKey(key:uint):void
		{
			var k:String = String(key);
			if (keyCounts[k] === undefined) return;
			var count:int = int(keyCounts[k]) - 1;
			if (count <= 0)
			{
				delete keyCounts[k];
				dispatchKey(KeyboardEvent.KEY_UP, key);
			}
			else
				keyCounts[k] = count;
		}

		private function pulseKey(key:uint):void
		{
			dispatchKey(KeyboardEvent.KEY_DOWN, key);
			setTimeout(function():void { dispatchKey(KeyboardEvent.KEY_UP, key); }, 90);
		}

		private function dispatchKey(type:String, key:uint):void
		{
			if (root.stage != null)
				root.stage.dispatchEvent(new KeyboardEvent(type, true, false, 0, key));
		}

		private function releaseAll():void
		{
			for (var k:String in keyCounts)
				dispatchKey(KeyboardEvent.KEY_UP, uint(k));
			keyCounts = {};
			touchKeys = {};
			touchStarts = {};
		}

		private function drawOverlay(bounds:Rectangle):void
		{
			lastX = bounds.x;
			lastY = bounds.y;
			lastW = bounds.width;
			lastH = bounds.height;
			while (overlay.numChildren > 0) overlay.removeChildAt(0);
			overlay.graphics.clear();
			var zoneW:Number = bounds.width / 6.0;
			var zoneY:Number = bounds.y + bounds.height * 0.75;
			var zoneH:Number = bounds.height * 0.25;
			drawZone(bounds.x, zoneY, zoneW, zoneH, "LEFT");
			drawZone(bounds.x + zoneW, zoneY, zoneW, zoneH, "RIGHT");
			drawZone(bounds.x + zoneW * 4, zoneY, zoneW, zoneH, "ACTION");
			drawZone(bounds.x + zoneW * 5, zoneY, zoneW, zoneH, "JUMP");
		}

		private function drawZone(x:Number, y:Number, w:Number, h:Number, label:String):void
		{
			var inset:Number = Math.max(8, Math.min(w, h) * 0.08);
			overlay.graphics.lineStyle(3, 0xffffff, 0.45);
			overlay.graphics.beginFill(0x000000, 0.20);
			overlay.graphics.drawRoundRect(x + inset, y + inset, w - inset * 2, h - inset * 2, 24, 24);
			overlay.graphics.endFill();

			var tf:TextField = new TextField();
			tf.mouseEnabled = false;
			tf.selectable = false;
			tf.width = w;
			tf.height = 44;
			tf.x = x;
			tf.y = y + (h - 44) * 0.5;
			tf.defaultTextFormat = new TextFormat("_sans", Math.max(18, h * 0.10), 0xffffff, true, null, null, null, null, "center");
			tf.text = label;
			overlay.addChild(tf);
		}
	}
}
