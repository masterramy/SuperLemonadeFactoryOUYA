package
{
    import org.flixel.*;

    /** QA-only direct launcher for reachable non-gameplay shipping states. */
    public class QAStateBoot extends FlxState
    {
        override public function create():void
        {
            // Match shipping PCIntroState presentation setup and make direct Level Select valid.
            FlxG.stage.align = "";
            ensureSaveDefaults();
            FlxG.bgColor = 0xff202020;
            var t:FlxText = new FlxText(20, 120, 600,
                "QA STATE BOOT\nQ menu  O options  H help  C credits\nL level select  A/F/D end cinematics  P old-school complete");
            t.setFormat(null, 12, 0xffffff, "center");
            add(t);
        }

        override public function update():void
        {
            super.update();
            if (FlxG.keys.justPressed("Q")) FlxG.switchState(new PCMenuState());
            else if (FlxG.keys.justPressed("O")) FlxG.switchState(new PCOptionsState());
            else if (FlxG.keys.justPressed("H")) FlxG.switchState(new PCHelpState());
            else if (FlxG.keys.justPressed("C")) FlxG.switchState(new PCCreditsState());
            else if (FlxG.keys.justPressed("L")) FlxG.switchState(new PCLevelSelectState());
            else if (FlxG.keys.justPressed("A")) { Registry.level = XML(new Registry.LevelEndScene1); Registry.levelType=1; Registry.levelNumber=12; FlxG.switchState(new PCCinematicState()); }
            else if (FlxG.keys.justPressed("F")) { Registry.level = XML(new Registry.LevelEndScene2); Registry.levelType=2; Registry.levelNumber=12; FlxG.switchState(new PCCinematicState()); }
            else if (FlxG.keys.justPressed("D")) { Registry.level = XML(new Registry.LevelEndScene3); Registry.levelType=3; Registry.levelNumber=12; FlxG.switchState(new PCCinematicState()); }
            else if (FlxG.keys.justPressed("P")) FlxG.switchState(new PrizeState());
        }

        private function progressArray(label:String):Array
        {
            return new Array(label, "1", "1", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0");
        }

        private function zeroArray(label:String):Array
        {
            return new Array(label, "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0");
        }

        private function ensureSaveDefaults():void
        {
            var save:FlxSave = new FlxSave();
            if (!save.bind("SLF")) return;
            if (save.data.warehouseLevelsComplete == null) save.data.warehouseLevelsComplete = progressArray("wh");
            if (save.data.factoryLevelsComplete == null) save.data.factoryLevelsComplete = progressArray("fc");
            if (save.data.mgmtLevelsComplete == null) save.data.mgmtLevelsComplete = progressArray("mgmt");
            if (save.data.hcwarehouseLevelsComplete == null) save.data.hcwarehouseLevelsComplete = progressArray("xwh");
            if (save.data.hcfactoryLevelsComplete == null) save.data.hcfactoryLevelsComplete = progressArray("xfc");
            if (save.data.hcmgmtLevelsComplete == null) save.data.hcmgmtLevelsComplete = progressArray("xmgmt");
            if (save.data.warehouseLevelsTalk == null) save.data.warehouseLevelsTalk = zeroArray("wh-talk");
            if (save.data.factoryLevelsTalk == null) save.data.factoryLevelsTalk = zeroArray("fc-talk");
            if (save.data.mgmtLevelsTalk == null) save.data.mgmtLevelsTalk = zeroArray("mgmt-talk");
            if (save.data.hcwarehouseLevelsTalk == null) save.data.hcwarehouseLevelsTalk = zeroArray("xwh-talk");
            if (save.data.hcfactoryLevelsTalk == null) save.data.hcfactoryLevelsTalk = zeroArray("xfc-talk");
            if (save.data.hcmgmtLevelsTalk == null) save.data.hcmgmtLevelsTalk = zeroArray("xmgmt-talk");
            if (save.data.warehouseLevelsTalkAndre == null) save.data.warehouseLevelsTalkAndre = zeroArray("wh-andre");
            if (save.data.factoryLevelsTalkAndre == null) save.data.factoryLevelsTalkAndre = zeroArray("fc-andre");
            if (save.data.mgmtLevelsTalkAndre == null) save.data.mgmtLevelsTalkAndre = zeroArray("mgmt-andre");
            if (save.data.hcwarehouseLevelsTalkAndre == null) save.data.hcwarehouseLevelsTalkAndre = zeroArray("xwh-andre");
            if (save.data.hcfactoryLevelsTalkAndre == null) save.data.hcfactoryLevelsTalkAndre = zeroArray("xfc-andre");
            if (save.data.hcmgmtLevelsTalkAndre == null) save.data.hcmgmtLevelsTalkAndre = zeroArray("xmgmt-andre");
            if (save.data.warehouseCap == null) save.data.warehouseCap = zeroArray("wh-cap");
            if (save.data.factoryCap == null) save.data.factoryCap = zeroArray("fc-cap");
            if (save.data.mgmtCap == null) save.data.mgmtCap = zeroArray("mgmt-cap");
            if (save.data.hcwarehouseCap == null) save.data.hcwarehouseCap = zeroArray("xwh-cap");
            if (save.data.hcfactoryCap == null) save.data.hcfactoryCap = zeroArray("xfc-cap");
            if (save.data.hcmgmtCap == null) save.data.hcmgmtCap = zeroArray("xmgmt-cap");
            if (save.data.plays == null) save.data.plays = 0;
            save.flush();
            save.close();
        }
    }
}
