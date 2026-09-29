import 'package:flutter/material.dart';

const ownerSetupBrand = Color(0xFFAE1504);

class OwnerSetupStepDef {
  const OwnerSetupStepDef({
    required this.key,
    required this.title,
    required this.hint,
    required this.icon,
  });

  final String key;
  final String title;
  final String hint;
  final IconData icon;
}

const ownerSetupSteps = <OwnerSetupStepDef>[
  OwnerSetupStepDef(
    key: 'create_store',
    title: 'Toko',
    hint: 'Nama dan alamat outlet pertama',
    icon: Icons.store_mall_directory_rounded,
  ),
  OwnerSetupStepDef(
    key: 'create_product',
    title: 'Produk',
    hint: 'Menu yang dijual di kasir',
    icon: Icons.shopping_bag_rounded,
  ),
  OwnerSetupStepDef(
    key: 'create_payment_method',
    title: 'Pembayaran',
    hint: 'Tunai, transfer, atau QRIS',
    icon: Icons.payments_rounded,
  ),
  OwnerSetupStepDef(
    key: 'create_table',
    title: 'Meja',
    hint: 'Untuk order meja / QR',
    icon: Icons.table_restaurant_rounded,
  ),
  OwnerSetupStepDef(
    key: 'create_employee',
    title: 'Pegawai',
    hint: 'Akun kasir yang melayani',
    icon: Icons.badge_rounded,
  ),
];

String normalizeOwnerSetupStep(String step) {
  if (step == 'create_master_product') return 'create_product';
  return step;
}

int ownerSetupActiveIndex(String nextStep) {
  final normalized = normalizeOwnerSetupStep(nextStep);
  if (normalized == 'ready') return ownerSetupSteps.length;
  final index =
      ownerSetupSteps.indexWhere((step) => step.key == normalized);
  return index < 0 ? 0 : index;
}

enum OwnerSetupStepStatus { done, active, upcoming }

OwnerSetupStepStatus ownerSetupStatusFor(int index, String nextStep) {
  final active = ownerSetupActiveIndex(nextStep);
  if (index < active) return OwnerSetupStepStatus.done;
  if (index == active) return OwnerSetupStepStatus.active;
  return OwnerSetupStepStatus.upcoming;
}

class OwnerSetupStepHeader extends StatelessWidget {
  const OwnerSetupStepHeader({
    super.key,
    required this.stepKey,
  });

  final String stepKey;

  @override
  Widget build(BuildContext context) {
    final normalized = normalizeOwnerSetupStep(stepKey);
    final index =
        ownerSetupSteps.indexWhere((step) => step.key == normalized);
    if (index < 0) return const SizedBox.shrink();
    final step = ownerSetupSteps[index];
    final total = ownerSetupSteps.length;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Langkah ${index + 1} dari $total · ${step.title}',
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 13.5,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              for (var i = 0; i < total; i++) ...[
                if (i > 0) const SizedBox(width: 6),
                Expanded(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    height: 6,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      color: i < index
                          ? const Color(0xFF047857)
                          : i == index
                              ? ownerSetupBrand
                              : const Color(0xFFE5E7EB),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
