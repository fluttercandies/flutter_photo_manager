import {
  FlutterPlugin,
  FlutterPluginBinding
} from '@ohos/flutter_ohos/src/main/ets/embedding/engine/plugins/FlutterPlugin';
import MethodChannel, {
  MethodCallHandler,
  MethodResult
} from '@ohos/flutter_ohos/src/main/ets/plugin/common/MethodChannel';
import MethodCall from '@ohos/flutter_ohos/src/main/ets/plugin/common/MethodCall';
import common from '@ohos.app.ability.common';
import { AbilityAware, AbilityPluginBinding } from '@ohos/flutter_ohos';

import PhotoManagerNotifyPlugin from './PhotoManagerNotifyPlugin';
import { SaveHandler } from './handlers/SaveHandler';
import { AlbumHandler } from './handlers/AlbumHandler';
import { PhotoAssetHandler } from './handlers/PhotoAssetHandler';
import { HandlerBase } from './handlers/HandlerBase';
import { PermissionHandler } from './handlers/PermissionHandler';


/** FlutterPhotoManagerPlugin **/
export default class PhotoManagerPlugin extends HandlerBase implements FlutterPlugin, MethodCallHandler, AbilityAware {
  private channel: MethodChannel | null = null;
  private static _context: Context | null = null;
  private static _uiContext: common.UIAbilityContext | null = null;

  static get uiContext(): common.UIAbilityContext | null {
    return PhotoManagerPlugin._uiContext;
  }

  static get context(): common.Context | null {
    return PhotoManagerPlugin._context;
  }

  get uiContext(): common.UIAbilityContext | null {
    return PhotoManagerPlugin._uiContext;
  }

  private static _showLog: boolean = true;

  static get showLog(): boolean {
    return PhotoManagerPlugin._showLog;
  }

  private notifyPlugin: PhotoManagerNotifyPlugin = new PhotoManagerNotifyPlugin();
  private saveHandler: SaveHandler = new SaveHandler();
  private albumHandler: AlbumHandler = new AlbumHandler();
  private photoAssetHandler: PhotoAssetHandler = new PhotoAssetHandler();
  private permissionHandler: PermissionHandler = new PermissionHandler();

  // private albums: Map<string, photoAccessHelper.AbsAlbum> = new Map<string, photoAccessHelper.AbsAlbum>();
  // private photoAssets: Map<string, photoAccessHelper.PhotoAsset> = new Map<string, photoAccessHelper.PhotoAsset>();

  constructor() {
    super();
  }


  onAttachedToAbility(binding: AbilityPluginBinding): void {
    PhotoManagerPlugin._uiContext = binding.getAbility().context;
    this.notifyPlugin.onAttachedToAbility(binding);
  }

  onDetachedFromAbility(): void {

  }

  getUniqueClassName(): string {
    return "FlutterPhotoManagerPlugin"
  }

  onAttachedToEngine(binding: FlutterPluginBinding): void {
    this.channel = new MethodChannel(binding.getBinaryMessenger(), "com.fluttercandies/photo_manager");
    this.channel.setMethodCallHandler(this)
    PhotoManagerPlugin._context = binding.getApplicationContext();
    this.notifyPlugin.onAttachedToEngine(binding);
  }

  onDetachedFromEngine(binding: FlutterPluginBinding): void {
    if (this.channel != null) {
      this.channel.setMethodCallHandler(null)
    }
    this.notifyPlugin.onDetachedFromEngine(binding);
  }

  async onMethodCall(call: MethodCall, result: MethodResult): Promise<void> {
    switch (call.method) {
      case 'log':
        PhotoManagerPlugin._showLog = call.args;
        break;
      case 'cancelCacheRequests':
        result.success(null);
        break;
      default:
        let handled = await this.tryAgain(call, result, async () => {
          return await this.permissionHandler.onMethodCall(call, result)
            || await this.albumHandler.onMethodCall(call, result)
            || await this.photoAssetHandler.onMethodCall(call, result)
            || await this.saveHandler.onMethodCall(call, result)
            || await this.notifyPlugin.onMethodCall(call, result)
          ;
        });

        if (!handled) {
          result.notImplemented()
        }
        break;
    }
  }
}


