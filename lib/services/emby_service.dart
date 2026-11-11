import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/search_result.dart';
import 'user_data_service.dart';

/// Emby uses LunaTV's authenticated API, not the public CMS/local-search API.
class EmbyService {
  static bool isSource(String source) =>
      source == 'emby' || source.startsWith('emby_');

  static Uri apiUri(
    String base,
    String path, [
    Map<String, String> query = const {},
  ]) =>
      Uri.parse('${base.replaceAll(RegExp(r'/+$'), '')}$path')
          .replace(queryParameters: query.isEmpty ? null : query);

  static Future<dynamic> get(
    String path, {
    Map<String, String> query = const {},
  }) async {
    final base =
        await UserDataService.getServerUrl() ??
        UserDataService.defaultServerUrl;
    final cookies = await UserDataService.getCookies();
    final response = await http
        .get(
          apiUri(base, path, query),
          headers: {
            'Accept': 'application/json',
            if (cookies != null && cookies.isNotEmpty) 'Cookie': cookies,
          },
        )
        .timeout(const Duration(seconds: 30));
    return decodeResponse(response);
  }

  static dynamic decodeResponse(http.Response response) {
    dynamic data;
    try {
      data = jsonDecode(response.body);
    } on FormatException {
      throw Exception('Emby 接口返回非 JSON 内容 (${response.statusCode})');
    }
    // Older LunaTV list routes return HTTP 200 even when the upstream failed.
    if (response.statusCode < 200 ||
        response.statusCode >= 300 ||
        (data is Map && data['error'] != null)) {
      throw Exception(
        data is Map
            ? data['error']?.toString() ?? 'Emby 请求失败 (${response.statusCode})'
            : 'Emby 请求失败 (${response.statusCode})',
      );
    }
    return data;
  }

  static Future<List<SearchResult>> detail(String source, String id) async {
    final data = await get('/api/detail', query: {'source': source, 'id': id});
    return [SearchResult.fromJson(data as Map<String, dynamic>)];
  }

  /// Resolve the backend's relative proxy URL; never send LunaTV cookies to
  /// an external Emby/CDN host. Direct Emby URLs already carry their api_key.
  static ({String url, Map<String, String> headers}) mediaRequest(
    String base,
    String url,
    String? cookies,
  ) {
    final baseUri = Uri.parse('${base.replaceAll(RegExp(r'/+$'), '')}/');
    final resolved = baseUri.resolve(url);
    final firstPartyProxy =
        resolved.origin == baseUri.origin &&
        resolved.path.startsWith('/api/emby/play/');
    return (
      url: resolved.toString(),
      headers: {
        if (firstPartyProxy && cookies != null && cookies.isNotEmpty)
          'Cookie': cookies,
      },
    );
  }
}
