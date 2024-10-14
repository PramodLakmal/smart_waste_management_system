import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Add Card Details',
      theme: ThemeData(
        primarySwatch: Colors.amber,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        primarySwatch: Colors.amber,
        brightness: Brightness.dark,
      ),
      themeMode: ThemeMode.system,
      home: const AddCardDetails(),
    );
  }
}

class AddCardDetails extends StatefulWidget {
  const AddCardDetails({super.key});

  @override
  State<AddCardDetails> createState() => _AddCardDetailsState();
}

class _AddCardDetailsState extends State<AddCardDetails> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController cardHolderNameController =
      TextEditingController();
  final TextEditingController cardNumberController = TextEditingController();
  final TextEditingController expiryDateController = TextEditingController();
  final TextEditingController cvvController = TextEditingController();

  // Custom colors
  final Color darkGreen = const Color(0xFF2E7D32);
  final Color mediumGreen = const Color(0xFF4CAF50);
  final Color lightGreen = const Color(0xFF81C784);
  final Color cream = const Color(0xFFFFFDE7);

  @override
  void dispose() {
    cardHolderNameController.dispose();
    cardNumberController.dispose();
    expiryDateController.dispose();
    cvvController.dispose();
    super.dispose();
  }

  bool validateCardNumber(String value) {
    // Basic Luhn algorithm for card number validation
    if (value.isEmpty) return false;
    int sum = 0;
    bool alternate = false;
    for (int i = value.length - 1; i >= 0; i--) {
      int n = int.parse(value[i]);
      if (alternate) {
        n *= 2;
        if (n > 9) n -= 9;
      }
      sum += n;
      alternate = !alternate;
    }
    return sum % 10 == 0;
  }

  String? validateExpiryDate(String? value) {
    if (value?.isEmpty ?? true) {
      return 'Please enter expiry date';
    }
    final RegExp regex = RegExp(r'^(0[1-9]|1[0-2])\/?([0-9]{2})$');
    if (!regex.hasMatch(value!)) {
      return 'Enter a valid date (MM/YY)';
    }
    return null;
  }

  String? validateCVV(String? value) {
    if (value?.isEmpty ?? true) {
      return 'Please enter CVV';
    }
    if (value != null && value.length != 3) {
      return 'CVV must be 3 digits';
    }
    return null;
  }

  void submitForm() {
    if (_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Card details saved!', style: GoogleFonts.poppins()),
          backgroundColor: mediumGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLightMode = Theme.of(context).brightness == Brightness.light;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Add Card Details',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: cream),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: darkGreen,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [darkGreen, mediumGreen],
              ),
            ),
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Container(
                  width: constraints.maxWidth < 600 ? double.infinity : 500,
                  decoration: BoxDecoration(
                    color: cream,
                    borderRadius: BorderRadius.circular(24.0),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        spreadRadius: 5,
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(32.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Card Information',
                          style: GoogleFonts.poppins(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: darkGreen,
                          ),
                        ).animate().fadeIn(duration: 600.ms).slideX(),
                        const SizedBox(height: 24),
                        AnimatedInputField(
                          controller: cardHolderNameController,
                          label: 'Cardholder Name',
                          keyboardType: TextInputType.text,
                          validator: (value) {
                            if (value!.isEmpty) {
                              return 'Please enter cardholder name';
                            }
                            return null;
                          },
                          fillColor: lightGreen.withOpacity(0.2),
                          textColor: darkGreen,
                        ),
                        const SizedBox(height: 16),
                        AnimatedInputField(
                          controller: cardNumberController,
                          label: 'Card Number',
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value!.isEmpty) {
                              return 'Please enter card number';
                            }
                            if (!validateCardNumber(value)) {
                              return 'Invalid card number';
                            }
                            return null;
                          },
                          fillColor: lightGreen.withOpacity(0.2),
                          textColor: darkGreen,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: AnimatedInputField(
                                controller: expiryDateController,
                                label: 'Expiry Date (MM/YY)',
                                keyboardType: TextInputType.datetime,
                                validator: validateExpiryDate,
                                fillColor: lightGreen.withOpacity(0.2),
                                textColor: darkGreen,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: AnimatedInputField(
                                controller: cvvController,
                                label: 'CVV',
                                obscureText: true,
                                keyboardType: TextInputType.number,
                                validator: validateCVV,
                                fillColor: lightGreen.withOpacity(0.2),
                                textColor: darkGreen,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: submitForm,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              backgroundColor: darkGreen,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16.0),
                              ),
                            ),
                            child: Text(
                              'Save Card Details',
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: cream,
                              ),
                            ),
                          ),
                        )
                            .animate()
                            .fadeIn(delay: 300.ms, duration: 600.ms)
                            .scale(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class AnimatedInputField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool obscureText;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final Color fillColor;
  final Color textColor;

  const AnimatedInputField({
    Key? key,
    required this.controller,
    required this.label,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.validator,
    required this.fillColor,
    required this.textColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: GoogleFonts.poppins(fontSize: 16, color: textColor),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.poppins(
            fontSize: 16, color: textColor.withOpacity(0.7)),
        filled: true,
        fillColor: fillColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16.0),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16.0),
          borderSide: BorderSide(
            color: textColor,
            width: 2.0,
          ),
        ),
      ),
      validator: validator,
    ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.2, end: 0);
  }
}
