package top.kikt.imagescanner.core

import android.content.Context
import android.net.Uri
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import top.kikt.imagescanner.util.LogUtils
import java.io.InputStream

class StreamManager(val context: Context, messenger: BinaryMessenger, id: String, val uri: Uri) : MethodChannel.MethodCallHandler {
  private val channelName = "top.kikt/photo_manager/stream/$id"
  private val channel: MethodChannel = MethodChannel(messenger, channelName)

  private var running = false

  private var stream: InputStream? = null

  fun handleChannel() {
    channel.setMethodCallHandler(this)
  }

  fun toMap(): Map<*, *> {
    return mapOf(
            "channelName" to channelName,
            "running" to running
    )
  }

  private fun start() {
    if (running) {
      return
    }
    running = true
    val stream: InputStream
    try {
      val inputStream = context.contentResolver.openInputStream(uri)
      if (inputStream == null) {
        reportError(mapOf("error" to "cannot open uri"))
        return
      }
      stream = inputStream
      this.stream = stream
    } catch (e: Exception) {
      LogUtils.error("Cannot load $uri", e)
      reportError(mapOf("error" to e.localizedMessage))
      return
    }

    val bufferSize = 1 shl 20
    val buffer = ByteArray(bufferSize)

    var len = 0

    try {
      while (true) {
        len = stream.read(buffer)
        if (len == -1) {
          onCompletion()
          break
        }
        writeData(buffer, len)
      }
    } catch (e: Exception) {
      reportError(e)
    } finally {
      stream.close()
    }

  }

  private fun writeData(buffer: ByteArray, len: Int) {
    val data: ByteArray =
            if (len == buffer.count()) {
              buffer
            } else {
              val dst = ByteArray(len)
              buffer.copyInto(dst, endIndex = len)
              dst
            }
    channel.invokeMethod("onReceived", mapOf("data" to data))
  }

  private fun onCompletion() {
    running = false
    channel.invokeMethod("completion", emptyMap<String, String>())
  }

  private fun stop() {
    running = false
    stream?.close()
  }

  fun onRelease() {
    stop()
    channel.setMethodCallHandler(null)
  }

  private fun reportError(any: Any) {
    channel.invokeMethod("happenError", mapOf("error" to any.toString()))
    running = false
  }

  override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
    when (call.method) {
      "start" -> {
        start()
        result.success(true)
      }
      "stop" -> {
        stop()
        result.success(true)
      }
    }
  }

}