import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:selene/utils/orientation_utils.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final calls = <MethodCall>[];
  setUp(() {
    calls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
      calls.add(call);
      return null;
    });
  });
  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });
  // Tests run on the host OS: the plugin must never issue mobile orientation
  // requests on a desktop. Actual iPad/Android orientation needs device QA.
  test('desktop does not issue mobile orientation requests', () async {
    await OrientationUtils.forceLandscape();
    await OrientationUtils.lockPortrait();
    expect(calls, isEmpty);
  });
  test('landscape preference remains selectable', () {
    OrientationUtils.setDirection(LandscapeDirection.right);
    expect(OrientationUtils.direction.orientation,
        DeviceOrientation.landscapeRight);
    OrientationUtils.setDirection(LandscapeDirection.left);
  });
}
