import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:roommate_expense_app/api/api.dart';
import 'package:roommate_expense_app/api/api_client.dart';
import 'package:roommate_expense_app/l10n/app_localizations.dart';
import 'package:roommate_expense_app/models.dart';
import 'package:roommate_expense_app/theme.dart';
import 'package:roommate_expense_app/utils/errors.dart';
import 'package:roommate_expense_app/utils/format.dart';

// The API allows at most 5 files per expense or payment, and 10 MB per file.
const int maxAttachmentsPerOwner = 5;
const int maxAttachmentBytes = 10 * 1024 * 1024;

// The same text the API sends for a wrong file type. errorMessage maps it to a localized text.
const String _typeErrorText = 'Only JPEG, PNG, WEBP images and PDF files are allowed';

// Downloaded bytes, kept for the session so scrolling does not download again.
final Map<int, Uint8List> _attachmentBytes = {};

Future<Uint8List> _bytesOf(int householdId, int attachmentId) async {
  final cached = _attachmentBytes[attachmentId];
  if (cached != null) return cached;
  final bytes = await Api.downloadAttachment(householdId, attachmentId);
  _attachmentBytes[attachmentId] = bytes;
  return bytes;
}

enum _PickSource { camera, gallery, pdf }

// Shows the "add" sheet and then picks the chosen file.
// Returns null when the user cancels. Throws ApiException for a file that is too large
// or of the wrong type, so the caller shows the usual localized message.
Future<UploadFile?> pickAttachment(BuildContext context) async {
  final l10n = AppLocalizations.of(context);
  final source = await showModalBottomSheet<_PickSource>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.photo_camera_outlined),
            title: Text(l10n.attachmentTakePhoto),
            onTap: () => Navigator.pop(sheetContext, _PickSource.camera),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: Text(l10n.attachmentPickGallery),
            onTap: () => Navigator.pop(sheetContext, _PickSource.gallery),
          ),
          ListTile(
            leading: const Icon(Icons.picture_as_pdf_outlined),
            title: Text(l10n.attachmentPickPdf),
            onTap: () => Navigator.pop(sheetContext, _PickSource.pdf),
          ),
        ],
      ),
    ),
  );
  if (source == null) return null;

  if (source == _PickSource.pdf) {
    final picked = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: const ['pdf'],
    );
    if (picked == null) return null;
    // Checked before reading, so a huge PDF is never loaded into memory.
    _checkSize(await picked.length() ?? 0);
    final bytes = await picked.readAsBytes();
    _checkSize(bytes.length);
    return UploadFile(
      bytes: bytes,
      filename: picked.name,
      contentType: 'application/pdf',
    );
  }

  // Scaled down and recompressed here, so an upload is about 0.5 to 1.5 MB.
  final photo = await ImagePicker().pickImage(
    source: source == _PickSource.camera ? ImageSource.camera : ImageSource.gallery,
    maxWidth: 2000,
    imageQuality: 80,
  );
  if (photo == null) return null;
  final bytes = await photo.readAsBytes();
  _checkSize(bytes.length);
  // The type comes from the bytes, not the file name, so the content type is always right.
  final type = _imageType(bytes);
  if (type == null) throw ApiException(400, _typeErrorText);
  return UploadFile(
    bytes: bytes,
    filename: _withExtension(photo.name, type.extension),
    contentType: type.mimeType,
  );
}

void _checkSize(int bytes) {
  if (bytes > maxAttachmentBytes) {
    throw ApiException(413, 'File is too large (max 10 MB)');
  }
}

// The extension and content type of a JPEG, PNG or WEBP image, read from its first bytes.
({String extension, String mimeType})? _imageType(Uint8List bytes) {
  bool startsWith(List<int> signature) {
    if (bytes.length < signature.length) return false;
    for (var i = 0; i < signature.length; i++) {
      if (bytes[i] != signature[i]) return false;
    }
    return true;
  }

  if (startsWith([0xFF, 0xD8, 0xFF])) {
    return (extension: 'jpg', mimeType: 'image/jpeg');
  }
  if (startsWith([0x89, 0x50, 0x4E, 0x47])) {
    return (extension: 'png', mimeType: 'image/png');
  }
  // WEBP files start with "RIFF", and "WEBP" comes at byte 8.
  if (startsWith([0x52, 0x49, 0x46, 0x46]) &&
      bytes.length >= 12 &&
      bytes[8] == 0x57 &&
      bytes[9] == 0x45 &&
      bytes[10] == 0x42 &&
      bytes[11] == 0x50) {
    return (extension: 'webp', mimeType: 'image/webp');
  }
  return null;
}

