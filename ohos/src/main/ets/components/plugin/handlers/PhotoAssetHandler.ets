import { photoAccessHelper } from '@kit.MediaLibraryKit';
import { dataSharePredicates } from '@kit.ArkData';
import { HandlerBase, MethodCallHandlerBase } from './HandlerBase';
import PhotoManagerPlugin from '../PhotoManagerPlugin';
import { MethodResult } from '@ohos/flutter_ohos/src/main/ets/plugin/common/MethodChannel';
import { MethodCall } from '@ohos/flutter_ohos';
import { RequestType } from '../types/RequestType';
import { AlbumHandler } from './AlbumHandler';
import { image } from '@kit.ImageKit';
import fs from '@ohos.file.fs';
import { FilterOption } from '../filter/FilterOption';
import { PermissionHandler } from './PermissionHandler';

export class PhotoAssetHandler extends HandlerBase implements MethodCallHandlerBase {
  async onMethodCall(call: MethodCall, result: MethodResult): Promise<boolean> {
    if (this.uiContext == null) {
      result.error('100', 'uiContext is null', 'it should not be null');
      return true;
    }
    switch (call.method) {
      case 'getAssetListPaged': {
        let args: Map<string, ESObject> = call.args;
        // 'id': id,
        // 'type': type.value,
        // 'page': page,
        // 'size': size,
        // 'option': optionGroup.toMap(),
        // let id: string = args.get('id');
        let page: number = args.get('page');
        let size: number = args.get('size');
        let assets: Array<Map<string, ESObject>> | null = await this.getAssetList(args, page * size, (page + 1) * size);
        if (assets != null) {
          result.success(new Map<string, ESObject>(
            [['data', assets]]
          ));
        }
        else {
          result.error(`${call.method} failed`, `not find assets by ${args}`, null);
        }
      }
        break;
      case 'getFullFile': {
        let args: Map<string, ESObject> = call.args;
        let id: string = args.get('id');
        // 'id': id,
        // 'isOrigin': isOrigin,
        // 'subtype': subtype,
        let photoAsset: photoAccessHelper.PhotoAsset | null = await PhotoAssetHandler.getPhotoAsset(id);
        // this.photoAssets.get(id);
        if (photoAsset != null) {
          result.success(photoAsset.uri);
        }
        else {
          result.error(`${call.method} failed`, `not find asset by ${id}`, null);
        }
      }
        break;
      case 'getOriginBytes': {
        let args: Map<string, ESObject> = call.args;
        let id: string = args.get('id');
        //option
        //type
        let photoAsset: photoAccessHelper.PhotoAsset | null = await PhotoAssetHandler.getPhotoAsset(id);
        // this.photoAssets.get(id);
        if (photoAsset != null) {
          let file = await fs.open(photoAsset.uri, fs.OpenMode.READ_ONLY);
          // let stat = await fs.stat(photoAsset.uri);
          let size = PhotoAssetHandler.getAssetMember(photoAsset, photoAccessHelper.PhotoKeys.SIZE)
          let arrayBuffer: ArrayBuffer = new ArrayBuffer(size as number);
          await fs.read(file.fd, arrayBuffer);
          await fs.close(file.fd);
          result.success(new Uint8Array(arrayBuffer));
        }
        else {
          result.error(`${call.method} failed`, `not find asset by ${args}`, null);
        }
      }
        break;
      case 'getThumb': {
        let args: Map<string, ESObject> = call.args;
        let id: string = args.get('id');
        // 'width': size.width,
        // 'height': size.height,
        // 'format': format.index,
        // 'quality': quality,
        // 'frame': frame,
        let option: Map<string, ESObject> = args.get('option');
        let width: number = option.get('width');
        let height: number = option.get('height');
        //option
        //type
        let photoAsset: photoAccessHelper.PhotoAsset | null = await PhotoAssetHandler.getPhotoAsset(id);
        // this.photoAssets.get(id);
        if (photoAsset != null) {

          let pixelMap: image.PixelMap;
          if (width != undefined && height != undefined) {
            pixelMap = await photoAsset.getThumbnail({
              width: width,
              height: height,
            });
          }
          else {
            pixelMap = await photoAsset.getThumbnail();
          }
          const imagePackerApi = image.createImagePacker();

          let format: string = 'image/jpeg';
          switch (option.get('format')) {
            case 1:
              format = 'image/png'
              break;
            default:
              break;
          }

          const packOptions: image.PackingOption = {
            format: format,
            quality: option.get('quality'),
          }

          let uint8Array: Uint8Array = new Uint8Array(await imagePackerApi.packing(pixelMap, packOptions));
          pixelMap.release();
          result.success(uint8Array);
        }
        else {
          result.error(`${call.method} failed`, `not find asset by ${args}`, null);
        }
      }
        break;
      case 'getAssetListRange': {
        // 'id': id,
        // 'type': type.value,
        // 'start': start,
        // 'end': end,
        // 'option': optionGroup.toMap(),
        let args: Map<string, ESObject> = call.args;
        let start: number = args.get('start');
        let end: number = args.get('end');

        let assets: Array<Map<string, ESObject>> | null = await this.getAssetList(args, start, end);
        if (assets != null) {
          result.success(new Map<string, ESObject>(
            [['data', assets]]
          ));
        }
        else {
          result.error(`${call.method} failed`, `not find assets by ${args}`, null);
        }
      }
        break;
      case 'getAssetsByRange': {
        // 'type': type.value,
        // 'start': start,
        // 'end': end,
        // 'option': filter.toMap(),
        let args: Map<string, ESObject> = call.args;
        let start: number = args.get('start');
        let end: number = args.get('end');
        let allObjects: Array<photoAccessHelper.Album> = await AlbumHandler.getAlbums(args, true, true);
        let data: Array<Map<string, ESObject>> = [];
        for (let i = 0; i < allObjects.length; i++) {
          const element = allObjects[i];
          if (element.count == 0) {
            continue;
          }
          start = start - element.count;
          end = end = element.count;
          let assets: Array<Map<string, ESObject>> | null = await this.getAssetList(args, start, end, element);
          if (assets != null) {
            data.push(...assets);
          }
          else {
            result.error(`${call.method} failed`, `not find assets by ${args}`, null);
            return true;
          }
        }
        result.success(new Map<string, ESObject>(
          [['data', data]]
        ));
      }
        break;
      case 'deleteWithIds':
      case 'moveToTrash': {
        if (!(await PermissionHandler.permissionWriteCheck())) {
          result.error('no ohos.permission.WRITE_IMAGEVIDEO', '', '');
          return true;
        }
        let args: Map<string, ESObject> = call.args;
        let ids: Array<string> = args.get('ids');


        await photoAccessHelper.MediaAssetChangeRequest.deleteAssets(this.uiContext, ids);
        // 从回收站里面彻底删除，系统接口，目前不支持
        // if (call.method == 'deleteWithIds') {
        //
        // }
        result.success(ids);
      }
        break;
      case 'getColumnNames':
        result.success(Object.keys(photoAccessHelper.PhotoKeys));
        break;
      case 'fetchEntityProperties': {
        let args: Map<string, ESObject> = call.args;
        let id: string = args.get('id');
        let photoAsset: photoAccessHelper.PhotoAsset | null = await PhotoAssetHandler.getPhotoAsset(id);
        if (photoAsset != null) {
          result.success(PhotoAssetHandler.photoAssetToMap(photoAsset));
        }
        else {
          result.error(`${call.method} failed`, `not find asset by ${args}`, null);
        }
      }
        break;
      case 'assetExists': {
        let args: Map<string, ESObject> = call.args;
        let id: string = args.get('id');
        let photoAsset: photoAccessHelper.PhotoAsset | null = await PhotoAssetHandler.getPhotoAsset(id);
        result.success(photoAsset != null);
      }
        break;
      case 'favoriteAsset': {
        let args: Map<string, ESObject> = call.args;
        let id: string = args.get('id');
        let favorite: Boolean = args.get('favorite');
        let photoAsset: photoAccessHelper.PhotoAsset | null = await PhotoAssetHandler.getPhotoAsset(id);
        if (photoAsset == null) {
          result.success(false);
        }
        else {
          result.success(PhotoAssetHandler.setAssetMember(photoAsset, photoAccessHelper.PhotoKeys.FAVORITE, favorite ? 'true' : 'false'));
        }
      }
        break;
      case 'getFileFd': {
        let args: Map<string, ESObject> = call.args;
        let id: string = args.get('id');
        let photoAsset: photoAccessHelper.PhotoAsset | null = await PhotoAssetHandler.getPhotoAsset(id);
        if (photoAsset != null) {
          let file = await fs.open(photoAsset.uri, fs.OpenMode.READ_ONLY);
          result.success(file.fd);
        }
        else {
          result.error(`${call.method} failed`, `not find asset by ${args}`, null);
        }
      }
        break;
      case 'copyAsset': {
        let args: Map<string, ESObject> = call.args;
        let id: string = args.get('assetId');
        let galleryId: string = args.get('galleryId');
        let photoAsset: photoAccessHelper.PhotoAsset | null = await PhotoAssetHandler.getPhotoAsset(id);

        let album: photoAccessHelper.Album | null = await AlbumHandler.getAlbum(galleryId);
        if (photoAsset != null && album != null) {
          try {
            await AlbumHandler.copyToAlbum(album, photoAsset);
            result.success(PhotoAssetHandler.photoAssetToMap(photoAsset));
          }
          catch (e) {
            result.error(`${call.method} failed`, e.toString(), null);
          }
        }
        else {
          let errorInfo = '';
          if (photoAsset == null) {
            errorInfo = `not find asset by ${id}`;
          }
          if (album == null) {
            errorInfo += `not find album by ${galleryId}`;
          }
          result.error(`${call.method} failed`, errorInfo, null);
        }
      }
        break;
      default:
        return false;
    }

    return true;
  }

