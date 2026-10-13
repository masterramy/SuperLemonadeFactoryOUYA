"""Regression contract for Level 2's authored movable-crate puzzle."""
import unittest
from crate_navigation import move_crate_off_left_ledge, reach_right_side_without_pushing


class CratePuzzleTests(unittest.TestCase):
    def test_ground_approach_keeps_authored_crate_left_and_unchanged(self):
        # Real run 38473523858: advancing directly to x825 shoved
        # the crate from x763 past x1092 (wrong edge). Stage on
        # FLOOR at x690 then jump above it without touching its side.
        p={'p2x':580.,'p2y':479.11,'crateX':763.,'crateY':377.1,
           'p1dead':False,'p2dead':False}
        launches=[];steps=[]
        def walk(direction,sec):
            steps.append((direction,sec))
            p['p2x']+= (1 if direction=='RIGHT' else -1)*min(210*sec,47)
        def jump():
            launches.append(dict(p))
            p.update(p2x=842.,p2y=359.11)
        out=reach_right_side_without_pushing(lambda:dict(p),walk,jump,
                                              lambda tag:None)
        self.assertEqual(len(launches),1)
        self.assertGreaterEqual(launches[0]['p2x'],670.)
        self.assertLessEqual(launches[0]['p2x'],715.)
        self.assertEqual(out['crateX'],763.)
        self.assertGreaterEqual(out['p2x'],out['crateX']+32.)
        self.assertTrue(all(s<=.25 for _,s in steps))

    def test_real_38474873546_safe_floor_staging_at_x719(self):
        # The vault did not run: x719.66 ground was rejected solely by
        # stale x<=715 threshold, while untouched crate x763 and all
        # characters were alive. Collision wall starts x740.
        p={'p2x':719.66,'p2y':479.11,'crateX':763.,'crateY':377.1,
           'p1dead':False,'p2dead':False}
        launched=[]
        def jump():
            launched.append(True)
            p.update(p2x=847.,p2y=359.11)
        d=reach_right_side_without_pushing(lambda:dict(p),
              lambda direction,sec:None,jump,lambda tag:None)
        self.assertEqual(launched,[True])
        self.assertEqual(d['crateX'],763.)

    def test_real_38475366497_wall_stall_fallback_one_moving_jump(self):
        # Real vertical vault came back to x730,y479, untouched
        # crate x763. A single native moving double-jump (as in
        # previous successful route) can stage on the upper platform
        # with bounded crate shift x842, then separate left-push helper.
        p={'p2x':719.66,'p2y':479.11,'crateX':763.,'crateY':377.1,
           'p1dead':False,'p2dead':False}
        calls=[]
        def vertical():
            calls.append('vertical')
            p.update(p2x=730.,p2y=479.11)
        def moving():
            calls.append('moving')
            p.update(p2x=801.76,p2y=359.11,crateX=842.77)
        result=reach_right_side_without_pushing(
            lambda:dict(p),lambda d,t:None,vertical,
            lambda tag:None, fallback_jump=moving)
        self.assertEqual(calls,['vertical','moving'])
        self.assertLess(result['crateX'],950.)
        self.assertLess(result['p2y'],400.)
        self.assertGreater(result['p2x'],780.)

    def test_ground_approach_rejects_previously_shoved_crate(self):
        p={'p2x':851.,'p2y':359.11,'crateX':1092.17,'crateY':427.1,
           'p1dead':False,'p2dead':False}
        with self.assertRaisesRegex(RuntimeError,'crate.*wrong|crate.*unsafe'):
            reach_right_side_without_pushing(lambda:dict(p),
                lambda *a:None,lambda:None,lambda *a:None)

    def test_vertical_double_jump_precedes_horizontal_vault(self):
        from crate_navigation import high_double_jump_over_crate
        events=[]
        high_double_jump_over_crate(lambda k:events.append(('down',k)),
                                    lambda k:events.append(('up',k)),
                                    lambda s:events.append(('sleep',round(s,2))))
        important=[e for e in events if e[0]!='sleep']
        self.assertEqual(important,[
            ('down','C'),('up','C'),('down','C'),('up','C'),
            ('down','RIGHT'),('up','RIGHT')])
        self.assertEqual(events[1],('sleep',.29))
        # Run 38474282598: moving RIGHT immediately after second C
        # shoved the crate from x763 to x875. Gain substantial second
        # jump height BEFORE the first horizontal frame.
        second_up=[i for i,v in enumerate(events) if v==('up','C')][1]
        right=events.index(('down','RIGHT'))
        self.assertIn(('sleep',.25),events[second_up+1:right])


    def test_jumps_to_right_then_pushes_crate_completely_off_left_edge(self):
        state={"p2x":809.6,"p2y":359.11,"crateX":842.0,"crateY":360.0,
               "p1dead":False,"p2dead":False}
        moves=[]; jumps=[]
        def jump():
            jumps.append("ordinary-double-jump")
            state["p2x"]=state["crateX"]+42
            state["p2y"]=359.11
        def hold(direction,seconds):
            moves.append((direction,seconds))
            if direction=="LEFT":
                state["p2x"]-=27
                if state["p2x"]<=state["crateX"]+29:
                    state["crateX"]-=27
                if state["crateX"]+24<=740:
                    state["crateY"]=498.0
        result=move_crate_off_left_ledge(lambda:dict(state),hold,jump,
                                         lambda tag:None)
        self.assertTrue(jumps)
        self.assertLessEqual(result["crateX"]+24,740.0)
        self.assertGreater(result["crateY"],410.0)
        self.assertTrue(all(t<=.20 for _,t in moves))

    def test_real_38463869038_airborne_overshoot_recovers_left(self):
        # Actual run: ordinary jump x809 -> x1046,y257 while crate
        # got pushed to x931.64. Still alive, enough time to steer LEFT.
        st={"p2x":809.,"p2y":359.11,"crateX":844.3,"crateY":377.1,
            "p1dead":False,"p2dead":False}
        moves=[]
        def jump():
            st.update(p2x=1046.14,p2y=257.62,crateX=931.64)
        def hold(direction,seconds):
            moves.append(direction)
            if direction=="LEFT":
                st["p2x"]-=32.
                if st["p2x"]<=st["crateX"]+29:
                    st["crateX"]-=32.
                if st["p2x"]<=995: st["p2y"]=359.11
                if st["crateX"]+24<=740: st["crateY"]=498.
        result=move_crate_off_left_ledge(lambda:dict(st),hold,jump,
                                         lambda t:None,max_actions=35)
        self.assertTrue(moves)
        self.assertEqual(moves[0],"LEFT")
        self.assertLessEqual(result["crateX"]+24,740)
        self.assertGreater(result["crateY"],410)

    def test_walking_away_does_not_claim_crate_pushed(self):
        st={"p2x":809.,"p2y":359.11,"crateX":844.,"crateY":360.,
            "p1dead":False,"p2dead":False}
        with self.assertRaisesRegex(RuntimeError,"crate.*not.*off|crate.*not.*fall"):
            move_crate_off_left_ledge(lambda:dict(st),lambda d,t:None,
                                      lambda:st.update(p2x=900.),
                                      lambda t:None,max_actions=4)

    def test_dead_player_never_passes(self):
        st={"p2x":900.,"p2y":359.,"crateX":820.,"crateY":360.,
            "p1dead":False,"p2dead":True}
        with self.assertRaisesRegex(RuntimeError,"death"):
            move_crate_off_left_ledge(lambda:dict(st),lambda d,t:None,
                                      lambda:None,lambda t:None)

    def test_crate_missing_fails_closed(self):
        st={"p2x":820.,"p2y":359.,"crateX":-1.,"crateY":-1.,
            "p1dead":False,"p2dead":False}
        with self.assertRaisesRegex(RuntimeError,"crate"):
            move_crate_off_left_ledge(lambda:dict(st),lambda d,t:None,
                                      lambda:None,lambda t:None)


if __name__=="__main__": unittest.main()
