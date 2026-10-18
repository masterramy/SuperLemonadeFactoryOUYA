package com.ramybaheeg.slfport.pgs;
import org.junit.Test;
import static org.junit.Assert.*;
import org.json.JSONArray;
import org.json.JSONObject;
import java.nio.charset.StandardCharsets;

public final class ProgressSnapshotMergeTest {
    private byte[] zeros() throws Exception {return ProgressSnapshotMerge.merge(new byte[0],new byte[0]);}
    @Test public void emptyIsFullValidSchema() throws Exception {
        JSONObject x=new JSONObject(new String(zeros(),StandardCharsets.UTF_8));
        assertEquals(1,x.getInt("schema"));assertEquals(24,x.getJSONObject("arrays").length());
    }
    @Test public void disjointAchievementsAreNeverLost() throws Exception {
        JSONObject a=new JSONObject(new String(zeros(),StandardCharsets.UTF_8));
        JSONObject b=new JSONObject(new String(zeros(),StandardCharsets.UTF_8));
        a.getJSONObject("arrays").getJSONArray("warehouseLevelsComplete").put(1,"1");
        b.getJSONObject("arrays").getJSONArray("warehouseLevelsComplete").put(3,"1");
        JSONArray out=new JSONObject(new String(
            ProgressSnapshotMerge.merge(a.toString().getBytes(StandardCharsets.UTF_8),
                                        b.toString().getBytes(StandardCharsets.UTF_8)),
            StandardCharsets.UTF_8)).getJSONObject("arrays").getJSONArray("warehouseLevelsComplete");
        assertEquals("1",out.getString(1));assertEquals("0",out.getString(2));
        assertEquals("1",out.getString(3));
    }
    @Test(expected=Exception.class) public void rejectNumericProgress() throws Exception {
        JSONObject x=new JSONObject(new String(zeros(),StandardCharsets.UTF_8));
        x.getJSONObject("arrays").getJSONArray("factoryLevelsTalk").put(4,1);
        ProgressSnapshotMerge.merge(zeros(),x.toString().getBytes(StandardCharsets.UTF_8));
    }
    @Test(expected=Exception.class) public void rejectUnexpectedEnvelopeKey() throws Exception {
        JSONObject x=new JSONObject(new String(zeros(),StandardCharsets.UTF_8));x.put("extra",true);
        ProgressSnapshotMerge.merge(zeros(),x.toString().getBytes(StandardCharsets.UTF_8));
    }
    @Test(expected=Exception.class) public void rejectWrongCategoryLabel() throws Exception {
        JSONObject x=new JSONObject(new String(zeros(),StandardCharsets.UTF_8));
        x.getJSONObject("arrays").getJSONArray("hcmgmtCap").put(0,"wrong");
        ProgressSnapshotMerge.merge(zeros(),x.toString().getBytes(StandardCharsets.UTF_8));
    }
    @Test(expected=Exception.class) public void rejectMalformedUtf8() throws Exception {
        ProgressSnapshotMerge.merge(zeros(),new byte[]{(byte)0xC3,(byte)0x28});
    }
    @Test(expected=Exception.class) public void rejectOversizedSnapshot() throws Exception {
        ProgressSnapshotMerge.merge(zeros(),new byte[65537]);
    }
}
