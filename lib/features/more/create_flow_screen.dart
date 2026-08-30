import 'dart:io';
import 'package:flutter/material.dart';
import '../../core/app_icons.dart';
import '../../core/widgets/app_modal.dart';
import '../../core/widgets/buttons.dart';
import '../../core/widgets/choice_chip.dart';
import '../../core/widgets/detail_header.dart';
import '../../core/widgets/device_photo_card.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

enum CreateFieldType { text, chips, photo }

class CreateField {
  const CreateField.text({
    required this.label,
    required this.hint,
    this.multiline = false,
    this.isOptional = false,
    this.prefixText,
  })  : type = CreateFieldType.text,
        chips = null;

  const CreateField.chips({
    required this.label,
    required this.chips,
    this.isOptional = false,
  })  : type = CreateFieldType.chips,
        hint = '',
        multiline = false,
        prefixText = null;

  const CreateField.photo({
    required this.label,
    this.hint = 'Take a photo or choose from library',
    this.isOptional = true,
  })  : type = CreateFieldType.photo,
        chips = null,
        multiline = false,
        prefixText = null;

  final CreateFieldType type;
  final String label;
  final String hint;
  final bool multiline;
  final List<String>? chips;
  final bool isOptional;
  final String? prefixText;
}

class CreateFlowScreen extends StatefulWidget {
  const CreateFlowScreen({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.fields,
    required this.submitLabel,
    required this.successTitle,
    required this.successMessage,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final List<CreateField> fields;
  final String submitLabel;
  final String successTitle;
  final String Function(List<String> values) successMessage;

  @override
  State<CreateFlowScreen> createState() => _CreateFlowScreenState();
}

class _CreateFlowScreenState extends State<CreateFlowScreen> {
  late final List<TextEditingController?> _controllers;
  late final List<int?> _chipSelections;
  late final List<File?> _photos;

  @override
  void initState() {
    super.initState();
    _controllers = [
      for (final f in widget.fields)
        f.type == CreateFieldType.text ? TextEditingController() : null
    ];
    _chipSelections = [for (final _ in widget.fields) null];
    _photos = [for (final _ in widget.fields) null];
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c?.dispose();
    }
    super.dispose();
  }

  String _valueFor(int i) {
    final field = widget.fields[i];
    switch (field.type) {
      case CreateFieldType.chips:
        final selected = _chipSelections[i];
        return selected == null ? '' : field.chips![selected];
      case CreateFieldType.photo:
        return _photos[i] != null ? _photos[i]!.path : (field.isOptional ? 'attached' : '');
      case CreateFieldType.text:
        return _controllers[i]!.text.trim();
    }
  }

  bool get _canSubmit {
    for (int i = 0; i < widget.fields.length; i++) {
      final f = widget.fields[i];
      if (f.isOptional) continue;
      if (_valueFor(i).isEmpty) return false;
    }
    return true;
  }

  void _submit() {
    final values = List.generate(widget.fields.length, _valueFor);
    showAppModal(
      context,
      icon: AppIcons.check,
      iconColor: AppColors.gain,
      title: widget.successTitle,
      message: widget.successMessage(values),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.page,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 40),
          children: [
            DetailHeader(
              icon: widget.icon,
              title: widget.title,
              subtitle: widget.subtitle,
            ),
            const SizedBox(height: 22),
            for (int i = 0; i < widget.fields.length; i++) ...[
              if (widget.fields[i].type == CreateFieldType.photo) ...[
                DevicePhotoCard(
                  label: widget.fields[i].label,
                  photo: _photos[i],
                  onChanged: (file) => setState(() => _photos[i] = file),
                  title: widget.fields[i].label,
                  hint: widget.fields[i].hint,
                ),
                const SizedBox(height: 22),
              ] else ...[
                Text(widget.fields[i].label, style: AppText.sectionTitle),
                const SizedBox(height: 10),
                if (widget.fields[i].type == CreateFieldType.chips)
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (int j = 0; j < widget.fields[i].chips!.length; j++)
                        AppChoiceChip(
                          label: widget.fields[i].chips![j],
                          selected: _chipSelections[i] == j,
                          onTap: () => setState(() => _chipSelections[i] = j),
                        ),
                    ],
                  )
                else
                  TextField(
                    controller: _controllers[i],
                    onChanged: (_) => setState(() {}),
                    maxLines: widget.fields[i].multiline ? 3 : 1,
                    decoration: InputDecoration(
                      hintText: widget.fields[i].hint,
                      prefixText: widget.fields[i].prefixText,
                    ),
                  ),
                const SizedBox(height: 22),
              ],
            ],
            PrimaryButton(
              label: widget.submitLabel,
              onPressed: _canSubmit ? _submit : null,
            ),
          ],
        ),
      ),
    );
  }
}
