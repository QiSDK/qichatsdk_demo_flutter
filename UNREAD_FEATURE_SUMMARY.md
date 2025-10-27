# 未读消息功能实现总结

## 实现概述

已成功实现全局未读消息管理功能，用户不管在哪个页面都能实时接收和显示未读消息数。

## 实现的功能

### 1. 全局消息监听
- 创建了 `GlobalChatManager` 单例，在应用启动时初始化
- 替代了原有的 ChatPage 中的局部消息监听
- 所有页面都能接收到消息通知

### 2. 未读数管理
- 创建了 `UnreadManager` 单例，在内存中维护未读消息数
- 只有不在聊天页面收到的消息才会计入未读数
- 自动回复消息（MST_SYSTEM_AUTO_TRANSFER）不计入未读数

### 3. 实时UI更新
- 客服咨询列表页面（EntrancePage）实时显示未读数
- 使用 Stream 机制，当未读数变化时自动刷新UI
- 红点提示显示当前有未读消息

### 4. 自动清零
- 进入聊天页面时自动清零对应会话的未读数
- 离开聊天页面时取消当前会话标记

## 新增文件

### 1. lib/model/unread_item.dart
未读消息数据模型，包含：
- `consultId`: 会话ID
- `unreadCount`: 未读消息数量
- 提供 `increment()` 和 `clear()` 方法

### 2. lib/manager/unread_manager.dart
未读消息管理器（单例），提供：
- `incrementUnread(consultId)`: 增加未读数
- `clearUnread(consultId)`: 清零未读数
- `getUnread(consultId)`: 获取未读数
- `getAllUnread()`: 获取所有未读数
- `unreadStream`: 未读数变化的 Stream

### 3. lib/manager/global_chat_manager.dart
全局聊天管理器（单例），提供：
- 实现 `TeneasySDKDelegate` 接口
- **SDK 初始化和连接管理**（参考 Android 版本）
- **自动连接监控**（每6秒检查一次连接状态）
- 全局消息监听和分发
- 判断用户是否在聊天页面
- 自动管理未读消息数

## 修改的文件

### 1. lib/main.dart
- 导入 `GlobalChatManager`
- 在 `main()` 函数中初始化全局聊天管理器
- 在 `didChangeAppLifecycleState()` 中处理应用生命周期：
  - `AppLifecycleState.resumed`: 应用恢复时确保连接
  - `AppLifecycleState.paused`: 应用进入后台
  - `AppLifecycleState.detached`: 应用退出时调用 `GlobalChatManager.instance.stop()` 断开连接

### 2. lib/vc/ChatPage.dart
- 导入 `GlobalChatManager` 和 `UnreadManager`
- **删除 `initSDK()` 方法**：SDK 初始化已移至 GlobalChatManager
- `initState()`:
  - 设置当前聊天页面ID
  - 清零未读数
  - 通过 `GlobalChatManager` 添加消息监听器
- 添加 `_onReceivedMsg`、`_onSystemMsg`、`_onConnected`、`_onWorkChanged`、`_onMsgReceipt`、`_onMsgDeleted` 等回调方法
- `checkSDKStatus()`: 改为调用 `GlobalChatManager.instance.connectIfNeeded()`
- `dispose()`: 清空当前聊天页面ID，移除所有监听器

### 3. lib/vc/entrancePage.dart
- 导入 `UnreadManager`
- 添加 `StreamSubscription` 监听未读数变化
- `initState()`: 订阅未读数变化的 Stream
- `_initCell()`: 从 UnreadManager 获取实时未读数，显示红色徽章和具体数字（超过99显示"99+"）
- `dispose()`: 取消订阅

## 工作流程

### 应用启动流程（参考 Android 版本）
```
1. main() 函数启动
   ↓
2. 加载 SharedPreferences 配置
   ↓
3. GlobalChatManager.instance.initialize()
   ├─ 设置 ChatLib 的 delegate 为 GlobalChatManager
   └─ 启动连接监控（每6秒检查一次）
        ↓
      connectIfNeeded()
        ├─ 检查是否已连接
        ├─ 检查 domain 是否已设置
        └─ 初始化 SDK 并建立 WebSocket 连接
```

### 消息接收流程
```
1. ChatLib 收到新消息
   ↓
2. GlobalChatManager.receivedMsg() 被调用
   ↓
3. 判断：用户是否在当前会话的聊天页面？
   ├─ 是 → 不计入未读数
   └─ 否 → 检查是否为自动回复消息
            ├─ 是 → 不计入未读数
            └─ 否 → UnreadManager.incrementUnread()
                    ↓
                  通过 Stream 通知所有监听者
                    ↓
                  EntrancePage 自动刷新UI显示未读数
                    ↓
                  ChatPage 通过监听器接收消息并更新UI
```

