package com.fluttercandies.photo_manager.core.entity.filter

import java.util.ArrayList

class CustomOption(private val map: Map<*, *>) : FilterOption() {

    override val containsPathModified: Boolean = map["containsPathModified"] as Boolean

    override fun orderByCondString(): String? {
        val list = map["orderBy"] as? List<*>
        if (list.isNullOrEmpty()) {
            return null
        }
        return list.joinToString(",") {
            val map = it as Map<*, *>
            val column = map["column"] as String
            val isAsc = map["isAsc"] as Boolean
            "$column ${if (isAsc) "ASC" else "DESC"}"
        }
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