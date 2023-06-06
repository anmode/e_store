import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import '../res/components/custom_button.dart';


class ChatModel {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static FlutterSoundRecorder flutterSoundRecorder = FlutterSoundRecorder();
  static String pathToSaveAudion = 'audio_example.aac';
  static final FlutterSoundPlayer player = FlutterSoundPlayer();
  static String voiceChatId = '';
  static final FlutterSoundRecorder voiceRecorder = FlutterSoundRecorder();

  static Future startRecording()async{
    voiceChatId = DateTime.now().microsecondsSinceEpoch.toString();
    await voiceRecorder.startRecorder(
      toFile: voiceChatId,
    );
    print('recording started');
  }

  static Future stopRecording()async{
    final path = await voiceRecorder.stopRecorder();
    final audioPath = File(path!);
    print('recording stopped');
    return audioPath;
  }

  static Future playVoiceMessage(String fileUrl, VoidCallback whenFinished) async {
    await player.startPlayer(
        fromURI: fileUrl,
        whenFinished: whenFinished
    );
    print('audio playback started');
  }

  static Future stopVoiceMessage() async {
    await player.stopPlayer();
    print('audio playback started');
  }

  static Future toggleVoiceMessage({required String fileUrl, required VoidCallback whenFinished}) async {
    if (player.isPlaying) {
      await stopVoiceMessage();
    } else {
      await playVoiceMessage(fileUrl,whenFinished);
    }
  }

  static void askForMicrophonePermission(context) async {
    final PermissionStatus permissionStatus =
        await Permission.microphone.status;
    if (!permissionStatus.isGranted) {
      bool status = await Permission.microphone.request().isGranted;
      if(!status){
        showDialog(
            context: context,
            builder: (_) => AlertDialog(
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              content: const Text('App requires microphone permissions.'),
              actions: [
                CustomButton(
                    height: 35,
                    width: 130,
                    text: 'No thanks',
                    onPressed: (){
                      Navigator.pop(context);
                    }),
                CustomButton(
                    height: 35,
                    width: 130,
                    text: 'Open settings',
                    onPressed: (){
                      openAppSettings();
                    }),
              ],
            ));
      }

    } else {
      print('it should work now');
    }
  }

  static sentChatMessage(
      {required bool isVoiceMessage, required String message, required dynamic productDocs}) {
    DateTime now = DateTime.now();
    String formattedDateTime = DateFormat.MMMd().add_jm().format(now);
    String customFormattedDateTime = formattedDateTime.replaceAll(',', ' at');

    final id = (_auth.currentUser!.uid +
            productDocs['productId'] +
            productDocs['uid'])
        .split('')
      ..sort()
      ..join();
    final doc = _firestore.collection('conversations').doc(id.toString());
    doc.get().then((value) {
      if (value.exists) {
        doc.update({
          "messages": FieldValue.arrayUnion([
            {
              "sender": _auth.currentUser!.uid,
              isVoiceMessage ? "voiceMessage" : "message": message,
              "time": customFormattedDateTime,
            }
          ]),
        });
      } else {
        doc.set({
          "members": [_auth.currentUser!.uid, productDocs['uid']],
          "productId": productDocs['productId'],
          "productName": productDocs['title'],
          "imageUrl": productDocs['imageUrl'],
          'userName': productDocs['name'],
          "messages": [
            {
              "sender": _auth.currentUser!.uid,
              isVoiceMessage ? "voiceMessage" : "message" : message,
              "time": customFormattedDateTime,
            }
          ],
        });
      }
    });
  }
}
