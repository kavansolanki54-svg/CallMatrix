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

    override fun onNewIntent(intent: android.content.Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
    }

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
                    // Run disk and DB operations on background thread to prevent UI freezing/crashing
                    Thread {
                        try {
                            val logs = fetchCallLogs(lastSync, customPath)
                            runOnUiThread {
                                result.success(logs)
                            }
                        } catch (e: Exception) {
                            runOnUiThread {
                                result.error("NATIVE_ERROR", e.message, null)
                            }
                        }
                    }.start()
                }
                "findRecording" -> {
                    val phoneNumber = call.argument<String>("phoneNumber") ?: ""
                    val startTimeVal = call.argument<Any>("startTime")
                    val startTimeMs = when (startTimeVal) {
                        is Number -> startTimeVal.toLong()
                        else -> 0L
                    }
                    Thread {
                        try {
                            val recordingPath = findCallRecording(phoneNumber, startTimeMs)
                            runOnUiThread {
                                result.success(recordingPath)
                            }
                        } catch (e: Exception) {
                            runOnUiThread {
                                result.error("NATIVE_ERROR", e.message, null)
                            }
                        }
                    }.start()
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

            // Cache today's filesystem files once to prevent repeated directory scans
            val todayFiles = cacheTodayFiles(customRecordingPath, todayStart)

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

                    val recordingPath = findCallRecordingOptimized(number, date, duration, todayFiles)

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
            // Guard against native failures
        }
        return callLogs
    }

    private fun cacheTodayFiles(customPath: String, todayStart: Long): List<File> {
        val todayFiles = mutableListOf<File>()
        try {
            val searchDirs = mutableListOf<File>()
            if (customPath.isNotEmpty()) {
                searchDirs.add(File(customPath))
            }
            searchDirs.addAll(listOf(
                File("/storage/emulated/0/Call"),
                File("/storage/emulated/0/Sounds/Call"),
                File("/storage/emulated/0/Recordings/Call"),
                File("/storage/emulated/0/Voice Recorder/Call"),
                File("/storage/emulated/0/Record"),
                File("/storage/emulated/0/Recorder"),
                File("/storage/emulated/0/MIUI/sound_recorder/call_rec"),
                File("/storage/emulated/0/Music/Recordings/Call Recordings"),
                File("/storage/emulated/0/CallRecordings"),
                File("/storage/emulated/0/Music/Recordings"),
                File("/storage/emulated/0/Recordings"),
                File("/storage/emulated/0/Android/data/com.google.android.dialer/files/call_recordings")
            ))

            for (dir in searchDirs) {
                if (dir.exists() && dir.isDirectory) {
                    val files = dir.listFiles()
                    if (files != null) {
                        for (file in files) {
                            if (file.isFile && file.lastModified() >= todayStart) {
                                todayFiles.add(file)
                            }
                        }
                    }
                }
            }
        } catch (e: Exception) {}
        return todayFiles
    }

    private fun queryMediaStore(phoneNumber: String, startTimeMs: Long, durationSec: Int): String? {
        try {
            val projection = arrayOf(MediaStore.Audio.Media.DATA)
            val cleanPhone = phoneNumber.replace("[^0-9]".toRegex(), "")
            
            // Search from start of call to 20 seconds after end of call
            val startWindowSec = (startTimeMs - 10000) / 1000
            val endWindowSec = (startTimeMs + (durationSec * 1000L) + 20000) / 1000

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
                val candidates = mutableListOf<String>()
                while (it.moveToNext()) {
                    val filePath = if (dataIndex >= 0) it.getString(dataIndex) else null
                    if (!filePath.isNullOrEmpty()) {
                        val fileName = File(filePath).name.lowercase()
                        if (cleanPhone.isNotEmpty() && fileName.contains(cleanPhone)) {
                            return filePath
                        }
                        if (fileName.contains("call") || fileName.contains("rec")) {
                            candidates.add(filePath)
                        }
                    }
                }
                if (candidates.isNotEmpty()) {
                    return candidates.first()
                }
            }
        } catch (e: Exception) {}
        return null
    }

    private fun findCallRecordingOptimized(phoneNumber: String, startTimeMs: Long, durationSec: Int, todayFiles: List<File>): String? {
        // 1. Try MediaStore first
        val mediaPath = queryMediaStore(phoneNumber, startTimeMs, durationSec)
        if (mediaPath != null) return mediaPath

        // 2. Fallback to cached filesystem list search
        try {
            val cleanPhone = phoneNumber.replace("[^0-9]".toRegex(), "")
            val startWindow = startTimeMs - 10000
            val endWindow = startTimeMs + (durationSec * 1000L) + 20000

            // Prioritize files containing the phone number
            for (file in todayFiles) {
                val lastModified = file.lastModified()
                val name = file.name.lowercase()
                val isPhoneMatch = cleanPhone.isNotEmpty() && name.contains(cleanPhone)
                val isTimeMatch = lastModified in startWindow..endWindow

                if (isPhoneMatch && isTimeMatch) {
                    return file.absolutePath
                }
            }

            // Fallback to just time match
            for (file in todayFiles) {
                val lastModified = file.lastModified()
                val isTimeMatch = lastModified in startWindow..endWindow
                if (isTimeMatch) {
                    return file.absolutePath
                }
            }
        } catch (e: Exception) {}
        return null
    }

    private fun findCallRecording(phoneNumber: String, startTimeMs: Long): String? {
        // Fallback full search (used in individual method channel queries)
        val todayStart = Calendar.getInstance().apply {
            set(Calendar.HOUR_OF_DAY, 0)
            set(Calendar.MINUTE, 0)
            set(Calendar.SECOND, 0)
            set(Calendar.MILLISECOND, 0)
        }.timeInMillis
        val cached = cacheTodayFiles("", todayStart)
        return findCallRecordingOptimized(phoneNumber, startTimeMs, 30, cached)
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
