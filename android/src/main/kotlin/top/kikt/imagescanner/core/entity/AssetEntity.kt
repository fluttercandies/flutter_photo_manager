package top.kikt.imagescanner.core.entity

/// create 2019-09-05 by cai


data class AssetEntity(
        val id: String,
        val path: String,
        val duration: Long,
        val createDt: Long,
        val width: Int,
        val height: Int,
        val type: Int,
        val displayName:String
)