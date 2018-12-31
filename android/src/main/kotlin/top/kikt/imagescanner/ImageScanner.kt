package top.kikt.imagescanner

import android.os.Handler
import android.provider.MediaStore
import android.util.Log
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.PluginRegistry
import top.kikt.imagescanner.thumb.ThumbnailUtil
import java.io.File
import java.util.concurrent.*


class ImageScanner(val registrar: PluginRegistry.Registrar) {

    companion object {
        private const val poolSize = 8
        private val thumbPool = ThreadPoolExecutor(poolSize, 1000, 200, TimeUnit.MINUTES, ArrayBlockingQueue<Runnable>(5))

        private val threadPool: ThreadPoolExecutor = ThreadPoolExecutor(poolSize + 3, 1000, 200, TimeUnit.MINUTES, ArrayBlockingQueue<Runnable>(poolSize + 3))

        var handler: Handler = Handler()
    }

    private val thumbHelper = ThumbHelper(registrar)

    private val storeImageKeys = arrayOf(MediaStore.Images.Media.DISPLAY_NAME, // 显示的名字
            MediaStore.Images.Media.DATA, // 数据
            MediaStore.Images.Media.LONGITUDE, // 经度
            MediaStore.Images.Media._ID, // id
            MediaStore.Images.Media.MINI_THUMB_MAGIC, // id
            MediaStore.Images.Media.TITLE, // id
            MediaStore.Images.Media.BUCKET_ID, // dir id 目录
            MediaStore.Images.Media.BUCKET_DISPLAY_NAME, // dir name 目录名字
            MediaStore.Images.Media.DATE_TAKEN //日期
    )


    private val storeVideoKeys = arrayOf(MediaStore.Video.Media.DISPLAY_NAME, // 显示的名字
            MediaStore.Video.Media.DATA, // 数据
            MediaStore.Video.Media.LONGITUDE, // 经度
            MediaStore.Video.Media._ID, // id
            MediaStore.Video.Media.MINI_THUMB_MAGIC, // id
            MediaStore.Video.Media.TITLE, // id
            MediaStore.Video.Media.BUCKET_ID, // dir id 目录
            MediaStore.Video.Media.BUCKET_DISPLAY_NAME, // dir name 目录名字
            MediaStore.Video.Media.DATE_TAKEN, //日期
            MediaStore.Video.Media.DURATION //时长
    )


    private var imgList = ArrayList<Img>()

    private fun scan() {
        Log.i("K", "start scan")
        imgList.clear()
        idPathMap.clear()
        pathIdMap.clear()
        pathImgMap.clear()

        scanVideo()
        scanImage()
        sortAsset()
    }

    private fun sortAsset() {
        imgList.sortWith(Comparator { o1, o2 ->
            o2.timeStamp.compareTo(o1.timeStamp)
        })
    }

    private fun scanImage() {
        val mImageUri = MediaStore.Images.Media.EXTERNAL_CONTENT_URI
        val mContentResolver = registrar.activity().contentResolver
        val mCursor = MediaStore.Images.Media.query(mContentResolver, mImageUri, storeImageKeys, null, MediaStore.Images.Media.DATE_TAKEN)
        val num = mCursor.count
        Log.i("K", "num = $num")

        if (num == 0) {
            mCursor.close()
            return
        }

        mCursor.moveToLast()
        do {
            val path = mCursor.getString(mCursor
                    .getColumnIndex(MediaStore.Images.Media.DATA))
            val dir = mCursor.getString(mCursor.getColumnIndex(MediaStore.Images.ImageColumns.BUCKET_DISPLAY_NAME))
            val dirId = mCursor.getString(mCursor.getColumnIndex(MediaStore.Images.ImageColumns.BUCKET_ID))
            val title = mCursor.getString(mCursor.getColumnIndex(MediaStore.Images.ImageColumns.TITLE))
            val thumb = mCursor.getString(mCursor.getColumnIndex(MediaStore.Images.ImageColumns.MINI_THUMB_MAGIC))
            val imgId = mCursor.getString(mCursor.getColumnIndex(MediaStore.Images.ImageColumns._ID))
            val date = mCursor.getLong(mCursor.getColumnIndex(MediaStore.Images.ImageColumns.DATE_TAKEN))
            val img = Img(path, imgId, dir, dirId, title, thumb, AssetType.Image, date, null)

            val file = File(path)
            if (file.exists().not()) {
                continue
            }

            imgList.add(img)

            idPathMap[dirId] = dir
            pathIdMap[dir] = dirId

            pathImgMap[path] = img
        } while (mCursor.moveToPrevious())
        mCursor.close()
    }

