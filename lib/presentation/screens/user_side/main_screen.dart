import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tapeats/presentation/state_management/navbar_state.dart';
import 'package:tapeats/presentation/widgets/footer_widget.dart';

class MainScreen extends StatefulWidget {
  final Widget? body;
  final String? title;
  final List<Widget>? actions;
  final bool showLeading;
  
  const MainScreen({
    super.key,
    this.body,
    this.title,
    this.actions,
    this.showLeading = true,
  });

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with WidgetsBindingObserver {
  // Pre-initialized page instances to avoid recreation

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
  
  // Handle system back button
  @override
  Future<bool> didPopRoute() async {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
      return true;
    }
    return false;
  }

@override
Widget build(BuildContext context) {
  return Consumer<NavbarState>(
    builder: (context, navbarState, child) {
      // If custom body is provided, use it
      if (widget.body != null) {
        return Scaffold(
          body: widget.body,
          extendBody: true, 
          bottomNavigationBar: const DynamicFooter(),
        );
      }
      
      // IMPORTANT: Use NavbarState's pages, not _rolePages
      final pages = navbarState.getPagesForRole();
      final index = navbarState.selectedIndex;
      final safeIndex = index < pages.length ? index : 0;
      
      // Debug
      print('MainScreen: pages=${pages.length}, index=$safeIndex, role=${navbarState.userRole}');
      
        return PopScope(
          canPop: false,
          onPopInvoked: (didPop) async {
            // Back handling logic...
          },
          child: Scaffold(
            body: IndexedStack(
              index: safeIndex,
              children: pages,
            ),
            extendBody: true,
            bottomNavigationBar: const DynamicFooter(),
          ),
        );
      },
    );
  }
}