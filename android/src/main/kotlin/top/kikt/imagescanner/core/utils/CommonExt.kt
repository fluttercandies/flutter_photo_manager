package top.kikt.imagescanner.core.utils

import android.os.Build
import android.os.Environment

fun belowSdk(int: Int): Boolean {
  return Build.VERSION.SDK_INT < int
}

fun isExternalStorageLegacy(): Boolean {
  if (Build.VERSION.SDK_INT <= 28) {
    return true
  } else if (Build.VERSION.SDK_INT == 29) {
    return Environment.isExternalStorageLegacy()
  } else {
    return false
  }
}