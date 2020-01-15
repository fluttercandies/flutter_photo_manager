package top.kikt.imagescanner.util;
/// create 2019-07-16 by cai


import android.util.Log;

public class LogUtils {

  public static final String TAG = "PhotoManagerPlugin";

  public static boolean isLog = false;

  public static void info(Object object) {
    if (!isLog) {
      return;
    }
    String msg;
    if (object == null) {
      msg = "null";
    } else {
      msg = object.toString();
    }
    Log.i(TAG, msg);
  }

  public static void debug(Object object) {
    if (!isLog) {
      return;
    }
    String msg;
    if (object == null) {
      msg = "null";
    } else {
      msg = object.toString();
    }
    Log.d(TAG, msg);
  }

  public static void error(Object object, Throwable error) {
    if (!isLog) {
      return;
    }
    String msg;
    if (object == null) {
      msg = "null";
    } else {
      msg = object.toString();
    }
    Log.e(TAG, msg, error);
  }

  public static void error(Object object) {
    if (!isLog) {
      return;
    }
    String msg;
    if (object == null) {
      msg = "null";
    } else {
      msg = object.toString();
    }
    Log.e(TAG, msg);
  }
}
