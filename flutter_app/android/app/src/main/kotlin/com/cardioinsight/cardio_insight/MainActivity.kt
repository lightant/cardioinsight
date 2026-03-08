package com.cardioinsight.cardio_insight

import android.os.Bundle
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import com.google.mediapipe.tasks.genai.llminference.LlmInference
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import java.io.File

class MainActivity : FlutterFragmentActivity() {
    private val CHANNEL = "com.cardioinsight.cardio_insight/gemma"
    private var llmInference: LlmInference? = null
    private val scope = CoroutineScope(Dispatchers.IO)

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "initModel" -> {
                    if (llmInference != null) {
                        result.success(null)
                        return@setMethodCallHandler
                    }
                    scope.launch {
                        try {
                            val modelFile = copyAssetToCache("flutter_assets/assets/gemma-2b-it-gpu-int4.bin", "gemma-2b-it-gpu-int4.bin")
                            val options = LlmInference.LlmInferenceOptions.builder()
                                .setModelPath(modelFile.absolutePath)
                                .setMaxTokens(4096)
                                .setMaxTopK(40)
                                .setPreferredBackend(LlmInference.Backend.GPU)
                                .build()
                            
                            llmInference = LlmInference.createFromOptions(applicationContext, options)
                            withContext(Dispatchers.Main) {
                                result.success("GPU")
                            }
                        } catch (e: Exception) {
                            if (e.message?.contains("OpenCL") == true || e.message?.contains("cISetPerfHintQCOM") == true) {
                                try {
                                    val modelFile = copyAssetToCache("flutter_assets/assets/gemma-2b-it-gpu-int4.bin", "gemma-2b-it-gpu-int4.bin")
                                    val fallbackOptions = LlmInference.LlmInferenceOptions.builder()
                                        .setModelPath(modelFile.absolutePath)
                                        .setMaxTokens(4096)
                                        .setMaxTopK(40)
                                        .setPreferredBackend(LlmInference.Backend.CPU)
                                        .build()
                                    llmInference = LlmInference.createFromOptions(applicationContext, fallbackOptions)
                                    withContext(Dispatchers.Main) {
                                        result.success("CPU_FALLBACK")
                                    }
                                } catch (fallbackE: Exception) {
                                    withContext(Dispatchers.Main) {
                                        result.error("INIT_FAILED_FALLBACK", fallbackE.message, null)
                                    }
                                }
                            } else {
                                withContext(Dispatchers.Main) {
                                    result.error("INIT_FAILED", e.message, null)
                                }
                            }
                        }
                    }
                }
                "generateResponse" -> {
                    val prompt = call.argument<String>("prompt")
                    if (prompt == null) {
                        result.error("INVALID_ARGUMENT", "Prompt is required", null)
                        return@setMethodCallHandler
                    }
                    if (llmInference == null) {
                        result.error("NOT_INITIALIZED", "Model is not initialized", null)
                        return@setMethodCallHandler
                    }
                    scope.launch {
                        try {
                            val response = llmInference?.generateResponse(prompt)
                            withContext(Dispatchers.Main) {
                                result.success(response)
                            }
                        } catch (e: Exception) {
                            withContext(Dispatchers.Main) {
                                result.error("GENERATE_FAILED", e.message, null)
                            }
                        }
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun copyAssetToCache(assetPath: String, fileName: String): File {
        val cacheFile = File(cacheDir, fileName)
        if (!cacheFile.exists()) {
            applicationContext.assets.open(assetPath).use { inputStream ->
                cacheFile.outputStream().use { outputStream ->
                    inputStream.copyTo(outputStream)
                }
            }
        }
        return cacheFile
    }
}
