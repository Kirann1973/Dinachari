import 'dart:io';

import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/foundation.dart' hide Category;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../app.dart';
import '../domain/habit_look.dart';
import '../domain/symbols.dart';
import 'habit_look_view.dart';

enum _Tab { emoji, icon, photo, text }

/// Lets the user give a habit any look: emoji (up to 3 combined), one of
/// ~4,000 searchable icons, a photo from their gallery, or a few letters.
class LookPicker extends StatefulWidget {
  const LookPicker({
    super.key,
    required this.look,
    required this.color,
    required this.onChanged,
  });

  /// The current stored look, e.g. `emoji:🛁🧴`.
  final String look;
  final Color color;
  final ValueChanged<String> onChanged;

  @override
  State<LookPicker> createState() => _LookPickerState();
}

class _LookPickerState extends State<LookPicker> {
  late _Tab _tab = switch (HabitLook.parse(widget.look)) {
    EmojiLook() => _Tab.emoji,
    IconLook() => _Tab.icon,
    PhotoLook() => _Tab.photo,
    TextLook() => _Tab.text,
  };

  late final _emoji = TextEditingController(
    text: switch (HabitLook.parse(widget.look)) {
      EmojiLook(:final emoji) => emoji,
      _ => '',
    },
  );
  late final _text = TextEditingController(
    text: switch (HabitLook.parse(widget.look)) {
      TextLook(:final text) => text,
      _ => '',
    },
  );
  final _iconQuery = TextEditingController();

  @override
  void dispose() {
    _emoji.dispose();
    _text.dispose();
    _iconQuery.dispose();
    super.dispose();
  }

  void _setEmoji(String value) {
    final limited = HabitLook.limit(value);
    if (_emoji.text != limited) {
      _emoji.value = TextEditingValue(
        text: limited,
        selection: TextSelection.collapsed(offset: limited.length),
      );
    }
    if (limited.isNotEmpty) widget.onChanged('emoji:$limited');
  }

