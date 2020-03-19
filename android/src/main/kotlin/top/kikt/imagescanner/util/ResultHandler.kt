package top.kikt.imagescanner.util


import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.MethodChannel

class ResultHandler(var result: MethodChannel.Result?) {
  
  companion object {
    private val handler = Handler(Looper.getMainLooper())
  }
  
  private var isReply = false
  
  fun reply(any: Any?) {
    if (isReply) {
      return
    }
    isReply = true
    val result = this.result
    this.result = null
    handler.post {
      result?.success(any)
    }
  }
  
  fun replyError(code: String, message: String? = null, obj: Any? = null) {
    if (isReply) {
      return
    }
    isReply = true
    val result = this.result
    this.result = null
    handler.post {
      result?.error(code, message, obj)
    }
  }
  
  fun notImplemented() {
    if (isReply) {
      return
    }
    isReply = true
    val result = this.result
    this.result = null
    handler.post {
      result?.notImplemented()
    }
  }
  
}