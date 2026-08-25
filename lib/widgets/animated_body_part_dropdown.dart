import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../models/body_area.dart';

class AnimatedBodyPartDropdown extends StatefulWidget {
  final String? value;
  final AppColors colors;
  final ValueChanged<String?> onChanged;
  final List<BodyArea> bodyAreas;

  const AnimatedBodyPartDropdown({
    super.key,
    required this.value,
    required this.colors,
    required this.onChanged,
    required this.bodyAreas,
  });

  @override
  State<AnimatedBodyPartDropdown> createState() => _AnimatedBodyPartDropdownState();
}

class _AnimatedBodyPartDropdownState extends State<AnimatedBodyPartDropdown>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _fadeAnimation;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleDropdown() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggleDropdown,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          border: Border.all(
            color: widget.colors.border,
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Selected value display
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: widget.value != null
                        ? _buildSelectedItem(widget.value!)
                        : Text(
                            'Select Body Area',
                            style: TextStyle(
                              color: widget.colors.textSecondary,
                              fontSize: 16,
                            ),
                          ),
                  ),
                  // Animated arrow icon
                  RotationTransition(
                    turns: Tween<double>(begin: 0.0, end: 0.5).animate(_controller),
                    child: Icon(
                      Icons.expand_more,
                      color: widget.colors.textPrimary,
                      size: 24,
                    ),
                  ),
                ],
              ),
            ),
            // Dropdown options
            if (_isExpanded)
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(8),
                  bottomRight: Radius.circular(8),
                ),
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Container(
                      constraints: const BoxConstraints(maxHeight: 250),
                      decoration: BoxDecoration(
                        color: widget.colors.surface,
                        border: Border(
                          top: BorderSide(
                            color: widget.colors.border,
                            width: 1.5,
                          ),
                          left: BorderSide(
                            color: widget.colors.border,
                            width: 1.5,
                          ),
                          right: BorderSide(
                            color: widget.colors.border,
                            width: 1.5,
                          ),
                          bottom: BorderSide(
                            color: widget.colors.border,
                            width: 1.5,
                          ),
                        ),
                      ),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: widget.bodyAreas.length,
                        itemBuilder: (context, index) {
                          final area = widget.bodyAreas[index];
                          final isSelected = widget.value == area.id;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: widget.colors.border.withValues(alpha: 0.2),
                                ),
                              ),
                            ),
                            child: Material(
                              color: isSelected
                                  ? widget.colors.accent.withValues(alpha: 0.1)
                                  : widget.colors.surface,
                              child: ListTile(
                                  leading: area.buildIcon(color: widget.colors.textPrimary, size: 20),
                                  title: Text(
                                    area.label,
                                    style: TextStyle(
                                      color: widget.colors.textPrimary,
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                    ),
                                  ),
                                  trailing: isSelected
                                      ? Icon(
                                          Icons.check_circle,
                                          color: widget.colors.accent,
                                        )
                                      : null,
                                  onTap: () {
                                    widget.onChanged(area.id);
                                    _toggleDropdown();
                                  },
                                ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedItem(String value) {
    final area = widget.bodyAreas.firstWhere(
      (a) => a.id == value,
      orElse: () => widget.bodyAreas.first,
    );
    return Row(
      children: [
        area.buildIcon(color: widget.colors.textPrimary, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            area.label,
            style: TextStyle(
              color: widget.colors.textPrimary,
              fontSize: 16,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ],
    );
  }
}