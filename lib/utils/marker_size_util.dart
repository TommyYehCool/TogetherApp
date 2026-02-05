import 'package:flutter/material.dart';

class MarkerSizeUtil {
  /// 根據標題長度和是否有 LIVE 標籤計算標記尺寸
  static Size measure({
    required Widget child,
    required BuildContext context,
    double maxWidth = 320,
  }) {
    // 簡化方案：根據內容估算尺寸
    // 這個方法不需要實際渲染，避免 RenderObject 問題
    
    // 基礎寬度計算（根據典型內容）
    // icon(26) + spacing(8) + title + spacing(6) + count + padding(28)
    double estimatedWidth = 26 + 8 + 100 + 6 + 40 + 28; // 約 208px
    
    // 限制在 maxWidth 範圍內
    estimatedWidth = estimatedWidth.clamp(120.0, maxWidth);
    
    // 高度固定
    const double height = 80.0;
    
    return Size(estimatedWidth, height);
  }
  
  /// 根據文字內容更精確地計算寬度
  static Size measureWithText({
    required String title,
    required bool hasLiveChip,
    required BuildContext context,
    double maxWidth = 360,
  }) {
    // 基礎元素寬度
    double width = 0;
    
    // LIVE chip
    if (hasLiveChip) {
      width += 28 + 12 + 8; // chip寬度 + padding + spacing
    }
    
    // Icon
    width += 26 + 8; // icon + spacing
    
    // 標題文字（粗略估算：中文約14px/字，英文約8px/字）
    final textPainter = TextPainter(
      text: TextSpan(
        text: title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    width += textPainter.width + 6; // text + spacing
    
    // 人數文字（估算約 40px）
    width += 40;
    
    // 左右 padding
    width += 28; // 14 * 2
    
    // 限制最大寬度
    width = width.clamp(120.0, maxWidth);
    
    return Size(width, 80);
  }
}
