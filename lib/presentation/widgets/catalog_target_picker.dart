import 'package:flutter/material.dart';
import 'package:recall/core/localization/app_strings.dart';
import 'package:recall/domain/entities/deck.dart';
import 'package:recall/domain/entities/deck_color.dart';
import 'package:recall/domain/entities/learning_space.dart';
import 'package:recall/domain/usecases/add_catalog_words_usecase.dart';
import 'package:recall/domain/usecases/get_decks_usecase.dart';
import 'package:recall/domain/usecases/get_spaces_usecase.dart';
import 'package:recall/injection.dart';
import 'package:recall/presentation/widgets/soft_ui.dart';

/// What the learner picked: a space and a deck in it, new or existing.
class CatalogTargetChoice {
  const CatalogTargetChoice({required this.space, required this.target, this.existingDeck});

  final LearningSpace space;
  final CatalogTarget target;

  /// The deck when an existing one was picked.
  final Deck? existingDeck;
}

/// Picks where a ready-made list goes: a space (when there is more than one),
/// then a new deck named after the list or one the space already has.
///
/// Reports the choice on every change, or null while it is incomplete (no
/// space yet, or a new deck with no name).
class CatalogTargetPicker extends StatefulWidget {
  const CatalogTargetPicker({
    super.key,
    required this.defaultName,
    required this.colorSeed,
    required this.onChanged,
    this.enabled = true,
    this.getSpaces,
    this.getDecks,
  });

  final String defaultName;

  /// Picks the new deck's colour, so the same list gets the same colour.
  final int colorSeed;
  final ValueChanged<CatalogTargetChoice?> onChanged;
  final bool enabled;

  /// Tests pass these; the app uses the registered ones.
  final GetSpacesUseCase? getSpaces;
  final GetDecksUseCase? getDecks;

  @override
  State<CatalogTargetPicker> createState() => _CatalogTargetPickerState();
}

class _CatalogTargetPickerState extends State<CatalogTargetPicker> {
  late final TextEditingController _name = TextEditingController(text: widget.defaultName);
  List<LearningSpace>? _spaces;
  List<Deck> _decks = const [];
  LearningSpace? _space;
  String? _deckId;
  bool _newDeck = true;

  @override
  void initState() {
    super.initState();
    _loadSpaces();
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _loadSpaces() async {
    final spaces = await (widget.getSpaces ?? sl<GetSpacesUseCase>())();
    if (!mounted) return;
    setState(() => _spaces = spaces);
    if (spaces.isNotEmpty) await _pickSpace(spaces.first);
    _report();
  }

  Future<void> _pickSpace(LearningSpace space) async {
    setState(() {
      _space = space;
      _decks = const [];
      _deckId = null;
    });
    _report();
    final decks = await (widget.getDecks ?? sl<GetDecksUseCase>())(space.id);
    if (!mounted || _space?.id != space.id) return;
    setState(() {
      _decks = decks;
      _deckId = decks.isEmpty ? null : decks.first.id;
      if (decks.isEmpty) _newDeck = true;
    });
    _report();
  }

  void _report() {
    final space = _space;
    if (space == null) return widget.onChanged(null);
    if (_newDeck) {
      final name = _name.text.trim();
      return widget.onChanged(name.isEmpty
          ? null
          : CatalogTargetChoice(
              space: space,
              target: NewDeckTarget(
                spaceId: space.id,
                name: name,
                color: DeckColor.values[widget.colorSeed % DeckColor.values.length],
              ),
            ));
    }
    final deck = _decks.where((deck) => deck.id == _deckId).firstOrNull;
    widget.onChanged(deck == null
        ? null
        : CatalogTargetChoice(space: space, target: ExistingDeckTarget(deck.id), existingDeck: deck));
  }

  @override
  Widget build(BuildContext context) {
    final spaces = _spaces;
    if (spaces == null) return const Center(child: CircularProgressIndicator());
    if (spaces.isEmpty) return const Text(AppStrings.createSpaceFirst);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (spaces.length > 1) ...[
          const Text(AppStrings.catalogSpace, style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: _space?.id,
            isExpanded: true,
            items: [for (final space in spaces) DropdownMenuItem(value: space.id, child: Text(space.name))],
            onChanged: widget.enabled ? (id) => _pickSpace(spaces.firstWhere((space) => space.id == id)) : null,
          ),
          const SizedBox(height: 16),
        ],
        SegmentedButton<bool>(
          segments: [
            const ButtonSegment(value: true, label: Text(AppStrings.catalogNewDeck), icon: Icon(Icons.add_rounded)),
            ButtonSegment(
              value: false,
              label: const Text(AppStrings.catalogExistingDeck),
              icon: const Icon(Icons.folder_open_outlined),
              enabled: _decks.isNotEmpty,
            ),
          ],
          selected: {_newDeck},
          onSelectionChanged: widget.enabled
              ? (value) {
                  setState(() => _newDeck = value.first);
                  _report();
                }
              : null,
        ),
        const SizedBox(height: 14),
        if (_newDeck)
          SoftTextField(
            controller: _name,
            hint: AppStrings.catalogDeckName,
            label: AppStrings.catalogDeckName,
            onChanged: (_) => _report(),
          )
        else
          DropdownButtonFormField<String>(
            initialValue: _deckId,
            isExpanded: true,
            decoration: const InputDecoration(labelText: AppStrings.catalogPickDeck),
            items: [for (final deck in _decks) DropdownMenuItem(value: deck.id, child: Text(deck.name))],
            onChanged: widget.enabled
                ? (id) {
                    setState(() => _deckId = id);
                    _report();
                  }
                : null,
          ),
      ],
    );
  }
}
