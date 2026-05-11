import 'package:flutter/material.dart';

const Map<String, List<String>> _emojiCategories = {
  'Smileys': [
    '😀', '😃', '😄', '😁', '😅', '😂', '🤣', '😊', '😇', '🙂', '😉', '😌',
    '😍', '🥰', '😘', '😗', '😙', '😚', '🥲', '😋', '😛', '😜', '🤪', '😝',
    '🤑', '🤗', '🤭', '🫢', '🫣', '🤫', '🤔', '🫡', '🤐', '🤨', '😐', '😑',
    '😶', '🫥', '😏', '😒', '🙄', '😬', '😮‍💨', '🤥', '😌', '😔', '😪', '🤤',
    '😴', '😷', '🤒', '🤕', '🤢', '🤮', '🥴', '😵', '🤯', '🤠', '🥳', '🥸',
    '😎', '🤓', '🧐', '😕', '🫤', '😟', '🙁', '😮', '😯', '😲', '😳', '🥺',
    '😦', '😧', '😨', '😰', '😥', '😢', '😭', '😱', '😖', '😣', '😞', '😓',
    '😩', '😫', '🥱', '😤', '😡', '😠', '🤬', '😈', '👿', '💀', '☠️', '💩',
    '🤡', '👹', '👺', '👻', '👽', '👾', '🤖', '😺', '😸', '😹', '😻', '😼',
    '😽', '🙀', '😿', '😾',
  ],
  'Gestos': [
    '👋', '🤚', '🖐️', '✋', '🖖', '🫱', '🫲', '🫳', '🫴', '👌', '🤌', '🤏',
    '✌️', '🤞', '🫰', '🤟', '🤘', '🤙', '👈', '👉', '👆', '🖕', '👇', '☝️',
    '🫵', '👍', '👎', '✊', '👊', '🤛', '🤜', '👏', '🙌', '🫶', '👐', '🤲',
    '🤝', '🙏', '✍️', '💅', '🤳', '💪', '🦵', '🦶', '👂', '🦻', '👃', '🧠',
    '🫀', '🫁', '🦷', '🦴', '👀', '👁️', '👅', '👄',
  ],
  'Pessoas': [
    '👶', '🧒', '👦', '👧', '🧑', '👱', '👨', '🧔', '👩', '🧓', '👴', '👵',
    '🙍', '🙎', '🙅', '🙆', '💁', '🙋', '🧏', '🙇', '🤦', '🤷', '💃', '🕺',
    '👯', '🧖', '🧗', '🤸', '⛹️', '🏋️', '🚴', '🚵', '🏇', '🧘', '🏄', '🏊',
    '🤽', '🚣', '🧗', '🚶', '🧍', '🧎', '🏃', '💆', '💇', '🛀', '🛌',
    '👪', '👫', '👬', '👭', '💏', '💑', '👨‍👩‍👧‍👦',
  ],
  'Animais': [
    '🐶', '🐱', '🐭', '🐹', '🐰', '🦊', '🐻', '🐼', '🐻‍❄️', '🐨', '🐯', '🦁',
    '🐮', '🐷', '🐸', '🐵', '🙈', '🙉', '🙊', '🐒', '🐔', '🐧', '🐦', '🐤',
    '🐣', '🐥', '🦆', '🦅', '🦉', '🦇', '🐺', '🐗', '🐴', '🦄', '🐝', '🪱',
    '🐛', '🦋', '🐌', '🐞', '🐜', '🪰', '🪲', '🪳', '🦟', '🦗', '🕷️', '🦂',
    '🐢', '🐍', '🦎', '🦖', '🦕', '🐙', '🦑', '🪼', '🦐', '🦞', '🦀', '🐡',
    '🐠', '🐟', '🐬', '🐳', '🐋', '🦈', '🪸', '🐊', '🐅', '🐆', '🦓', '🦍',
    '🦧', '🐘', '🦛', '🦏', '🐪', '🐫', '🦒', '🦘', '🦬', '🐃', '🐂', '🐄',
    '🐎', '🐖', '🐏', '🐑', '🦙', '🐐', '🦌', '🐕', '🐩', '🦮', '🐕‍🦺', '🐈',
    '🐈‍⬛', '🪶', '🐓', '🦃', '🦤', '🦚', '🦜', '🦢', '🦩', '🕊️', '🐇', '🦝',
    '🦨', '🦡', '🦫', '🦦', '🦥', '🐁', '🐀', '🐿️', '🦔', '🐾', '🐉', '🐲',
  ],
  'Natureza': [
    '🌸', '💮', '🪷', '🏵️', '🌹', '🥀', '🌺', '🌻', '🌼', '🌷', '🌱', '🪴',
    '🌲', '🌳', '🌴', '🌵', '🌾', '🌿', '☘️', '🍀', '🍁', '🍂', '🍃', '🪹',
    '🪺', '🍄', '🌰', '🦀', '🦞', '🪨', '🌍', '🌎', '🌏', '🌐', '🌑', '🌒',
    '🌓', '🌔', '🌕', '🌖', '🌗', '🌘', '🌙', '🌚', '🌛', '🌜', '☀️', '🌝',
    '🌞', '🪐', '⭐', '🌟', '🌠', '🌌', '☁️', '⛅', '🌈', '🌤️', '🌥️', '🌦️',
    '🌧️', '🌨️', '🌩️', '🌪️', '🌫️', '🌬️', '💧', '💨', '❄️', '☃️', '⛄', '🔥',
  ],
  'Comida': [
    '🍇', '🍈', '🍉', '🍊', '🍋', '🍌', '🍍', '🥭', '🍎', '🍏', '🍐', '🍑',
    '🍒', '🍓', '🫐', '🥝', '🍅', '🫒', '🥥', '🥑', '🍆', '🥔', '🥕', '🌽',
    '🌶️', '🫑', '🥒', '🥬', '🥦', '🧄', '🧅', '🍄', '🥜', '🫘', '🌰', '🍞',
    '🥐', '🥖', '🫓', '🥨', '🧀', '🥚', '🍳', '🧈', '🥞', '🧇', '🥓', '🥩',
    '🍗', '🍖', '🦴', '🌭', '🍔', '🍟', '🍕', '🫓', '🥪', '🥙', '🧆', '🌮',
    '🌯', '🫔', '🥗', '🥘', '🫕', '🥫', '🍝', '🍜', '🍲', '🍛', '🍣', '🍱',
    '🥟', '🦪', '🍤', '🍙', '🍚', '🍘', '🍥', '🥠', '🥮', '🍢', '🍡', '🍧',
    '🍨', '🍦', '🥧', '🧁', '🍰', '🎂', '🍮', '🍭', '🍬', '🍫', '🍿', '🧂',
    '🍩', '🍪', '🌰', '🥛', '🍼', '🫖', '☕', '🍵', '🧉', '🥤', '🧃', '🧋',
    '🍶', '🍺', '🍻', '🥂', '🍷', '🫗', '🥃', '🍸', '🍹', '🧊',
  ],
  'Atividades': [
    '⚽', '🏀', '🏈', '⚾', '🥎', '🎾', '🏐', '🏉', '🥏', '🎱', '🪀', '🏓',
    '🏸', '🏒', '🏑', '🥍', '🏏', '🪃', '🥅', '⛳', '🪁', '🏹', '🎣', '🤿',
    '🥊', '🥋', '🎽', '🛹', '🛼', '🛷', '⛸️', '🥌', '🎿', '⛷️', '🏂', '🪂',
    '🏋️', '🤼', '🤸', '🤺', '⛹️', '🤾', '🏌️', '🏇', '🧘', '🏄', '🏊', '🤽',
    '🚣', '🧗', '🚵', '🚴', '🎯', '🎳', '🎲', '♟️', '🃏', '🀄', '🎴', '🎭',
    '🎨', '🧵', '🪡', '🧶', '🪢',
  ],
  'Objetos': [
    '🔇', '🔈', '🔉', '🔊', '📢', '📣', '📯', '🔔', '🔕', '🎼', '🎵', '🎶',
    '🎙️', '🎚️', '🎛️', '🎤', '🎧', '📻', '🎷', '🪗', '🎸', '🎹', '🎺', '🎻',
    '🪕', '🥁', '🪘', '📱', '📲', '☎️', '📞', '📟', '📠', '🔋', '🪫', '🔌',
    '💻', '🖥️', '🖨️', '⌨️', '🖱️', '🖲️', '💽', '💾', '💿', '📀', '🧮', '📷',
    '📸', '📹', '🎥', '📽️', '🎞️', '📞', '🔍', '🔎', '🕯️', '💡', '🔦', '🏮',
    '🪔', '📔', '📕', '📖', '📗', '📘', '📙', '📚', '📓', '📒', '📃', '📜',
    '📄', '📰', '🗞️', '📑', '🔖', '🏷️', '💰', '🪙', '💴', '💵', '💶', '💷',
    '💸', '💳', '🧾', '✉️', '📧', '📨', '📩', '📤', '📥', '📦', '📫', '📪',
    '📬', '📭', '📮', '🗳️', '✏️', '✒️', '🖋️', '🖊️', '🖌️', '🖍️', '📝', '📎',
    '🖇️', '📏', '📐', '✂️', '🗃️', '🗄️', '🗑️', '🔒', '🔓', '🔏', '🔐', '🔑',
    '🗝️', '🔨', '🪓', '⛏️', '⚒️', '🛠️', '🗡️', '⚔️', '💣', '🪃', '🏹', '🛡️',
    '🔧', '🔩', '⚙️', '🗜️', '⚖️', '🦯', '🔗', '⛓️', '🪝', '🧰', '🧲', '🪜',
    '⚗️', '🧪', '🧫', '🧬', '🔬', '🔭', '📡', '💉', '🩸', '💊', '🩹', '🩺',
  ],
  'Símbolos': [
    '❤️', '🧡', '💛', '💚', '💙', '💜', '🖤', '🤍', '🤎', '💕', '💞', '💓',
    '💗', '💖', '💘', '💝', '💟', '☮️', '✝️', '☪️', '🕉️', '☸️', '✡️', '🔯',
    '🕎', '☯️', '🪯', '✝️', '☦️', '☪️', '☮️', '🕎', '🔯', '♈', '♉', '♊',
    '♋', '♌', '♍', '♎', '♏', '♐', '♑', '♒', '♓', '⛎', '🆔', '⚛️',
    '🉑', '☢️', '☣️', '📴', '📳', '🈶', '🈚', '🈸', '🈺', '🈷️', '✴️', '🆚',
    '💮', '🉐', '㊙️', '㊗️', '🈴', '🈵', '🈹', '🈲', '🅰️', '🅱️', '🆎', '🆑',
    '🅾️', '🆘', '🛑', '⛔', '📛', '🚫', '💢', '♨️', '🚷', '🚯', '🚳', '🚱',
    '🔞', '📵', '🚭', '❗', '❕', '❓', '❔', '‼️', '⁉️', '🔅', '🔆', '💯',
    '🔠', '🔡', '🔢', '🔣', '🔤', '🅿️', '🆗', '🆕', '🆙', '🆒', '🆓', 'ℹ️',
    '🆑', '🆔', '⚕️', '♿', '🚻', '🚹', '🚺', '🚼', '🚾', '⚠️', '🚸', '⛔',
    '🚫', '🚳', '🚭', '🚯', '🚱', '🚷', '📵', '🔞', '☢️', '☣️',
  ],
  'BandEiras': [
    '🏳️', '🏴', '🏁', '🚩', '🎌', '🏴‍☠️',
    '🇧🇷', '🇵🇹', '🇺🇸', '🇬🇧', '🇫🇷', '🇩🇪', '🇮🇹', '🇪🇸', '🇯🇵', '🇰🇷',
    '🇨🇳', '🇷🇺', '🇮🇳', '🇨🇦', '🇦🇺', '🇦🇷', '🇲🇽', '🇨🇱', '🇨🇴', '🇵🇾',
    '🇺🇾', '🇻🇪', '🇵🇪', '🇪🇨', '🇧🇴', '🇵🇦', '🇨🇷', '🇨🇺', '🇩🇴', '🇭🇹',
    '🇸🇻', '🇬🇹', '🇭🇳', '🇳🇮', '🇪🇸', '🇦🇴', '🇲🇿', '🇨🇻', '🇬🇼', '🇸🇹',
    '🇬🇶', '🇹🇱', '🇲🇴', '🇭🇰',
  ],
};