  async getAssetList(args: Map<string, ESObject>, start: number, end: number, album?: photoAccessHelper.AbsAlbum | null): Promise<Array<Map<string, ESObject>> | null> {
    if (!(await PermissionHandler.permissionReadCheck())) {
      return null;
    }
    let id: string = args.get('id');

    album = album ?? await AlbumHandler.getAlbum(id);
    // = this.albums.get(id);
    if (album != undefined) {

      start = Math.max(0, start);
      end = Math.min(end, album.count);
      let assets: Array<Map<string, ESObject>> = [];
      if (start > end) {
        return assets;
      }
      let filterOption: FilterOption = new FilterOption(args.get('option'));
      let requestType: RequestType = new RequestType(args.get('type'));
      let predicates: dataSharePredicates.DataSharePredicates = new dataSharePredicates.DataSharePredicates();
      if (!(requestType.containsImage() && requestType.containsVideo())) {
        if (requestType.containsImage()) {
          predicates.equalTo(photoAccessHelper.PhotoKeys.PHOTO_TYPE, photoAccessHelper.PhotoType.IMAGE);
        }
        else if (requestType.containsVideo()) {
          predicates.equalTo(photoAccessHelper.PhotoKeys.PHOTO_TYPE, photoAccessHelper.PhotoType.VIDEO);
        }
      }

      if (filterOption.child.orderBy.length != 0) {
        for (let index = 0; index < filterOption.child.orderBy.length; index++) {
          const orderByItem = filterOption.child.orderBy[index];
          let column = orderByItem.column;
          if (column.length == 0 || !Object.values(photoAccessHelper.PhotoKeys)
            .includes(column as photoAccessHelper.PhotoKeys)) {
            continue;
          }
          if (orderByItem.isAsc) {
            predicates.orderByAsc(orderByItem.column);
          }
          else {
            predicates.orderByDesc(orderByItem.column);
          }
        }
      }

      if (filterOption.child.orders.length != 0) {
        for (let index = 0; index < filterOption.child.orders.length; index++) {
          const orderItem = filterOption.child.orders[index];
          let column: string | undefined = undefined;
          if (orderItem.type == 0) {
            column = photoAccessHelper.PhotoKeys.DATE_ADDED;
          }
          else if (orderItem.type == 1) {
            column = photoAccessHelper.PhotoKeys.DATE_MODIFIED;
          }
          if (column != undefined) {
            if (orderItem.asc) {
              predicates.orderByAsc(column);
            }
            else {
              predicates.orderByDesc(column);
            }
          }
        }
      }

      let fetchOptions: photoAccessHelper.FetchOptions = {
        fetchColumns: [
          'width',
          'height',
          'duration',
          'orientation',
          'is_favorite',
          'title',
          'date_added',
          'date_modified',
          'media_type',
          'size',
        //...Object.keys(photoAccessHelper.PhotoKeys),
        ],
        predicates: predicates
      };

      let photoFetchResult: photoAccessHelper.FetchResult<photoAccessHelper.PhotoAsset> =
        await album.getAssets(fetchOptions);

      for (let index = start; index < end && index < album.count; index++) {
        let photoAsset: photoAccessHelper.PhotoAsset = await photoFetchResult.getObjectByPosition(index);
        assets.push(PhotoAssetHandler.photoAssetToMap(photoAsset));
      }
      photoFetchResult.close();
      return assets;
    }
    else {
      return null;
    }
  }

