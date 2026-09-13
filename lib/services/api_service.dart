import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:html/parser.dart' as html_parser;
import '../models/app_models.dart';

class ApiService {
  static const String baseUrl = 'https://www.88ipa.com';
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;

  late Dio _dio;
  SharedPreferences? _prefs;
  Map<String, String> _cookies = {};

  ApiService._internal() {
    _dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 20),
      responseType: ResponseType.plain, // 关键：始终返回原始字符串，不自动解析JSON
      validateStatus: (status) => status != null && status < 500,
      followRedirects: false,
      headers: {
        'User-Agent':
            'Mozilla/5.0 (Android 13; Mobile) AppleWebKit/537.36 Chrome/128.0.0.0 Mobile Safari/537.36',
      },
    ));
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        if (_cookies.isNotEmpty) {
          options.headers['Cookie'] = _cookies.entries
              .map((e) => '${e.key}=${e.value}')
              .join('; ');
        }
        handler.next(options);
      },
      onResponse: (response, handler) {
        final setCookie = response.headers['set-cookie'];
        if (setCookie != null) {
          for (var c in setCookie) {
            final pairs = c.split(',');
            for (var pair in pairs) {
              final parts = pair.trim().split(';').first.trim();
              final eq = parts.indexOf('=');
              if (eq > 0) {
                final name = parts.substring(0, eq).trim();
                final value = parts.substring(eq + 1).trim();
                if (name.isNotEmpty && !name.startsWith('\$')) {
                  _cookies[name] = value;
                }
              }
            }
          }
          _saveCookies();
        }
        handler.next(response);
      },
    ));
  }

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    final saved = _prefs!.getString('cookies');
    if (saved != null) {
      try {
        final Map<String, dynamic> map = jsonDecode(saved);
        _cookies = map.map((k, v) => MapEntry(k, v.toString()));
      } catch (_) {}
    }
  }

  Future<void> _saveCookies() async {
    await _prefs?.setString('cookies', jsonEncode(_cookies));
  }

  bool get isLoggedIn => _cookies.isNotEmpty;

  Future<void> logout() async {
    _cookies.clear();
    await _prefs?.remove('cookies');
    await _prefs?.remove('user_email');
  }

  /// 统一解析API响应：如果返回HTML说明未登录，如果是JSON则解析
  Map<String, dynamic>? _parseApiResponse(String body) {
    final trimmed = body.trim();
    if (trimmed.startsWith('<')) return null; // HTML登录页
    try {
      return jsonDecode(trimmed) as Map<String, dynamic>;
    } catch (_) {
      return {'__parse_error__': body};
    }
  }

  // ============ 登录 ============
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await _dio.post(
        '$baseUrl/user/api/login',
        data: {
          'userMail': email,
          'userPass': password,
        },
        options: Options(
          headers: {
            'X-Requested-With': 'XMLHttpRequest',
            'Referer': '$baseUrl/user/login.html',
          },
          contentType: Headers.formUrlEncodedContentType,
        ),
      );
      final body = response.data.toString();
      final data = _parseApiResponse(body);
      if (data == null) {
        return {'success': false, 'message': '登录失败：返回异常页面'};
      }
      if (data['__parse_error__'] != null) {
        return {'success': false, 'message': '响应解析失败'};
      }
      final status = data['status'] ?? '';
      final msg = data['message'] ?? '';
      if (status == 'success') {
        await _prefs?.setString('user_email', email);
        return {'success': true, 'message': msg.toString()};
      }
      return {'success': false, 'message': msg.toString()};
    } catch (e) {
      return {'success': false, 'message': '网络错误: $e'};
    }
  }

  // ============ 签到 ============
  // 注意：jQuery原版签到POST没有body，没有Content-Type
  Future<Map<String, dynamic>> signIn() async {
    try {
      final response = await _dio.post(
        '$baseUrl/user/api/sign_in',
        options: Options(
          headers: {
            'X-Requested-With': 'XMLHttpRequest',
            'Referer': '$baseUrl/user/dashboard.html',
          },
          // 不设置contentType，不发送body —— 模拟jQuery无data的POST
        ),
      );
      final body = response.data.toString();
      final data = _parseApiResponse(body);
      if (data == null) {
        return {'success': false, 'message': '__NOT_LOGGED_IN__'};
      }
      if (data['__parse_error__'] != null) {
        return {'success': false, 'message': '签到响应解析失败'};
      }
      final status = data['status'] ?? '';
      final msg = data['message'] ?? '';
      return {'success': status == 'success', 'message': msg.toString()};
    } catch (e) {
      return {'success': false, 'message': '网络错误: $e'};
    }
  }

  // ============ 获取HTML页面 ============
  Future<String?> _fetchHtml(String path) async {
    try {
      final response = await _dio.get(
        '$baseUrl$path',
        options: Options(
          headers: {'Referer': '$baseUrl/'},
          followRedirects: true,
        ),
      );
      return response.data.toString();
    } catch (_) {
      return null;
    }
  }

  // ============ 解析应用列表 ============
  List<AppInfo> _parseAppList(String html) {
    final document = html_parser.parse(html);
    final List<AppInfo> apps = [];
    final seen = <String>{};

    final containers = document.querySelectorAll('div.mdui-container-fluid');
    for (var container in containers) {
      final linkEl = container.querySelector('a[href*="/application/"]');
      if (linkEl == null) continue;
      final href = linkEl.attributes['href'] ?? '';
      final id = href.replaceAll('/application/', '').replaceAll('.html', '');
      if (id.isEmpty || !RegExp(r'^\d+$').hasMatch(id)) continue;
      if (seen.contains(id)) continue;
      seen.add(id);

      String iconUrl = '';
      final imgEl = container.querySelector('img');
      if (imgEl != null) {
        iconUrl = imgEl.attributes['src'] ?? '';
        if (iconUrl.startsWith('//')) iconUrl = 'https:$iconUrl';
        if (iconUrl.startsWith('/')) iconUrl = '$baseUrl$iconUrl';
      }

      String name = '';
      String version = '';
      final titleEl = container.querySelector('.is-app-category-title');
      if (titleEl != null) {
        final raw = titleEl.text.trim();
        final match = RegExp(r'^(.*?)\s+(\d[\d.]*)$').firstMatch(raw);
        if (match != null) {
          name = match.group(1)!.trim();
          version = match.group(2)!.trim();
        } else {
          name = raw;
        }
      }

      String size = '';
      String iosVer = '';
      final captionEl = container.querySelector('.mdui-typo-caption');
      if (captionEl != null) {
        final raw = captionEl.text.trim();
        final sizeMatch = RegExp(r'([\d.]+\s*(?:KB|MB|GB))').firstMatch(raw);
        if (sizeMatch != null) size = sizeMatch.group(1)!;
        final iosMatch = RegExp(r'iOS\s+([\d.]+)').firstMatch(raw);
        if (iosMatch != null) iosVer = 'iOS ${iosMatch.group(1)}+';
      }

      if (name.isNotEmpty) {
        apps.add(AppInfo(
          id: id,
          name: name,
          version: version,
          size: size,
          iosVersion: iosVer,
          iconUrl: iconUrl,
        ));
      }
    }
    return apps;
  }

  Future<List<AppInfo>> fetchAppList(String path) async {
    final html = await _fetchHtml(path);
    if (html == null) return [];
    return _parseAppList(html);
  }

  Future<List<AppInfo>> searchApps(String keyword) async {
    final encoded = Uri.encodeComponent(keyword);
    final html = await _fetchHtml('/search.html?keyword=$encoded');
    if (html == null) return [];
    return _parseAppList(html);
  }

  // ============ 应用详情 ============
  Future<AppDetail?> fetchAppDetail(String appId) async {
    final html = await _fetchHtml('/application/$appId.html');
    if (html == null) return null;
    final document = html_parser.parse(html);

    String name = '';
    final titleEl = document.querySelector('title');
    if (titleEl != null) {
      name = titleEl.text.split(' - ').first.trim();
    }

    String iconUrl = '';
    final imgEls = document.querySelectorAll('img');
    for (var img in imgEls) {
      final src = img.attributes['src'] ?? '';
      if (src.contains('/data/icon/')) {
        iconUrl = src.startsWith('http') ? src : '$baseUrl$src';
        break;
      }
    }

    String version = '';
    String size = '';
    final captions =
        document.querySelectorAll('div.mdui-float-left.mdui-typo-caption-opacity');
    for (var i = 0; i < captions.length; i++) {
      final text = captions[i].text.trim();
      final next = captions[i].nextElementSibling;
      if (text.contains('版本') && next != null) version = next.text.trim();
      if (text.contains('大小') && next != null) size = next.text.trim();
    }

    String iosVer = '';
    final iosEl = document.querySelector('div.mdui-float-right.mdui-typo-caption');
    if (iosEl != null) iosVer = iosEl.text.trim();

    final screenshots = <String>[];
    document.querySelectorAll('img[src*="/data/preview/"]').forEach((img) {
      final src = img.attributes['src'] ?? '';
      if (src.isNotEmpty) {
        screenshots.add(src.startsWith('http') ? src : '$baseUrl$src');
      }
    });

    String description = '';
    final descEl = document.querySelector('p[style*="white-space"]');
    if (descEl != null) description = descEl.text.trim();

    return AppDetail(
      id: appId,
      name: name,
      version: version,
      size: size,
      iosVersion: iosVer,
      iconUrl: iconUrl,
      screenshots: screenshots,
      description: description,
    );
  }

  // ============ 用户信息（积分） ============
  Future<UserInfo?> fetchUserInfo() async {
    final html = await _fetchHtml('/user/dashboard.html');
    if (html == null) return null;

    String email = _prefs?.getString('user_email') ?? '';
    int points = 0;

    // 从HTML中提取积分 —— 多种模式匹配
    // 模式1: "积分" 后面跟数字
    final p1 = RegExp(r'积分[：:\s]*([0-9,]+)').firstMatch(html);
    if (p1 != null) points = int.tryParse(p1.group(1)!.replaceAll(',', '')) ?? 0;

    // 模式2: 数字 + "积分"
    if (points == 0) {
      final p2 = RegExp(r'([0-9,]+)\s*积分').firstMatch(html);
      if (p2 != null) points = int.tryParse(p2.group(1)!.replaceAll(',', '')) ?? 0;
    }

    // 模式3: 剩余/可用 积分
    if (points == 0) {
      final p3 = RegExp(r'(?:剩余|可用|我的)?\s*积分[：:\s]*([0-9,]+)',
              caseSensitive: false)
          .firstMatch(html);
      if (p3 != null) points = int.tryParse(p3.group(1)!.replaceAll(',', '')) ?? 0;
    }

    // 提取邮箱
    final emailMatch = RegExp(r'[\w.+-]+@[\w-]+\.[\w.-]+').firstMatch(html);
    if (emailMatch != null) email = emailMatch.group(0)!;

    return UserInfo(email: email, points: points, rawHtml: html);
  }

  // ============ 获取下载链接 ============
  Future<Map<String, dynamic>> getDownloadLink(String appId) async {
    try {
      final response = await _dio.post(
        '$baseUrl/user/api/down_the_file',
        data: {'appId': appId},
        options: Options(
          headers: {
            'X-Requested-With': 'XMLHttpRequest',
            'Referer': '$baseUrl/select_download_method/$appId.html',
          },
          contentType: Headers.formUrlEncodedContentType,
        ),
      );
      final body = response.data.toString();
      final data = _parseApiResponse(body);
      if (data == null) {
        return {'success': false, 'message': '__NOT_LOGGED_IN__'};
      }
      if (data['__parse_error__'] != null) {
        return {'success': false, 'message': '服务器返回格式异常，请重试'};
      }
      if (data['status'] == 'success') {
        final link = data['data']?['ipa_download_link'] ?? '';
        final cost = data['data']?['cost'] ?? data['data']?['score'] ?? 0;
        return {'success': true, 'link': link.toString(), 'cost': cost};
      }
      return {
        'success': false,
        'message': data['message'] ?? '获取下载链接失败'
      };
    } catch (e) {
      return {'success': false, 'message': '网络错误: $e'};
    }
  }

  // ============ 获取在线安装plist ============
  Future<Map<String, dynamic>> getInstallPlist(String appId) async {
    try {
      final response = await _dio.post(
        '$baseUrl/user/api/install_the_ipa',
        data: {'appId': appId},
        options: Options(
          headers: {
            'X-Requested-With': 'XMLHttpRequest',
            'Referer': '$baseUrl/select_download_method/$appId.html',
          },
          contentType: Headers.formUrlEncodedContentType,
        ),
      );
      final body = response.data.toString();
      final data = _parseApiResponse(body);
      if (data == null) {
        return {'success': false, 'message': '__NOT_LOGGED_IN__'};
      }
      if (data['__parse_error__'] != null) {
        return {'success': false, 'message': '服务器返回格式异常，请重试'};
      }
      if (data['status'] == 'success') {
        final link = data['data']?['plist_link'] ?? '';
        return {'success': true, 'link': link.toString()};
      }
      return {
        'success': false,
        'message': data['message'] ?? '获取安装链接失败'
      };
    } catch (e) {
      return {'success': false, 'message': '网络错误: $e'};
    }
  }

  String get savedEmail => _prefs?.getString('user_email') ?? '';
}