String _withExtension(String name, String extension) {
  final dot = name.lastIndexOf('.');
  final base = dot > 0 ? name.substring(0, dot) : name;
  return '$base.$extension';
}

// A safe file extension for the temp file. Falls back to "pdf".
String _safeExtension(String filename) {
  final dot = filename.lastIndexOf('.');
  if (dot < 0 || dot == filename.length - 1) return 'pdf';
  final ext = filename
      .substring(dot + 1)
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]'), '');
  return ext.isEmpty ? 'pdf' : ext;
}

void _showError(BuildContext context, Object error) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(errorMessage(context, error))),
  );
}

void _showText(BuildContext context, String text) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
}

// Receipts and documents of one expense or one payment. Shows thumbnails, opens files,
// and lets the user add files and delete the ones they may delete.
// Give exactly one of expenseId or paymentId.
class AttachmentsSection extends StatefulWidget {
  const AttachmentsSection({
    super.key,
    required this.householdId,
    this.expenseId,
    this.paymentId,
    required this.canDelete,
    this.onChanged,
  }) : assert((expenseId == null) != (paymentId == null));

  final int householdId;
  final int? expenseId;
  final int? paymentId;
  // True when the current user may delete this attachment (uploader, payer/sender or admin).
  final bool Function(Attachment attachment) canDelete;
  // Called after a file was added or deleted, so the parent can refresh its counts.
  final VoidCallback? onChanged;

  @override
  State<AttachmentsSection> createState() => _AttachmentsSectionState();
}

