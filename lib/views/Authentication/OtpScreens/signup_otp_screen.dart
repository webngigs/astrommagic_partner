// ignore_for_file: must_be_immutable, avoid_print, deprecated_member_use

import 'dart:developer';
import 'dart:io';

import 'package:astromagic/constants/messageConst.dart';
import 'package:astromagic/controllers/Authentication/signup_controller.dart';
import 'package:astromagic/controllers/Authentication/signup_otp_controller.dart';
import 'package:astromagic/utils/config.dart';
import 'package:astromagic/views/Authentication/OtpScreens/login_otp_screen.dart';
import 'package:astromagic/widgets/app_bar_widget.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:otpless_flutter/otpless_flutter.dart';
import 'package:pinput/pinput.dart';
import 'package:sizer/sizer.dart';
import 'package:astromagic/utils/global.dart' as global;

import '../../../services/apiHelper.dart';
import '../signup_screen.dart';

class SignupOtpScreen extends StatefulWidget {
  String? mobileNumber;
  String? verificationId;

  SignupOtpScreen({super.key, this.mobileNumber, this.verificationId});

  @override
  State<SignupOtpScreen> createState() => _SignupOtpScreenState();
}

class _SignupOtpScreenState extends State<SignupOtpScreen> {
  // final SignupController signupController = Get.find<SignupController>();
  final signupController = Get.find<SignupController>();
  final signupOtpController = Get.find<SignupOtpController>();
  String phoneOrEmail = '';
  String otp = '';
  bool isInitIos = false;
  final otplessFlutterPlugin = Otpless();
  APIHelper apihelper = APIHelper();
  final pinEditingControllersignup = TextEditingController(text: '');
  late final FocusNode focusNode;

  @override
  void initState() {
    super.initState();
    focusNode = FocusNode();

    // if (Platform.isAndroid) {
    //   otplessFlutterPlugin.initHeadless(OtplessappId);
    //   otplessFlutterPlugin.setHeadlessCallback(onHeadlessResultloginotp);

    //   debugPrint("init headless sdk is called for android");
    // }
  }

  Future<void> verfiyHeadlesswithOtp(
      String phoneno, String countrycode, String otp) async {
    if (Platform.isIOS && !isInitIos) {
      log('SignupOtpScreen Initializing headless SDK for iOS');
      otplessFlutterPlugin.initHeadless(OtplessappId);
      isInitIos = true;
      debugPrint("init headless sdk is called for ios");
      return;
    }
    log('SignupOtpScreen response otp is $otp');
    Map<String, dynamic> arg = {};
    arg["phone"] = phoneno;
    arg["countryCode"] = countrycode;
    arg["otp"] = otp;
    print('response otp arg $arg');
    otplessFlutterPlugin.startHeadless(onHeadlessResultloginotp, arg);
  }

