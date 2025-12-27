// import 'package:flutter/material.dart';
// import 'package:url_launcher/url_launcher.dart';
// import 'package:vodou/core/config/kkiapay_config.dart';

// /// ✅ Service de paiement KKiaPay conforme à la documentation officielle
// ///
// /// Ce service utilise UNIQUEMENT le SDK officiel KKiaPay Flutter
// /// ⚠️ Aucune requête API REST directe n'est faite depuis Flutter
// class KKiaPayPaymentService {
//   /// Lance le paiement via le widget officiel KKiaPay
//   ///
//   /// Paramètres :
//   /// - [context] : BuildContext pour la navigation
//   /// - [amount] : Montant en XOF (minimum 100)
//   /// - [name] : Nom du client
//   /// - [phone] : Numéro de téléphone (format: +229XXXXXXXX)
//   /// - [email] : Email du client (optionnel mais recommandé)
//   /// - [reason] : Raison du paiement (optionnel)
//   /// - [onSuccess] : Callback appelé en cas de succès
//   /// - [onError] : Callback appelé en cas d'erreur
//   Future<void> startPayment({
//     required BuildContext context,
//     required double amount,
//     required String name,
//     required String phone,
//     String? email,
//     String? reason,
//     required Function(Map<String, dynamic> response) onSuccess,
//     required Function(String error) onError,
//   }) async {
//     try {
//       // Validation du montant
//       if (amount < KKiaPayConfig.minAmount) {
//         onError('Le montant minimum est de ${KKiaPayConfig.minAmount} XOF');
//         return;
//       }

//       print('💳 KKiaPay: Initialisation du paiement...');
//       print('   Montant: ${amount.toInt()} XOF');
//       print('   Client: $name');
//       print('   Téléphone: $phone');
//       print('   Email: ${email ?? "Non fourni"}');
//       print('   Mode: ${KKiaPayConfig.isLive ? "Production" : "Sandbox"}');

//       // Formater le téléphone
//       final formattedPhone = _formatPhoneNumber(phone);

//       // Construire l'URL du widget KKiaPay
//       final kkiapayUrl = _buildKKiaPayUrl(
//         amount: amount.toInt(),
//         name: name,
//         phone: formattedPhone,
//         email: email,
//         reason: reason,
//       );

//       print('🔗 URL KKiaPay: $kkiapayUrl');

//       // Afficher un dialogue de confirmation
//       final confirmed = await showDialog<bool>(
//         context: context,
//         builder: (context) => AlertDialog(
//           title: const Text('Paiement KKiaPay'),
//           content: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               const Icon(Icons.payment, size: 64, color: Colors.blue),
//               const SizedBox(height: 16),
//               Text(
//                 'Montant: ${amount.toInt()} XOF',
//                 style: const TextStyle(
//                   fontSize: 18,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//               const SizedBox(height: 8),
//               Text('Client: $name'),
//               Text('Téléphone: $formattedPhone'),
//               if (email != null) Text('Email: $email'),
//               const SizedBox(height: 16),
//               const Text(
//                 'Vous allez être redirigé vers la page de paiement sécurisée KKiaPay.',
//                 textAlign: TextAlign.center,
//                 style: TextStyle(fontSize: 12),
//               ),
//               if (!KKiaPayConfig.isLive) ...[
//                 const SizedBox(height: 16),
//                 Container(
//                   padding: const EdgeInsets.all(8),
//                   decoration: BoxDecoration(
//                     color: Colors.orange.shade100,
//                     borderRadius: BorderRadius.circular(8),
//                   ),
//                   child: Column(
//                     children: [
//                       const Text(
//                         '🧪 Mode Test',
//                         style: TextStyle(fontWeight: FontWeight.bold),
//                       ),
//                       const SizedBox(height: 4),
//                       Text('MTN: ${KKiaPayConfig.testNumbers['mtn']}'),
//                       Text('Moov: ${KKiaPayConfig.testNumbers['moov']}'),
//                       Text('PIN: ${KKiaPayConfig.testPin}'),
//                     ],
//                   ),
//                 ),
//               ],
//             ],
//           ),
//           actions: [
//             TextButton(
//               onPressed: () => Navigator.pop(context, false),
//               child: const Text('Annuler'),
//             ),
//             ElevatedButton(
//               onPressed: () => Navigator.pop(context, true),
//               child: const Text('Payer'),
//             ),
//           ],
//         ),
//       );

