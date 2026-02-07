import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/theme_viewmodel.dart';

class SettingsPage extends StatelessWidget {
  final String uid;

  const SettingsPage({super.key, required this.uid});

  @override
  Widget build(BuildContext context) {
    final authVM = Provider.of<AuthViewModel>(context);
    final themeVM = Provider.of<ThemeViewModel>(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 600;
    final horizontalPadding = isSmallScreen ? 16.0 : 24.0;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Settings & Profile',
          style: TextStyle(fontSize: isSmallScreen ? 18 : 20),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // =================== PROFILE SECTION ===================
            Container(
              padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
                decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withAlpha((0.3 * 255).round()),
              ),
              child: Column(
                children: [
                  Container(
                    width: isSmallScreen ? 60 : 80,
                    height: isSmallScreen ? 60 : 80,
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.person,
                      size: isSmallScreen ? 30 : 40,
                      color: colorScheme.onPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    authVM.user?.email ?? 'User',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: isSmallScreen ? 16 : 18,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'User ID: ${authVM.user?.uid.substring(0, 8) ?? ''}...',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: isSmallScreen ? 12 : 13,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // =================== THEME SECTION ===================
            Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Appearance',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: isSmallScreen ? 16 : 18,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 16),
                        side: BorderSide(
                        color: colorScheme.outlineVariant.withAlpha((0.5 * 255).round()),
                      ),
                    ),
                    color: colorScheme.surface,
                    child: ListTile(
                      dense: isSmallScreen,
                      leading: Icon(
                        themeVM.isDark ? Icons.dark_mode : Icons.light_mode,
                        color: colorScheme.primary,
                        size: isSmallScreen ? 22 : 24,
                      ),
                      title: Text(
                        'Dark Mode',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 14 : 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      subtitle: Text(
                        themeVM.isDark ? 'Enabled' : 'Disabled',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontSize: isSmallScreen ? 12 : 13,
                        ),
                      ),
                      trailing: Switch(
                        value: themeVM.isDark,
                        onChanged: (_) => themeVM.toggleDarkMode(),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // =================== ACCOUNT SECTION ===================
            Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Account',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: isSmallScreen ? 16 : 18,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 16),
                        side: BorderSide(
                      color: colorScheme.outlineVariant.withAlpha((0.5 * 255).round()),
                      ),
                    ),
                    color: colorScheme.surface,
                    child: ListTile(
                      dense: isSmallScreen,
                      leading: Icon(
                        Icons.logout,
                        color: colorScheme.error,
                        size: isSmallScreen ? 22 : 24,
                      ),
                      title: Text(
                        'Logout',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 14 : 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      subtitle: Text(
                        'Sign out from your account',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 12 : 13,
                        ),
                      ),
                      onTap: () => _confirmLogout(context, authVM),
                      trailing: Icon(Icons.arrow_forward, size: isSmallScreen ? 20 : 24),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // =================== APP INFO SECTION ===================
            Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'About',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: isSmallScreen ? 16 : 18,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 16),
                        side: BorderSide(
                      color: colorScheme.outlineVariant.withAlpha((0.5 * 255).round()),
                      ),
                    ),
                    color: colorScheme.surface,
                    child: Padding(
                      padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'App Version',
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 13 : 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                '1.0.0',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                  fontSize: isSmallScreen ? 13 : 14,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Build Number',
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 13 : 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                '1',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                  fontSize: isSmallScreen ? 13 : 14,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 16),
                        side: BorderSide(
                      color: colorScheme.outlineVariant.withAlpha((0.5 * 255).round()),
                      ),
                    ),
                    color: colorScheme.surface,
                    child: Padding(
                      padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Memoro is a program created to help make recording easier and faster. We created it for the final exam of the first semester of the Information Technology major in the Faculty of Science and Technology of Battambang National University.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontSize: isSmallScreen ? 13 : 14,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'The contributors to this program are as follows',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: isSmallScreen ? 13 : 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '1. DONG DARONG',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontSize: isSmallScreen ? 13 : 14,
                            ),
                          ),
                          Text(
                            '2. POCH SOVANNAK',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontSize: isSmallScreen ? 13 : 14,
                            ),
                          ),
                          Text(
                            '3. NHEM LEANGHENG',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontSize: isSmallScreen ? 13 : 14,
                            ),
                          ),
                          Text(
                            '4. THOUN BUNTHAI',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontSize: isSmallScreen ? 13 : 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  void _confirmLogout(BuildContext context, AuthViewModel authVM) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Logout'),
        content: const Text(
          'Are you sure you want to logout from your account?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () {
              authVM.logout();
              Navigator.pop(context);
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}
