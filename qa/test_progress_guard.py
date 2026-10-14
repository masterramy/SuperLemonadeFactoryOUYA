import unittest
from progress_guard import is_genuine_completion, is_death


class CompletionGuardTests(unittest.TestCase):
    def test_death_is_not_victory(self):
        dead = {"levelFinished": True, "levelOverMenu": False,
                "p1dead": False, "p2dead": True}
        self.assertFalse(is_genuine_completion(dead))
        self.assertTrue(is_death(dead))

    def test_genuine_level_over_menu_is_victory(self):
        won = {"levelFinished": True, "levelOverMenu": True,
               "p1dead": False, "p2dead": False}
        self.assertTrue(is_genuine_completion(won))
        self.assertFalse(is_death(won))

    def test_live_level_is_not_victory(self):
        playing = {"levelFinished": False, "levelOverMenu": False,
                   "p1dead": False, "p2dead": False}
        self.assertFalse(is_genuine_completion(playing))
        self.assertFalse(is_death(playing))

    def test_inconsistent_death_flag_is_not_victory(self):
        inconsistent = {"levelFinished": True, "levelOverMenu": True,
                        "p1dead": True, "p2dead": False}
        self.assertFalse(is_genuine_completion(inconsistent))
        self.assertTrue(is_death(inconsistent))


if __name__ == "__main__":
    unittest.main()
