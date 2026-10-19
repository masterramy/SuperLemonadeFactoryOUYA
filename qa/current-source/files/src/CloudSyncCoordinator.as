// Copyright 2026 independent Super Limeade Factory Android restoration.
// This does not grant network access or sign in: a real native transport and
// explicit player consent are necessary before using Saved Games.
package
{
    public class CloudSyncCoordinator
    {
        public static const SLOT:String = "slf_progress_v1";
        private static const MAX_CONFLICT_RETRIES:int = 3;
        private static const MAX_LOCAL_RECHECKS:int = 3;
        private var transport:ICloudSaveTransport;
        private var busy:Boolean = false;
        private var finished:Function;
        private var attempts:int = 0;
        private var localRechecks:int = 0;
        private var operationId:uint = 0;

        public function CloudSyncCoordinator(adapter:ICloudSaveTransport)
        {
            transport = adapter;
        }

        public function get isBusy():Boolean { return busy; }

        // No consent implies no API call of any kind, including authentication.
        public function sync(consent:Boolean, onComplete:Function):Boolean
        {
            if (busy || !consent || transport == null || !transport.supported)
                return false;
            busy = true;
            attempts = 0;
            localRechecks = 0;
            operationId++;
            var generation:uint = operationId;
            finished = onComplete;
            if (transport.available) {
                readFresh(generation);
            } else {
                var self:CloudSyncCoordinator = this;
                try {
                    transport.authorize(function(status:String):void {
                        if (!self.busy || generation != self.operationId) return;
                        if (status != "ok" || !self.transport.available) {
                            self.done("authentication_failed"); return;
                        }
                        self.readFresh(generation);
                    });
                } catch (error:Error) { done("authentication_exception"); }
            }
            return true;
        }

        private function done(status:String):void
        {
            if (!busy) return;
            busy = false;
            var callback:Function = finished;
            finished = null;
            if (callback != null) callback(status);
        }

        private function readFresh(generation:uint):void
        {
            if (!busy || generation != operationId) return;
            // Read fresh local state every retry: player could have made
            // progress during an asynchronous network roundtrip.
            var local:String = CloudProgressCodec.capture();
            if (local == null) { done("local_unavailable"); return; }
            var self:CloudSyncCoordinator = this;
            try {
                transport.read(SLOT, function(status:String, remote:String):void {
                    if (!self.busy || generation != self.operationId) return;
                    if (status == "error") { self.done("network_error"); return; }
                    if (status != "ok" && status != "empty") {
                        self.done("unexpected_read_status"); return;
                    }
                    // Null only means the provider explicitly said empty.
                    if (status == "ok" && remote == null) {
                        self.done("malformed_remote"); return;
                    }
                    var current:String = CloudProgressCodec.capture();
                    if (current == null) { self.done("local_unavailable"); return; }
                    var merged:String = status == "empty" ? current : CloudProgressCodec.merge(current, remote);
                    if (merged == null) { self.done("malformed_remote"); return; }
                    // Merge on disk BEFORE upload, guaranteeing the progress
                    // from a successfully downloaded snapshot is retained even
                    // if upload fails or the network disconnects.
                    if (status == "ok" && !CloudProgressCodec.mergeIntoLocal(remote)) {
                        self.done("local_write_failed"); return;
                    }
                    var newest:String = CloudProgressCodec.capture();
                    if (newest == null) { self.done("local_unavailable"); return; }
                    // Reconcile changes made during writing, too.
                    merged = CloudProgressCodec.merge(merged, newest);
                    if (merged == null) { self.done("local_invalid"); return; }
                    self.writeMerged(merged, generation);
                });
            } catch (error:Error) { done("read_exception"); }
        }

        private function writeMerged(snapshot:String, generation:uint):void
        {
            if (!busy || generation != operationId) return;
            var self:CloudSyncCoordinator = this;
            try {
                transport.write(SLOT, snapshot, function(status:String):void {
                    if (!self.busy || generation != self.operationId) return;
                    if (status == "ok") {
                        // Progress may have advanced while the upload was in flight.
                        // A completed network write alone is not proof that the
                        // current device state has reached the cloud.
                        var latest:String = CloudProgressCodec.capture();
                        if (latest == null) { self.done("local_unavailable"); return; }
                        var checked:String = CloudProgressCodec.merge(snapshot, latest);
                        if (checked == null) { self.done("local_invalid"); return; }
                        if (checked != snapshot) {
                            if (self.localRechecks >= MAX_LOCAL_RECHECKS) {
                                self.done("local_progress_pending"); return;
                            }
                            self.localRechecks++;
                            self.readFresh(generation);
                            return;
                        }
                        self.done("synced"); return;
                    }
                    if (status == "conflict") {
                        if (self.attempts >= MAX_CONFLICT_RETRIES) {
                            self.done("conflict_retry_exhausted"); return;
                        }
                        self.attempts++;
                        self.readFresh(generation);
                        return;
                    }
                    self.done("network_error");
                });
            } catch (error:Error) { done("write_exception"); }
        }
    }
}
