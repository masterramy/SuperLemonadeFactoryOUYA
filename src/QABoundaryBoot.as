package
{
    import org.flixel.*;

    /** QA-only launcher for actual shipping world/OLD SCHOOL boundary transitions. */
    public class QABoundaryBoot extends FlxState
    {
        override public function create():void
        {
            FlxG.bgColor = 0xff202020;
            var t:FlxText = new FlxText(20, 90, 600,
                "QA BOUNDARY BOOT\n" +
                "1-3 normal W1/W2/W3 L12 -> cinematics\n" +
                "4-9 OLD SCHOOL W1->W2->W3->HC W1->W2->W3->Prize");
            t.setFormat(null, 12, 0xffffff, "center");
            add(t);
        }

        override public function update():void
        {
            super.update();
            var n:int = 0;
            if (FlxG.keys.justPressed("ONE")) n = 1;
            else if (FlxG.keys.justPressed("TWO")) n = 2;
            else if (FlxG.keys.justPressed("THREE")) n = 3;
            else if (FlxG.keys.justPressed("FOUR")) n = 4;
            else if (FlxG.keys.justPressed("FIVE")) n = 5;
            else if (FlxG.keys.justPressed("SIX")) n = 6;
            else if (FlxG.keys.justPressed("SEVEN")) n = 7;
            else if (FlxG.keys.justPressed("EIGHT")) n = 8;
            else if (FlxG.keys.justPressed("NINE")) n = 9;
            if (n > 0)
            {
                QABoundaryPlayState.qaCase = n;
                FlxG.switchState(new QABoundaryPlayState());
            }
        }
    }
}
