package com.ramybaheeg.slfport.pgs;
import java.nio.ByteBuffer;
import java.nio.charset.CharacterCodingException;
import java.nio.charset.CodingErrorAction;
import java.nio.charset.StandardCharsets;
import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

/** Strict monotonic merge of the 24 original progress categories. */
public final class ProgressSnapshotMerge {
    private static final int MAX = 65536;
    private static final String[] FIELDS = {
        "warehouseLevelsComplete","factoryLevelsComplete","mgmtLevelsComplete",
        "hcwarehouseLevelsComplete","hcfactoryLevelsComplete","hcmgmtLevelsComplete",
        "warehouseLevelsTalk","factoryLevelsTalk","mgmtLevelsTalk",
        "hcwarehouseLevelsTalk","hcfactoryLevelsTalk","hcmgmtLevelsTalk",
        "warehouseLevelsTalkAndre","factoryLevelsTalkAndre","mgmtLevelsTalkAndre",
        "hcwarehouseLevelsTalkAndre","hcfactoryLevelsTalkAndre","hcmgmtLevelsTalkAndre",
        "warehouseCap","factoryCap","mgmtCap","hcwarehouseCap","hcfactoryCap","hcmgmtCap"
    };
    private static final String[] LABELS = {
        "wh   ","fc   ","mgmt ","xwh  ","xfc  ","xmgmt",
        "wh-talk   ","fc-talk   ","mgmt-talk ","xwh-talk  ","xfc-talk  ","xmgmt-talk",
        "wh-talk-andre   ","fc-talk-andre   ","mgmt-talk-andre ",
        "xwh-talk-andre  ","xfc-talk-andre  ","xmgmt-talk-andre",
        "whcap   ","fccap   ","mgmtcap ","xwhcap  ","xfccap  ","xmgmtcap"
    };
    private ProgressSnapshotMerge() {}
    public static byte[] merge(byte[] one, byte[] two) throws JSONException, CharacterCodingException {
        JSONObject a = decode(one), b = decode(two), arrays = new JSONObject();
        for (int f=0; f<FIELDS.length; f++) {
            JSONArray left=a.getJSONObject("arrays").getJSONArray(FIELDS[f]);
            JSONArray right=b.getJSONObject("arrays").getJSONArray(FIELDS[f]);
            JSONArray out=new JSONArray().put(LABELS[f]);
            for(int i=1;i<13;i++){
                String x=(String)left.get(i), y=(String)right.get(i);
                out.put(("1".equals(x)||"1".equals(y))?"1":"0");
            }
            arrays.put(FIELDS[f],out);
        }
        byte[] bytes=new JSONObject().put("schema",1).put("arrays",arrays).toString()
                .getBytes(StandardCharsets.UTF_8);
        if(bytes.length>MAX)throw new JSONException("Merged snapshot oversized");
        return bytes;
    }
    private static JSONObject decode(byte[] bytes) throws JSONException, CharacterCodingException {
        if(bytes==null||bytes.length>MAX)throw new JSONException("Missing/oversized snapshot");
        if(bytes.length==0)return empty();
        String text=StandardCharsets.UTF_8.newDecoder()
                .onMalformedInput(CodingErrorAction.REPORT)
                .onUnmappableCharacter(CodingErrorAction.REPORT)
                .decode(ByteBuffer.wrap(bytes)).toString();
        JSONObject root=new JSONObject(text);
        if(root.length()!=2||!(root.get("schema") instanceof Number)||root.getInt("schema")!=1
                ||!(root.get("arrays") instanceof JSONObject))
            throw new JSONException("Unexpected progress envelope");
        JSONObject arrays=root.getJSONObject("arrays");
        if(arrays.length()!=FIELDS.length)throw new JSONException("Unexpected progress field count");
        for(int f=0;f<FIELDS.length;f++){
            if(!arrays.has(FIELDS[f])||!(arrays.get(FIELDS[f]) instanceof JSONArray))
                throw new JSONException("Missing progress field");
            JSONArray values=arrays.getJSONArray(FIELDS[f]);
            if(values.length()!=13||!(values.get(0) instanceof String)
                    ||!LABELS[f].equals(values.getString(0)))
                throw new JSONException("Invalid progress array geometry");
            for(int i=1;i<13;i++){
                Object item=values.get(i);
                if(!(item instanceof String)||(!"0".equals(item)&&!"1".equals(item)))
                    throw new JSONException("Invalid progress slot");
            }
        }
        return root;
    }
    private static JSONObject empty() throws JSONException {
        JSONObject arrays=new JSONObject();
        for(int f=0;f<FIELDS.length;f++){
            JSONArray a=new JSONArray().put(LABELS[f]);
            for(int i=1;i<13;i++)a.put("0");
            arrays.put(FIELDS[f],a);
        }
        return new JSONObject().put("schema",1).put("arrays",arrays);
    }
}
