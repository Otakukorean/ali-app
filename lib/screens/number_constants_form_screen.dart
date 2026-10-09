import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../models/number_constants.dart';
import '../services/constants_service.dart';

class NumberConstantsFormScreen extends StatefulWidget {
  const NumberConstantsFormScreen({
    super.key,
    required this.constants,
    required this.number,
  });

  final NumberConstants constants;
  final String number;

  @override
  State<NumberConstantsFormScreen> createState() =>
      _NumberConstantsFormScreenState();
}

class _NumberConstantsFormScreenState extends State<NumberConstantsFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _ipController;
  late final TextEditingController _whatsappController;
  late final TextEditingController _landlineController;
  String? _pickedImagePath;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _ipController = TextEditingController(text: widget.constants.ip);
    _whatsappController = TextEditingController(
      text: widget.constants.whatsapp,
    );
    _landlineController = TextEditingController(
      text: widget.constants.landline,
    );
  }

  @override
  void dispose() {
    _ipController.dispose();
    _whatsappController.dispose();
    _landlineController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    await ConstantsService.instance.updateNumberConstants(
      id: widget.constants.id,
      ip: _ipController.text,
      whatsapp: _whatsappController.text,
      landline: _landlineController.text,
      sourceImagePath: _pickedImagePath,
    );

    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  String? _required(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'هذا الحقل مطلوب';
    }
    return null;
  }

  Future<void> _pickImage() async {
    final file = await FilePicker.pickFile(type: FileType.image);
    if (file?.path != null) {
      setState(() => _pickedImagePath = file!.path);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('تعديل ثوابت ${widget.number}')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _ipController,
                    textAlign: TextAlign.left,
                    decoration: const InputDecoration(labelText: 'IP'),
                    validator: _required,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _whatsappController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(labelText: 'واتساب'),
                    validator: _required,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _landlineController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(labelText: 'ثابت'),
                    validator: _required,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 36,
                        backgroundColor: Colors.grey.shade200,
                        backgroundImage: _pickedImagePath != null
                            ? FileImage(File(_pickedImagePath!))
                            : (widget.constants.imagePath != null
                                  ? FileImage(File(widget.constants.imagePath!))
                                  : null),
                        child:
                            _pickedImagePath == null &&
                                widget.constants.imagePath == null
                            ? Icon(
                                Icons.image_outlined,
                                color: Colors.grey.shade500,
                              )
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
