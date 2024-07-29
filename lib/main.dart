// ignore_for_file: use_key_in_widget_constructors, library_private_types_in_public_api, avoid_print

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phone_state/phone_state.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(CallDurationApp());
}

class CallDurationApp extends StatefulWidget {
  @override
  _CallDurationAppState createState() => _CallDurationAppState();
}

class _CallDurationAppState extends State<CallDurationApp> {
  static const platform = MethodChannel('com.example.call_duration');
  bool isReleaseMode = false;
  PhoneStateStatus status = PhoneStateStatus.NOTHING;
  DateTime? callStartTime;
  Duration callDuration = Duration.zero;
  DateTime? ringingTime;

  @override
  void initState() {
    super.initState();
    initializeIsReleaseMode();
    requestPermissions();
  }

  Future<void> requestPermissions() async {
    final status = await Permission.phone.status;
    if (!status.isGranted) {
      final result = await Permission.phone.request();
      if (result.isDenied || result.isPermanentlyDenied) {
        // Handle permission denied scenarios
        print('Permission denied');
        return;
      }
    }
    initializePhoneState();
  }

  Future<void> initializeIsReleaseMode() async {
    if (Platform.isIOS) {
      final isReleaseModeResult =
          await platform.invokeMethod<bool>('isReleaseMode');
      setState(() {
        isReleaseMode = isReleaseModeResult ?? false;
      });
    }
  }

  void initializePhoneState() {
    PhoneState.stream.listen((PhoneState phoneState) {
      setState(() {
        status = phoneState.status;
        if (isReleaseMode && status == PhoneStateStatus.CALL_INCOMING) {
          ringingTime = DateTime.now();
        } else if (status == PhoneStateStatus.CALL_STARTED) {
          print('Call started');
          callStartTime = DateTime.now();
        } else if (status == PhoneStateStatus.CALL_ENDED &&
            callStartTime != null) {
          final callEndTime = DateTime.now();
          if (isReleaseMode) {
            callDuration = callEndTime.difference(ringingTime!);
          } else {
            callDuration = callEndTime.difference(callStartTime!);
          }
          callStartTime = null;
          ringingTime = null;
        }
      });
    });
  }

  Color getColorBasedOnDuration(int duration) {
    if (duration <= 30) {
      return const Color(0xFFBFA2DB);
    } else {
      return const Color.fromARGB(255, 90, 47, 133);
      
    }
  }

  String formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$hours:$minutes:$seconds';
  }

   @override
  Widget build(BuildContext context) {
    final durationInSeconds = callDuration.inSeconds % 60; // Reset each minute
    const maxDuration = 60; // Max duration for the progress indicator
    final progress = durationInSeconds / maxDuration;
    final formattedDuration = formatDuration(callDuration);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xFFF3F1F5),
        appBar: AppBar(
          title: const Text('Phone Call Duration Capturer',),
          backgroundColor: const Color(0xFFF0D9FF),        
          foregroundColor: const Color.fromARGB(255, 65, 64, 64),
        ),
        body: Center(

          child: status == PhoneStateStatus.CALL_ENDED
              ? Column(
                  
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 400,
                      height: 400,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [ SizedBox(width: 300, height: 300, child:
                          CircularProgressIndicator( 
                            value: progress,
                            strokeWidth: 30.0,
                            valueColor: AlwaysStoppedAnimation<Color>(
                                getColorBasedOnDuration(durationInSeconds)),
                            backgroundColor: const Color.fromARGB(255, 223, 221, 224),
                          )),
                          Text(
                            formattedDuration,
                            style: const TextStyle(fontSize: 40, color: Color.fromARGB(255, 65, 64, 64)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                  ],
                )
              : status == PhoneStateStatus.CALL_INCOMING
              ? const Center(child: Text('You have an incoming call...', style: TextStyle(fontSize: 25, color: Color.fromARGB(255, 65, 64, 64)),)):
              const Center(child: Text('Waiting for call...', style: TextStyle(fontSize: 25, color: Color.fromARGB(255, 65, 64, 64)),)),
        ),
      ),
    );
  }
}
