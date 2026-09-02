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
	import org.flixel.FlxSound;

	/**
	 * Android/mobile compatibility layer. Native touch is translated into the
	 * exact legacy inputs consumed by the shipping game, with a native mobile
	 * pause surface where the historical input edge is not reliable on Android.
	 */
	public class MobileControls
	{
		private static const GAME_W:Number = 1920;
		private static const GAME_H:Number = 1080;
		private static const KEY_LEFT:uint = 37;
		private static const KEY_UP:uint = 38;
		private static const KEY_RIGHT:uint = 39;
		private static const KEY_DOWN:uint = 40;
		private static const KEY_B:uint = 66;
		private static const KEY_C:uint = 67;
		private static const KEY_V:uint = 86;
		private static const KEY_X:uint = 88;

		private var root:DisplayObjectContainer;
		private var overlay:Sprite = new Sprite();
		private var touchKeys:Object = {};
		private var touchStarts:Object = {};
		private var keyCounts:Object = {};
		private var lastX:Number = NaN;
		private var lastY:Number = NaN;
		private var lastW:Number = NaN;
		private var lastH:Number = NaN;
		private var lastMode:String = "";
		private var wasGameplay:Boolean = false;

		public function MobileControls(gameRoot:DisplayObjectContainer)
		{
			root = gameRoot;
			overlay.mouseEnabled = false;
			overlay.mouseChildren = false;
			if (root.stage != null) attach();
			else root.addEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
		}

		private function onAddedToStage(e:Event):void
		{
			root.removeEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
			attach();
		}

		private function attach():void
		{
			if (!Multitouch.supportsTouchEvents) return;
			Multitouch.inputMode = MultitouchInputMode.TOUCH_POINT;
			root.stage.addChild(overlay);
			root.stage.addEventListener(TouchEvent.TOUCH_BEGIN, onTouchBegin, false, 1000, true);
			root.stage.addEventListener(TouchEvent.TOUCH_MOVE, onTouchMove, false, 1000, true);
			root.stage.addEventListener(TouchEvent.TOUCH_END, onTouchEnd, false, 1000, true);
			root.addEventListener(Event.ENTER_FRAME, onFrame, false, 0, true);
		}

		private function suppressSynthesizedMouse(e:TouchEvent):void
		{
			if (e.cancelable) e.preventDefault();
		}

		private function gameplayActive():Boolean
		{
			return FlxG.state != null && FlxG.state is PlayState;
		}

		private function navigationMode():String
		{
			if (FlxG.state == null) return "none";
			if (FlxG.state is PCIntroState) return "intro";
			if (FlxG.state is PCCinematicState) return "cinematic";
			if (FlxG.state is PCHelpState || FlxG.state is PCCreditsState || FlxG.state is PrizeState) return "back";
			return "menu";
		}

		private function gameBounds():Rectangle
		{
			if (root.stage == null) return new Rectangle();
			var stageW:Number = root.stage.stageWidth;
			var stageH:Number = root.stage.stageHeight;
			if (stageW <= 0 || stageH <= 0) return new Rectangle();

			var fit:Number = Math.min(stageW / GAME_W, stageH / GAME_H);
			var viewportW:Number = GAME_W * fit;
			var viewportH:Number = GAME_H * fit;
			return new Rectangle((stageW - viewportW) * 0.5, (stageH - viewportH) * 0.5, viewportW, viewportH);
		}

		private function onFrame(e:Event):void
		{
			if (root.stage == null) return;
			var active:Boolean = gameplayActive();
			if (!active && wasGameplay) releaseAll();
			wasGameplay = active;
			var mode:String = active ? (FlxG.paused ? "gameplay-paused" : "gameplay") : navigationMode();
			overlay.visible = mode != "none";
			if (mode == "none") return;
			var bounds:Rectangle = gameBounds();
			if (lastX != bounds.x || lastY != bounds.y || lastW != bounds.width || lastH != bounds.height || lastMode != mode)
			{
				if (active) drawGameplayOverlay(bounds, mode);
				else drawNavigationOverlay(bounds, mode);
			}
			if (overlay.parent == root.stage) root.stage.setChildIndex(overlay, root.stage.numChildren - 1);
		}

		private function isPauseTarget(x:Number, y:Number):Boolean
		{
			var bounds:Rectangle = gameBounds();
			return bounds.contains(x, y) && x >= bounds.x + bounds.width * 5.0 / 6.0 && y <= bounds.y + bounds.height * 0.17;
		}

		private function controlKey(x:Number, y:Number):uint
		{
			var bounds:Rectangle = gameBounds();
			if (!bounds.contains(x, y)) return 0;
			var zoneY:Number = bounds.y + bounds.height * 0.75;
			if (y < zoneY) return 0;
			var nx:Number = (x - bounds.x) / bounds.width;
			if (nx < 1.0 / 6.0) return KEY_LEFT;
			if (nx < 2.0 / 6.0) return KEY_RIGHT;
			if (nx < 3.0 / 6.0) return KEY_V;
			if (nx < 4.0 / 6.0) return KEY_B;
			if (nx < 5.0 / 6.0) return KEY_X;
			return KEY_C;
		}

		private function onTouchBegin(e:TouchEvent):void
		{
			suppressSynthesizedMouse(e);
			var id:String = String(e.touchPointID);
			var bounds:Rectangle = gameBounds();
			if (!bounds.contains(e.stageX, e.stageY)) return;
			if (!gameplayActive())
			{
				touchStarts[id] = {x:e.stageX, y:e.stageY, navigation:true};
				return;
			}

			if (FlxG.paused)
			{
				touchKeys[id] = 0;
				if (isPauseTarget(e.stageX, e.stageY))
				{
					toggleMobilePause();
					return;
				}
				var state:PlayState = FlxG.state as PlayState;
				if (state != null && e.stageY >= bounds.y + bounds.height * 0.58 && e.stageY <= bounds.y + bounds.height * 0.80)
				{
					FlxG.paused = false;
					if (e.stageX < bounds.x + bounds.width * 0.5) state.resetLevel();
					else state.goToMenu(false);
				}
				return;
			}

			if (isPauseTarget(e.stageX, e.stageY))
			{
				touchKeys[id] = 0;
				toggleMobilePause();
				return;
			}
			var key:uint = controlKey(e.stageX, e.stageY);
			touchKeys[id] = key;
			if (key != 0) pressKey(key);
		}

		private function onTouchMove(e:TouchEvent):void
		{
			suppressSynthesizedMouse(e);
			if (!gameplayActive() || FlxG.paused) return;
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
			suppressSynthesizedMouse(e);
			var id:String = String(e.touchPointID);
			if (touchKeys[id] !== undefined)
			{
				var key:uint = uint(touchKeys[id]);
				if (key != 0) releaseKey(key);
				delete touchKeys[id];
			}
			if (touchStarts[id] === undefined || root.stage == null) return;
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
				{
					if (FlxG.state is PCIntroState)
					{
						pulseKey(KEY_X);
						setTimeout(function():void { if (FlxG.state is PCIntroState) pulseKey(KEY_X); }, 180);
					}
					else if (FlxG.state is PCCinematicState && Number(start.x) >= bounds.x + bounds.width * 0.72 && Number(start.y) <= bounds.y + bounds.height * 0.18)
						skipCinematic();
					else pulseKey(KEY_X);
				}
				else if (ax >= ay) pulseKey(dx < 0 ? KEY_LEFT : KEY_RIGHT);
				else pulseKey(dy < 0 ? KEY_UP : KEY_DOWN);
			}
		}

		private function toggleMobilePause():void
		{
			if (!(FlxG.state is PlayState)) return;
			FlxG.paused = !FlxG.paused;
			if (FlxG.music != null)
			{
				if (FlxG.paused) FlxG.music.pause();
				else FlxG.music.play();
			}
		}

		private function skipCinematic():void
		{
			var cinematic:PCCinematicState = FlxG.state as PCCinematicState;
			if (cinematic == null) return;
			stopTransientSounds();
			FlxG.fade(0xff000000, 1, cinematic.fadeComplete);
		}

		private function stopTransientSounds():void
		{
			if (FlxG.sounds == null) return;
			var i:uint = 0;
			var sound:FlxSound;
			var l:uint = FlxG.sounds.length;
			while (i < l)
			{
				sound = FlxG.sounds.members[i++] as FlxSound;
				if (sound != null && sound.exists && sound.active) sound.stop();
			}
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
			else keyCounts[k] = count;
		}

		private function pulseKey(key:uint):void
		{
			dispatchKey(KeyboardEvent.KEY_DOWN, key);
			setTimeout(function():void { dispatchKey(KeyboardEvent.KEY_UP, key); }, 90);
		}

		private function dispatchKey(type:String, key:uint):void
		{
			if (root.stage != null) root.stage.dispatchEvent(new KeyboardEvent(type, true, false, 0, key));
		}

		private function releaseAll():void
		{
			for (var k:String in keyCounts) dispatchKey(KeyboardEvent.KEY_UP, uint(k));
			keyCounts = {};
			touchKeys = {};
			touchStarts = {};
		}

		private function clearOverlay(bounds:Rectangle, mode:String):void
		{
			lastX = bounds.x; lastY = bounds.y; lastW = bounds.width; lastH = bounds.height; lastMode = mode;
			while (overlay.numChildren > 0) overlay.removeChildAt(0);
			overlay.graphics.clear();
		}

		private function drawGameplayOverlay(bounds:Rectangle, mode:String):void
		{
			clearOverlay(bounds, mode);
			var zoneW:Number = bounds.width / 6.0;
			if (mode == "gameplay-paused")
			{
				overlay.graphics.lineStyle(0, 0, 0);
				overlay.graphics.beginFill(0x000000, 0.56); overlay.graphics.drawRect(bounds.x, bounds.y, bounds.width, bounds.height); overlay.graphics.endFill();
				drawHint(bounds.x + bounds.width * 0.20, bounds.y + bounds.height * 0.20, bounds.width * 0.60, bounds.height * 0.13, "PAUSED", 0x000000, 0.72, 0xffffff);
				drawHint(bounds.x + bounds.width * 0.12, bounds.y + bounds.height * 0.58, bounds.width * 0.34, bounds.height * 0.22, "RESTART LEVEL", 0x7725a1, 0.95, 0xffffff);
				drawHint(bounds.x + bounds.width * 0.54, bounds.y + bounds.height * 0.58, bounds.width * 0.34, bounds.height * 0.22, "TO MENU", 0x7725a1, 0.95, 0xffffff);
				drawZone(bounds.x + zoneW * 5, bounds.y, zoneW, bounds.height * 0.17, "RESUME");
				return;
			}
			var zoneY:Number = bounds.y + bounds.height * 0.75;
			var zoneH:Number = bounds.height * 0.25;
			drawZone(bounds.x, zoneY, zoneW, zoneH, "LEFT");
			drawZone(bounds.x + zoneW, zoneY, zoneW, zoneH, "RIGHT");
			drawZone(bounds.x + zoneW * 2, zoneY, zoneW, zoneH, "SWITCH");
			drawZone(bounds.x + zoneW * 3, zoneY, zoneW, zoneH, "PIGGY");
			drawZone(bounds.x + zoneW * 4, zoneY, zoneW, zoneH, "ACTION");
			drawZone(bounds.x + zoneW * 5, zoneY, zoneW, zoneH, "JUMP");
			drawZone(bounds.x + zoneW * 5, bounds.y, zoneW, bounds.height * 0.17, "PAUSE");
		}

		private function drawNavigationOverlay(bounds:Rectangle, mode:String):void
		{
			clearOverlay(bounds, mode);
			if (mode == "intro")
				drawHint(bounds.x, bounds.y + bounds.height * 0.80, bounds.width, bounds.height * 0.14, "TAP TO START", 0xd3bdb2, 1.0, 0x7725a1);
			else if (mode == "cinematic")
			{
				drawHint(bounds.x + bounds.width * 0.72, bounds.y + bounds.height * 0.035, bounds.width * 0.25, bounds.height * 0.08, "TAP TO SKIP", 0x000000, 1.0, 0xffffff);
				drawHint(bounds.x + bounds.width * 0.68, bounds.y + bounds.height * 0.88, bounds.width * 0.29, bounds.height * 0.08, "TAP TO CONTINUE", 0x000000, 1.0, 0xffffff);
			}
			else
			{
				var label:String = mode == "back" ? "TAP TO GO BACK" : "SWIPE TO MOVE  -  TAP TO SELECT";
				drawHint(bounds.x + bounds.width * 0.28, bounds.y + bounds.height * 0.925, bounds.width * 0.44, bounds.height * 0.055, label, 0x000000, 0.62, 0xffffff);
			}
		}

		private function drawHint(x:Number, y:Number, w:Number, h:Number, label:String, bg:uint, alpha:Number, fg:uint):void
		{
			overlay.graphics.lineStyle(0, 0, 0);
			overlay.graphics.beginFill(bg, alpha); overlay.graphics.drawRect(x, y, w, h); overlay.graphics.endFill();
			var tf:TextField = new TextField();
			tf.mouseEnabled = false; tf.selectable = false; tf.width = w; tf.height = h; tf.x = x; tf.y = y + Math.max(0, (h - 34) * 0.5);
			tf.defaultTextFormat = new TextFormat("_sans", Math.max(14, Math.min(22, h * 0.28)), fg, true, null, null, null, null, "center");
			tf.text = label; overlay.addChild(tf);
		}

		private function drawZone(x:Number, y:Number, w:Number, h:Number, label:String):void
		{
			var inset:Number = Math.max(6, Math.min(w, h) * 0.08);
			overlay.graphics.lineStyle(3, 0xffffff, 0.45); overlay.graphics.beginFill(0x000000, 0.20);
			overlay.graphics.drawRoundRect(x + inset, y + inset, w - inset * 2, h - inset * 2, 20, 20); overlay.graphics.endFill();
			var tf:TextField = new TextField();
			tf.mouseEnabled = false; tf.selectable = false; tf.width = w; tf.height = 40; tf.x = x; tf.y = y + (h - 40) * 0.5;
			tf.defaultTextFormat = new TextFormat("_sans", Math.max(14, Math.min(24, h * 0.10)), 0xffffff, true, null, null, null, null, "center");
			tf.text = label; overlay.addChild(tf);
		}
	}
}
