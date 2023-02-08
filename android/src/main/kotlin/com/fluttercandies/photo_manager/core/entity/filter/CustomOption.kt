package com.fluttercandies.photo_manager.core.entity.filter

import java.util.ArrayList

class CustomOption(private val map: Map<*, *>) : FilterOption() {

    override val containsPathModified: Boolean = map["containsPathModified"] as Boolean

    override fun orderByCondString(): String? {
        val orderBy = map["orderBy"] as String?
        if (orderBy != null && orderBy.trim().isEmpty()) {
            return null
        }
        return orderBy
    }

    override fun makeWhere(requestType: Int, args: ArrayList<String>, needAnd: Boolean): String {
        val where = map["where"] as String

        if (where.trim().isEmpty()) {
            return ""
        }

        if (needAnd && where.trim().isNotEmpty()) {
            return "AND ( $where )"
        }
        return "( $where )"
    }
}