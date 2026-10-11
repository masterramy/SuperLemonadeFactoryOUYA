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
        with self.assertRaisesRegex(RuntimeError,'not cleared'):
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
            if 'C' in held: p['p1y']=378.57 if jumps==1 else 334.0
            if 'X' in held:
                if dashes==1: p.update(p1x=250.13,p1y=439.11)
                else: p['p1x']+=500*t
            elif dashes>=2 and 'RIGHT' in held: p['p1x']+=210*t
        out=airborne_dash_past_guard(lambda:dict(p),down,up,sleep,captures.append)
        self.assertGreaterEqual(out['p1x'],510.)
        self.assertEqual(jumps,2)
        self.assertIn('guard-helper-step-apex',captures)
        self.assertIn('guard-helper-step-after-dash',captures)
        self.assertIn('guard-helper-step-flight-00',captures)
        self.assertNotIn(0.16,sleeps)  # extra delay makes Andre fall from the apex
        self.assertFalse(out['p1dead'])
        self.assertEqual(held,set())

    def test_rejects_unknown_wrong_staging(self):
        with self.assertRaisesRegex(ValueError,'guard staging'):
            airborne_dash_past_guard(lambda:{'p1x':400.,'p1dead':False,'p2dead':False},lambda k:None,lambda k:None,lambda s:None,lambda s:None)

if __name__=='__main__': unittest.main()
