// ignore_for_file: file_names, non_constant_identifier_names

import 'dart:async';
import 'dart:developer';

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:astrowaypartner/controllers/HomeController/wallet_controller.dart';
import 'package:astrowaypartner/views/HomeScreen/home_screen.dart';
import 'package:draggable_widget/draggable_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_countdown_timer/index.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:sizer/sizer.dart';
import 'package:astrowaypartner/utils/global.dart' as global;

import '../../../../controllers/HomeController/call_controller.dart';
import '../../../../services/apiHelper.dart';
import '../../../../utils/global.dart';
import 'AgoraEventHandler.dart';
import 'Agrommanager.dart';
import 'cohost_screen.dart';
import 'host_screen.dart';

class OneToOneLiveScreen extends StatefulWidget {
  final int id;
  final String name;
  final String profile;
  final int callId;
  final String fcmToken;
  final String call_duration;

  const OneToOneLiveScreen(
      {super.key,
      required this.id,
      required this.name,
      required this.profile,
      required this.callId,
      required this.fcmToken,
      required this.call_duration});

  @override
  State<OneToOneLiveScreen> createState() => OneToOneLiveScreenState();
}

class OneToOneLiveScreenState extends State<OneToOneLiveScreen> {
  ValueNotifier<bool> isMuted = ValueNotifier(false);
  ValueNotifier<bool> isSpeaker = ValueNotifier(true);
  ValueNotifier<bool> isImHost = ValueNotifier(false);
  ValueNotifier<bool> isJoined = ValueNotifier(false);
  ValueNotifier<int?> remoteUid = ValueNotifier(null);
  final callController = Get.find<CallController>();
  final dragController = DragController();
  final walletController = Get.put(WalletController());
  late RtcEngine agoraEngine; // Agora engine instance
  late AgoraEventHandler agoraEventHandler;
  CountdownTimer? countdownTimer;
  final apiHelper = APIHelper();
  var uid = 0;
  int conneId = 0;

  @override
  void initState() {
    debugPrint(
        'one to one live call id ${widget.callId}, name ${widget.name}, profile ${widget.profile} callid ${widget.callId}, fcm ${widget.fcmToken}');
    super.initState();
    clearList();

    generateToken();
    initagora();
  }

