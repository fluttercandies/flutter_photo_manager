import { MethodCall } from '@ohos/flutter_ohos';
import { MethodResult } from '@ohos/flutter_ohos/src/main/ets/plugin/common/MethodChannel';
import { HandlerBase, MethodCallHandlerBase } from './HandlerBase';
import { photoAccessHelper } from '@kit.MediaLibraryKit';
import { RequestType } from '../types/RequestType';
import { dataSharePredicates } from '@kit.ArkData';
import PhotoManagerPlugin from '../PhotoManagerPlugin';
import { PermissionHandler } from './PermissionHandler';
import { PhotoAssetHandler } from './PhotoAssetHandler';
import { AsyncCallback } from '@ohos.base';
import { MapUtils } from '../utils/MapUtils';

export class AlbumHandler extends HandlerBase implements MethodCallHandlerBase {
  async onMethodCall(call: MethodCall, result: MethodResult): Promise<boolean> {
    if (this.uiContext == null) {
      result.error('100', `${call.method} : uiContext is null`, 'it should not be null');
      return true;
    }
    switch (call.method) {
      case 'getAssetPathList': {
        let args: Map<string, ESObject> = call.args;
        // 'type': type.value,
        // 'hasAll': hasAll,
        // 'onlyAll': onlyAll,
        // 'option': filterOption.toMap(),
        // "pathOption": pathFilterOption.toMap(),

        let hasAll: boolean = args.get('hasAll');
        let onlyAll: boolean = args.get('onlyAll');

        let albums: Array<Map<string, ESObject>> = [];
        // "pathOption": pathFilterOption.toMap(),
        let pathOption: Map<string, ESObject> = args.get('pathOption');
        // type
        // subType
        let ohosPathFilter: Map<string, ESObject> = pathOption.get('ohos');

        let pathFilterType: Array<number> = MapUtils.get(ohosPathFilter, 'type', []);
        let pathFilterSubtype: Array<number> = MapUtils.get(ohosPathFilter, 'subType', []);

        let allObjects: Array<photoAccessHelper.Album> = await AlbumHandler.getAlbums(args, hasAll, onlyAll);
        for (let index = 0; index < allObjects.length; index++) {
          const album = allObjects[index];
          if (!(pathFilterType.includes(album.albumType) && (pathFilterSubtype.includes(album.albumSubtype) || pathFilterSubtype.includes(photoAccessHelper.AlbumSubtype.ANY)))) {
            continue;
          }
          albums.push(AlbumHandler.albumToMap(album));
        }

        result.success(new Map<string, ESObject>(
          [['data', albums]]
        ));
      }
        break;
      case 'getAssetCountFromPath': {
        let args: Map<string, ESObject> = call.args;
        let id: string = args.get('id');
        //option
        //type
        let album: photoAccessHelper.AbsAlbum | null = await AlbumHandler.getAlbum(id);
        if (album != null) {
          result.success(album.count);
        }
        else {
          result.error(`${call.method} failed`, `not find album by ${id}`, null);
        }
      }
        break;
      case 'fetchPathProperties': {
        let args: Map<string, ESObject> = call.args;
        let id: string = args.get('id');
        //option
        //type
        let album: photoAccessHelper.AbsAlbum | null = await AlbumHandler.getAlbum(id);
        if (album != null) {
          result.success(new Map<string, ESObject>(
            [['data', [
              AlbumHandler.albumToMap(album)
            ]]]
          ));
        }
        else {
          result.error(`${call.method} failed`, `not find album by ${id}`, null);
        }
      }
        break;
      case 'getAssetCount': {
        // 'type': type.value,
        // 'option': filter.toMap(),
        let args: Map<string, ESObject> = call.args;
        //option
        //type
        let allObjects: Array<photoAccessHelper.Album> = await AlbumHandler.getAlbums(args, true, true);
        let count: number = 0;
        allObjects.forEach((e) => {
          count += e.count;
        })
        result.success(count);
      }
        break;
      default:
        return false;
    }

    return true;
  }

