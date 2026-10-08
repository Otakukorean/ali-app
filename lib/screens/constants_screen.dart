import 'dart:io';

import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../models/constants_entry.dart';
import '../services/constants_service.dart';
import 'constants_entry_form_screen.dart';

class ConstantsScreen extends StatefulWidget {
  const ConstantsScreen({super.key});

  @override
  State<ConstantsScreen> createState() => _ConstantsScreenState();
}

class _ConstantsScreenState extends State<ConstantsScreen> {
  late Future<List<ConstantsEntry>> _entriesFuture;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    setState(() {
      _entriesFuture = ConstantsService.instance.getEntries();
    });
  }

  Future<void> _openAddPage() async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const ConstantsEntryFormScreen()),
    );
    if (saved == true) _reload();
  }

  Future<void> _confirmDelete(ConstantsEntry entry) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف السجل'),
        content: Text('هل أنت متأكد من حذف "${entry.name}"؟'),
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
      await ConstantsService.instance.deleteEntry(entry.id);
      _reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الثوابت')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddPage,
        icon: const Icon(Icons.add),
        label: const Text('إضافة'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              children: [
                const _ConstantsHeaderCard(),
                const SizedBox(height: 24),
                FutureBuilder<List<ConstantsEntry>>(
                  future: _entriesFuture,
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Padding(
                        padding: EdgeInsets.only(top: 40),
                        child: CircularProgressIndicator(),
                      );
                    }

                    final entries = snapshot.data!;
                    if (entries.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.only(top: 40),
                        child: Text('لا توجد بيانات بعد'),
                      );
                    }

                    return Card(
                      clipBehavior: Clip.antiAlias,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          columns: const [
                            DataColumn(label: Text('')),
                            DataColumn(label: Text('الاسم')),
                            DataColumn(label: Text('رقم الهاتف')),
                            DataColumn(label: Text('IP')),
                            DataColumn(label: Text('')),
                          ],
                          rows: entries.map((entry) {
                            return DataRow(
                              cells: [
                                DataCell(_EntryThumbnail(imagePath: entry.imagePath)),
                                DataCell(Text(entry.name)),
                                DataCell(Text(entry.phone)),
                                DataCell(Text(entry.ip)),
                                DataCell(
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                                    onPressed: () => _confirmDelete(entry),
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EntryThumbnail extends StatelessWidget {
  const _EntryThumbnail({this.imagePath});

  final String? imagePath;

  @override
  Widget build(BuildContext context) {
    if (imagePath == null) {
      return CircleAvatar(
        radius: 18,
        backgroundColor: Colors.grey.shade200,
        child: Icon(Icons.image_outlined, size: 18, color: Colors.grey.shade500),
      );
    }
    return CircleAvatar(
      radius: 18,
      backgroundImage: FileImage(File(imagePath!)),
    );
  }
}

class _ConstantsHeaderCard extends StatelessWidget {
  const _ConstantsHeaderCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: const [
            _HeaderRow(label: 'IP', value: '192.168.1.10'),
            Divider(height: 28),
            _HeaderRow(label: 'واتساب', value: '+964 770 123 4567'),
            Divider(height: 28),
            _HeaderRow(label: 'ثابت', value: '07701234567'),
          ],
        ),
      ),
    );
  }
}

class _HeaderRow extends StatelessWidget {
  const _HeaderRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppTheme.primary,
          ),
        ),
        const SizedBox(width: 16),
        Text(
          value,
          style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
        ),
      ],
    );
  }
}
