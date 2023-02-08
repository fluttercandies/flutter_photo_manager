package com.fluttercandies.photo_manager.core.entity.filter

import java.util.ArrayList

class CustomOption(private val map: Map<*, *>) : FilterOption() {

    override val containsPathModified: Boolean = map["containsPathModified"] as Boolean

    override fun orderByCondString(): String? {
        return map["orderBy"] as String?
    }

    override fun makeWhere(requestType: Int, args: ArrayList<String>, needAnd: Boolean): String {
        val where = map["where"] as String
        if (needAnd && where.trim().isNotEmpty()) {
            return "AND ( $where )"
        }
        return "( $where )"
    }
}