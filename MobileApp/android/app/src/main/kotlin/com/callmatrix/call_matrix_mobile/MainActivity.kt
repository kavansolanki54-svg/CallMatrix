package com.callmatrix.call_matrix_mobile

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import android.database.Cursor
import android.os.Build
import android.provider.CallLog
import android.provider.MediaStore
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.util.*

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.dallytasksheet.dally_task_sheet/calls"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "fetchCallLogs" -> {
                    val lastSyncVal = call.argument<Any>("lastSyncTime")
                    val customPath = call.argument<String>("customRecordingPath") ?: ""
                    val lastSync = when (lastSyncVal) {
                        is Number -> lastSyncVal.toLong()
                        else -> 0L
                    }
                    val logs = fetchCallLogs(lastSync, customPath)
                    result.success(logs)
                }
                "findRecording" -> {
                    val phoneNumber = call.argument<String>("phoneNumber") ?: ""
                    val startTimeVal = call.argument<Any>("startTime")
                    val startTimeMs = when (startTimeVal) {
                        is Number -> startTimeVal.toLong()
                        else -> 0L
                    }
                    val recordingPath = findCallRecording(phoneNumber, startTimeMs)
                    result.success(recordingPath)
                }
                "getDeviceDetails" -> {
                    val details = getDeviceDetails()
                    result.success(details)
                }
                "checkCallEndedIntent" -> {
                    val callEnded = intent?.getBooleanExtra("call_ended", false) ?: false
                    val phoneNumber = intent?.getStringExtra("phone_number") ?: ""
                    if (callEnded) {
                        intent?.removeExtra("call_ended")
                    }
                    result.success(mapOf("callEnded" to callEnded, "phoneNumber" to phoneNumber))
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun fetchCallLogs(lastSyncTime: Long, customRecordingPath: String = ""): List<Map<String, Any>> {
        val callLogs = mutableListOf<Map<String, Any>>()
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M &&
                checkSelfPermission(Manifest.permission.READ_CALL_LOG) != PackageManager.PERMISSION_GRANTED) {
                return callLogs
            }

            val projection = mutableListOf(
                CallLog.Calls.NUMBER,
                CallLog.Calls.CACHED_NAME,
                CallLog.Calls.TYPE,
                CallLog.Calls.DATE,
                CallLog.Calls.DURATION
            )
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                projection.add(CallLog.Calls.PHONE_ACCOUNT_ID)
            }

            val cal = Calendar.getInstance()
            cal.set(Calendar.HOUR_OF_DAY, 0)
            cal.set(Calendar.MINUTE, 0)
            cal.set(Calendar.SECOND, 0)
            cal.set(Calendar.MILLISECOND, 0)
            val todayStart = cal.timeInMillis

            val minTime = if (lastSyncTime > todayStart) lastSyncTime else todayStart

            val selection = "${CallLog.Calls.DATE} >= ?"
            val selectionArgs = arrayOf(minTime.toString())
            val sortOrder = "${CallLog.Calls.DATE} DESC"

            val cursor: Cursor? = contentResolver.query(
                CallLog.Calls.CONTENT_URI,
                projection.toTypedArray(),
                selection,
                selectionArgs,
                sortOrder
            )

            cursor?.use {
                val numberIndex = it.getColumnIndex(CallLog.Calls.NUMBER)
                val nameIndex = it.getColumnIndex(CallLog.Calls.CACHED_NAME)
                val typeIndex = it.getColumnIndex(CallLog.Calls.TYPE)
                val dateIndex = it.getColumnIndex(CallLog.Calls.DATE)
                val durationIndex = it.getColumnIndex(CallLog.Calls.DURATION)
                val simIdIndex = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) it.getColumnIndex(CallLog.Calls.PHONE_ACCOUNT_ID) else -1

                while (it.moveToNext()) {
                    val number = if (numberIndex >= 0) it.getString(numberIndex) ?: "" else ""
                    val name = if (nameIndex >= 0) it.getString(nameIndex) ?: "" else ""
                    val type = if (typeIndex >= 0) it.getInt(typeIndex) else 1
                    val date = if (dateIndex >= 0) it.getLong(dateIndex) else 0L
                    val duration = if (durationIndex >= 0) it.getInt(durationIndex) else 0
                    val rawSimId = if (simIdIndex >= 0) it.getString(simIdIndex) ?: "" else ""
                    val simId = if (rawSimId.isNotEmpty()) rawSimId else "SIM1"

                    val callTypeStr = when (type) {
                        CallLog.Calls.INCOMING_TYPE -> "Incoming"
                        CallLog.Calls.OUTGOING_TYPE -> "Outgoing"
                        CallLog.Calls.MISSED_TYPE -> "Missed"
                        CallLog.Calls.REJECTED_TYPE -> "Rejected"
                        CallLog.Calls.BLOCKED_TYPE -> "Rejected"
                        else -> "Unknown"
                    }

                    val recordingPath = findCallRecording(number, date, customRecordingPath)

                    val log = mapOf(
                        "phoneNumber" to number,
                        "contactName" to name,
                        "callType" to callTypeStr,
                        "startTime" to date,
                        "duration" to duration,
                        "simId" to simId,
                        "recordingPath" to (recordingPath ?: "")
                    )
                    callLogs.add(log)
                }
            }
        } catch (e: Exception) {
            // Guard against native SQLite query failures
        }
        return callLogs
    }

    private fun findCallRecording(phoneNumber: String, startTimeMs: Long, customPath: String = ""): String? {
        try {
            val projection = arrayOf(
                MediaStore.Audio.Media.DATA,
                MediaStore.Audio.Media.DATE_ADDED,
                MediaStore.Audio.Media.DISPLAY_NAME
            )
            val cleanPhone = phoneNumber.replace("[^0-9]".toRegex(), "")
            val startWindowSec = (startTimeMs - 10000) / 1000
            val endWindowSec = (startTimeMs + 45000) / 1000

            val selection = "${MediaStore.Audio.Media.DATE_ADDED} >= ? AND ${MediaStore.Audio.Media.DATE_ADDED} <= ?"
            val selectionArgs = arrayOf(startWindowSec.toString(), endWindowSec.toString())

            val mediaCursor: Cursor? = contentResolver.query(
                MediaStore.Audio.Media.EXTERNAL_CONTENT_URI,
                projection,
                selection,
                selectionArgs,
                "${MediaStore.Audio.Media.DATE_ADDED} DESC"
            )

            mediaCursor?.use {
                val dataIndex = it.getColumnIndex(MediaStore.Audio.Media.DATA)
                val nameIndex = it.getColumnIndex(MediaStore.Audio.Media.DISPLAY_NAME)
                while (it.moveToNext()) {
                    val filePath = if (dataIndex >= 0) it.getString(dataIndex) else null
                    val displayName = if (nameIndex >= 0) it.getString(nameIndex) ?: "" else ""
                    if (!filePath.isNullOrEmpty()) {
                        val lowerName = displayName.lowercase()
                        if (cleanPhone.isEmpty() || lowerName.contains(cleanPhone) || lowerName.contains("call") || lowerName.contains("rec")) {
                            return filePath
                        }
                    }
                }
            }

            val searchDirs = mutableListOf<File>()
            if (customPath.isNotEmpty()) {
                searchDirs.add(File(customPath))
            }
            searchDirs.addAll(listOf(
                File("/storage/emulated/0/Call"),
                File("/storage/emulated/0/Sounds/Call"),
                File("/storage/emulated/0/Recordings/Call"),
                File("/storage/emulated/0/Voice Recorder/Call"),
                File("/storage/emulated/0/Record/Call"),
                File("/storage/emulated/0/Recorder/Call"),
                File("/storage/emulated/0/MIUI/sound_recorder/call_rec"),
                File("/storage/emulated/0/Music/Recordings/Call Recordings"),
                File("/storage/emulated/0/CallRecordings"),
                File("/storage/emulated/0/Music/Recordings"),
                File("/storage/emulated/0/Recordings"),
                File("/storage/emulated/0/Android/data/com.google.android.dialer/files/call_recordings")
            ))

            val startWindow = startTimeMs - 10000
            val endWindow = startTimeMs + 45000

            for (dir in searchDirs) {
                if (dir.exists() && dir.isDirectory) {
                    val files = dir.listFiles()
                    if (files != null) {
                        for (file in files) {
                            if (file.isFile) {
                                val lastModified = file.lastModified()
                                val name = file.name.lowercase()
                                val isPhoneMatch = cleanPhone.isNotEmpty() && name.contains(cleanPhone)
                                val isTimeMatch = lastModified in startWindow..endWindow

                                if (isTimeMatch || (isPhoneMatch && isTimeMatch)) {
                                    return file.absolutePath
                                }
                            }
                        }
                    }
                }
            }
        } catch (e: Exception) {
            // Guard against storage navigation failure
        }
        return null
    }

    private fun getDeviceDetails(): Map<String, String> {
        var batteryPct = 100
        try {
            val bm = getSystemService(Context.BATTERY_SERVICE) as? android.os.BatteryManager
            if (bm != null) {
                batteryPct = bm.getIntProperty(android.os.BatteryManager.BATTERY_PROPERTY_CAPACITY)
            }
        } catch (e: Exception) {}

        return mapOf(
            "deviceId" to (Build.ID ?: "Unknown"),
            "manufacturer" to (Build.MANUFACTURER ?: "Unknown"),
            "model" to (Build.MODEL ?: "Unknown"),
            "androidVersion" to (Build.VERSION.RELEASE ?: "Unknown"),
            "batteryPercentage" to batteryPct.toString()
        )
    }
}
