package com.fluttercandies.photo_manager.core.utils

import android.content.ContentUris
import android.content.ContentValues
import android.content.Context
import android.graphics.BitmapFactory
import android.media.MediaMetadataRetriever
import android.net.Uri
import android.os.Environment
import android.provider.BaseColumns._ID
import android.provider.MediaStore
import android.text.TextUtils
import android.util.Log
import android.webkit.MimeTypeMap
import androidx.exifinterface.media.ExifInterface
import com.fluttercandies.photo_manager.core.PhotoManager
import com.fluttercandies.photo_manager.core.entity.AssetEntity
import com.fluttercandies.photo_manager.core.entity.AssetPathEntity
import com.fluttercandies.photo_manager.core.entity.FilterOption
import java.io.*
import java.net.URLConnection
import java.util.concurrent.locks.ReentrantLock
import kotlin.concurrent.withLock


/// Call the MediaStore API and get entity for the data.
@Suppress("Deprecation", "InlinedApi")
object DBUtils : IDBUtils {
    private val locationKeys = arrayOf(
        MediaStore.Images.ImageColumns.LONGITUDE,
        MediaStore.Images.ImageColumns.LATITUDE
    )

    override fun getAssetPathList(
        context: Context,
        requestType: Int,
        option: FilterOption
    ): List<AssetPathEntity> {
        val list = ArrayList<AssetPathEntity>()
        val args = ArrayList<String>()
        val typeSelection: String = getCondFromType(requestType, option, args)
        val dateSelection = getDateCond(args, option)
        val sizeWhere = sizeWhere(requestType, option)
        val selection =
            "${MediaStore.MediaColumns.BUCKET_ID} IS NOT NULL $typeSelection $dateSelection $sizeWhere) GROUP BY (${MediaStore.MediaColumns.BUCKET_ID}"
        val cursor = context.contentResolver.query(
            allUri,
            IDBUtils.storeBucketKeys + arrayOf("count(1)"),
            selection,
            args.toTypedArray(),
            null
        ) ?: return list
        cursor.use {
            while (it.moveToNext()) {
                val id = it.getString(0)
                val name = it.getString(1) ?: ""
                val assetCount = it.getInt(2)
                val entity = AssetPathEntity(id, name, assetCount, 0)
                if (option.containsPathModified) {
                    injectModifiedDate(context, entity)
                }
                list.add(entity)
            }
        }
        return list
    }

    override fun getMainAssetPathEntity(
        context: Context,
        requestType: Int,
        option: FilterOption
    ): List<AssetPathEntity> {
        val list = ArrayList<AssetPathEntity>()
        val args = ArrayList<String>()
        val typeSelection: String = getCondFromType(requestType, option, args)
        val projection = IDBUtils.storeBucketKeys + arrayOf("count(1)")
        val dateSelection = getDateCond(args, option)
        val sizeWhere = sizeWhere(requestType, option)
        val selections =
            "${MediaStore.MediaColumns.BUCKET_ID} IS NOT NULL $typeSelection $dateSelection $sizeWhere"

        val cursor = context.contentResolver.query(
            allUri,
            projection,
            selections,
            args.toTypedArray(),
            null
        ) ?: return list
        cursor.use {
            if (it.moveToNext()) {
                val countIndex = projection.indexOf("count(1)")
                val assetCount = it.getInt(countIndex)
                val assetPathEntity = AssetPathEntity(
                    PhotoManager.ALL_ID,
                    PhotoManager.ALL_ALBUM_NAME,
                    assetCount,
                    requestType,
                    true
                )
                list.add(assetPathEntity)
            }
        }
        return list
    }

