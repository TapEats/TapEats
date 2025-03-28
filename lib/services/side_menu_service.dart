import 'package:flutter/material.dart';
import 'package:tapeats/presentation/widgets/sidemenu_overlay.dart';

class SideMenuService {
  static Future<void> showSideMenu(BuildContext context) async {
    await Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        pageBuilder: (context, _, __) => const RoleBasedSideMenu(),
        transitionsBuilder: (_, __, ___, child) => child,
      ),
    );
  }
}