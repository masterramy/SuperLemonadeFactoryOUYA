// Copyright 2026 Independent Super Limeade Factory Android restoration.
// Google Play Games Services v2 Saved Games Adobe AIR native extension.
// Not packaged with public game until genuine PGS console/device acceptance.
package com.ramybaheeg.slfport.pgs;

import android.app.Activity;
import android.content.pm.ApplicationInfo;
import android.content.pm.PackageManager;
import android.os.Bundle;
import com.adobe.fre.FREContext;
import com.adobe.fre.FREExtension;
import com.adobe.fre.FREFunction;
import com.adobe.fre.FREObject;
import com.google.android.gms.games.PlayGames;
import com.google.android.gms.games.PlayGamesSdk;
import com.google.android.gms.games.GamesSignInClient;
import com.google.android.gms.games.SnapshotsClient;
import com.google.android.gms.games.snapshot.Snapshot;
import com.google.android.gms.games.snapshot.SnapshotMetadataChange;
import com.google.android.gms.games.snapshot.SnapshotContents;
import org.json.JSONObject;
import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.util.Arrays;
import java.util.HashMap;
import java.util.Map;
import java.util.regex.Pattern;

public final class PGSExtension implements FREExtension {
    @Override public void initialize() { }
    @Override public void dispose() { }
    @Override public FREContext createContext(String type) { return new PGSContext(); }

    public static final class PGSContext extends FREContext {
        private static final Pattern SLOT = Pattern.compile("[A-Za-z0-9._~-]{1,100}");
        private static final int MAX_BYTES = 65536;
        private static final int MAX_NATIVE_CONFLICT_RETRIES = 3;
        private interface OpenedConsumer { void onOpen(Snapshot snapshot, boolean resolvedConflict); }
        private static final String APP_ID_META = "com.google.android.gms.games.APP_ID";
        private static final String APP_SMOKE_META = "com.ramybaheeg.slfport.pgs.QA_SMOKE_ONLY";
        // All operations are allowed only after the user presses Cloud Save.
        private volatile boolean authorized = false;
        private volatile boolean disposed = false;
        private volatile boolean busy = false;
        private volatile long activeRequestId = 0;
        // Timeouts must never permit an older pending remote write to race
        // a newer one. Once quarantined, sync is disabled until app restart.
        private static volatile boolean processQuarantined = false;
        private final Map<String,byte[]> lastRead = new HashMap<>();
        private SnapshotsClient snapshots;

        private static FREObject booleanResult(boolean value) {
            try { return FREObject.newObject(value); }
            catch (Exception ignored) { return null; }
        }
        private static boolean configured(Activity activity) {
            if (activity == null) return false;
            try {
                ApplicationInfo info = activity.getPackageManager().getApplicationInfo(
                        activity.getPackageName(), PackageManager.GET_META_DATA);
                Bundle data = info.metaData;
                // Smoke-only developer APKs must never present unconfigured cloud saves as available.
                if (data != null && data.getBoolean(APP_SMOKE_META, false)) return false;
                // Numeric resources and resource-backed strings are both supported.
                Object value = data == null ? null : data.get(APP_ID_META);
                return value != null && !value.toString().trim().isEmpty() && !"0".equals(value.toString());
            } catch (Exception | LinkageError ignored) { return false; }
        }
        private void emit(String operation, long requestId, String status, String payload) {
            if (disposed) return;
            try {
                JSONObject message = new JSONObject()
                        .put("operation", operation).put("requestId", requestId)
                        .put("status", status);
                if (payload != null) message.put("payload", payload);
                dispatchStatusEventAsync("PGS", message.toString());
            } catch (Exception ignored) { }
        }
        private static long requestId(FREObject[] args, int position) throws Exception {
            // FRE int is signed; zero-extend to preserve the AS3 uint request token.
            return ((long)args[position].getAsInt()) & 0xffffffffL;
        }
        private static String str(FREObject[] args, int position) throws Exception {
            return args[position].getAsString();
        }
        private boolean live() { return !disposed && !processQuarantined && configured(getActivity()); }
        private boolean current(long id) { return !disposed && !processQuarantined && busy && activeRequestId == id; }
        private boolean validSlot(String slot) { return slot != null && SLOT.matcher(slot).matches(); }
        private void finish(String operation, long id, String status, String payload) {
            if (!current(id)) return;
            activeRequestId = 0;
            busy = false;
            emit(operation, id, status, payload);
        }

