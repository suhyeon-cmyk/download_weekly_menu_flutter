import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/saved_menu.dart';
import '../services/menu_storage_service.dart';

class SavedMenuBar extends StatefulWidget {
  final List<SavedMenu> savedMenus;
  final String? selectedMenuId; // null means live view is selected
  final ValueChanged<SavedMenu?> onSelectMenu;
  final ValueChanged<List<String>> onDeleteMenus;

  const SavedMenuBar({
    super.key,
    required this.savedMenus,
    required this.selectedMenuId,
    required this.onSelectMenu,
    required this.onDeleteMenus,
  });

  @override
  State<SavedMenuBar> createState() => _SavedMenuBarState();
}

class _SavedMenuBarState extends State<SavedMenuBar> {
  bool isSelectionMode = false;
  final Set<String> selectedIds = {};
  bool isCollapsed = false;

  void _toggleSelectionMode() {
    setState(() {
      isSelectionMode = !isSelectionMode;
      selectedIds.clear();
    });
  }

  void _toggleSelectAll() {
    setState(() {
      if (selectedIds.length == widget.savedMenus.length) {
        selectedIds.clear();
      } else {
        selectedIds.clear();
        for (final item in widget.savedMenus) {
          selectedIds.add(item.id);
        }
      }
    });
  }

  void _toggleItemSelection(String id) {
    setState(() {
      if (selectedIds.contains(id)) {
        selectedIds.remove(id);
      } else {
        selectedIds.add(id);
      }
    });
  }

