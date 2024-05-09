import { MethodResult } from '@ohos/flutter_ohos/src/main/ets/plugin/common/MethodChannel';
import { BusinessError } from '@kit.BasicServicesKit';
import { photoAccessHelper } from '@kit.MediaLibraryKit';
import fs from '@ohos.file.fs';
import { PhotoAssetHandler } from './PhotoAssetHandler';
import { MethodCall } from '@ohos/flutter_ohos';
import { HandlerBase, MethodCallHandlerBase } from './HandlerBase';
import { PermissionHandler } from './PermissionHandler';
import PhotoManagerPlugin from '../PhotoManagerPlugin';

export class SaveHandler extends HandlerBase implements MethodCallHandlerBase {
  async onMethodCall(call: MethodCall, result: MethodResult): Promise<boolean> {
    if (this.uiContext == null) {
      result.error('100', `${call.method} : uiContext is null`, 'it should not be null');
      return true;
    }
    switch (call.method) {
      case 'saveImage': {
        // 'image': data,
        // 'title': title,
        // 'desc': desc ?? '',
        // 'relativePath': relativePath,
        // 'onlyAddPermission': true,
        let args: Map<string, ESObject> = call.args;
        let list: Uint8Array = args.get('image');
        await this._save(args, result, photoAccessHelper.PhotoType.IMAGE, list.buffer as ArrayBuffer);
      }
        break;
      case 'saveImageWithPath': {
        // 'path': path,
        // 'title': title,
        // 'desc': desc ?? '',
        // 'relativePath': relativePath,
        // 'onlyAddPermission': true,
        let args: Map<string, ESObject> = call.args;
        let path: string = args.get('path');
        let buff = await SaveHandler.getBuffFromPath(path);
        await this._save(args, result, photoAccessHelper.PhotoType.IMAGE, buff);
      }
        break;
      case 'saveVideo': {
        // 'path': path,
        // 'title': title,
        // 'desc': desc ?? '',
        // 'relativePath': relativePath,
        // 'onlyAddPermission': true,
        let args: Map<string, ESObject> = call.args;
        let path: string = args.get('path');
        let buff = await SaveHandler.getBuffFromPath(path);
        await this._save(args, result, photoAccessHelper.PhotoType.VIDEO, buff);
      }
        break;
      default:
        return false;
    }

    return true;
  }


  private static async getBuffFromPath(path: string): Promise<ArrayBuffer> {
    let file = fs.openSync(path, fs.OpenMode.READ_ONLY);
    let stat = await fs.stat(file.fd);
    let buff = new ArrayBuffer(stat.size);
    await fs.read(file.fd, buff);
    fs.close(file.fd);
    return buff;
  }

  private async _save(args: Map<string, ESObject>, result: MethodResult, photoType: photoAccessHelper.PhotoType, buffer: ArrayBuffer,
    //  srcUri?: string
  ): Promise<void> {
    if (!(await PermissionHandler.permissionWriteCheck())) {
      result.error('no ohos.permission.WRITE_IMAGEVIDEO', '', '');
    }

    try {
      let title: string = args.get('title');
      let extension: string = photoType == photoAccessHelper.PhotoType.IMAGE ? 'jpg' : 'mp4';
      if (title != undefined && title.includes('.')) {
        const lastIndex = title.lastIndexOf('.');
        if (lastIndex > 0 && lastIndex < title.length -1) {
          extension = title.slice(lastIndex + 1);
          title = title.slice(0, lastIndex);
        }
      }
      let createOptions: photoAccessHelper.CreateOptions = {};
      if (title != undefined) {
        createOptions = {
          title: title,
        };
      }
      let phAccessHelper = photoAccessHelper.getPhotoAccessHelper(this.uiContext);
      let assetChangeRequest: photoAccessHelper.MediaAssetChangeRequest = photoAccessHelper.MediaAssetChangeRequest.createAssetRequest(this.uiContext, photoType, extension, createOptions);
      assetChangeRequest.addResource(photoType == photoAccessHelper.PhotoType.IMAGE ? photoAccessHelper.ResourceType.IMAGE_RESOURCE : photoAccessHelper.ResourceType.VIDEO_RESOURCE, buffer);
      await phAccessHelper.applyChanges(assetChangeRequest);
      let asset = assetChangeRequest.getAsset();
      let path = asset.uri;
      let photoAsset: photoAccessHelper.PhotoAsset | null = await PhotoAssetHandler.getPhotoAsset(path);
      if (photoAsset != null) {
        result.success(PhotoAssetHandler.photoAssetToMap(photoAsset));
      }
      else {
        if (PhotoManagerPlugin.showLog) {
          console.info('can not find photo for now', path, '');
        }
        result.error('can not find photo for now', path, '');
      }
    } catch (error) {
      let err: BusinessError = error as BusinessError;
      if (PhotoManagerPlugin.showLog) {
        console.info(err.code.toString(), err.message, err.stack);
      }
      result.error(err.code.toString(), err.message, err.stack);
    }
  }
}