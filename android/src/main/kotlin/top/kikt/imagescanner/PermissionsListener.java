package top.kikt.imagescanner;

/**
 * Created by Administrator on 2017/2/19.
 */

public interface PermissionsListener {

    void onDenied(String[] deniedPermissions);

    void onGranted();
}