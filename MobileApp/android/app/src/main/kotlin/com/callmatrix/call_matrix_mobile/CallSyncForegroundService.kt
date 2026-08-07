package com.callmatrix.call_matrix_mobile

import android.Manifest
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.database.Cursor
import android.os.Build
import android.os.IBinder
import android.provider.CallLog
import android.provider.MediaStore
import android.util.Log
import androidx.core.app.NotificationCompat
import okhttp3.MediaType.Companion.toMediaTypeOrNull
import okhttp3.MultipartBody
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.RequestBody.Companion.asRequestBody
import okhttp3.RequestBody.Companion.toRequestBody
import org.json.JSONArray
import org.json.JSONObject
import java.io.File
import java.text.SimpleDateFormat
import java.util.*
import java.util.concurrent.TimeUnit

/**
 * Android Foreground Service that syncs call logs and uploads call recordings
 * to the CallMatrix API, showing a persistent notification with real progress.
 *
 * Lifecycle:
 *   startForegroundService(intent) → shows notification → syncs → uploads → stopSelf()
 */
class CallSyncForegroundService : Service() {

    companion object {
        private const val TAG = "CallSyncFGS"
        private const val CHANNEL_ID = "call_recording_sync_channel"
        private const val NOTIFICATION_ID = 2001
        private var isRunning = false

        /**
         * Convenience starter — can be called from Activity, BroadcastReceiver, or Flutter MethodChannel.
         */
        fun start(context: Context) {
            if (isRunning) {
                Log.d(TAG, "Service already running, skipping duplicate start")
                return
            }
            val intent = Intent(context, CallSyncForegroundService::class.java)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(intent)
            } else {
                context.startService(intent)
            }
        }
    }

    private val httpClient by lazy {
        OkHttpClient.Builder()
            .connectTimeout(30, TimeUnit.SECONDS)
            .readTimeout(60, TimeUnit.SECONDS)
            .writeTimeout(120, TimeUnit.SECONDS)
            .build()
    }

    override fun onBind(intent: Intent?): IBinder? = null

    private fun logToFile(message: String, t: Throwable? = null) {
        try {
            val dir = getExternalFilesDir(null)
            if (dir != null) {
                val file = File(dir, "callmatrix_sync_log.txt")
                val timestamp = SimpleDateFormat("yyyy-MM-dd HH:mm:ss", Locale.US).format(Date())
                val logLine = "$timestamp: $message\n" + (t?.let { Log.getStackTraceString(it) } ?: "") + "\n"
                file.appendText(logLine)
            }
        } catch (e: Exception) {
            Log.e(TAG, "Failed to write log to file", e)
        }
    }

    override fun onCreate() {
        super.onCreate()
        logToFile("Service onCreate() called")
        createNotificationChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        logToFile("Service onStartCommand() called, isRunning=$isRunning")
        if (isRunning) {
            Log.d(TAG, "Already running — ignoring duplicate onStartCommand")
            logToFile("Service already running — ignoring duplicate start")
            stopSelf()
            return START_NOT_STICKY
        }
        isRunning = true

        // Immediately go foreground with an indeterminate progress notification
        val initialNotification = buildNotification(
            title = "Syncing Call Logs…",
            text = "Preparing call data",
            progress = -1, // indeterminate
            maxProgress = 0,
            ongoing = true
        )
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                logToFile("Calling startForeground with FOREGROUND_SERVICE_TYPE_DATA_SYNC")
                startForeground(
                    NOTIFICATION_ID, 
                    initialNotification, 
                    android.content.pm.ServiceInfo.FOREGROUND_SERVICE_TYPE_DATA_SYNC
                )
            } else {
                logToFile("Calling startForeground (Legacy)")
                startForeground(NOTIFICATION_ID, initialNotification)
            }
            logToFile("startForeground() executed successfully")
        } catch (se: SecurityException) {
            logToFile("SecurityException during startForeground()", se)
            isRunning = false
            stopSelf()
            return START_NOT_STICKY
        } catch (e: Throwable) {
            logToFile("Unexpected error during startForeground()", e)
            isRunning = false
            stopSelf()
            return START_NOT_STICKY
        }

        // Run the entire pipeline on a background thread
        Thread {
            try {
                logToFile("Background thread started, starting sync pipeline")
                runSyncPipeline()
                logToFile("Sync pipeline finished executing")
            } catch (e: Throwable) {
                Log.e(TAG, "Sync pipeline crashed", e)
                logToFile("Sync pipeline crashed with exception", e)
                updateNotification(
                    title = "Sync Failed",
                    text = e.message ?: "Unknown error",
                    progress = 0,
                    maxProgress = 0,
                    ongoing = false
                )
            } finally {
                isRunning = false
                stopSelf()
                logToFile("Service background thread stopped, called stopSelf()")
            }
        }.start()

        return START_NOT_STICKY
    }

    override fun onDestroy() {
        super.onDestroy()
        logToFile("Service onDestroy() called")
        isRunning = false
    }

    // ─────────────────────────────────────────────────────────────
    // NOTIFICATION HELPERS
    // ─────────────────────────────────────────────────────────────

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Call Recording Sync",
                NotificationManager.IMPORTANCE_LOW // No sound, just visual
            ).apply {
                description = "Shows progress while syncing call recordings"
                setShowBadge(false)
            }
            val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            manager.createNotificationChannel(channel)
        }
    }

    /**
     * Build a notification with optional progress bar.
     * @param progress -1 for indeterminate, 0..maxProgress for determinate
     */
    private fun buildNotification(
        title: String,
        text: String,
        progress: Int,
        maxProgress: Int,
        ongoing: Boolean
    ): Notification {
        val launchIntent = Intent(this, MainActivity::class.java).apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
        }
        val pendingIntent = PendingIntent.getActivity(
            this, 0, launchIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val builder = NotificationCompat.Builder(this, CHANNEL_ID)
            .setSmallIcon(com.callmatrix.call_matrix_mobile.R.mipmap.ic_launcher)
            .setContentTitle(title)
            .setContentText(text)
            .setContentIntent(pendingIntent)
            .setOngoing(ongoing)
            .setOnlyAlertOnce(true)
            .setSilent(true)
            .setCategory(NotificationCompat.CATEGORY_PROGRESS)

        when {
            progress < 0 -> builder.setProgress(0, 0, true) // indeterminate
            maxProgress > 0 -> builder.setProgress(maxProgress, progress, false)
            else -> builder.setProgress(0, 0, false) // no progress bar (complete state)
        }

        if (!ongoing) {
            builder.setAutoCancel(true)
            builder.setTimeoutAfter(8000) // auto-dismiss after 8 seconds
        }

        return builder.build()
    }

    private fun updateNotification(
        title: String,
        text: String,
        progress: Int,
        maxProgress: Int,
        ongoing: Boolean
    ) {
        val notification = buildNotification(title, text, progress, maxProgress, ongoing)
        val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        manager.notify(NOTIFICATION_ID, notification)
    }

    // ─────────────────────────────────────────────────────────────
    // SYNC PIPELINE
    // ─────────────────────────────────────────────────────────────

    private fun runSyncPipeline() {
        // 1. Read credentials from SharedPreferences (written by Flutter)
        val prefs = getSharedPreferences("FlutterSharedPreferences", MODE_PRIVATE)
        val token = prefs.getString("flutter.token", "") ?: ""
        val baseUrl = prefs.getString("flutter.baseUrl", "") ?: ""
        val userDeviceId = try {
            prefs.getLong("flutter.user_device_id", 0L).toInt()
        } catch (e: ClassCastException) {
            prefs.getInt("flutter.user_device_id", 0)
        }
        val customPath = prefs.getString("flutter.custom_recording_path", "") ?: ""

        logToFile("Credentials loaded: token length=${token.length}, baseUrl=$baseUrl, userDeviceId=$userDeviceId, customPath=$customPath")

        if (token.isEmpty() || baseUrl.isEmpty()) {
            Log.w(TAG, "Missing token or baseUrl — cannot sync")
            logToFile("Aborting sync: token or baseUrl is empty")
            updateNotification("Sync Skipped", "Not logged in", 0, 0, false)
            return
        }

        // 2. Fetch recent call logs (last 3 days) from the Android system
        val cal = Calendar.getInstance().apply {
            set(Calendar.HOUR_OF_DAY, 0); set(Calendar.MINUTE, 0)
            set(Calendar.SECOND, 0); set(Calendar.MILLISECOND, 0)
        }
        val todayStart = cal.timeInMillis - (3 * 24 * 60 * 60 * 1000L) // last 3 days
        logToFile("Fetching today's call logs since $todayStart")
        val logs = fetchCallLogs(todayStart, customPath)

        logToFile("Fetched ${logs.size} call logs from system")
        for ((idx, log) in logs.withIndex()) {
            logToFile("Log #$idx: phone=${log["phoneNumber"]}, type=${log["callType"]}, startTime=${log["startTime"]}, duration=${log["duration"]}, recordingPath=${log["recordingPath"]}")
        }

        if (logs.isEmpty()) {
            Log.i(TAG, "No call logs for today")
            updateNotification("✓ Sync Complete", "No new calls to sync", 0, 0, false)
            return
        }

        // 3. Sync call logs to API
        updateNotification("Syncing Call Logs…", "Uploading ${logs.size} call logs", -1, 0, true)

        val formattedCalls = logs.map { log ->
            val startTimeMs = log["startTime"] as? Long ?: 0L
            val dt = Date(startTimeMs)
            val sdf = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss", Locale.US).apply {
                timeZone = TimeZone.getDefault()
            }
            mapOf(
                "companyId" to 0,
                "phoneNumber" to (log["phoneNumber"] as? String ?: ""),
                "contactName" to (log["contactName"] as? String ?: ""),
                "callType" to (log["callType"] as? String ?: "Outgoing"),
                "duration" to (log["duration"] as? Int ?: 0),
                "callDateTime" to sdf.format(dt),
                "deviceId" to userDeviceId,
                "customerId" to 0
            )
        }

        val syncPayload = JSONObject().apply {
            put("companyId", 0)
            put("deviceId", userDeviceId)
            put("calls", JSONArray().apply {
                for (c in formattedCalls) {
                    put(JSONObject().apply {
                        put("companyId", 0)
                        put("phoneNumber", c["phoneNumber"])
                        put("contactName", c["contactName"])
                        put("callType", c["callType"])
                        put("duration", c["duration"])
                        put("callDateTime", c["callDateTime"])
                        put("deviceId", c["deviceId"])
                        put("customerId", 0)
                    })
                }
            })
        }

        val syncRequest = Request.Builder()
            .url("$baseUrl/api/Calls/sync")
            .post(syncPayload.toString().toRequestBody("application/json; charset=utf-8".toMediaTypeOrNull()))
            .addHeader("Authorization", "Bearer $token")
            .build()

        val syncResponse = httpClient.newCall(syncRequest).execute()
        if (!syncResponse.isSuccessful) {
            Log.e(TAG, "Call logs sync failed: code=${syncResponse.code}")
            logToFile("Call logs sync failed: code=${syncResponse.code}")
            syncResponse.close()
            updateNotification("Sync Failed", "Could not sync call logs", 0, 0, false)
            return
        }
        syncResponse.close()
        Log.i(TAG, "Call logs synced successfully")
        logToFile("Call logs synced successfully")

        // 4. Find recordings that need uploading
        val logsWithRecordings = logs.filter {
            val path = it["recordingPath"] as? String ?: ""
            path.isNotEmpty() && File(path).exists()
        }
        logToFile("Found ${logsWithRecordings.size} local recordings needing upload")

        if (logsWithRecordings.isEmpty()) {
            Log.i(TAG, "No local recordings to upload")
            logToFile("No local recordings found, completing sync")
            updateNotification("✓ Sync Complete", "${logs.size} calls synced, no recordings found", 0, 0, false)
            return
        }

        // 5. Fetch server-side call list to get CallIds for matching
        updateNotification("Preparing Uploads…", "Matching recordings to call logs", -1, 0, true)
        logToFile("Fetching server-side calls list for matching")

        val listRequest = Request.Builder()
            .url("$baseUrl/api/Calls?page=1&pageSize=50")
            .get()
            .addHeader("Authorization", "Bearer $token")
            .build()

        val listResponse = httpClient.newCall(listRequest).execute()
        if (!listResponse.isSuccessful) {
            Log.e(TAG, "Fetch calls list failed: code=${listResponse.code}")
            logToFile("Fetch calls list failed: code=${listResponse.code}")
            listResponse.close()
            updateNotification("Sync Partial", "Calls synced but could not match recordings", 0, 0, false)
            return
        }

        val responseBodyStr = listResponse.body?.string() ?: ""
        listResponse.close()
        val apiResponse = JSONObject(responseBodyStr)
        val success = apiResponse.optBoolean("success", false) || apiResponse.optBoolean("isSuccess", false)

        if (!success) {
            updateNotification("Sync Partial", "Calls synced but server returned error", 0, 0, false)
            return
        }

        val fetchedCalls = mutableListOf<Map<String, Any>>()
        val dataObj = apiResponse.optJSONObject("data")
        if (dataObj != null) {
            val itemsArray = dataObj.optJSONArray("items")
            if (itemsArray != null) {
                for (i in 0 until itemsArray.length()) {
                    val item = itemsArray.getJSONObject(i)
                    fetchedCalls.add(mapOf(
                        "callId" to item.optInt("callId"),
                        "phoneNumber" to item.optString("phoneNumber"),
                        "callDateTime" to item.optString("callDateTime")
                    ))
                }
            }
        }

        // 6. Upload recordings with progress notification
        val totalToUpload = logsWithRecordings.size
        var uploadedCount = 0
        var failedCount = 0

        for ((index, log) in logsWithRecordings.withIndex()) {
            val recordingPath = log["recordingPath"] as? String ?: ""
            val phoneNumber = log["phoneNumber"] as? String ?: ""
            val startTimeMs = log["startTime"] as? Long ?: 0L
            val duration = log["duration"] as? Int ?: 0
            val file = File(recordingPath)

            updateNotification(
                title = "Uploading Recordings…",
                text = "File ${index + 1} of $totalToUpload — ${file.name}",
                progress = index,
                maxProgress = totalToUpload,
                ongoing = true
            )

            // Wait for file stabilization (recorder may still be writing)
            if (!waitForFileStabilization(file)) {
                Log.w(TAG, "File not stable, skipping: ${file.name}")
                logToFile("Recording file not stable, skipping: ${file.name}")
                failedCount++
                continue
            }

            // Match to server-side call
            val matchedCall = matchCallLog(fetchedCalls, phoneNumber, startTimeMs)
            if (matchedCall == null) {
                Log.w(TAG, "No matching server call for phone=$phoneNumber, time=$startTimeMs")
                logToFile("Matching failed: could not match local recording to any call on server (phone=$phoneNumber, startTime=$startTimeMs)")
                failedCount++
                continue
            }

            val callId = matchedCall["callId"] as? Int ?: 0
            val fileName = file.name
            val fileSize = file.length()
            logToFile("Matched local recording ${file.name} to server CallId=$callId")

            // Upload via multipart
            try {
                val fileBody = file.asRequestBody("application/octet-stream".toMediaTypeOrNull())
                val multipartBody = MultipartBody.Builder()
                    .setType(MultipartBody.FORM)
                    .addFormDataPart("companyId", "0")
                    .addFormDataPart("callId", callId.toString())
                    .addFormDataPart("fileName", fileName)
                    .addFormDataPart("filePath", file.absolutePath)
                    .addFormDataPart("fileUrl", file.absolutePath)
                    .addFormDataPart("duration", duration.toString())
                    .addFormDataPart("fileSize", fileSize.toString())
                    .addFormDataPart("file", fileName, fileBody)
                    .build()

                val uploadRequest = Request.Builder()
                    .url("$baseUrl/api/Calls/recording")
                    .post(multipartBody)
                    .addHeader("Authorization", "Bearer $token")
                    .build()

                val uploadResponse = httpClient.newCall(uploadRequest).execute()
                if (uploadResponse.isSuccessful) {
                    uploadedCount++
                    Log.i(TAG, "Uploaded recording for CallId=$callId: $fileName")
                    logToFile("Uploaded recording successfully: CallId=$callId, file=$fileName")
                } else {
                    failedCount++
                    val respBody = uploadResponse.body?.string() ?: ""
                    Log.e(TAG, "Upload failed for CallId=$callId: code=${uploadResponse.code}, body=$respBody")
                    logToFile("Upload failed for CallId=$callId: code=${uploadResponse.code}, response=$respBody")
                }
                uploadResponse.close()
            } catch (e: Exception) {
                failedCount++
                Log.e(TAG, "Upload exception for CallId=$callId", e)
                logToFile("Upload exception for CallId=$callId", e)
            }
        }

        // 7. Show completion notification
        val summaryParts = mutableListOf<String>()
        summaryParts.add("${logs.size} calls synced")
        if (uploadedCount > 0) summaryParts.add("$uploadedCount recordings uploaded")
        if (failedCount > 0) summaryParts.add("$failedCount failed")

        updateNotification(
            title = "✓ Sync Complete",
            text = summaryParts.joinToString(" · "),
            progress = 0,
            maxProgress = 0,
            ongoing = false
        )

        Log.i(TAG, "Sync pipeline complete: uploaded=$uploadedCount, failed=$failedCount")
    }

    // ─────────────────────────────────────────────────────────────
    // CALL LOG + RECORDING HELPERS (shared logic)
    // ─────────────────────────────────────────────────────────────

    private fun fetchCallLogs(todayStart: Long, customRecordingPath: String): List<Map<String, Any>> {
        val callLogs = mutableListOf<Map<String, Any>>()
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M &&
                checkSelfPermission(Manifest.permission.READ_CALL_LOG) != PackageManager.PERMISSION_GRANTED) {
                logToFile("READ_CALL_LOG permission is NOT granted to the service process!")
                return callLogs
            }

            val projection = arrayOf(
                CallLog.Calls.NUMBER,
                CallLog.Calls.CACHED_NAME,
                CallLog.Calls.TYPE,
                CallLog.Calls.DATE,
                CallLog.Calls.DURATION
            )

            val cursor: Cursor? = contentResolver.query(
                CallLog.Calls.CONTENT_URI,
                projection,
                "${CallLog.Calls.DATE} >= ?",
                arrayOf(todayStart.toString()),
                "${CallLog.Calls.DATE} DESC"
            )

            val todayFiles = cacheTodayFiles(customRecordingPath, todayStart)
            logToFile("Cached ${todayFiles.size} filesystem files from today for recording matching")

            cursor?.use {
                val numberIndex = it.getColumnIndex(CallLog.Calls.NUMBER)
                val nameIndex = it.getColumnIndex(CallLog.Calls.CACHED_NAME)
                val typeIndex = it.getColumnIndex(CallLog.Calls.TYPE)
                val dateIndex = it.getColumnIndex(CallLog.Calls.DATE)
                val durationIndex = it.getColumnIndex(CallLog.Calls.DURATION)

                while (it.moveToNext()) {
                    val number = if (numberIndex >= 0) it.getString(numberIndex) ?: "" else ""
                    val name = if (nameIndex >= 0) it.getString(nameIndex) ?: "" else ""
                    val type = if (typeIndex >= 0) it.getInt(typeIndex) else 1
                    val date = if (dateIndex >= 0) it.getLong(dateIndex) else 0L
                    val duration = if (durationIndex >= 0) it.getInt(durationIndex) else 0

                    val callTypeStr = when (type) {
                        CallLog.Calls.INCOMING_TYPE -> "Incoming"
                        CallLog.Calls.OUTGOING_TYPE -> "Outgoing"
                        CallLog.Calls.MISSED_TYPE -> "Missed"
                        CallLog.Calls.REJECTED_TYPE -> "Rejected"
                        else -> "Unknown"
                    }

                    val recordingPath = findCallRecordingOptimized(number, date, duration, todayFiles)

                    callLogs.add(mapOf(
                        "phoneNumber" to number,
                        "contactName" to name,
                        "callType" to callTypeStr,
                        "startTime" to date,
                        "duration" to duration,
                        "recordingPath" to (recordingPath ?: "")
                    ))
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "fetchCallLogs error", e)
            logToFile("Exception in fetchCallLogs", e)
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
        } catch (e: Exception) {
            Log.e(TAG, "cacheTodayFiles error", e)
        }
        return todayFiles
    }

    private fun findCallRecordingOptimized(phoneNumber: String, startTimeMs: Long, durationSec: Int, todayFiles: List<File>): String? {
        // 1. Try MediaStore first
        val mediaPath = queryMediaStore(phoneNumber, startTimeMs, durationSec)
        if (mediaPath != null) return mediaPath

        // 2. Fallback to cached filesystem search
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
                if (isPhoneMatch && isTimeMatch) return file.absolutePath
            }

            // Fallback to just time match
            for (file in todayFiles) {
                val isTimeMatch = file.lastModified() in startWindow..endWindow
                if (isTimeMatch) return file.absolutePath
            }
        } catch (e: Exception) {
            Log.e(TAG, "findCallRecordingOptimized error", e)
        }
        return null
    }

    private fun queryMediaStore(phoneNumber: String, startTimeMs: Long, durationSec: Int): String? {
        try {
            val projection = arrayOf(MediaStore.Audio.Media.DATA)
            val cleanPhone = phoneNumber.replace("[^0-9]".toRegex(), "")
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
                        if (cleanPhone.isNotEmpty() && fileName.contains(cleanPhone)) return filePath
                        if (fileName.contains("call") || fileName.contains("rec")) candidates.add(filePath)
                    }
                }
                if (candidates.isNotEmpty()) return candidates.first()
            }
        } catch (e: Exception) {
            Log.e(TAG, "queryMediaStore error", e)
        }
        return null
    }

    /**
     * Wait for a recording file to finish being written by the system recorder.
     * Returns true if the file stabilized, false if it never did.
     */
    private fun waitForFileStabilization(file: File): Boolean {
        var lastSize = file.length()
        var stableCount = 0
        for (i in 1..10) {
            try { Thread.sleep(800) } catch (_: Exception) {}
            val currentSize = file.length()
            if (currentSize == lastSize && currentSize > 0) {
                stableCount++
                if (stableCount >= 2) return true
            } else {
                stableCount = 0
                lastSize = currentSize
            }
        }
        return file.length() > 0
    }

    /**
     * Match a local call log entry to a server-side call by phone number + timestamp.
     */
    private fun matchCallLog(
        serverCalls: List<Map<String, Any>>,
        phoneNumber: String,
        startTimeMs: Long
    ): Map<String, Any>? {
        val cleanLocalPhone = phoneNumber.replace("[^0-9]".toRegex(), "")

        return serverCalls.firstOrNull { fc ->
            val fcPhone = fc["phoneNumber"] as? String ?: ""
            val fcTimeStr = fc["callDateTime"] as? String ?: ""

            val cleanFcPhone = fcPhone.replace("[^0-9]".toRegex(), "")
            val isPhoneMatched = if (cleanFcPhone.length >= 10 && cleanLocalPhone.length >= 10) {
                cleanFcPhone.substring(cleanFcPhone.length - 10) == cleanLocalPhone.substring(cleanLocalPhone.length - 10)
            } else {
                cleanFcPhone == cleanLocalPhone
            }

            if (!isPhoneMatched) return@firstOrNull false

            val fcTime = try {
                if (fcTimeStr.length >= 19) {
                    val subStr = fcTimeStr.substring(0, 19)
                    if (fcTimeStr.endsWith("Z")) {
                        SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss", Locale.US).apply {
                            timeZone = TimeZone.getTimeZone("UTC")
                        }.parse(subStr)
                    } else {
                        SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss", Locale.US).apply {
                            timeZone = TimeZone.getDefault()
                        }.parse(subStr)
                    }
                } else {
                    null
                }
            } catch (e: Exception) { null }

            if (fcTime == null) return@firstOrNull false

            val diffSec = Math.abs((fcTime.time - startTimeMs) / 1000)
            diffSec < 90
        }
    }
}
