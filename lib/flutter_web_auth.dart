import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart' show MethodChannel;

class _OnAppLifecycleResumeObserver extends WidgetsBindingObserver {
  final Function onResumed;

  _OnAppLifecycleResumeObserver(this.onResumed);

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      onResumed();
    }
  }
}

class FlutterWebAuth {
  static const MethodChannel _channel = MethodChannel('flutter_web_auth');
  static RegExp _schemeRegExp = RegExp(r"^[a-z][a-z0-9+.-]*$");//URL schemeの正規表現

  static final _OnAppLifecycleResumeObserver _resumedObserver = _OnAppLifecycleResumeObserver(() {
    _cleanUpDanglingCalls(); // unawaited
  });

  /// Ask the user to authenticate to the specified web service.
  ///
  /// The page pointed to by [url] will be loaded and displayed to the user. From the page, the user can authenticate herself and grant access to the app. On completion, the service will send a callback URL with an authentication token, and this URL will be result of the returned [Future].
  ///
  /// [callbackUrlScheme] should be a string specifying the scheme of the url that the page will redirect to upon successful authentication.
  /// [preferEphemeral] if this is specified as `true`, an ephemeral web browser session will be used where possible (`FLAG_ACTIVITY_NO_HISTORY` on Android, `prefersEphemeralWebBrowserSession` on iOS/macOS)
  
  
  static Future<String> authenticate({required String url, required String callbackUrlScheme, bool? preferEphemeral}) async {
     if (!_schemeRegExp.hasMatch(callbackUrlScheme)) {//正規表現にマッチしない場合例外をスロー
       throw ArgumentError.value(callbackUrlScheme, 'callbackUrlScheme', 'must be a valid URL scheme');
     }
    WidgetsBinding.instance.removeObserver(_resumedObserver);//アプリがバックグラウンドからフォアグラウンドに移行した際に呼び出されるコールバックを削除
    WidgetsBinding.instance.addObserver(_resumedObserver);
     final result= await _channel.invokeMethod('authenticate', <String, dynamic>{
       'url': url,
       'callbackUrlScheme': callbackUrlScheme,
       'preferEphemeral': preferEphemeral ?? false,
     }) as String;
  print('Native authenticate method returned: $result');
  return result;
  }


  static Future<void> _cleanUpDanglingCalls() async {
    await _channel.invokeMethod('cleanUpDanglingCalls');
    WidgetsBinding.instance.removeObserver(_resumedObserver);
  }
}
