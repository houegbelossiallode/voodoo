import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:vodou/core/constants/app_colors.dart';
import 'package:vodou/core/constants/app_strings.dart';
import 'package:vodou/core/router/app_router.dart';

class PhoneAuthPage extends StatefulWidget {
  const PhoneAuthPage({super.key});

  @override
  State<PhoneAuthPage> createState() => _PhoneAuthPageState();
}

class _PhoneAuthPageState extends State<PhoneAuthPage> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  String _selectedCountryCode = '+229'; // Benin default

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  void _sendOTP() {
    if (_formKey.currentState!.validate()) {
      // TODO: Implement OTP sending logic
      // Redirection vers la page de connexion
      context.go(AppRouter.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Entrez votre numéro',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  'Nous vous enverrons un code de vérification',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),

                const SizedBox(height: 32),

                // Country Code Selector
                DropdownButtonFormField<String>(
                  value: _selectedCountryCode,
                  decoration: const InputDecoration(
                    labelText: 'Pays',
                    prefixIcon: Icon(Icons.flag),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: '+229',
                      child: Text('🇧🇯 Bénin (+229)'),
                    ),
                    DropdownMenuItem(
                      value: '+33',
                      child: Text('🇫🇷 France (+33)'),
                    ),
                    DropdownMenuItem(value: '+1', child: Text('🇺🇸 USA (+1)')),
                    DropdownMenuItem(
                      value: '+44',
                      child: Text('🇬🇧 UK (+44)'),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedCountryCode = value!;
                    });
                  },
                ),

                const SizedBox(height: 16),

                // Phone Number Input
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: AppStrings.phoneNumber,
                    prefixIcon: const Icon(Icons.phone),
                    hintText: '12 34 56 78',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez entrer votre numéro de téléphone';
                    }
                    if (value.length < 8) {
                      return 'Numéro de téléphone invalide';
                    }
                    return null;
                  },
                ),

                const Spacer(),

                // Continue Button
                ElevatedButton(
                  onPressed: _sendOTP,
                  child: const Text('Continuer'),
                ),

                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
