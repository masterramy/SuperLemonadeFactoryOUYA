package
{
	import flash.display.DisplayObjectContainer;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.events.TouchEvent;
	import flash.text.TextField;
	import flash.text.TextFormat;
	import flash.ui.Multitouch;
	import flash.ui.MultitouchInputMode;
	import flash.utils.setTimeout;
	import org.flixel.FlxG;

	/**
	 * Android/mobile compatibility layer derived from the title's original iOS
	 * control semantics. It translates native multitouch into the legacy keyboard
	 * inputs already consumed by the game, leaving gameplay logic untouched.
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
		private var lastW:Number = -1;
		private var lastH:Number = -1;
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
			root.addChild(overlay);
			root.stage.addEventListener(TouchEvent.TOUCH_BEGIN, onTouchBegin, false, 0, true);
			root.stage.addEventListener(TouchEvent.TOUCH_MOVE, onTouchMove, false, 0, true);
			root.stage.addEventListener(TouchEvent.TOUCH_END, onTouchEnd, false, 0, true);
			root.addEventListener(Event.ENTER_FRAME, onFrame, false, 0, true);
		}

		private function gameplayActive():Boolean
		{
			return FlxG.state != null && FlxG.state is PlayState;
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

			if (lastW != root.stage.stageWidth || lastH != root.stage.stageHeight)
				drawOverlay(root.stage.stageWidth, root.stage.stageHeight);
			if (root.contains(overlay))
				root.setChildIndex(overlay, root.numChildren - 1);
		}

		private function controlKey(x:Number, y:Number):uint
		{
			if (root.stage == null || y < root.stage.stageHeight * 0.75)
				return 0;
			var nx:Number = x / root.stage.stageWidth;
			if (nx < 1.0 / 6.0) return KEY_LEFT;
			if (nx < 2.0 / 6.0) return KEY_RIGHT;
			if (nx >= 4.0 / 6.0 && nx < 5.0 / 6.0) return KEY_X;
			if (nx >= 5.0 / 6.0) return KEY_Z;
			return 0;
		}

		private function onTouchBegin(e:TouchEvent):void
		{
			if (!gameplayActive()) return;
			var id:String = String(e.touchPointID);
			var key:uint = controlKey(e.stageX, e.stageY);
			touchKeys[id] = key;
			if (key != 0)
				pressKey(key);
			else if (root.stage != null && e.stageY < root.stage.stageHeight * 0.75)
				touchStarts[id] = {x:e.stageX, y:e.stageY};
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

			if (!gameplayActive() || touchStarts[id] === undefined || root.stage == null)
			{
				delete touchStarts[id];
				return;
			}

			var start:Object = touchStarts[id];
			delete touchStarts[id];
			var dx:Number = e.stageX - Number(start.x);
			var dy:Number = e.stageY - Number(start.y);
			var ax:Number = Math.abs(dx);
			var ay:Number = Math.abs(dy);
			if (ax > ay && ax >= root.stage.stageWidth * 0.12)
				pulseKey(KEY_V);
			else if (ay > ax && ay >= root.stage.stageHeight * 0.12)
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

		private function drawOverlay(w:Number, h:Number):void
		{
			lastW = w;
			lastH = h;
			while (overlay.numChildren > 0) overlay.removeChildAt(0);
			overlay.graphics.clear();
			var zoneW:Number = w / 6.0;
			var zoneY:Number = h * 0.75;
			var zoneH:Number = h * 0.25;
			drawZone(0, zoneY, zoneW, zoneH, "LEFT");
			drawZone(zoneW, zoneY, zoneW, zoneH, "RIGHT");
			drawZone(zoneW * 4, zoneY, zoneW, zoneH, "ACTION");
			drawZone(zoneW * 5, zoneY, zoneW, zoneH, "JUMP");
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
