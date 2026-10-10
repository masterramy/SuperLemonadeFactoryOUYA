import unittest
from PIL import Image,ImageDraw
from screen_navigation import classify_screen,system_dialog_target


class ScreenNavigationTests(unittest.TestCase):
    def test_system_ui_wait_dialog_coordinates(self):
        xml='<hierarchy><node text="Pixel Launcher isn\'t responding" bounds="[100,200][900,710]"/><node text="Wait" bounds="[350,525][710,690]"/></hierarchy>'
        self.assertEqual(system_dialog_target(xml),(530,607))

    def test_unknown_dialog_does_not_click_game(self):
        xml='<hierarchy><node text="PLAY AGAIN" bounds="[100,100][400,300]"/></hierarchy>'
        self.assertIsNone(system_dialog_target(xml))

    def test_title_menu_and_level_select_classification(self):
        def frame():return Image.new('RGB',(1920,1080),(211,189,178))
        intro=frame();d=ImageDraw.Draw(intro);d.rectangle((575,35,1265,420),fill=(100,180,35));d.rectangle((1450,160,1700,400),fill=(205,40,45))
        menu=frame();d=ImageDraw.Draw(menu);d.rectangle((575,35,1265,420),fill=(100,180,35));d.rectangle((790,440,1150,590),fill=(130,65,159))
        levels=frame();d=ImageDraw.Draw(levels);d.rectangle((420,190,800,440),fill=(130,65,159))
        self.assertEqual(classify_screen(intro),'title')
        self.assertEqual(classify_screen(menu),'menu')
        self.assertEqual(classify_screen(levels),'level_select')


if __name__=='__main__':unittest.main()
