package com.callalyze.call_alyze_mobile

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.graphics.Typeface
import android.graphics.drawable.ColorDrawable
import android.graphics.drawable.GradientDrawable
import android.os.Bundle
import android.view.Gravity
import android.view.View
import android.view.Window
import android.view.WindowManager
import android.widget.*
import java.text.SimpleDateFormat
import java.util.*

class CallEndedOverlayActivity : Activity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        requestWindowFeature(Window.FEATURE_NO_TITLE)
        window.setBackgroundDrawable(ColorDrawable(Color.TRANSPARENT))
        window.setLayout(WindowManager.LayoutParams.MATCH_PARENT, WindowManager.LayoutParams.MATCH_PARENT)
        window.setGravity(Gravity.CENTER)
        window.addFlags(
            WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL or
                    WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                    WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON or
                    WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON
        )

        val phoneNumber = intent.getStringExtra("phone_number") ?: "Unknown Number"
        val contactName = intent.getStringExtra("contact_name") ?: ""
        val callDuration = intent.getStringExtra("call_duration") ?: "0s"
        val callType = intent.getStringExtra("call_type") ?: "Outgoing"
        val currentTimeStr = intent.getStringExtra("call_time") 
            ?: SimpleDateFormat("hh:mm a", Locale.getDefault()).format(Date())

        setContentView(buildLayout(phoneNumber, contactName, callDuration, currentTimeStr, callType))
    }

    private fun buildLayout(
        phoneNumber: String,
        contactName: String,
        callDuration: String,
        timeStr: String,
        callType: String
    ): View {
        // Read theme settings from Flutter Shared Preferences
        val prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        val themeStr = prefs.getString("flutter.theme_mode", "system")
        
        val isDark = when (themeStr) {
            "dark" -> true
            "light" -> false
            else -> {
                val currentNightMode = resources.configuration.uiMode and android.content.res.Configuration.UI_MODE_NIGHT_MASK
                currentNightMode == android.content.res.Configuration.UI_MODE_NIGHT_YES
            }
        }

        // Palette definitions
        val bgOverColor = if (isDark) "#CC0C111D" else "#99475569"
        val cardBgColor = if (isDark) "#1D2939" else "#FFFFFF"
        val cardBorderColor = if (isDark) "#334155" else "#E2E8F0"
        val titleColor = if (isDark) "#FFFFFF" else "#0F172A"
        val phoneColor = if (isDark) "#94A3B8" else "#475569"
        val labelColor = if (isDark) "#94A3B8" else "#64748B"
        val valColor = if (isDark) "#FFFFFF" else "#0F172A"
        val dividerColor = if (isDark) "#334155" else "#F1F5F9"
        val primaryColor = "#0070F3"

        val root = FrameLayout(this).apply {
            setBackgroundColor(Color.parseColor(bgOverColor))
        }

        // Dialog Box Card Container
        val dialogBox = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER_HORIZONTAL
            setPadding(dpToPx(24), dpToPx(24), dpToPx(24), dpToPx(24))
            
            background = createCardDrawable(
                Color.parseColor(cardBgColor), 
                dpToPx(20).toFloat(), 
                Color.parseColor(cardBorderColor)
            )

            val lp = FrameLayout.LayoutParams(
                dpToPx(300),
                FrameLayout.LayoutParams.WRAP_CONTENT
            ).apply {
                gravity = Gravity.CENTER
            }
            layoutParams = lp
        }

        // Header Title: Callalyze
        val headerTitle = TextView(this).apply {
            text = "Callalyze"
            setTextColor(Color.parseColor(primaryColor))
            textSize = 12f
            typeface = Typeface.create("sans-serif-medium", Typeface.BOLD)
            gravity = Gravity.CENTER_HORIZONTAL
            val lp = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.WRAP_CONTENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            ).apply {
                setMargins(0, 0, 0, dpToPx(16))
            }
            layoutParams = lp
        }
        dialogBox.addView(headerTitle)

        // Initials Avatar
        val displayName = if (contactName.isNotEmpty()) contactName else phoneNumber
        val initials = if (displayName.isNotEmpty()) displayName[0].toString().uppercase() else "?"
        
        val avatarContainer = FrameLayout(this).apply {
            val size = dpToPx(56)
            val lp = LinearLayout.LayoutParams(size, size).apply {
                setMargins(0, 0, 0, dpToPx(12))
            }
            layoutParams = lp
            
            background = GradientDrawable().apply {
                shape = GradientDrawable.OVAL
                setColor(Color.parseColor(if (isDark) "#1E293B" else "#F1F5F9"))
                setStroke(dpToPx(1), Color.parseColor(primaryColor))
            }
        }

        val avatarText = TextView(this).apply {
            text = initials
            setTextColor(Color.parseColor(primaryColor))
            textSize = 20f
            typeface = Typeface.DEFAULT_BOLD
            gravity = Gravity.CENTER
            val lp = FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.MATCH_PARENT,
                FrameLayout.LayoutParams.MATCH_PARENT
            )
            layoutParams = lp
        }
        avatarContainer.addView(avatarText)
        dialogBox.addView(avatarContainer)

        // Contact Name
        val nameTxt = TextView(this).apply {
            text = if (contactName.isNotEmpty()) contactName else "Unknown Contact"
            setTextColor(Color.parseColor(titleColor))
            textSize = 16f
            typeface = Typeface.create("sans-serif-medium", Typeface.BOLD)
            gravity = Gravity.CENTER_HORIZONTAL
            val lp = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.WRAP_CONTENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            ).apply {
                setMargins(0, 0, 0, dpToPx(2))
            }
            layoutParams = lp
        }
        dialogBox.addView(nameTxt)

        // Phone Number
        val phoneTxt = TextView(this).apply {
            text = phoneNumber
            setTextColor(Color.parseColor(phoneColor))
            textSize = 13f
            typeface = Typeface.create("sans-serif", Typeface.NORMAL)
            gravity = Gravity.CENTER_HORIZONTAL
            val lp = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.WRAP_CONTENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            ).apply {
                setMargins(0, 0, 0, dpToPx(16))
            }
            layoutParams = lp
        }
        dialogBox.addView(phoneTxt)

        // Divider
        val div1 = View(this).apply {
            setBackgroundColor(Color.parseColor(dividerColor))
            val lp = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                dpToPx(1)
            ).apply {
                setMargins(0, 0, 0, dpToPx(12))
            }
            layoutParams = lp
        }
        dialogBox.addView(div1)

        // Metadata Table
        val displayDuration = if (callDuration.contains("0h 0m")) callDuration.replace("0h 0m ", "") else callDuration
        
        dialogBox.addView(buildDetailRow("Duration", displayDuration, labelColor, valColor))
        dialogBox.addView(buildDetailSpacer())
        dialogBox.addView(buildDetailRow("Time", timeStr, labelColor, valColor))
        dialogBox.addView(buildDetailSpacer())

        val isMissed = callType.lowercase(Locale.getDefault()) == "missed"
        val statusText = if (isMissed) "Missed" else "Answered"
        val statusColorStr = if (isMissed) "#EF4444" else (if (isDark) "#38BDF8" else "#0070F3")
        val badgeBgColorStr = if (isMissed) "#26EF4444" else (if (isDark) "#1A38BDF8" else "#1A0070F3")

        val typeRow = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            val lp = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            ).apply {
                setMargins(0, 0, 0, dpToPx(20))
            }
            layoutParams = lp
        }

        val typeLabel = TextView(this).apply {
            text = "Status"
            setTextColor(Color.parseColor(labelColor))
            textSize = 13f
            typeface = Typeface.create("sans-serif", Typeface.BOLD)
            val lp = LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.WRAP_CONTENT, 1f)
            layoutParams = lp
        }
        typeRow.addView(typeLabel)

        val typeBadgeContainer = FrameLayout(this).apply {
            background = GradientDrawable().apply {
                cornerRadius = dpToPx(6).toFloat()
                setColor(Color.parseColor(badgeBgColorStr))
            }
            setPadding(dpToPx(8), dpToPx(4), dpToPx(8), dpToPx(4))
        }

        val typeBadgeText = TextView(this).apply {
            text = statusText
            setTextColor(Color.parseColor(statusColorStr))
            textSize = 11f
            typeface = Typeface.create("sans-serif", Typeface.BOLD)
        }
        typeBadgeContainer.addView(typeBadgeText)
        typeRow.addView(typeBadgeContainer)
        dialogBox.addView(typeRow)

        // Action Button: Save & Close
        val doneBtn = Button(this).apply {
            text = "Close"
            setTextColor(Color.WHITE)
            textSize = 14f
            typeface = Typeface.create("sans-serif-medium", Typeface.BOLD)
            isAllCaps = false
            
            background = GradientDrawable().apply {
                cornerRadius = dpToPx(24).toFloat()
                setColor(Color.parseColor(primaryColor))
            }

            setOnClickListener {
                saveNoteAndClose()
            }

            val lp = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                dpToPx(44)
            )
            layoutParams = lp
        }
        dialogBox.addView(doneBtn)

        root.addView(dialogBox)
        return root
    }

    private fun buildDetailRow(label: String, value: String, labelColor: String, valColor: String): View {
        return LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            val lp = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            )
            layoutParams = lp

            val labelTxt = TextView(context).apply {
                text = label
                setTextColor(Color.parseColor(labelColor))
                textSize = 13f
                typeface = Typeface.create("sans-serif", Typeface.BOLD)
                val lp2 = LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.WRAP_CONTENT, 1f)
                layoutParams = lp2
            }
            addView(labelTxt)

            val valTxt = TextView(context).apply {
                text = value
                setTextColor(Color.parseColor(valColor))
                textSize = 13f
                typeface = Typeface.create("sans-serif", Typeface.BOLD)
            }
            addView(valTxt)
        }
    }

    private fun buildDetailSpacer(): View {
        return View(this).apply {
            val lp = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                dpToPx(10)
            )
            layoutParams = lp
        }
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

    private fun saveNoteAndClose() {
        val phoneNumber = intent.getStringExtra("phone_number") ?: ""
        // Trigger background sync foreground service
        CallSyncForegroundService.start(this)
        finish()
    }
}
