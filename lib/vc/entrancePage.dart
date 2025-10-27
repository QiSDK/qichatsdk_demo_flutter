
import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:qichatsdk_demo_flutter/model/Entrance.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:qichatsdk_demo_flutter/vc/ChatPage.dart';
import '../Constant.dart';
import '../article_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fixnum/src/int64.dart';
import '../manager/unread_manager.dart';

class EntrancePage extends StatefulWidget {
  const EntrancePage({super.key});

  @override
  State<EntrancePage> createState() => _EntrancePageState();
}

class _EntrancePageState extends State<EntrancePage> {
  //final AppPurchaseV2 _appPurchase = AppPurchaseV2.instance;

  // 未读消息变化的订阅
  StreamSubscription<Map<int, int>>? _unreadSubscription;

  @override
  void initState() {
    super.initState();
    //WidgetsBinding.instance.addObserver(this);
    loadData();

    // 监听未读数变化
    _unreadSubscription = UnreadManager.instance.unreadStream.listen((unreadMap) {
      // 当未读数发生变化时，刷新UI
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: const Color(0xFFf8f8f8),
        appBar: AppBar(
          title: const Text(
            '客服',
            style: TextStyle(fontSize: 18),
          ),
        ),
        body: _initBody());
  }

  _initBody() {
    return entrance?.consults == null
        ? Container()
        : Column(
      children: [
        Expanded(
            child: ListView.builder(
                itemCount: entrance!.consults!.length,
                itemBuilder: (ctx, index) {
                  Consults model = entrance!.consults![index];
                  return GestureDetector(
                      onTap: () {
                        print("Tapped on: ${model.name}");
                        _navigateToChatPage(model);
                      },

                  child: _initCell(model),
                  );
                }
            )),
        SizedBox(
          height: MediaQuery.of(context).padding.bottom + 15,
        )
      ],
    );
  }

  _initCell(Consults model) {
    // Assuming `works` is a list of URLs or paths to image assets
    var thumbnail = model.works != null && model.works!.isNotEmpty
        ? baseUrlImage + model.works![0].avatar!
        : "default_thumbnail_url"; // Provide a default or fallback URL if `works` is null or empty
    print(thumbnail);

    // 从UnreadManager获取实时未读数，如果没有则使用model中的默认未读数
    var unread = UnreadManager.instance.getUnread(model.consultId ?? 0);
    if (unread == 0) {
      unread = model.unread ?? 0;
    }

    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
          color: const Color.fromRGBO(255, 255, 255, 1),
          borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
              Row(
                children: [
                  CachedNetworkImage(
                    imageUrl: thumbnail,
                    width: 30,
                    height: 30,
                    progressIndicatorBuilder: (context, url, downloadProgress) => Center(
                      child: SizedBox(
                        width: 30,
                        height: 30,
                        child: CircularProgressIndicator(
                          value: downloadProgress.progress,
                          color: Colors.blue,
                        ),
                      ),
                    ),
                    errorWidget: (context, url, error) =>
                        Image.asset(""),
                  ),
                  const SizedBox(
                    width: 12,
                  ),
                  Text('${model.name}',
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  if (unread > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 20,
                        minHeight: 20,
                      ),
                      child: Text(
                        unread > 99 ? '99+' : '$unread',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    )
                ],
              )
            ],
      ),
    );
  }

   Future<void> _navigateToChatPage(Consults model) async {
     await Navigator.push(
       context,
       MaterialPageRoute( builder: (context) => ChatPage(consultId: Int64(model.consultId ?? 0))));

     // Call loadData when returning from Page B
     loadData();
   }

  loadData() async {
    print("调用queryEntrance ${DateTime.now()}");
    SharedPreferences prefs = await SharedPreferences.getInstance();
    xToken = await prefs.getString(PARAM_XTOKEN) ?? cert;
    // 获取线路之后，获取咨询类型列表
    /* 获取咨询列表有3个接口：
                    1. 普通咨询列表 + 隐藏咨询列表, 使用接口：v1/api/query-entrance-hidden
                    2. 普通咨询列表, 使用接口：v1/api/query-entrance
                    3. 获取特定咨询列表, 使用接口：v1/api/query-consult-user
                   */
    entrance = await ArticleRepository.queryEntrance();
    if (entrance != null && mounted)
      setState(() {});
  }

   @override
   void dispose() {
     // 取消未读数变化的订阅
     _unreadSubscription?.cancel();
     super.dispose();
   }
}
