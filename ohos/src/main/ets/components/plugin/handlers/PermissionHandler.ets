import { MethodCall } from '@ohos/flutter_ohos';
import { MethodResult } from '@ohos/flutter_ohos/src/main/ets/plugin/common/MethodChannel';
import PhotoManagerPlugin from '../PhotoManagerPlugin';
import { HandlerBase, MethodCallHandlerBase } from './HandlerBase';
import { Permissions, abilityAccessCtrl, Want, PermissionRequestResult } from '@kit.AbilityKit';

export class PermissionHandler extends HandlerBase implements MethodCallHandlerBase {
  private static ignoreCheck: boolean = false;

  async onMethodCall(call: MethodCall, result: MethodResult): Promise<boolean> {
    if (this.context == null || this.uiContext == null) {
      result.error('100', 'context and uiContext are null', 'They should not be null');
      return true;
    }
    switch (call.method) {
      case 'openSetting': {
        let applicationInfo = this.context!.applicationInfo;
        let wantInfo: Want = {
          bundleName: 'com.huawei.hmos.settings',
          abilityName: 'com.huawei.hmos.settings.MainAbility',
          uri: 'application_info_entry',
          parameters: {
            pushParams: applicationInfo.name
          }
        }
        await this.uiContext!.startAbility(wantInfo);
        result.success(true);
      }
        break;
      case 'requestPermissionExtend': {
        let args: Map<string, ESObject> = call.args;
        let ohosPermissions: Array<Permissions> = args.get('ohosPermissions');

        if (Array.isArray(ohosPermissions)) {
          let granted = await PermissionHandler.permissionCheck(ohosPermissions);
          if (granted) {
            result.success(3);
          }
          else {
            result.success(2);
          }
        } else {
          result.error('102', 'permissions is not List<String>', 'make sure you pass the right permissions');
        }
      }
        break;
      case 'ignorePermissionCheck': {
        let args: Map<string, ESObject> = call.args;
        PermissionHandler.ignoreCheck = args.get('ignore');
        result.success(null);
      }
        break;
      default:
        return false;
    }

    return true;
  }

  static async permissionReadCheck(): Promise<boolean> {
    return PermissionHandler.permissionCheck(['ohos.permission.READ_IMAGEVIDEO']);
  }

  static async permissionWriteCheck(): Promise<boolean> {
    return PermissionHandler.permissionCheck(['ohos.permission.WRITE_IMAGEVIDEO']);
  }

  static async permissionCheck(permissions: Array<Permissions> = ['ohos.permission.READ_IMAGEVIDEO', 'ohos.permission.WRITE_IMAGEVIDEO']): Promise<boolean> {
    if (permissions.length == 0 || PermissionHandler.ignoreCheck) {
      // result.error('101', 'permissions is empty', 'make sure you pass the permissions');
      return true;
    }

    let atManager = abilityAccessCtrl.createAtManager();
    /// dart
    /// The user has not set the app’s authorization status.
    /// notDetermined,

    /// The app isn’t authorized to access the photo library, and the user can’t grant such permission.
    /// restricted,

    /// The user explicitly denied this app access to the photo library.
    /// denied,

    /// The user explicitly granted this app access to the photo library.
    /// authorized,

    /// The user authorized this app for limited photo library access.
    ///
    /// This state only supports iOS 14 and above.
    /// limited,

    /// ohos
    /// The user denied access to the requested feature, permission needs to be
    /// asked first.
    /// denied(-1),

    /// The user granted access to the requested feature.
    /// granted(0),

    /// Invalid request.
    /// invalid(2)
    let data: PermissionRequestResult = await atManager.requestPermissionsFromUser(PhotoManagerPlugin.uiContext!, permissions,);
    let grantStatus: Array<number> = data.authResults;
    let length: number = grantStatus.length;
    for (let i = 0; i < length; i++) {
      if (grantStatus[i] != 0) {
        return false;
      }
    }
    return true;
  }
}