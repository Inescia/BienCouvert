import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../../horses/domain/horse.dart';

class HorseSwitcher extends StatelessWidget {
  const HorseSwitcher({
    super.key,
    required this.horses,
    required this.selected,
    required this.onSelected,
  });

  final List<Horse> horses;
  final Horse selected;
  final ValueChanged<Horse> onSelected;

  @override
  Widget build(BuildContext context) {
    if (horses.length == 1) {
      return Text(
        selected.name,
        style: Theme.of(context).textTheme.headlineLarge,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 280),
          child: SizedBox(
            width: double.infinity,
            child: Text(
              selected.name,
              textAlign: TextAlign.left,
              key: ValueKey(selected.id),
              style: Theme.of(context).textTheme.headlineLarge,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          height: 52,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: horses.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final horse = horses[index];
              final isSelected = horse.id == selected.id;
              return GestureDetector(
                onTap: () => onSelected(horse),
                child: Semantics(
                  button: true,
                  selected: isSelected,
                  label: horse.name,
                  child: HorseAvatar(name: horse.name, selected: isSelected),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