    override fun getAssetPathEntityFromId(
        context: Context,
        pathId: String,
        type: Int,
        option: FilterOption
    ): AssetPathEntity? {
        val args = ArrayList<String>()
        val typeSelection: String = getCondFromType(type, option, args)
        val dateSelection = getDateCond(args, option)
        val idSelection: String
        if (pathId == "") {
            idSelection = ""
        } else {
            idSelection = "AND ${MediaStore.MediaColumns.BUCKET_ID} = ?"
            args.add(pathId)
        }
        val sizeWhere = sizeWhere(null, option)
        val selection =
            "${MediaStore.MediaColumns.BUCKET_ID} IS NOT NULL $typeSelection $dateSelection $idSelection $sizeWhere) GROUP BY (${MediaStore.MediaColumns.BUCKET_ID}"
        val cursor = context.contentResolver.query(
            allUri,
            IDBUtils.storeBucketKeys + arrayOf("count(1)"),
            selection,
            args.toTypedArray(),
            null
        ) ?: return null
        cursor.use {
            return if (it.moveToNext()) {
                val id = it.getString(0)
                val name = it.getString(1) ?: ""
                val assetCount = it.getInt(2)
                AssetPathEntity(id, name, assetCount, 0)
            } else {
                null
            }
        }
    }

    override fun getAssetListPaged(
        context: Context,
        pathId: String,
        page: Int,
        size: Int,
        requestType: Int,
        option: FilterOption
    ): List<AssetEntity> {
        val isAll = pathId.isEmpty()
        val list = ArrayList<AssetEntity>()
        val args = ArrayList<String>()
        if (!isAll) {
            args.add(pathId)
        }
        val typeSelection = getCondFromType(requestType, option, args)
        val dateSelection = getDateCond(args, option)
        val sizeWhere = sizeWhere(requestType, option)
        val keys =
            (IDBUtils.storeImageKeys + IDBUtils.storeVideoKeys + IDBUtils.typeKeys + locationKeys).distinct().toTypedArray()
        val selection = if (isAll) {
            "${MediaStore.MediaColumns.BUCKET_ID} IS NOT NULL $typeSelection $dateSelection $sizeWhere"
        } else {
            "${MediaStore.MediaColumns.BUCKET_ID} = ? $typeSelection $dateSelection $sizeWhere"
        }
        val sortOrder = getSortOrder(page * size, size, option)
        val cursor = context.contentResolver.query(
            allUri,
            keys,
            selection,
            args.toTypedArray(),
            sortOrder
        ) ?: return list
        cursor.use {
            while (it.moveToNext()) {
                it.toAssetEntity(context)?.apply {
                    list.add(this)
                }
            }
        }
        return list
    }

    override fun getAssetListRange(
        context: Context,
        galleryId: String,
        start: Int,
        end: Int,
        requestType: Int,
        option: FilterOption
    ): List<AssetEntity> {
        val isAll = galleryId.isEmpty()
        val list = ArrayList<AssetEntity>()
        val args = ArrayList<String>()
        if (!isAll) {
            args.add(galleryId)
        }
        val typeSelection = getCondFromType(requestType, option, args)
        val dateSelection = getDateCond(args, option)
        val sizeWhere = sizeWhere(requestType, option)
        val keys =
            (IDBUtils.storeImageKeys + IDBUtils.storeVideoKeys + IDBUtils.typeKeys + locationKeys).distinct().toTypedArray()
        val selection = if (isAll) {
            "${MediaStore.MediaColumns.BUCKET_ID} IS NOT NULL $typeSelection $dateSelection $sizeWhere"
        } else {
            "${MediaStore.MediaColumns.BUCKET_ID} = ? $typeSelection $dateSelection $sizeWhere"
        }
        val pageSize = end - start
        val sortOrder = getSortOrder(start, pageSize, option)
        val cursor = context.contentResolver.query(
            allUri,
            keys,
            selection,
            args.toTypedArray(),
            sortOrder
        ) ?: return list
        cursor.use {
            while (it.moveToNext()) {
                it.toAssetEntity(context)?.apply {
                    list.add(this)
                }
            }
        }
        return list
    }

