// Copyright 2026 independent Super Limeade Factory Android restoration.
// Adapter contract: caller must explicitly authorize sync, no automatic sign-in.
package
{
    public interface ICloudSaveTransport
    {
        // "supported" means extension capabilities exist, NOT a signed-in player.
        function get supported():Boolean;
        function get available():Boolean;
        // Authentication may begin only from explicit player consent.
        // Callback status is "ok" or "error"; never pretend offline means ok.
        function authorize(completed:Function):void;
        // Callback signature: (status:String, json:String). Status ok/empty/error.
        // Invalid/untrusted remote JSON remains subject to CloudProgressCodec.
        function read(slot:String, completed:Function):void;
        // Callback signature: (status:String). Status ok/conflict/error.
        // A conflict MUST NOT silently choose the newer timestamp.
        function write(slot:String, json:String, completed:Function):void;
    }
}