  Future<void> _pickPhoto() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );
    if (picked == null) return;
    // Keep our own copy so the photo stays if it's deleted from the gallery.
    final dir = Directory(
      '${(await getApplicationSupportDirectory()).path}/habit_photos',
    );
    await dir.create(recursive: true);
    final ext = picked.path.contains('.') ? picked.path.split('.').last : 'jpg';
    final file = File(
      '${dir.path}/${DateTime.now().microsecondsSinceEpoch}.$ext',
    );
    await file.writeAsBytes(await picked.readAsBytes());
    widget.onChanged('photo:${file.path}');
  }

  @override
  Widget build(BuildContext context) {
    final look = HabitLook.parse(widget.look);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            HabitLookView(look: widget.look, color: widget.color, size: 56),
            const SizedBox(width: 14),
            Expanded(
              child: Text(switch (look) {
                EmojiLook() => 'Tap up to 3 emoji to combine them',
                IconLook(:final name) => name.replaceAll('_', ' '),
                PhotoLook() => 'Your photo',
                TextLook() => 'Up to 3 letters or symbols',
              }, style: const TextStyle(fontSize: 14, color: DC.muted)),
            ),
          ],
        ),
        const SizedBox(height: 14),
        SegmentedButton<_Tab>(
          showSelectedIcon: false,
          style: SegmentedButton.styleFrom(
            foregroundColor: DC.ink,
            selectedForegroundColor: Colors.white,
            selectedBackgroundColor: DC.accentDeep,
            side: const BorderSide(color: DC.line),
            visualDensity: VisualDensity.compact,
          ),
          segments: const [
            ButtonSegment(value: _Tab.emoji, label: Text('Emoji')),
            ButtonSegment(value: _Tab.icon, label: Text('Icons')),
            ButtonSegment(value: _Tab.photo, label: Text('Photo')),
            ButtonSegment(value: _Tab.text, label: Text('Text')),
          ],
          selected: {_tab},
          onSelectionChanged: (s) => setState(() => _tab = s.first),
        ),
        const SizedBox(height: 14),
        switch (_tab) {
          _Tab.emoji => _emojiTab(),
          _Tab.icon => _iconTab(look),
          _Tab.photo => _photoTab(look),
          _Tab.text => _textTab(),
        },
      ],
    );
  }

  Widget _emojiTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _emoji,
          style: const TextStyle(fontSize: 26, color: DC.ink),
          decoration: _decoration(
            'Your emoji',
            hint: 'Pick below or type from your keyboard',
            suffix: IconButton(
              tooltip: 'Clear',
              icon: const Icon(Icons.close, color: DC.muted),
              onPressed: () => setState(_emoji.clear),
            ),
          ),
          onChanged: _setEmoji,
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: EmojiPicker(
            onEmojiSelected: (_, emoji) {
              final current = _emoji.text.characters;
              // Full? Drop the oldest so the newest tap always shows.
              final base = current.length >= HabitLook.maxParts
                  ? current.skip(1).string
                  : current.string;
              _setEmoji(base + emoji.emoji);
              setState(() {});
            },
            config: Config(
              height: 300,
              checkPlatformCompatibility: true,
              emojiViewConfig: EmojiViewConfig(
                backgroundColor: DC.soft,
                emojiSizeMax:
                    28 *
                    (defaultTargetPlatform == TargetPlatform.iOS ? 1.2 : 1),
              ),
              categoryViewConfig: const CategoryViewConfig(
                // Habits are mostly activities; Recents starts empty.
                initCategory: Category.ACTIVITIES,
                backgroundColor: DC.soft,
                indicatorColor: DC.accentDeep,
                iconColorSelected: DC.accentDeep,
              ),
              bottomActionBarConfig: const BottomActionBarConfig(
                showBackspaceButton: false,
                backgroundColor: DC.soft,
                buttonColor: DC.soft,
                buttonIconColor: DC.muted,
              ),
              searchViewConfig: const SearchViewConfig(
                backgroundColor: DC.soft,
                hintText: 'Search emoji, e.g. bath',
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _iconTab(HabitLook look) {
    final results = SymbolCatalog.instance.search(_iconQuery.text, limit: 240);
    final selected = look is IconLook ? look.name : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _iconQuery,
          style: const TextStyle(color: DC.ink),
          decoration: _decoration(
            'Search ${SymbolCatalog.instance.icons.length} icons',
            hint: 'e.g. gym, bath, book, sleep',
            prefix: const Icon(Icons.search, color: DC.muted),
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 300,
          child: results.isEmpty
              ? const Center(
                  child: Text(
                    'No icons match. Try another word, or use Emoji.',
                    style: TextStyle(color: DC.muted),
                  ),
                )
              : GridView.builder(
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 52,
                    mainAxisSpacing: 6,
                    crossAxisSpacing: 6,
                  ),
                  itemCount: results.length,
                  itemBuilder: (context, i) {
                    final icon = results[i];
                    final isSelected = icon.name == selected;
                    return Semantics(
                      button: true,
                      selected: isSelected,
                      label: icon.name.replaceAll('_', ' '),
                      excludeSemantics: true,
                      child: InkResponse(
                        onTap: () => widget.onChanged('icon:${icon.name}'),
                        child: Container(
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isSelected ? deepOf(widget.color) : DC.soft,
                          ),
                          child: SymbolGlyph(
                            icon,
                            size: 24,
                            color: isSelected ? Colors.white : DC.muted,
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _photoTab(HabitLook look) {
    return Row(
      children: [
        if (look is PhotoLook) ...[
          HabitLookView(look: widget.look, color: widget.color, size: 72),
          const SizedBox(width: 16),
        ],
        Expanded(
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: DC.ink,
              side: const BorderSide(color: DC.line),
              minimumSize: const Size.fromHeight(48),
            ),
            onPressed: _pickPhoto,
            icon: const Icon(Icons.photo_library_outlined),
            label: Text(
              look is PhotoLook
                  ? 'Choose another photo'
                  : 'Choose from gallery',
            ),
          ),
        ),
      ],
    );
  }

  Widget _textTab() {
    return TextField(
      controller: _text,
      style: const TextStyle(color: DC.ink, fontSize: 20),
      decoration: _decoration('Letters or symbols', hint: 'e.g. GY, ॐ, 5K'),
      onChanged: (value) {
        final limited = HabitLook.limit(value);
        if (limited != value) {
          _text.value = TextEditingValue(
            text: limited,
            selection: TextSelection.collapsed(offset: limited.length),
          );
        }
        if (limited.isNotEmpty) widget.onChanged('text:$limited');
      },
    );
  }

  InputDecoration _decoration(
    String label, {
    String? hint,
    Widget? prefix,
    Widget? suffix,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: prefix,
      suffixIcon: suffix,
      labelStyle: const TextStyle(color: DC.muted),
      hintStyle: const TextStyle(color: DC.faint),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: DC.line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: DC.accentDeep, width: 2),
      ),
    );
  }
}