    override fun getAssetEntity(context: Context, id: String, checkIfExists: Boolean): AssetEntity? {
        val keys =
            (IDBUtils.storeImageKeys + IDBUtils.storeVideoKeys + locationKeys + IDBUtils.typeKeys).distinct().toTypedArray()
        val selection = "${MediaStore.MediaColumns._ID} = ?"
        val args = arrayOf(id)

        val cursor = context.contentResolver.query(
            allUri,
            keys,
            selection,
            args,
            null
        ) ?: return null
        cursor.use {
            return if (it.moveToNext()) {
                it.toAssetEntity(context, checkIfExists)
            } else {
                null
            }
        }
    }

    override fun getOriginBytes(
        context: Context,
        asset: AssetEntity,
        needLocationPermission: Boolean
    ): ByteArray {
        return File(asset.path).readBytes()
    }

    override fun getExif(context: Context, id: String): ExifInterface? {
        val asset = getAssetEntity(context, id) ?: return null
        val file = File(asset.path)
        return if (file.exists()) ExifInterface(asset.path) else null
    }

    override fun getFilePath(context: Context, id: String, origin: Boolean): String? {
        val assetEntity = getAssetEntity(context, id) ?: return null
        return assetEntity.path
    }

    override fun saveImage(
        context: Context,
        image: ByteArray,
        title: String,
        desc: String,
        relativePath: String?
    ): AssetEntity? {
        val cr = context.contentResolver
        var inputStream = ByteArrayInputStream(image)
        fun refreshInputStream() {
            inputStream = ByteArrayInputStream(image)
        }

        val latLong = kotlin.run {
            val exifInterface = try {
                ExifInterface(inputStream)
            } catch (e: Exception) {
                return@run doubleArrayOf(0.0, 0.0)
            }
            exifInterface.latLong ?: doubleArrayOf(0.0, 0.0)
        }
        refreshInputStream()

        val bmp = BitmapFactory.decodeStream(inputStream)
        val width = bmp.width
        val height = bmp.height
        val timestamp = System.currentTimeMillis() / 1000
        refreshInputStream()

        val typeFromStream: String = if (title.contains(".")) {
            // title contains file extension, form mimeType from it
            "image/${File(title).extension}"
        } else {
            URLConnection.guessContentTypeFromStream(inputStream) ?: "image/*"
        }

        val values = ContentValues().apply {
            put(
                MediaStore.Files.FileColumns.MEDIA_TYPE,
                MediaStore.Files.FileColumns.MEDIA_TYPE_IMAGE
            )
            put(MediaStore.MediaColumns.DISPLAY_NAME, title)
            put(MediaStore.MediaColumns.MIME_TYPE, typeFromStream)
            put(MediaStore.MediaColumns.TITLE, title)
            put(MediaStore.Images.ImageColumns.DESCRIPTION, desc)
            put(MediaStore.MediaColumns.DATE_ADDED, timestamp)
            put(MediaStore.MediaColumns.DATE_MODIFIED, timestamp)
            put(MediaStore.MediaColumns.DISPLAY_NAME, title)
            put(MediaStore.MediaColumns.WIDTH, width)
            put(MediaStore.MediaColumns.HEIGHT, height)
            put(MediaStore.Images.ImageColumns.LATITUDE, latLong[0])
            put(MediaStore.Images.ImageColumns.LONGITUDE, latLong[1])
        }

        val insertUri = cr.insert(
            MediaStore.Images.Media.EXTERNAL_CONTENT_URI,
            values
        ) ?: return null

        // Write bytes.
        val cursor = cr.query(
            insertUri,
            arrayOf(MediaStore.MediaColumns.DATA),
            null,
            null,
            null
        ) ?: return null
        cursor.use {
            if (it.moveToNext()) {
                val targetPath = it.getString(0)
                targetPath.checkDirs()
                val outputStream = FileOutputStream(targetPath)
                refreshInputStream()
                outputStream.use { os -> inputStream.use { iStream -> iStream.copyTo(os) } }
            }
        }
        val id = ContentUris.parseId(insertUri)
        return getAssetEntity(context, id.toString())
    }

