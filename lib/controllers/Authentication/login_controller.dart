// ignore_for_file: prefer_interpolation_to_compose_strings, avoid_print, no_leading_underscores_for_local_identifiers

import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:astrowaypartner/utils/global.dart' as global;
import 'package:otpless_flutter/otpless_flutter.dart';

import '../../models/device_detail_model.dart';
import '../../services/apiHelper.dart';
import '../../utils/config.dart';
import '../../views/Authentication/OtpScreens/login_otp_screen.dart';
import '../../views/Authentication/login_screen.dart';
import '../../views/HomeScreen/home_screen.dart';
import '../HomeController/call_controller.dart';
import '../HomeController/chat_controller.dart';
import '../HomeController/live_astrologer_controller.dart';
import '../HomeController/report_controller.dart';
import '../following_controller.dart';
import 'login_otp_controller.dart';

class LoginController extends GetxController {
  String screen = 'login_controller.dart';
  APIHelper apiHelper = APIHelper();

  // //Controller
  // final TextEditingController cMobileNumber = TextEditingController();

  //Login
  ChatController chatController = Get.find<ChatController>();
  CallController callController = Get.find<CallController>();
  ReportController reportController = Get.find<ReportController>();
  FollowingController followingController = Get.find<FollowingController>();
  final liveAstrologerController = Get.find<LiveAstrologerController>();
  final loginOtpController = Get.put(LoginOtpController());

  String signupText = tr('By signin up you agree to our');
  String termsConditionText = tr('Terms of Services');
  String andText = tr('and');
  String privacyPolicyText = tr('Privacy Policy');
  String notaAccountText = tr("Don't have an account?");
  var loaderVisibility = true;
  final urlTextContoller = TextEditingController();
  Map<String, dynamic>? dataResponse;

  String phoneOrEmail = '';
  String otp = '';
  bool isInitIos = false;
  final otplessFlutterPlugin = Otpless();
  final apihelper = APIHelper();

  String? phonenois;
  String? countrycodeis;
  int loginTypeis = 0;
  @override
  void onInit() async {
    await init();
    super.onInit();
  }

  init() {
    signupText = tr('By signin up you agree to our');
    termsConditionText = tr('Terms of Services');
    andText = tr('and');
    privacyPolicyText = tr('Privacy Policy');
    notaAccountText = tr("Don't have an account?");

    if (Platform.isIOS && !isInitIos) {
      otplessFlutterPlugin.initHeadless(OtplessappId);
      otplessFlutterPlugin.setHeadlessCallback(
        (result) {
          onHeadlessResult(result, true);
        },
      );
    }
    if (Platform.isAndroid) {
      otplessFlutterPlugin.initHeadless(OtplessappId);
//        otplessFlutterPlugin.enableOneTap(false);
      otplessFlutterPlugin.setHeadlessCallback(
        (result) {
          onHeadlessResult(result, false);
        },
      );
      debugPrint("init headless sdk is called for android");
    }
    update();
  }

  void onHeadlessResult(dynamic result, bool isphone) async {
    log('onHeadlessResult: $result');
    if (isphone) {
      dataResponse = result;
      if (result != null) {
        int statuscode = dataResponse!['statusCode'];
        log('loginscreen-onHeadlessResult statuscode: $statuscode');

        if (statuscode == 200) {
          String phoneNumber = loginOtpController.cMobileNumber.text;
          if (phoneNumber.isNotEmpty) {
            log('going to LoginOtpScreen: $statuscode');

            Get.offAll(() => LoginOtpScreen(
                  mobileNumber: phoneNumber,
                  countryCode: loginOtpController.countryCode,
                ));
          } else {
            log('failed to send otp error is $result');
          }
        } else {
          if (statuscode == 400) {
            global.showToast(message: 'Invalid otp ');
          }
          log('failed to send otp');
        }
      } else {
        log('failed to send otp result is null');
      }
    } else {
      if (result != null) {
        dataResponse = result;
        String status = dataResponse!['response']['status'].toString();
        String identity = dataResponse!['response']['identities'][0]
                ['identityType']
            .toString();
        String emailid = dataResponse!['response']['identities'][0]
                ['identityValue']
            .toString();

        log('email identity is $identity');
        log('email status is $status');

        if (status == "SUCCESS") {
          if (identity == "EMAIL") {
            loginAstrologer(email: emailid, phoneNumber: '');
          } else if (identity == "MOBILE") {
            await global.checkBody().then(
              (result) async {
                if (result) {
                  global.showOnlyLoaderDialog();
                  await apiHelper
                      .otpResponseOptless(dataResponse)
                      .then((phoneno) {
                    global.hideLoader();
                    log('phone is $phoneno');
                    if (phoneno != null) {
                      loginAstrologer(phoneNumber: phoneno, email: '');
                    } else {
                      log('onHeadlessResult phone no is null');
                    }
                  });
                }
              },
            );
          }
        } else {
          Get.snackbar("Error", "Please try again later");
        }
      } else {
        log('something went wrong while sending otp using onHeadlessResult');
      }
    }
  }

