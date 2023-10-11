package com.fluttercandies.photo_manager.core.entity

enum class PermissionResult(val value: Int) {
    NotDetermined(0),
    Denied(2),
    Authorized(3),
    Limited(4),
}
