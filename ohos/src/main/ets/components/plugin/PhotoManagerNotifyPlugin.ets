import { AbilityAware, AbilityPluginBinding, FlutterPlugin, MethodCall } from '@ohos/flutter_ohos';
import { FlutterPluginBinding } from '@ohos/flutter_ohos/src/main/ets/embedding/engine/plugins/FlutterPlugin';
import MethodChannel, { MethodResult } from '@ohos/flutter_ohos/src/main/ets/plugin/common/MethodChannel';
import { common } from '@kit.AbilityKit';
import { photoAccessHelper } from '@kit.MediaLibraryKit';
import { EnumUtils } from './utils/EnumUtils';
import { HashMap } from '@kit.ArkTS';
import { MethodCallHandlerBase } from './handlers/HandlerBase';
import PhotoManagerPlugin from './PhotoManagerPlugin';

export default class PhotoManagerNotifyPlugin implements FlutterPlugin, MethodCallHandlerBase, AbilityAware {
  private static channel: MethodChannel | null = null;
  // private context: Context | null = null;
  private uiContext: common.UIAbilityContext | null = null;

  getUniqueClassName(): string {
    return 'PhotoManagerNotifyPlugin';
  }

  onAttachedToEngine(binding: FlutterPluginBinding): void {
    PhotoManagerNotifyPlugin.channel = new MethodChannel(binding.getBinaryMessenger(), "com.fluttercandies/photo_manager/notify");
    PhotoManagerNotifyPlugin.channel.setMethodCallHandler(this)
    // this.context = binding.getApplicationContext();
  }

  onDetachedFromEngine(binding: FlutterPluginBinding): void {
    if (PhotoManagerNotifyPlugin.channel != null) {
      PhotoManagerNotifyPlugin.channel.setMethodCallHandler(null)
    }
  }

  onAttachedToAbility(binding: AbilityPluginBinding): void {
    this.uiContext = binding.getAbility().context;
  }

  onDetachedFromAbility(): void {

  }

  async onMethodCall(call: MethodCall, result: MethodResult): Promise<boolean> {
    switch (call.method) {
      case 'notify': {
        let args: Map<string, ESObject> = call.args;
        let notify: boolean = args.get('notify');
        result.success(this.notify(notify));
      }
        break;
      default:
        return false;
    }
    return true;
  }

  notify(start: boolean): boolean {
    let phAccessHelper = photoAccessHelper.getPhotoAccessHelper(this.uiContext);
    try {
      if (start) {
        phAccessHelper.registerChange(photoAccessHelper.DefaultChangeUri.DEFAULT_PHOTO_URI, true, this._onCallback);
      }
      else {
        phAccessHelper.unRegisterChange(photoAccessHelper.DefaultChangeUri.DEFAULT_PHOTO_URI, this._onCallback);
      }
      return true;
    }
    catch (e) {
    }
    return false;
  }

  _onCallback(changeData: photoAccessHelper.ChangeData) {
    if (PhotoManagerPlugin.showLog) {
      console.info('onCallback successfully, changData: ' + JSON.stringify(changeData));
    }

    let map: HashMap<string, ESObject> = new  HashMap<string, ESObject>();
    if (changeData.type != undefined) {
      // let keys = Object.keys(photoAccessHelper.NotifyType)
      //   .filter(x => (photoAccessHelper.NotifyType[x] === changeData.type));
      let typeName: string = EnumUtils.getName(photoAccessHelper.NotifyType, changeData.type);
      map.set('type', changeData.type);
      map.set('typeName', typeName.toLowerCase());
    }
    if (changeData.uris != undefined) {
      map.set('uris', changeData.uris);
    }
    if (changeData.extraUris != undefined) {
      map.set('extraUris', changeData.extraUris);
    }
    PhotoManagerNotifyPlugin.channel?.invokeMethod('change', map);
  }
}