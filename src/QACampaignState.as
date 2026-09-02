package
{
    import org.flixel.*;

    /**
     * QA-only exhaustive campaign state. Never promote this file to shipping.
     * Cycles all 36 normal + 36 hardcore campaign variants in one Android runtime.
     */
    public class QACampaignState extends PCPlayState
    {
        public static var qaIndex:int = 0;
        private var qaLabel:FlxText;

        override public function create():void
        {
            configureVariant();
            loadLevel();
            super.create();

            qaLabel = new FlxText(6, 4, 630, variantName());
            qaLabel.setFormat(null, 8, 0xffffff, "left", 0x000000);
            qaLabel.scrollFactor.x = qaLabel.scrollFactor.y = 0;
            add(qaLabel);
        }

        override public function update():void
        {
            super.update();

            if (FlxG.keys.justPressed("N"))
            {
                qaIndex++;
                if (qaIndex >= 72) qaIndex = 0;
                FlxG.paused = false;
                FlxG.switchState(new QACampaignState);
                return;
            }
            if (FlxG.keys.justPressed("B"))
            {
                qaIndex--;
                if (qaIndex < 0) qaIndex = 71;
                FlxG.paused = false;
                FlxG.switchState(new QACampaignState);
                return;
            }
        }

        private function configureVariant():void
        {
            var raw:int = qaIndex % 36;
            Registry.levelType = int(raw / 12) + 1;
            Registry.levelNumber = (raw % 12) + 1;
            Registry.hardCore = qaIndex >= 36;
            Registry.oldSchoolMode = false;
            Registry.restartMusic = true;
            Registry.DEMO = false;
            Registry.isPCVersion = true;
            Registry.isWinnitron = false;
            FlxG.paused = false;
        }

        private function variantName():String
        {
            return "QA " + (qaIndex + 1) + "/72  " +
                (Registry.hardCore ? "HARDCORE" : "NORMAL") +
                "  WORLD " + Registry.levelType +
                "  LEVEL " + Registry.levelNumber;
        }
    }
}
