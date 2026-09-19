// Modified for the independent Super Limeade Factory Android restoration by Ramy Baheeg, 2026.
package
{
	import flash.display.DisplayObjectContainer;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.events.TouchEvent;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.text.TextField;
	import flash.text.TextFormat;
	import flash.ui.Multitouch;
	import flash.ui.MultitouchInputMode;
	import flash.utils.setTimeout;
	import org.flixel.FlxG;
	import org.flixel.FlxSave;
	import org.flixel.FlxSound;

	/**
	 * Android/mobile compatibility layer. Native touch is translated into the
	 * exact legacy inputs consumed by the shipping game, with a native mobile
	 * pause surface where the historical input edge is not reliable on Android.
	 *
	 * On tall/foldable displays the gameplay controls automatically dock into
	 * otherwise-unused space below the 16:9 game canvas. If that space is not
	 * large enough they fall back to the historical in-game overlay position.
	 * The user can fine-tune vertical placement with the CONTROL HEIGHT slider
	 * on the mobile pause surface; the preference is persisted in the SLF save.
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
		private static const CONTROL_SAVE_KEY:String = "mobileControlVerticalPosition";

		private var root:DisplayObjectContainer;
		private var overlay:Sprite = new Sprite();
		private var touchKeys:Object = {};
		private var touchStarts:Object = {};
		private var sliderTouches:Object = {};
		private var keyCounts:Object = {};
		private var lastX:Number = NaN;
		private var lastY:Number = NaN;
		private var lastW:Number = NaN;
		private var lastH:Number = NaN;
		private var lastControlX:Number = NaN;
		private var lastControlY:Number = NaN;
		private var lastControlW:Number = NaN;
		private var lastControlH:Number = NaN;
		private var lastControlPosition:Number = NaN;
		private var lastMode:String = "";
		private var wasGameplay:Boolean = false;
		private var controlPosition:Number = 1.0;

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
			loadControlPreference();
			Multitouch.inputMode = MultitouchInputMode.TOUCH_POINT;
			root.stage.addChild(overlay);
			root.stage.addEventListener(TouchEvent.TOUCH_BEGIN, onTouchBegin, false, 1000, true);
			root.stage.addEventListener(TouchEvent.TOUCH_MOVE, onTouchMove, false, 1000, true);
			root.stage.addEventListener(TouchEvent.TOUCH_END, onTouchEnd, false, 1000, true);
			root.stage.addEventListener(Event.DEACTIVATE, onDeactivate, false, 1000, true);
			root.addEventListener(Event.ENTER_FRAME, onFrame, false, 0, true);
		}

		private function loadControlPreference():void
		{
			var save:FlxSave = new FlxSave();
			if (!save.bind("SLF")) return;
			var raw:* = save.data[CONTROL_SAVE_KEY];
			if (raw !== undefined && raw !== null && !isNaN(Number(raw)))
				controlPosition = clamp01(Number(raw));
			save.destroy();
		}

		private function saveControlPreference():void
		{
			var save:FlxSave = new FlxSave();
			if (!save.bind("SLF")) return;
			save.data[CONTROL_SAVE_KEY] = controlPosition;
			save.close();
		}

		private function clamp01(value:Number):Number
		{
			if (!isFinite(value)) return 1.0;
			if (value < 0) return 0;
			if (value > 1) return 1;
			return value;
		}

		private function onDeactivate(e:Event):void
		{
			releaseAll();
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
			if (FlxG.state is PCHelpState || FlxG.state is PCPrivacyState ||
				FlxG.state is PCCreditsState || FlxG.state is PrizeState) return "back";
			return "menu";
		}

		private function isHelpPrivacyTarget(stageX:Number, stageY:Number):Boolean
		{
			var help:PCHelpState = FlxG.state as PCHelpState;
			if (help == null || help.privacyBtn == null) return false;
			var bounds:Rectangle = gameBounds();
			if (!bounds.contains(stageX, stageY) || bounds.width <= 0 || bounds.height <= 0)
				return false;

			var gameX:Number = (stageX - bounds.x) / bounds.width * FlxG.width;
			var gameY:Number = (stageY - bounds.y) / bounds.height * FlxG.height;
			return gameX >= help.privacyBtn.x &&
				gameX <= help.privacyBtn.x + help.privacyBtn.width &&
				gameY >= help.privacyBtn.y &&
				gameY <= help.privacyBtn.y + help.privacyBtn.height;
		}

		private function gameBounds():Rectangle
		{
			if (root.stage == null) return new Rectangle();
			var origin:Point = root.localToGlobal(new Point(0, 0));
			var far:Point = root.localToGlobal(new Point(GAME_W, GAME_H));
			var left:Number = Math.min(origin.x, far.x);
			var top:Number = Math.min(origin.y, far.y);
			var width:Number = Math.abs(far.x - origin.x);
			var height:Number = Math.abs(far.y - origin.y);
			if (width <= 0 || height <= 0) return new Rectangle();
			return new Rectangle(left, top, width, height);
		}

		private function gameplayControlBounds(bounds:Rectangle):Rectangle
		{
			if (root.stage == null || bounds.width <= 0 || bounds.height <= 0)
				return new Rectangle();

			var zoneH:Number = bounds.height * 0.25;
			var stageH:Number = root.stage.stageHeight;
			if (!isFinite(stageH) || stageH <= 0) stageH = bounds.bottom;
			var margin:Number = Math.max(6, Math.min(24, bounds.height * 0.015));
			var freeBelow:Number = stageH - bounds.bottom;
			var minY:Number;
			var maxY:Number;

			// Auto-dock only when the full historical control row fits below the
			// game without touching the gameplay canvas. Otherwise preserve the
			// established overlay behavior.
			if (freeBelow >= zoneH + margin * 2)
			{
				minY = bounds.bottom + margin;
				maxY = stageH - zoneH - margin;
				if (maxY < minY) maxY = minY;
			}
			else
			{
				minY = bounds.y + bounds.height * 0.60;
				maxY = bounds.bottom - zoneH;
				if (minY > maxY) minY = maxY;
			}

			var y:Number = minY + (maxY - minY) * controlPosition;
			return new Rectangle(bounds.x, y, bounds.width, zoneH);
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
			var controls:Rectangle = active && !FlxG.paused ? gameplayControlBounds(bounds) : new Rectangle();
			var changed:Boolean = lastX != bounds.x || lastY != bounds.y || lastW != bounds.width || lastH != bounds.height || lastMode != mode;
			if (active && !FlxG.paused)
				changed = changed || lastControlX != controls.x || lastControlY != controls.y || lastControlW != controls.width || lastControlH != controls.height || lastControlPosition != controlPosition;
			else if (mode == "gameplay-paused")
				changed = changed || lastControlPosition != controlPosition;
			if (changed)
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

		private function isCinematicSkipTarget(x:Number, y:Number):Boolean
		{
			var bounds:Rectangle = gameBounds();
			return bounds.contains(x, y) && x >= bounds.x + bounds.width * 0.72 && y <= bounds.y + bounds.height * 0.18;
		}

		private function controlKey(x:Number, y:Number):uint
		{
			var bounds:Rectangle = gameplayControlBounds(gameBounds());
			if (!bounds.contains(x, y) || bounds.width <= 0) return 0;
			var nx:Number = (x - bounds.x) / bounds.width;
			if (nx < 1.0 / 6.0) return KEY_LEFT;
			if (nx < 2.0 / 6.0) return KEY_RIGHT;
			if (nx < 3.0 / 6.0) return KEY_V;
			if (nx < 4.0 / 6.0) return KEY_B;
			if (nx < 5.0 / 6.0) return KEY_X;
			return KEY_C;
		}

		private function controlSliderBounds(bounds:Rectangle):Rectangle
		{
			return new Rectangle(bounds.x + bounds.width * 0.18,
				bounds.y + bounds.height * 0.855,
				bounds.width * 0.64,
				bounds.height * 0.075);
		}

		private function isControlSliderTarget(x:Number, y:Number):Boolean
		{
			return controlSliderBounds(gameBounds()).contains(x, y);
		}

		private function setControlPositionFromStageX(x:Number):void
		{
			var slider:Rectangle = controlSliderBounds(gameBounds());
			if (slider.width <= 0) return;
			controlPosition = clamp01((x - slider.x) / slider.width);
			lastControlPosition = NaN;
		}

		private function onTouchBegin(e:TouchEvent):void
		{
			suppressSynthesizedMouse(e);
			var id:String = String(e.touchPointID);
			var bounds:Rectangle = gameBounds();

			if (!gameplayActive())
			{
				if (!bounds.contains(e.stageX, e.stageY)) return;
				if (FlxG.state is PCCinematicState && isCinematicSkipTarget(e.stageX, e.stageY))
				{
					skipCinematic();
					return;
				}
				touchStarts[id] = {x:e.stageX, y:e.stageY, navigation:true};
				return;
			}

			if (FlxG.paused)
			{
				if (!bounds.contains(e.stageX, e.stageY)) return;
				touchKeys[id] = 0;
				if (isControlSliderTarget(e.stageX, e.stageY))
				{
					sliderTouches[id] = true;
					setControlPositionFromStageX(e.stageX);
					return;
				}
				if (isPauseTarget(e.stageX, e.stageY))
				{
					toggleMobilePause();
					return;
				}
				var state:PlayState = FlxG.state as PlayState;
				if (state != null && e.stageY >= bounds.y + bounds.height * 0.58 && e.stageY <= bounds.y + bounds.height * 0.80)
				{
					FlxG.paused = false;
					if (e.stageX < bounds.x + bounds.width * 0.5)
					{
						FlxG.resumeSounds();
						state.resetLevel();
					}
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
			if (key == 0) return;
			touchKeys[id] = key;
			pressKey(key);
		}

		private function onTouchMove(e:TouchEvent):void
		{
			suppressSynthesizedMouse(e);
			var id:String = String(e.touchPointID);
			if (sliderTouches[id] !== undefined)
			{
				setControlPositionFromStageX(e.stageX);
				return;
			}
			if (!gameplayActive() || FlxG.paused) return;
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
			if (sliderTouches[id] !== undefined)
			{
				setControlPositionFromStageX(e.stageX);
				delete sliderTouches[id];
				delete touchKeys[id];
				saveControlPreference();
				return;
			}
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
					if (FlxG.state is PCHelpState && isHelpPrivacyTarget(e.stageX, e.stageY))
					{
						pulseKey(KEY_DOWN);
					}
					else if (FlxG.state is PCIntroState)
					{
						pulseKey(KEY_X);
						setTimeout(function():void { if (FlxG.state is PCIntroState) pulseKey(KEY_X); }, 180);
					}
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
			if (FlxG.paused) FlxG.pauseSounds();
			else FlxG.resumeSounds();
		}

		private function skipCinematic():void
		{
			var cinematic:PCCinematicState = FlxG.state as PCCinematicState;
			if (cinematic == null) return;
			stopTransientSounds();
			FlxG.fade(0xff000000, 0.35, cinematic.fadeComplete, true);
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
			sliderTouches = {};
		}

		private function clearOverlay(bounds:Rectangle, mode:String):void
		{
			lastX = bounds.x;
			lastY = bounds.y;
			lastW = bounds.width;
			lastH = bounds.height;
			lastMode = mode;
			lastControlPosition = controlPosition;
			while (overlay.numChildren > 0) overlay.removeChildAt(0);
			overlay.graphics.clear();
		}

		private function drawGameplayOverlay(bounds:Rectangle, mode:String):void
		{
			clearOverlay(bounds, mode);
			var zoneW:Number = bounds.width / 6.0;
			if (mode == "gameplay-paused")
			{
				lastControlX = lastControlY = lastControlW = lastControlH = NaN;
				overlay.graphics.lineStyle(0, 0, 0);
				overlay.graphics.beginFill(0x000000, 0.56);
				overlay.graphics.drawRect(bounds.x, bounds.y, bounds.width, bounds.height);
				overlay.graphics.endFill();
				drawHint(bounds.x + bounds.width * 0.20, bounds.y + bounds.height * 0.20, bounds.width * 0.60, bounds.height * 0.13, "PAUSED", 0x000000, 0.72, 0xffffff);
				drawHint(bounds.x + bounds.width * 0.12, bounds.y + bounds.height * 0.58, bounds.width * 0.34, bounds.height * 0.22, "RESTART LEVEL", 0x7725a1, 0.95, 0xffffff);
				drawHint(bounds.x + bounds.width * 0.54, bounds.y + bounds.height * 0.58, bounds.width * 0.34, bounds.height * 0.22, "TO MENU", 0x7725a1, 0.95, 0xffffff);
				drawZone(bounds.x + zoneW * 5, bounds.y, zoneW, bounds.height * 0.17, "RESUME");
				drawControlSlider(bounds);
				return;
			}

			var controls:Rectangle = gameplayControlBounds(bounds);
			lastControlX = controls.x;
			lastControlY = controls.y;
			lastControlW = controls.width;
			lastControlH = controls.height;
			zoneW = controls.width / 6.0;
			drawZone(controls.x, controls.y, zoneW, controls.height, "LEFT");
			drawZone(controls.x + zoneW, controls.y, zoneW, controls.height, "RIGHT");
			drawZone(controls.x + zoneW * 2, controls.y, zoneW, controls.height, "SWITCH");
			drawZone(controls.x + zoneW * 3, controls.y, zoneW, controls.height, "PIGGY");
			drawZone(controls.x + zoneW * 4, controls.y, zoneW, controls.height, "ACTION");
			drawZone(controls.x + zoneW * 5, controls.y, zoneW, controls.height, "JUMP");
			drawZone(bounds.x + bounds.width * 5.0 / 6.0, bounds.y, bounds.width / 6.0, bounds.height * 0.17, "PAUSE");
		}

		private function drawControlSlider(bounds:Rectangle):void
		{
			var slider:Rectangle = controlSliderBounds(bounds);
			var labelH:Number = bounds.height * 0.04;
			drawHint(slider.x, slider.y - labelH, slider.width, labelH, "CONTROL HEIGHT", 0x000000, 0.30, 0xffffff);
			var cy:Number = slider.y + slider.height * 0.5;
			overlay.graphics.lineStyle(Math.max(4, slider.height * 0.14), 0xffffff, 0.70);
			overlay.graphics.moveTo(slider.x, cy);
			overlay.graphics.lineTo(slider.right, cy);
			overlay.graphics.lineStyle(3, 0xffffff, 0.95);
			overlay.graphics.beginFill(0x7725a1, 1.0);
			overlay.graphics.drawCircle(slider.x + slider.width * controlPosition, cy, Math.max(10, slider.height * 0.28));
			overlay.graphics.endFill();
		}

		private function drawNavigationOverlay(bounds:Rectangle, mode:String):void
		{
			clearOverlay(bounds, mode);
			lastControlX = lastControlY = lastControlW = lastControlH = NaN;
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
			overlay.graphics.beginFill(bg, alpha);
			overlay.graphics.drawRect(x, y, w, h);
			overlay.graphics.endFill();
			var tf:TextField = new TextField();
			tf.mouseEnabled = false;
			tf.selectable = false;
			tf.width = w;
			tf.height = h;
			tf.x = x;
			tf.y = y + Math.max(0, (h - 34) * 0.5);
			tf.defaultTextFormat = new TextFormat("_sans", Math.max(14, Math.min(22, h * 0.28)), fg, true, null, null, null, null, "center");
			tf.text = label;
			overlay.addChild(tf);
		}

		private function drawZone(x:Number, y:Number, w:Number, h:Number, label:String):void
		{
			var inset:Number = Math.max(6, Math.min(w, h) * 0.08);
			overlay.graphics.lineStyle(3, 0xffffff, 0.45);
			overlay.graphics.beginFill(0x000000, 0.20);
			overlay.graphics.drawRoundRect(x + inset, y + inset, w - inset * 2, h - inset * 2, 20, 20);
			overlay.graphics.endFill();
			var tf:TextField = new TextField();
			tf.mouseEnabled = false;
			tf.selectable = false;
			tf.width = w;
			tf.height = 40;
			tf.x = x;
			tf.y = y + (h - 40) * 0.5;
			tf.defaultTextFormat = new TextFormat("_sans", Math.max(14, Math.min(24, h * 0.10)), 0xffffff, true, null, null, null, null, "center");
			tf.text = label;
			overlay.addChild(tf);
		}
	}
}
