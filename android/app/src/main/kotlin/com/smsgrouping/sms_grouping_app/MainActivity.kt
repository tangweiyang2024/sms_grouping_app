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
                    android.util.Log.d("SMS_READING", "开始读取短信...")
                    val smsList = readAllSms()
                    android.util.Log.d("SMS_READING", "成功读取 ${smsList.size} 条短信")
                    result.success(smsList)
                } catch (e: SecurityException) {
                    android.util.Log.e("SMS_READING", "权限错误: ${e.message}", e)
                    result.error("PERMISSION_DENIED", "没有短信读取权限: ${e.message}", mapOf("error_type" to "SecurityException"))
                } catch (e: Exception) {
                    android.util.Log.e("SMS_READING", "读取短信失败: ${e.message}", e)
                    result.error("SMS_ERROR", "读取短信失败: ${e.message}", mapOf(
                        "error_type" to e.javaClass.simpleName,
                        "stack_trace" to android.util.Log.getStackTraceString(e)
                    ))
                }
            } else {
                result.notImplemented()
            }
        }
    }

    private fun readAllSms(): List<Map<String, Any>> {
        val smsList = mutableListOf<Map<String, Any>>()
        
        try {
            val contentResolver: ContentResolver = contentResolver
            
            // SMS inbox URI
            val uri = Uri.parse("content://sms/inbox")
            
            android.util.Log.d("SMS_READING", "URI: $uri")
            
            // 读取最新的100条短信
            val projection = arrayOf(
                "_id",
                "address",     // 发送者号码
                "body",        // 短信内容
                "date"         // 时间戳
            )
            
            android.util.Log.d("SMS_READING", "开始查询短信...")
            
            val cursor = contentResolver.query(
                uri,
                projection,
                null,
                null,
                "date DESC"
            ) ?: throw Exception("无法创建短信查询游标，可能权限不足")
            
            android.util.Log.d("SMS_READING", "游标创建成功")
            
            cursor.use {
                val idIndex = it.getColumnIndexOrThrow("_id")
                val addressIndex = it.getColumnIndexOrThrow("address")
                val bodyIndex = it.getColumnIndexOrThrow("body")
                val dateIndex = it.getColumnIndexOrThrow("date")
                
                android.util.Log.d("SMS_READING", "列索引获取成功: id=$idIndex, address=$addressIndex, body=$bodyIndex, date=$dateIndex")
                
                var count = 0
                while (it.moveToNext() && count < 100) { // 限制读取100条
                    val id = it.getLong(idIndex)
                    val sender = it.getString(addressIndex) ?: "未知号码"
                    val content = it.getString(bodyIndex) ?: ""
                    val timestamp = it.getLong(dateIndex)
                    
                    val sms = mapOf(
                        "id" to id,
                        "sender" to sender,
                        "content" to content,
                        "timestamp" to timestamp
                    )
                    smsList.add(sms)
                    
                    android.util.Log.d("SMS_READING", "短信 #$count: ID=$id, 发送者=$sender, 时间=$timestamp")
                    count++
                }
                
                android.util.Log.d("SMS_READING", "共读取 $count 条短信")
            }
            
            if (smsList.isEmpty()) {
                android.util.Log.w("SMS_READING", "警告: 没有读取到任何短信")
            }
            
        } catch (e: SecurityException) {
            android.util.Log.e("SMS_READING", "安全异常: ${e.message}", e)
            throw Exception("没有短信读取权限，请在设置中授予短信访问权限")
        } catch (e: Exception) {
            android.util.Log.e("SMS_READING", "读取短信异常: ${e.message}", e)
            throw Exception("读取短信失败: ${e.message}")
        }
        
        return smsList
    }
}