package com.cardioinsight.cardio_insight

import android.os.Bundle
import android.widget.TextView
import io.flutter.embedding.android.FlutterActivity

class PrivacyPolicyActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val textView = TextView(this)
        textView.text = "Privacy Policy: We only access heart rate data to display it in your dashboard. No data is shared with third parties."
        textView.setPadding(40, 40, 40, 40)
        setContentView(textView)
    }
}
