import unittest
from hazard_navigation import cross_spike_and_worker_corridor

class CorridorTests(unittest.TestCase):
    def test_real_held_jump_double_jump_and_observed_finish(self):
        presses=[]
        p={'p2x':987.0,'p2y':359.0,'p2dead':False,'p1dead':False}
        held=set()
        def down(k): presses.append(('down',k)); held.add(k)
        def up(k): presses.append(('up',k)); held.discard(k)
        def sleep(dt):
            presses.append(('sleep',round(dt,2)))
            if 'RIGHT' in held: p['p2x']+=230*dt
        def read():return dict(p)
        captures=[]
        result=cross_spike_and_worker_corridor(read,down,up,sleep,captures.append)
        self.assertGreaterEqual(result['p2x'],1315)
        self.assertIn(('sleep',0.34),presses)
        self.assertEqual([x for x in presses if x[0]!='sleep'][:4], [('down','RIGHT'),('down','C'),('up','C'),('down','C')])
        self.assertEqual([x for x in presses if x[0]!='sleep'][-2:], [('up','C'),('up','RIGHT')])
        self.assertTrue(any('corridor' in a for a in captures))

    def test_dead_never_passes_and_releases_direction(self):
        actions=[]
        p={'p2x':995.,'p2dead':False,'p1dead':False}
        def sleep(t):p['p2dead']=True
        with self.assertRaisesRegex(RuntimeError,'death'):
            cross_spike_and_worker_corridor(lambda:dict(p),lambda k:actions.append(('down',k)),lambda k:actions.append(('up',k)),sleep,lambda x:None)
        self.assertIn(('up','RIGHT'), actions)
        self.assertIn(('up','C'), actions)

    def test_stalled_corridor_never_claims_success(self):
        p={'p2x':990.,'p2dead':False,'p1dead':False}
        actions=[]
        with self.assertRaisesRegex(RuntimeError,'not crossed'):
            cross_spike_and_worker_corridor(lambda:dict(p),lambda k:actions.append(('down',k)),lambda k:actions.append(('up',k)),lambda t:None,lambda x:None)
        self.assertIn(('up','RIGHT'),actions)

    def test_out_of_bounds_staging_rejected(self):
        p={'p2x':1060.,'p2dead':False,'p1dead':False}
        with self.assertRaisesRegex(ValueError,'unsafe staging'):
            cross_spike_and_worker_corridor(lambda:dict(p),lambda k:None,lambda k:None,lambda t:None,lambda x:None)


class ExitAlignmentTests(unittest.TestCase):
    def test_aligns_without_jump_and_observes_true_exit_proximity(self):
        from hazard_navigation import align_exit_from_right
        pos={'p2x':1380.,'p2dead':False,'p1dead':False}
        cmds=[]
        def walk(d,t):
            cmds.append((d,t)); pos['p2x'] -= 210*t
        result=align_exit_from_right(lambda:dict(pos),walk,1320.0)
        self.assertLessEqual(abs(result['p2x']-1320),15)
        self.assertTrue(all(direction=='LEFT' for direction,t in cmds))
        self.assertTrue(all(t<=.16 for direction,t in cmds))

    def test_micro_corrects_safe_left_of_exit_without_jumping(self):
        from hazard_navigation import align_exit_from_right
        player={'p2x':1303.46,'p2dead':False,'p1dead':False}
        actions=[]
        def walk(direction,seconds):
            actions.append((direction,seconds))
            player['p2x'] += (220*seconds if direction=='RIGHT' else -220*seconds)
        final=align_exit_from_right(lambda:dict(player),walk,1320.0)
        self.assertLessEqual(abs(final['p2x']-1320.0),15.0)
        self.assertTrue(actions)
        self.assertEqual(actions[0][0], 'RIGHT')
        self.assertTrue(all(t<=0.16 for _,t in actions))
        self.assertTrue(all(direction in ('LEFT','RIGHT') for direction,t in actions))

    def test_actual_run_38457476683_safe_29px_left_micro_recovery(self):
        # Exact read-only observed live coordinate: both alive, x=1291.06,
        # 28.94px left of exit. A small rightward walk is safer than
        # claiming a gameplay failure without even attempting recovery.
        from hazard_navigation import align_exit_from_right
        p={'p2x':1291.06,'p1dead':False,'p2dead':False}
        actions=[]
        def walk(direction,seconds):
            actions.append((direction,seconds))
            p['p2x'] += 220*seconds if direction=='RIGHT' else -220*seconds
        result=align_exit_from_right(lambda:dict(p),walk,1320.,max_steps=12)
        self.assertLessEqual(abs(result['p2x']-1320.),15.)
        self.assertTrue(actions)
        self.assertTrue(all(k=='RIGHT' for k,_ in actions))

    def test_rejects_overshoot_into_enemy_corridor(self):
        from hazard_navigation import align_exit_from_right
        with self.assertRaisesRegex(RuntimeError,'unsafe'):
            align_exit_from_right(lambda:{'p2x':1260.,'p2dead':False,'p1dead':False},lambda *a:None,1320.)

    def test_stalled_alignment_does_not_pass(self):
        from hazard_navigation import align_exit_from_right
        with self.assertRaisesRegex(RuntimeError,'not aligned'):
            align_exit_from_right(lambda:{'p2x':1380.,'p2dead':False,'p1dead':False},lambda *a:None,1320.)

if __name__=='__main__': unittest.main()
