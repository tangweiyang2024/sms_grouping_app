package com.smsgrouping.sms_grouping_app

import android.content.ContentResolver
import android.net.Uri
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.smsgrouping/sms"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "readSms") {
                try {
                    val smsList = readAllSms()
                    result.success(smsList)
                } catch (e: Exception) {
                    result.error("SMS_ERROR", "Failed to read SMS: ${e.message}", null)
                }
            } else {
                result.notImplemented()
            }
        }
    }

    private fun readAllSms(): List<Map<String, Any>> {
        val smsList = mutableListOf<Map<String, Any>>()
        val contentResolver: ContentResolver = contentResolver
        
        // SMS inbox URI
        val uri = Uri.parse("content://sms/inbox")
        
        // 读取最新的100条短信
        val projection = arrayOf(
            "_id",
            "address",     // 发送者号码
            "body",        // 短信内容
            "date"         // 时间戳
        )
        
        val cursor = contentResolver.query(
            uri,
            projection,
            null,
            null,
            "date DESC"
        )
        
        cursor?.use {
            val idIndex = it.getColumnIndexOrThrow("_id")
            val addressIndex = it.getColumnIndexOrThrow("address")
            val bodyIndex = it.getColumnIndexOrThrow("body")
            val dateIndex = it.getColumnIndexOrThrow("date")
            
            var count = 0
            while (it.moveToNext() && count < 100) { // 限制读取100条
                val sms = mapOf(
                    "id" to it.getLong(idIndex),
                    "sender" to (it.getString(addressIndex) ?: "未知号码"),
                    "content" to (it.getString(bodyIndex) ?: ""),
                    "timestamp" to it.getLong(dateIndex)
                )
                smsList.add(sms)
                count++
            }
        }
        
        return smsList
    }
}