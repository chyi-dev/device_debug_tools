import 'package:flutter/material.dart';

import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_text_style.dart';

/// 页面通用骨架：标题栏 + 内容区。
class AppScaffold extends StatelessWidget {
  const AppScaffold({
    super.key,
    required this.title,
    required this.body,
    this.actions,
    this.floatingActionButton,
    this.padding = const EdgeInsets.all(AppSpacing.xl),
  });

  final String title;
  final Widget body;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        title: Text(title, style: AppTextStyles.titleMedium(cs)),
        actions: actions,
      ),
      body: Padding(padding: padding, child: body),
      floatingActionButton: floatingActionButton,
    );
  }
}
