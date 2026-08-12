// Shared SharedPreferences key marking that a camera capture is in
// progress, so Home can tell a lost-capture recovery apart from a normal
// launch. Set by ScanScreen before opening the camera, cleared once the
// picker returns or HomeScreen finishes recovering.
const String pendingCaptureKey = 'pending_capture';
