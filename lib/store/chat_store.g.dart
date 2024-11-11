// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_store.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$ChatStore on _ChatStore, Store {
  late final _$loadingMsgAtom =
      Atom(name: '_ChatStore.loadingMsg', context: context);

  @override
  String get loadingMsg {
    _$loadingMsgAtom.reportRead();
    return super.loadingMsg;
  }

  @override
  set loadingMsg(String value) {
    _$loadingMsgAtom.reportWrite(value, super.loadingMsg, () {
      super.loadingMsg = value;
    });
  }

  @override
  String toString() {
    return '''
loadingMsg: ${loadingMsg}
    ''';
  }
}
