# TODO - Flutter 未读消息功能实现

## 1. 创建全局聊天管理器
- [ ] 创建 `lib/manager/global_chat_manager.dart` 文件
  - 使用单例模式（Singleton）实现全局ChatLib管理
  - 目的：让用户不管在哪个页面都能监听到消息
  - 参考：Android版的 GlobalChatManager.kt

## 2. 创建未读消息数据模型
- [ ] 创建 `lib/model/unread_item.dart` 文件
  ```dart
  class UnreadItem {
    final int consultId;
    int unreadCount;

    UnreadItem({
      required this.consultId,
      this.unreadCount = 0,
    });
  }
  ```

## 3. 创建未读消息管理类
- [ ] 创建 `lib/manager/unread_manager.dart` 文件
  - 使用 Map<int, int> 存储未读数：`consultId -> unreadCount`
  - 只在内存中维护，不需要持久化
  - 提供方法：
    - `incrementUnread(int consultId)` - 未读数+1
    - `clearUnread(int consultId)` - 清零指定会话的未读数
    - `getUnread(int consultId)` - 获取未读数
    - `getAllUnread()` - 获取所有未读数
  - 使用 StreamController 或 ChangeNotifier 通知UI更新

## 4. 集成消息监听
- [ ] 在 GlobalChatManager 中初始化 ChatLib
  - 参考现有代码：[ChatPage.dart:346](lib/vc/ChatPage.dart#L346)
  - 监听新消息事件
  - 判断：如果当前不在对应的聊天页面，则调用 `UnreadManager.incrementUnread()`

## 5. 更新客服咨询列表页面
- [ ] 修改 [lib/vc/entrancePage.dart](lib/vc/entrancePage.dart)
  - 监听 UnreadManager 的未读数变化
  - 当用户停留在列表页面时，实时更新列表中的未读数显示
  - 使用 StreamBuilder 或 ValueListenableBuilder 实现响应式更新

## 6. 聊天页面清零未读数
- [ ] 修改 [lib/vc/ChatPage.dart](lib/vc/ChatPage.dart)
  - 在进入聊天页面时（initState 或 onResume）调用 `UnreadManager.clearUnread(consultId)`
  - 确保用户查看消息后未读数正确清零

## 实现顺序建议
1. 先创建数据模型（UnreadItem）
2. 再创建未读消息管理器（UnreadManager）
3. 然后创建全局聊天管理器（GlobalChatManager）
4. 最后修改现有页面集成功能

## 注意事项
- 参考 Android 版本的实现逻辑，但使用 Flutter/Dart 的语法和设计模式
- 确保内存管理得当，避免内存泄漏
- 考虑使用 Provider、GetX 或 Riverpod 等状态管理方案



