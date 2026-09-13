import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/app_models.dart';
import 'detail_screen.dart';

class AppListItem extends StatelessWidget {
  final AppInfo app;
  const AppListItem({super.key, required this.app});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: CachedNetworkImage(
            imageUrl: app.iconUrl,
            width: 52,
            height: 52,
            fit: BoxFit.cover,
            placeholder: (_, __) => Container(
              width: 52,
              height: 52,
              color: Colors.grey[200],
              child: const Icon(Icons.apps),
            ),
            errorWidget: (_, __, ___) => Container(
              width: 52,
              height: 52,
              color: Colors.grey[200],
              child: const Icon(Icons.android),
            ),
          ),
        ),
        title: Text(
          app.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        subtitle: Text(
          [
            if (app.version.isNotEmpty) 'v${app.version}',
            if (app.size.isNotEmpty) app.size,
            if (app.iosVersion.isNotEmpty) app.iosVersion,
          ].join('  ·  '),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        trailing: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Text(
            '获取',
            style: TextStyle(color: Colors.white, fontSize: 13),
          ),
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => DetailScreen(appId: app.id, appName: app.name),
            ),
          );
        },
      ),
    );
  }
}
