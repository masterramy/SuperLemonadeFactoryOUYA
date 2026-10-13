"""Regression contract for Level 2's authored movable-crate puzzle."""
import unittest
from crate_navigation import move_crate_off_left_ledge


class CratePuzzleTests(unittest.TestCase):
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
