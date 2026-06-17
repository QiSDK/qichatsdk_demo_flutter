import '../model/ServiceKeyword.dart';

/// 在 [list] 中查找命中 [input] 的卡片配置。
///
/// 命中规则：[input] **包含**某条目的任一 keyword 子串即命中；
/// 多条命中时取 weight 最大的那条，weight 并列取列表中靠前的一条。
/// 无命中返回 null。
ServiceKeyword? matchAutoCard(String input, List<ServiceKeyword> list) {
  if (input.isEmpty || list.isEmpty) return null;
  ServiceKeyword? best;
  for (final item in list) {
    final hit =
        item.keywords.any((k) => k.isNotEmpty && input.contains(k));
    // 严格大于才替换 → 并列时保留先出现的（靠前）那条。
    if (hit && (best == null || item.weight > best.weight)) {
      best = item;
    }
  }
  return best;
}
