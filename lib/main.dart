import 'dart:async';
import 'dart:io' show HttpClient, SecurityContext;

import 'package:flutter/foundation.dart' as foundation;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flux_interface/flux_interface.dart';
import 'package:flux_ui/flux_ui.dart';
import 'package:injectable/injectable.dart';
import 'package:provider/provider.dart';
import 'package:responsive_builder/responsive_builder.dart';
import 'package:universal_platform/universal_platform.dart';

import 'app.dart';
import 'common/config.dart';
import 'common/constants.dart';
import 'common/localization/flux_ui_localizaion.impl.dart';
import 'common/tools.dart';
import 'common/tools/biometrics_tools.dart';
import 'data/boxes.dart';
import 'dependency_injection/dependency_injection.dart';
import 'dependency_injection/di.dart';
import 'env.dart';
import 'modules/analytics/analytics.dart';
import 'modules/meta_seo/meta_seo_service.dart';
import 'modules/webview/index.dart';
import 'services/locale_service.dart';
import 'services/services.dart';

// Ref: https://github.com/firebase/flutterfire/blob/master/packages/firebase_messaging/firebase_messaging/example/lib/main.dart#L46
// Docs: https://firebase.google.com/docs/cloud-messaging/flutter/receive#apple_platforms_and_android

/// When using Flutter version 3.3.0 or higher, the message handler must be
/// annotated with @pragma('vm:entry-point') right above the function
/// declaration (otherwise it may be removed during tree shaking for release
/// mode).
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(dynamic message) async {
  await injector.get<FirebaseCoreService>().initializeApp();
  printLog('Handling a background message ${message.messageId}');
}

void _setupApplication() {
  Configurations().setConfigurationValues(environment);

  /// Fix issue android sdk version 22 can not run the app.
  if (UniversalPlatform.isAndroid) {
    SecurityContext.defaultContext
        .setTrustedCertificatesBytes(Uint8List.fromList(isrgRootX1.codeUnits));
  }

  /// Support Webview (iframe) for Flutter Web. Requires this below header.
  /// Content-Security-Policy: frame-ancestors 'self' *.yourdomain.com
  registerWebViewWebImplementation();

  /// Hide status bar for splash screen
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.leanBack);

  Provider.debugCheckInvalidValueType = null;

  LicenseRegistry.addLicense(() async* {
    final license = await rootBundle.loadString('google_fonts/OFL.txt');
    yield LicenseEntryWithLineBreaks(['google_fonts'], license);
  });

  injector
      .get<FirebaseMessagingService>()
      .onBackgroundMessage(_firebaseMessagingBackgroundHandler);
}

void main() {
  printLog('[main] ===== START main.dart =======');

  // It is required to add the following to run the meta_seo package correctly
  // before the running of the Flutter app
  if (foundation.kIsWeb) {
    MetaSeoService.config();
  }

  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    /// Configure dependencies before running the app.
    await configureDependencies(environment: Environment.prod);

    /// Call the setup for the application.
    _setupApplication();

    /// get language code default
    var languageCode = kAdvanceConfig.defaultLanguage;

    /// override localization for flux_ui
    F.ofStatic = (context) => FluxUiLocalizationImpl(context);

    /// Init Hive boxes.
    await initBoxes();

    if (!foundation.kIsWeb) {
      /// Enable network traffic logging.
      HttpClient.enableTimelineLogging = !foundation.kReleaseMode;

      /// Lock portrait mode.
      unawaited(SystemChrome.setPreferredOrientations(
          [DeviceOrientation.portraitUp]));
    } else {
      /// Set webProxy for web
      HttpClientSetting.webProxy = Configurations.webProxy;
    }

    await GmsCheck().checkGmsAvailability(enableLog: foundation.kDebugMode);

    try {
      /// Init Firebase settings due to version 0.5.0+ requires to.
      /// Use await to prevent any usage until the initialization is completed.
      await Services().firebase.init();
      await Configurations().loadRemoteConfig();
      if (isMobile) {
        await BiometricsTools.instance.init();
      }
    } catch (e) {
      printLog(e);
      printLog('🔴 Firebase init issue');
    }

    await DependencyInjection.inject();
    Services().setAppConfig(serverConfig,
        ignoreInitCart: (Configurations.multiSiteConfigs?.isNotEmpty ?? false));
    Analytics.instance.init();
    FluxUIFactory.init(
      cacheImageWidth: kCacheImageWidth,
      imageProxy: kImageProxy,
      webProxy: Configurations.webProxy,
    );

    if (isMobile && kAdvanceConfig.autoDetectLanguage) {
      final lang = SettingsBox().languageCode;

      // The first time the app starts, get the device language
      if (lang?.isEmpty ?? true) {
        languageCode = await LocaleService().getDeviceLanguage();
      } else {
        languageCode = lang.toString();
      }
    }

    if (serverConfig['type'] == 'vendorAdmin') {
      return runApp(Services()
              .getVendorAdminApp(languageCode: languageCode, isFromMV: false) ??
          const SizedBox());
    }

    if (serverConfig['type'] == 'delivery') {
      return runApp(Services()
              .getDeliveryApp(languageCode: languageCode, isFromMV: false) ??
          const SizedBox());
    }

    ResponsiveSizingConfig.instance.setCustomBreakpoints(
        const ScreenBreakpoints(desktop: 1000, tablet: 600, watch: 100));
    runApp(App(languageCode: languageCode));
  }, printError);
}