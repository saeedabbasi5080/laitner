import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:recall/core/localization/app_strings.dart';
import 'package:recall/core/theme/app_theme.dart';
import 'package:recall/data/utils/card_media_store_factory.dart';
import 'package:recall/domain/entities/card_media.dart';
import 'package:recall/presentation/widgets/local_file_image.dart';

class StudyCardMediaList extends StatelessWidget {
  const StudyCardMediaList({super.key, required this.media});

  final List<CardMedia> media;

  @override
  Widget build(BuildContext context) {
    if (media.isEmpty) return const SizedBox.shrink();
    return Column(
      children: [
        for (final item in media) ...[
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () {},
            child: item.isImage
                ? _StudyImage(media: item)
                : _StudyAudio(media: item),
          ),
        ],
      ],
    );
  }
}

class _StudyImage extends StatelessWidget {
  const _StudyImage({required this.media});

  final CardMedia media;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: createCardMediaStore().absolutePath(media),
      builder: (context, snapshot) {
        final path = snapshot.data;
        if (path == null) {
          return const SizedBox.shrink();
        }
        return ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: localFileImage(path, fit: BoxFit.contain, height: 160),
        );
      },
    );
  }
}

class _StudyAudio extends StatefulWidget {
  const _StudyAudio({required this.media});

  final CardMedia media;

  @override
  State<_StudyAudio> createState() => _StudyAudioState();
}

class _StudyAudioState extends State<_StudyAudio> {
  final AudioPlayer _player = AudioPlayer();
  bool _playing = false;

  @override
  void initState() {
    super.initState();
    _player.onPlayerComplete.listen((_) {
      if (mounted) setState(() => _playing = false);
    });
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _toggle() async {
    if (kIsWeb) return;
    if (_playing) {
      await _player.stop();
      if (mounted) setState(() => _playing = false);
      return;
    }
    final path = await createCardMediaStore().absolutePath(widget.media);
    if (path == null || !mounted) return;
    await _player.play(DeviceFileSource(path));
    if (mounted) setState(() => _playing = true);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.recallColors;
    final label = widget.media.originalName.trim().isEmpty
        ? (widget.media.kind == CardMediaKind.voice
            ? AppStrings.attachVoice
            : AppStrings.attachAudio)
        : widget.media.originalName;
    return Material(
      color: colors.muted,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: _toggle,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _playing
                    ? Icons.stop_circle_outlined
                    : Icons.play_circle_outline,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  _playing ? AppStrings.stopPlayback : AppStrings.playAttachment,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: colors.mutedForeground,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
