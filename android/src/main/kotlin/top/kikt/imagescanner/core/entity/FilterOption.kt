package top.kikt.imagescanner.core.entity

import android.annotation.SuppressLint
import android.provider.MediaStore
import top.kikt.imagescanner.AssetType
import top.kikt.imagescanner.core.utils.ConvertUtils

class FilterOption(map: Map<*, *>) {
  
  val videoOption = ConvertUtils.getOptionFromType(map, AssetType.Video)
  val imageOption = ConvertUtils.getOptionFromType(map, AssetType.Image)
  val audioOption = ConvertUtils.getOptionFromType(map, AssetType.Audio)
  val dateCond = ConvertUtils.convertToDateCond(map["date"] as Map<*, *>)
}

class FilterCond {
  var isShowTitle = false
  lateinit var sizeConstraint: SizeConstraint
  lateinit var durationConstraint: DurationConstraint
  
  companion object {
    private const val widthKey = MediaStore.Files.FileColumns.WIDTH
    private const val heightKey = MediaStore.Files.FileColumns.HEIGHT
    @SuppressLint("InlinedApi")
    private const val durationKey = MediaStore.Video.VideoColumns.DURATION
  }
  
  fun sizeCond(): String {
    
    return "$widthKey >= ? AND $widthKey <= ? AND $heightKey >= ? AND $heightKey <=?"
  }
  
  fun sizeArgs(): Array<String> {
    return arrayOf(sizeConstraint.minWidth, sizeConstraint.maxWidth, sizeConstraint.minHeight, sizeConstraint.maxHeight).toList().map {
      it.toString()
    }.toTypedArray()
  }
  
  fun durationCond(): String {
    return "$durationKey >=? AND $durationKey <=?"
  }
  
  fun durationArgs(): Array<String> {
    return arrayOf(durationConstraint.min, durationConstraint.max).toList().map {
      it.toString()
    }.toTypedArray()
  }
  
  class SizeConstraint {
    var minWidth = 0
    var maxWidth = 0
    var minHeight = 0
    var maxHeight = 0
    var ignoreSize = false
  }
  
  class DurationConstraint {
    var min: Long = 0
    var max: Long = 0
    
  }
}

data class DateCond(
  val minMs: Long, val maxMs: Long, val asc: Boolean
)