    override fun saveImage(
        context: Context,
        path: String,
        title: String,
        desc: String,
        relativePath: String?
    ): AssetEntity? {
        val cr = context.contentResolver
        val file = File(path)
        var inputStream = FileInputStream(file)
        fun refreshInputStream() {
            inputStream = FileInputStream(file)
        }

        val latLong = kotlin.run {
            val exifInterface = try {
                ExifInterface(inputStream)
            } catch (e: Exception) {
                return@run doubleArrayOf(0.0, 0.0)
            }
            exifInterface.latLong ?: doubleArrayOf(0.0, 0.0)
        }
        refreshInputStream()

        val (width, height) = try {
            val bmp = BitmapFactory.decodeFile(path)
            Pair(bmp.width, bmp.height)
        } catch (e: Exception) {
            Pair(0, 0)
        }
        val timestamp = System.currentTimeMillis() / 1000

        val typeFromStream = URLConnection.guessContentTypeFromStream(inputStream)
            ?: "image/${File(path).extension}"
        refreshInputStream()

        val uri = MediaStore.Images.Media.EXTERNAL_CONTENT_URI
        val dir = Environment.getExternalStorageDirectory()
        val savePath = file.absolutePath.startsWith(dir.path)
        val values = ContentValues().apply {
            put(
                MediaStore.Files.FileColumns.MEDIA_TYPE,
                MediaStore.Files.FileColumns.MEDIA_TYPE_IMAGE
            )
            put(MediaStore.MediaColumns.DISPLAY_NAME, title)
            put(MediaStore.MediaColumns.MIME_TYPE, typeFromStream)
            put(MediaStore.MediaColumns.TITLE, title)
            put(MediaStore.Images.ImageColumns.DESCRIPTION, desc)
            put(MediaStore.MediaColumns.DATE_ADDED, timestamp)
            put(MediaStore.MediaColumns.DATE_MODIFIED, timestamp)
            put(MediaStore.MediaColumns.DISPLAY_NAME, title)
            put(MediaStore.Images.ImageColumns.LATITUDE, latLong[0])
            put(MediaStore.Images.ImageColumns.LONGITUDE, latLong[1])
            put(MediaStore.MediaColumns.WIDTH, width)
            put(MediaStore.MediaColumns.HEIGHT, height)
            if (savePath) {
                put(MediaStore.MediaColumns.DATA, path)
            }
        }

        val contentUri = cr.insert(uri, values) ?: return null
        val id = ContentUris.parseId(contentUri)
        // Ignore the existence of the file, it'll be exported later.
        val assetEntity = getAssetEntity(context, id.toString(), checkIfExists = false)
        if (!savePath) {
            val tmpPath = assetEntity?.path!!
            tmpPath.checkDirs()
            val tmpFile = File(tmpPath)
            val targetPath = "${tmpFile.parent}/$title"
            val targetFile = File(targetPath)
            if (targetFile.exists()) {
                throw IOException("save target path is ")
            }
            tmpFile.renameTo(targetFile)
            val updateDataValues = ContentValues().apply {
                put(MediaStore.MediaColumns.DATA, targetPath)
            }
            cr.update(contentUri, updateDataValues, null, null)
            val outputStream = FileOutputStream(targetFile)
            outputStream.use { os -> inputStream.use { it.copyTo(os) } }
            assetEntity.path = targetPath
        }
        cr.notifyChange(contentUri, null)
        return assetEntity
    }