        /** Preserve both Google server snapshots; never use last-modified overwrite. */
        private void handleOpenResult(SnapshotsClient.DataOrConflict<Snapshot> result,
                String operation, long id, boolean resolvedConflict, int retries,
                OpenedConsumer consumer) {
            if (disposed) return;
            if (result == null) { finish(operation,id,"error",null); return; }
            if (!result.isConflict()) {
                Snapshot opened=result.getData();
                if(opened==null){finish(operation,id,"error",null);return;}
                consumer.onOpen(opened,resolvedConflict);
                return;
            }
            if(retries>=MAX_NATIVE_CONFLICT_RETRIES){
                finish(operation,id,"error",null);return;
            }
            try {
                SnapshotsClient.SnapshotConflict conflict=result.getConflict();
                if(conflict==null||conflict.getSnapshot()==null
                        ||conflict.getConflictingSnapshot()==null
                        ||conflict.getResolutionSnapshotContents()==null){
                    finish(operation,id,"error",null);return;
                }
                byte[] server=conflict.getSnapshot().getSnapshotContents().readFully();
                byte[] device=conflict.getConflictingSnapshot().getSnapshotContents().readFully();
                byte[] merged=ProgressSnapshotMerge.merge(server,device);
                SnapshotContents contents=conflict.getResolutionSnapshotContents();
                if(!contents.writeBytes(merged)){
                    finish(operation,id,"error",null);return;
                }
                String serverId=conflict.getSnapshot().getMetadata().getSnapshotId();
                snapshots.resolveConflict(conflict.getConflictId(),serverId,
                        new SnapshotMetadataChange.Builder().build(),contents)
                    .addOnCompleteListener(getActivity(),task -> {
                        if(disposed)return;
                        if(!task.isSuccessful()){
                            finish(operation,id,"error",null);return;
                        }
                        handleOpenResult(task.getResult(),operation,id,true,retries+1,consumer);
                    });
            } catch(Exception | LinkageError ex){
                // A malformed snapshot never grants permission to overwrite progress.
                finish(operation,id,"error",null);
            }
        }

