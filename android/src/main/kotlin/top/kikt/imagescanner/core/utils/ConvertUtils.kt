package top.kikt.imagescanner.core.utils

import top.kikt.imagescanner.core.entity.AssetEntity
import top.kikt.imagescanner.core.entity.FilterOptions
import top.kikt.imagescanner.core.entity.GalleryEntity

/// create 2019-09-05 by cai


object ConvertUtils {
  fun convertToGalleryResult(list: List<GalleryEntity>): Map<String, Any> {
    val data = ArrayList<Map<String, Any>>()

    for (entity in list) {
      val element = mapOf(
          "id" to entity.id,
          "name" to entity.name,
          "length" to entity.length,
          "isAll" to entity.isAll
      )

      if (entity.length > 0) {
        data.add(element)
      }
    }

    return mapOf(
        "data" to data
    )
  }

  fun convertToAssetResult(list: List<AssetEntity>): Map<String, Any?> {
    val data = ArrayList<Map<String, Any?>>()

    for (entity in list) {
      val element = mapOf(
          "id" to entity.id,
          "duration" to entity.duration / 1000,
          "type" to entity.type,
          "createDt" to entity.createDt / 1000,
          "width" to entity.width,
          "height" to entity.height,
          "modifiedDt" to entity.modifiedDate,
          "lat" to entity.lat,
          "lng" to entity.lng,
          "title" to entity.displayName
      )
      data.add(element)
    }

    return mapOf(
        "data" to data
    )
  }

  fun convertToAssetResult(entity: AssetEntity): Map<String, Any?> {

    val data = mapOf(
        "id" to entity.id,
        "duration" to entity.duration,
        "type" to entity.type,
        "createDt" to entity.createDt / 1000,
        "width" to entity.width,
        "height" to entity.height,
        "modifiedDt" to entity.modifiedDate,
        "lat" to entity.lat,
        "lng" to entity.lng,
        "title" to entity.displayName
    )

    return mapOf(
        "data" to data
    )
  }

  fun convertFilterOptionsFromMap(map: Map<*, *>): FilterOptions {
    val filterOptions = FilterOptions()
    filterOptions.isShowTitle = map["title"] as Boolean

    val sizeConstraint = FilterOptions.SizeConstraint()
    filterOptions.sizeConstraint = sizeConstraint
    val sizeMap = map["size"] as Map<*, *>
    sizeConstraint.minWidth = sizeMap["minWidth"] as Int
    sizeConstraint.maxWidth = sizeMap["maxWidth"] as Int
    sizeConstraint.minHeight = sizeMap["minHeight"] as Int
    sizeConstraint.maxHeight = sizeMap["maxHeight"] as Int

    val durationConstraint = FilterOptions.DurationConstraint()
    filterOptions.durationConstraint = durationConstraint
    val durationMap = map["duration"] as Map<*, *>
    durationConstraint.min = (durationMap["min"] as Int).toLong()
    durationConstraint.max = (durationMap["max"] as Int).toLong()

    return filterOptions
  }
}