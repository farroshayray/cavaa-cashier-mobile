class Env {
  static const String baseUrl = 'https://dev.nurray.my.id';
  // static const String baseUrl = 'https://cafe.vastech.co.id';
  
  // static const String baseUrl = 'https://cavaa.id';

  /// Google OAuth Web client ID (used as serverClientId to obtain idToken).
  /// Must match Laravel GOOGLE_CLIENT_ID / an allowed aud on tokeninfo.
  static const String googleServerClientId =
      '297190910515-82spjjkjpmlut910adg0usva5ug1bb96.apps.googleusercontent.com';

  // ✅ Pusher (dari .env Laravel)
  static const String pusherKey = '8829e680d7bf6f7b567a';
  static const String pusherCluster = 'ap1';
}
// flutter build apk --release 
