import 'package:flutter/material.dart';
import 'package:kkiapay_flutter_sdk/kkiapay_flutter_sdk.dart';
import 'package:vodou/core/config/kkiapay_config.dart';

class KKiaPayService {
  /// Lance le paiement via le widget officiel KKIAPAY
  Future<void> startPayment({
    required BuildContext context,
    required double amount,
    required String name,
    required String email,
    String? reason,
    required Function(Map<String, dynamic> response, BuildContext context)
    onSuccess,
    Function(Map<String, dynamic> response, BuildContext context)? onFailed,
  }) async {
    print('🚀 Démarrage du paiement KKiaPay');
    print('   Montant: ${amount.toInt()} XOF');
    print('   Nom: $name');
    print('   Email: $email');
    print('   Sandbox: ${!KKiaPayConfig.isLive}');
    print('   API Key: ${KKiaPayConfig.publicKey}');

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => KKiaPay(
          apikey: KKiaPayConfig.publicKey,
          sandbox: !KKiaPayConfig.isLive,
          amount: amount.toInt(),
          name: name,
          email: email,
          phone: "", // Laissez vide pour que l'utilisateur saisisse
          reason: reason ?? 'Réservation Vodou Host',
          callback: (response, ctx) {
            print('✅ Callback KKiaPay reçu');
            print('   Response: $response');

            final status = response['status']?.toString() ?? '';

            if (status == 'PAYMENT_SUCCESS') {
              print('✅ Paiement réussi!');
              onSuccess(response, ctx);
            } else if (status == 'PAYMENT_CANCELLED') {
              print('❌ Paiement annulé');
              if (onFailed != null) {
                onFailed(response, ctx);
              }
            } else if (status == 'PAYMENT_FAILED') {
              print('❌ Paiement échoué');
              if (onFailed != null) {
                onFailed(response, ctx);
              }
            }
          },
        ),
      ),
    );
  }
}
