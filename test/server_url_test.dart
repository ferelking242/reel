import 'package:flutter_test/flutter_test.dart';
import 'package:reel/remote/remote_config_provider.dart';

void main() {
  group('parseServerInput', () {
    test('adds the http scheme when it is missing', () {
      final parsed = parseServerInput('192.168.1.184:4567');
      expect(parsed.url, 'http://192.168.1.184:4567');
      expect(parsed.apiKey, isNull);
    });

    test('drops trailing slashes and a /api suffix', () {
      expect(parseServerInput('http://host:4567/').url, 'http://host:4567');
      expect(parseServerInput('https://host/').url, 'https://host');
      expect(parseServerInput('http://host:4567/api').url, 'http://host:4567');
    });

    test('lifts ?key= out of the URL', () {
      final parsed = parseServerInput(
        'https://abc.lhr.life/?key=ECEAciXeSzD3wBNnk2bM1XgEx6',
      );
      expect(parsed.url, 'https://abc.lhr.life');
      expect(parsed.apiKey, 'ECEAciXeSzD3wBNnk2bM1XgEx6');
    });

    test('keeps a deployment sub-path', () {
      expect(
        parseServerInput('https://example.com/watchtower/').url,
        'https://example.com/watchtower',
      );
    });

    test('returns an empty URL for blank input', () {
      expect(parseServerInput('   ').url, isEmpty);
    });
  });
}
