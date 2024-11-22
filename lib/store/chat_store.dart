import 'package:mobx/mobx.dart';
part 'chat_store.g.dart';

class ChatStore = _ChatStore with _$ChatStore;

abstract class _ChatStore with Store {

  @observable
  var loadingMsg = "正在连接中。。。";

  @observable
  var workerAvatar = "";
}