  static getAssetMember(photoAsset: photoAccessHelper.PhotoAsset, member: string): photoAccessHelper.MemberType | null {
    try {
      return photoAsset.get(member)
    }
    catch (e) {
      return null;
    }
  }

  static setAssetMember(photoAsset: photoAccessHelper.PhotoAsset, member: string, value: string): Boolean {
    try {
      photoAsset.set(member, value);
      return true;
    }
    catch (e) {
      return false;
    }
  }

  static photoAssetToMap(photoAsset: photoAccessHelper.PhotoAsset): Map<string, ESObject> {
    // this.photoAssets.set(photoAsset.uri, photoAsset);
    // typeInt: data['type'] as int,
    // width: data['width'] as int,
    // height: data['height'] as int,
    // duration: data['duration'] as int? ?? 0,
    // orientation: data['orientation'] as int? ?? 0,
    // isFavorite: data['favorite'] as bool? ?? false,
    // title: data['title'] as String? ?? title,
    // subtype: data['subtype'] as int? ?? 0,
    // createDateSecond: data['createDt'] as int?,
    // modifiedDateSecond: data['modifiedDt'] as int?,
    // relativePath: data['relativePath'] as String?,
    // latitude: data['lat'] as double?,
    // longitude: data['lng'] as double?,
    // mimeType: data['mimeType'] as String?,
    let uri = photoAsset.uri;
    // this.getAssetMember(photoAsset, photoAccessHelper.PhotoKeys.URI);
    let media_type = PhotoAssetHandler.getAssetMember(photoAsset, photoAccessHelper.PhotoKeys.PHOTO_TYPE);
    // let display_name = this.getAssetMember(photoAsset, photoAccessHelper.PhotoKeys.DISPLAY_NAME);
    // let size = this.getAssetMember(photoAsset, photoAccessHelper.PhotoKeys.SIZE);
    let date_added = PhotoAssetHandler.getAssetMember(photoAsset, photoAccessHelper.PhotoKeys.DATE_ADDED);
    let date_modified = PhotoAssetHandler.getAssetMember(photoAsset, photoAccessHelper.PhotoKeys.DATE_MODIFIED);
    let duration: number = PhotoAssetHandler.getAssetMember(photoAsset, photoAccessHelper.PhotoKeys.DURATION) as number;
    let width = PhotoAssetHandler.getAssetMember(photoAsset, photoAccessHelper.PhotoKeys.WIDTH);
    let height = PhotoAssetHandler.getAssetMember(photoAsset, photoAccessHelper.PhotoKeys.HEIGHT);
    // let date_taken = this.getAssetMember(photoAsset, photoAccessHelper.PhotoKeys.DATE_TAKEN);
    let orientation = PhotoAssetHandler.getAssetMember(photoAsset, photoAccessHelper.PhotoKeys.ORIENTATION);
    let is_favorite = PhotoAssetHandler.getAssetMember(photoAsset, photoAccessHelper.PhotoKeys.FAVORITE);
    // let title = this.getAssetMember(photoAsset, photoAccessHelper.PhotoKeys.TITLE);

    return new Map<string, ESObject>(
      [
        ['id', uri],
        // IMAGE 1  VIDEO 2
        ['type', photoAsset.photoType],
        ['width', width],
        ['height', height],
        ['duration', Math.ceil(duration / 1000)],
        ['orientation', orientation],
        ['favorite', is_favorite == 1],
        // dart 会根据 title 获取图片类型，所以这里返回文件路径比较好
        // 鸿蒙的 tilte 不带扩展后缀
        ['title', uri],
        // ['title', title],
        // ['subtype', subtype],
        ['createDt', date_added],
        ['modifiedDt', date_modified],
        ['relativePath', uri],
        // latitude: data['lat'] as double?,
        // ['lat', 1.0],
        // longitude: data['lng'] as double?,
        // ['lng', 1.0],
        ['mimeType', media_type?.toString()],
      ]
    );
  }


  static async getPhotoAsset(id: string): Promise<photoAccessHelper.PhotoAsset | null> {
    if (!(await PermissionHandler.permissionReadCheck())) {
      return null;
    }
    let phAccessHelper = photoAccessHelper.getPhotoAccessHelper(PhotoManagerPlugin.uiContext);
    let predicates: dataSharePredicates.DataSharePredicates = new dataSharePredicates.DataSharePredicates();
    predicates.equalTo(photoAccessHelper.PhotoKeys.URI, id);
    let fetchOptions: photoAccessHelper.FetchOptions = {
      fetchColumns: [
        'width',
        'height',
        'duration',
        'orientation',
        'is_favorite',
        'title',
        'date_added',
        'date_modified',
        'media_type',
        'size',
      //...Object.keys(photoAccessHelper.PhotoKeys),
      ],
      predicates: predicates
    };

    let assets = await phAccessHelper.getAssets(fetchOptions);
    if (assets.getCount() != 0) {
      return await assets.getFirstObject();
    }
    return null;
  }
}