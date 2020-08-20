package top.kikt.imagescanner.core

import android.app.Activity
import android.app.RecoverableSecurityException
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import io.flutter.plugin.common.PluginRegistry

class PhotoManagerDeleteManager(val context: Context, val activity: Activity?) : PluginRegistry.ActivityResultListener {

  private var requestCodeIndex = 3000

  private val uriMap = HashMap<Int, Uri>()

  private fun isHandleCode(requestCode: Int): Boolean {
    return uriMap.containsKey(requestCode)
  }

  private fun addRequestUri(uri: Uri): Int {
    val requestCode = requestCodeIndex
    requestCodeIndex++
    uriMap[requestCode] = uri
    return requestCode
  }

  fun deleteWithUri(uri: Uri, havePermission: Boolean) {
    val cr = context.contentResolver
    if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) {
      cr.delete(uri, null, null)
    } else {
      try {
        cr.delete(uri, null, null)
      } catch (e: Exception) {
        if (e is RecoverableSecurityException) {
          if (activity == null) {
            return
          }
          if (havePermission) {
            return
          }
          val requestCode = addRequestUri(uri)
          activity.startIntentSenderForResult(
              e.userAction.actionIntent.intentSender,
              requestCode,
              null,
              0,
              0,
              0
          )
        }
      }
    }
  }

  override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
    if (!isHandleCode(requestCode)) {
      return false;
    }

    val uri = uriMap.remove(requestCode) ?: return true
    if (resultCode == Activity.RESULT_OK) {
      // User allow delete asset.
      deleteWithUri(uri, true)
    }

    return true
  }
}