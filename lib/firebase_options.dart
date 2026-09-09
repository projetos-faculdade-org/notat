// Firebase configuration for the Web platform, fetched from the
// "notat-ed3af" Firebase project (Web app: flutter_application_again).
//
// Android and iOS keep initializing Firebase from their native config
// files (google-services.json / GoogleService-Info.plist) in the
// "notatcatolica" project, so only Web options are defined here.
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;

class DefaultFirebaseOptions {
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBnVq_2ZRe5JQdDwpQudMYL7VCMFS1UqEk',
    appId: '1:850792075309:web:2fb279c1d34c04c1eaa8a4',
    messagingSenderId: '850792075309',
    projectId: 'notat-ed3af',
    authDomain: 'notat-ed3af.firebaseapp.com',
    storageBucket: 'notat-ed3af.firebasestorage.app',
    measurementId: 'G-8XEKX25EZY',
  );
}