  static async getAlbum(id: string): Promise<photoAccessHelper.Album | null> {

    if (!(await PermissionHandler.permissionReadCheck())) {
      return null;
    }

    if (id == AllAlbum.allAlbumKey) {
      return await AlbumHandler.getAllAlbum(RequestType.all);
    }
    else if (id == AllAlbum.allImageAlbumKey) {
      return await AlbumHandler.getAllAlbum(RequestType.image);
    }
    else if (id == AllAlbum.allVideoAlbumKey) {
      return await AlbumHandler.getAllAlbum(RequestType.video);
    }

    let predicates: dataSharePredicates.DataSharePredicates = new dataSharePredicates.DataSharePredicates();
    predicates.equalTo(photoAccessHelper.AlbumKeys.URI, id);
    let fetchOptions: photoAccessHelper.FetchOptions = {
      fetchColumns: [
      // photoAccessHelper.AlbumKeys.URI,
      // photoAccessHelper.AlbumKeys.ALBUM_NAME,
      //...Object.keys(photoAccessHelper.PhotoKeys),
      ],
      predicates: predicates
    };
    let phAccessHelper = photoAccessHelper.getPhotoAccessHelper(PhotoManagerPlugin.uiContext);


    let user: photoAccessHelper.FetchResult<photoAccessHelper.Album> = await phAccessHelper.getAlbums(photoAccessHelper.AlbumType.USER, photoAccessHelper.AlbumSubtype.ANY, fetchOptions);
    if (user.getCount() != 0) {
      let album = await user.getFirstObject();
      user.close();
      return album;
    }
    else {
      let system: photoAccessHelper.FetchResult<photoAccessHelper.Album> = await phAccessHelper.getAlbums(photoAccessHelper.AlbumType.SYSTEM, photoAccessHelper.AlbumSubtype.ANY, fetchOptions);
      if (system.getCount() != 0) {
        let album = await system.getFirstObject();
        system.close();
        return album;
      }
    }

    return null;
  }

  static async getAlbums(args: Map<string, ESObject>, hasAll: boolean = true, onlyAll: boolean = false): Promise<Array<photoAccessHelper.Album>> {
    if (!(await PermissionHandler.permissionReadCheck())) {
      return [];
    }
    if (onlyAll) {
      return [await AlbumHandler.getAllAlbum(RequestType.all)];
    }

    let requestType: RequestType = new RequestType(args.get('type'));

    if (!(requestType.containsImage() && requestType.containsVideo())) {
      if (requestType.containsImage()) {
        return [await AlbumHandler.getAllAlbum(RequestType.image)];
      }
      else if (requestType.containsVideo()) {
        return [await AlbumHandler.getAllAlbum(RequestType.video)];
      }
    }

    // hasAll 返回的列表里有一个代表所有的相册
    // onlyAll 只返回这个代表所有的相册
    // 在鸿蒙这边 这个相册 应该是 从 system 这个类型里面获取到的相册的集合
    let phAccessHelper = photoAccessHelper.getPhotoAccessHelper(PhotoManagerPlugin.uiContext);
    let predicates: dataSharePredicates.DataSharePredicates = new dataSharePredicates.DataSharePredicates();
    let fetchOptions: photoAccessHelper.FetchOptions = {
      fetchColumns: [
      // photoAccessHelper.AlbumKeys.URI,
      // photoAccessHelper.AlbumKeys.ALBUM_NAME,
      //...Object.keys(photoAccessHelper.PhotoKeys),
      ],
      predicates: predicates
    };


    let allObjects: Array<photoAccessHelper.Album> = [];
    if (hasAll) {
      allObjects.push(await AlbumHandler.getAllAlbum(RequestType.all));
    }


    // TODO 合并，如果官方不提供获取 all 的 api
    // let system: photoAccessHelper.FetchResult<photoAccessHelper.Album> = await phAccessHelper.getAlbums(photoAccessHelper.AlbumType.SYSTEM, photoAccessHelper.AlbumSubtype.ANY, fetchOptions);
    // let list = await system.getAllObjects();
    //
    // // allObjects.push(...await system.getAllObjects());
    // system.close();

    allObjects.push(await AlbumHandler.getAllAlbum(RequestType.image));
    allObjects.push(await AlbumHandler.getAllAlbum(RequestType.video));

    let user: photoAccessHelper.FetchResult<photoAccessHelper.Album> = await phAccessHelper.getAlbums(photoAccessHelper.AlbumType.USER, photoAccessHelper.AlbumSubtype.ANY, fetchOptions);
    allObjects.push(...await user.getAllObjects());
    user.close();
    return allObjects;
  }

  static albumToMap(album: photoAccessHelper.AbsAlbum): Map<string, ESObject> {
    return new Map<string, ESObject>([
      ['modified', 1],
      // file://media/PhotoAlbum/2
      ['id', album.albumUri],
      ['name', album.albumName],
      /// The type of the album.
      ///  * Android: Always be 1.
      ///  * iOS: 1 - Album, 2 - Folder.
      ['albumType', 1],
      ['assetCount', album.count],
      ['ohosAlbumType', album.albumType],
      ['ohosAlbumSubtype', album.albumSubtype],
      // ['albumTypeNameOhos', EnumUtils.getName(photoAccessHelper.AlbumType, album.albumType)],
      // ['albumSubtypeNameOhos', EnumUtils.getName(photoAccessHelper.AlbumSubtype, album.albumSubtype)],
      ['isAll', (album instanceof AllAlbum) ? (album as AllAlbum).isAll : false],
    ]);
  }