    override fun copyToGallery(context: Context, assetId: String, galleryId: String): AssetEntity? {
        val (currentGalleryId, _) = getSomeInfo(context, assetId)
            ?: throw RuntimeException("Cannot get gallery id of $assetId")
        if (galleryId == currentGalleryId) {
            throw RuntimeException("No copy required, because the target gallery is the same as the current one.")
        }
        val cr = context.contentResolver
        val asset = getAssetEntity(context, assetId)
            ?: throw RuntimeException("No copy required, because the target gallery is the same as the current one.")

        val copyKeys = arrayListOf(
            MediaStore.MediaColumns.DISPLAY_NAME,
            MediaStore.MediaColumns.TITLE,
            MediaStore.MediaColumns.DATE_ADDED,
            MediaStore.MediaColumns.DATE_MODIFIED,
            MediaStore.MediaColumns.DURATION,
            MediaStore.Video.VideoColumns.LONGITUDE,
            MediaStore.Video.VideoColumns.LATITUDE,
            MediaStore.MediaColumns.WIDTH,
            MediaStore.MediaColumns.HEIGHT
        )
        val mediaType = convertTypeToMediaType(asset.type)
        if (mediaType != MediaStore.Files.FileColumns.MEDIA_TYPE_AUDIO) {
            copyKeys.add(MediaStore.Video.VideoColumns.DESCRIPTION)
        }

        val cursor = cr.query(
            allUri,
            copyKeys.toTypedArray() + arrayOf(MediaStore.MediaColumns.DATA),
            idSelection,
            arrayOf(assetId),
            null
        ) ?: throw RuntimeException("Cannot find asset .")
        if (!cursor.moveToNext()) {
            throw RuntimeException("Cannot find asset .")
        }
        val insertUri = MediaStoreUtils.getInsertUri(mediaType)
        val galleryInfo = getGalleryInfo(context, galleryId) ?: throwMsg("Cannot find gallery info")
        val outputPath = "${galleryInfo.path}/${asset.displayName}"
        val cv = ContentValues().apply {
            for (key in copyKeys) {
                put(key, cursor.getString(key))
            }
            put(MediaStore.Files.FileColumns.MEDIA_TYPE, mediaType)
            put(MediaStore.MediaColumns.DATA, outputPath)
        }

        val insertedUri =
            cr.insert(insertUri, cv) ?: throw RuntimeException("Cannot insert new asset.")
        val outputStream = cr.openOutputStream(insertedUri)
            ?: throw RuntimeException("Cannot open output stream for $insertedUri.")
        val inputStream = File(asset.path).inputStream()
        inputStream.use {
            outputStream.use {
                inputStream.copyTo(outputStream)
            }
        }

        cursor.close()
        val insertedId = insertedUri.lastPathSegment
            ?: throw RuntimeException("Cannot open output stream for $insertedUri.")
        return getAssetEntity(context, insertedId)
    }

    override fun moveToGallery(context: Context, assetId: String, galleryId: String): AssetEntity? {
        val (currentGalleryId, _) = getSomeInfo(context, assetId)
            ?: throwMsg("Cannot get gallery id of $assetId")

        val targetGalleryInfo = getGalleryInfo(context, galleryId)
            ?: throwMsg("Cannot get target gallery info")

        if (galleryId == currentGalleryId) {
            throwMsg("No move required, because the target gallery is the same as the current one.")
        }

        val cr = context.contentResolver
        val cursor = cr.query(
            allUri,
            arrayOf(MediaStore.MediaColumns.DATA),
            idSelection,
            arrayOf(assetId),
            null
        ) ?: throwMsg("Cannot find $assetId path")

        val targetPath = if (cursor.moveToNext()) {
            val srcPath = cursor.getString(0)
            cursor.close()
            val target = "${targetGalleryInfo.path}/${File(srcPath).name}"
            File(srcPath).renameTo(File(target))
            target
        } else {
            throwMsg("Cannot find $assetId path")
        }

        val contentValues = ContentValues().apply {
            put(MediaStore.MediaColumns.DATA, targetPath)
            put(MediaStore.MediaColumns.BUCKET_ID, galleryId)
            put(MediaStore.MediaColumns.BUCKET_DISPLAY_NAME, targetGalleryInfo.galleryName)
        }

        val count = cr.update(allUri, contentValues, idSelection, arrayOf(assetId))
        if (count > 0) {
            return getAssetEntity(context, assetId)
        }
        throwMsg("Cannot update $assetId relativePath")
    }

