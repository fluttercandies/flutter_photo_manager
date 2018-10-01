package top.kikt.imagescanner.thumb;

import android.content.Context;
import android.graphics.Bitmap;
import android.graphics.Color;
import android.graphics.drawable.Drawable;
import android.support.annotation.NonNull;
import android.support.annotation.Nullable;

import com.bumptech.glide.Glide;
import com.bumptech.glide.request.transition.Transition;

import java.io.ByteArrayOutputStream;
import java.io.File;
import java.util.ArrayList;

import io.flutter.plugin.common.MethodChannel;

/**
 * Created by debuggerx on 18-9-27 下午2:08
 */
public class ThumbnailUtil {
    public static void getThumbnailByGlideUsePixels(Context ctx, String path, int width, int height, final MethodChannel.Result result) {

        Glide.with(ctx)
                .asBitmap()
                .load(new File(path))
                .into(new CustomTarget<Bitmap>(width, height) {
                    @Override
                    public void onResourceReady(@NonNull Bitmap resource, @Nullable Transition<? super Bitmap> transition) {
                        int[] pixels = new int[resource.getWidth() * resource.getHeight()];
                        resource.getPixels(pixels, 0, resource.getWidth(), 0, 0, resource.getWidth(), resource.getHeight());
                        int[] res = new int[pixels.length * 4];
                        for (int i = 0; i < pixels.length; i++) {
                            res[i * 4] = Color.red(pixels[i]);
                            res[i * 4 + 1] = Color.green(pixels[i]);
                            res[i * 4 + 2] = Color.blue(pixels[i]);
                            res[i * 4 + 3] = Color.alpha(pixels[i]);
                        }

                        ArrayList<Object> list = new ArrayList<>();
                        list.add(resource.getWidth());
                        list.add(resource.getHeight());
                        list.add(res);
                        result.success(list);
                    }

                    @Override
                    public void onLoadCleared(@Nullable Drawable placeholder) {
                        result.success(null);
                    }
                });
    }

    public static void getThumbnailByGlide(Context ctx, String path, final MethodChannel.Result result) {
        getThumbnailByGlide(ctx, path, 64, 64, result);
    }


    public static void getThumbnailByGlide(Context ctx, String path, int width, int height, final MethodChannel.Result result) {

        Glide.with(ctx)
                .asBitmap()
                .load(new File(path))
                .into(new CustomTarget<Bitmap>(width, height) {
                    @Override
                    public void onResourceReady(@NonNull Bitmap resource, @Nullable Transition<? super Bitmap> transition) {
                        ByteArrayOutputStream bos = new ByteArrayOutputStream();
                        resource.compress(Bitmap.CompressFormat.JPEG, 100, bos);
                        result.success(bos.toByteArray());
                    }

                    @Override
                    public void onLoadCleared(@Nullable Drawable placeholder) {
                        result.success(null);
                    }
                });
    }
}