    private fun scanVideo() {
        val mImageUri = MediaStore.Video.Media.EXTERNAL_CONTENT_URI
        val mContentResolver = registrar.activity().contentResolver

        val mCursor = MediaStore.Images.Media.query(mContentResolver, mImageUri, storeVideoKeys, null, MediaStore.Images.Media.DATE_TAKEN)
        val num = mCursor.count
        Log.i("K", "num = $num")

        if (num == 0) {
            mCursor.close()
            return
        }

        mCursor.moveToLast()
        do {
            val path = mCursor.getString(mCursor
                    .getColumnIndex(MediaStore.Video.Media.DATA))
            val dir = mCursor.getString(mCursor.getColumnIndex(MediaStore.Video.Media.BUCKET_DISPLAY_NAME))
            val dirId = mCursor.getString(mCursor.getColumnIndex(MediaStore.Video.Media.BUCKET_ID))
            val title = mCursor.getString(mCursor.getColumnIndex(MediaStore.Video.Media.TITLE))
            val thumb = mCursor.getString(mCursor.getColumnIndex(MediaStore.Video.Media.MINI_THUMB_MAGIC))
            val imgId = mCursor.getString(mCursor.getColumnIndex(MediaStore.Video.Media._ID))
            val date = mCursor.getLong(mCursor.getColumnIndex(MediaStore.Video.Media.DATE_TAKEN))
            val durationMs = mCursor.getLong(mCursor.getColumnIndex(MediaStore.Video.Media.DURATION))
            val img = Img(path, imgId, dir, dirId, title, thumb, AssetType.Video, date, durationMs)

            val file = File(path)
            if (file.exists().not()) {
                continue
            }

            imgList.add(img)

            idPathMap[dirId] = dir
            pathIdMap[dir] = dirId

            pathImgMap[path] = img
        } while (mCursor.moveToPrevious())
        mCursor.close()
    }

    fun scanAndGetImageIdList(result: MethodChannel.Result?) {
        threadPool.execute {
            scan()
            scanThumb()
            split()
            result?.success(map.keys.toList())
        }
    }

    /// dirId,ImgList
    val map = HashMap<String, ArrayList<Img>>()

    val idPathMap = HashMap<String, String>()
    val pathIdMap = HashMap<String, String>()