    private val deleteLock = ReentrantLock()

    override fun removeAllExistsAssets(context: Context): Boolean {
        if (deleteLock.isLocked) {
            return false
        }
        deleteLock.withLock {
            val removedList = ArrayList<String>()
            val cr = context.contentResolver
            val cursor = cr.query(
                allUri,
                arrayOf(_ID, MediaStore.MediaColumns.DATA),
                null,
                null,
                null
            ) ?: return false
            cursor.use {
                while (it.moveToNext()) {
                    val id = it.getString(_ID)
                    val path = it.getString(MediaStore.MediaColumns.DATA)
                    if (!File(path).exists()) {
                        removedList.add(id)
                        Log.i("PhotoManagerPlugin", "The $path was not exists. ")
                    }
                }
                Log.i("PhotoManagerPlugin", "will be delete ids = $removedList")
            }
            val idWhere = removedList.joinToString(",") { "?" }
            // Remove exists rows.
            val deleteRowCount = cr.delete(
                allUri,
                "$_ID in ( $idWhere )",
                removedList.toTypedArray()
            )
            Log.i("PhotoManagerPlugin", "Delete rows: $deleteRowCount")
        }
        return true
    }

    /**
     * 0 : gallery id
     * 1 : current asset parent path
     */
    override fun getSomeInfo(context: Context, assetId: String): Pair<String, String?>? {
        val cursor = context.contentResolver.query(
            allUri,
            arrayOf(MediaStore.MediaColumns.BUCKET_ID, MediaStore.MediaColumns.DATA),
            "${MediaStore.MediaColumns._ID} = ?",
            arrayOf(assetId),
            null
        ) ?: return null
        cursor.use {
            if (!it.moveToNext()) {
                return null
            }
            val galleryID = it.getString(0)
            val path = it.getString(1)
            return Pair(galleryID, File(path).parent)
        }
    }

    private fun getGalleryInfo(context: Context, galleryId: String): GalleryInfo? {
        val keys = arrayOf(
            MediaStore.MediaColumns.BUCKET_ID,
            MediaStore.MediaColumns.BUCKET_DISPLAY_NAME,
            MediaStore.MediaColumns.DATA
        )
        val cursor = context.contentResolver.query(
            allUri,
            keys,
            "${MediaStore.MediaColumns.BUCKET_ID} = ?",
            arrayOf(galleryId),
            null
        ) ?: return null
        cursor.use {
            if (!it.moveToNext()) {
                return null
            }
            val path = it.getStringOrNull(MediaStore.MediaColumns.DATA) ?: return null
            val name = it.getStringOrNull(MediaStore.MediaColumns.BUCKET_DISPLAY_NAME)
                ?: return null
            val galleryPath = File(path).parentFile?.absolutePath ?: return null
            return GalleryInfo(galleryPath, galleryId, name)
        }
    }

