package com.example.imagegallerysaver;

import android.content.ContentResolver;
import android.content.ContentValues;
import android.content.Context;
import android.graphics.Bitmap;
import android.net.Uri;
import android.os.Build;
import android.os.Environment;
import android.provider.MediaStore;
import androidx.annotation.NonNull;

import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.OutputStream;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;

public class ImageGallerySaverPlugin implements FlutterPlugin, MethodCallHandler {
    private static final String ALBUM_NAME = "Planillas";

    private MethodChannel channel;
    private Context context;

    @Override
    public void onAttachedToEngine(@NonNull FlutterPluginBinding binding) {
        channel = new MethodChannel(binding.getBinaryMessenger(), "image_gallery_saver");
        context = binding.getApplicationContext();
        channel.setMethodCallHandler(this);
    }

    @Override
    public void onMethodCall(@NonNull MethodCall call, @NonNull Result result) {
        if (call.method.equals("saveFile")) {
            String filePath = call.argument("filePath");
            String name = call.argument("name");

            // Añade validaciones para los argumentos para evitar NullPointerExceptions.
            if (filePath == null || filePath.isEmpty()) {
                result.error("ARGUMENT_ERROR", "filePath cannot be null or empty", null);
                return;
            }
            if (name == null || name.isEmpty()) {
                result.error("ARGUMENT_ERROR", "name cannot be null or empty", null);
                return;
            }

            try {
                File file = new File(filePath);
                if (!file.exists()) {
                    result.error("FILE_NOT_FOUND", "File not found", null);
                    return;
                }
                saveFileToGallery(file, name, result);
            } catch (Exception e) {
                result.error("SAVE_ERROR", e.getMessage(), null);
            }
        } else {
            result.notImplemented();
        }
    }

    private void saveFileToGallery(File file, String name, Result result) {
        try {
            final String fileNameWithExt = name + ".png";

            ContentValues values = new ContentValues();
            values.put(MediaStore.MediaColumns.DISPLAY_NAME, fileNameWithExt);
            values.put(MediaStore.MediaColumns.MIME_TYPE, "image/png");
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                // Para Android 10 y superior, se usa RELATIVE_PATH para especificar la subcarpeta en DCIM.
                values.put(MediaStore.MediaColumns.RELATIVE_PATH, Environment.DIRECTORY_DCIM + File.separator + ALBUM_NAME);
            } else {
                // Para versiones anteriores a Android Q, se necesita la ruta absoluta.
                File dcimDir = Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DCIM);
                File albumDir = new File(dcimDir, ALBUM_NAME);
                // Asegurarse de que el directorio de destino exista.
                if (!albumDir.exists()) {
                    albumDir.mkdirs();
                }
                File imageFile = new File(albumDir, fileNameWithExt);
                values.put(MediaStore.Images.Media.DATA, imageFile.getAbsolutePath());
            }

            ContentResolver resolver = context.getContentResolver();
            Uri uri = resolver.insert(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, values);

            if (uri != null) {
                try (OutputStream os = resolver.openOutputStream(uri);
                     java.io.FileInputStream is = new java.io.FileInputStream(file)) {
                    if (os != null) {
                        byte[] buffer = new byte[4096];
                        int bytesRead;
                        while ((bytesRead = is.read(buffer)) != -1) {
                            os.write(buffer, 0, bytesRead);
                        }
                    }
                }
                result.success(true);
            } else {
                result.error("SAVE_ERROR", "Failed to create new MediaStore record.", null);
            }
        } catch (IOException e) {
            result.error("SAVE_ERROR", e.getMessage(), null);
        }
    }

    @Override
    public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
        channel.setMethodCallHandler(null);
    }
}
