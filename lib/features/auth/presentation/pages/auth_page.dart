import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:vodou/core/constants/app_colors.dart';
import 'package:vodou/core/constants/app_strings.dart';
import 'package:vodou/core/router/app_router.dart';

class AuthPage extends StatelessWidget {
  const AuthPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),

              // Logo
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.home_outlined,
                  size: 50,
                  color: AppColors.primary,
                ),
              ),

              const SizedBox(height: 24),

              Text(
                AppStrings.appName,
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 8),

              Text(
                AppStrings.appTagline,
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),

              const Spacer(),

              // Email Auth Button
              ElevatedButton.icon(
                onPressed: () => context.push(AppRouter.signup),
                icon: const Icon(Icons.email),
                label: const Text('Créer un compte'),
              ),

              const SizedBox(height: 16),

              // Divider
              Row(
                children: [
                  const Expanded(child: Divider()),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      AppStrings.orContinueWith,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                  const Expanded(child: Divider()),
                ],
              ),

              const SizedBox(height: 16),

              // Social Auth Buttons
              OutlinedButton.icon(
                onPressed: () {
                  // TODO: Implement Google Sign In
                },
                icon: const Icon(Icons.g_mobiledata, size: 32),
                label: Text('Continuer avec ${AppStrings.google}'),
              ),

              const SizedBox(height: 12),

              OutlinedButton.icon(
                onPressed: () {
                  // TODO: Implement Facebook Sign In
                },
                icon: const Icon(Icons.facebook),
                label: Text('Continuer avec ${AppStrings.facebook}'),
              ),

              const SizedBox(height: 12),

              OutlinedButton.icon(
                onPressed: () {
                  // TODO: Implement Apple Sign In
                },
                icon: const Icon(Icons.apple),
                label: Text('Continuer avec ${AppStrings.apple}'),
              ),

              const SizedBox(height: 24),

              // Login Button
              TextButton(
                onPressed: () => context.go(AppRouter.login),
                child: const Text(
                  'Déjà un compte ? Se connecter',
                  style: TextStyle(decoration: TextDecoration.underline),
                ),
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
