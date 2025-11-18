import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/auth_provider.dart';

class AppBarWidget extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showNotificationIcon;
  final int? notificationCount;
  final VoidCallback? onNotificationPressed;
  final VoidCallback? onProfilePressed;
  final bool showSearchIcon;
  final VoidCallback? onSearchPressed;
  final bool centerTitle;
  final Color backgroundColor;
  final Color textColor;
  final List<Widget>? actions;

  const AppBarWidget({
    super.key,
    required this.title,
    this.showNotificationIcon = true,
    this.notificationCount,
    this.onNotificationPressed,
    this.onProfilePressed,
    this.showSearchIcon = false,
    this.onSearchPressed,
    this.centerTitle = true,
    this.backgroundColor = const Color(0xFF36E27B),
    this.textColor = Colors.black,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(
        title,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
      ),
      backgroundColor: backgroundColor,
      elevation: 0,
      centerTitle: centerTitle,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios, color: textColor),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        // Search icon
        if (showSearchIcon)
          IconButton(
            icon: Icon(Icons.search, color: textColor),
            onPressed: onSearchPressed ?? () {},
          ),

        // Notifications
        if (showNotificationIcon)
          Stack(
            children: [
              IconButton(
                icon: Icon(Icons.notifications, color: textColor),
                onPressed: onNotificationPressed ?? () {},
              ),
              if (notificationCount != null && notificationCount! > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      notificationCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),

        // Profile
        Consumer<AuthProvider>(
          builder: (context, authProvider, _) {
            return PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'profile') {
                  onProfilePressed?.call();
                } else if (value == 'settings') {
                  Navigator.pushNamed(context, '/account');
                } else if (value == 'logout') {
                  _showLogoutDialog(context, authProvider);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'profile',
                  child: Row(
                    children: [
                      Icon(Icons.person),
                      SizedBox(width: 8),
                      Text('Profile'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'settings',
                  child: Row(
                    children: [
                      Icon(Icons.settings),
                      SizedBox(width: 8),
                      Text('Settings'),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem(
                  value: 'logout',
                  child: Row(
                    children: [
                      Icon(Icons.logout, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Logout', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: CircleAvatar(
                  backgroundColor: Colors.grey.shade300,
                  child: Icon(Icons.account_circle, color: textColor),
                ),
              ),
            );
          },
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  void _showLogoutDialog(BuildContext context, AuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await authProvider.logout();
              if (!context.mounted) return;
              Navigator.pushReplacementNamed(context, '/login');
            },
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
