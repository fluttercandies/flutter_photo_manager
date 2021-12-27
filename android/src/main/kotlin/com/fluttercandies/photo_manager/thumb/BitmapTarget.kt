package com.fluttercandies.photo_manager.thumb

import android.graphics.Bitmap
import com.bumptech.glide.request.transition.Transition

abstract class BitmapTarget(width: Int, height: Int) : CustomTarget<Bitmap>(width, height) {

    private var bitmap: Bitmap? = null

    override fun onResourceReady(resource: Bitmap, transition: Transition<in Bitmap>?) {
        this.bitmap = resource
    }

    override fun onDestroy() {
        super.onDestroy()
        if (bitmap?.isRecycled == false) {
            bitmap?.recycle()
        }
    }
}
