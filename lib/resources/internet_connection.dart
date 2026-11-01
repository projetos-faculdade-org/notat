import 'package:connectivity_plus/connectivity_plus.dart';

class Connection {
  static Future<bool> checkInternet() async {
    final connection = await Connectivity().checkConnectivity();

    return connection.contains(ConnectivityResult.mobile) ||
        connection.contains(ConnectivityResult.wifi) ||
        connection.contains(ConnectivityResult.ethernet);
  }
}
