import unittest
from guard_navigation import airborne_dash_past_guard

class GuardPassTests(unittest.TestCase):
    def test_true_airborne_dash_and_observed_clear(self):
        p={'p1x':205.,'p1y':479.11,'p1dead':False,'p2dead':False}
        held=set(); commands=[]; observations=[]
        def down(k): held.add(k);commands.append(('down',k))
        def up(k): held.discard(k);commands.append(('up',k))
        def sleep(t):
            commands.append(('sleep',round(t,2)))
            if 'X' in held and 'RIGHT' in held:p['p1x']+=500*t
            elif 'RIGHT' in held:p['p1x']+=210*t
            if 'C' in held:p['p1y']-=240*t
        result=airborne_dash_past_guard(lambda:dict(p),down,up,sleep,observations.append)
        self.assertGreaterEqual(result['p1x'],510.)
        self.assertLess(commands.index(('down','C')),commands.index(('down','X')))
        self.assertLess(commands.index(('up','C')),commands.index(('down','X')))
        # PlayerMale.airDash derives direction from facing, not KEY_RIGHT.
        # A full frame with RIGHT held must happen before X is pressed.
        ri=commands.index(('down','RIGHT'))
        ai=commands.index(('down','X'))
        self.assertIn(('sleep',0.07),commands[ri+1:ai])
        self.assertIn('guard-apex-before-dash',observations)
        self.assertIn('guard-after-dash',observations)
        self.assertEqual(held,set())

    def test_guard_death_is_hard_failure_and_releases(self):
        p={'p1x':205.,'p1y':479.,'p1dead':False,'p2dead':False}
        commands=[]
        def sleep(t):p['p1dead']=True
        with self.assertRaisesRegex(RuntimeError,'death'):
            airborne_dash_past_guard(lambda:dict(p),lambda k:commands.append(('down',k)),lambda k:commands.append(('up',k)),sleep,lambda s:None)
        self.assertIn(('up','C'),commands)
        self.assertNotIn(('down','X'),commands)

    def test_stalled_guard_cannot_be_called_cleared(self):
        p={'p1x':205.,'p1y':479.,'p1dead':False,'p2dead':False}
        with self.assertRaisesRegex(RuntimeError,'not cleared|did not rise above helper block'):
            airborne_dash_past_guard(lambda:dict(p),lambda k:None,lambda k:None,lambda t:None,lambda s:None)

    def test_first_helper_platform_landing_requires_second_legitimate_jump(self):
        # Rev52 observed run 38122130236: first dash reaches (250,439),
        # the *safe* helper step at x220,y480. That is not yet x510,
        # but a second ordinary jump can clear the x260,y440 guard ledge.
        p={'p1x':210.,'p1y':479.11,'p1dead':False,'p2dead':False}
        held=set(); captures=[]; jumps=0; dashes=0; sleeps=[]
        def down(k):
            nonlocal jumps,dashes
            held.add(k)
            if k=='C': jumps+=1
            if k=='X': dashes+=1
        def up(k): held.discard(k)
        def sleep(t):
            sleeps.append(round(t,2))
            if 'C' in held: p['p1y']={1:378.57,2:352.7,3:314.0}[jumps]
            if 'X' in held:
                if dashes==1: p.update(p1x=250.13,p1y=439.11)
                else: p['p1x']+=500*t
            elif jumps==2 and 'RIGHT' in held: p['p1x']+=210*t
            if jumps==2 and t>=.50 and 'RIGHT' not in held: p['p1y']=399.0
        def guarded_observation():
            # ADB state observation takes real elapsed time. From the second
            # helper jump until its air dash, there must be no read/capture
            # that turns a clean launch into a fatal landing.
            if jumps >= 2 and dashes < 2 and not (
                270. <= p['p1x'] <= 335. and 375. <= p['p1y'] <= 415.
            ):
                raise AssertionError('blocking observation before upper-ledge landing')
            return dict(p)
        out=airborne_dash_past_guard(guarded_observation,down,up,sleep,captures.append)
        self.assertGreaterEqual(out['p1x'],510.)
        self.assertEqual(jumps,3)
        self.assertIn('guard-upper-platform-landed',captures)
        self.assertNotIn('guard-helper-step-apex',captures)
        # No screenshot while the real game clock advances through the dash.
        # Those slow captures caused actual guard collision in run 38357033825.
        self.assertNotIn('guard-high-air-dash-early',captures)
        self.assertNotIn('guard-helper-airborne-clearance',captures)
        self.assertNotIn('guard-upper-platform-stage',captures)
        self.assertNotIn('guard-high-air-dash-late',captures)
        self.assertNotIn(0.16,sleeps)  # extra delay makes Andre fall from the apex
        self.assertFalse(out['p1dead'])
        self.assertEqual(held,set())

    # Retired the old mock claiming x210 could ground-walk through the solid
    # x220 helper. Run 38214609453 proves that premise physically false.
    # test_ground_stall_requires_actual_jump_onto_helper supersedes it.

    def test_guard_helper_uses_upper_ledge_landing_before_second_dash(self):
        # Real run 38367393914: one continuous dash from lower helper
        # x250,y439 hit patrolling army at x451,y399. The source map has
        # an upper platform at y440: land on it and jump again before X.
        p={'p1x':210.,'p1y':479.11,'p1dead':False,'p2dead':False}
        held=set(); jumps=0; dashes=0; observations=[]; landed=False
        def down(k):
            nonlocal jumps,dashes
            held.add(k)
            if k=='C': jumps+=1
            if k=='X': dashes+=1
        def up(k): held.discard(k)
        def sleep(t):
            nonlocal landed
            if jumps==1 and 'C' in held: p['p1y']=380.
            if dashes==1 and 'X' in held: p.update(p1x=250.,p1y=439.)
            elif jumps==2 and 'RIGHT' in held and 'X' not in held:
                p['p1x']=283.
            if jumps==2 and t>=.50 and 'RIGHT' not in held:
                landed=True; p['p1y']=399.
            if dashes>=2 and 'X' in held:
                if not landed: raise AssertionError('dash before landing on upper ledge')
                p.update(p1x=535.,p1y=300.)
        def observe():
            if dashes>=2 and not landed:
                raise AssertionError('no upper platform landing was established')
            return dict(p)
        out=airborne_dash_past_guard(observe,down,up,sleep,observations.append)
        self.assertTrue(landed)
        self.assertGreaterEqual(jumps,3)
        self.assertGreaterEqual(out['p1x'],510.)
        self.assertIn('guard-upper-platform-landed',observations)
        self.assertEqual(held,set())

    def test_rejects_unknown_wrong_staging(self):
        with self.assertRaisesRegex(ValueError,'guard staging'):
            airborne_dash_past_guard(lambda:{'p1x':400.,'p1dead':False,'p2dead':False},lambda k:None,lambda k:None,lambda s:None,lambda s:None)


    def test_ground_stall_requires_actual_jump_onto_helper(self):
        # Exact real-device blocker in run 38214609453: at x210,y479 the
        # x220,y480 helper block prevents simply walking RIGHT. A genuine
        # C jump is needed before a short grounded approach can advance.
        p={'p1x':205.0,'p1y':479.11,'p1dead':False,'p2dead':False}
        held=set(); jumps=0; dashes=0; captures=[]
        def down(k):
            nonlocal jumps,dashes
            held.add(k)
            if k=='C': jumps+=1
            if k=='X': dashes+=1
        def up(k): held.discard(k)
        def sleep(t):
            if 'C' in held:
                p['p1y']={1:377.0,2:377.0,3:352.0,4:314.0}[min(jumps,4)]
            if 'X' in held:
                if dashes==1: p.update(p1x=210.0,p1y=479.11)
                else: p['p1x']+=500*t
            elif jumps==2 and 'RIGHT' in held:
                p['p1x']=250.0
            elif jumps==3 and 'RIGHT' in held:
                p['p1x']+=210*t
            if jumps==2 and t>=.30 and 'RIGHT' not in held:
                p['p1y']=439.0
            if jumps==3 and t>=.50 and 'RIGHT' not in held:
                p['p1y']=399.0
        result=airborne_dash_past_guard(lambda:dict(p),down,up,sleep,captures.append)
        self.assertGreaterEqual(result['p1x'],510.)
        self.assertGreaterEqual(jumps,4)
        self.assertIn('guard-upper-platform-landed',captures)
        self.assertIn('guard-ground-helper-takeoff',captures)
        self.assertIn('guard-ground-helper-landed',captures)
        self.assertEqual(held,set())

if __name__=='__main__': unittest.main()
