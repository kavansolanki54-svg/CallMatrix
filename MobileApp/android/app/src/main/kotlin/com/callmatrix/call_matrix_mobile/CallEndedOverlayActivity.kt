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
        val phoneNumber = intent.getStringExtra("phone_number") ?: ""
        // Trigger background REST sync silently on separate thread
        triggerBackgroundSync(phoneNumber)
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

    private fun triggerBackgroundSync(targetPhone: String) {
        // Delegate to the foreground service which handles sync with progress notification
        CallSyncForegroundService.start(this)
    }
}
