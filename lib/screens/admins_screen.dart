import 'dart:io';

import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../models/app_user.dart';
import '../services/user_service.dart';
import 'admin_form_screen.dart';

class AdminsScreen extends StatefulWidget {
  const AdminsScreen({super.key});

  @override
  State<AdminsScreen> createState() => _AdminsScreenState();
}

class _AdminsScreenState extends State<AdminsScreen> {
  late Future<List<AppUser>> _adminsFuture;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    setState(() {
      _adminsFuture = UserService.instance.getAdmins();
    });
  }

  Future<void> _openAddPage() async {
    final saved = await Navigator.of(context)
        .push<bool>(MaterialPageRoute(builder: (_) => const AdminFormScreen()));
    if (saved == true) _reload();
  }

  Future<void> _openEditPage(AppUser admin) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => AdminFormScreen(admin: admin)),
    );
    if (saved == true) _reload();
  }

  Future<void> _confirmDelete(AppUser admin) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف المشرف'),
        content: Text('هل أنت متأكد من حذف "${admin.username}"؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('حذف', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await UserService.instance.deleteAdmin(admin.id);
      _reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('المشرفين')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddPage,
        icon: const Icon(Icons.add),
        label: const Text('إضافة مشرف'),
      ),
      body: FutureBuilder<List<AppUser>>(
        future: _adminsFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final admins = snapshot.data!;
          if (admins.isEmpty) {
            return const Center(child: Text('لا يوجد مشرفين بعد'));
          }

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(
                  vertical: 24,
                  horizontal: 16,
                ),
                itemCount: admins.length,
                itemBuilder: (context, index) {
                  final admin = admins[index];
                  return Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppTheme.primary,
                        backgroundImage: admin.imagePath != null
                            ? FileImage(File(admin.imagePath!))
                            : null,
                        child: admin.imagePath == null
                            ? const Icon(Icons.person, color: Colors.white)
                            : null,
                      ),
                      title: Text(
                        admin.username,
                        textAlign: TextAlign.right,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.edit_outlined,
                              color: AppTheme.primary,
                            ),
                            onPressed: () => _openEditPage(admin),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Colors.red,
                            ),
                            onPressed: () => _confirmDelete(admin),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
