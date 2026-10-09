import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../models/constants_entry.dart';
import '../services/constants_service.dart';

class ConstantsEntryFormScreen extends StatefulWidget {
  const ConstantsEntryFormScreen({
    super.key,
    required this.siteId,
    required this.siteNumberId,
    required this.siteName,
    required this.number,
    this.entry,
  });

  final int siteId;
  final int siteNumberId;
  final String siteName;
  final String number;
  final ConstantsEntry? entry;

  @override
  State<ConstantsEntryFormScreen> createState() =>
      _ConstantsEntryFormScreenState();
}

class _ConstantsEntryFormScreenState extends State<ConstantsEntryFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _ipController;

  String? _pickedImagePath;
  bool _isSaving = false;

  bool get _isEditing => widget.entry != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.entry?.name ?? '');
    _phoneController = TextEditingController(text: widget.entry?.phone ?? '');
    _ipController = TextEditingController(text: widget.entry?.ip ?? '');
  }

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

    if (_isEditing) {
      await ConstantsService.instance.updateEntry(
        id: widget.entry!.id,
        name: _nameController.text,
        phone: _phoneController.text,
        ip: _ipController.text,
        sourceImagePath: _pickedImagePath,
      );
    } else {
      await ConstantsService.instance.addEntry(
        name: _nameController.text,
        phone: _phoneController.text,
        ip: _ipController.text,
        siteId: widget.siteId,
        siteNumberId: widget.siteNumberId,
        number: widget.number,
        sourceImagePath: _pickedImagePath,
      );
    }

    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'تعديل السجل' : 'إضافة سجل')),
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
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.pin_outlined),
                      title: Text(widget.number),
                      subtitle: Text(widget.siteName),
                    ),
                  ),
                  const SizedBox(height: 20),
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
                        backgroundImage: _pickedImagePath != null
                            ? FileImage(File(_pickedImagePath!))
                            : (widget.entry?.imagePath != null
                                  ? FileImage(File(widget.entry!.imagePath!))
                                  : null),
                        child:
                            _pickedImagePath == null &&
                                widget.entry?.imagePath == null
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
