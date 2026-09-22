import 'package:flutter/material.dart';
import 'package:vodou/core/constants/app_colors.dart';
import 'package:vodou/core/widgets/app_logo_widget.dart';

/// AppBar personnalisé avec fond jaune et titre centré en blanc
class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final Widget? titleWidget;
  final List<Widget>? actions;
  final Widget? leading;
  final bool centerTitle;
  final PreferredSizeWidget? bottom;
  final bool showLogo;
  final bool showBackButton;

  const CustomAppBar({
    super.key,
    this.title,
    this.titleWidget,
    this.actions,
    this.leading,
    this.centerTitle = true,
    this.bottom,
    this.showLogo = true,
    this.showBackButton = true,
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
      actions: showLogo
          ? [
              if (actions != null) ...actions!,
              const Padding(
                padding: EdgeInsets.only(right: 12.0),
                child: AppLogoWidget(),
              ),
            ]
          : actions,
      automaticallyImplyLeading: showBackButton,
      leading: leading ??
          (showBackButton && Navigator.of(context).canPop()
              ? IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () {
                    if (Navigator.of(context).canPop()) {
                      Navigator.of(context).pop();
                    }
                  },
                )
              : null),
      bottom: bottom,
    );
  }

  @override
  Size get preferredSize =>
      Size.fromHeight(kToolbarHeight + (bottom?.preferredSize.height ?? 0.0));
}
