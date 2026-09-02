package
{
    import org.flixel.*;

    /** QA-only state that invokes the real PCPlayState.levelOver boundary logic. */
    public class QABoundaryPlayState extends PCPlayState
    {
        public static var qaCase:int = 1;
        private var fired:Boolean = false;
        private var qaLabel:FlxText;

        override public function create():void
        {
            ensureSaveDefaults();
            configureCase();
            if (Registry.oldSchoolMode) loadLevel_oldSchoolMode();
            else loadLevel();
            super.create();
            qaLabel = new FlxText(5, 4, 630, caseLabel());
            qaLabel.setFormat(null, 8, 0xffffff, "left", 0x000000);
            qaLabel.scrollFactor.x = qaLabel.scrollFactor.y = 0;
            add(qaLabel);
        }

        override public function update():void
        {
            super.update();
            if (!fired && FlxG.keys.justPressed("K"))
            {
                fired = true;
                levelOver();
                levelOverCount = 6.1;
                levelOver();
            }
        }

        private function configureCase():void
        {
            Registry.DEMO = false;
            Registry.isPCVersion = true;
            Registry.isWinnitron = false;
            Registry.isPlayingCustomLevel = false;
            Registry.restartMusic = true;
            Registry.levelNumber = 12;
            Registry.oldSchoolMode = qaCase >= 4;
            Registry.hardCore = false;
            Registry.levelType = 1;

            if (qaCase == 1) Registry.levelType = 1;
            else if (qaCase == 2) Registry.levelType = 2;
            else if (qaCase == 3) Registry.levelType = 3;
            else if (qaCase == 4) { Registry.levelType = 1; Registry.hardCore = false; }
            else if (qaCase == 5) { Registry.levelType = 2; Registry.hardCore = false; }
            else if (qaCase == 6) { Registry.levelType = 3; Registry.hardCore = false; }
            else if (qaCase == 7) { Registry.levelType = 1; Registry.hardCore = true; }
            else if (qaCase == 8) { Registry.levelType = 2; Registry.hardCore = true; }
            else if (qaCase == 9) { Registry.levelType = 3; Registry.hardCore = true; }

            Registry.oldSchoolLivesM = 3;
            Registry.oldSchoolLivesF = 3;
            FlxG.paused = false;
        }

        private function caseLabel():String
        {
            if (qaCase <= 3) return "QA BOUNDARY " + qaCase + "/9 NORMAL W" + Registry.levelType + " L12 -> CINEMATIC";
            return "QA BOUNDARY " + qaCase + "/9 OLD SCHOOL " + (Registry.hardCore ? "HC " : "NORMAL ") + "W" + Registry.levelType + " L12";
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
