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
            MediaStore.Images.Media.WIDTH, // 宽
            MediaStore.Images.Media.HEIGHT, // 高
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
            MediaStore.Video.Media.WIDTH, // 宽
            MediaStore.Video.Media.HEIGHT, // 高
            MediaStore.Video.Media.DURATION //时长
    )


    private var imgList = ArrayList<Asset>()
    /// dirId,AssetList
    private val map = HashMap<String, ArrayList<Asset>>()
    private val idPathMap = HashMap<String, String>()
    private val pathIdMap = HashMap<String, String>()
    private var thumbMap = HashMap<String, String>()
    private val pathAssetMap = HashMap<String, Asset>()

    /// dirId,AssetList
    internal val videoPathDirIdMap = HashMap<String, ArrayList<Asset>>()
    /// dirId,AssetList
    internal val imagePathDirIdMap = HashMap<String, ArrayList<Asset>>()

    private fun scan() {
//        Log.i("K", "start scan")
        imgList.clear()
        idPathMap.clear()
        pathIdMap.clear()
        pathAssetMap.clear()

        scanVideo()
        scanImage()
        sortAsset()
    }

    private fun onlyScanVideo() {
        imgList.clear()
        idPathMap.clear()
        pathIdMap.clear()
        pathAssetMap.clear()

        scanVideo()
        sortAsset()
    }


    private fun onlyScanImage() {
        imgList.clear()
        idPathMap.clear()
        pathIdMap.clear()
        pathAssetMap.clear()

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
            val width = mCursor.getInt(mCursor.getColumnIndex(MediaStore.Images.Media.WIDTH))
            val height = mCursor.getInt(mCursor.getColumnIndex(MediaStore.Images.Media.HEIGHT))
            val img = Asset(path, imgId, dir, dirId, title, thumb, AssetType.Image, date, null, width, height)

            val file = File(path)
            if (file.exists().not()) {
                continue
            }

            if (imgList.contains(img).not()) {
                imgList.add(img)
            }

            idPathMap[dirId] = dir
            pathIdMap[dir] = dirId

            pathAssetMap[path] = img

            createImagePath(dirId, dir)
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

            val width = mCursor.getInt(mCursor.getColumnIndex(MediaStore.Video.Media.WIDTH))
            val height = mCursor.getInt(mCursor.getColumnIndex(MediaStore.Video.Media.HEIGHT))

            val img = Asset(path, imgId, dir, dirId, title, thumb, AssetType.Video, date, durationMs, width, height)

            val file = File(path)
            if (file.exists().not()) {
                continue
            }

            if (imgList.contains(img).not()) {
                imgList.add(img)
            }

            idPathMap[dirId] = dir
            pathIdMap[dir] = dirId

            pathAssetMap[path] = img

            createVideoPath(dirId, dir)
        } while (mCursor.moveToPrevious())
        mCursor.close()
    }

    fun scanAndGetImageIdList(result: MethodChannel.Result?) {
        threadPool.execute {
            scan()
            scanThumb()
            filter()
            result?.success(map.keys.toList())
        }
    }

    private fun filter() {
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

    private fun refreshThumb(assetList: List<Asset>): Future<Boolean> {
        val count = assetList.count()


        if (count >= poolSize) {
            val futureList = ArrayList<Future<Boolean>>()
            val per = count / poolSize
            for (i in 0 until poolSize) {
                val start = i * per
                val end = if (i == poolSize - 1) count - 1 else (i + 1) * per
                Log.i("img_count", "max = $count , start = $start , end = $end")
                val subList = assetList.subList(start, end)
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
                assetList.forEachIndexed { index, img ->
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

    private fun getThumbFromPath(asset: Asset?): String? {
        if (asset == null) {
            return null
        }
        return thumbMap[asset.imgId]
    }

    fun getImageThumb(call: MethodCall, result: MethodChannel.Result) {
        threadPool.execute {
            val path = call.arguments as String
            val img = getImageWithId(path)
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
        val img = getImageWithId(id) ?: return
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
            val img = getImageWithId(id)
            img?.apply {
                resultList.add(typeFromEntity(this))
            }
        }
        result.success(resultList)
    }

    private fun typeFromEntity(asset: Asset): String {
        return when (asset.type) {
            AssetType.Image -> "1"
            AssetType.Video -> "2"
            AssetType.Other -> "0"
        }
    }

    fun getAssetDurationWithId(call: MethodCall, result: MethodChannel.Result) {
        val id = call.arguments<String>()
        val img = getImageWithId(id)
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

    private fun getImageWithId(id: String) = pathAssetMap[id]

    fun getSizeWithId(call: MethodCall, result: MethodChannel.Result) {
        val id = call.arguments<String>()
        val img = getImageWithId(id)
        if (img == null) {
            result.success(mapOf<String, Int>())
            return
        }
        val sizeMap = mapOf(
                "width" to img.width,
                "height" to img.height
        )
        result.success(sizeMap)
    }

    fun releaseMemCache(result: MethodChannel.Result) {
        imgList.clear()
        idPathMap.clear()
        pathIdMap.clear()
        pathAssetMap.clear()
        map.clear()
        thumbMap.clear()
        videoPathDirIdMap.clear()
        imagePathDirIdMap.clear()

        result.success(1)
    }

    fun getVideoPathIdList(result: MethodChannel.Result?) {
        threadPool.execute {
            videoPathDirIdMap.clear()
            scanVideo()
            scanThumb()
            filterVideoPath()
            result?.success(videoPathDirIdMap.keys.toList())
        }
    }

    private fun createVideoPath(dirId: String, dir: String) {
        if (videoPathDirIdMap.containsKey(dirId)) {
            return
        }

        videoPathDirIdMap[dirId] = ArrayList()
    }

    private fun filterVideoPath() {

        for (img in imgList) {
            if(img.type == AssetType.Video) {
                videoPathDirIdMap[img.dirId]?.add(img)
            }
        }
    }


    fun getImagePathIdList(result: MethodChannel.Result?) {
        threadPool.execute {
            imagePathDirIdMap.clear()
            scanImage()
            scanThumb()
            filterImagePath()
            result?.success(imagePathDirIdMap.keys.toList())
        }
    }

    private fun createImagePath(dirId: String, dir: String) {
        if (imagePathDirIdMap.containsKey(dirId)) {
            return
        }

        imagePathDirIdMap[dirId] = ArrayList()
    }

    private fun filterImagePath() {

        for (img in imgList) {
            if(img.type == AssetType.Image) {
                imagePathDirIdMap[img.dirId]?.add(img)
            }
        }
    }


}

fun ImageScanner.getAllVideo(result: MethodChannel.Result) {
    val list = ArrayList<String>()
    for (entry in videoPathDirIdMap) {
        for (asset in entry.value) {
            list.add(asset.path)
        }
    }
    result.success(list)
}

fun ImageScanner.getOnlyVideoWithPathId(call: MethodCall, result: MethodChannel.Result) {
    val list = ArrayList<String>()
    val id = call.arguments<String>()
    videoPathDirIdMap[id]?.forEach { asset ->
        list.add(asset.path)
    }
    result.success(list)
}

fun ImageScanner.getAllImage(result: MethodChannel.Result) {
    val list = ArrayList<String>()
    for (entry in imagePathDirIdMap) {
        for (asset in entry.value) {
            list.add(asset.path)
        }
    }
    result.success(list)
}


fun ImageScanner.getOnlyImageWithPathId(call: MethodCall, result: MethodChannel.Result) {
    val list = ArrayList<String>()
    val id = call.arguments<String>()
    imagePathDirIdMap[id]?.forEach { asset ->
        list.add(asset.path)
    }
    result.success(list)
}

class ImageCallBack(val assetList: List<Asset>, val thumbHelper: ThumbHelper) : Callable<Boolean> {
    override fun call(): Boolean {
        assetList.forEachIndexed { index, img ->
            val thumb = thumbHelper.getThumb(img.path, img.imgId)
            Log.i("image_thumb", "make thumb = $thumb ,progress = ${index + 1} / ${assetList.count()}")
        }
        return true
    }

}