class _AttachmentsSectionState extends State<AttachmentsSection> {
  // null while the first load runs, or when it failed (see _loadError).
  List<Attachment>? _items;
  String? _loadError;
  // Uploads in progress. Each one shows a placeholder tile.
  int _uploading = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final items = widget.expenseId != null
          ? await Api.getExpenseAttachments(widget.householdId, widget.expenseId!)
          : await Api.getPaymentAttachments(widget.householdId, widget.paymentId!);
      if (!mounted) return;
      setState(() {
        _items = items;
        _loadError = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadError = errorMessage(context, e));
    }
  }

  Future<void> _add() async {
    UploadFile? file;
    try {
      file = await pickAttachment(context);
    } catch (e) {
      if (mounted) _showError(context, e);
      return;
    }
    if (file == null || !mounted) return;

    setState(() {
      _uploading++;
    });
    try {
      final created = widget.expenseId != null
          ? await Api.uploadExpenseAttachment(
              widget.householdId,
              widget.expenseId!,
              file,
            )
          : await Api.uploadPaymentAttachment(
              widget.householdId,
              widget.paymentId!,
              file,
            );
      if (!mounted) return;
      setState(() {
        _items = [...?_items, created];
      });
      widget.onChanged?.call();
    } catch (e) {
      if (mounted) _showError(context, e);
    } finally {
      if (mounted) {
        setState(() {
          _uploading--;
        });
      }
    }
  }

  Future<void> _delete(Attachment attachment) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        content: Text(l10n.attachmentDeleteConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      await Api.deleteAttachment(widget.householdId, attachment.id);
    } catch (e) {
      if (mounted) _showError(context, e);
      return;
    }
    if (!mounted) return;
    _attachmentBytes.remove(attachment.id);
    setState(() {
      _items = _items?.where((item) => item.id != attachment.id).toList();
    });
    widget.onChanged?.call();
  }

  // Images open in the full-screen viewer. PDFs go to another app on the phone.
  Future<void> _open(Attachment attachment) async {
    final Uint8List bytes;
    try {
      bytes = await _bytesOf(widget.householdId, attachment.id);
    } catch (e) {
      if (mounted) _showError(context, e);
      return;
    }
    if (!mounted) return;

    if (attachment.isImage) {
      await Navigator.push<void>(
        context,
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (_) => _AttachmentViewer(attachment: attachment, bytes: bytes),
        ),
      );
      return;
    }
    await _openPdf(attachment, bytes);
  }

  // Writes the PDF to the temp folder (keeping its extension) and opens it with an app.
  Future<void> _openPdf(Attachment attachment, Uint8List bytes) async {
    final l10n = AppLocalizations.of(context);
    try {
      final tempDir = await getTemporaryDirectory();
      final folder = Directory('${tempDir.path}/attachments');
      await folder.create(recursive: true);
      final file = File(
        '${folder.path}/${attachment.id}.${_safeExtension(attachment.originalFilename)}',
      );
      await file.writeAsBytes(bytes, flush: true);

      final result = await OpenFilex.open(file.path, type: attachment.contentType);
      if (!mounted) return;
      if (result.type == ResultType.noAppToOpen) {
        _showText(context, l10n.attachmentNoApp);
      } else if (result.type != ResultType.done) {
        _showText(context, l10n.attachmentCannotOpen);
      }
    } catch (_) {
      if (mounted) _showText(context, l10n.attachmentCannotOpen);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final items = _items;
    final full = ((items?.length ?? 0) + _uploading) >= maxAttachmentsPerOwner;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                l10n.attachmentsTitle,
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
            TextButton.icon(
              onPressed: items == null || full ? null : _add,
              icon: const Icon(Icons.add_rounded),
              label: Text(l10n.attachmentAdd),
            ),
          ],
        ),
        if (full)
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              l10n.attachmentMaxHint,
              style: theme.textTheme.bodySmall?.copyWith(color: AppColors.muted),
            ),
          ),
        const SizedBox(height: 8),
        _buildContent(l10n, items),
      ],
    );
  }

  Widget _buildContent(AppLocalizations l10n, List<Attachment>? items) {
    if (items == null) {
      if (_loadError != null) {
        return Row(
          children: [
            Expanded(
              child: Text(
                _loadError!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.owes),
              ),
            ),
            TextButton(onPressed: _load, child: Text(l10n.retry)),
          ],
        );
      }
      return const SizedBox(
        height: 112,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (items.isEmpty && _uploading == 0) {
      return Text(
        l10n.attachmentEmpty,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.muted),
      );
    }

    return SizedBox(
      height: 112,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length + _uploading,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          if (index >= items.length) return const _UploadingTile();
          final attachment = items[index];
          return _AttachmentThumb(
            key: ValueKey(attachment.id),
            householdId: widget.householdId,
            attachment: attachment,
            canDelete: widget.canDelete(attachment),
            onOpen: () => _open(attachment),
            onDelete: () => _delete(attachment),
          );
        },
      ),
    );
  }
}

// Create mode of the expense form. The files stay in memory until the expense is saved,
// then the form uploads them.
class PendingAttachmentsSection extends StatelessWidget {
  const PendingAttachmentsSection({
    super.key,
    required this.files,
    required this.onAdded,
    required this.onRemoved,
    this.enabled = true,
  });

  final List<UploadFile> files;
  final ValueChanged<UploadFile> onAdded;
  final ValueChanged<int> onRemoved;
  final bool enabled;

  Future<void> _add(BuildContext context) async {
    UploadFile? file;
    try {
      file = await pickAttachment(context);
    } catch (e) {
      if (context.mounted) _showError(context, e);
      return;
    }
    if (file == null || !context.mounted) return;
    onAdded(file);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final full = files.length >= maxAttachmentsPerOwner;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                l10n.attachmentsTitle,
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
            TextButton.icon(
              onPressed: enabled && !full ? () => _add(context) : null,
              icon: const Icon(Icons.add_rounded),
              label: Text(l10n.attachmentAdd),
            ),
          ],
        ),
        if (full)
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              l10n.attachmentMaxHint,
              style: theme.textTheme.bodySmall?.copyWith(color: AppColors.muted),
            ),
          ),
        if (files.isEmpty)
          Text(
            l10n.attachmentEmpty,
            style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.muted),
          )
        else ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (var i = 0; i < files.length; i++)
                InputChip(
                  avatar: Icon(
                    files[i].isImage ? Icons.image_outlined : Icons.picture_as_pdf_outlined,
                    size: 18,
                  ),
                  label: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 220),
                    child: Text(
                      files[i].filename,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  onDeleted: enabled ? () => onRemoved(i) : null,
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            l10n.attachmentsPendingHint,
            style: theme.textTheme.bodySmall?.copyWith(color: AppColors.muted),
          ),
        ],
      ],
    );
  }
}

