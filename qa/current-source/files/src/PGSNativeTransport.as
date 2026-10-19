// Copyright 2026 independent Super Limeade Factory Android restoration.
// Unconfigured native extension adapter: fail closed until tested ANE installed.
// The actual Google Play Games SDK implementation MUST be supplied by an ANE;
// no claim of cloud functionality is made by including this source file.
package
{
    import flash.external.ExtensionContext;
    import flash.events.StatusEvent;
    import flash.utils.setTimeout;
    import flash.utils.clearTimeout;

    public class PGSNativeTransport implements ICloudSaveTransport
    {
        public static const EXTENSION_ID:String = "com.ramybaheeg.slfport.pgs.savedgames";
        private static const MAX_REQUEST_MILLIS:uint = 20000;
        private var requestTimeout:uint = 0;
        private var serial:uint = 0;
        private var pendingId:uint = 0;
        private var context:ExtensionContext;
        private var pending:Function;
        private var pendingType:String;
        private var ready:Boolean = false;
        private var extensionSupported:Boolean = false;

        public function PGSNativeTransport()
        {
            // A missing extension MUST NOT crash ordinary offline play.
            try { context = ExtensionContext.createExtensionContext(EXTENSION_ID, null); }
            catch (error:Error) { context = null; }
            if (context != null)
            {
                context.addEventListener(StatusEvent.STATUS, onStatus);
                try {
                    extensionSupported = context.call("supported") === true;
                    ready = extensionSupported && context.call("signedIn") === true;
                }
                catch (error2:Error) { extensionSupported = false; ready = false; }
            }
        }
        public function get supported():Boolean { return extensionSupported && context != null; }
        public function get available():Boolean { return ready && context != null; }

        public function authorize(completed:Function):void
        {
            if (!supported || pending != null) { completed("error"); return; }
            if (available) { completed("ok"); return; }
            pending = completed; pendingType = "authorize"; pendingId = nextRequestId();
            armTimeout();
            try {
                if (context.call("authorize", pendingId) !== true) fail("error");
            } catch (error:Error) { fail("error"); }
        }

        public function read(slot:String, completed:Function):void
        {
            if (!available || pending != null) { completed("error", null); return; }
            pending = completed; pendingType = "read"; pendingId = nextRequestId();
            armTimeout();
            try {
                if (context.call("read", slot, pendingId) !== true) fail("error");
            } catch (error:Error) { fail("error"); }
        }

        public function write(slot:String, snapshot:String, completed:Function):void
        {
            if (!available || pending != null) { completed("error"); return; }
            pending = completed; pendingType = "write"; pendingId = nextRequestId();
            armTimeout();
            try {
                if (context.call("write", slot, snapshot, pendingId) !== true) fail("error");
            } catch (error:Error) { fail("error"); }
        }

        private function nextRequestId():uint
        {
            serial++;
            if (serial == 0) serial = 1;
            return serial;
        }

        private function armTimeout():void
        {
            clearRequestTimeout();
            var requestId:uint = pendingId;
            requestTimeout = setTimeout(function():void {
                onRequestTimeout(requestId);
            }, MAX_REQUEST_MILLIS);
        }

        private function clearRequestTimeout():void
        {
            if (requestTimeout == 0) return;
            clearTimeout(requestTimeout);
            requestTimeout = 0;
        }

        private function onRequestTimeout(requestId:uint):void
        {
            // The old timer must never fail a new request after the old one
            // was completed or cancelled on the same transport instance.
            if (pendingId != requestId || pending == null) return;
            requestTimeout = 0;
            // Native Google SDK may still be committing this operation.
            // Cancel under the matching request ID BEFORE failing the caller.
            try {
                if (context != null) context.call("cancel", requestId);
            } catch (error:Error) { /* Native may already be unavailable. */ }
            ready = false;
            extensionSupported = false;
            fail("error");
        }

        private function fail(status:String):void
        {
            clearRequestTimeout();
            var callback:Function = pending;
            var kind:String = pendingType;
            pending = null; pendingType = null; pendingId = 0;
            if (callback != null)
            {
                if (kind == "read") callback(status, null);
                else callback(status);
            }
        }

        // ANE sends JSON {operation, status, payload} in StatusEvent.level.
        // Never accept a stale, unsolicited, or mismatched operation result.
        private function onStatus(event:StatusEvent):void
        {
            if (pending == null) return;
            var data:Object;
            try { data = JSON.parse(event.level); }
            catch (error:Error) { fail("error"); return; }
            if (data == null || data.operation !== pendingType || data.requestId !== pendingId) return;
            clearRequestTimeout();
            var callback:Function = pending;
            var kind:String = pendingType;
            pending = null; pendingType = null; pendingId = 0;
            if (kind == "authorize")
            {
                ready = data.status == "ok";
                callback(ready ? "ok" : "error");
            }
            else if (kind == "read")
                callback(data.status == "ok" || data.status == "empty" ? data.status : "error",
                         data.status == "ok" && data.payload is String ? data.payload as String : null);
            else
                callback(data.status == "ok" || data.status == "conflict" ? data.status : "error");
        }

        public function dispose():void
        {
            if (pending != null) fail("error");
            if (context != null)
            {
                context.removeEventListener(StatusEvent.STATUS, onStatus);
                context.dispose();
                context = null;
            }
            ready = false;
            extensionSupported = false;
        }
    }
}
