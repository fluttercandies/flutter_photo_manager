package top.kikt.imagescanner

import android.provider.MediaStore
import android.util.Log
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.PluginRegistry
import java.util.concurrent.Executors


class ImageScanner(val registrar: PluginRegistry.Registrar) {

    companion object {
        private val threadPool = Executors.newFixedThreadPool(5)
    }

    private val STORE_IMAGES = arrayOf(MediaStore.Images.Media.DISPLAY_NAME, // 显示的名字
            MediaStore.Images.Media.DATA, // 数据
            MediaStore.Images.Media.LONGITUDE, // 经度
            MediaStore.Images.Media._ID, // id
            MediaStore.Images.Media.MINI_THUMB_MAGIC, // id
            MediaStore.Images.Media.TITLE, // id
            MediaStore.Images.Media.BUCKET_ID, // dir id 目录
            MediaStore.Images.Media.BUCKET_DISPLAY_NAME, // dir name 目录名字
            MediaStore.Images.Media.DATE_TAKEN
    )


    var imgList = ArrayList<Img>()

    private fun scan() {
        Log.i("K", "start scan")
        val mImageUri = MediaStore.Images.Media.EXTERNAL_CONTENT_URI
        val mContentResolver = registrar.activity().contentResolver
        val mCursor = MediaStore.Images.Media.query(mContentResolver, mImageUri, STORE_IMAGES, null, MediaStore.Images.Media.DATE_TAKEN)

        val num = mCursor.count
        Log.i("K", "num = $num")
        mCursor.moveToLast()
        imgList.clear()
        idPathMap.clear()
        pathIdMap.clear()
        while (mCursor.moveToPrevious()) {
            val path = mCursor.getString(mCursor
                    .getColumnIndex(MediaStore.Images.Media.DATA))
            val dir = mCursor.getString(mCursor.getColumnIndex(MediaStore.Images.ImageColumns.BUCKET_DISPLAY_NAME))
            val dirId = mCursor.getString(mCursor.getColumnIndex(MediaStore.Images.ImageColumns.BUCKET_ID))
            val title = mCursor.getString(mCursor.getColumnIndex(MediaStore.Images.ImageColumns.TITLE))
            val thumb = mCursor.getString(mCursor.getColumnIndex(MediaStore.Images.ImageColumns.MINI_THUMB_MAGIC))
            val imgId = mCursor.getString(mCursor.getColumnIndex(MediaStore.Images.ImageColumns._ID))
            val img = Img(path, imgId, dir, dirId, title, thumb)
            imgList.add(img)

            idPathMap[dirId] = dir
            pathIdMap[dir] = dirId

            pathImgMap[path] = img
        }
        mCursor.close()
    }

    fun scanAndGetImageIdList(result: MethodChannel.Result) {
        threadPool.execute {
            scan()
            scanThumb()
            split()
            result.success(map.keys.toList())
        }
    }

    /// dirId,ImgList
    val map = HashMap<String, ArrayList<Img>>()

    val idPathMap = HashMap<String, String>()
    val pathIdMap = HashMap<String, String>()

    private fun split() {
        map.clear()
        val thumbHelper = ThumbHelper(registrar)
        imgList.forEach {
            var list = map[it.dirId]
            if (list == null) {
                list = ArrayList()
                map[it.dirId] = list
            }
            list.add(it)

            val thumb = thumbMap[it.imgId]
            if (thumb != null) {
                it.thumb = thumb
            }
        }

    }

    fun getPathListWithPathIds(call: MethodCall, result: MethodChannel.Result) {
        threadPool.execute {
            val r = ArrayList<String>()
            val list = call.arguments as List<Any>
            list.forEach {
                if (it is String) {
                    idPathMap[it]?.apply {
                        r.add(this)
                    }
                }
            }
            result.success(r)
        }
    }

    fun getImageListWithPathId(call: MethodCall, result: MethodChannel.Result) {
        threadPool.execute {
            val pathId = call.arguments as String
            val list = map[pathId]
            val r = list?.map { img ->
                img.path
            }
            result.success(r)
        }
    }


    fun getImageThumbListWithPathId(call: MethodCall, result: MethodChannel.Result) {
        threadPool.execute {
            val pathId = call.arguments as String
            val list = map[pathId]
            val r = list?.map { img ->
                img.thumb
            }
            result.success(r)
        }
    }

    var thumbMap = HashMap<String, String>()

    private fun scanThumb() {
        val mImageUri = MediaStore.Images.Thumbnails.EXTERNAL_CONTENT_URI
        val mContentResolver = registrar.activity().contentResolver
        val mCursor = MediaStore.Images.Media.query(mContentResolver, mImageUri, arrayOf(
                MediaStore.Images.Thumbnails.IMAGE_ID,
                MediaStore.Images.Thumbnails.DATA
        ), null, MediaStore.Images.Thumbnails.IMAGE_ID)
        thumbMap.clear()
        mCursor.moveToLast()
        while (mCursor.moveToPrevious()) {
            thumbMap[mCursor.getString(0)] = mCursor.getString(1)
        }

    }

    fun getThumb(call: MethodCall, result: MethodChannel.Result) {
        val path = call.arguments as String

    }

    val pathImgMap = HashMap<String, Img>()

    fun getImageThumb(call: MethodCall, result: MethodChannel.Result) {
        threadPool.execute {
            val path = call.arguments as String
            val img = pathImgMap[path]
            if (img == null) {
                result.success(null)
            } else {
                val thumb = ThumbHelper(registrar).getThumb(path, img.imgId)
                result.success(thumb)
            }
        }
    }

}