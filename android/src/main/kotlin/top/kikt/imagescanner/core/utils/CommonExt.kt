package top.kikt.imagescanner.core.utils

import android.os.Build

fun belowSdk(int: Int): Boolean {
  return Build.VERSION.SDK_INT < int
}