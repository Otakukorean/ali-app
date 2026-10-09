import 'dart:io';

import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../models/constants_entry.dart';
import '../models/number_constants.dart';
import '../services/constants_service.dart';
import 'constants_entry_form_screen.dart';
import 'number_constants_form_screen.dart';

class ConstantsScreen extends StatefulWidget {
  const ConstantsScreen({
    super.key,
    this.siteId,
    this.siteNumberId,
    this.siteName,
    this.number,
  });

  final int? siteId;
  final int? siteNumberId;
  final String? siteName;
  final String? number;

  bool get isNumberView =>
      siteId != null && siteNumberId != null && number != null;

  @override
  State<ConstantsScreen> createState() => _ConstantsScreenState();
}

class _ConstantsScreenState extends State<ConstantsScreen> {
  late Future<List<ConstantsEntry>> _entriesFuture;
  Future<NumberConstants>? _numberConstantsFuture;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    setState(() {
      _entriesFuture = ConstantsService.instance.getEntries(
        siteNumberId: widget.siteNumberId,
      );
      if (widget.siteNumberId != null) {
        _numberConstantsFuture = ConstantsService.instance.getNumberConstants(
          widget.siteNumberId!,
        );
      }
    });
  }

  Future<void> _openEditEntry(ConstantsEntry entry) async {
    if (!widget.isNumberView) return;
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => ConstantsEntryFormScreen(
          siteId: widget.siteId!,
          siteNumberId: widget.siteNumberId!,
          siteName: widget.siteName ?? '',
          number: widget.number!,
          entry: entry,
        ),
      ),
    );
    if (saved == true) _reload();
  }

  Future<void> _openEditNumberConstants(NumberConstants constants) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => NumberConstantsFormScreen(
          constants: constants,
          number: widget.number!,
        ),
      ),
    );
    if (saved == true) _reload();
  }

  Future<void> _openAddPage() async {
    if (!widget.isNumberView) return;
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => ConstantsEntryFormScreen(
          siteId: widget.siteId!,
          siteNumberId: widget.siteNumberId!,
          siteName: widget.siteName ?? '',
          number: widget.number!,
        ),
      ),
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
      appBar: AppBar(
        title: Text(
          widget.isNumberView ? 'الثوابت — ${widget.number}' : 'كل الثوابت',
        ),
      ),
      floatingActionButton: widget.isNumberView
          ? FloatingActionButton.extended(
              onPressed: _openAddPage,
              icon: const Icon(Icons.add),
              label: const Text('إضافة'),
            )
          : null,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              children: [
                if (widget.isNumberView) ...[
                  Card(
                    child: ListTile(
                      leading: const Icon(
                        Icons.pin_outlined,
                        color: AppTheme.gold,
                      ),
                      title: Text(
                        widget.number!,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(widget.siteName ?? ''),
                    ),
                  ),
                  const SizedBox(height: 16),
                ] else ...[
                  const Text(
                    'هذه الصفحة تعرض كل الثوابت. لإضافة ثابت جديد، اختر الموقع ثم الرقم.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                ],
                if (_numberConstantsFuture != null)
                  FutureBuilder<NumberConstants>(
                    future: _numberConstantsFuture,
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Padding(
                          padding: EdgeInsets.all(24),
                          child: CircularProgressIndicator(),
                        );
                      }
                      return _ConstantsHeaderCard(
                        constants: snapshot.data!,
                        onEdit: () => _openEditNumberConstants(snapshot.data!),
                      );
                    },
                  ),
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
                          columns: [
                            const DataColumn(label: Text('')),
                            if (!widget.isNumberView) ...const [
                              DataColumn(label: Text('الموقع')),
                              DataColumn(label: Text('الرقم')),
                            ],
                            const DataColumn(label: Text('الاسم')),
                            const DataColumn(label: Text('رقم الهاتف')),
                            const DataColumn(label: Text('IP')),
                            const DataColumn(label: Text('')),
                          ],
                          rows: entries.map((entry) {
                            return DataRow(
                              cells: [
                                DataCell(
                                  _EntryThumbnail(imagePath: entry.imagePath),
                                ),
                                if (!widget.isNumberView) ...[
                                  DataCell(Text(entry.siteName ?? 'غير مرتبط')),
                                  DataCell(Text(entry.number ?? '—')),
                                ],
                                DataCell(Text(entry.name)),
                                DataCell(Text(entry.phone)),
                                DataCell(Text(entry.ip)),
                                DataCell(
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        tooltip: 'تعديل',
                                        icon: const Icon(Icons.edit_outlined),
                                        onPressed: () => _openEditEntry(entry),
                                      ),
                                      IconButton(
                                        tooltip: 'حذف',
                                        icon: const Icon(
                                          Icons.delete_outline,
                                          color: Colors.red,
                                        ),
                                        onPressed: () => _confirmDelete(entry),
                                      ),
                                    ],
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
        child: Icon(
          Icons.image_outlined,
          size: 18,
          color: Colors.grey.shade500,
        ),
      );
    }
    return CircleAvatar(
      radius: 18,
      backgroundImage: FileImage(File(imagePath!)),
    );
  }
}

class _ConstantsHeaderCard extends StatelessWidget {
  const _ConstantsHeaderCard({required this.constants, required this.onEdit});

  final NumberConstants constants;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            CircleAvatar(
              radius: 44,
              backgroundColor: Colors.grey.shade200,
              backgroundImage: constants.imagePath == null
                  ? null
                  : FileImage(File(constants.imagePath!)),
              child: constants.imagePath == null
                  ? Icon(
                      Icons.image_outlined,
                      size: 32,
                      color: Colors.grey.shade500,
                    )
                  : null,
            ),
            const SizedBox(height: 12),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton.icon(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined),
                label: const Text('تعديل الثوابت'),
              ),
            ),
            _HeaderRow(label: 'IP', value: constants.ip),
            const Divider(height: 28),
            _HeaderRow(label: 'واتساب', value: constants.whatsapp),
            const Divider(height: 28),
            _HeaderRow(label: 'ثابت', value: constants.landline),
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
