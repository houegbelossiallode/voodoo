import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vodou/core/constants/app_colors.dart';
import 'package:vodou/core/constants/app_strings.dart';
import 'package:vodou/features/home/presentation/pages/home_page.dart';
import 'package:vodou/features/favorites/presentation/pages/favorites_page.dart';
import 'package:vodou/features/messaging/presentation/pages/conversations_page.dart';
import 'package:vodou/features/profile/presentation/pages/profile_page.dart';

/// Provider pour contrôler l'onglet actif de la navigation principale
final bottomNavIndexProvider = StateProvider<int>((ref) => 0);

class MainPage extends ConsumerStatefulWidget {
  const MainPage({super.key});

  @override
  ConsumerState<MainPage> createState() => _MainPageState();
}

class _MainPageState extends ConsumerState<MainPage> {
  final List<Widget> _pages = [
    const HomePage(),
    const FavoritesPage(),
    const ConversationsPage(),
    const ProfilePage(),
  ];

  Future<bool> _onWillPop() async {
    final currentIndex = ref.read(bottomNavIndexProvider);
    // 1er cas : Si l'utilisateur est sur un autre onglet (Favoris, Messages, Profil), revenir à l'onglet Accueil (index 0)
    if (currentIndex != 0) {
      ref.read(bottomNavIndexProvider.notifier).state = 0;
      return false;
    }

    // 2ème cas : Si l'utilisateur est sur l'onglet Accueil, demander confirmation avec la modale (Quitter / Annuler)
    final shouldQuit = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Quitter l\'application'),
        content: const Text('Voulez-vous vraiment quitter Vodoo Host ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Quitter'),
          ),
        ],
      ),
    );

    return shouldQuit ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = ref.watch(bottomNavIndexProvider);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldQuit = await _onWillPop();
        if (shouldQuit && context.mounted) {
          // Fermer l'application sur Android / iOS
          await SystemNavigator.pop();
        }
      },
      child: Scaffold(
        body: IndexedStack(index: currentIndex, children: _pages),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: currentIndex,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.grey,
          onTap: (index) {
            ref.read(bottomNavIndexProvider.notifier).state = index;
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Accueil',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.favorite_outline),
              activeIcon: Icon(Icons.favorite),
              label: AppStrings.favorites,
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.message_outlined),
              activeIcon: Icon(Icons.message),
              label: AppStrings.messages,
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: AppStrings.profile,
            ),
          ],
        ),
      ),
    );
  }
}
