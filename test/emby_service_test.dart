import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:selene/services/emby_service.dart';

void main() {
  test('list query preserves source key and parent independently of pageSize',
      () {
    final uri = EmbyService.apiUri('https://tv.example/', '/api/emby/list', {
      'page': '1',
      'pageSize': '40',
      'sortOrder': 'Ascending',
      'embyKey': 'source /?&中文',
      'parentId': 'library&1',
    });
    expect(uri.queryParameters['sortOrder'], 'Ascending');
    expect(uri.queryParameters['embyKey'], 'source /?&中文');
    expect(uri.queryParameters['parentId'], 'library&1');
  });

  test('backend proxy is absolute and carries the login cookie', () {
    final request = EmbyService.mediaRequest('https://tv.example/',
        '/api/emby/play/proxy/video?itemId=1&embyKey=two', 'session=value');
    expect(request.url,
        'https://tv.example/api/emby/play/proxy/video?itemId=1&embyKey=two');
    expect(request.headers, {'Cookie': 'session=value'});
  });

  test('direct streams keep query auth but never receive LunaTV cookies', () {
    final request = EmbyService.mediaRequest(
        'https://tv.example',
        'https://emby.example/Videos/1/stream?api_key=TOKEN&static=true',
        'session=value');
    expect(Uri.parse(request.url).queryParameters['api_key'], 'TOKEN');
    expect(request.headers, isEmpty);
    expect(
        EmbyService.mediaRequest(
                'https://tv.example',
                'https://other.example/api/emby/play/proxy/video',
                'session=value')
            .headers,
        isEmpty);
  });

  test('200 error envelopes are surfaced rather than displayed as empty media',
      () {
    expect(
        () => EmbyService.decodeResponse(
            http.Response('{"error":"upstream failed","list":[]}', 200)),
        throwsA(predicate((e) => e.toString().contains('upstream failed'))));
  });

  test('non JSON and HTTP auth failures retain an actionable error', () {
    expect(
        () => EmbyService.decodeResponse(
            http.Response('<html>error</html>', 502)),
        throwsException);
    expect(
        () => EmbyService.decodeResponse(http.Response('{"error":"not logged in"}', 401)),
        throwsException);
  });

  test('only actual Emby source identities select the Emby detail route', () {
    expect(EmbyService.isSource('emby'), isTrue);
    expect(EmbyService.isSource('emby_second'), isTrue);
    expect(EmbyService.isSource('other_emby'), isFalse);
  });
}
