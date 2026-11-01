import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_preview/device_preview.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_application_again/screens/authentication/login_screen.dart';
import 'package:flutter_application_again/screens/authentication/signup_screen.dart';
import 'package:flutter_application_again/screens/functionalities/home_page.dart';
import 'package:flutter_application_again/screens/wrapper.dart';
import 'package:flutter_application_again/utils/colors.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'firebase_options.dart';

final rootScaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: kIsWeb ? DefaultFirebaseOptions.web : null,
  );
  if (!kIsWeb) {
    FirebaseFirestore.instance.settings =
        const Settings(persistenceEnabled: true);
  }
  FlutterError.onError = (details) {
    //whenever there's an error, exit the app
    FlutterError.presentError(details);
    if (kReleaseMode) exit(1);
  };
  runApp(ProviderScope(
      child: DevicePreview(
          enabled: !kReleaseMode, builder: ((context) => const MyApp()))));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      scaffoldMessengerKey: rootScaffoldMessengerKey,
      locale: DevicePreview.locale(context),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        FlutterQuillLocalizations.delegate,
      ],
      debugShowCheckedModeBanner: false,
      builder: DevicePreview.appBuilder,
      theme: CustomTheme.DarkTheme,
      home: const Wrapper(),
      routes: {
        'Login': (context) => const LoginScreen(),
        'Sign up': (context) => const SignUpScreen(),
        'Home page': (context) => const HomePage()
      },
    );
  }
}