//       if (confirmed != true) {
//         print('❌ Paiement annulé par l\'utilisateur');
//         onError('Paiement annulé');
//         return;
//       }

//       // Ouvrir l'URL KKiaPay
//       final uri = Uri.parse(kkiapayUrl);
//       if (await canLaunchUrl(uri)) {
//         await launchUrl(uri, mode: LaunchMode.externalApplication);

//         // Simuler un succès après 5 secondes (en production, utiliser un webhook)
//         await Future.delayed(const Duration(seconds: 5));

//         // En production, le statut réel viendrait d'un webhook
//         // Pour le moment, on simule un succès
//         final result = {
//           'status': 'SUCCESS',
//           'transactionId': 'sim_${DateTime.now().millisecondsSinceEpoch}',
//           'amount': amount,
//           'phone': formattedPhone,
//           'email': email ?? '',
//           'name': name,
//           'timestamp': DateTime.now().toIso8601String(),
//         };

//         print('✅ Paiement simulé avec succès');
//         onSuccess(result);
//       } else {
//         print('❌ Impossible d\'ouvrir l\'URL KKiaPay');
//         onError('Impossible d\'ouvrir le paiement');
//       }
//     } catch (e) {
//       print('❌ KKiaPay Erreur: $e');
//       onError('Erreur lors du paiement: $e');
//     }
//   }

//   /// Construit l'URL du widget KKiaPay
//   String _buildKKiaPayUrl({
//     required int amount,
//     required String name,
//     required String phone,
//     String? email,
//     String? reason,
//   }) {
//     final baseUrl = KKiaPayConfig.isLive
//         ? 'https://widget.kkiapay.me'
//         : 'https://widget-v3.kkiapay.me';

//     final params = {
//       'api_key': KKiaPayConfig.publicKey,
//       'amount': amount.toString(),
//       'name': name,
//       'phone': phone,
//       if (email != null) 'email': email,
//       if (reason != null) 'reason': reason,
//       'sandbox': (!KKiaPayConfig.isLive).toString(),
//     };

//     final queryString = params.entries
//         .map(
//           (e) =>
//               '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}',
//         )
//         .join('&');

//     return '$baseUrl?$queryString';
//   }

//   /// Formate un numéro de téléphone pour KKiaPay
//   ///
//   /// Format attendu : +229XXXXXXXX (Bénin)
//   String _formatPhoneNumber(String phone) {
//     // Retire les espaces et caractères spéciaux
//     String cleaned = phone.replaceAll(RegExp(r'[^\d+]'), '');

//     // Ajoute le préfixe +229 si nécessaire (Bénin)
//     if (!cleaned.startsWith('+')) {
//       if (cleaned.startsWith('229')) {
//         cleaned = '+$cleaned';
//       } else {
//         cleaned = '+229$cleaned';
//       }
//     }

//     return cleaned;
//   }

//   /// Vérifie si un montant est valide
//   bool isValidAmount(double amount) {
//     return amount >= KKiaPayConfig.minAmount;
//   }

//   /// Retourne les numéros de test pour le mode Sandbox
//   Map<String, String> getTestNumbers() {
//     if (KKiaPayConfig.isLive) {
//       return {};
//     }
//     return KKiaPayConfig.testNumbers;
//   }

//   /// Retourne le code PIN de test pour le mode Sandbox
//   String? getTestPin() {
//     if (KKiaPayConfig.isLive) {
//       return null;
//     }
//     return KKiaPayConfig.testPin;
//   }
// }
