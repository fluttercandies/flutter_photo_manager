import { common } from '@kit.AbilityKit';
import { MethodCall } from '@ohos/flutter_ohos';
import { MethodResult } from '@ohos/flutter_ohos/src/main/ets/plugin/common/MethodChannel';
import PhotoManagerPlugin from '../PhotoManagerPlugin';

export class HandlerBase {
  get uiContext(): common.UIAbilityContext | null {
    return PhotoManagerPlugin.uiContext;
  }

  get context(): common.Context | null {
    return PhotoManagerPlugin.uiContext;
  }

  get showLog(): boolean {
    return PhotoManagerPlugin.showLog;
  }

  async tryAgain(call: MethodCall, result: MethodResult, doWork: () => Promise<boolean>, numberOfRetries: number = 1): Promise<boolean> {
    if (numberOfRetries < 0) {
      return false;
    }
    try {
      return await doWork();
    }
    catch (e) {
      if (this.showLog) {
        console.error(`${call.method} failed, code is ${e.code}, message is ${e.message}`);
      }
      if (numberOfRetries - 1 > 0) {
        return this.tryAgain(call, result, doWork, numberOfRetries - 1);
      }
      else {
        result.error(`${e.code}`, call.method, `${e.message}`);
        return true;
      }
    }
  }
}


export interface MethodCallHandlerBase {
  onMethodCall(call: MethodCall, result: MethodResult): Promise<boolean>;
}