        @Override public Map<String,FREFunction> getFunctions() {
            Map<String,FREFunction> functions = new HashMap<>();
            functions.put("supported", (ctx, args) -> booleanResult(live()));
            functions.put("signedIn", (ctx, args) -> booleanResult(authorized && live()));
            functions.put("cancel", (ctx, args) -> {
                if (args.length != 1) return booleanResult(false);
                final long id;
                try { id = requestId(args,0); } catch (Exception e) { return booleanResult(false); }
                if (!current(id)) return booleanResult(false);
                // Do not allow new writes while an old SDK write may still be
                // executing: quarantine sync across all contexts this process.
                processQuarantined = true;
                activeRequestId = 0;
                busy = false;
                authorized = false;
                lastRead.clear();
                return booleanResult(true);
            });
            functions.put("authorize", (ctx,args) -> {
                if (!live() || busy || args.length != 1) return booleanResult(false);
                final long id;
                try { id = requestId(args,0); } catch (Exception e) { return booleanResult(false); }
                if (id == 0) return booleanResult(false);
                busy = true; activeRequestId = id;
                try {
                    Activity activity = getActivity();
                    // Initialize only after an explicit Cloud Save button action.
                    // PGSv2 initialization may otherwise trigger silent sign-in.
                    PlayGamesSdk.initialize(activity.getApplicationContext());
                    GamesSignInClient signIn = PlayGames.getGamesSignInClient(activity);
                    signIn.isAuthenticated().addOnCompleteListener(activity, check -> {
                        if (!current(id)) return;
                        if (check.isSuccessful() && check.getResult().isAuthenticated()) {
                            authorized = true;
                            snapshots = PlayGames.getSnapshotsClient(activity);
                            finish("authorize",id,"ok",null);
                        } else {
                            signIn.signIn().addOnCompleteListener(activity, result -> {
                                if (!current(id)) return;
                                authorized = result.isSuccessful() && result.getResult().isAuthenticated();
                                if (authorized) snapshots = PlayGames.getSnapshotsClient(activity);
                                else { snapshots = null; lastRead.clear(); }
                                finish("authorize",id,authorized ? "ok" : "error",null);
                            });
                        }
                    });
                } catch (Exception | LinkageError e) {
                    authorized = false; snapshots = null; lastRead.clear();
                    finish("authorize",id,"error",null);
                }
                return booleanResult(true);
            });
            functions.put("read", (ctx,args) -> {
                if (!authorized || !live() || busy || snapshots == null || args.length != 2)
                    return booleanResult(false);
                final String slot;
                final long id;
                try { slot = str(args,0); id = requestId(args,1); }
                catch (Exception e) { return booleanResult(false); }
                if (id == 0 || !validSlot(slot)) return booleanResult(false);
                busy = true; activeRequestId = id;
                try {
                    snapshots.open(slot, true, SnapshotsClient.RESOLUTION_POLICY_MANUAL)
                        .addOnCompleteListener(getActivity(), task -> {
                            if (!current(id)) {
                                // A timed-out open may still return a native handle.
                                if (task.isSuccessful() && !task.getResult().isConflict()) {
                                    Snapshot late = task.getResult().getData();
                                    if (late != null) try { snapshots.discardAndClose(late); } catch (Exception ignored) { }
                                }
                                return;
                            }
                            if (!task.isSuccessful()) {
                                finish("read",id,"error",null); return;
                            }
                            handleOpenResult(task.getResult(),"read",id,false,0,(snapshot,resolved) -> {
                            if (snapshot == null || snapshot.getSnapshotContents() == null) {
                                finish("read",id,"error",null); return;
                            }
                            try {
                                byte[] bytes = snapshot.getSnapshotContents().readFully();
                                if (bytes == null) bytes = new byte[0];
                                // Always close the opened snapshot even on reads.
                                snapshots.discardAndClose(snapshot);
                                if (bytes.length > MAX_BYTES) { finish("read",id,"error",null);return; }
                                lastRead.put(slot, bytes.clone());
                                String payload = bytes.length == 0 ? null : new String(bytes, StandardCharsets.UTF_8);
                                finish("read",id,bytes.length == 0 ? "empty" : "ok",payload);
                            } catch (IOException | RuntimeException e) {
                                try { snapshots.discardAndClose(snapshot); } catch (Exception ignored) { }
                                finish("read",id,"error",null);
                            }
                            });
                        });
                } catch (Exception | LinkageError e) { finish("read",id,"error",null); }
                return booleanResult(true);
            });
            functions.put("write", (ctx,args) -> {
                if (!authorized || !live() || busy || snapshots == null || args.length != 3)
                    return booleanResult(false);
                final String slot, json;
                final long id;
                try { slot = str(args,0); json = str(args,1); id = requestId(args,2); }
                catch (Exception e) { return booleanResult(false); }
                if (id == 0 || !validSlot(slot) || json == null || !lastRead.containsKey(slot))
                    return booleanResult(false);
                byte[] incoming = json.getBytes(StandardCharsets.UTF_8);
                if (incoming.length == 0 || incoming.length > MAX_BYTES) return booleanResult(false);
                // The caller merged *fresh local* and the preceding remote state.
                final byte[] expectedSnapshot = lastRead.get(slot).clone();
                busy = true; activeRequestId = id;
                try {
                    snapshots.open(slot, true, SnapshotsClient.RESOLUTION_POLICY_MANUAL)
                        .addOnCompleteListener(getActivity(), task -> {
                            if (!current(id)) {
                                if (task.isSuccessful() && !task.getResult().isConflict()) {
                                    Snapshot late = task.getResult().getData();
                                    if (late != null) try { snapshots.discardAndClose(late); } catch (Exception ignored) { }
                                }
                                return;
                            }
                            if (!task.isSuccessful()) { finish("write",id,"error",null);return; }
                            handleOpenResult(task.getResult(),"write",id,false,0,(snapshot,resolved) -> {
                                if(resolved){
                                    // Fresh cloud monotonic merge requires a new AS3 local read.
                                    snapshots.discardAndClose(snapshot);
                                    finish("write",id,"conflict",null);return;
                                }
                            if (snapshot == null || snapshot.getSnapshotContents() == null) {
                                finish("write",id,"error",null);return;
                            }
                            try {
                                SnapshotContents contents = snapshot.getSnapshotContents();
                                byte[] remote = contents.readFully();
                                if (remote == null) remote = new byte[0];
                                if (!Arrays.equals(remote, expectedSnapshot)) {
                                    snapshots.discardAndClose(snapshot);
                                    finish("write",id,"conflict",null);return;
                                }
                                if (!contents.writeBytes(incoming)) {
                                    snapshots.discardAndClose(snapshot);
                                    finish("write",id,"error",null);return;
                                }
                                snapshots.commitAndClose(snapshot,new SnapshotMetadataChange.Builder().build())
                                    .addOnCompleteListener(getActivity(), saved -> {
                                        if (!current(id)) return;
                                        if (!saved.isSuccessful()) { finish("write",id,"error",null);return; }
                                        lastRead.put(slot, incoming.clone());
                                        finish("write",id,"ok",null);
                                    });
                            } catch (IOException | RuntimeException e) {
                                try { snapshots.discardAndClose(snapshot); } catch (Exception ignored) { }
                                finish("write",id,"error",null);
                            }
                            });
                        });
                } catch (Exception | LinkageError e) { finish("write",id,"error",null); }
                return booleanResult(true);
            });
            return functions;
        }
        @Override public void dispose() {
            disposed = true;
            activeRequestId = 0;
            busy = false;
            lastRead.clear();
            snapshots = null;
            authorized = false;
        }
    }
}
