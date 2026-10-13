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

    def test_player_body_must_clear_wall_not_just_head(self):
        pos={'p1x':730.,'p1y':479.,'p1dead':False,'p2dead':False}
        def jump(): pos.update(p1x=785.,p1y=385.)
        with self.assertRaisesRegex(RuntimeError,'Tall platform not crossed'):
            clear_tall_ledge(lambda:dict(pos),lambda *a:None,jump,lambda *a:None,attempts=1)

    def test_blocked_path_fails_closed(self):
        pos={'p1x':730.0,'p1y':479.0,'p1dead':False,'p2dead':False}
        with self.assertRaisesRegex(RuntimeError,'Tall platform not crossed'):
            clear_tall_ledge(lambda:dict(pos),lambda *a:None,lambda:None,lambda *a:None,attempts=2)


    def test_real_crate_landing_triggers_second_normal_jump_before_wall(self):
        # Exact run 38464588882: p1x730,y457.19 on fallen crate x716,y497.
        # Do not stage LEFT off the foothold; jump toward the upper platform.
        pos={'p1x':730.0,'p1y':457.19,
             'crateX':716.,'crateY':497.1,'p1dead':False,'p2dead':False}
        launched=[]; actions=[]
        def hold(direction, seconds): actions.append(direction)
        def normal_ground_jump():
            raise AssertionError('Already on fallen crate: no extra ground jump')
        def crate_jump():
            launched.append(dict(pos))
            pos.update(p1x=770.0,p1y=359.0)
        out=clear_tall_ledge(lambda:dict(pos),hold,normal_ground_jump,
                             lambda _:None,attempts=4,crate_jump=crate_jump)
        self.assertEqual(len(launched),1)
        self.assertAlmostEqual(launched[0]['p1x'],730)
        self.assertAlmostEqual(launched[0]['p1y'],457.19)
        self.assertEqual(out['p1x'],770)
        self.assertNotIn('LEFT',actions)

    def test_ground_jump_lands_on_crate_then_second_jump_clears_wall(self):
        pos={'p1x':691.0,'p1y':479.11,
             'crateX':716.,'crateY':497.1,'p1dead':False,'p2dead':False}
        actions=[]
        def hold(direction,seconds):actions.append((direction,seconds))
        def ordinary_ground_jump():pos.update(p1x=730.0,p1y=457.19)
        def ordinary_crate_jump():
            self.assertAlmostEqual(pos['p1x'],730.0)
            self.assertAlmostEqual(pos['p1y'],457.19)
            pos.update(p1x=772.0,p1y=359.0)
        result=clear_tall_ledge(lambda:dict(pos),hold,ordinary_ground_jump,
                                lambda _:None,attempts=3,
                                crate_jump=ordinary_crate_jump)
        self.assertEqual(result['p1x'],772.0)
        self.assertEqual(actions,[])

    def test_crate_jump_uses_genuine_held_keys_and_always_releases(self):
        from ledge_navigation import crate_jump_right
        events=[]
        crate_jump_right(lambda k:events.append(('down',k)),
                         lambda k:events.append(('up',k)),
                         lambda t:events.append(('sleep',round(t,2))))
        self.assertEqual([e for e in events if e[0]!='sleep'],[
            ('down','C'),('down','RIGHT'),('up','C'),('up','RIGHT')])
        self.assertEqual(events[1],('sleep',.26))

    def test_crate_stage_cannot_be_mistaken_for_final_wall_clearance(self):
        pos={'p1x':730.,'p1y':457.19,'crateX':716.,'crateY':497.1,
             'p1dead':False,'p2dead':False}
        launches=[]
        with self.assertRaisesRegex(RuntimeError,'Tall platform not crossed'):
            clear_tall_ledge(lambda:dict(pos),lambda *a:None,lambda:None,
                             lambda *a:None,attempts=2,
                             crate_jump=lambda:launches.append(True))
        self.assertTrue(launches)

    def test_apex_first_jump_holds_c_before_right(self):
        from ledge_navigation import apex_first_jump_right
        log=[]
        def down(k): log.append(('down',k))
        def up(k): log.append(('up',k))
        def sleep(s): log.append(('sleep',round(s,2)))
        probes=[]
        apex_first_jump_right(down,up,sleep,lambda label:probes.append(label))
        self.assertLess(log.index(('down','C')),log.index(('down','RIGHT')))
        self.assertIn(('sleep',0.34),log)
        self.assertEqual(log[-2:],[('up','RIGHT'),('sleep',0.18)])
        self.assertIn('apex-before-translate',probes)

    def test_apex_jump_releases_keys_on_observer_error(self):
        from ledge_navigation import apex_first_jump_right
        log=[]
        with self.assertRaisesRegex(RuntimeError,'observer unavailable'):
            apex_first_jump_right(lambda k: log.append(('down',k)),
                                  lambda k: log.append(('up',k)),
                                  lambda s:None,
                                  lambda label: (_ for _ in ()).throw(RuntimeError('observer unavailable')))
        self.assertIn(('up','C'),log)
        self.assertNotIn(('down','RIGHT'),log)

if __name__=='__main__':
    unittest.main()
