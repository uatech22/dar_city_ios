import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:dar_city_app/core/theme/dar_theme.dart';
import 'package:dar_city_app/core/widgets/dar_widgets.dart';
import 'package:dar_city_app/features/coach/services/coach_announcement_service.dart';
import 'package:dar_city_app/features/shared/api/feature_api_client.dart';
import 'package:dar_city_app/features/shared/widgets/feature_async_body.dart';

class CoachTeamAnnouncementScreen extends StatelessWidget {
  const CoachTeamAnnouncementScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  Widget build(BuildContext context) {
    return DarScaffold(
      showBottomNav: false,
      title: 'New Announcement',
      leading: IconButton(
        icon: const Icon(Icons.close, color: Colors.white),
        onPressed: () => Navigator.of(context).pop(),
      ),
      showBack: false,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: CoachAnnouncementForm(
          onPublished: () => Navigator.of(context).pop(true),
        ),
      ),
    );
  }
}

class CoachAnnouncementForm extends StatefulWidget {
  const CoachAnnouncementForm({super.key, this.onPublished});

  final VoidCallback? onPublished;

  @override
  State<CoachAnnouncementForm> createState() => _CoachAnnouncementFormState();
}

Map<String, dynamic> _announcementFromPostResponse(Map<String, dynamic> response) {
  final data = response['data'];
  if (data is Map<String, dynamic>) return data;
  if (data is List && data.isNotEmpty && data.first is Map) {
    return data.first as Map<String, dynamic>;
  }
  return response;
}

class _CoachAnnouncementFormState extends State<CoachAnnouncementForm> {
  final _subjectController = TextEditingController();
  final _bodyController = TextEditingController();
  final _picker = ImagePicker();

  String? _imageUrl;
  String? _linkUrl;
  File? _imagePreview;
  bool _submitting = false;
  bool _uploadingImage = false;

  @override
  void dispose() {
    _subjectController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  bool get _isDesktop =>
      !kIsWeb &&
      (Platform.isLinux || Platform.isWindows || Platform.isMacOS);

  Future<String?> _pickImagePath() async {
    if (_isDesktop) {
      const typeGroup = XTypeGroup(
        label: 'Images',
        extensions: ['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp'],
      );
      final file = await openFile(acceptedTypeGroups: [typeGroup]);
      return file?.path;
    }
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    return picked?.path;
  }

  Future<void> _pickAndUploadImage() async {
    String? path;
    try {
      path = await _pickImagePath();
    } catch (e) {
      if (mounted) {
        showFeatureSnackBar(
          context,
          'Could not open file picker: ${featureErrorMessage(e)}',
          isError: true,
        );
      }
      return;
    }
    if (path == null || path.isEmpty) {
      if (mounted && _isDesktop) {
        showFeatureSnackBar(
          context,
          'No image selected. On Linux the file dialog may open behind this window — check your taskbar.',
        );
      }
      return;
    }
    if (!mounted) return;

    final imagePath = path;
    setState(() {
      _uploadingImage = true;
      _imagePreview = File(imagePath);
    });

    try {
      final url = await CoachAnnouncementService.uploadMedia(
        File(imagePath),
        type: 'image',
      );
      if (!mounted) return;
      setState(() => _imageUrl = url);
      showFeatureSnackBar(context, 'Image attached');
    } on FeatureApiException catch (e) {
      if (mounted) {
        setState(() {
          _imageUrl = null;
          _imagePreview = null;
        });
        showFeatureSnackBar(context, featureErrorMessage(e), isError: true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _imageUrl = null;
          _imagePreview = null;
        });
        showFeatureSnackBar(context, featureErrorMessage(e), isError: true);
      }
    } finally {
      if (mounted) setState(() => _uploadingImage = false);
    }
  }

