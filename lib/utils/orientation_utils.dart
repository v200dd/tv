import 'dart:io';
import 'dart:ui';

import 'package:flutter/services.dart';

/// 全屏时固定的横屏方向。
///
/// Flutter 的 [DeviceOrientation.landscapeLeft] / [DeviceOrientation.landscapeRight]
/// 在不同人的直觉里指向相反，所以这里用「往左 / 往右」描述用户实际的转动方向，
/// 并且做成可切换的设置项：方向反了在 App 里改一下就行。
enum LandscapeDirection {
  /// 手机往左转（顶边朝左）。
  left(DeviceOrientation.landscapeLeft),

  /// 手机往右转（顶边朝右）。
  right(DeviceOrientation.landscapeRight);

  const LandscapeDirection(this.orientation);

  final DeviceOrientation orientation;

  static LandscapeDirection fromName(String? value) =>
      value == 'right' ? LandscapeDirection.right : LandscapeDirection.left;
}

/// Phones return to portrait outside fullscreen. Tablets restore system policy.
/// Explicit fullscreen requests landscape on both phones and tablets.
class OrientationUtils {
  const OrientationUtils._();

  /// 当前生效的全屏方向，默认往左。设置页可改。
  static LandscapeDirection _direction = LandscapeDirection.left;

  static LandscapeDirection get direction => _direction;

  /// 设置项变更时调用。只改偏好，不主动转屏。
  static void setDirection(LandscapeDirection direction) {
    _direction = direction;
  }

  static bool get _isMobile => Platform.isAndroid || Platform.isIOS;

  /// 平板不锁朝向。用短边判断，避免横屏时被误判成手机。
  static bool get _isPhone {
    if (!_isMobile) return false;
    final view = PlatformDispatcher.instance.implicitView;
    if (view == null) return true;
    final size = view.physicalSize / view.devicePixelRatio;
    return size.shortestSide < 600;
  }

  /// 回到竖屏：非播放页、播放页非全屏、以及退出全屏时。
  static Future<void> lockPortrait() async {
    if (!_isMobile) return;
    await SystemChrome.setPreferredOrientations(
      _isPhone ? const [DeviceOrientation.portraitUp] : const [],
    );
  }

  /// 点全屏时转横屏。固定单一方向，避免系统按重力选反。
  static Future<void> forceLandscape() async {
    if (!_isMobile) return;
    await SystemChrome.setPreferredOrientations([_direction.orientation]);
  }
}
