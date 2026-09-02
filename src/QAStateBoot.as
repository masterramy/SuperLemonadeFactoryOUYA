package
{
    import org.flixel.*;

    /** QA-only direct launcher for reachable non-gameplay shipping states. */
    public class QAStateBoot extends FlxState
    {
        override public function create():void
        {
            FlxG.bgColor = 0xff202020;
            var t:FlxText = new FlxText(20, 120, 600,
                "QA STATE BOOT\nM menu  O options  H help  C credits\nL level select  1/2/3 end cinematics  P old-school complete");
            t.setFormat(null, 12, 0xffffff, "center");
            add(t);
        }

        override public function update():void
        {
            super.update();
            if (FlxG.keys.justPressed("M")) FlxG.switchState(new PCMenuState());
            else if (FlxG.keys.justPressed("O")) FlxG.switchState(new PCOptionsState());
            else if (FlxG.keys.justPressed("H")) FlxG.switchState(new PCHelpState());
            else if (FlxG.keys.justPressed("C")) FlxG.switchState(new PCCreditsState());
            else if (FlxG.keys.justPressed("L")) FlxG.switchState(new PCLevelSelectState());
            else if (FlxG.keys.justPressed("ONE")) { Registry.level = XML(new Registry.LevelEndScene1); Registry.levelType=1; Registry.levelNumber=12; FlxG.switchState(new PCCinematicState()); }
            else if (FlxG.keys.justPressed("TWO")) { Registry.level = XML(new Registry.LevelEndScene2); Registry.levelType=2; Registry.levelNumber=12; FlxG.switchState(new PCCinematicState()); }
            else if (FlxG.keys.justPressed("THREE")) { Registry.level = XML(new Registry.LevelEndScene3); Registry.levelType=3; Registry.levelNumber=12; FlxG.switchState(new PCCinematicState()); }
            else if (FlxG.keys.justPressed("P")) FlxG.switchState(new PrizeState());
        }
    }
}
