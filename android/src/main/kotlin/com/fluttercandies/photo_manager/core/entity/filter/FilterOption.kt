package com.fluttercandies.photo_manager.core.entity.filter

import java.util.ArrayList

abstract class FilterOption {
    abstract val containsPathModified: Boolean

    abstract fun orderByCondString(): String?

    abstract fun makeWhere(requestType: Int, args: ArrayList<String>, needAnd: Boolean = true): String
}