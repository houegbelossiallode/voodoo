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
    String? phone,
    String? reason,
    required Function(Map<String, dynamic> response, BuildContext context)
    onSuccess,
    Function(Map<String, dynamic> response, BuildContext context)? onFailed,
  }) async {
    // Assurer que tous les champs obligatoires respectent scrupuleusement le format KKiaPay
    final validName = name.trim().isNotEmpty ? name.trim() : 'Client VodooHost';
    final validEmail = (email.trim().isNotEmpty && email.contains('@'))
        ? email.trim()
        : 'client@vodoohost.com';
    final validReason = (reason != null && reason.trim().isNotEmpty)
        ? reason.trim()
        : 'Réservation Vodou Host';
    // Vérifier si le montant dépasse la limite maximale autorisée par KKiaPay (10 Millions XOF)
    if (amount > KKiaPayConfig.maxAmount) {
      final errorMsg =
          'Le montant total (${amount.toInt()} XOF) dépasse la limite maximale de 10 000 000 XOF autorisée par transaction KKiaPay. Veuillez raccourcir le séjour ou contacter l\'assistance.';
      print('⚠️ $errorMsg');

      if (onFailed != null) {
        onFailed({
          'status': 'PAYMENT_FAILED',
          'message': errorMsg,
        }, context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg),
            backgroundColor: Colors.red[700],
            duration: const Duration(seconds: 5),
          ),
        );
      }
      return;
    }

    final validAmount = (amount < KKiaPayConfig.minAmount)
        ? KKiaPayConfig.minAmount.toInt()
        : amount.toInt();
    final apiKey = KKiaPayConfig.publicKey.trim();

    // Formater le numéro de téléphone pour KKiaPay (ex: 229XXXXXXXX)
    String cleanPhone = (phone != null && phone.trim().isNotEmpty)
        ? phone.trim().replaceAll(RegExp(r'[^\d]'), '')
        : '';

    if (cleanPhone.startsWith('01') && cleanPhone.length == 10) {
      cleanPhone = '229${cleanPhone.substring(1)}';
    } else if (cleanPhone.length == 8) {
      cleanPhone = '229$cleanPhone';
    } else if (cleanPhone.length > 0 && !cleanPhone.startsWith('229') && !cleanPhone.startsWith('225') && !cleanPhone.startsWith('228') && !cleanPhone.startsWith('221')) {
      cleanPhone = '229$cleanPhone';
    }

    // Si le numéro est incomplet, laisser vide pour que le widget KKiaPay demande le numéro à l'utilisateur
    if (cleanPhone.length < 8) {
      cleanPhone = '';
    }

    final sdkData = SdkData(
      reason: validReason,
      amount: validAmount,
      paymentMethod: const ["momo", "card"],
      partnerId: "",
      countries: const ["BJ", "CI", "SN", "TG"],
      phone: cleanPhone,
      data: "",
      sandbox: !KKiaPayConfig.isLive,
      apikey: apiKey,
      theme: "#4E6BFC",
      callbackUrl: "https://kkiapay.me",
      name: validName,
      email: validEmail,
    );

    print('🚀 Démarrage du paiement KKiaPay');
    print('   Montant: $validAmount XOF');
    print('   Nom: $validName');
    print('   Email: $validEmail');
    print('   Téléphone: ${cleanPhone.isEmpty ? "(vide, à saisir par l'utilisateur)" : cleanPhone}');
    print('   Sandbox: ${!KKiaPayConfig.isLive}');
    print('   API Key: $apiKey');
    print('   Payload JSON: ${sdkData.toMap()}');
    print('   Base64 URL: ${Utils.getUrl(sdkData)}');

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => KKiaPay(
          apikey: apiKey,
          sandbox: !KKiaPayConfig.isLive,
          amount: validAmount,
          name: validName,
          email: validEmail,
          phone: cleanPhone,
          reason: validReason,
          callbackUrl: 'https://kkiapay.me',
          data: '',
          partnerId: '',
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
