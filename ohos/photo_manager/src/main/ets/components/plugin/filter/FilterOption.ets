import { MapUtils } from '../utils/MapUtils';

// let map = {
//   "type": 1,
//   "child": {
//     "where": "width >= 1000",
//     "orderBy": [{ "column": "width", "isAsc": false }],
//     "needTitle": false,
//     "containsPathModified": false
//   }
// };

// let map = {
//   "type": 1,
//   "child": {
//     "where": "( (  ) AND (  ) )",
//     "orderBy": [{ "column": "date_added", "isAsc": false }],
//     "needTitle": false,
//     "containsPathModified": false
//   }
// }

// let map = {
//   "type": 0,
//   "child": {
//     "image": {
//       "title": false,
//       "size": {
//         "minWidth": 0,
//         "maxWidth": 100000,
//         "minHeight": 0,
//         "maxHeight": 100000,
//         "ignoreSize": true
//       },
//       "duration": { "min": 0, "max": 86400000, "allowNullable": false }
//     },
//     "video": {
//       "title": false,
//       "size": {
//         "minWidth": 0,
//         "maxWidth": 100000,
//         "minHeight": 0,
//         "maxHeight": 100000,
//         "ignoreSize": false
//       },
//       "duration": { "min": 0, "max": 86400000, "allowNullable": false }
//     },
//     "audio": {
//       "title": false,
//       "size": {
//         "minWidth": 0,
//         "maxWidth": 100000,
//         "minHeight": 0,
//         "maxHeight": 100000,
//         "ignoreSize": false
//       },
//       "duration": { "min": 0, "max": 86400000, "allowNullable": false }
//     },
//     "createDate": { "min": 0, "max": 1711090613183, "ignore": false },
//     "updateDate": { "min": 0, "max": 1711090613183, "ignore": true },
//     "orders": [],
//     "containsLivePhotos": true,
//     "onlyLivePhotos": false,
//     "containsPathModified": false
//   }
// };

export class AssetSize {
  minWidth: number;
  maxWidth: number;
  minHeight: number;
  maxHeight: number;
  ignoreSize: boolean;

  constructor(size: Map<string, ESObject>) {
    this.minWidth = MapUtils.get(size, 'minWidth', 0);
    this.maxWidth = MapUtils.get(size, 'maxWidth', 100000);
    this.minHeight = MapUtils.get(size, 'minHeight', 0);
    this.maxHeight = MapUtils.get(size, 'maxHeight', 100000);
    this.ignoreSize = MapUtils.get(size, 'ignoreSize', true);
  }
}

export class Duration {
  min: number;
  max: number;
  allowNullable: boolean;

  constructor(duration: Map<string, ESObject>) {
    this.min = MapUtils.get(duration, 'min', 0);
    this.max = MapUtils.get(duration, 'max', 86400000);
    this.allowNullable = MapUtils.get(duration, 'allowNullable', false);
  }
}

export class MediaType {
  title: boolean;
  size: AssetSize;
  duration: Duration;

  constructor(mediaType: Map<string, ESObject>) {
    this.title = MapUtils.get(mediaType, 'title', false);
    this.size = new AssetSize(MapUtils.get(mediaType, 'size', new Map<string, ESObject>()));
    this.duration = new Duration(MapUtils.get(mediaType, 'duration', new Map<string, ESObject>()));
  }
}

export class DateRange {
  min: number;
  max: number;
  ignore: boolean;

  constructor(dateRange: Map<string, ESObject>) {
    this.min = MapUtils.get(dateRange, 'min', 0);
    this.max = MapUtils.get(dateRange, 'max', 0);
    this.ignore = MapUtils.get(dateRange, 'ignore', false);
  }
}

export class OrderByItem {
  column: string;
  isAsc: boolean;

  constructor(order: Map<string, ESObject>) {
    this.column = MapUtils.get(order, 'column', '');
    this.isAsc = MapUtils.get(order, 'isAsc', false);
  }
}

export class OrderOption {
  //   enum OrderOptionType {
  //   /// Sorts assets by their creation date.
  //   createDate,
  //
  //   /// Sorts assets by their modification date.
  //   updateDate,
  // }
  type: number;
  asc: boolean;

  constructor(order: Map<string, ESObject>) {
    this.type = MapUtils.get(order, 'type', 0);
    this.asc = MapUtils.get(order, 'asc', false);
  }
}

export class FilterOptionChild {
  where: string;
  orderBy: OrderByItem[];
  image: MediaType;
  video: MediaType;
  audio: MediaType;
  createDate: DateRange;
  updateDate: DateRange;
  orders: OrderOption[];
  needTitle: boolean;
  containsLivePhotos: boolean;
  onlyLivePhotos: boolean;
  containsPathModified: boolean;

  constructor(child: Map<string, ESObject>) {
    this.where = MapUtils.get(child, 'where', '');
    this.orderBy = (MapUtils.get(child, 'orderBy', []) as Map<string, ESObject>[]).map((item: ESObject) => new OrderByItem(item));
    this.image = new MediaType(MapUtils.get(child, 'image', new Map<string, ESObject>()));
    this.video = new MediaType(MapUtils.get(child, 'video', new Map<string, ESObject>()));
    this.audio = new MediaType(MapUtils.get(child, 'audio', new Map<string, ESObject>()));
    this.createDate = new DateRange(MapUtils.get(child, 'createDate', new Map<string, ESObject>()));
    this.updateDate = new DateRange(MapUtils.get(child, 'updateDate', new Map<string, ESObject>()));
    this.orders = (MapUtils.get(child, 'orders', []) as Map<string, ESObject>[]).map((item: ESObject) => new OrderOption(item));
    this.needTitle = MapUtils.get(child, 'needTitle', false);
    this.containsLivePhotos = MapUtils.get(child, 'containsLivePhotos', false);
    this.onlyLivePhotos = MapUtils.get(child, 'onlyLivePhotos', false);
    this.containsPathModified = MapUtils.get(child, 'containsPathModified', false);
  }
}

export class FilterOption {
  type: number;
  child: FilterOptionChild;

  constructor(map: Map<string, ESObject>) {
    this.type = MapUtils.get(map, 'type', 0);
    this.child = new FilterOptionChild(MapUtils.get(map, 'child', new Map<string, ESObject>()));
  }
}