    override fun saveVideo(
        context: Context,
        path: String,
        title: String,
        desc: String,
        relativePath: String?
    ): AssetEntity? {

        path.checkDirs()
        val inputFile = File(path)
        val inputStream: InputStream?
        val outputStream: OutputStream?
        val extension = MimeTypeMap.getFileExtensionFromUrl(inputFile.toString())
        val mimeType = MimeTypeMap.getSingleton().getMimeTypeFromExtension(extension)
        val directory = Environment.DIRECTORY_MOVIES
        val albumDir = File(getAlbumFolderPath(relativePath, MediaType.video, false))
        val videoFilePath = File(albumDir, inputFile.name).absolutePath

        val timestamp = System.currentTimeMillis() / 1000

        val info = VideoUtils.getPropertiesUseMediaPlayer(path)
        val values = ContentValues().apply {
            put(
                MediaStore.Files.FileColumns.MEDIA_TYPE,
                MediaStore.Files.FileColumns.MEDIA_TYPE_VIDEO
            )
            put(MediaStore.Video.VideoColumns.DESCRIPTION, desc)
            put(MediaStore.MediaColumns.TITLE, title)
            put(MediaStore.MediaColumns.DISPLAY_NAME, title)
            put(MediaStore.MediaColumns.MIME_TYPE, mimeType)
            put(MediaStore.MediaColumns.DATE_ADDED, timestamp)
            put(MediaStore.MediaColumns.DATE_MODIFIED, timestamp)
            put(MediaStore.MediaColumns.DATE_TAKEN, timestamp * 1000)
            put(MediaStore.MediaColumns.WIDTH, info.width)
            put(MediaStore.MediaColumns.HEIGHT, info.height)

        }

        if (android.os.Build.VERSION.SDK_INT < 29) {
            try {
                val r = MediaMetadataRetriever()
                r.setDataSource(path)
                val durString = r.extractMetadata(MediaMetadataRetriever.METADATA_KEY_DURATION)
                val duration = durString!!.toInt()
                values.put(MediaStore.Video.Media.DURATION, duration)
                values.put(MediaStore.Video.VideoColumns.DATA, videoFilePath)
            } catch (e: Exception) {
            }
        } else {
            values.put(
                MediaStore.Video.Media.RELATIVE_PATH,
                directory + File.separator + relativePath
            )
        }
        val cr = context.contentResolver

        try {
            val url = cr.insert(MediaStore.Video.Media.EXTERNAL_CONTENT_URI, values)
            inputStream = FileInputStream(inputFile)
            if (url != null) {
                outputStream = cr.openOutputStream(url)
                val buffer = ByteArray(1024 * 1024 * 8)
                inputStream.use {
                    outputStream?.use {
                        var len = inputStream.read(buffer)
                        while (len != -1) {
                            outputStream.write(buffer, 0, len)
                            len = inputStream.read(buffer)
                        }
                    }
                }
                val id = ContentUris.parseId(url)
                val assetEntity = getAssetEntity(context, id.toString())
                cr.notifyChange(url, null)
                return assetEntity
            }
        } catch (fnfE: FileNotFoundException) {
            Log.e("Gllery Save Error", fnfE.message ?: fnfE.toString())
            return null
        } catch (e: Exception) {
            Log.e("Gllery Save Error", e.message ?: e.toString())
            return null
        }
        return null
    }

    private fun getAlbumFolderPath(
        folderName: String?,
        mediaType: MediaType,
        toDcim: Boolean
    ): String {
        var albumFolderPath: String = Environment.getExternalStorageDirectory().path
        if (toDcim && android.os.Build.VERSION.SDK_INT < 29) {
            albumFolderPath += File.separator + Environment.DIRECTORY_DCIM;
        }
        albumFolderPath = if (TextUtils.isEmpty(folderName)) {
            var baseFolderName = if (mediaType == MediaType.image)
                Environment.DIRECTORY_PICTURES else
                Environment.DIRECTORY_MOVIES
            if (toDcim) {
                baseFolderName = Environment.DIRECTORY_DCIM;
            }
            createDirIfNotExist(
                Environment.getExternalStoragePublicDirectory(baseFolderName).path
            ) ?: albumFolderPath
        } else {
            createDirIfNotExist(albumFolderPath + File.separator + folderName)
                ?: albumFolderPath
        }
        return albumFolderPath
    }

    private fun createDirIfNotExist(dirPath: String): String? {
        val dir = File(dirPath)
        if (!dir.exists()) {
            if (dir.mkdirs()) {
                return dir.path
            } else {
                return null
            }
        } else {
            return dir.path
        }
    }

    private data class GalleryInfo(val path: String, val galleryId: String, val galleryName: String)
}

enum class MediaType { image, video }