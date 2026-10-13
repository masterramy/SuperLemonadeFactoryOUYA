"""Read-only QA patrol telemetry contract, independent of shipping source."""
import unittest
from pathlib import Path

class PatrolObserverContract(unittest.TestCase):
    def test_army_patrol_is_observed_without_mutating_enemy(self):
        code = Path("src/PCPlayState.as").read_text(encoding="utf-8")
        body = code.split("private function writeQAObservation():void", 1)[1].split("public function replaceAt", 1)[0]
        for token in ('"armyX="', '"armyY="', '"armyVx="', 'army.x.toFixed(2)', 'army.y.toFixed(2)', 'army.velocity.x.toFixed(2)'):
            self.assertIn(token, body)
        self.assertIn('army != null', body)
        self.assertNotRegex(body, r'army\.(?:x|y|velocity\.x)\s*=')
        self.assertIn('"observationOnly=true\\n"', body)

    def test_reader_accepts_patrol_observations(self):
        code = Path("qa/observed_playthrough.py").read_text(encoding="utf-8")
        self.assertIn('"armyX"', code)
        self.assertIn('"armyY"', code)
        self.assertIn('"armyVx"', code)

if __name__ == "__main__":
    unittest.main()
