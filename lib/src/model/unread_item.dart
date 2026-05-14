/// 未读消息数据模型
class UnreadItem {
  /// 会话ID
  final int consultId;

  /// 未读消息数量
  int unreadCount;

  UnreadItem({
    required this.consultId,
    this.unreadCount = 0,
  });

  /// 增加未读数
  void increment() {
    unreadCount++;
  }

  /// 清零未读数
  void clear() {
    unreadCount = 0;
  }

  /// 转换为Map
  Map<String, dynamic> toMap() {
    return {
      'consultId': consultId,
      'unreadCount': unreadCount,
    };
  }

  /// 从Map创建
  factory UnreadItem.fromMap(Map<String, dynamic> map) {
    return UnreadItem(
      consultId: map['consultId'] as int,
      unreadCount: map['unreadCount'] as int? ?? 0,
    );
  }

  @override
  String toString() {
    return 'UnreadItem(consultId: $consultId, unreadCount: $unreadCount)';
  }
}
