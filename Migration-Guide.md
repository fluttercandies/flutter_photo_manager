# Migration Guide

The document only describes the equivalent changes to the API.
If you want to see the new feature support, please refer to [readme][] and [change log][].

- [Migration Guide](#migration-guide)
  - [0.5.x To 0.6.x](#05x-to-06x)

## 0.5.x To 0.6.x

0.5.x:

```dart
final dtCond = DateTimeCond(
    min: startDt,
    max: endDt,
    asc: asc,
);

FilterOptionGroup().dateTimeCond = dtCond;
```

0.6.x

```dart
final dtCond = DateTimeCond(
    min: startDt,
    max: endDt,
);

final orderOption = OrderOption(
  type: OrderOptionType.createDate,
  asc: asc,
);

final filterOptionGroup = FilterOptionGroup()
..addOrderOption(orderOption);
```

[readme]: ./README.md
[change log]: ./CHANGELOG.md