  static async getAllAlbum(requestType: RequestType): Promise<AllAlbum> {

    let predicates: dataSharePredicates.DataSharePredicates = new dataSharePredicates.DataSharePredicates();
    if (!(requestType.containsImage() && requestType.containsVideo())) {
      if (requestType.containsImage()) {
        predicates.equalTo(photoAccessHelper.PhotoKeys.PHOTO_TYPE, photoAccessHelper.PhotoType.IMAGE);
      }
      else if (requestType.containsVideo()) {
        predicates.equalTo(photoAccessHelper.PhotoKeys.PHOTO_TYPE, photoAccessHelper.PhotoType.VIDEO);
      }
    }
    let options: photoAccessHelper.FetchOptions = {
      fetchColumns: [],
      predicates: predicates
    };
    let phAccessHelper = photoAccessHelper.getPhotoAccessHelper(PhotoManagerPlugin.uiContext);
    let assets = await phAccessHelper.getAssets(options);

    return new AllAlbum(requestType, assets.getCount());

  }

  static async copyToAlbum(album: photoAccessHelper.Album, photoAsset: photoAccessHelper.PhotoAsset): Promise<void> {
    let phAccessHelper = photoAccessHelper.getPhotoAccessHelper(PhotoManagerPlugin.uiContext);
    let albumChangeRequest = new photoAccessHelper.MediaAlbumChangeRequest(album);
    albumChangeRequest.addAssets([photoAsset]);
    await phAccessHelper.applyChanges(albumChangeRequest);
  }
}

/// For all Album and photo Album
class AllAlbum implements photoAccessHelper.Album {
  static readonly allAlbumKey: string = 'AllAlbum';
  static readonly allImageAlbumKey: string = 'AllImageAlbum';
  static readonly allVideoAlbumKey: string = 'AllVideoAlbum';

  constructor(requestType: RequestType, count: number) {
    let albumName = '';
    this.albumSubtype = photoAccessHelper.AlbumSubtype.ANY;
    if (requestType == RequestType.image) {
      albumName = AllAlbum.allImageAlbumKey;
    }
    else if (requestType == RequestType.video) {
      albumName = AllAlbum.allVideoAlbumKey;
      this.albumSubtype = photoAccessHelper.AlbumSubtype.VIDEO;
    }
    else {
      albumName = AllAlbum.allAlbumKey;
    }
    this.albumType = photoAccessHelper.AlbumType.SYSTEM;

    this.albumName = albumName;
    this.albumUri = albumName;
    this.count = count;
    this.coverUri = '';
    this.isAll = albumName == AllAlbum.allAlbumKey;
    this.requestType = requestType;
  }

  requestType: RequestType;
  imageCount?: number | undefined;
  videoCount?: number | undefined;

  commitModify(callback: AsyncCallback<void, void>): void;
  commitModify(): Promise<void>;
  commitModify(callback?: AsyncCallback<void, void>): void | Promise<void> {
    throw new Error('Method not implemented.');
  }

  addAssets(assets: photoAccessHelper.PhotoAsset[], callback: AsyncCallback<void, void>): void;
  addAssets(assets: photoAccessHelper.PhotoAsset[]): Promise<void>;
  addAssets(assets: photoAccessHelper.PhotoAsset[], callback?: AsyncCallback<void, void>): void | Promise<void> {
    throw new Error('Method not implemented.');
  }

  removeAssets(assets: photoAccessHelper.PhotoAsset[], callback: AsyncCallback<void, void>): void;
  removeAssets(assets: photoAccessHelper.PhotoAsset[]): Promise<void>;
  removeAssets(assets: photoAccessHelper.PhotoAsset[], callback?: AsyncCallback<void, void>): void | Promise<void> {
    throw new Error('Method not implemented.');
  }

  albumType: photoAccessHelper.AlbumType;
  albumSubtype: photoAccessHelper.AlbumSubtype;
  albumName: string;
  albumUri: string;
  count: number;
  coverUri: string;
  isAll: boolean;

  async getAssets(options: photoAccessHelper.FetchOptions): Promise<photoAccessHelper.FetchResult<photoAccessHelper.PhotoAsset>> {
    let phAccessHelper = photoAccessHelper.getPhotoAccessHelper(PhotoManagerPlugin.uiContext);
    if (!(this.requestType.containsImage() && this.requestType.containsVideo())) {
      if (this.requestType.containsImage()) {
        options.predicates.equalTo(photoAccessHelper.PhotoKeys.PHOTO_TYPE, photoAccessHelper.PhotoType.IMAGE);
      }
      else if (this.requestType.containsVideo()) {
        options.predicates.equalTo(photoAccessHelper.PhotoKeys.PHOTO_TYPE, photoAccessHelper.PhotoType.VIDEO);
      }
    }

    let assets = await phAccessHelper.getAssets(options);
    return assets;
  }
}