### 未读数清零流程
```
1. 用户点击进入聊天页面
   ↓
2. ChatPage.initState() 被调用
   ↓
3. GlobalChatManager.setCurrentChatConsultId(consultId)
   ↓
4. UnreadManager.clearUnread(consultId)
   ↓
5. 通过 Stream 通知所有监听者
   ↓
6. EntrancePage 自动刷新UI，未读数清零
```

### 离开聊天页面流程
```
1. 用户返回到列表页面
   ↓
2. ChatPage.dispose() 被调用
   ↓
3. GlobalChatManager.setCurrentChatConsultId(null)
   ↓
4. 移除所有消息监听器
   ↓
5. 后续收到的消息会正常计入未读数
```

### 连接管理流程（新增）
```
1. GlobalChatManager 启动连接监控
   ↓
2. 每6秒执行一次 connectIfNeeded()
   ↓
3. 检查连接状态
   ├─ 已连接 → 跳过
   └─ 未连接 → 尝试连接
        ├─ payloadId == 0 → 初始化 SDK 并连接
        └─ payloadId != 0 → 重新连接
```

### 应用生命周期管理流程（新增）
```
应用状态变化
   ↓
didChangeAppLifecycleState() 被调用
   ↓
判断应用状态
   ├─ resumed（恢复） → GlobalChatManager.connectIfNeeded()
   ├─ paused（后台） → 保持连接
   └─ detached（退出） → GlobalChatManager.stop()
                           ├─ 停止连接监控
                           ├─ 断开 WebSocket 连接
                           └─ 清空未读数
```

## 使用说明

### 获取未读数
```dart
// 获取指定会话的未读数
int unread = UnreadManager.instance.getUnread(consultId);

// 获取所有未读数
Map<int, int> allUnread = UnreadManager.instance.getAllUnread();

// 获取总未读数
int totalUnread = UnreadManager.instance.getTotalUnread();
```

### 监听未读数变化
```dart
StreamSubscription? subscription;

subscription = UnreadManager.instance.unreadStream.listen((unreadMap) {
  // unreadMap: Map<int, int> - consultId -> unreadCount
  // 在这里更新UI
  setState(() {});
});

// 记得在dispose时取消订阅
subscription?.cancel();
```

### 手动操作未读数
```dart
// 增加未读数
UnreadManager.instance.incrementUnread(consultId);

// 清零未读数
UnreadManager.instance.clearUnread(consultId);

// 清空所有未读数
UnreadManager.instance.clearAll();
```

## 注意事项

1. **单例模式**: `GlobalChatManager` 和 `UnreadManager` 都是单例，全局只有一个实例
2. **SDK 初始化**: SDK 初始化和连接管理已完全由 `GlobalChatManager` 负责，**不要**在其他地方调用 `chatLib.initialize()` 或 `chatLib.callWebSocket()`
3. **自动连接**: GlobalChatManager 会每6秒自动检查并维护连接状态
4. **内存管理**: 未读数只在内存中维护，应用重启后会清零
5. **自动回复**: 自动回复消息（`MST_SYSTEM_AUTO_TRANSFER`）不计入未读数
6. **Stream 订阅**: 记得在页面 dispose 时取消订阅，避免内存泄漏
7. **监听器管理**: ChatPage 需要在 initState 中添加监听器，在 dispose 中移除监听器
8. **线程安全**: 由于 Flutter 是单线程模型，不需要考虑线程安全问题

## 测试建议

1. **基本功能测试**:
   - 在列表页面时收到消息，检查未读数是否正确显示
   - 进入聊天页面，检查未读数是否清零
   - 在聊天页面收到消息，检查是否不计入未读数

2. **边界情况测试**:
   - 多个会话同时收到消息
   - 快速进出聊天页面
   - 收到自动回复消息

3. **UI 测试**:
   - 列表页面的红点提示是否正确显示
   - 未读数变化时UI是否实时更新

## 后续优化建议

1. **持久化**: 如果需要，可以将未读数持久化到本地数据库或 SharedPreferences
2. **角标显示**: 可以在应用图标上显示总未读数角标（需要原生代码支持）
3. **推送通知**: 集成推送通知，在应用后台时也能收到消息提醒
4. **性能优化**: 如果会话数量很多，考虑使用分页加载和虚拟列表

## 完成时间

2025-10-27
