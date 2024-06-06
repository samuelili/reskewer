package com.example.paper_cropper

import android.R
import android.content.ClipData
import android.content.ClipboardManager
import android.widget.Toast
import androidx.annotation.NonNull
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File


class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.example.paper_cropper/battery"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler {
            call, result ->
            if (call.method == "copyImage") {
                copyImage(call.arguments as String)
            } else {
                result.notImplemented()
            }
        }
    }

    private fun copyImage(path: String): String {
        val clipboardManager = getSystemService(CLIPBOARD_SERVICE) as ClipboardManager

        val file = File(cacheDir, path)
//
//        val data = ClipData.newUri(contentResolver, "foooo", Uri.parse("content://${cacheDir.absolutePath}/${path}"))

        val uri = FileProvider.getUriForFile(
                this,
                "com.example.paper_cropper.fileprovider",
                file)
        val clip = ClipData.newUri(applicationContext.contentResolver, "a Photo", uri)
        clipboardManager.setPrimaryClip(clip)
        Toast.makeText(this, "Image copied to clipboard", Toast.LENGTH_SHORT).show()

        return path;
    }
}
