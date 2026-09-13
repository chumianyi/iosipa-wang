class AppInfo {
  final String id;
  final String name;
  final String version;
  final String size;
  final String iosVersion;
  final String iconUrl;

  AppInfo({
    required this.id,
    required this.name,
    required this.version,
    required this.size,
    required this.iosVersion,
    required this.iconUrl,
  });
}

class AppDetail {
  final String id;
  final String name;
  final String version;
  final String size;
  final String iosVersion;
  final String iconUrl;
  final List<String> screenshots;
  final String description;

  AppDetail({
    required this.id,
    required this.name,
    required this.version,
    required this.size,
    required this.iosVersion,
    required this.iconUrl,
    required this.screenshots,
    required this.description,
  });
}

class UserInfo {
  final String email;
  final int points;
  final String rawHtml;

  UserInfo({required this.email, required this.points, required this.rawHtml});
}