class EmojiPickerSheet extends StatefulWidget {
  final void Function(String emoji) onSelected;

  const EmojiPickerSheet({super.key, required this.onSelected});

  @override
  State<EmojiPickerSheet> createState() => _EmojiPickerSheetState();
}

class _EmojiPickerSheetState extends State<EmojiPickerSheet> {
  String _search = '';
  late final TextEditingController _searchCtrl;
  late final List<_EmojiCategory> _categories;
  String? _activeCategory;

  @override
  void initState() {
    super.initState();
    _searchCtrl = TextEditingController();
    _categories = _emojiCategories.entries
        .map((e) => _EmojiCategory(e.key, e.value))
        .toList();
    _activeCategory = _categories.first.name;
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<_EmojiCategory> get _filtered {
    if (_search.isEmpty) return _categories;
    final q = _search.toLowerCase();
    return _categories
        .map((c) => _EmojiCategory(
              c.name,
              c.emojis.where((e) => e.toLowerCase().contains(q)).toList(),
            ))
        .where((c) => c.emojis.isNotEmpty)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    final theme = Theme.of(context);

    return Container(
      height: MediaQuery.of(context).size.height * 0.5,
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 8),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurfaceVariant.withAlpha(80),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Buscar emoji...',
                prefixIcon: const Icon(Icons.search, size: 20),
                isDense: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              onChanged: (v) => setState(() => _search = v),
            ),
          ),
          if (_search.isEmpty)
            _buildCategoryTabs(),
          Expanded(
            child: _search.isEmpty
                ? _buildCategorizedGrid()
                : _buildSearchGrid(filtered),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTabs() {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        itemCount: _categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 4),
        itemBuilder: (context, index) {
          final cat = _categories[index];
          final active = cat.name == _activeCategory;
          return FilterChip(
            label: Text(
              cat.emojis.first,
              style: const TextStyle(fontSize: 18),
            ),
            tooltip: cat.name,
            selected: active,
            onSelected: (_) {
              setState(() => _activeCategory = cat.name);
            },
            showCheckmark: false,
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.symmetric(horizontal: 4),
          );
        },
      ),
    );
  }

  Widget _buildCategorizedGrid() {
    final cat = _categories.firstWhere(
      (c) => c.name == _activeCategory,
      orElse: () => _categories.first,
    );
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 8,
        childAspectRatio: 1,
      ),
      itemCount: cat.emojis.length,
      itemBuilder: (context, index) {
        return _EmojiCell(
          emoji: cat.emojis[index],
          onTap: () {
            widget.onSelected(cat.emojis[index]);
            Navigator.pop(context);
          },
        );
      },
    );
  }

  Widget _buildSearchGrid(List<_EmojiCategory> filtered) {
    final all = filtered.expand((c) => c.emojis).toList();
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 8,
        childAspectRatio: 1,
      ),
      itemCount: all.length,
      itemBuilder: (context, index) {
        return _EmojiCell(
          emoji: all[index],
          onTap: () {
            widget.onSelected(all[index]);
            Navigator.pop(context);
          },
        );
      },
    );
  }
}

class _EmojiCategory {
  final String name;
  final List<String> emojis;
  const _EmojiCategory(this.name, this.emojis);
}

class _EmojiCell extends StatelessWidget {
  final String emoji;
  final VoidCallback onTap;

  const _EmojiCell({required this.emoji, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Center(
        child: Text(emoji, style: const TextStyle(fontSize: 24)),
      ),
    );
  }
}
