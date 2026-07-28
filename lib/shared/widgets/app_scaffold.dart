import 'package:flutter/material.dart';

import '../../design_system/spacing/app_spacing.dart';

/// Base scaffold wrapper for HealthFit Heal screens.
///
/// Provides consistent page chrome: safe-area handling, background colour,
/// a standard [AppBar], and optional floating action button.
/// Use this instead of raw [Scaffold] in feature screens.
class AppScaffold extends StatelessWidget {
  const AppScaffold({
    required this.body,
    super.key,
    this.title,
    this.titleWidget,
    this.actions,
    this.leading,
    this.automaticallyImplyLeading = true,
    this.floatingActionButton,
    this.bottomNavigationBar,
    this.bottomSheet,
    this.drawer,
    this.backgroundColor,
    this.extendBodyBehindAppBar = false,
    this.extendBody = false,
    this.resizeToAvoidBottomInset = true,
    this.onWillPop,
    this.padding,
  }) : assert(
          title == null || titleWidget == null,
          'Provide either title or titleWidget, not both.',
        );

  /// Main body content.
  final Widget body;

  /// AppBar title string (mutually exclusive with [titleWidget]).
  final String? title;

  /// Custom AppBar title widget (mutually exclusive with [title]).
  final Widget? titleWidget;

  /// AppBar trailing actions.
  final List<Widget>? actions;

  /// AppBar leading widget.
  final Widget? leading;

  /// Whether to auto-show back button.
  final bool automaticallyImplyLeading;

  /// Optional FAB.
  final Widget? floatingActionButton;

  /// Optional bottom navigation bar.
  final Widget? bottomNavigationBar;

  /// Optional persistent bottom sheet.
  final Widget? bottomSheet;

  /// Optional drawer.
  final Widget? drawer;

  /// Override scaffold background colour.
  final Color? backgroundColor;

  /// Whether the body extends behind the app bar.
  final bool extendBodyBehindAppBar;

  /// Whether the body extends behind the bottom bar.
  final bool extendBody;

  /// Whether to resize when the keyboard appears.
  final bool resizeToAvoidBottomInset;

  /// Deprecated pop intercept — use [PopScope] inside body instead.
  final Future<bool> Function()? onWillPop;

  /// Optional body padding override.
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final scaffold = Scaffold(
      backgroundColor:
          backgroundColor ?? Theme.of(context).scaffoldBackgroundColor,
      extendBodyBehindAppBar: extendBodyBehindAppBar,
      extendBody: extendBody,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      drawer: drawer,
      bottomNavigationBar: bottomNavigationBar,
      bottomSheet: bottomSheet,
      floatingActionButton: floatingActionButton,
      appBar: (title != null || titleWidget != null || actions != null)
          ? AppBar(
              title: titleWidget ?? (title != null ? Text(title!) : null),
              actions: actions,
              leading: leading,
              automaticallyImplyLeading: automaticallyImplyLeading,
              centerTitle: false,
            )
          : null,
      body: padding != null
          ? Padding(padding: padding!, child: body)
          : body,
    );

    if (onWillPop != null) {
      return PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) async {
          if (didPop) return;
          final shouldPop = await onWillPop!();
          if (shouldPop && context.mounted) {
            Navigator.of(context).pop(result);
          }
        },
        child: scaffold,
      );
    }

    return scaffold;
  }
}

/// A simple padded page scaffold used for content screens.
class AppPageScaffold extends StatelessWidget {
  const AppPageScaffold({
    required this.body,
    super.key,
    this.title,
    this.titleWidget,
    this.actions,
    this.floatingActionButton,
    this.bottomNavigationBar,
  });

  final Widget body;
  final String? title;
  final Widget? titleWidget;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: title,
      titleWidget: titleWidget,
      actions: actions,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.pageHorizontal,
      ),
      body: body,
    );
  }
}