  Future<void> _addLink() async {
    final controller = TextEditingController(text: _linkUrl ?? '');
    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: DarColors.maroonDark,
          title: const Text('Add link', style: TextStyle(color: Colors.white)),
          content: TextField(
            controller: controller,
            autofocus: true,
            keyboardType: TextInputType.url,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'https://example.com',
              hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.4)),
              ),
              focusedBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.white),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, controller.text.trim()),
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
    controller.dispose();

    if (!mounted || result == null) return;
    if (result.isEmpty) {
      setState(() => _linkUrl = null);
      return;
    }
    setState(() => _linkUrl = result);
  }

  Future<void> _publish() async {
    final subject = _subjectController.text.trim();
    final body = _bodyController.text.trim();
    if (subject.isEmpty || body.isEmpty) {
      showFeatureSnackBar(context, 'Subject and body are required', isError: true);
      return;
    }
    if (_uploadingImage) {
      showFeatureSnackBar(context, 'Wait for upload to finish', isError: true);
      return;
    }

    setState(() => _submitting = true);
    try {
      final response = await FeatureApiClient.postJson(
        '/coach/announcements',
        {
          'subject': subject,
          'body': body,
          'image_url': _imageUrl,
          'video_url': null,
          'link_url': _linkUrl,
        },
      );
      final created = _announcementFromPostResponse(response);

      if (!mounted) return;
      final author = created['author_name']?.toString();
      final successMsg = author != null && author.isNotEmpty
          ? 'Sent to your team — all players will see it'
          : 'Announcement sent to your team';
      showFeatureSnackBar(context, successMsg);
      _subjectController.clear();
      _bodyController.clear();
      setState(() {
        _imageUrl = null;
        _linkUrl = null;
        _imagePreview = null;
      });
      widget.onPublished?.call();
    } on FeatureApiException catch (e) {
      if (mounted) showFeatureSnackBar(context, featureErrorMessage(e), isError: true);
    } catch (e) {
      if (mounted) showFeatureSnackBar(context, featureErrorMessage(e), isError: true);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: DarColors.maroonBubble.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.groups_outlined, color: Colors.white70, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'This message goes to every player on your team. '
                  'No individual targeting — everyone sees the same announcement.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 13,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        DarTextField(hint: 'Announcement Subject', controller: _subjectController),
        const SizedBox(height: 12),
        DarTextField(
          maxLines: 8,
          controller: _bodyController,
          hint: 'Write your message to the team...',
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _MediaButton(
              icon: Icons.image_outlined,
              label: 'Photo',
              active: _imageUrl != null,
              loading: _uploadingImage,
              onTap: _uploadingImage ? null : _pickAndUploadImage,
            ),
            _MediaButton(
              icon: Icons.link,
              label: 'Link',
              active: _linkUrl != null,
              onTap: _addLink,
            ),
          ],
        ),
        if (_imageUrl != null || _linkUrl != null) ...[
          const SizedBox(height: 20),
          _AttachmentSummary(
            imagePreview: _imagePreview,
            hasImage: _imageUrl != null,
            linkUrl: _linkUrl,
            onRemoveImage: () => setState(() {
              _imageUrl = null;
              _imagePreview = null;
            }),
            onRemoveLink: () => setState(() => _linkUrl = null),
          ),
        ],
        const SizedBox(height: 32),
        DarPrimaryButton(
          label: _submitting ? 'Sending...' : 'Send to Team',
          onPressed: (_submitting || _uploadingImage) ? null : _publish,
        ),
      ],
    );
  }
}

class _MediaButton extends StatelessWidget {
  const _MediaButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.active = false,
    this.loading = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool active;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(40),
        child: Column(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: DarColors.maroonBubble,
                    shape: BoxShape.circle,
                    border: active
                        ? Border.all(color: Colors.greenAccent, width: 2)
                        : null,
                  ),
                  child: loading
                      ? const Padding(
                          padding: EdgeInsets.all(16),
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Icon(icon, color: Colors.white, size: 26),
                ),
                if (active && !loading)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: Colors.greenAccent,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check, size: 12, color: Colors.black),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(color: Colors.white, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}

class _AttachmentSummary extends StatelessWidget {
  const _AttachmentSummary({
    required this.hasImage,
    required this.linkUrl,
    required this.onRemoveImage,
    required this.onRemoveLink,
    this.imagePreview,
  });

  final bool hasImage;
  final String? linkUrl;
  final File? imagePreview;
  final VoidCallback onRemoveImage;
  final VoidCallback onRemoveLink;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (hasImage && imagePreview != null)
          _AttachmentChip(
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.file(imagePreview!, width: 40, height: 40, fit: BoxFit.cover),
            ),
            label: 'Photo attached',
            onRemove: onRemoveImage,
          ),
        if (linkUrl != null)
          _AttachmentChip(
            leading: const Icon(Icons.link, color: Colors.white70, size: 28),
            label: linkUrl!,
            onRemove: onRemoveLink,
          ),
      ],
    );
  }
}

class _AttachmentChip extends StatelessWidget {
  const _AttachmentChip({
    required this.leading,
    required this.label,
    required this.onRemove,
  });

  final Widget leading;
  final String label;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: DarColors.maroonBubble.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          leading,
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white70, size: 20),
            onPressed: onRemove,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
      ),
    );
  }
}
