package top.kikt.imagescanner.core.permission;

/**
 * Created by Administrator on 2017/2/19.
 */

public interface PermissionsListener {

    void onDenied(String[] deniedPermissions);

    void onGranted();
}