  Future<void> _confirmDeleteSelected() async {
    if (selectedIds.isEmpty) return;

    final count = selectedIds.length;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF2C2C2C),
        title: const Text(
          '식단표 삭제',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          '$count개의 저장된 식단표를 삭제하시겠습니까?\n삭제된 식단표는 복구할 수 없습니다.',
          style: const TextStyle(color: Colors.white70, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('취소', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('삭제'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final idsToDelete = selectedIds.toList();
      setState(() {
        isSelectionMode = false;
        selectedIds.clear();
      });
      widget.onDeleteMenus(idsToDelete);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasMenus = widget.savedMenus.isNotEmpty;
    final isAllSelected =
        hasMenus && selectedIds.length == widget.savedMenus.length;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        border: const Border(
          top: BorderSide(color: Color(0xFF333333), width: 1.0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(128),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top control header
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 12.0,
                vertical: 6.0,
              ),
              child: Row(
                children: [
                  if (isSelectionMode) ...[
                    // Select All checkbox
                    InkWell(
                      onTap: _toggleSelectAll,
                      borderRadius: BorderRadius.circular(6),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Checkbox(
                            value: isAllSelected,
                            onChanged: (_) => _toggleSelectAll(),
                            activeColor: Colors.blueAccent,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                          ),
                          const Text(
                            '전체선택',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '(${selectedIds.length}/${widget.savedMenus.length})',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    // Delete selected button
                    TextButton.icon(
                      onPressed: selectedIds.isNotEmpty
                          ? _confirmDeleteSelected
                          : null,
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.redAccent,
                        disabledForegroundColor: Colors.grey,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                      ),
                      icon: const Icon(Icons.delete_outline, size: 16),
                      label: Text(
                        '삭제 (${selectedIds.length})',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    // Done / Cancel button
                    TextButton(
                      onPressed: _toggleSelectionMode,
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                      ),
                      child: const Text('취소', style: TextStyle(fontSize: 12)),
                    ),
                  ] else ...[
                    // Normal header
                    const Icon(
                      Icons.photo_library_outlined,
                      size: 16,
                      color: Colors.white70,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '저장된 식단표 (${widget.savedMenus.length})',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    if (hasMenus) ...[
                      // Manage / Delete mode button
                      TextButton.icon(
                        onPressed: _toggleSelectionMode,
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white70,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                        ),
                        icon: const Icon(Icons.checklist, size: 15),
                        label: const Text('관리', style: TextStyle(fontSize: 12)),
                      ),
                    ],
                    // Collapse/expand toggle
                    IconButton(
                      icon: Icon(
                        isCollapsed
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        size: 20,
                        color: Colors.white70,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      tooltip: isCollapsed ? '식단표 목록 펼치기' : '식단표 목록 접기',
                      onPressed: () {
                        setState(() {
                          isCollapsed = !isCollapsed;
                        });
                      },
                    ),
                  ],
                ],
              ),
            ),

            // Horizontal thumbnail list
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 200),
              crossFadeState: isCollapsed
                  ? CrossFadeState.showFirst
                  : CrossFadeState.showSecond,
              firstChild: const SizedBox.shrink(),
              secondChild: SizedBox(
                height: 116,
                child: !hasMenus
                    ? _buildEmptyState()
                    : ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        itemCount: widget.savedMenus.length,
                        itemBuilder: (context, index) {
                          final menu = widget.savedMenus[index];
                          final isSelected = widget.selectedMenuId == menu.id;
                          final isItemChecked = selectedIds.contains(menu.id);

                          return _buildSavedMenuItem(
                            menu: menu,
                            isSelected: isSelected,
                            isItemChecked: isItemChecked,
                          );
                        },
                      ),
              ),
            ),
            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF252525),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.bookmark_add_outlined, size: 20, color: Colors.amber),
          SizedBox(width: 8),
          Flexible(
            child: Text(
              '저장된 식단표가 없습니다. 상단 우측의 저장 버튼을 눌러 보관해보세요.',
              style: TextStyle(color: Colors.white70, fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  /// Saved meal thumbnail item
  Widget _buildSavedMenuItem({
    required SavedMenu menu,
    required bool isSelected,
    required bool isItemChecked,
  }) {
    return Container(
      width: 106,
      margin: const EdgeInsets.only(right: 8, bottom: 4),
      child: Material(
        color: isSelected ? const Color(0xFF2A2A2A) : const Color(0xFF202020),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: isSelected
                ? Colors.blueAccent
                : (isItemChecked ? Colors.amberAccent : Colors.white12),
            width: isSelected || isItemChecked ? 2.0 : 1.0,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () {
            if (isSelectionMode) {
              _toggleItemSelection(menu.id);
            } else {
              if (isSelected) {
                // 이미 선택된 식단표를 다시 누르면 실시간 식단표로 복귀
                widget.onSelectMenu(null);
              } else {
                widget.onSelectMenu(menu);
              }
            }
          },
          onLongPress: () {
            HapticFeedback.mediumImpact();
            if (!isSelectionMode) {
              setState(() {
                isSelectionMode = true;
                selectedIds.add(menu.id);
              });
            }
          },
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Thumbnail preview image
              _MenuThumbnailImage(menu: menu),

              // Gradient scrim overlay for readable text
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black54,
                      Colors.transparent,
                      Colors.black87,
                    ],
                    stops: [0.0, 0.4, 0.9],
                  ),
                ),
              ),

              // Title label at top (e.g. 제주청사_오름동4층_1)
              Positioned(
                top: 4,
                left: 4,
                right: 4,
                child: Text(
                  menu.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    shadows: [Shadow(color: Colors.black, blurRadius: 2)],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              // Date label at bottom (e.g. 2026-09-12)
              Positioned(
                bottom: 4,
                left: 4,
                right: 4,
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        menu.savedDate,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 9,
                          shadows: [Shadow(color: Colors.black, blurRadius: 2)],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isSelected)
                      const Icon(
                        Icons.check_circle,
                        size: 12,
                        color: Colors.blueAccent,
                      ),
                  ],
                ),
              ),

              // Selection mode checkbox overlay
              if (isSelectionMode)
                Positioned(
                  top: 2,
                  right: 2,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Checkbox(
                      value: isItemChecked,
                      onChanged: (_) => _toggleItemSelection(menu.id),
                      activeColor: Colors.blueAccent,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
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

/// Helper widget to asynchronously load and display thumbnail image
class _MenuThumbnailImage extends StatefulWidget {
  final SavedMenu menu;

  const _MenuThumbnailImage({required this.menu});

  @override
  State<_MenuThumbnailImage> createState() => _MenuThumbnailImageState();
}

class _MenuThumbnailImageState extends State<_MenuThumbnailImage> {
  Uint8List? _bytes;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  @override
  void didUpdateWidget(covariant _MenuThumbnailImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.menu.id != widget.menu.id) {
      _loadImage();
    }
  }

  Future<void> _loadImage() async {
    final bytes = await MenuStorageService.instance.getImageBytes(widget.menu);
    if (mounted) {
      setState(() {
        _bytes = bytes;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Colors.white38,
          ),
        ),
      );
    }

    if (_bytes == null || _bytes!.isEmpty) {
      return Container(
        color: const Color(0xFF333333),
        child: const Icon(Icons.broken_image, size: 24, color: Colors.white38),
      );
    }

    return Image.memory(
      _bytes!,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => Container(
        color: const Color(0xFF333333),
        child: const Icon(Icons.broken_image, size: 24, color: Colors.white38),
      ),
    );
  }
}
