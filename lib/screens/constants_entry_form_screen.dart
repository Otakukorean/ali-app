import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../services/constants_service.dart';

class ConstantsEntryFormScreen extends StatefulWidget {
  const ConstantsEntryFormScreen({super.key});

  @override
  State<ConstantsEntryFormScreen> createState() => _ConstantsEntryFormScreenState();
}

class _ConstantsEntryFormScreenState extends State<ConstantsEntryFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _ipController = TextEditingController();

  String? _pickedImagePath;
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _ipController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final file = await FilePicker.pickFile(type: FileType.image);
    if (file?.path != null) {
      setState(() => _pickedImagePath = file!.path);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    await ConstantsService.instance.addEntry(
      name: _nameController.text,
      phone: _phoneController.text,
      ip: _ipController.text,
      sourceImagePath: _pickedImagePath,
    );

    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('إضافة سجل')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: _nameController,
                    textAlign: TextAlign.right,
                    decoration: const InputDecoration(labelText: 'الاسم'),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'الرجاء إدخال الاسم';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _phoneController,
                    textAlign: TextAlign.right,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(labelText: 'رقم الهاتف'),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'الرجاء إدخال رقم الهاتف';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _ipController,
                    textAlign: TextAlign.left,
                    decoration: const InputDecoration(labelText: 'IP'),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'الرجاء إدخال IP';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: Colors.grey.shade200,
                        backgroundImage:
                            _pickedImagePath == null ? null : FileImage(File(_pickedImagePath!)),
                        child: _pickedImagePath == null
                            ? Icon(Icons.image_outlined, color: Colors.grey.shade500)
                            : null,
                      ),
                      const SizedBox(width: 12),
                      TextButton.icon(
                        onPressed: _pickImage,
                        icon: const Icon(Icons.upload_outlined),
                        label: const Text('اختر صورة'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _submit,
                      child: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('حفظ'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
