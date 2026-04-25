import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class GoogleAuthService {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: '935244299106-v20skm9cgmkcdguqkko7fuais8ks3f95.apps.googleusercontent.com',
    scopes: ['email', 'profile'],
  );

  Future<Map<String, dynamic>?> signInWithGoogle() async {
    try {
      GoogleSignInAccount? account = _googleSignIn.currentUser;
      
      if (account == null) {
        if (kIsWeb) {
          // For web, use signIn() directly to avoid double-completion issues
          account = await _googleSignIn.signIn();
        } else {
          // For mobile/desktop, try silent first
          account = await _googleSignIn.signInSilently().catchError((_) => null);
          account ??= await _googleSignIn.signIn();
        }
      }
      
      if (account != null) {
        final GoogleSignInAuthentication auth = await account.authentication;
        
        return {
          'id': account.id,
          'email': account.email,
          'displayName': account.displayName,
          'photoUrl': account.photoUrl,
          'idToken': auth.idToken,
          'accessToken': auth.accessToken,
        };
      }
      return null;
    } catch (error) {
      print('Google Sign-In Error: $error');
      return null;
    }
  }

  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (error) {
      print('Google Sign-Out Error: $error');
    }
  }
}