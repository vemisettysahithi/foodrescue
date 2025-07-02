import 'package:flutter/material.dart';
import '../services/api_service.dart';

class FoodInspectionPage extends StatefulWidget {
  final String donationId;
  final String donorName;
  final String foodType;

  const FoodInspectionPage({
    Key? key,
    required this.donationId,
    required this.donorName,
    required this.foodType,
  }) : super(key: key);

  @override
  FoodInspectionPageState createState() => FoodInspectionPageState();
}

class FoodInspectionPageState extends State<FoodInspectionPage> {
  int _qualityRating = 3;
  DateTime? _expirationDate;
  bool _isSubmitting = false;
  final TextEditingController _notesController = TextEditingController();

  Future<void> _submitInspection() async {
    if (_expirationDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please set expiration date'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // Call API to submit inspection results
      await ApiService.submitInspection(
        donationId: widget.donationId,
        qualityRating: _qualityRating,
        expirationDate: _expirationDate!,
        notes: _notesController.text,
      );

      // Show appropriate message based on rating
      if (_qualityRating <= 2) {
        _showResultDialog(
          'Food Rejected',
          'The food did not meet quality standards and has been dismissed.',
          Icons.warning_amber,
          Colors.orange,
        );
      } else {
        _showResultDialog(
          'Food Accepted',
          'The food has been approved for distribution.',
          Icons.check_circle,
          Colors.green,
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error submitting inspection: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _showResultDialog(String title, String message, IconData icon, Color color) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 10),
            Text(title),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _selectExpirationDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 3)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _expirationDate) {
      if (mounted) {
        setState(() => _expirationDate = picked);
      }
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Food Quality Inspection'),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Inspection Guidelines'),
                  content: const Text(
                    'Rate food quality from 1-5:\n\n'
                    '1-2: Poor quality - Reject\n'
                    '3: Acceptable\n'
                    '4-5: Excellent quality\n\n'
                    'Check for proper packaging, temperature, and signs of spoilage.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('OK'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Donation Information Card
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Donation Details',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildDetailRow('Donation ID', widget.donationId),
                    _buildDetailRow('Donor Name', widget.donorName),
                    _buildDetailRow('Food Type', widget.foodType),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Quality Rating Section
            const Text(
              'Food Quality Rating',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('Rate the food quality from 1 (Poor) to 5 (Excellent)'),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return IconButton(
                  icon: Icon(
                    index < _qualityRating ? Icons.star : Icons.star_border,
                    size: 40,
                    color: Colors.amber,
                  ),
                  onPressed: () {
                    setState(() => _qualityRating = index + 1);
                  },
                );
              }),
            ),
            Center(
              child: Text(
                _qualityRating <= 2 ? 'REJECT QUALITY' : 'ACCEPTABLE QUALITY',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: _qualityRating <= 2 ? Colors.red : Colors.green,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Expiration Date Section
            const Text(
              'Expiration Date',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: _selectExpirationDate,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today),
                    const SizedBox(width: 10),
                    Text(
                      _expirationDate == null
                          ? 'Select expiration date'
                          : 'Expires: ${_expirationDate!.toString().split(' ')[0]}',
                    ),
                  ],
                ),
              ),
            ),
            if (_expirationDate != null) ...[
              const SizedBox(height: 10),
              Text(
                'Days remaining: ${_expirationDate!.difference(DateTime.now()).inDays}',
                style: TextStyle(
                  color: _expirationDate!.isBefore(DateTime.now().add(const Duration(days: 3)))
                      ? Colors.red
                      : Colors.green,
                ),
              ),
            ],
            const SizedBox(height: 20),

            // Additional Notes
            const Text(
              'Inspection Notes',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _notesController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Enter any observations about the food quality...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 30),

            // Submit Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitInspection,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.green[700],
                ),
                child: _isSubmitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'SUBMIT INSPECTION',
                        style: TextStyle(fontSize: 16),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(value),
        ],
      ),
    );
  }
}