import { MethodCall } from '@ohos/flutter_ohos';
import { MethodResult } from '@ohos/flutter_ohos/src/main/ets/plugin/common/MethodChannel';
import { HandlerBase, MethodCallHandlerBase } from './HandlerBase';
import { photoAccessHelper } from '@kit.MediaLibraryKit';
import { RequestType } from '../types/RequestType';
import { dataSharePredicates } from '@kit.ArkData';
import PhotoManagerPlugin from '../PhotoManagerPlugin';
import { PermissionHandler } from './PermissionHandler';


export class AlbumHandler extends HandlerBase implements MethodCallHandlerBase {
  async onMethodCall(call: MethodCall, result: MethodResult): Promise<boolean> {
    if (this.uiContext == null) {
      result.error('100', `${call.method} : uiContext is null`, 'it should not be null');
      return true;
    }
    switch (call.method) {
      case 'getAssetPathList': {
        let args: Map<String, ESObject> = call.args;
        // 'type': type.value,
        // 'hasAll': hasAll,
        // 'onlyAll': onlyAll,
        // 'option': filterOption.toMap(),
        // "pathOption": pathFilterOption.toMap(),

        let albums: Array<Map<string, ESObject>> = [];
        let allObjects: Array<photoAccessHelper.Album> = await AlbumHandler.getAlbums(args, true);
        for (let index = 0; index < allObjects.length; index++) {
          const album = allObjects[index];
          // this.albums.set(element.albumUri, element);
          albums.push(AlbumHandler.albumToMap(album));
        }

        result.success(new Map<string, ESObject>(
          [['data', albums]]
        ));
      }
        break;
      case 'getAssetCountFromPath': {
        let args: Map<String, ESObject> = call.args;
        let id: string = args.get('id');
        //option
        //type
        let album: photoAccessHelper.AbsAlbum | null = await AlbumHandler.getAlbum(id);
        if (album != null) {
          result.success(album.count);
        }
        else {
          result.error('', '', '');
        }
      }
        break;
      case 'fetchPathProperties': {
        let args: Map<String, ESObject> = call.args;
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
          result.error('', '', '');
        }
      }
        break;
      case 'getAssetCount': {
        // 'type': type.value,
        // 'option': filter.toMap(),
        let args: Map<String, ESObject> = call.args;
        //option
        //type
        let allObjects: Array<photoAccessHelper.Album> = await AlbumHandler.getAlbums(args);
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

  static async getAlbums(args: Map<String, ESObject>, hasAll: boolean = true, onlyAll: boolean = false): Promise<Array<photoAccessHelper.Album>> {
    if (!(await PermissionHandler.permissionReadCheck())) {
      return [];
    }
    let requestType: RequestType = new RequestType(args.get('type'));
    // hasAll 返回的列表里有一个代表所有的相册
    // onlyAll 只返回这个代表所以的相册
    // 在鸿蒙这边 这个相册 应该是 从 system 这个类型里面获取到的相册的集合
    // TODO 暂时没法做
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

    // TODO 合并，如果官方不提供获取 all 的 api
    let system: photoAccessHelper.FetchResult<photoAccessHelper.Album> = await phAccessHelper.getAlbums(photoAccessHelper.AlbumType.SYSTEM, photoAccessHelper.AlbumSubtype.ANY, fetchOptions);
    allObjects.push(...await system.getAllObjects());
    system.close();

    if (!onlyAll) {
      let user: photoAccessHelper.FetchResult<photoAccessHelper.Album> = await phAccessHelper.getAlbums(photoAccessHelper.AlbumType.USER, photoAccessHelper.AlbumSubtype.ANY, fetchOptions);
      allObjects.push(...await user.getAllObjects());
      user.close();
    }

    // if (!(requestType.containsImage() && requestType.containsVideo())) {
    //   if (requestType.containsImage()) {
    //
    //   }
    //   else if (requestType.containsVideo()) {
    //
    //   }
    // }
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
      ['albumTypeOhos', album.albumType],
      ['albumSubtypeOhos', album.albumSubtype],
      // ['albumTypeNameOhos', EnumUtils.getName(photoAccessHelper.AlbumType, album.albumType)],
      // ['albumSubtypeNameOhos', EnumUtils.getName(photoAccessHelper.AlbumSubtype, album.albumSubtype)],
      ['isAll', album.albumType == photoAccessHelper.AlbumType.SYSTEM],
    ]);
  }
}