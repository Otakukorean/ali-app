import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../models/site.dart';
import '../models/site_number.dart';
import '../models/site_prefix.dart';
import '../services/site_service.dart';
import 'constants_screen.dart';

class NumbersScreen extends StatefulWidget {
  const NumbersScreen({super.key, required this.site});

  final Site site;

  @override
  State<NumbersScreen> createState() => _NumbersScreenState();
}

class _NumbersScreenState extends State<NumbersScreen> {
  late Future<List<SitePrefix>> _prefixesFuture;
  final _numberSearchController = TextEditingController();
  String? _searchError;

  @override
  void initState() {
    super.initState();
    _prefixesFuture = SiteService.instance.getPrefixesForSite(widget.site.id);
  }

  @override
  void dispose() {
    _numberSearchController.dispose();
    super.dispose();
  }

  String _normalizeNumber(String value) {
    const arabicDigits = '٠١٢٣٤٥٦٧٨٩';
    const persianDigits = '۰۱۲۳۴۵۶۷۸۹';
    var normalized = value.trim();
    for (var index = 0; index < 10; index++) {
      normalized = normalized
          .replaceAll(arabicDigits[index], '$index')
          .replaceAll(persianDigits[index], '$index');
    }
    return normalized;
  }

  Future<void> _searchNumber() async {
    final number = _normalizeNumber(_numberSearchController.text);
    if (number.isEmpty) {
      setState(() => _searchError = 'الرجاء إدخال الرقم');
      return;
    }

    final siteNumber = await SiteService.instance.findNumberForSite(
      widget.site.id,
      number,
    );

    if (!mounted) return;
    if (siteNumber == null) {
      setState(() {
        _searchError = 'الرقم غير موجود في هذا الموقع';
      });
      return;
    }

    setState(() => _searchError = null);
    FocusScope.of(context).unfocus();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ConstantsScreen(
          siteId: widget.site.id,
          siteNumberId: siteNumber.id,
          siteName: widget.site.name,
          number: siteNumber.number,
        ),
      ),
    );
  }

  void _openNumbersSheet(BuildContext context, SitePrefix sitePrefix) {
    final numbersFuture = SiteService.instance.getNumbersForPrefix(
      sitePrefix.id,
    );
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return DraggableScrollableSheet(
          initialChildSize: 0.85,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    '${widget.site.name} — ${sitePrefix.prefix}'
                    '00 إلى ${sitePrefix.prefix}'
                    '99',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primary,
                    ),
                  ),
                ),
                Expanded(
                  child: FutureBuilder<List<SiteNumber>>(
                    future: numbersFuture,
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final numbers = snapshot.data!;
                      return GridView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 5,
                              mainAxisSpacing: 10,
                              crossAxisSpacing: 10,
                              childAspectRatio: 1.6,
                            ),
                        itemCount: numbers.length,
                        itemBuilder: (context, index) {
                          final siteNumber = numbers[index];
                          return _NumberChip(
                            number: siteNumber.number,
                            onTap: () => _showNumberDetail(context, siteNumber),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showNumberDetail(BuildContext context, SiteNumber siteNumber) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تفاصيل الرقم'),
        content: Text(
          siteNumber.number,
          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        actions: [
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              Future.microtask(() {
                if (!mounted) return;
                Navigator.of(this.context).push(
                  MaterialPageRoute(
                    builder: (_) => ConstantsScreen(
                      siteId: widget.site.id,
                      siteNumberId: siteNumber.id,
                      siteName: widget.site.name,
                      number: siteNumber.number,
                    ),
                  ),
                );
              });
            },
            icon: const Icon(Icons.dashboard_customize_outlined),
            label: const Text('الثوابت'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.site.name)),
      body: FutureBuilder<List<SitePrefix>>(
        future: _prefixesFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final prefixes = snapshot.data!;
          if (prefixes.isEmpty) {
            return const Center(child: Text('لا توجد أرقام بعد'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: TextField(
                    key: const Key('numberSearchField'),
                    controller: _numberSearchController,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => _searchNumber(),
                    onChanged: (_) {
                      if (_searchError != null) {
                        setState(() => _searchError = null);
                      }
                    },
                    decoration: InputDecoration(
                      labelText: 'البحث برقم كامل',
                      hintText: 'مثال: 11100',
                      errorText: _searchError,
                      prefixIcon: IconButton(
                        key: const Key('numberSearchButton'),
                        tooltip: 'بحث',
                        onPressed: _searchNumber,
                        icon: const Icon(Icons.search),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Center(
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 16,
                    runSpacing: 16,
                    children: prefixes
                        .map(
                          (sitePrefix) => SizedBox(
                            width: 220,
                            child: _PrefixCard(
                              prefix: sitePrefix.prefix,
                              onTap: () =>
                                  _openNumbersSheet(context, sitePrefix),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _PrefixCard extends StatelessWidget {
  const _PrefixCard({required this.prefix, required this.onTap});

  final String prefix;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.numbers, size: 32, color: AppTheme.gold),
              const SizedBox(height: 10),
              Text(
                '${prefix}xx',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primary,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'اضغط لعرض كل الأرقام من ${prefix}00 إلى ${prefix}99',
                style: TextStyle(color: Colors.grey.shade600),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NumberChip extends StatelessWidget {
  const _NumberChip({required this.number, required this.onTap});

  final String number;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.background,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppTheme.primary.withValues(alpha: 0.25)),
          ),
          child: Text(
            number,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: AppTheme.primary,
            ),
          ),
        ),
      ),
    );
  }
}
