package com.callmatrix.call_matrix_mobile

import android.app.Activity
import android.content.Intent
import android.graphics.Color
import android.graphics.Typeface
import android.graphics.drawable.ColorDrawable
import android.graphics.drawable.GradientDrawable
import android.os.Bundle
import android.speech.RecognizerIntent
import android.text.InputType
import android.view.Gravity
import android.view.View
import android.view.Window
import android.view.WindowManager
import android.widget.*
import java.text.SimpleDateFormat
import java.util.*
import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import android.database.Cursor
import android.provider.CallLog
import android.provider.MediaStore
import java.io.File
import okhttp3.MediaType.Companion.toMediaTypeOrNull
import okhttp3.RequestBody.Companion.toRequestBody
import okhttp3.RequestBody.Companion.asRequestBody

class CallEndedOverlayActivity : Activity() {

    private var noteEditText: EditText? = null
    private val SPEECH_REQUEST_CODE = 101

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        requestWindowFeature(Window.FEATURE_NO_TITLE)
        window.setBackgroundDrawable(ColorDrawable(Color.parseColor("#77000000"))) // Translucent overlay
        window.setLayout(WindowManager.LayoutParams.MATCH_PARENT, WindowManager.LayoutParams.MATCH_PARENT)
        window.setGravity(Gravity.CENTER)
        window.addFlags(
            WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL or
                    WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                    WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON or
                    WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON
        )

        val phoneNumber = intent.getStringExtra("phone_number") ?: "+916353046278"
        val contactName = intent.getStringExtra("contact_name") ?: "Office Contact"
        val callFromNumber = intent.getStringExtra("call_from") ?: "+916353036645"
        val callDuration = intent.getStringExtra("call_duration") ?: "0h 0m 4s"
        val callType = intent.getStringExtra("call_type") ?: "Outgoing"
        val currentTimeStr = intent.getStringExtra("call_time") 
            ?: SimpleDateFormat("hh:mm a", Locale.getDefault()).format(Date())

