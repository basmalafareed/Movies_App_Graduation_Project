import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:movies_app_graduation_project/providers/auth_provider.dart';
import 'package:movies_app_graduation_project/providers/favorites_provider.dart';

class AuthSyncWidget extends StatefulWidget {
  final Widget child;

  const AuthSyncWidget({super.key, required this.child});

  @override
  State<AuthSyncWidget> createState() => _AuthSyncWidgetState();
}

class _AuthSyncWidgetState extends State<AuthSyncWidget> {
  String? _lastSyncedUserId;

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        final favoritesProvider = context.read<FavoritesProvider>();
        final currentUser = authProvider.currentUser;
        final currentUserId = currentUser?.id;

        if (_lastSyncedUserId != currentUserId) {
          _lastSyncedUserId = currentUserId;

          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (currentUser != null) {
              favoritesProvider.loadUserData(currentUser.id);
            } else {
              favoritesProvider.clearData();
            }
          });
        }

        return widget.child;
      },
    );
  }
}

