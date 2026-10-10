import unittest
from ledge_navigation import sustained_jump_right, clear_tall_ledge


class LedgeNavigationTests(unittest.TestCase):
    def test_sustained_jump_held_not_tapped(self):
        log=[]
        sustained_jump_right(lambda k: log.append(('down',k)),
                            lambda k: log.append(('up',k)),
                            lambda s: log.append(('sleep',round(s,2))))
        self.assertEqual([x for x in log if x[0]!='sleep'],
                         [('down','RIGHT'),('down','C'),('up','C'),('up','RIGHT')])
        i=log.index(('down','C'))
        self.assertGreaterEqual(log[i+1][1],.32)

    def test_stages_left_then_crosses_on_held_jump(self):
        pos={'p1x':730.0,'p1y':479.0,'p1dead':False,'p2dead':False}
        snaps=[]
        def hold(direction,seconds):
            pos['p1x'] += (-1 if direction=='LEFT' else 1)*210*seconds
        def jump(): pos.update(p1x=785.0,p1y=359.0)
        result=clear_tall_ledge(lambda:dict(pos),hold,jump,snaps.append)
        self.assertGreaterEqual(result['p1x'],740)
        self.assertTrue(any('stage' in s for s in snaps))
        self.assertTrue(any('result' in s for s in snaps))

    def test_apparent_wall_clip_below_platform_is_not_a_crossing(self):
        pos={'p1x':730.0,'p1y':479.0,'p1dead':False,'p2dead':False}
        def jump(): pos.update(p1x=785.0,p1y=425.0)
        with self.assertRaisesRegex(RuntimeError,'Tall platform not crossed'):
            clear_tall_ledge(lambda:dict(pos),lambda *a:None,jump,lambda *a:None,attempts=1)

    def test_blocked_path_fails_closed(self):
        pos={'p1x':730.0,'p1y':479.0,'p1dead':False,'p2dead':False}
        with self.assertRaisesRegex(RuntimeError,'Tall platform not crossed'):
            clear_tall_ledge(lambda:dict(pos),lambda *a:None,lambda:None,lambda *a:None,attempts=2)

if __name__=='__main__':
    unittest.main()
