// ignore_for_file: must_be_immutable, avoid_print

import 'dart:developer';
import 'dart:io';

import 'package:astrommagic/services/apiHelper.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:otpless_flutter/otpless_flutter.dart';
import 'package:pinput/pinput.dart';
import 'package:sizer/sizer.dart';

import '../../../constants/messageConst.dart';
import '../../../controllers/Authentication/login_controller.dart';
import '../../../controllers/Authentication/login_otp_controller.dart';
import '../../../controllers/Authentication/signup_controller.dart';
import '../../../utils/config.dart';
import '../../../widgets/app_bar_widget.dart';
import 'package:astrommagic/utils/global.dart' as global;

import '../login_screen.dart';

const borderColor = Color.fromRGBO(114, 178, 238, 1);
const errorColor = Color.fromRGBO(255, 234, 238, 1);
const fillColor = Color.fromRGBO(222, 231, 240, .57);
final defaultPinTheme = PinTheme(
  width: 65,
  height: 65,
  textStyle: const TextStyle(
    fontSize: 18,
    color: Color.fromRGBO(30, 60, 87, 1),
  ),
  decoration: BoxDecoration(
    color: fillColor,
    borderRadius: BorderRadius.circular(8),
    border: Border.all(color: Colors.grey[400]!, width: 0.7),
  ),
);

final focusedPinTheme = defaultPinTheme.copyDecorationWith(
  border: Border.all(color: const Color.fromRGBO(114, 178, 238, 1)),
  borderRadius: BorderRadius.circular(8),
);

final pinEditingController = TextEditingController(text: '');
const focusedBorderColor = Color.fromRGBO(23, 171, 144, 1);

class LoginOtpScreen extends StatefulWidget {
  String? mobileNumber;
  String? verificationId;
  String? countryCode;

  LoginOtpScreen({
    super.key,
    this.mobileNumber,
    this.verificationId,
    this.countryCode,
  });

  @override
  State<LoginOtpScreen> createState() => _LoginOtpScreenState();
}

class _LoginOtpScreenState extends State<LoginOtpScreen> {
  final loginOtpController = Get.find<LoginOtpController>();
  final loginController = Get.find<LoginController>();
  final signupController = Get.find<SignupController>();
  String phoneOrEmail = '';
  String otp = '';
  bool isInitIos = false;
  final otplessFlutterPlugin = Otpless();
  APIHelper apihelper = APIHelper();
  bool? solidEnable = false;
  TextEditingController pinEditingController = TextEditingController(text: '');
  late final FocusNode focusNode;
  @override
  void initState() {
    super.initState();
    loginOtpController.timer();
    focusNode = FocusNode();
    if (Platform.isAndroid) {
      otplessFlutterPlugin.initHeadless(OtplessappId);
      otplessFlutterPlugin.setHeadlessCallback(onHeadlessResultloginotp);

      debugPrint("init headless sdk is called for android");
    }
  }

  Future<void> verfiyHeadlesswithOtp(
      String phoneno, String countrycode, String otp) async {
    loginOtpController.phonenois = phoneno;
    loginOtpController.countrycodeis = countrycode;
    loginOtpController.update();
    if (Platform.isIOS && !isInitIos) {
      otplessFlutterPlugin.initHeadless(OtplessappId);
      isInitIos = true;
      debugPrint("init headless sdk is called for ios");
      return;
    }
    Map<String, dynamic> arg = {};
    arg["phone"] = phoneno;
    arg["countryCode"] = countrycode;
    arg["otp"] = otp;
    print('response otp arg $arg');
    otplessFlutterPlugin.startHeadless(onHeadlessResultloginotp, arg);
  }

  Future<void> startHeadlesswithOtp(String phoneno, String countrycode) async {
    log('start sending otp $phoneno  and $countrycode');

    if (Platform.isIOS && !isInitIos) {
      otplessFlutterPlugin.initHeadless(OtplessappId);
      otplessFlutterPlugin.setHeadlessCallback(
        (result) {
          onHeadlessResultloginotp(result);
        },
      );
      isInitIos = true;
      return;
    }
    Map<String, dynamic> arg = {};
    arg["phone"] = phoneno;
    arg["countryCode"] = countrycode;
    log('arg is $arg');
    otplessFlutterPlugin.startHeadless((result) {
      onHeadlessResultloginotp(result);
    }, arg);
  }

