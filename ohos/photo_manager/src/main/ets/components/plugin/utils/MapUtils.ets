

export class MapUtils {
  static get<T>(map: Map<string, ESObject>, key: string, defaultValue: T): T {
    return map.has(key) ? map.get(key) as T : defaultValue;
  }
}