// One thumbnail. Images are downloaded once and shown from memory. PDFs show an icon and the name.
class _AttachmentThumb extends StatefulWidget {
  const _AttachmentThumb({
    super.key,
    required this.householdId,
    required this.attachment,
    required this.canDelete,
    required this.onOpen,
    required this.onDelete,
  });

  final int householdId;
  final Attachment attachment;
  final bool canDelete;
  final VoidCallback onOpen;
  final VoidCallback onDelete;

  @override
  State<_AttachmentThumb> createState() => _AttachmentThumbState();
}

class _AttachmentThumbState extends State<_AttachmentThumb> {
  Uint8List? _bytes;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    if (widget.attachment.isImage) _loadImage();
  }

  Future<void> _loadImage() async {
    try {
      final bytes = await _bytesOf(widget.householdId, widget.attachment.id);
      if (mounted) setState(() => _bytes = bytes);
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final attachment = widget.attachment;
    final Widget content;
    if (!attachment.isImage) {
      content = _PdfTile(name: attachment.originalFilename);
    } else if (_bytes != null) {
      content = Image.memory(_bytes!, fit: BoxFit.cover, gaplessPlayback: true);
    } else if (_failed) {
      content = const Center(
        child: Icon(Icons.broken_image_outlined, color: AppColors.muted),
      );
    } else {
      content = const Center(
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    return _TileFrame(
      onTap: widget.onOpen,
      // Long press is the same as the x button, so both work for deleting.
      onLongPress: widget.canDelete ? widget.onDelete : null,
      onRemove: widget.canDelete ? widget.onDelete : null,
      child: content,
    );
  }
}

// The rounded frame shared by thumbnails and the upload placeholder.
class _TileFrame extends StatelessWidget {
  const _TileFrame({
    required this.child,
    this.onTap,
    this.onLongPress,
    this.onRemove,
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 96,
      height: 112,
      child: Stack(
        children: [
          Positioned.fill(
            child: Material(
              color: AppColors.paper,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: AppColors.line),
              ),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: onTap,
                onLongPress: onLongPress,
                child: SizedBox.expand(child: child),
              ),
            ),
          ),
          if (onRemove != null)
            Positioned(
              top: 4,
              right: 4,
              child: Material(
                color: Colors.black54,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: onRemove,
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(Icons.close_rounded, size: 16, color: Colors.white),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PdfTile extends StatelessWidget {
  const _PdfTile({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.picture_as_pdf_rounded, size: 36, color: AppColors.terracotta),
          const SizedBox(height: 6),
          Text(
            name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

// Placeholder shown while a file uploads.
class _UploadingTile extends StatelessWidget {
  const _UploadingTile();

  @override
  Widget build(BuildContext context) {
    return const _TileFrame(
      child: Center(
        child: SizedBox(
          width: 26,
          height: 26,
          child: CircularProgressIndicator(strokeWidth: 3),
        ),
      ),
    );
  }
}

// Full screen view of one image, on a dark background, with pinch to zoom.
class _AttachmentViewer extends StatelessWidget {
  const _AttachmentViewer({required this.attachment, required this.bytes});

  final Attachment attachment;
  final Uint8List bytes;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
          onPressed: () => Navigator.pop(context),
        ),
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              attachment.originalFilename,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            Text(
              l10n.attachmentByline(
                attachment.uploadedByName,
                formatDate(context, attachment.createdAt),
              ),
              style: const TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
      ),
      body: InteractiveViewer(
        minScale: 1,
        maxScale: 5,
        child: Center(
          child: Image.memory(bytes, fit: BoxFit.contain),
        ),
      ),
    );
  }
}
