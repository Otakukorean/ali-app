import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../models/site.dart';
import '../services/site_service.dart';
import 'numbers_screen.dart';

class SitesScreen extends StatefulWidget {
  const SitesScreen({super.key});

  @override
  State<SitesScreen> createState() => _SitesScreenState();
}

class _SitesScreenState extends State<SitesScreen> {
  late Future<List<Site>> _sitesFuture;

  @override
  void initState() {
    super.initState();
    _sitesFuture = SiteService.instance.getSites();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('المواقع')),
      body: FutureBuilder<List<Site>>(
        future: _sitesFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final sites = snapshot.data!;
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  vertical: 24,
                  horizontal: 16,
                ),
                children: sites.map((site) => _SiteCard(site: site)).toList(),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SiteCard extends StatelessWidget {
  const _SiteCard({required this.site});

  final Site site;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => NumbersScreen(site: site)));
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
          child: Row(
            children: [
              const Icon(Icons.chevron_left, color: AppTheme.primary),
              Expanded(
                child: Text(
                  site.name,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primary,
                  ),
                ),
              ),
              const Icon(Icons.location_city, color: AppTheme.gold),
            ],
          ),
        ),
      ),
    );
  }
}
