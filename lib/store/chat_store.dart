import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:easy_refresh/easy_refresh.dart';
import 'package:mobx/mobx.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:qichatsdk_flutter/src/dartOut/api/common/c_message.pb.dart'
as cMessage;
import 'package:qichatsdk_flutter/src/dartOut/gateway/g_gateway.pb.dart';
part 'chat_store.g.dart';

class ChatStore = _ChatStore with _$ChatStore;

abstract class _ChatStore with Store {
  _ChatStore() {}

  EasyRefreshController controller = EasyRefreshController(
    controlFinishRefresh: true,
    controlFinishLoad: true,
  );

  int pageNum = 0;
  int total = 0;

  @observable
  ObservableList<types.Message> _messages = ObservableList<types.Message>();
  loadList(List<String> cateList, {bool isFooter = false}) async {
    String cate = cateList.length == 1
        ? cateList.first
        : '${cateList[0]},${cateList[1]},${cateList[2]}';

    if (isFooter) {
      pageNum++;
    } else {
      pageNum = 0;
    }
    try {
      // var res = await HomeRepository.getMyPlaylist(cate, pageNum);
      // if (res['data'] is List) {
      //   var result = res['data'] as List;
      //   var list = result
      //       .mapIndexed<AllWork>((element, index) => AllWork.fromJson(element))
      //       .toList();
      //   if (isFooter) {
      //     dataList.addAll(list);
      //     controller.finishLoad();
      //     if (list.isEmpty) {
      //       SmartDialog.showToast('已全部加载完成');
      //     }
      //   } else {
      //     dataList = ObservableList.of(list);
      //     controller.finishRefresh();
      //   }
      // }
    } catch (e) {
      print(e);
      if (isFooter) {
        controller.finishLoad();
      } else {
        controller.finishRefresh();
      }
    }
  }
}
