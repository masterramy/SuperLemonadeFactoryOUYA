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

if __name__=='__main__': unittest.main()
