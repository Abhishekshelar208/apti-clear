package com.example.apticlear;

import android.os.Bundle;
import android.telephony.SmsManager;
import androidx.annotation.NonNull;
import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodChannel;

public class MainActivity extends FlutterActivity {
    private static final String CHANNEL = "com.abhaya.sos/sms";

    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);
        new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), CHANNEL)
                .setMethodCallHandler(
                        (call, result) -> {
                            if (call.method.equals("sendSMS")) {
                                String number = call.argument("number");
                                String message = call.argument("message");
                                try {
                                    sendSMS(number, message);
                                    result.success("SMS Sent Successfully");
                                } catch (Exception e) {
                                    result.error("SMS_ERROR", e.getMessage(), null);
                                }
                            } else {
                                result.notImplemented();
                            }
                        });
    }

    private void sendSMS(String number, String message) throws Exception {
        SmsManager smsManager = SmsManager.getDefault();
        smsManager.sendTextMessage(number, null, message, null, null);
    }
}
