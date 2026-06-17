import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:qichat_ui_sdk/src/model/ServiceKeyword.dart';
import 'package:qichat_ui_sdk/src/util/auto_card_matcher.dart';

void main() {
  final raw =
      File('assets/json/mst_card_msg_match_list.json').readAsStringSync();
  final data = jsonDecode(raw) as Map<String, dynamic>;
  final list = (data['result'].first['service_keyword'] as List)
      .cast<Map<String, dynamic>>()
      .map((e) => ServiceKeyword.fromJson(e))
      .toList();

  test('包含即命中 + content 数组保真', () {
    final hit = matchAutoCard('我要补单怎么办', list);
    expect(hit, isNotNull);
    expect(hit!.subject, '请选择补单类型');
    expect(hit.options, ['充值补单', '提现补单', '转账补单']);
    // toJson 原样还原 content 数组
    expect(jsonDecode(jsonEncode(hit.toJson()))['content'],
        ['充值补单', '提现补单', '转账补单']);
  });

  test('content 字符串型（questionType 2）模型解析', () {
    // 用合成数据验证字符串 content 的解析：options 为空、contentText 有值、toJson 保真。
    final sk = ServiceKeyword.fromJson({
      'id': 5,
      'questionType': 2,
      'subject': '提现进度查询',
      'content': '提现一般在2小时内到账，节假日可能延迟',
      'keywords': ['提现未到账'],
      'weight': 95,
    });
    expect(sk.options, isEmpty);
    expect(sk.contentText, '提现一般在2小时内到账，节假日可能延迟');
    expect(jsonDecode(jsonEncode(sk.toJson()))['content'],
        '提现一般在2小时内到账，节假日可能延迟');
  });

  test('weight 最大优先（generic 提现 weight100 屏蔽更具体的卡片）', () {
    // "提现失败" 同时含 "提现"(weight100,id4) 与 "提现失败"(weight90,id6) → 取 weight 大的
    final hit = matchAutoCard('我提现失败了', list);
    expect(hit!.weight, 100);
    expect(hit.subject, '请选择提现相关问题');
  });

  test('无命中返回 null', () {
    expect(matchAutoCard('你好今天天气不错', list), isNull);
  });
}
