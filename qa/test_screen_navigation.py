import unittest
from PIL import Image,ImageDraw
from screen_navigation import classify_screen,system_dialog_target,retry_level_select_transition,advance_cutscene_to_gameplay


class ScreenNavigationTests(unittest.TestCase):
    def test_system_ui_wait_dialog_coordinates(self):
        xml='<hierarchy><node text="Pixel Launcher isn\'t responding" bounds="[100,200][900,710]"/><node text="Wait" bounds="[350,525][710,690]"/></hierarchy>'
        self.assertEqual(system_dialog_target(xml),(530,607))

    def test_unknown_dialog_does_not_click_game(self):
        xml='<hierarchy><node text="PLAY AGAIN" bounds="[100,100][400,300]"/></hierarchy>'
        self.assertIsNone(system_dialog_target(xml))

    def test_bounded_level_select_transition_retries_only_confirmed_select(self):
        observed=iter(['level_select','level_select','gameplay'])
        actions=[]
        outcome=retry_level_select_transition(
            lambda:next(observed),
            lambda:actions.append('tap'),
            lambda:actions.append('wait'),
            attempts=4)
        self.assertEqual(outcome,'gameplay')
        self.assertEqual(actions,['tap','wait','tap','wait'])

    def test_unknown_screen_does_not_receive_extra_tap(self):
        touches=[]
        with self.assertRaisesRegex(RuntimeError,'Unknown screen'):
            retry_level_select_transition(
                lambda:'unknown',lambda:touches.append('tap'),
                lambda:None)
        self.assertEqual(touches,[])

    def test_delayed_system_dialog_unknown_is_observed_without_game_taps(self):
        observed=iter(['unknown','level_select','gameplay'])
        actions=[]
        outcome=retry_level_select_transition(
            lambda:next(observed),
            lambda:actions.append('tap'),
            lambda:actions.append('wait'),
            attempts=4)
        self.assertEqual(outcome,'gameplay')
        self.assertEqual(actions,['wait','tap','wait'])

    def test_repeated_unknown_never_causes_game_touch(self):
        touches=[]
        waits=[]
        with self.assertRaisesRegex(RuntimeError,'Unknown screen'):
            retry_level_select_transition(
                lambda:'unknown',
                lambda:touches.append('tap'),
                lambda:waits.append('wait'),
                attempts=3)
        self.assertEqual(touches,[])
        self.assertEqual(len(waits),3)

    def test_nontransition_stops_after_bounded_attempts(self):
        actions=[]
        with self.assertRaisesRegex(RuntimeError,'Level Select remains'):
            retry_level_select_transition(
                lambda:'level_select',lambda:actions.append('tap'),
                lambda:None,attempts=3)
        self.assertEqual(len(actions),3)

    def test_realistic_gameplay_controls_override_purple_level_ui(self):
        # Run 38213127671: genuine Level 2 frames have purple scenery,
        # causing the old color-only classifier to return level_select.
        im=Image.new('RGB',(1920,1080),(211,189,178))
        d=ImageDraw.Draw(im)
        d.rectangle((420,190,800,440),fill=(130,65,159))
        d.rectangle((0,850,1919,1079),fill=(145,124,109))
        d.rectangle((1640,20,1890,150),fill=(70,65,54))
        self.assertEqual(classify_screen(im),'gameplay')

    def test_story_cutscene_is_not_level_select_even_with_purple_accents(self):
        # Run 38368800892 captured real black-letterboxed dialogue,
        # misclassified as Level Select and interrupted with repeat taps.
        im=Image.new('RGB',(1920,1080),(211,189,178))
        d=ImageDraw.Draw(im)
        d.rectangle((0,0,1919,159),fill=(0,0,0))
        d.rectangle((0,866,1919,1079),fill=(0,0,0))
        d.rectangle((110,195,1820,530),fill=(250,250,250))
        d.rectangle((440,420,800,550),fill=(130,65,159))
        self.assertEqual(classify_screen(im),'cutscene')

    def test_story_advances_only_with_confirmed_cutscene_frames(self):
        labels=iter(['cutscene','cutscene','gameplay'])
        calls=[]
        outcome=advance_cutscene_to_gameplay(
            lambda:next(labels),
            lambda:calls.append('tap'),
            lambda:calls.append('wait'),
            attempts=4)
        self.assertEqual(outcome,'gameplay')
        self.assertEqual(calls,['tap','wait','tap','wait'])

    def test_cutscene_unknown_must_not_receive_blind_actions(self):
        taps=[]
        with self.assertRaisesRegex(RuntimeError,'Unknown'):
            advance_cutscene_to_gameplay(
                lambda:'unknown',lambda:taps.append('tap'),
                lambda:None,attempts=3)
        self.assertEqual(taps,[])

    def test_title_menu_and_level_select_classification(self):
        def frame():return Image.new('RGB',(1920,1080),(211,189,178))
        intro=frame();d=ImageDraw.Draw(intro);d.rectangle((575,35,1265,420),fill=(100,180,35));d.rectangle((1450,160,1700,400),fill=(205,40,45))
        menu=frame();d=ImageDraw.Draw(menu);d.rectangle((575,35,1265,420),fill=(100,180,35));d.rectangle((790,440,1150,590),fill=(130,65,159))
        levels=frame();d=ImageDraw.Draw(levels);d.rectangle((420,190,800,440),fill=(130,65,159))
        self.assertEqual(classify_screen(intro),'title')
        self.assertEqual(classify_screen(menu),'menu')
        self.assertEqual(classify_screen(levels),'level_select')


if __name__=='__main__':unittest.main()
