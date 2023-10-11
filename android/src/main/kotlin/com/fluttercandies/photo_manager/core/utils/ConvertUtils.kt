package com.fluttercandies.photo_manager.core.utils

import android.provider.MediaStore
import com.fluttercandies.photo_manager.constant.AssetType
import com.fluttercandies.photo_manager.core.entity.AssetEntity
import com.fluttercandies.photo_manager.core.entity.AssetPathEntity
import com.fluttercandies.photo_manager.core.entity.filter.CommonFilterOption
import com.fluttercandies.photo_manager.core.entity.filter.CustomOption
import com.fluttercandies.photo_manager.core.entity.filter.DateCond
import com.fluttercandies.photo_manager.core.entity.filter.FilterCond
import com.fluttercandies.photo_manager.core.entity.filter.FilterOption
import com.fluttercandies.photo_manager.core.entity.filter.OrderByCond

object ConvertUtils {
    fun convertPaths(list: List<AssetPathEntity>): Map<String, Any> {
        val data = ArrayList<Map<String, Any>>()
        for (entity in list) {
            if (entity.assetCount == 0) {
                continue
            }
            val element = mutableMapOf<String, Any>(
                "id" to entity.id,
                "name" to entity.name,
                "assetCount" to entity.assetCount,
                "isAll" to entity.isAll
            )
            if (entity.modifiedDate != null) {
                element["modified"] = entity.modifiedDate!!
            }
            data.add(element)
        }
        return mapOf("data" to data)
    }

    fun convertAssets(list: List<AssetEntity>): Map<String, Any?> {
        val data = ArrayList<Map<String, Any?>>()
        for (entity in list) {
            val result = convertAsset(entity)
            data.add(result)
        }
        return mapOf("data" to data)
    }

    fun convertAsset(entity: AssetEntity): Map<String, Any?> {
        val data = hashMapOf(
            "id" to entity.id.toString(),
            "duration" to entity.duration / 1000,
            "type" to entity.type,
            "createDt" to entity.createDt,
            "width" to entity.width,
            "height" to entity.height,
            "orientation" to entity.orientation,
            "modifiedDt" to entity.modifiedDate,
            "lat" to entity.lat,
            "lng" to entity.lng,
            "title" to entity.displayName,
            "relativePath" to entity.relativePath
        )
        if (entity.mimeType != null) {
            data["mimeType"] = entity.mimeType
        }
        return data
    }

    fun getOptionFromType(map: Map<*, *>, type: AssetType): FilterCond {
        val key = type.name.lowercase()
        if (map.containsKey(key)) {
            val value = map[key]
            if (value is Map<*, *>) {
                return convertToOption(value)
            }
        }
        return FilterCond()
    }

    private fun convertToOption(map: Map<*, *>): FilterCond {
        val filterOptions = FilterCond()
        filterOptions.isShowTitle = map["title"] as Boolean

        val sizeMap = map["size"] as Map<*, *>
        filterOptions.sizeConstraint = FilterCond.SizeConstraint().apply {
            minWidth = sizeMap["minWidth"] as Int
            maxWidth = sizeMap["maxWidth"] as Int
            minHeight = sizeMap["minHeight"] as Int
            maxHeight = sizeMap["maxHeight"] as Int
            ignoreSize = sizeMap["ignoreSize"] as Boolean
        }

        val durationMap = map["duration"] as Map<*, *>
        filterOptions.durationConstraint = FilterCond.DurationConstraint().apply {
            min = (durationMap["min"] as Int).toLong()
            max = (durationMap["max"] as Int).toLong()
            allowNullable = durationMap["allowNullable"] as Boolean
        }

        return filterOptions
    }

    fun convertToDateCond(map: Map<*, *>): DateCond {
        val min = map["min"].toString().toLong()
        val max = map["max"].toString().toLong()
        val ignore = map["ignore"].toString().toBoolean()
        return DateCond(min, max, ignore)
    }

    fun convertToFilterOptions(map: Map<*, *>): FilterOption {
        val type = map["type"] as Int
        val childMap = map["child"] as Map<*, *>
        if (type == 0) {
            return CommonFilterOption(childMap)
        } else if (type == 1) {
            return CustomOption(childMap)
        }
        throw IllegalStateException("Unknown type $type for filter option.")
    }

    fun convertToOrderByConds(orders: List<*>): List<OrderByCond> {
        val list = ArrayList<OrderByCond>()
        // Handle platform default sorting first.
        if (orders.isEmpty()) {
            // Use ID to sort by default.
            return arrayListOf(OrderByCond(MediaStore.MediaColumns._ID, false))
        }
        for (order in orders) {
            val map = order as Map<*, *>
            val keyIndex = map["type"] as Int
            val asc = map["asc"] as Boolean
            val key = when (keyIndex) {
                0 -> MediaStore.MediaColumns.DATE_ADDED
                1 -> MediaStore.MediaColumns.DATE_MODIFIED
                else -> null
            } ?: continue
            list.add(OrderByCond(key, asc))
        }
        return list
    }
}
