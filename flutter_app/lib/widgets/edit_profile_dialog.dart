// Copyright (c) 2026 Jacken Xu (lightant@gmail.com)
// All rights reserved.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../l10n/generated/app_localizations.dart';
import '../models/user_profile.dart';
import '../providers/profile_provider.dart';

class EditProfileDialog extends ConsumerStatefulWidget {
  final UserProfile? profile;

  const EditProfileDialog({super.key, this.profile});

  @override
  ConsumerState<EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends ConsumerState<EditProfileDialog> {
  late TextEditingController _nameController;
  late TextEditingController _dobController;
  late TextEditingController _heightController;
  late TextEditingController _weightController;
  late String _activityLevel;

  final List<String> _activityLevels = [
    'Sedentary',
    'Lightly Active',
    'Moderately Active',
    'Very Active',
    'Extra Active',
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.profile?.name ?? '');
    _dobController = TextEditingController(text: widget.profile?.dob ?? '');
    _heightController = TextEditingController(
      text: widget.profile?.height ?? '',
    );
    _weightController = TextEditingController(
      text: widget.profile?.weight ?? '',
    );
    _activityLevel = widget.profile?.activityLevel ?? 'Moderately Active';
    // Ensure the current level exists in our list
    if (!_activityLevels.contains(_activityLevel)) {
      _activityLevel = 'Moderately Active';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dobController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AlertDialog(
      title: Text(l10n.editProfile),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(labelText: l10n.name),
            ),
            TextField(
              controller: _dobController,
              decoration: InputDecoration(
                labelText: '${l10n.dob} (YYYY-MM-DD)',
              ),
            ),
            TextField(
              controller: _heightController,
              decoration: InputDecoration(
                labelText: '${l10n.height} (e.g. 5\'10")',
              ),
            ),
            TextField(
              controller: _weightController,
              decoration: InputDecoration(
                labelText: '${l10n.weight} (e.g. 170 lbs)',
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _activityLevel,
              decoration: InputDecoration(labelText: l10n.activityLevel),
              items: _activityLevels.map((level) {
                return DropdownMenuItem(value: level, child: Text(level));
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _activityLevel = value);
                }
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        ElevatedButton(
          onPressed: () {
            final newProfile = UserProfile(
              name: _nameController.text,
              dob: _dobController.text,
              activityLevel: _activityLevel,
              sex: widget.profile?.sex,
              height: _heightController.text,
              weight: _weightController.text,
            );
            ref.read(profileProvider.notifier).updateProfile(newProfile);
            Navigator.pop(context);
          },
          child: Text(l10n.save),
        ),
      ],
    );
  }
}
