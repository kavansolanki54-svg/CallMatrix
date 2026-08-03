package com.callmatrix.call_matrix_mobile

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.ContactsContract
import android.telephony.TelephonyManager
import androidx.core.app.NotificationCompat
import java.text.SimpleDateFormat
import java.util.*

class CallStateReceiver : BroadcastReceiver() {
    companion object {
        private var lastState = TelephonyManager.CALL_STATE_IDLE
        private var isIncoming = false
        private var isAnswered = false
        private var savedNumber: String? = null
        private var callStartTime: Long = 0
        private const val CHANNEL_ID = "call_sync_channel"
        private const val NOTIFICATION_ID = 1001
    }

    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == TelephonyManager.ACTION_PHONE_STATE_CHANGED) {
            val stateStr = intent.extras?.getString(TelephonyManager.EXTRA_STATE)
            val number = intent.extras?.getString(TelephonyManager.EXTRA_INCOMING_NUMBER)

            if (stateStr != null) {
                var state = TelephonyManager.CALL_STATE_IDLE
                if (stateStr == TelephonyManager.EXTRA_STATE_RINGING) {
                    state = TelephonyManager.CALL_STATE_RINGING
                } else if (stateStr == TelephonyManager.EXTRA_STATE_OFFHOOK) {
                    state = TelephonyManager.CALL_STATE_OFFHOOK
                }

                onCustomCallStateChanged(context, state, number)
            }
        }
    }

    private fun onCustomCallStateChanged(context: Context, state: Int, number: String?) {
        if (lastState == state) {
            return
        }

        if (!number.isNullOrEmpty()) {
            savedNumber = number
        }

        when (state) {
            TelephonyManager.CALL_STATE_RINGING -> {
                isIncoming = true
                isAnswered = false
            }
            TelephonyManager.CALL_STATE_OFFHOOK -> {
                isAnswered = true
                callStartTime = System.currentTimeMillis()
            }
            TelephonyManager.CALL_STATE_IDLE -> {
                if (lastState == TelephonyManager.CALL_STATE_OFFHOOK || lastState == TelephonyManager.CALL_STATE_RINGING) {
                    val durationSec = if (callStartTime > 0) ((System.currentTimeMillis() - callStartTime) / 1000).toInt() else 0
                    val hours = durationSec / 3600
                    val mins = (durationSec % 3600) / 60
                    val secs = durationSec % 60
                    val durationStr = "${hours}h ${mins}m ${secs}s"
                    val timeStr = SimpleDateFormat("hh:mm a", Locale.getDefault()).format(Date())

                    val callType = when {
                        isIncoming && isAnswered -> "Incoming"
                        isIncoming && !isAnswered -> "Missed"
                        !isIncoming && !isAnswered -> "Rejected"
                        else -> "Outgoing"
                    }

                    val targetNumber = savedNumber ?: "Unknown"
                    val contactName = getContactName(context, targetNumber)

                    showTruecallerStyleNotification(context, targetNumber, contactName, callType)
                    launchOverlayPopup(context, targetNumber, contactName, callType, durationStr, timeStr)
                }
                isIncoming = false
                isAnswered = false
                savedNumber = null
                callStartTime = 0
            }
        }
        lastState = state
    }

    private fun getContactName(context: Context, phoneNumber: String): String {
        if (phoneNumber.isEmpty() || phoneNumber == "Unknown") return ""
        try {
            val uri = Uri.withAppendedPath(ContactsContract.PhoneLookup.CONTENT_FILTER_URI, Uri.encode(phoneNumber))
            val projection = arrayOf(ContactsContract.PhoneLookup.DISPLAY_NAME)
            val cursor = context.contentResolver.query(uri, projection, null, null, null)
            cursor?.use {
                if (it.moveToFirst()) {
                    val nameIdx = it.getColumnIndex(ContactsContract.PhoneLookup.DISPLAY_NAME)
                    if (nameIdx >= 0) {
                        return it.getString(nameIdx) ?: ""
                    }
                }
            }
        } catch (e: Exception) {}
        return ""
    }

    private fun launchOverlayPopup(
        context: Context,
        phoneNumber: String,
        contactName: String,
        callType: String,
        durationStr: String,
        timeStr: String
    ) {
        try {
            val popupIntent = Intent(context, CallEndedOverlayActivity::class.java).apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP)
                addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP)
                putExtra("phone_number", phoneNumber)
                putExtra("contact_name", contactName)
                putExtra("call_from", if (callType.contains("Incoming", ignoreCase = true)) phoneNumber else "My Device")
                putExtra("call_to", if (callType.contains("Incoming", ignoreCase = true)) "My Device" else phoneNumber)
                putExtra("call_type", callType)
                putExtra("call_duration", durationStr)
                putExtra("call_time", timeStr)
            }
            context.startActivity(popupIntent)
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    private fun showTruecallerStyleNotification(context: Context, phoneNumber: String, contactName: String, callType: String) {
        val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Call Sync & AI Summary",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Shows notifications and sync options after call ends"
                enableVibration(true)
            }
            notificationManager.createNotificationChannel(channel)
        }

        val launchIntent = Intent(context, MainActivity::class.java).apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
            putExtra("call_ended", true)
            putExtra("phone_number", phoneNumber)
        }

        val pendingIntent = PendingIntent.getActivity(
            context,
            0,
            launchIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val titleName = contactName.ifEmpty { phoneNumber }

        val notification = NotificationCompat.Builder(context, CHANNEL_ID)
            .setSmallIcon(android.R.drawable.ic_menu_call)
            .setContentTitle("$callType Call — $titleName")
            .setContentText("Tap to add notes and sync call log")
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setCategory(NotificationCompat.CATEGORY_CALL)
            .setDefaults(NotificationCompat.DEFAULT_ALL)
            .setAutoCancel(true)
            .setContentIntent(pendingIntent)
            .setFullScreenIntent(pendingIntent, true)
            .build()

        notificationManager.notify(NOTIFICATION_ID, notification)
    }
}
