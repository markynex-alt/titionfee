import 'package:flutter/material.dart';
import '../../providers/app_provider.dart';

class SubscriptionActivationCard extends StatelessWidget {
  final AppProvider provider;
  final bool isBn;
  final TextEditingController codeController;
  final bool isActivating;
  final String? activationStatus;
  final bool isSuccess;
  final VoidCallback onActivate;

  const SubscriptionActivationCard({
    super.key,
    required this.provider,
    required this.isBn,
    required this.codeController,
    required this.isActivating,
    required this.activationStatus,
    required this.isSuccess,
    required this.onActivate,
  });

  @override
  Widget build(BuildContext context) {
    final p = provider;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.deepPurple.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.vpn_key_rounded, color: Colors.deepPurple, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.tr('have_activation_code'),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    Text(
                      isBn
                          ? "বিকাশ/নগদ 01825690912-এ পেমেন্ট করে TrxID বা কোড লিখুন"
                          : "Pay to bKash/Nagad 01825690912 & enter TrxID or code to extend validity",
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: codeController,
                  textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(
                    hintText: p.tr('activation_code_hint'),
                    hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: isActivating ? null : onActivate,
                child: isActivating
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : Text(
                        p.tr('activate_btn'),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
              ),
            ],
          ),
          if (activationStatus != null) ...[
            const SizedBox(height: 10),
            Text(
              activationStatus!,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSuccess ? Colors.green.shade700 : Colors.red.shade700,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
