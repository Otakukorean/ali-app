import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../models/app_user.dart';
import '../services/user_service.dart';

class AdminFormScreen extends StatefulWidget {
  const AdminFormScreen({super.key, this.admin});

  final AppUser? admin;

  @override
  State<AdminFormScreen> createState() => _AdminFormScreenState();
}

class _AdminFormScreenState extends State<AdminFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _usernameController;
  final _passwordController = TextEditingController();

  String? _pickedImagePath;
  bool _isSaving = false;
  String? _errorMessage;

  bool get _isEditing => widget.admin != null;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController(text: widget.admin?.username ?? '');
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
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

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      if (_isEditing) {
        await UserService.instance.updateAdmin(
          widget.admin!.id,
          username: _usernameController.text,
          password: _passwordController.text.isEmpty ? null : _passwordController.text,
          sourceImagePath: _pickedImagePath,
        );
      } else {
        await UserService.instance.addAdmin(
          _usernameController.text,
          _passwordController.text,
          sourceImagePath: _pickedImagePath,
        );
      }

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on UsernameTakenException {
      setState(() {
        _isSaving = false;
        _errorMessage = 'اسم المستخدم مستخدم بالفعل';
      });
    } catch (_) {
      setState(() {
        _isSaving = false;
        _errorMessage = 'حدث خطأ، حاول مرة أخرى';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final existingImagePath = widget.admin?.imagePath;

    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'تعديل المشرف' : 'إضافة مشرف')),
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
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: Colors.grey.shade200,
                        backgroundImage: _pickedImagePath != null
                            ? FileImage(File(_pickedImagePath!))
                            : (existingImagePath != null
                                ? FileImage(File(existingImagePath))
                                : null),
                        child: _pickedImagePath == null && existingImagePath == null
                            ? Icon(Icons.person, color: Colors.grey.shade500)
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
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _usernameController,
                    textAlign: TextAlign.right,
                    decoration: const InputDecoration(labelText: 'اسم المستخدم'),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'الرجاء إدخال اسم المستخدم';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    textAlign: TextAlign.right,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: _isEditing ? 'كلمة مرور جديدة (اختياري)' : 'كلمة المرور',
                    ),
                    validator: (value) {
                      if (!_isEditing && (value == null || value.isEmpty)) {
                        return 'الرجاء إدخال كلمة المرور';
                      }
                      return null;
                    },
                  ),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  ],
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