  @override
  void dispose() {
    clearList();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        global.showToast(
          message: 'You must end the call to exit the live streaming session.',
        );
      },
      child: Scaffold(
          backgroundColor: Colors.black,
          body: ValueListenableBuilder(
            valueListenable: isJoined,
            builder: (BuildContext context, bool isJoin, Widget? child) =>
                ValueListenableBuilder(
              valueListenable: isImHost,
              builder: (BuildContext context, bool meHost, Widget? child) =>
                  Stack(
                children: [
                  SizedBox(
                    height: 100.h,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        //IS USER JOINED LAYOUT
                        isJoin
                            ? SizedBox(
                                width: double.infinity,
                                height: 100.h,
                                child: CoHostWidget(
                                  remoteUid: remoteUid.value,
                                  agoraEngine: agoraEngine,
                                ),
                                //CO-HOST VIDEO
                              )
                            : const Center(
                                child: CircularProgressIndicator(
                                  color: Colors.amberAccent,
                                ),
                              )
                      ],
                    ),
                  ),
                  //IS IM HOST YES
                  meHost
                      ? DraggableWidget(
                          intialVisibility: true,
                          horizontalSpace: 2.h,
                          verticalSpace: 10.h,
                          shadowBorderRadius: 10.h,
                          initialPosition: AnchoringPosition.topLeft,
                          dragController: dragController,
                          child: SizedBox(
                            height: 25.h,
                            width: 35.w,
                            //HOST CHILD
                            child:
                                HostWidget(uid: uid, agoraEngine: agoraEngine),
                          ))
                      : Center(
                          child: Text('Im host-->s $meHost'),
                        ),

                  //BOTTOM BAR MUTE CALL DISCONNECT SPEAKER
                  Positioned(
                    bottom: 0,
                    left: 0,
                    child: SizedBox(
                      height: 10.h,
                      width: 100.w,
                      child: Row(children: [
                        Expanded(
                          child: SizedBox(
                            height: 10.h,
                            child: Center(
                              child: InkWell(
                                onTap: () {
                                  isMuted.value = !isMuted.value;
                                  log('mute Audio is ${isMuted.value}');
                                  AgoraManager().muteVideoCall(
                                      isMuted.value, agoraEngine);
                                },
                                child: ValueListenableBuilder(
                                  valueListenable: isMuted,
                                  builder: (BuildContext context, bool meMuted,
                                          Widget? child) =>
                                      CircleAvatar(
                                    radius: 3.h,
                                    backgroundColor: meMuted
                                        ? Colors.black12
                                        : Colors.black38,
                                    child: FaIcon(
                                      meMuted
                                          ? FontAwesomeIcons.microphoneSlash
                                          : FontAwesomeIcons.microphone,
                                      color:
                                          meMuted ? Colors.blue : Colors.white,
                                      size: 15.sp,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(bottom: 2.h),
                            child: SizedBox(
                              height: 10.h,
                              child: InkWell(
                                onTap: () async {
                                  await walletController.getAmountList();

                                  leaveVideoCall();
                                },
                                child: SizedBox(
                                  width: 100.w,
                                  height: 6.h,
                                  child: Center(
                                    child: CircleAvatar(
                                      radius: 3.h,
                                      backgroundColor: Colors.red,
                                      child: Icon(
                                        Icons.call_end,
                                        color: Colors.white,
                                        size: 20.sp,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: SizedBox(
                            height: 10.h,
                            child: Center(
                              child: Padding(
                                padding: EdgeInsets.only(bottom: 2.h),
                                child: InkWell(
                                  onTap: () {
                                    isSpeaker.value = !isSpeaker.value;
                                    AgoraManager()
                                        .onVolume(isSpeaker.value, agoraEngine);
                                  },
                                  child: ValueListenableBuilder(
                                    valueListenable: isSpeaker,
                                    builder: (BuildContext context,
                                            bool meSpeaker, Widget? child) =>
                                        CircleAvatar(
                                      radius: 3.h,
                                      backgroundColor: meSpeaker
                                          ? Colors.black12
                                          : Colors.black38,
                                      child: Icon(
                                        meSpeaker
                                            ? FontAwesomeIcons.volumeHigh
                                            : FontAwesomeIcons.volumeLow,
                                        color: meSpeaker
                                            ? Colors.blue
                                            : Colors.white,
                                        size: 20.sp,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ]),
                    ),
                  ),

                  Positioned(
                    top: 3.h,
                    left: 36.w,
                    child: ValueListenableBuilder(
                      valueListenable: isJoined,
                      builder:
                          (BuildContext context, bool isJoin, Widget? child) =>
                              isJoin ? startTimer() : const SizedBox(),
                    ),
                  )
                ],
              ),
            ),
          )),
    );
  }

  CountdownTimer startTimer() {
    return CountdownTimer(
      endTime: DateTime.now().millisecondsSinceEpoch +
          1000 * int.parse(widget.call_duration),
      widgetBuilder: (_, CurrentRemainingTime? time) {
        if (time == null) {
          return Text(
            '00 min 00 sec',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.black,
              fontSize: 12.sp,
            ),
          );
        }
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(5),
          ),
          child: time.hours != null && time.hours != 0
              ? Text(
                  '${time.hours! <= 9 ? '0${time.hours}' : time.hours ?? '00'}:${time.min! <= 9 ? '0${time.min}' : time.min ?? '00'}:${time.sec! <= 9 ? '0${time.sec}' : time.sec}',
                  style: TextStyle(
                      fontWeight: FontWeight.w400,
                      fontSize: 16.sp,
                      color: Colors.black),
                )
              : time.min != null
                  ? Text(
                      '${time.min! <= 9 ? '0${time.min}' : time.min ?? '00'}:${time.sec! <= 9 ? '0${time.sec}' : time.sec}',
                      style: TextStyle(
                          fontWeight: FontWeight.w400,
                          fontSize: 16.sp,
                          color: Colors.black),
                    )
                  : Text(
                      '${time.sec! <= 9 ? '0${time.sec}}' : time.sec}',
                      style: TextStyle(
                          fontWeight: FontWeight.w400,
                          fontSize: 16.sp,
                          color: Colors.black),
                    ),
        );
      },
      onEnd: () {
        AgoraManager().leave(agoraEngine,
            onchannelLeaveCallback: (isLiveEnded) {
          if (isLiveEnded) {
            // LIVE SESSION ENDED GOTO PREVIOUS SCREEN
            Get.back();
          }
        });
      },
    );
  }

  void handler() {
    agoraEventHandler.handleEvent(agoraEngine);
  }

  void initagora() async {
    agoraEngine = await AgoraManager().initializeAgora(
        global.getSystemFlagValue(global.systemFlagNameList.agoraAppId));
    AgoraManager().joinChannel(
        global.agoraLiveToken, global.agoraLiveChannelName, agoraEngine);

    agoraEventHandler = AgoraEventHandler(
      onJoinChannelSuccessCallback: (isHost, localUid) {
        isImHost.value = isHost;
        conneId = localUid!;
      },
      onUserJoinedCallback: (remoteId, isJoin) {
        isJoined.value = isJoin!;
        remoteUid.value = remoteId;

        apiHelper.setAstrologerOnOffBusyline("Busy");
      },
      onUserMutedCallback: (remoteUid3, muted) {
        log('Is muted->  $muted');
        if (remoteUid.value == remoteUid3) {
          if (muted == true) {
            isImHost.value = true;
            log('isimHost in onUserMuteVideo muted $isImHost');
          } else {
            isImHost.value = true;
            log('isimHost in onUserMuteVideo mutede else $isImHost');
          }
        }
      },
      onUserOfflineCallback: (id, reason) {
        debugPrint("User is Offiline reasion is -> $reason");
        remoteUid.value = null;
        apiHelper.setAstrologerOnOffBusyline("Online");

        if (reason == UserOfflineReasonType.userOfflineQuit) {
          AgoraManager().leave(agoraEngine,
              onchannelLeaveCallback: (isLiveEnded) {
            if (isLiveEnded) {
              Get.offAll(() => const HomeScreen());
            }
          });
        } else if (reason == UserOfflineReasonType.userOfflineDropped) {
          AgoraManager().leave(agoraEngine,
              onchannelLeaveCallback: (isLiveEnded) {
            if (isLiveEnded) {
              Get.offAll(() => const HomeScreen());
            }
          });
        }
      },
      onLeaveChannelCallback: (con, sc) {
        apiHelper.setAstrologerOnOffBusyline("Online");

        debugPrint("onLeaveChannel called id- >${con.localUid}");
        isJoined.value = false;
        remoteUid.value = null;
      },
      onAgoraError: (err, msg) {
        log('error agora - $err  and msg is - $msg');
      },
    );

    handler();
  }

  Future generateToken() async {
    try {
      global.agoraLiveChannelName = '${global.liveChannelName}_${widget.id}';

      await liveAstrologerController.getRitcToken(
          global.getSystemFlagValue(global.systemFlagNameList.agoraAppId),
          global.getSystemFlagValue(
              global.systemFlagNameList.agoraAppCertificate),
          "$uid",
          global.agoraLiveChannelName);

      await callController.sendCallToken(
          global.agoraLiveToken, global.agoraLiveChannelName, widget.callId);
    } catch (e) {
      debugPrint("Exception in getting token: ${e.toString()}");
    }
  }

  void leaveVideoCall() {
    debugPrint('leave video call click ');
    AgoraManager().leave(
      agoraEngine,
      onchannelLeaveCallback: (isLiveEnded) {
        if (isLiveEnded) {
          apiHelper.setAstrologerOnOffBusyline("Online");
          debugPrint('leave done ');

          Get.offAll(() => const HomeScreen());
        } else {
          log('live not ended');
          Get.offAll(() => const HomeScreen());
        }
      },
    );
  }

  void clearList() async {
    callController.callList.removeWhere((call) => call.callId == widget.callId);
    callController.callList.clear();
    callController.update();
    await callController.getCallList(false);
  }
}
