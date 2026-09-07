import 'package:flutter/material.dart';

import '../models/user.dart';
import '../theme/app_theme.dart';

/// A row of toggleable chips for picking one or more subteams. Used in
/// onboarding, a captain editing someone else's subteams, and a member
/// editing their own.
class SubteamMultiSelect extends StatelessWidget {
  final Set<Subteam> selected;
  final ValueChanged<Set<Subteam>> onChanged;

  const SubteamMultiSelect({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: Subteam.values.map((s) {
        final isSelected = selected.contains(s);
        return FilterChip(
          avatar: CircleAvatar(
            backgroundColor: AppTheme.subteamColor(s),
            radius: 6,
          ),
          label: Text(subteamLabel(s)),
          selected: isSelected,
          onSelected: (v) {
            final next = Set<Subteam>.from(selected);
            if (v) {
              next.add(s);
            } else {
              next.remove(s);
            }
            onChanged(next);
          },
        );
      }).toList(),
    );
  }
}
