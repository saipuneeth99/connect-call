import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/main_navigation_controller.dart';
import '../../../modules/home/views/home_view.dart';
import '../../../modules/contacts/views/contacts_view.dart';
import '../../../modules/history/views/call_history_view.dart';
import '../../../modules/profile/views/profile_view.dart';

class MainNavigationView extends GetView<MainNavigationController> {
  const MainNavigationView({super.key});

  final _pages = const [
    HomeView(),
    ContactsView(),
    CallHistoryView(),
    ProfileView(),
  ];

  @override
  Widget build(BuildContext context) {
    // Ensure controller is registered
    final navCtrl = Get.isRegistered<MainNavigationController>()
        ? Get.find<MainNavigationController>()
        : Get.put(MainNavigationController());

    return Obx(() => Scaffold(
          body: IndexedStack(
            index: navCtrl.currentIndex.value,
            children: _pages,
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: navCtrl.currentIndex.value,
            onDestinationSelected: navCtrl.changePage,
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home_rounded),
                label: 'Home',
              ),
              NavigationDestination(
                icon: Icon(Icons.contacts_outlined),
                selectedIcon: Icon(Icons.contacts_rounded),
                label: 'Contacts',
              ),
              NavigationDestination(
                icon: Icon(Icons.call_outlined),
                selectedIcon: Icon(Icons.call_rounded),
                label: 'Calls',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline),
                selectedIcon: Icon(Icons.person_rounded),
                label: 'Profile',
              ),
            ],
          ),
        ));
  }
}