    private fun split() {
        map.clear()
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


    fun getAllImageList(call: MethodCall, result: MethodChannel.Result) {
        threadPool.execute {
            val list = imgList.map {
                it.path
            }.toList()
            result.success(list)
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
//            refreshThumb(r)
        }
    }

    private fun refreshThumb(imgList: List<Img>): Future<Boolean> {
        val count = imgList.count()


        if (count >= poolSize) {
            val futureList = ArrayList<Future<Boolean>>()
            val per = count / poolSize
            for (i in 0 until poolSize) {
                val start = i * per
                val end = if (i == poolSize - 1) count - 1 else (i + 1) * per
                Log.i("img_count", "max = $count , start = $start , end = $end")
                val subList = imgList.subList(start, end)
                val futureTask = FutureTask(ImageCallBack(subList, thumbHelper))
                futureList.add(futureTask)
                thumbPool.execute(futureTask)
            }

            val future = FutureTask<Boolean>(Callable {
                futureList.forEach {
                    it.get()
                }
                true
            })

            thumbPool.execute(future)

            return future
        } else {
            val future: FutureTask<Boolean> = FutureTask(Callable {
                imgList.forEachIndexed { index, img ->
                    val thumb = thumbHelper.getThumb(img.path, img.imgId)
                    Log.i("image_thumb", "make thumb = $thumb ,progress = ${index + 1} / $count")
                }
                true
            })
            handler.post {
                thumbPool.execute(future)
            }
            return future
        }
    }


    fun createThumbWithPathId(call: MethodCall, result: MethodChannel.Result) {
        val pathId = call.arguments as String
        val list = map[pathId]
        if (list == null || list.isEmpty()) {
            result.success(true)
            return
        }
        val future = refreshThumb(list)
        threadPool.execute {
            result.success(future.get())
        }
    }

    fun createThumbWithPathIdAndIndex(call: MethodCall, result: MethodChannel.Result) {
        val params = call.arguments as List<Any>
        val pathId = params[0] as String
        var startIndex = params[1] as Int
        var endIndex = params[2] as Int

        val list = map[pathId]
        if (list == null || list.isEmpty()) {
            result.success(true)
            return
        }
        if (startIndex <= 0) {
            startIndex = 0
        }

        if (endIndex >= list.count()) {
            endIndex = list.count()
        }
        val future = refreshThumb(list.subList(startIndex, endIndex))
        threadPool.execute {
            result.success(future.get())
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

    private fun getThumbFromPath(img: Img?): String? {
        if (img == null) {
            return null
        }
        return thumbMap[img.imgId]
    }

    fun getImageThumb(call: MethodCall, result: MethodChannel.Result) {
        threadPool.execute {
            val path = call.arguments as String
            val img = pathImgMap[path]
            if (img == null) {
                result.success(null)
            } else {
                val thumbFromPath = getThumbFromPath(img)
                if (thumbFromPath == null) {
                    val thumb = thumbHelper.getThumb(path, img.imgId)
                    result.success(thumb)
                } else {
                    result.success(thumbFromPath)
                }
            }
        }
    }


    fun getImageThumbData(call: MethodCall, result: MethodChannel.Result) {

        val args = call.arguments as List<Any>
        val id = args[0] as String
        val img = pathImgMap[id] ?: return
        val width = (args[1] as String).toInt()
        val height = (args[2] as String).toInt()

//        result.success(thumbHelper.getThumbData(img))
        when (img.type) {
            AssetType.Image -> ThumbnailUtil.getThumbnailByGlide(registrar.activity(), img.path, width, height, result)
            AssetType.Video -> ThumbnailUtil.getThumbnailWithVideo(registrar.activity(), img, width, height, result)
            else -> result.success(null)
        }
    }

    fun getAssetTypeWithIds(call: MethodCall, result: MethodChannel.Result) {
        val args = call.arguments as List<Any>
        val idList = args.map { it.toString() }
        val resultList = ArrayList<String>()

        idList.forEach { id ->
            val img = pathImgMap[id]
            img?.apply {
                resultList.add(typeFromEntity(this))
            }
        }
        result.success(resultList)
    }

    private fun typeFromEntity(img: Img): String {
        return when (img.type) {
            AssetType.Image -> "1"
            AssetType.Video -> "2"
            AssetType.Other -> "0"
        }
    }

    fun getAssetDurationWithId(call: MethodCall, result: MethodChannel.Result) {
        val id = call.arguments<String>()
        val img = pathImgMap[id]
        if (img == null || img.type != AssetType.Video) {
            result.success(null)
        } else {
            val duration = img.duration
            if (duration == null) {
                result.success(null)
            } else {
                result.success(duration / 1000)
            }
        }
    }
}

class ImageCallBack(val imgList: List<Img>, val thumbHelper: ThumbHelper) : Callable<Boolean> {
    override fun call(): Boolean {
        imgList.forEachIndexed { index, img ->
            val thumb = thumbHelper.getThumb(img.path, img.imgId)
            Log.i("image_thumb", "make thumb = $thumb ,progress = ${index + 1} / ${imgList.count()}")
        }
        return true
    }

}