import 'package:fixnum/fixnum.dart' as fixnum;
import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:qichat_ui_sdk/src/article_repository.dart';
import 'package:qichat_ui_sdk/src/model/Evaluation.dart';

enum EvaluationScene {
  manual,    // 用户主动点 ★ 按钮
  triggered, // 触发消息自动弹出
}

class EvaluationDialog extends StatefulWidget {
  final EvaluationScene scene;
  final EvaluationConfig config;
  final fixnum.Int64 consultId;
  final Color tintColor;
  /// 评价状态变化时回调（1=已评价, 2=已关闭）
  final ValueChanged<int>? onStatusChanged;

  const EvaluationDialog({
    super.key,
    required this.scene,
    required this.config,
    required this.consultId,
    required this.tintColor,
    this.onStatusChanged,
  });

  /// 静态入口：展示评价弹窗
  static void show({
    required EvaluationScene scene,
    required EvaluationConfig config,
    required fixnum.Int64 consultId,
    required Color tintColor,
    ValueChanged<int>? onStatusChanged,
  }) {
    SmartDialog.show(
      tag: 'evaluation_dialog',
      clickMaskDismiss: false,
      backType: SmartBackType.ignore,
      builder: (_) => EvaluationDialog(
        scene: scene,
        config: config,
        consultId: consultId,
        tintColor: tintColor,
        onStatusChanged: onStatusChanged,
      ),
    );
  }

  static Future<void> dismiss() async {
    await SmartDialog.dismiss(tag: 'evaluation_dialog');
  }

  @override
  State<EvaluationDialog> createState() => _EvaluationDialogState();
}

class _EvaluationDialogState extends State<EvaluationDialog> {
  int _selectedScore = 0;
  final TextEditingController _remarkCtrl = TextEditingController();
  static const int _maxLength = 200;
  bool _submitting = false;

  @override
  void dispose() {
    _remarkCtrl.dispose();
    super.dispose();
  }

  Future<void> _onClose() async {
    if (widget.scene == EvaluationScene.triggered) {
      // 触发场景下关闭 = 告诉后端不再弹出
      // 这是 fire-and-forget，不等待结果
      ArticleRepository.addEvaluation(widget.consultId, 0, '', 1);
      widget.onStatusChanged?.call(2);
    }
    EvaluationDialog.dismiss();
  }

  Future<void> _onSubmit() async {
    if (_selectedScore <= 0 || _submitting) return;
    setState(() => _submitting = true);
    final success = await ArticleRepository.addEvaluation(
        widget.consultId, _selectedScore, _remarkCtrl.text, 0);
    if (!mounted) return;
    if (success) {
      // 匹配 score 找到 feedback 文案；没有就用默认「评价成功」
      final cfg = widget.config.configs
          ?.where((c) => c.score == _selectedScore)
          .firstOrNull;
      final feedback = (cfg?.status == 1) ? (cfg?.feedback ?? '') : '';
      final toastText = feedback.isNotEmpty ? feedback : '评价成功';
      //final feedback = (cfg?.feedback ?? '').isEmpty ?  '评价成功' : cfg!.feedback!;
      widget.onStatusChanged?.call(1);
      await EvaluationDialog.dismiss();
      SmartDialog.showToast(toastText);
    } else {
      // 失败时 toast 已由 repository 弹出
      setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const disabledColor = Color(0xFFD2D2D2);
    const starUnselected = Color(0xFFC7C7C7);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => FocusScope.of(context).unfocus(),
      child: Material(
      color: Colors.black.withOpacity(0.5),
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          padding: const EdgeInsets.fromLTRB(20, 16, 12, 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      '客服满意度评价',
                      style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A1A1A)),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Color(0xFF808080)),
                    onPressed: _submitting ? null : _onClose,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(5, (i) {
                    final score = i + 1;
                    final filled = score <= _selectedScore;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedScore = score),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 4),
                        child: Icon(
                          Icons.star,
                          size: 36,
                          color: filled ? widget.tintColor : starUnselected,
                        ),
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F7F7),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFD9D9D9), width: 0.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    TextField(
                      controller: _remarkCtrl,
                      maxLength: _maxLength,
                      maxLines: 4,
                      minLines: 4,
                      style: const TextStyle(
                          fontSize: 14, color: Color(0xFF1A1A1A)),
                      decoration: const InputDecoration(
                        hintText: '请留下宝贵意见',
                        hintStyle: TextStyle(
                            fontSize: 14, color: Color(0xFF999999)),
                        border: InputBorder.none,
                        counterText: '',
                        contentPadding: EdgeInsets.symmetric(
                            horizontal: 8, vertical: 8),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(right: 8, bottom: 6),
                      child: Text(
                        '${_remarkCtrl.text.characters.length}/$_maxLength',
                        style: const TextStyle(
                            fontSize: 12, color: Color(0xFF999999)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: SizedBox(
                  width: 140,
                  height: 36,
                  child: ElevatedButton(
                    onPressed: (_selectedScore > 0 && !_submitting)
                        ? _onSubmit
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.tintColor,
                      disabledBackgroundColor: disabledColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: _submitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('提交',
                            style: TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w500)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }
}
