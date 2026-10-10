package
{
    import flash.geom.Rectangle;
    import org.flixel.*;

    /**
     * QA-only observation surface for the natural campaign learner.
     *
     * This class is intentionally read-only with respect to gameplay. It
     * encodes public PCPlayState/Registry state into a 13x8 two-color pixel
     * grid so CI can observe ordinary play without save edits, teleportation,
     * debug completion hooks, or network instrumentation.
     */
    public class QANaturalTelemetry extends FlxSprite
    {
        private static const COLS:int = 13;
        private static const ROWS:int = 8;
        private static const CELL:int = 4;
        private static const ONE:uint = 0xffff00ff;
        private static const ZERO:uint = 0xff00ffff;

        public function QANaturalTelemetry()
        {
            super(0, 0);
            makeGraphic(COLS * CELL, ROWS * CELL, ZERO, true);
            scrollFactor.x = 0;
            scrollFactor.y = 0;
            solid = false;
            immovable = true;
        }

        private function clamp12(value:Number):int
        {
            var n:int = int(value);
            if (n < 0) return 0;
            if (n > 4095) return 4095;
            return n;
        }

        private function pushBits(out:Array, value:int, width:int):void
        {
            var shift:int;
            for (shift = width - 1; shift >= 0; shift--)
                out.push((value >> shift) & 1);
        }

        private function firstMovableCrate(state:PCPlayState):FlxSprite
        {
            var i:int;
            var candidate:FlxSprite;
            if (state.crates != null)
            {
                for (i = 0; i < state.crates.length; i++)
                {
                    candidate = state.crates.members[i] as FlxSprite;
                    if (candidate != null && candidate.exists) return candidate;
                }
            }
            if (state.largeCrates != null)
            {
                for (i = 0; i < state.largeCrates.length; i++)
                {
                    candidate = state.largeCrates.members[i] as FlxSprite;
                    if (candidate != null && candidate.exists) return candidate;
                }
            }
            return null;
        }

        public function refresh(state:PCPlayState, finished:Boolean):void
        {
            if (state == null || state.player1 == null || state.player2 == null) return;

            var out:Array = [];
            var crate:FlxSprite = firstMovableCrate(state);

            pushBits(out, 0xA5, 8);
            pushBits(out, 1, 4);
            pushBits(out, Registry.levelType, 2);
            pushBits(out, Registry.levelNumber, 4);
            out.push(Registry.hardCore ? 1 : 0);
            out.push(state.player2._currentlyControlled ? 1 : 0);
            out.push(finished ? 1 : 0);
            pushBits(out, clamp12(state.player1.x), 12);
            pushBits(out, clamp12(state.player1.y), 12);
            pushBits(out, clamp12(state.player2.x), 12);
            pushBits(out, clamp12(state.player2.y), 12);
            out.push(state.player1.dead ? 1 : 0);
            out.push(state.player2.dead ? 1 : 0);
            out.push((state.player1._isPiggyBacking || state.player2._isPiggyBacking) ? 1 : 0);
            out.push(crate != null ? 1 : 0);
            pushBits(out, crate == null ? 0 : clamp12(crate.x), 12);
            pushBits(out, crate == null ? 0 : clamp12(crate.y), 12);
            pushBits(out, 0, 7);

            if (out.length != 104) throw new Error("QA telemetry protocol length mismatch: " + out.length);

            pixels.lock();
            var i:int;
            var col:int;
            var row:int;
            for (i = 0; i < out.length; i++)
            {
                col = i % COLS;
                row = int(i / COLS);
                pixels.fillRect(new Rectangle(col * CELL, row * CELL, CELL, CELL), out[i] == 1 ? ONE : ZERO);
            }
            pixels.unlock();
            dirty = true;
        }
    }
}