        setContentView(buildLayout(phoneNumber, contactName, callFromNumber, callDuration, currentTimeStr, callType))
    }

    private fun buildLayout(
        phoneNumber: String,
        contactName: String,
        callFromNumber: String,
        callDuration: String,
        timeStr: String,
        callType: String
    ): View {
        val root = FrameLayout(this).apply {
            setBackgroundColor(Color.parseColor("#B30B0F19")) // Dimmed translucent deep dark background
        }

        // Dialog Box Container
        val dialogBox = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER_HORIZONTAL
            setPadding(dpToPx(28), dpToPx(32), dpToPx(28), dpToPx(32))
            
            // Material 3 Dark theme card background: #1A1C1E
            background = createCardDrawable(
                Color.parseColor("#1A1C1E"), 
                dpToPx(24).toFloat(), 
                Color.parseColor("#2D3135") // Subtle border
            )

            val lp = FrameLayout.LayoutParams(
                dpToPx(320),
                FrameLayout.LayoutParams.WRAP_CONTENT
            ).apply {
                gravity = Gravity.CENTER
            }
            layoutParams = lp
        }

        // --- 1. Green Circular Checkmark Icon ---
        val iconContainer = FrameLayout(this).apply {
            val size = dpToPx(64)
            val lp = LinearLayout.LayoutParams(size, size).apply {
                setMargins(0, 0, 0, dpToPx(16))
            }
            layoutParams = lp
            
            background = GradientDrawable().apply {
                shape = GradientDrawable.OVAL
                setColor(Color.parseColor("#1B3D2F")) // Dark green translucent circle
            }
        }

        val checkmark = TextView(this).apply {
            text = "✓"
            setTextColor(Color.parseColor("#34D399")) // Material Green/Emerald
            textSize = 28f
            typeface = Typeface.DEFAULT_BOLD
            gravity = Gravity.CENTER
            val lp = FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.MATCH_PARENT,
                FrameLayout.LayoutParams.MATCH_PARENT
            )
            layoutParams = lp
        }
        iconContainer.addView(checkmark)
        dialogBox.addView(iconContainer)

        // --- 2. Title "Call Ended" ---
        val titleTxt = TextView(this).apply {
            text = "Call Ended"
            setTextColor(Color.parseColor("#F1F5F9")) // Premium off-white
            textSize = 22f
            typeface = Typeface.create("sans-serif-medium", Typeface.NORMAL)
            gravity = Gravity.CENTER_HORIZONTAL
            val lp = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.WRAP_CONTENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            ).apply {
                setMargins(0, 0, 0, dpToPx(20))
            }
            layoutParams = lp
        }
        dialogBox.addView(titleTxt)

        // --- 3. Contact Name & Phone Number (Text only, no avatar) ---
        val displayName = if (contactName.isNotEmpty()) contactName else "Unknown Contact"
        val nameTxt = TextView(this).apply {
            text = displayName
            setTextColor(Color.WHITE)
            textSize = 20f
            typeface = Typeface.create("sans-serif-medium", Typeface.NORMAL)
            gravity = Gravity.CENTER_HORIZONTAL
            val lp = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.WRAP_CONTENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            ).apply {
                setMargins(0, 0, 0, dpToPx(4))
            }
            layoutParams = lp
        }
        dialogBox.addView(nameTxt)

        val phoneTxt = TextView(this).apply {
            text = phoneNumber
            setTextColor(Color.parseColor("#94A3B8")) // Slate gray
            textSize = 15f
            typeface = Typeface.create("sans-serif", Typeface.NORMAL)
            gravity = Gravity.CENTER_HORIZONTAL
            val lp = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.WRAP_CONTENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            ).apply {
                setMargins(0, 0, 0, dpToPx(20))
            }
            layoutParams = lp
        }
        dialogBox.addView(phoneTxt)

        // --- 4. Call Duration & Call End Time (Clean typography, no icons) ---
        val infoTxt = TextView(this).apply {
            val displayDuration = if (callDuration.contains("0h 0m")) callDuration.replace("0h 0m ", "") else callDuration
            text = "Duration: $displayDuration  •  Ended at $timeStr"
            setTextColor(Color.parseColor("#64748B")) // Dimmer slate gray
            textSize = 13.5f
            typeface = Typeface.create("sans-serif", Typeface.NORMAL)
            gravity = Gravity.CENTER_HORIZONTAL
            val lp = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.WRAP_CONTENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            ).apply {
                setMargins(0, 0, 0, dpToPx(32))
            }
            layoutParams = lp
        }
        dialogBox.addView(infoTxt)

        // --- 5. Full-Width Green "Done" Button with Rounded Corners ---
        val doneBtn = Button(this).apply {
            text = "Done"
            setTextColor(Color.parseColor("#0F172A")) // Slate 900
            textSize = 15f
            typeface = Typeface.create("sans-serif-medium", Typeface.NORMAL)
            isAllCaps = false
            
            background = GradientDrawable().apply {
                cornerRadius = dpToPx(28).toFloat()
                setColor(Color.parseColor("#10B981")) // Material Green/Emerald
            }

            setOnClickListener {
                saveNoteAndClose("Done")
            }

            val lp = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                dpToPx(50)
            )
            layoutParams = lp
        }
        dialogBox.addView(doneBtn)

        root.addView(dialogBox)
        return root
    }

    private fun dpToPx(dp: Int): Int {
        return (dp * resources.displayMetrics.density).toInt()
    }

    private fun createCardDrawable(color: Int, radius: Float, borderColor: Int): GradientDrawable {
        return GradientDrawable().apply {
            shape = GradientDrawable.RECTANGLE
            cornerRadius = radius
            setColor(color)
            setStroke(dpToPx(1), borderColor)
        }
    }

    private fun createActionButton(label: String, onClick: () -> Unit): Button {
        return Button(this).apply {
            text = label
            setTextColor(Color.WHITE)
            textSize = 11f
            typeface = Typeface.DEFAULT_BOLD
            background = createCardDrawable(Color.parseColor("#2563EB"), dpToPx(10).toFloat(), Color.TRANSPARENT)
            setPadding(dpToPx(4), dpToPx(8), dpToPx(4), dpToPx(8))
            isAllCaps = false
            setOnClickListener { onClick() }
            val lp = LinearLayout.LayoutParams(0, dpToPx(44), 1f).apply {
                setMargins(dpToPx(3), 0, dpToPx(3), 0)
            }
            layoutParams = lp
        }
    }

    private fun triggerSpeechToText() {
        try {
            val intent = Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH).apply {
                putExtra(RecognizerIntent.EXTRA_LANGUAGE_MODEL, RecognizerIntent.LANGUAGE_MODEL_FREE_FORM)
                putExtra(RecognizerIntent.EXTRA_LANGUAGE, Locale.getDefault())
                putExtra(RecognizerIntent.EXTRA_PROMPT, "Speak call note...")
            }
            startActivityForResult(intent, SPEECH_REQUEST_CODE)
        } catch (e: Exception) {}
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == SPEECH_REQUEST_CODE && resultCode == RESULT_OK && data != null) {
            val results = data.getStringArrayListExtra(RecognizerIntent.EXTRA_RESULTS)
            if (!results.isNullOrEmpty()) {
                val currentText = noteEditText?.text?.toString() ?: ""
                val spokenText = results[0]
                noteEditText?.setText(if (currentText.isEmpty()) spokenText else "$currentText $spokenText")
            }
        }
    }

    private fun saveNoteAndClose(actionType: String) {
        // Trigger background REST sync silently on separate thread
        triggerBackgroundSync()
        finish()
    }

    private fun triggerMainActivitySync() {
        try {
            val phoneNumber = intent.getStringExtra("phone_number") ?: ""
            val launchIntent = Intent(this, MainActivity::class.java).apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
                putExtra("call_ended", true)
                putExtra("phone_number", phoneNumber)
            }
            startActivity(launchIntent)
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    private fun triggerBackgroundSync() {
        Thread {
            try {
                val prefs = getSharedPreferences("FlutterSharedPreferences", MODE_PRIVATE)
                val token = prefs.getString("flutter.token", "") ?: ""
                val employeeId = prefs.getString("flutter.employeeId", "") ?: ""
                val baseUrl = prefs.getString("flutter.baseUrl", "") ?: ""
                val userDeviceId = prefs.getInt("flutter.user_device_id", 0)
                val customPath = prefs.getString("flutter.custom_recording_path", "") ?: ""

                if (token.isEmpty() || baseUrl.isEmpty()) {
                    return@Thread
                }

                // Fetch Today's logs
                val cal = Calendar.getInstance().apply {
                    set(Calendar.HOUR_OF_DAY, 0)
                    set(Calendar.MINUTE, 0)
                    set(Calendar.SECOND, 0)
                    set(Calendar.MILLISECOND, 0)
                }
                val todayStart = cal.timeInMillis

                val logs = fetchCallLogs(todayStart, customPath)
                if (logs.isEmpty()) {
                    return@Thread
                }

                val formattedCalls = mutableListOf<Map<String, Any>>()
                for (log in logs) {
                    val number = log["phoneNumber"] as? String ?: ""
                    val name = log["contactName"] as? String ?: ""
                    val type = log["callType"] as? String ?: "Outgoing"
                    val startTimeMs = log["startTime"] as? Long ?: 0L
                    val duration = log["duration"] as? Int ?: 0

                    val dt = Date(startTimeMs)
                    val sdf = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss", Locale.US).apply {
                        timeZone = TimeZone.getDefault()
                    }
                    val formattedTime = sdf.format(dt)

                    formattedCalls.add(mapOf(
                        "companyId" to 0,
                        "phoneNumber" to number,
                        "contactName" to name,
                        "callType" to type,
                        "duration" to duration,
                        "callDateTime" to formattedTime,
                        "deviceId" to userDeviceId,
                        "customerId" to 0
                    ))
                }

                val okHttpClient = okhttp3.OkHttpClient()

                val syncPayload = org.json.JSONObject().apply {
                    put("companyId", 0)
                    put("deviceId", userDeviceId)
                    
                    val callsArray = org.json.JSONArray()
                    for (c in formattedCalls) {
                        val callObj = org.json.JSONObject().apply {
                            put("companyId", 0)
                            put("phoneNumber", c["phoneNumber"])
                            put("contactName", c["contactName"])
                            put("callType", c["callType"])
                            put("duration", c["duration"])
                            put("callDateTime", c["callDateTime"])
                            put("deviceId", c["deviceId"])
                            put("customerId", 0)
                        }
                        callsArray.put(callObj)
                    }
                    put("calls", callsArray)
                }

                val requestBody = syncPayload.toString().toRequestBody("application/json; charset=utf-8".toMediaTypeOrNull())

                val syncRequest = okhttp3.Request.Builder()
                    .url("$baseUrl/api/Calls/sync")
                    .post(requestBody)
                    .addHeader("Authorization", "Bearer $token")
                    .build()

                val syncResponse = okHttpClient.newCall(syncRequest).execute()
                if (syncResponse.isSuccessful) {
                    val listRequest = okhttp3.Request.Builder()
                        .url("$baseUrl/api/Calls?page=1&pageSize=50")
                        .get()
                        .addHeader("Authorization", "Bearer $token")
                        .build()

                    val listResponse = okHttpClient.newCall(listRequest).execute()
                    if (listResponse.isSuccessful) {
                        val responseBodyStr = listResponse.body?.string() ?: ""
                        val apiResponseMap = org.json.JSONObject(responseBodyStr)
                        val success = apiResponseMap.optBoolean("success", false) || apiResponseMap.optBoolean("isSuccess", false)
                        if (success) {
                            val dataObj = apiResponseMap.optJSONObject("data")
                            val fetchedCalls = mutableListOf<Map<String, Any>>()
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

                            for (log in logs) {
                                val recordingPath = log["recordingPath"] as? String ?: ""
                                if (recordingPath.isNotEmpty()) {
                                    val file = File(recordingPath)
                                    if (file.exists()) {
                                        val phoneNumber = log["phoneNumber"] as? String ?: ""
                                        val startTimeMs = log["startTime"] as? Long ?: 0L
                                        val duration = log["duration"] as? Int ?: 0

                                        val matchedCall = fetchedCalls.firstOrNull { fc ->
                                            val fcPhone = fc["phoneNumber"] as? String ?: ""
                                            val fcTimeStr = fc["callDateTime"] as? String ?: ""

                                            val cleanFcPhone = fcPhone.replace("[^0-9]".toRegex(), "")
                                            val cleanLocalPhone = phoneNumber.replace("[^0-9]".toRegex(), "")

                                            val isPhoneMatched = if (cleanFcPhone.length >= 10 && cleanLocalPhone.length >= 10) {
                                                cleanFcPhone.substring(cleanFcPhone.length - 10) == cleanLocalPhone.substring(cleanLocalPhone.length - 10)
                                            } else {
                                                cleanFcPhone == cleanLocalPhone
                                            }

                                            if (!isPhoneMatched) return@firstOrNull false

                                            val fcTimeSdf = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss", Locale.US).apply {
                                                timeZone = TimeZone.getTimeZone("UTC")
                                            }
                                            val fcTime = try { fcTimeSdf.parse(fcTimeStr) } catch(e: Exception) { null }
                                            if (fcTime == null) return@firstOrNull false

                                            val diffSec = Math.abs((fcTime.time - startTimeMs) / 1000)
                                            diffSec < 90
                                        }

                                        if (matchedCall != null) {
                                            val callId = matchedCall["callId"] as? Int ?: 0
                                            val fileName = file.name
                                            val fileSize = file.length()

                                            val fileBody = file.asRequestBody("application/octet-stream".toMediaTypeOrNull())

                                            val multipartBody = okhttp3.MultipartBody.Builder()
                                                .setType(okhttp3.MultipartBody.FORM)
                                                .addFormDataPart("companyId", "0")
                                                .addFormDataPart("callId", callId.toString())
                                                .addFormDataPart("fileName", fileName)
                                                .addFormDataPart("filePath", file.absolutePath)
                                                .addFormDataPart("fileUrl", file.absolutePath)
                                                .addFormDataPart("duration", duration.toString())
                                                .addFormDataPart("fileSize", fileSize.toString())
                                                .addFormDataPart("file", fileName, fileBody)
                                                .build()

                                            val uploadRequest = okhttp3.Request.Builder()
                                                .url("$baseUrl/api/Calls/recording")
                                                .post(multipartBody)
                                                .addHeader("Authorization", "Bearer $token")
                                                .build()

                                            val uploadResponse = okHttpClient.newCall(uploadRequest).execute()
                                            uploadResponse.close()
                                        }
                                    }
                                }
                            }
                        }
                    }
                    listResponse.close()
                }
                syncResponse.close()
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }
    }

    private fun fetchCallLogs(lastSyncTime: Long, customRecordingPath: String = ""): List<Map<String, Any>> {
        val callLogs = mutableListOf<Map<String, Any>>()
        try {
            if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.M &&
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

            val todayFiles = cacheTodayFiles(customRecordingPath, todayStart)

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

                    val log = mapOf(
                        "phoneNumber" to number,
                        "contactName" to name,
                        "callType" to callTypeStr,
                        "startTime" to date,
                        "duration" to duration,
                        "recordingPath" to (recordingPath ?: "")
                    )
                    callLogs.add(log)
                }
            }
        } catch (e: Exception) {}
        return callLogs
    }

    private fun findCallRecordingOptimized(phoneNumber: String, startTimeMs: Long, durationSec: Int, todayFiles: List<File>): String? {
        val mediaPath = queryMediaStore(phoneNumber, startTimeMs, durationSec)
        if (mediaPath != null) return mediaPath

        try {
            val cleanPhone = phoneNumber.replace("[^0-9]".toRegex(), "")
            val startWindow = startTimeMs - 10000
            val endWindow = startTimeMs + (durationSec * 1000L) + 20000

            for (file in todayFiles) {
                val lastModified = file.lastModified()
                val name = file.name.lowercase()
                val isPhoneMatch = cleanPhone.isNotEmpty() && name.contains(cleanPhone)
                val isTimeMatch = lastModified in startWindow..endWindow

                if (isPhoneMatch && isTimeMatch) {
                    return file.absolutePath
                }
            }

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

}