  void onHeadlessResultloginotp(dynamic response) async {
    log('response otp response $response');
    global.hideLoader();

    Map<String, dynamic> otpresponse = response;

    dynamic statuscode = otpresponse['statusCode'];
    log('login otp statuscode->  $statuscode');
    log('login otp response->  $response');
    log('login otp response->  ${otpresponse['response']}');

    if (statuscode == 200) {
      String otptoken = otpresponse['response']['token'];
      log('login otp Otptoken->  $otptoken');
      if (otptoken.isNotEmpty) {
        await global.checkBody().then(
          (result) async {
            if (result) {
              global.showOnlyLoaderDialog();
              await apihelper.otpResponseOptless(otpresponse).then((phoneno) {
                global.hideLoader();
                // log('phone is $phoneno');
                if (phoneno != null) {
                  loginController.loginAstrologer(
                      phoneNumber: phoneno, email: '');
                } else {
                  log('onHeadlessResult phone no is null');
                }
              });
            }
          },
        );
      } else {
        // Get.offAll(() => const LoginScreen());
        log('otp token not found error otpscreen verified');
        global.showToast(message: 'Invalid token try again');
      }
    } else {
      if (statuscode == 400) {
        global.showToast(message: 'Invalid otp');
      }
      log('otp error is $otpresponse');
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Get.offAll(() => const LoginScreen());
        return true;
      },
      child: SafeArea(
        child: Scaffold(
          backgroundColor: Colors.grey[100],
          appBar: MyCustomAppBar(
            leading: IconButton(
              onPressed: () {
                log('backpress to otpscreen');
                Get.offAll(() => const LoginScreen());
              },
              icon: Icon(
                Icons.arrow_back_ios,
                size: 18.sp,
                color: Colors.black,
              ),
            ),
            height: 10.h,
            elevation: 0.5,
            appbarPadding: 0,
            title: Text(
              MessageConstants.VERIFY_PHONE,
              style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w300,
                  fontSize: 14.sp),
            ).tr(),
            backgroundColor: Colors.grey[100],
          ),
          body: Center(
            child: SizedBox(
              width: 100.w,
              child: Padding(
                padding: EdgeInsets.only(top: 5.h),
                child: Column(
                  children: [
                    Text(
                      'OTP Send to',
                      style: TextStyle(color: Colors.green, fontSize: 11.sp),
                    ).tr(args: [
                      widget.countryCode.toString(),
                      widget.mobileNumber.toString()
                    ]),
                    SizedBox(
                      height: 3.h,
                    ),
                    SizedBox(
                      height: 6.h,
                      width: 90.w,
                      child: Pinput(
                        controller: pinEditingController,
                        focusNode: focusNode,
                        defaultPinTheme: defaultPinTheme,
                        length: 6,
                        separatorBuilder: (index) => const SizedBox(width: 8),
                        hapticFeedbackType: HapticFeedbackType.lightImpact,
                        onCompleted: (pin) {
                          loginOtpController.smsCode = pin;
                          loginOtpController.update();
                          log('smscode from : ${loginOtpController.smsCode}');
                        },
                        onChanged: (pin) {
                          loginOtpController.smsCode = pin;
                          loginOtpController.update();
                          log('smscode from : ${loginOtpController.smsCode}');
                        },
                        cursor: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 2,
                              height: 3.h,
                              decoration: BoxDecoration(
                                color: borderColor,
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ],
                        ),
                        focusedPinTheme: focusedPinTheme,
                        errorPinTheme: defaultPinTheme.copyBorderWith(
                          border: Border.all(color: Colors.redAccent),
                        ),
                      ),
                    ),
                    // SizedBox(
                    //   height: 6.h,
                    //   width: 90.w,
                    //   child: PinInputTextField(
                    //     pinLength: 6,
                    //     decoration: BoxLooseDecoration(
                    //       strokeColorBuilder: PinListenColorBuilder(
                    //           Colors.grey.shade400, Colors.grey.shade400),
                    //     ),
                    //     controller: pinEditingController,
                    //     textInputAction: TextInputAction.done,
                    //     enabled: true,
                    //     cursor: Cursor(
                    //       enabled: true,
                    //       width: 2.0,
                    //       color: Colors.black,
                    //     ),
                    //     keyboardType: TextInputType.number,
                    //     onSubmit: (pin) {
                    //       loginOtpController.smsCode = pin;
                    //       loginOtpController.update();
                    //       log('smscode from : ${loginOtpController.smsCode}');
                    //     },
                    //     onChanged: (pin) {
                    //       loginOtpController.smsCode = pin;
                    //       loginOtpController.update();
                    //       debugPrint('onChanged execute. pin:$pin');
                    //     },
                    //     enableInteractiveSelection: false,
                    //   ),
                    // ),
                    SizedBox(
                      height: 5.h,
                    ),
                    SizedBox(
                      width: 90.w,
                      child: ElevatedButton(
                        onPressed: () {
                          global.showOnlyLoaderDialog();

                          verfiyHeadlesswithOtp(
                            widget.mobileNumber!,
                            widget.countryCode!,
                            loginOtpController.smsCode,
                          );
                          loginOtpController.update();
                        },
                        style: ElevatedButton.styleFrom(
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            side: const BorderSide(
                                width: 0.5, color: Colors.grey),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.all(12),
                          backgroundColor: Get.theme.primaryColor,
                          textStyle:
                              TextStyle(fontSize: 12.sp, color: Colors.black),
                        ),
                        child: const Text(
                          MessageConstants.SUBMIT_CAPITAL,
                          style: TextStyle(color: Colors.black),
                        ).tr(),
                      ),
                    ),
                    SizedBox(
                      height: 2.h,
                    ),
                    GetBuilder<LoginOtpController>(builder: (c) {
                      return loginOtpController.maxSecond != 0
                          ? Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: EdgeInsets.only(left: 5.w),
                                  child: Text(
                                    'Resend OTP Available in',
                                    style: TextStyle(
                                        color: Colors.green,
                                        fontWeight: FontWeight.w500,
                                        fontSize: 11.sp),
                                  ).tr(args: [
                                    loginOtpController.maxSecond.toString()
                                  ]),
                                )
                              ],
                            )
                          : SizedBox(
                              child: Column(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                  Padding(
                                    padding: EdgeInsets.only(left: 5.w),
                                    child: Text(
                                      'Resend OTP Available',
                                      style: TextStyle(
                                          color: Colors.green,
                                          fontWeight: FontWeight.w500,
                                          fontSize: 11.sp),
                                    ).tr(),
                                  ),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Padding(
                                        padding: EdgeInsets.only(left: 5.w),
                                        child: ElevatedButton(
                                          onPressed: () {
                                            String phoneNumber =
                                                loginOtpController
                                                    .cMobileNumber.text;

                                            global.showOnlyLoaderDialog();
                                            //RESET TIMER
                                            loginOtpController.maxSecond = 0;
                                            loginOtpController.timer();

                                            phoneNumber.isNotEmpty
                                                ? startHeadlesswithOtp(
                                                    phoneNumber,
                                                    loginOtpController
                                                        .countryCode,
                                                  )
                                                : global.showToast(
                                                    message: tr(
                                                        'Please enter mobile number'));
                                          },
                                          style: ButtonStyle(
                                            shape: WidgetStateProperty.all(
                                              RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                            ),
                                            padding: WidgetStateProperty.all(
                                                const EdgeInsets.only(
                                                    left: 25, right: 25)),
                                            backgroundColor:
                                                WidgetStateProperty.all(
                                                    Get.theme.primaryColor),
                                            textStyle: WidgetStateProperty.all(
                                                const TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.black)),
                                          ),
                                          child: Text(
                                            'Resend OTP on SMS',
                                            style: TextStyle(
                                              color: Colors.black,
                                              fontSize: 11.sp,
                                            ),
                                          ).tr(),
                                        ),
                                      ),
                                    ],
                                  )
                                ]));
                    })
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