  void onHeadlessResultloginotp(dynamic response) async {
    log('SignupOtpScreen response otp response $response');
    Map<String, dynamic> otpresponse = response;
    dynamic statuscode = otpresponse['statusCode'];
    if (statuscode == 200) {
      String otptoken = otpresponse['response']['token'];
      log('SignupOtpScreen response otp Otptoken $otptoken');
      global.hideLoader();

      signupController.onStepNext();
      Get.to(() => const SignupScreen());
    } else if (statuscode == 400) {
      global.showToast(message: 'invalid otp');
    } else {
      log('otp error is $otpresponse');
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.grey[100],
        appBar: MyCustomAppBar(
          leading: IconButton(
            onPressed: () {
              Get.back();
            },
            icon: const Icon(
              Icons.arrow_back_ios,
              size: 20,
              color: Colors.black,
            ),
          ),
          height: 80,
          elevation: 0.5,
          appbarPadding: 0,
          title: const Text(
            MessageConstants.VERIFY_PHONE,
            style: TextStyle(
                color: Colors.black, fontWeight: FontWeight.w300, fontSize: 19),
          ).tr(),
          backgroundColor: Colors.grey[100],
        ),
        body: Center(
          child: SizedBox(
            width: Get.width - Get.width * 0.1,
            child: Padding(
              padding: const EdgeInsets.only(top: 30.0),
              child: Column(
                children: [
                  Text(
                    'OTP Send to',
                    style: TextStyle(color: Colors.green, fontSize: 11.sp),
                  ).tr(args: [
                    signupOtpController.countryCode.toString(),
                    widget.mobileNumber.toString()
                  ]),
                  const SizedBox(
                    height: 30,
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
                        signupController.smsCode = pin;
                        signupController.update();
                        log('smscode from : ${signupController.smsCode}');
                      },
                      onChanged: (pin) {
                        signupController.smsCode = pin;
                        signupController.update();
                        log('smscode from : ${signupController.smsCode}');
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
                  //   height: 50,
                  //   child: PinInputTextField(
                  //     pinLength: 6,
                  //     decoration: BoxLooseDecoration(
                  //       strokeColorBuilder: PinListenColorBuilder(
                  //           Colors.grey.shade400, Colors.grey.shade400),
                  //     ),
                  //     controller: pinEditingControllersignup,
                  //     textInputAction: TextInputAction.done,
                  //     enabled: true,
                  //     cursor: Cursor(
                  //       enabled: true,
                  //       width: 2.0,
                  //       color: Colors.black,
                  //     ),
                  //     keyboardType: TextInputType.number,
                  //     onSubmit: (pin) {
                  //       signupController.smsCode = pin;
                  //       signupController.update();
                  //       log('smscode from signup : ${signupController.smsCode}');
                  //     },
                  //     onChanged: (pin) {
                  //       signupController.smsCode = pin;
                  //       signupController.update();
                  //       debugPrint('onChanged execute. pin:$pin');
                  //     },
                  //     enableInteractiveSelection: false,
                  //   ),
                  // child: OtpTextField(
                  //   mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  //   numberOfFields: 6,
                  //   showFieldAsBox: true,
                  //   onSubmit: (value) {
                  //     signupController.smsCode = value;
                  //     signupController.update();
                  //     print('smscode from : ${signupController.smsCode}');
                  //   },
                  //   onCodeChanged: (value) {},
                  //   filled: true,
                  //   fillColor: Colors.white,
                  //   fieldWidth: 48,
                  //   borderColor: Colors.transparent,
                  //   enabledBorderColor: Colors.transparent,
                  //   focusedBorderColor: Colors.transparent,
                  //   borderRadius: BorderRadius.circular(10),
                  //   margin: const EdgeInsets.only(right: 4),
                  // ),
                  //  ),
                  const SizedBox(
                    height: 15,
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        FocusScope.of(context).unfocus();
                        global.showOnlyLoaderDialog();

                        log('phoen no is ${signupController.cMobileNumber.text} and country code is ${signupController.countryCode} and otp is ${signupController.smsCode}');
                        verfiyHeadlesswithOtp(
                          signupController.cMobileNumber.text,
                          signupController.countryCode,
                          signupController.smsCode,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          side:
                              const BorderSide(width: 0.5, color: Colors.grey),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.all(12),
                        backgroundColor: Get.theme.primaryColor,
                        textStyle:
                            const TextStyle(fontSize: 18, color: Colors.black),
                      ),
                      child: const Text(
                        MessageConstants.VERIFY_OTP,
                        style: TextStyle(color: Colors.black),
                      ).tr(),
                    ),
                  ),
                  const SizedBox(
                    height: 15,
                  ),
                  GetBuilder<SignupOtpController>(builder: (c) {
                    return SizedBox(
                        child: signupOtpController.maxSecond != 0
                            ? Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Resend OTP Available in',
                                    style: TextStyle(
                                        color: Colors.green,
                                        fontWeight: FontWeight.w500),
                                  ).tr(args: [
                                    signupOtpController.maxSecond.toString()
                                  ])
                                ],
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                    const Text(
                                      'Resend OTP Available',
                                      style: TextStyle(
                                          color: Colors.green,
                                          fontWeight: FontWeight.w500),
                                    ).tr(),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        ElevatedButton(
                                          onPressed: () {
                                            signupOtpController.maxSecond = 60;
                                            signupOtpController.second = 0;
                                            signupOtpController.update();
                                            signupOtpController.timer();
                                            signupController.cMobileNumber
                                                .text = widget.mobileNumber!;
                                            // signupOtpController.verifyOTP();
                                            log('Resend otp clicked mobile no is ${widget.mobileNumber} and country code is ${signupController.countryCode}');
                                            signupController
                                                .startHeadlesswithOtp(
                                              signupController
                                                  .cMobileNumber.text,
                                              signupController
                                                  .countryCode, //Country cdoe
                                            );
                                            print('Resend otp');
                                          },
                                          style: ButtonStyle(
                                            shape: MaterialStateProperty.all(
                                              RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                            ),
                                            padding: MaterialStateProperty.all(
                                                const EdgeInsets.only(
                                                    left: 25, right: 25)),
                                            backgroundColor:
                                                MaterialStateProperty.all(
                                                    Get.theme.primaryColor),
                                            textStyle:
                                                MaterialStateProperty.all(
                                                    const TextStyle(
                                                        fontSize: 12,
                                                        color: Colors.black)),
                                          ),
                                          child: const Text(
                                            'Resend OTP on SMS',
                                            style:
                                                TextStyle(color: Colors.black),
                                          ).tr(),
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
    );
  }
}
