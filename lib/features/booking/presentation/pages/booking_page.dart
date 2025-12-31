import 'package:flutter/material.dart';
import 'package:vodou/core/widgets/custom_app_bar.dart';
import 'package:vodou/core/constants/app_colors.dart';
import 'package:vodou/core/constants/app_strings.dart';

class BookingPage extends StatefulWidget {
  final String accommodationId;

  const BookingPage({super.key, required this.accommodationId});

  @override
  State<BookingPage> createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage> {
  DateTime? _checkIn;
  DateTime? _checkOut;
  int _guests = 1;
  String? _selectedProject;
  bool _payInTwo = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: AppStrings.booking),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Accommodation Summary
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.greyLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.image, color: AppColors.grey),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Maison traditionnelle',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 4),
                        const Text('Ouidah, Bénin'),
                        const SizedBox(height: 4),
                        Row(
                          children: const [
                            Icon(Icons.star, size: 16, color: AppColors.rating),
                            SizedBox(width: 4),
                            Text('4.8'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Dates
          Text(
            'Dates du séjour',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildDateField(
                  context,
                  AppStrings.checkIn,
                  _checkIn,
                  () => _selectDate(context, true),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildDateField(
                  context,
                  AppStrings.checkOut,
                  _checkOut,
                  () => _selectDate(context, false),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Guests
          Text(
            AppStrings.guests,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              IconButton(
                onPressed: _guests > 1 ? () => setState(() => _guests--) : null,
                icon: const Icon(Icons.remove_circle_outline),
              ),
              Expanded(
                child: Text(
                  '$_guests voyageur${_guests > 1 ? 's' : ''}',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              IconButton(
                onPressed: () => setState(() => _guests++),
                icon: const Icon(Icons.add_circle_outline),
              ),
            ],
          ),

          const Divider(height: 32),

          // Social Project
          Text(
            AppStrings.socialProject,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            AppStrings.chooseSocialProject,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _selectedProject,
            decoration: const InputDecoration(
              hintText: 'Sélectionner un projet',
            ),
            items: const [
              DropdownMenuItem(
                value: 'education',
                child: Text(AppStrings.educationProject),
              ),
              DropdownMenuItem(
                value: 'heritage',
                child: Text(AppStrings.heritagePreservation),
              ),
              DropdownMenuItem(
                value: 'artisan',
                child: Text(AppStrings.artisanSupport),
              ),
              DropdownMenuItem(
                value: 'water',
                child: Text(AppStrings.waterAccess),
              ),
            ],
            onChanged: (value) {
              setState(() => _selectedProject = value);
            },
          ),

          const Divider(height: 32),

          // Payment Options
          Text(
            AppStrings.paymentMethod,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          RadioListTile<bool>(
            title: const Text(AppStrings.payInFull),
            subtitle: const Text('Payer 150 000 FCFA maintenant'),
            value: false,
            groupValue: _payInTwo,
            onChanged: (value) => setState(() => _payInTwo = value!),
          ),
          RadioListTile<bool>(
            title: const Text(AppStrings.payInTwo),
            subtitle: const Text(
              '75 000 FCFA maintenant, 75 000 FCFA plus tard',
            ),
            value: true,
            groupValue: _payInTwo,
            onChanged: (value) => setState(() => _payInTwo = value!),
          ),

          const SizedBox(height: 24),

          // Price Summary
          Card(
            color: AppColors.primaryLight.withOpacity(0.1),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildPriceRow('25 000 FCFA x 6 nuits', '150 000 FCFA'),
                  const Divider(height: 16),
                  _buildPriceRow('Frais de service', '15 000 FCFA'),
                  _buildPriceRow('Contribution sociale', '5 000 FCFA'),
                  const Divider(height: 16),
                  _buildPriceRow('Total', '170 000 FCFA', bold: true),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Confirm Button
          ElevatedButton(
            onPressed: () {
              // TODO: Process booking
            },
            child: const Text(AppStrings.confirmBooking),
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildDateField(
    BuildContext context,
    String label,
    DateTime? date,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: const Icon(Icons.calendar_today),
        ),
        child: Text(
          date != null
              ? '${date.day}/${date.month}/${date.year}'
              : 'Sélectionner',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context, bool isCheckIn) async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null) {
      setState(() {
        if (isCheckIn) {
          _checkIn = date;
        } else {
          _checkOut = date;
        }
      });
    }
  }

  Widget _buildPriceRow(String label, String amount, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            amount,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
