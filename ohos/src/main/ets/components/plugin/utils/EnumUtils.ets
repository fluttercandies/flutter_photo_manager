export class EnumUtils {
  static getName(enumType: ESObject, value: ESObject,): string {
    let keys = Object.keys(enumType)
      .filter(x => (enumType[x] === value));
    let typeName: string = keys.length > 0 ? keys[0] : '';
    return typeName;
  }
}