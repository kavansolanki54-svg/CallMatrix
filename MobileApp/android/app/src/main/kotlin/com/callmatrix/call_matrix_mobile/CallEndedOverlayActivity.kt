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
        val rootScroll = ScrollView(this).apply {
            isFillViewport = true
            setBackgroundColor(Color.parseColor("#44000000"))
        }

        val container = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER
            setPadding(dpToPx(16), dpToPx(24), dpToPx(16), dpToPx(24))
        }

        // --- 1. Notification Card Top Banner ---
        val notifCard = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(dpToPx(16), dpToPx(12), dpToPx(16), dpToPx(12))
            background = createCardDrawable(Color.WHITE, dpToPx(16).toFloat(), Color.parseColor("#E2E8F0"))
            val lp = LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT).apply {
                setMargins(0, 0, 0, dpToPx(12))
            }
            layoutParams = lp
        }

        val notifHeaderRow = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
        }

        val appIcon = TextView(this).apply {
            text = "🎯"
            textSize = 12f
        }

        val notifTitle = TextView(this).apply {
            text = "  CallMatrix • Now 🔔"
            setTextColor(Color.parseColor("#475569"))
            textSize = 12f
            typeface = Typeface.DEFAULT_BOLD
        }
        notifHeaderRow.addView(appIcon)
        notifHeaderRow.addView(notifTitle)
        notifCard.addView(notifHeaderRow)

        val displayName = if (contactName.isNotEmpty()) contactName else phoneNumber
        val notifBody = TextView(this).apply {
            text = "Tap to add notes for $displayName"
            setTextColor(Color.parseColor("#0F172A"))
            textSize = 15f
            typeface = Typeface.DEFAULT_BOLD
            setPadding(0, dpToPx(4), 0, 0)
        }
        notifCard.addView(notifBody)

        val notifSub = TextView(this).apply {
            text = "Notes"
            setTextColor(Color.parseColor("#64748B"))
            textSize = 13f
        }
        notifCard.addView(notifSub)

        container.addView(notifCard)

        // --- 2. Main "Last Call Details" Modal Card ---
        val mainCard = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(dpToPx(20), dpToPx(20), dpToPx(20), dpToPx(20))
            background = createCardDrawable(Color.WHITE, dpToPx(24).toFloat(), Color.parseColor("#CBD5E1"))
            val lp = LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT)
            layoutParams = lp
        }

        // Header: "Last Call Details" + "X"
        val headerRow = RelativeLayout(this).apply {
            setPadding(0, 0, 0, dpToPx(16))
        }

        val titleTxt = TextView(this).apply {
            text = "Last Call Details"
            setTextColor(Color.parseColor("#0F172A"))
            textSize = 18f
            typeface = Typeface.DEFAULT_BOLD
        }
        val titleParams = RelativeLayout.LayoutParams(
            RelativeLayout.LayoutParams.WRAP_CONTENT,
            RelativeLayout.LayoutParams.WRAP_CONTENT
        ).apply {
            addRule(RelativeLayout.ALIGN_PARENT_LEFT)
            addRule(RelativeLayout.CENTER_VERTICAL)
        }
        headerRow.addView(titleTxt, titleParams)

        val closeBtn = TextView(this).apply {
            text = "✕"
            setTextColor(Color.parseColor("#0F172A"))
            textSize = 20f
            typeface = Typeface.DEFAULT_BOLD
            setPadding(dpToPx(8), dpToPx(4), dpToPx(8), dpToPx(4))
            setOnClickListener { finish() }
        }
        val closeParams = RelativeLayout.LayoutParams(
            RelativeLayout.LayoutParams.WRAP_CONTENT,
            RelativeLayout.LayoutParams.WRAP_CONTENT
        ).apply {
            addRule(RelativeLayout.ALIGN_PARENT_RIGHT)
            addRule(RelativeLayout.CENTER_VERTICAL)
        }
        headerRow.addView(closeBtn, closeParams)

        mainCard.addView(headerRow)

        // Call From -> Call To Box
        val callBox = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
            setPadding(dpToPx(12), dpToPx(12), dpToPx(12), dpToPx(12))
            background = createCardDrawable(Color.parseColor("#F8FAFC"), dpToPx(12).toFloat(), Color.parseColor("#E2E8F0"))
            val lp = LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT).apply {
                setMargins(0, 0, 0, dpToPx(16))
            }
            layoutParams = lp
        }

        // Call From Column
        val callFromCol = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            val lp = LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.WRAP_CONTENT, 1f)
            layoutParams = lp
        }
        val callFromLbl = TextView(this).apply {
            text = "Call From"
            setTextColor(Color.parseColor("#0F172A"))
            textSize = 13f
            typeface = Typeface.DEFAULT_BOLD
        }
        val callFromVal = TextView(this).apply {
            text = callFromNumber
            setTextColor(Color.parseColor("#475569"))
            textSize = 12f
            setPadding(0, dpToPx(4), 0, 0)
        }
        callFromCol.addView(callFromLbl)
        callFromCol.addView(callFromVal)
        callBox.addView(callFromCol)

        // Arrow
        val arrowTxt = TextView(this).apply {
            text = "→  "
            setTextColor(Color.parseColor("#94A3B8"))
            textSize = 18f
            typeface = Typeface.DEFAULT_BOLD
        }
        callBox.addView(arrowTxt)

        // Call To Column
        val callToCol = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            val lp = LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.WRAP_CONTENT, 1.2f)
            layoutParams = lp
        }
        val callToLbl = TextView(this).apply {
            text = "Call To"
            setTextColor(Color.parseColor("#0F172A"))
            textSize = 13f
            typeface = Typeface.DEFAULT_BOLD
        }
        val callToName = TextView(this).apply {
            text = contactName.ifEmpty { phoneNumber }
            setTextColor(Color.parseColor("#0F172A"))
            textSize = 12f
            typeface = Typeface.DEFAULT_BOLD
            setPadding(0, dpToPx(2), 0, 0)
        }
        val callToNum = TextView(this).apply {
            text = phoneNumber
            setTextColor(Color.parseColor("#475569"))
            textSize = 11f
        }
        callToCol.addView(callToLbl)
        callToCol.addView(callToName)
        if (contactName.isNotEmpty()) {
            callToCol.addView(callToNum)
        }
        callBox.addView(callToCol)

        mainCard.addView(callBox)

        // Call Stats Section
        val statsRow = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
            setPadding(0, dpToPx(8), 0, dpToPx(16))
        }

        // Col 1: Call Type
        val typeCol = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            val lp = LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.WRAP_CONTENT, 1f)
            layoutParams = lp
        }
        val typeLbl = TextView(this).apply {
            text = "Call Type"
            setTextColor(Color.parseColor("#0F172A"))
            textSize = 14f
            typeface = Typeface.DEFAULT_BOLD
        }
        val typeValRow = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
            setPadding(0, dpToPx(4), 0, 0)
        }
        val typeIconText = TextView(this).apply {
            val isOut = callType.contains("Outgoing", ignoreCase = true)
            text = if (isOut) "📞 Outgoing " else "📞 Incoming "
            setTextColor(if (isOut) Color.parseColor("#D97706") else Color.parseColor("#16A34A"))
            textSize = 12f
            typeface = Typeface.DEFAULT_BOLD
        }
        val simBadge = TextView(this).apply {
            text = " 1 "
            setTextColor(Color.parseColor("#475569"))
            textSize = 10f
            setPadding(dpToPx(4), dpToPx(1), dpToPx(4), dpToPx(1))
            background = createCardDrawable(Color.TRANSPARENT, dpToPx(4).toFloat(), Color.parseColor("#CBD5E1"))
        }
        typeValRow.addView(typeIconText)
        typeValRow.addView(simBadge)
        typeCol.addView(typeLbl)
        typeCol.addView(typeValRow)
        statsRow.addView(typeCol)

        // Col 2: Duration
        val durCol = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            val lp = LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.WRAP_CONTENT, 1f)
            layoutParams = lp
        }
        val durLbl = TextView(this).apply {
            text = "Duration"
            setTextColor(Color.parseColor("#0F172A"))
            textSize = 14f
            typeface = Typeface.DEFAULT_BOLD
        }
        val durVal = TextView(this).apply {
            text = "⏱ $callDuration"
            setTextColor(Color.parseColor("#334155"))
            textSize = 12f
            setPadding(0, dpToPx(4), 0, 0)
        }
        durCol.addView(durLbl)
        durCol.addView(durVal)
        statsRow.addView(durCol)

        // Col 3: Call Time
        val timeCol = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            val lp = LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.WRAP_CONTENT, 1f)
            layoutParams = lp
        }
        val timeLbl = TextView(this).apply {
            text = "Call Time"
            setTextColor(Color.parseColor("#0F172A"))
            textSize = 14f
            typeface = Typeface.DEFAULT_BOLD
        }
        val timeVal = TextView(this).apply {
            text = "🕒 $timeStr"
            setTextColor(Color.parseColor("#334155"))
            textSize = 12f
            setPadding(0, dpToPx(4), 0, 0)
        }
        timeCol.addView(timeLbl)
        timeCol.addView(timeVal)
        statsRow.addView(timeCol)

        mainCard.addView(statsRow)

        // Divider
        val divider = View(this).apply {
            setBackgroundColor(Color.parseColor("#E2E8F0"))
            val lp = LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, dpToPx(1)).apply {
                setMargins(0, 0, 0, dpToPx(16))
            }
            layoutParams = lp
        }
        mainCard.addView(divider)

        // Add Note Section Header
        val addNoteLbl = TextView(this).apply {
            text = "Add Note"
            setTextColor(Color.parseColor("#0F172A"))
            textSize = 15f
            typeface = Typeface.DEFAULT_BOLD
            setPadding(0, 0, 0, dpToPx(8))
        }
        mainCard.addView(addNoteLbl)

        // Add Note Container Box
        val noteContainer = RelativeLayout(this).apply {
            background = createCardDrawable(Color.WHITE, dpToPx(12).toFloat(), Color.parseColor("#CBD5E1"))
            setPadding(dpToPx(12), dpToPx(12), dpToPx(12), dpToPx(12))
            val lp = LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT).apply {
                setMargins(0, 0, 0, dpToPx(16))
            }
            layoutParams = lp
        }

        noteEditText = EditText(this).apply {
            id = View.generateViewId()
            hint = "Type your call summary or use '/' to add call note template(s) quickly."
            setHintTextColor(Color.parseColor("#94A3B8"))
            setTextColor(Color.parseColor("#0F172A"))
            textSize = 13f
            minLines = 3
            maxLines = 5
            gravity = Gravity.TOP or Gravity.LEFT
            background = null
            inputType = InputType.TYPE_CLASS_TEXT or InputType.TYPE_TEXT_FLAG_MULTI_LINE
        }
        val editParams = RelativeLayout.LayoutParams(
            RelativeLayout.LayoutParams.MATCH_PARENT,
            RelativeLayout.LayoutParams.WRAP_CONTENT
        ).apply {
            setMargins(0, 0, dpToPx(36), 0)
        }
        noteContainer.addView(noteEditText, editParams)

        // Voice Microphone Button
        val micBtn = TextView(this).apply {
            text = "🎤"
            textSize = 18f
            setPadding(dpToPx(6), dpToPx(6), dpToPx(6), dpToPx(6))
            background = createCardDrawable(Color.parseColor("#F1F5F9"), dpToPx(20).toFloat(), Color.parseColor("#CBD5E1"))
            setOnClickListener { triggerSpeechToText() }
        }
        val micParams = RelativeLayout.LayoutParams(
            RelativeLayout.LayoutParams.WRAP_CONTENT,
            RelativeLayout.LayoutParams.WRAP_CONTENT
        ).apply {
            addRule(RelativeLayout.ALIGN_PARENT_RIGHT)
            addRule(RelativeLayout.ALIGN_PARENT_BOTTOM)
        }
        noteContainer.addView(micBtn, micParams)

        mainCard.addView(noteContainer)

        // Action Buttons Row
        val actionRow = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER
        }

        val btn1 = createActionButton("Save & Exit") {
            saveNoteAndClose("Exit")
        }
        val btn2 = createActionButton("Save &\nConnect") {
            saveNoteAndClose("Connect")
        }
        val btn3 = createActionButton("Save & Add\nLead") {
            saveNoteAndClose("AddLead")
        }

        actionRow.addView(btn1)
        actionRow.addView(btn2)
        actionRow.addView(btn3)

        mainCard.addView(actionRow)

        container.addView(mainCard)
        rootScroll.addView(container)
        return rootScroll
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
        val noteText = noteEditText?.text?.toString()?.trim() ?: ""
        Toast.makeText(this, "Note Saved ($actionType)", Toast.LENGTH_SHORT).show()
        finish()
    }

    private fun createCardDrawable(bgColor: Int, cornerRadiusPx: Float, strokeColor: Int): GradientDrawable {
        return GradientDrawable().apply {
            setColor(bgColor)
            cornerRadius = cornerRadiusPx
            if (strokeColor != Color.TRANSPARENT) {
                setStroke(dpToPx(1), strokeColor)
            }
        }
    }

    private fun dpToPx(dp: Int): Int {
        return (dp * resources.displayMetrics.density).toInt()
    }
}
