import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:appsflyer_sdk/appsflyer_sdk.dart';
import 'package:crossoverretro/Filltler.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:loading_animations/loading_animations.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,

      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: WebViewPage(),
    );
  }
}

class WebViewPage extends StatefulWidget {
  @override
  _WebViewPageState createState() => _WebViewPageState();
}

class _WebViewPageState extends State<WebViewPage> {
  final GlobalKey webViewKey = GlobalKey();
  InAppWebViewController? webViewController;

  String? iosSystemVersion;
  String? deviceInformation;
  String? appsFlyerUniqueId;
  String? _firebaseCloudToken;
  late AppsflyerSdk _customAppsFlyerSdk;
  String  currentUrl="";
  String advertisingId = "Fetching Advertising ID...";
  String trackingStatus = "Unknown";
  bool isLoading = true; // Показывает, идет ли загрузка страницы
  final List<ContentBlocker> contentBlockers = [];


  Future<void> _initializeATT() async {
    final TrackingStatus status =
    await AppTrackingTransparency.trackingAuthorizationStatus;

    if (status == TrackingStatus.notDetermined) {
      await Future.delayed(const Duration(milliseconds: 1000));
      await AppTrackingTransparency.requestTrackingAuthorization();
    }

    final uuid = await AppTrackingTransparency.getAdvertisingIdentifier();
    print("UUID: $uuid");
  }
  void _initializeAppsFlyer() {
    AppsFlyerOptions options = AppsFlyerOptions(
      afDevKey: "qsBLmy7dAXDQhowM8V3ca4",
      appId: "6742021017",
      showDebug: true,
      timeToWaitForATTUserAuthorization: 30,
    );

    _customAppsFlyerSdk = AppsflyerSdk(options);

    _customAppsFlyerSdk.initSdk(
      registerConversionDataCallback: true,
      registerOnAppOpenAttributionCallback: true,
      registerOnDeepLinkingCallback: true,
    );

    _customAppsFlyerSdk.startSDK(
      onSuccess: () {
        print("AppsFlyer SDK успешно инициализирован.");
      },
      onError: (int errorCode, String errorMessage) {
        print(
            "Ошибка инициализации AppsFlyer SDK: Код $errorCode - $errorMessage");
      },
    );
  }
  @override
  void initState() {
    super.initState();
    _initializeATT();
_initializeAppsFlyer();


    for (final adUrlFilter in Filltler) {
      contentBlockers.add(ContentBlocker(
          trigger: ContentBlockerTrigger(
            urlFilter: adUrlFilter,
          ),
          action: ContentBlockerAction(
            type: ContentBlockerActionType.BLOCK,
          )));
    }

    contentBlockers.add(ContentBlocker(
      trigger: ContentBlockerTrigger(urlFilter: ".cookie", resourceType: [
        //   ContentBlockerTriggerResourceType.IMAGE,

        ContentBlockerTriggerResourceType.RAW
      ]),
      action: ContentBlockerAction(
          type: ContentBlockerActionType.BLOCK, selector: ".notification"),
    ));

    contentBlockers.add(ContentBlocker(
      trigger: ContentBlockerTrigger(urlFilter: ".cookie", resourceType: [
        //   ContentBlockerTriggerResourceType.IMAGE,

        ContentBlockerTriggerResourceType.RAW
      ]),
      action: ContentBlockerAction(
          type: ContentBlockerActionType.CSS_DISPLAY_NONE,
          selector: ".privacy-info"),
    ));
    // apply the "display: none" style to some HTML elements
    contentBlockers.add(ContentBlocker(
        trigger: ContentBlockerTrigger(
          urlFilter: ".*",
        ),
        action: ContentBlockerAction(
            type: ContentBlockerActionType.CSS_DISPLAY_NONE,
            selector: ".banner, .banners, .ads, .ad, .advert")));

    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      body: Stack(
        children: [
          InAppWebView(
            key: webViewKey,
            initialUrlRequest: URLRequest(
              url: WebUri("https://app.puzzgamesdev.bond/MP715x"), // Замените URL на нужный вам
            ),
            onWebViewCreated: (controller) {
              webViewController = controller;
            },
            initialSettings: InAppWebViewSettings(
              disableDefaultErrorPage: true,
              contentBlockers: contentBlockers,
            ),
            onLoadStart: (controller, url) {
              setState(() {
                isLoading = true; // Начало загрузки
              });
            },
            onLoadStop: (controller, url) async {
              setState(() {
                isLoading = false; // Конец загрузки
              });
            },
            onLoadError: (controller, url, code, message) {
              setState(() {
                isLoading = false; // Ошибка загрузки
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Error loading page: $message")),
              );
            },
          ),
          if (isLoading)
            Center(
              child: LoadingBouncingGrid.square(
                size: 50.0,
                backgroundColor: Colors.blue,
              ),
            ),
        ],
      ),
    );
  }
}