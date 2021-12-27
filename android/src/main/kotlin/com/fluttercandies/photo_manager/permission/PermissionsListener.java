package com.fluttercandies.photo_manager.permission;

import java.util.List;

public interface PermissionsListener {
    void onDenied(List<String> deniedPermissions, List<String> grantedPermissions);

    void onGranted();
}
