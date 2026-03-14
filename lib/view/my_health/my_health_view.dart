import 'package:flutter/material.dart';
import 'package:food_delivery_app/common/color_extension.dart';
import 'package:food_delivery_app/common_widget/round_button.dart';
import 'package:food_delivery_app/common_widget/round_textfield.dart';
import 'package:food_delivery_app/common_widget/value_tile.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:intl/intl.dart';

import 'health_service.dart';

class MyHealthView extends StatefulWidget {
  const MyHealthView({super.key});

  @override
  State<MyHealthView> createState() => _MyHealthViewState();
}

class _MyHealthViewState extends State<MyHealthView> {
  final HealthService _healthService = HealthService();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();

  Map<String, dynamic>? _healthData;
  double? _bmi;
  String? _bmiCategory;
  List<Map<String, dynamic>> _healthTips = [];
  bool _isLoading = true;
  bool _isGeneratingTip = false;
  String? _generatedTip;

  @override
  void initState() {
    super.initState();
    _loadHealthData();
  }

  Future<void> _loadHealthData() async {
    setState(() => _isLoading = true);
    try {
      _healthData = await _healthService.getHealthData();
      if (_healthData != null) {
        _weightController.text = _healthData!['weight_kg']?.toString() ?? '';
        _heightController.text = _healthData!['height_cm']?.toString() ?? '';
        _ageController.text = _healthData!['age']?.toString() ?? '';
      }

      _bmi = await _healthService.calculateBMI();
      _bmiCategory = _getBMICategory(_bmi);
      _healthTips = await _healthService.getHealthTips();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load health data: ${e.toString()}')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String _getBMICategory(double? bmi) {
    if (bmi == null) return 'Unknown';
    if (bmi < 18.5) return 'Underweight';
    if (bmi < 25) return 'Normal';
    if (bmi < 30) return 'Overweight';
    return 'Obese';
  }

  Color _getBMIColor(double? bmi) {
    if (bmi == null) return TColor.secondaryText;
    if (bmi < 18.5) return Colors.blue;
    if (bmi < 25) return Colors.green;
    if (bmi < 30) return Colors.orange;
    return Colors.red;
  }

  Future<void> _saveHealthData() async {
    if (_weightController.text.isEmpty ||
        _heightController.text.isEmpty ||
        _ageController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all required fields')),
      );
      return;
    }

    try {
      await _healthService.saveHealthData(
        weight: double.parse(_weightController.text),
        height: double.parse(_heightController.text),
        age: int.parse(_ageController.text),
      );
      await _loadHealthData();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Health data saved successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save health data: ${e.toString()}')),
      );
    }
  }

  Future<void> _generateHealthTip() async {
    await _healthService.updateUserCalorie();
    await _loadHealthData(); // Refresh data after calorie update

    if (_bmi == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please save your health data first')),
      );
      return;
    }

    setState(() => _isGeneratingTip = true);

    try {
      final model = GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: 'AIzaSyD25Vh9PKuB-T2oA2N0oS_X9qggd6Bz_ZQ',
      );

      final prompt = '''
      Generate a health tip for someone with:
      - BMI: ${_bmi!.toStringAsFixed(1)} (${_bmiCategory})
      - Age: ${_healthData?['age'] ?? 'unknown'} years
      - Weight: ${_healthData?['weight_kg'] ?? 'unknown'} kg
      - Height: ${_healthData?['height_cm'] ?? 'unknown'} cm
      - Recent calories: ${_healthData?['last_calorie_intake'] ?? 'unknown'} kcal
      
      Make it practical and encouraging (2-3 sentences max).
      ''';

      final response = await model.generateContent([Content.text(prompt)]);
      final tip = response.text ?? 'Could not generate tip. Please try again.';

      await _healthService.saveHealthTip(tip, _bmi!);
      setState(() => _generatedTip = tip);
      await _loadHealthData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to generate tip: ${e.toString()}')),
      );
    } finally {
      setState(() => _isGeneratingTip = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 46),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                "My Health Dashboard",
                style: TextStyle(
                  color: TColor.primaryText,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Health Metrics Summary
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        ValueTile(
                          title: "BMI",
                          value: _bmi?.toStringAsFixed(1) ?? "--",
                          unit: "kg/m²",
                          color: _getBMIColor(_bmi),
                        ),
                        ValueTile(
                          title: "Weight",
                          value: _healthData?['weight_kg']?.toString() ?? "--",
                          unit: "kg",
                        ),
                        ValueTile(
                          title: "Height",
                          value: _healthData?['height_cm']?.toString() ?? "--",
                          unit: "cm",
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Calorie Information
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: TColor.primary.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Recent Calorie Intake",
                                style: TextStyle(
                                  color: TColor.primaryText,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                "Based on your last 24h orders",
                                style: TextStyle(
                                  color: TColor.secondaryText,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            "${_healthData?['last_calorie_intake']?.toString() ?? "--"} kcal",
                            style: TextStyle(
                              color: TColor.primary,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_bmi != null)
                      LinearProgressIndicator(
                        value: _bmi! / 40,
                        minHeight: 10,
                        backgroundColor: TColor.secondaryText.withOpacity(0.1),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _getBMIColor(_bmi),
                        ),
                        borderRadius: BorderRadius.circular(5),
                      ),
                    const SizedBox(height: 8),
                    if (_bmi != null)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Underweight",
                            style: TextStyle(
                              color: _bmi! < 18.5 ? _getBMIColor(_bmi) : TColor.secondaryText,
                              fontSize: 10,
                            ),
                          ),
                          Text(
                            "Normal",
                            style: TextStyle(
                              color: _bmi! >= 18.5 && _bmi! < 25 ? _getBMIColor(_bmi) : TColor.secondaryText,
                              fontSize: 10,
                            ),
                          ),
                          Text(
                            "Overweight",
                            style: TextStyle(
                              color: _bmi! >= 25 && _bmi! < 30 ? _getBMIColor(_bmi) : TColor.secondaryText,
                              fontSize: 10,
                            ),
                          ),
                          Text(
                            "Obese",
                            style: TextStyle(
                              color: _bmi! >= 30 ? _getBMIColor(_bmi) : TColor.secondaryText,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Health Data Form
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Update Your Health Metrics",
                      style: TextStyle(
                        color: TColor.primaryText,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildInputField(
                      controller: _weightController,
                      label: "Body Weight",
                      unit: "kg",
                      icon: Icons.monitor_weight,
                      description: "Your current body weight in kilograms",
                    ),
                    const SizedBox(height: 12),
                    _buildInputField(
                      controller: _heightController,
                      label: "Height",
                      unit: "cm",
                      icon: Icons.height,
                      description: "Your height in centimeters",
                    ),
                    const SizedBox(height: 12),
                    _buildInputField(
                      controller: _ageController,
                      label: "Age",
                      unit: "years",
                      icon: Icons.person,
                      description: "Your current age",
                    ),
                    const SizedBox(height: 20),
                    RoundButton(
                      title: "Save Health Data",
                      onPressed: _saveHealthData,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Rest of your existing code for tips...
            // Generated Tip Section
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Personalized Health Tip",
                          style: TextStyle(
                            color: TColor.primaryText,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.refresh),
                          onPressed: _isGeneratingTip ? null : _generateHealthTip,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_isGeneratingTip)
                      const Center(child: CircularProgressIndicator())
                    else if (_generatedTip != null || _healthTips.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: TColor.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _generatedTip ?? _healthTips.first['tip_text'],
                              style: TextStyle(
                                color: TColor.primaryText,
                                fontSize: 14,
                              ),
                            ),
                            if (_healthTips.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  "Generated on ${DateFormat('MMM d, y').format(DateTime.parse(_healthTips.first['generated_at']))}",
                                  style: TextStyle(
                                    color: TColor.secondaryText,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      )
                    else
                      Text(
                        "Generate a personalized health tip based on your metrics",
                        style: TextStyle(
                          color: TColor.secondaryText,
                          fontSize: 14,
                        ),
                      ),
                  ],
                ),
              ),
            ),

            ListView.separated(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: _healthTips.length - 1,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final tip = _healthTips[index + 1];
                return Card(
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tip['tip_text'],
                          style: TextStyle(
                            color: TColor.primaryText,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "BMI: ${tip['bmi'].toStringAsFixed(1)}",
                              style: TextStyle(
                                color: _getBMIColor(tip['bmi']),
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              DateFormat('MMM d, y').format(
                                  DateTime.parse(tip['generated_at'])),
                              style: TextStyle(
                                color: TColor.secondaryText,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String unit,
    required IconData icon,
    required String description,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: TColor.primary),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: TColor.primaryText,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            Text(
              unit,
              style: TextStyle(
                color: TColor.secondaryText,
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          description,
          style: TextStyle(
            color: TColor.secondaryText,
            fontSize: 10,
          ),
        ),
        const SizedBox(height: 4),
        RoundTextField(
          controller: controller,
          hintText: "Enter $label in $unit",
          keyboardType: TextInputType.number,
        ),
      ],
    );
  }
}