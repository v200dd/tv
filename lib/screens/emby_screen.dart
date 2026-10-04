import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/user_data_service.dart';
import '../utils/font_utils.dart';

/// Emby 入口页。网页端已提供多源、媒体库分类和播放能力，客户端直接打开同一服务。
class EmbyScreen extends StatefulWidget {
  const EmbyScreen({super.key});

  @override
  State<EmbyScreen> createState() => _EmbyScreenState();
}

class _EmbyScreenState extends State<EmbyScreen> {
  bool _isOpening = false;

  Future<void> _openEmby() async {
    if (_isOpening) return;
    setState(() => _isOpening = true);
    try {
      final serverUrl = await UserDataService.getServerUrl() ??
          UserDataService.defaultServerUrl;
      final uri = Uri.parse('${serverUrl.replaceAll(RegExp(r'/+$'), '')}/emby');
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } finally {
      if (mounted) setState(() => _isOpening = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF2c3e50);
    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              children: [
                Icon(LucideIcons.library,
                    size: 64, color: const Color(0xFF27ae60)),
                const SizedBox(height: 16),
                Text('Emby',
                    style: FontUtils.poppins(
                        fontSize: 28,
                        fontWeight: FontWeight.w600,
                        color: textColor)),
                const SizedBox(height: 12),
                Text(
                  '电影、电视剧等媒体库分类已接入网页播放器。点击进入 Emby，即可使用媒体库筛选、搜索和播放。',
                  textAlign: TextAlign.center,
                  style: FontUtils.poppins(
                      fontSize: 15,
                      color: isDark ? Colors.white70 : Colors.black54),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isOpening ? null : _openEmby,
                    icon: const Icon(LucideIcons.externalLink, size: 18),
                    label: Text(_isOpening ? '正在打开...' : '打开 Emby 媒体库'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF27ae60),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
