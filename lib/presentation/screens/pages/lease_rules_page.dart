import 'package:flutter/material.dart';

class LeaseRulesPage extends StatelessWidget {
  const LeaseRulesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF141725),
      appBar: AppBar(
        title: const Text('Lease Rules & Terms', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF141725),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('General Rules'),
            _buildRuleItem('Rent is due on the 1st of every month.'),
            _buildRuleItem('Maintain cleanliness of the premises at all times.'),
            _buildRuleItem('No loud noise or parties after 10:00 PM.'),
            _buildRuleItem('Pets are only allowed with prior written consent.'),
            
            const SizedBox(height: 24),
            _buildSectionHeader('Maintenance & Repairs'),
            _buildRuleItem('Report any damages or maintenance issues immediately via the app.'),
            _buildRuleItem('Do not attempt major repairs without management approval.'),
            _buildRuleItem('Tenant is responsible for minor light bulb replacements.'),
            
            const SizedBox(height: 24),
            _buildSectionHeader('Security & Access'),
            _buildRuleItem('Ensure all doors and gates are locked after entry/exit.'),
            _buildRuleItem('Do not share access codes or keys with unauthorized persons.'),
            _buildRuleItem('Management reserves the right to entry for inspections with 24h notice.'),
            
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E2235),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Color(0xFF4E95FF)),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Failure to comply with these rules may lead to penalties or termination of the lease.',
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: Color(0xFF4E95FF),
          fontSize: 14,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildRuleItem(String rule) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle_outline, color: Colors.greenAccent, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              rule,
              style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}
