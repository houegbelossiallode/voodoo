import 'package:flutter/material.dart';
import 'package:vodou/core/constants/app_colors.dart';

/// AppBar personnalisé avec fond jaune et titre centré en blanc
class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final Widget? titleWidget;
  final List<Widget>? actions;
  final Widget? leading;
  final bool centerTitle;
  final PreferredSizeWidget? bottom;

  const CustomAppBar({
    super.key,
    this.title,
    this.titleWidget,
    this.actions,
    this.leading,
    this.centerTitle = true,
    this.bottom,
  }) : assert(
         title != null || titleWidget != null,
         'Either title or titleWidget must be provided',
       );

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title:
          titleWidget ??
          Text(
            title!,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
      centerTitle: centerTitle,
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      elevation: 2,
      iconTheme: const IconThemeData(color: Colors.white),
      actions: actions,
      leading: leading,
      bottom: bottom,
    );
  }

  @override
  Size get preferredSize =>
      Size.fromHeight(kToolbarHeight + (bottom?.preferredSize.height ?? 0.0));
}