  //! PHONE OTP
  Future<void> startHeadlesswithOtp(String phoneno, String countrycode) async {
    log('start sending otp $phoneno  and $countrycode');
    global.hideLoader();

    if (Platform.isIOS && !isInitIos) {
      isInitIos = true;
      debugPrint("init headless sdk is called for ios");
      return;
    }
    Map<String, dynamic> arg = {};
    arg["phone"] = phoneno;
    arg["countryCode"] = countrycode;
    log('arg is $arg');
    otplessFlutterPlugin.startHeadless((result) {
      onHeadlessResult(result, true);
    }, arg);
  }

// //! SOCIAL MEDIA LOGIN
  Future<void> startHeadlessWithSocialMedia(String loginType) async {
    log('channelType is $loginType');
    otplessFlutterPlugin.setHeadlessCallback(
      (result) {
        onHeadlessResult(result, false);
      },
    );

    if (Platform.isIOS && !isInitIos) {
      log('Initializing headless SDK for iOS');
      otplessFlutterPlugin.initHeadless(OtplessappId);
      isInitIos = true;
      debugPrint("init headless sdk is called for ios");
      return;
    }
    Map<String, dynamic> arg = {'channelType': loginType}; //GMAIL
    log('Starting headless with arguments: $arg');
    otplessFlutterPlugin.startHeadless((result) {
      onHeadlessResult(result, false);
    }, arg);
  }

  Future loginAstrologer({String? phoneNumber, String? email}) async {
    try {
      await global.checkBody().then((result) async {
        if (result) {
          global.showOnlyLoaderDialog();
          global.getDeviceData();
          DeviceInfoLoginModel deviceInfoLoginModel = DeviceInfoLoginModel(
            appId: "2",
            appVersion: global.appVersion,
            deviceId: global.deviceId,
            deviceManufacturer: global.deviceManufacturer,
            deviceModel: global.deviceModel,
            fcmToken: global.fcmToken,
            deviceLocation: "",
          );

          await apiHelper
              .login(phoneNumber, email, deviceInfoLoginModel)
              .then((result) async {
            if (result.status == "200") {
              global.user = result.recordList;
              await global.sp!
                  .setString('currentUser', json.encode(global.user.toJson()));
              log('GLOBALLY SET VALUE ${global.user}');
              log('isverified  ${global.user.isVerified}');

              print('success');
              await global.getCurrentUserId();
              await chatController.getChatList(false);
              await callController.getCallList(true);
              await reportController.getReportList(false);
              await followingController.followingList(false);
              FutureBuilder(
                future: liveAstrologerController.endLiveSession(true),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.connectionState == ConnectionState.done) {
                    if (snapshot.hasError) {
                      debugPrint('error ${snapshot.error}');
                    }
                    debugPrint('Live Session Ended Successfully');
                    return const SizedBox();
                  } else {
                    return const SizedBox();
                  }
                },
              );
              global.hideLoader();
              Get.to(() => const HomeScreen());
            } else if (result.status == "400") {
              global.showToast(message: result.message.toString());
              print('statuscode400 ${result.message.toString()}');
              global.hideLoader(); //ERROR OCCURED HIDE LOADER
              Get.offAll(() =>
                  const LoginScreen()); //REMOVE PREVIOUS SCREEN FROM STACK
            } else {
              global.showToast(message: result.message.toString());
              print('statuscode${result.status}');
              global.hideLoader();
              Get.offAll(() =>
                  const LoginScreen()); //REMOVE PREVIOUS SCREEN FROM STACK
            }
          });
        } else {
          global.showToast(message: 'No network connection!');
        }
      });
      update();
    } catch (e) {
      print('Exception - $screen - loginAstrologer(): ' + e.toString());
    }
  }

//send otp to login
  Future<void> sendLoginOTP(String phoneNumber, String countryCode) async {
    log('full phone no is $countryCode $phoneNumber');
    try {
      await global.checkBody().then((result) {
        if (result) {
          global.showOnlyLoaderDialog();
          global.hideLoader();
          Get.to(() => LoginOtpScreen(
                mobileNumber: phoneNumber,
                countryCode: countryCode,
              ));
          log('Login Screen -> code sent');
        }
      });
    } on Exception catch (e) {
      String errorMessage = 'An error occurred, please try again later.';
      if (e is FirebaseAuthException) {
        String errorCode = e.code;
        switch (errorCode) {
          case 'invalid-verification-code':
            errorMessage = 'The verification code entered is incorrect.';
            break;
          case 'invalid-verification-id':
            errorMessage = 'The verification ID is invalid.';
            break;
          case 'invalid-phone-number':
            errorMessage = 'The phone number is invalid.';
            break;
          case 'too-many-requests':
            errorMessage = 'Too many requests, please try again later.';
            break;
          default:
            // Handle other Firebase authentication errors
            errorMessage =
                'An unexpected error occurred, please try again later.';
        }
        global.showToast(
          message: errorMessage,
        );
        debugPrint("Exception - $screen - sendLoginOTP():" + errorMessage);
      }
    }
    // catch (e) {
    //   print("Exception - $screen - sendLoginOTP():" + e.toString());
    // }
  }
}
