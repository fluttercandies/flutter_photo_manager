package top.kikt.imagescanner.old

import android.database.Cursor
import android.os.Handler
import android.provider.MediaStore
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.PluginRegistry
import top.kikt.imagescanner.Asset
import top.kikt.imagescanner.AssetType
import top.kikt.imagescanner.old.ImageScanner.Companion.threadPool
import top.kikt.imagescanner.old.refresh.ThumbHelper
import top.kikt.imagescanner.thumb.ThumbnailUtil
import top.kikt.imagescanner.util.LogUtils
import java.io.File
import java.util.concurrent.*


@Suppress("UNCHECKED_CAST")
class ImageScanner(private val registrar: PluginRegistry.Registrar) {

    companion object {
        private const val poolSize = 8
        private val thumbPool = ThreadPoolExecutor(poolSize, 1000, 200, TimeUnit.MINUTES, ArrayBlockingQueue<Runnable>(5))

        internal val threadPool: ThreadPoolExecutor = ThreadPoolExecutor(poolSize + 3, 1000, 200, TimeUnit.MINUTES, ArrayBlockingQueue<Runnable>(poolSize + 3))

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

    private val storeBucketKeys = arrayOf(
            MediaStore.Images.Media.BUCKET_ID,
            MediaStore.Images.ImageColumns.BUCKET_DISPLAY_NAME
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

    private fun scanBuckets() {
        imgList.clear()
        idPathMap.clear()
        pathIdMap.clear()
        pathAssetMap.clear()
        val mImageUri = MediaStore.Images.Media.EXTERNAL_CONTENT_URI
        val mVideoUri = MediaStore.Video.Media.EXTERNAL_CONTENT_URI
        val mContentResolver = registrar.activity().contentResolver
        val imageCursor = mContentResolver.query(mImageUri, storeBucketKeys, "${MediaStore.Images.Media.BUCKET_ID} IS NOT NULL) GROUP BY (${MediaStore.Images.Media.BUCKET_ID}", null, null)
        val num = imageCursor!!.count
        LogUtils.info("num = $num")
        while (imageCursor.moveToNext()) {
            handleBucketCursor(imageCursor, isImage = true)
        }
        val videoCursor = mContentResolver.query(mVideoUri, storeBucketKeys, "${MediaStore.Video.Media.BUCKET_ID} IS NOT NULL) GROUP BY (${MediaStore.Video.Media.BUCKET_ID}", null, null)
        val vNum = videoCursor!!.count
        LogUtils.info("num = $vNum")
        while (videoCursor.moveToNext()) {
            handleBucketCursor(videoCursor, isVideo = true)
        }
        videoCursor.close()
    }

    private fun handleBucketCursor(mCursor: Cursor, isImage: Boolean = false, isVideo: Boolean = false) {
        val dir = mCursor.getString(mCursor.getColumnIndex(MediaStore.Images.ImageColumns.BUCKET_DISPLAY_NAME))
        val dirId = mCursor.getString(mCursor.getColumnIndex(MediaStore.Images.ImageColumns.BUCKET_ID))

        idPathMap[dirId] = dir
        pathIdMap[dir] = dirId
        map[dirId] = ArrayList()

        if (isImage)
            createImagePath(dirId, dir)
        if (isVideo)
            createVideoPath(dirId, dir)
    }

    private fun scan() {
//        LogUtils.info("start scan")
        imgList.clear()
        idPathMap.clear()
        pathIdMap.clear()
        pathAssetMap.clear()

        scanVideo()
        scanImage()
        sortAsset()
        scanThumb()
        filter()
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
        LogUtils.info("num = $num")

        if (num == 0) {
            mCursor.close()
            return
        }

        mCursor.moveToLast()
        do {
            handleImageCursor(mCursor)
        } while (mCursor.moveToPrevious())
        mCursor.close()
    }

    private fun handleImageCursor(mCursor: Cursor) {
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

        if (width <= 0 || height <= 0) {
            return
        }

        val img = Asset(path, imgId, dir, dirId, title, thumb, AssetType.Image, date, null, width, height)

        val file = File(path)
        if (file.exists().not()) {
            return
        }

        if (imgList.contains(img).not()) {
            imgList.add(img)
        }

        idPathMap[dirId] = dir
        pathIdMap[dir] = dirId

        pathAssetMap[path] = img

        createImagePath(dirId, dir)
    }

    private fun scanVideo() {
        val mImageUri = MediaStore.Video.Media.EXTERNAL_CONTENT_URI
        val mContentResolver = registrar.activity().contentResolver

        val mCursor = MediaStore.Images.Media.query(mContentResolver, mImageUri, storeVideoKeys, null, MediaStore.Images.Media.DATE_TAKEN)
        val num = mCursor.count
        LogUtils.info("num = $num")

        if (num == 0) {
            mCursor.close()
            return
        }

        mCursor.moveToLast()
        do {
            handleVideoCursor(mCursor)
        } while (mCursor.moveToPrevious())
        mCursor.close()
    }

    private fun handleVideoCursor(mCursor: Cursor) {
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

        if (width <= 0 || height <= 0) {
            return
        }

        val file = File(path)
        if (file.exists().not()) {
            return
        }

        if (imgList.contains(img).not()) {
            imgList.add(img)
        }

        idPathMap[dirId] = dir
        pathIdMap[dir] = dirId

        pathAssetMap[path] = img

        createVideoPath(dirId, dir)
    }

    fun scanAndGetImageIdList(call: MethodCall, result: MethodChannel.Result?) {
        val resultHandler = ResultHandler(result)
        threadPool.execute {
            if (call.arguments()) {
                resultHandler.reply(map.keys.toList())
                return@execute
            }
            scanBuckets()
            resultHandler.reply(map.keys.toList())
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
        val resultHandler = ResultHandler(result)
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
            resultHandler.reply(r)
        }
    }

    fun getImageListWithPathId(call: MethodCall, result: MethodChannel.Result) {
        val resultHandler = ResultHandler(result)
        threadPool.execute {
            if (imgList.isEmpty()) scan()
            val pathId = call.arguments as String
            val list = map[pathId]
            val r = list?.map { img ->
                img.path
            }
            resultHandler.reply(r)
        }
    }

    fun getImageListPaged(call: MethodCall, result: MethodChannel.Result) {
        val resultHandler = ResultHandler(result)
        threadPool.execute {
            pathAssetMap.clear()
            val args = call.arguments as Map<String, Any>
            val page = args["page"] as Int
            val pageSize = args["pageSize"] as Int
            val pathId = args["id"] as String?
            val hasVideo = args["hasVideo"] as Boolean

            val uri = MediaStore.Files.getContentUri("external")
            val columns = (arrayOf(MediaStore.Files.FileColumns.MEDIA_TYPE) + storeVideoKeys + storeImageKeys).distinct().toTypedArray()
            val pathIdSelection = if (pathId == null) null else " ${MediaStore.Images.ImageColumns.BUCKET_ID} = $pathId"
            val mediaTypeSelection = (MediaStore.Files.FileColumns.MEDIA_TYPE +
                    " in (" +
                    MediaStore.Files.FileColumns.MEDIA_TYPE_IMAGE +
                    (if (hasVideo) ", ${MediaStore.Files.FileColumns.MEDIA_TYPE_VIDEO}" else "") +
                    ")"
                    )
            val zeroSizeSelection = "${MediaStore.MediaColumns.WIDTH} > 0 AND ${MediaStore.MediaColumns.HEIGHT} > 0"
            val selection = (if (pathIdSelection != null) "$pathIdSelection AND " else "") +
                    "$mediaTypeSelection AND $zeroSizeSelection"

            val sortOrder = "${MediaStore.Images.Media.DATE_TAKEN} DESC LIMIT $pageSize OFFSET ${page * pageSize}"

            val cursor = registrar.activity().contentResolver.query(uri, columns, selection, null, sortOrder)
            val list = mutableListOf<String>()
            if (cursor != null) {
                while (list.size < pageSize && cursor.moveToNext()) {
                    val mediaType = cursor.getInt(cursor.getColumnIndex(MediaStore.Files.FileColumns.MEDIA_TYPE))
                    val path = cursor.getString(cursor.getColumnIndex(MediaStore.Images.Media.DATA))
                    val dir = cursor.getString(cursor.getColumnIndex(MediaStore.Images.ImageColumns.BUCKET_DISPLAY_NAME))
                    val dirId = cursor.getString(cursor.getColumnIndex(MediaStore.Images.ImageColumns.BUCKET_ID))
                    val title = cursor.getString(cursor.getColumnIndex(MediaStore.Images.ImageColumns.TITLE))
                    val thumb = cursor.getString(cursor.getColumnIndex(MediaStore.Images.ImageColumns.MINI_THUMB_MAGIC))
                    val imgId = cursor.getString(cursor.getColumnIndex(MediaStore.Images.ImageColumns._ID))
                    val date = cursor.getLong(cursor.getColumnIndex(MediaStore.Images.ImageColumns.DATE_TAKEN))
                    val width = cursor.getInt(cursor.getColumnIndex(MediaStore.Images.Media.WIDTH))
                    val height = cursor.getInt(cursor.getColumnIndex(MediaStore.Images.Media.HEIGHT))
                    val durationMs = if (mediaType == MediaStore.Files.FileColumns.MEDIA_TYPE_VIDEO) {
                        cursor.getLong(cursor.getColumnIndex(MediaStore.Video.Media.DURATION))
                    } else {
                        null
                    }
                    val type = if (mediaType == MediaStore.Files.FileColumns.MEDIA_TYPE_VIDEO) {
                        AssetType.Video
                    } else {
                        AssetType.Image
                    }
                    val img = Asset(path, imgId, dir, dirId, title, thumb, type, date, durationMs, width, height)
                    pathAssetMap[path] = img
                    list.add(path)
                }
            }
            cursor?.close()
            resultHandler.reply(list)
        }
    }


    fun getAllImageList(call: MethodCall, result: MethodChannel.Result) {
        val resultHandler = ResultHandler(result)
        threadPool.execute {
            if (imgList.isEmpty()) scan();
            val list = imgList.map {
                it.path
            }.toList()
            resultHandler.reply(list)
        }
    }


    fun getImageThumbListWithPathId(call: MethodCall, result: MethodChannel.Result) {
        val resultHandler = ResultHandler(result)
        threadPool.execute {
            val pathId = call.arguments as String
            val list = map[pathId]
            val r = list?.map { img ->
                img.thumb
            }
            resultHandler.reply(r)
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
                LogUtils.info("max = $count , start = $start , end = $end")
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
                    LogUtils.info("make thumb = $thumb ,progress = ${index + 1} / $count")
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
        val resultHandler = ResultHandler(result)
        val pathId = call.arguments as String
        val list = map[pathId]
        if (list == null || list.isEmpty()) {
            resultHandler.reply(true)
            return
        }
        val future = refreshThumb(list)
        threadPool.execute {
            resultHandler.reply(future.get())
        }
    }

    fun createThumbWithPathIdAndIndex(call: MethodCall, result: MethodChannel.Result) {
        val params = call.arguments as List<Any>
        val pathId = params[0] as String
        var startIndex = params[1] as Int
        var endIndex = params[2] as Int

        val list = map[pathId]

        val resultHandler = ResultHandler(result)

        if (list == null || list.isEmpty()) {
            resultHandler.reply(true)
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
            resultHandler.reply(future.get())
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
        val resultHandler = ResultHandler(result)
        threadPool.execute {
            val path = call.arguments as String
            val img = getImageWithId(path)
            if (img == null) {
                resultHandler.reply(null)
            } else {
                val thumbFromPath = getThumbFromPath(img)
                if (thumbFromPath == null) {
                    val thumb = thumbHelper.getThumb(path, img.imgId)
                    resultHandler.reply(thumb)
                } else {
                    resultHandler.reply(thumbFromPath)
                }
            }
        }
    }


    fun getImageThumbData(call: MethodCall, result: MethodChannel.Result) {
        val resultHandler = ResultHandler(result)
        threadPool.execute {

            val args = call.arguments as List<Any>
            val id = args[0] as String
            val imageWithId = getImageWithId(id)
            val img = if (imageWithId != null) {
                imageWithId
            } else {
                resultHandler.reply(null)
                return@execute
            }
            val width = (args[1] as String).toInt()
            val height = (args[2] as String).toInt()

//        resultHandler.reply(thumbHelper.getThumbData(img))
            when (img.type) {
                AssetType.Image -> ThumbnailUtil.getThumbnailByGlide(registrar.activity(), img.path, width, height, result)
                AssetType.Video -> ThumbnailUtil.getThumbnailWithVideo(registrar.activity(), img, width, height, result)
                else -> resultHandler.reply(null)
            }
        }
    }

    fun getAssetTypeWithIds(call: MethodCall, result: MethodChannel.Result) {
        val resultHandler = ResultHandler(result)
        threadPool.execute {

            val args = call.arguments as List<Any>
            val idList = args.map { it.toString() }
            val resultList = ArrayList<String>()

            idList.forEach { id ->
                val img = getImageWithId(id)
                img?.apply {
                    resultList.add(typeFromEntity(this))
                }
            }
            resultHandler.reply(resultList)
        }
    }

    private fun typeFromEntity(asset: Asset): String {
        return when (asset.type) {
            AssetType.Image -> "1"
            AssetType.Video -> "2"
            AssetType.Other -> "0"
        }
    }

    fun getAssetDurationWithId(call: MethodCall, result: MethodChannel.Result) {
        val resultHandler = ResultHandler(result)
        threadPool.execute {
            val id = call.arguments<String>()
            val img = getImageWithId(id)
            if (img == null || img.type != AssetType.Video) {
                resultHandler.reply(null)
            } else {
                val duration = img.duration
                if (duration == null) {
                    resultHandler.reply(null)
                } else {
                    resultHandler.reply(duration / 1000)
                }
            }
        }
    }

    /**
     * [id] id image path
     *
     * id system data is [MediaStore.Images.ImageColumns.DATA] or [MediaStore.Video.VideoColumns.DATA]
     */
    fun getImageWithId(id: String): Asset? {
        var img = pathAssetMap[id]
        if (img == null) {
            val cursor = registrar.activity().contentResolver.query(
                    MediaStore.Files.getContentUri("external"),
                    (storeImageKeys + storeVideoKeys + arrayOf(MediaStore.Files.FileColumns.MEDIA_TYPE)).distinct().toTypedArray(),
                    "${MediaStore.Images.ImageColumns.DATA} = ? AND " +
                            "${MediaStore.Files.FileColumns.MEDIA_TYPE} in (${MediaStore.Files.FileColumns.MEDIA_TYPE_IMAGE}, ${MediaStore.Files.FileColumns.MEDIA_TYPE_VIDEO})",
                    arrayOf(id),
                    MediaStore.Images.ImageColumns.DATE_TAKEN
            )
            if (cursor != null && cursor.moveToFirst()) {
                val mediaType = cursor.getInt(cursor.getColumnIndex(MediaStore.Files.FileColumns.MEDIA_TYPE))
                val path = cursor.getString(cursor.getColumnIndex(MediaStore.Images.Media.DATA))
                val dir = cursor.getString(cursor.getColumnIndex(MediaStore.Images.ImageColumns.BUCKET_DISPLAY_NAME))
                val dirId = cursor.getString(cursor.getColumnIndex(MediaStore.Images.ImageColumns.BUCKET_ID))
                val title = cursor.getString(cursor.getColumnIndex(MediaStore.Images.ImageColumns.TITLE))
                val thumb = cursor.getString(cursor.getColumnIndex(MediaStore.Images.ImageColumns.MINI_THUMB_MAGIC))
                val imgId = cursor.getString(cursor.getColumnIndex(MediaStore.Images.ImageColumns._ID))
                val date = cursor.getLong(cursor.getColumnIndex(MediaStore.Images.ImageColumns.DATE_TAKEN))
                val width = cursor.getInt(cursor.getColumnIndex(MediaStore.Images.Media.WIDTH))
                val height = cursor.getInt(cursor.getColumnIndex(MediaStore.Images.Media.HEIGHT))
                val durationMs = if (mediaType == MediaStore.Files.FileColumns.MEDIA_TYPE_VIDEO) {
                    cursor.getLong(cursor.getColumnIndex(MediaStore.Video.Media.DURATION))
                } else {
                    null
                }
                val type = if (mediaType == MediaStore.Files.FileColumns.MEDIA_TYPE_VIDEO) AssetType.Video else AssetType.Image
                img = Asset(path, imgId, dir, dirId, title, thumb, type, date, durationMs, width, height)
            }
            cursor?.close()
        }
        return img
    }

    fun getSizeWithId(call: MethodCall, result: MethodChannel.Result) {
        val resultHandler = ResultHandler(result)
        threadPool.execute {
            val id = call.arguments<String>()
            val img = getImageWithId(id)
            if (img == null) {
                resultHandler.reply(mapOf<String, Int>())
                return@execute
            }
            val sizeMap = mapOf(
                    "width" to img.width,
                    "height" to img.height
            )
            resultHandler.reply(sizeMap)
        }
    }

    fun releaseMemCache(result: MethodChannel.Result) {
        val resultHandler = ResultHandler(result)

        imgList.clear()
        idPathMap.clear()
        pathIdMap.clear()
        pathAssetMap.clear()
        map.clear()
        thumbMap.clear()
        videoPathDirIdMap.clear()
        imagePathDirIdMap.clear()

        resultHandler.reply(1)
    }

    fun getVideoPathIdList(call: MethodCall, result: MethodChannel.Result?) {
        val resultHandler = ResultHandler(result)
        threadPool.execute {
            if (call.arguments()) {
                resultHandler.reply(videoPathDirIdMap.keys.toList())
                return@execute
            }
            videoPathDirIdMap.clear()
            scanVideo()
            scanThumb()
            filterVideoPath()
            resultHandler.reply(videoPathDirIdMap.keys.toList())
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
            if (img.type == AssetType.Video) {
                videoPathDirIdMap[img.dirId]?.add(img)
            }
        }
    }


    fun getImagePathIdList(call: MethodCall, result: MethodChannel.Result?) {
        val resultHandler = ResultHandler(result)
        threadPool.execute {
            if (call.arguments()) {
                resultHandler.reply(imagePathDirIdMap.keys.toList())
                return@execute
            }
            imagePathDirIdMap.clear()
            scanImage()
            scanThumb()
            filterImagePath()
            resultHandler.reply(imagePathDirIdMap.keys.toList())
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
            if (img?.type == AssetType.Image) {
                imagePathDirIdMap[img.dirId]?.add(img)
            }
        }
    }

    fun createAssetWithId(call: MethodCall, result: MethodChannel.Result?) {
        val id = call.arguments as String
        val resultHandler = ResultHandler(result)
        threadPool.execute {
            val asset = createAsset(id)
            resultHandler.reply(asset?.imgId)
        }
    }

    private fun createAsset(path: String): Asset? {
        run {
            val mImageUri = MediaStore.Images.Media.EXTERNAL_CONTENT_URI
            val mContentResolver = registrar.activity().contentResolver

            val where = "${MediaStore.Images.Media.DATA} = ?"

            val mCursor = MediaStore.Images.Media.query(mContentResolver, mImageUri, storeImageKeys, where, arrayOf(path), MediaStore.Images.Media.DATE_TAKEN)
            if (mCursor.count > 0) {
                mCursor.moveToPosition(0)
                handleImageCursor(mCursor)
            }
        }

        run {
            val mImageUri = MediaStore.Video.Media.EXTERNAL_CONTENT_URI
            val mContentResolver = registrar.activity().contentResolver

            val where = "${MediaStore.Video.Media.DATA} = ?"

            val mCursor = MediaStore.Images.Media.query(mContentResolver, mImageUri, storeVideoKeys, where, arrayOf(path), MediaStore.Images.Media.DATE_TAKEN)
            if (mCursor.count > 0) {
                mCursor.moveToPosition(0)
                handleVideoCursor(mCursor)
            }
        }

        return getImageWithId(path)
    }

    fun checkAssetExists(call: MethodCall, result: MethodChannel.Result) {
        val resultHandler = ResultHandler(result)

        val id = call.arguments<String>()
        val exists = File(id).exists()
        resultHandler.reply(exists)
    }

}

fun ImageScanner.getAllVideo(result: MethodChannel.Result) {
    val resultHandler = ResultHandler(result)

    val list = ArrayList<String>()
    for (entry in videoPathDirIdMap) {
        for (asset in entry.value) {
            list.add(asset.path)
        }
    }
    resultHandler.reply(list)
}

fun ImageScanner.getOnlyVideoWithPathId(call: MethodCall, result: MethodChannel.Result) {
    val resultHandler = ResultHandler(result)

    val list = ArrayList<String>()
    val id = call.arguments<String>()
    videoPathDirIdMap[id]?.forEach { asset ->
        list.add(asset.path)
    }
    resultHandler.reply(list)
}

fun ImageScanner.getAllImage(result: MethodChannel.Result) {
    val resultHandler = ResultHandler(result)

    val list = ArrayList<String>()
    for (entry in imagePathDirIdMap) {
        for (asset in entry.value) {
            list.add(asset.path)
        }
    }
    resultHandler.reply(list)
}


fun ImageScanner.getOnlyImageWithPathId(call: MethodCall, result: MethodChannel.Result) {
    val resultHandler = ResultHandler(result)

    val list = ArrayList<String>()
    val id = call.arguments<String>()
    imagePathDirIdMap[id]?.forEach { asset ->
        list.add(asset.path)
    }
    resultHandler.reply(list)
}

fun ImageScanner.getTimeStampWithIds(call: MethodCall, result: MethodChannel.Result) {
    val resultHandler = ResultHandler(result)

    threadPool.execute {
        val ids: List<String> = call.arguments()
        val timeList = ArrayList<Long>()
        for (id in ids) {
            val asset = getImageWithId(id)
            timeList.add(asset?.timeStamp ?: 0)
        }

        resultHandler.reply(timeList)
    }
}

class ImageCallBack(val assetList: List<Asset>, val thumbHelper: ThumbHelper) : Callable<Boolean> {
    override fun call(): Boolean {
        assetList.forEachIndexed { index, img ->
            val thumb = thumbHelper.getThumb(img.path, img.imgId)
            LogUtils.info("make thumb = $thumb ,progress = ${index + 1} / ${assetList.count()}")
        }
        return true
    }

}