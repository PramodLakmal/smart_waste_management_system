import 'package:flutter/material.dart';

class BinForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final Function onImagePicked;
  final Function(String type, String nickname, double weight, String description) onSubmit;

  BinForm({super.key, 
    required this.formKey,
    required this.onImagePicked,
    required this.onSubmit,
  });

  final TextEditingController _typeController = TextEditingController();
  final TextEditingController _nicknameController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        children: [
          TextFormField(
            controller: _typeController,
            decoration: InputDecoration(labelText: 'Bin Type (e.g., Plastic, Organic)'),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a bin type';
              }
              return null;
            },
          ),
          TextFormField(
            controller: _nicknameController,
            decoration: InputDecoration(labelText: 'Bin Nickname'),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a nickname';
              }
              return null;
            },
          ),
          TextFormField(
            controller: _weightController,
            decoration: InputDecoration(labelText: 'Weight (in kg)'),
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value == null || double.tryParse(value) == null) {
                return 'Please enter a valid weight';
              }
              return null;
            },
          ),
          TextFormField(
            controller: _descriptionController,
            decoration: InputDecoration(labelText: 'Description (optional)'),
          ),
          SizedBox(height: 10),
          ElevatedButton(
            onPressed: () => onImagePicked(),
            child: Text('Pick Image'),
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              onSubmit(
                _typeController.text,
                _nicknameController.text,
                double.parse(_weightController.text),
                _descriptionController.text,
              );
            },
            child: Text('Submit'),
          ),
        ],
      ),
    );
  }
}
