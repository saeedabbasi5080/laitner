import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:recall/core/localization/app_strings.dart';
import 'package:recall/core/utils/tag_utils.dart';
import 'package:recall/data/utils/card_media_store.dart';
import 'package:recall/domain/entities/card_media.dart';
import 'package:recall/domain/entities/deck.dart';
import 'package:recall/domain/entities/deck_color.dart';
import 'package:recall/domain/entities/duplicate_card.dart';
import 'package:recall/domain/entities/flashcard.dart';
import 'package:recall/domain/services/id_generator.dart';
import 'package:recall/domain/usecases/add_card_usecase.dart';
import 'package:recall/domain/usecases/add_deck_usecase.dart';
import 'package:recall/domain/usecases/get_decks_usecase.dart';

part 'add_card_state.dart';

class AddCardCubit extends Cubit<AddCardState> {
  AddCardCubit({
    required String deckId,
    required String spaceId,
    required AddCardUseCase addCardUseCase,
    required AddDeckUseCase addDeckUseCase,
    required GetDecksUseCase getDecksUseCase,
    required IdGenerator idGenerator,
    required CardMediaStore mediaStore,
  }) : _spaceId = spaceId,
       _addCardUseCase = addCardUseCase,
       _addDeckUseCase = addDeckUseCase,
       _getDecksUseCase = getDecksUseCase,
       _idGenerator = idGenerator,
       _mediaStore = mediaStore,
       super(AddCardState(draftId: idGenerator.generateId(), deckId: deckId));

  final String _spaceId;
  final AddCardUseCase _addCardUseCase;
  final AddDeckUseCase _addDeckUseCase;
  final GetDecksUseCase _getDecksUseCase;
  final IdGenerator _idGenerator;
  final CardMediaStore _mediaStore;

  Future<void> loadDecks() async {
    final decks = await _getDecksUseCase(_spaceId);
    emit(state.copyWith(decks: decks));
  }

  void selectDeck(String deckId) {
    emit(state.copyWith(deckId: deckId));
  }

  Future<void> createDeck(String name, DeckColor color) async {
    final deck = Deck(
      id: _idGenerator.generateId(),
      spaceId: _spaceId,
      name: name.trim(),
      color: color,
      createdAt: DateTime.now(),
    );
    final saved = await _addDeckUseCase(deck);
    final decks = await _getDecksUseCase(_spaceId);
    emit(state.copyWith(decks: decks, deckId: saved.id));
  }

  void setFront({required String plain, required String style}) {
    emit(
      state.copyWith(
        front: plain,
        frontStyle: style,
        status: AddCardStatus.initial,
        clearError: true,
      ),
    );
  }

  void setBack({required String plain, required String style}) {
    emit(
      state.copyWith(
        back: plain,
        backStyle: style,
        status: AddCardStatus.initial,
        clearError: true,
      ),
    );
  }

  void setTags(List<String> tags) {
    emit(
      state.copyWith(
        tags: TagUtils.normalize(tags),
        status: AddCardStatus.initial,
        clearError: true,
      ),
    );
  }

  Future<bool> attachBytes({
    required CardMediaSide side,
    required CardMediaKind kind,
    required List<int> bytes,
    required String fileName,
  }) async {
    try {
      final item = await _mediaStore.importBytes(
        draftId: state.draftId,
        side: side,
        kind: kind,
        bytes: bytes,
        fileName: fileName,
      );
      emit(
        state.copyWith(
          media: [...state.media, item],
          status: AddCardStatus.initial,
          clearError: true,
        ),
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> attachFile({
    required CardMediaSide side,
    required CardMediaKind kind,
    required String filePath,
    required String fileName,
  }) async {
    try {
      final item = await _mediaStore.importFile(
        draftId: state.draftId,
        side: side,
        kind: kind,
        filePath: filePath,
        fileName: fileName,
      );
      emit(
        state.copyWith(
          media: [...state.media, item],
          status: AddCardStatus.initial,
          clearError: true,
        ),
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> removeMedia(CardMedia media) async {
    await _mediaStore.delete(media);
    emit(
      state.copyWith(
        media: [
          for (final item in state.media)
            if (item.id != media.id) item,
        ],
        status: AddCardStatus.initial,
        clearError: true,
      ),
    );
  }

  Future<bool> save() async {
    if (!state.canSave) return false;

    emit(state.copyWith(status: AddCardStatus.saving, clearError: true));
    try {
      final card = Flashcard(
        id: state.draftId,
        deckId: state.deckId,
        front: state.front.trim(),
        back: state.back.trim(),
        box: 1,
        createdAt: DateTime.now(),
        tags: state.tags,
        frontStyle: state.frontStyle,
        backStyle: state.backStyle,
        media: state.media,
      );
      await _addCardUseCase(card, spaceId: _spaceId);
      emit(state.copyWith(status: AddCardStatus.saved));
      return true;
    } on DuplicateCardException catch (e) {
      emit(
        state.copyWith(
          status: AddCardStatus.duplicate,
          errorMessage: AppStrings.duplicateCardInDeck(e.deckName),
        ),
      );
      return false;
    } catch (e) {
      emit(
        state.copyWith(
          status: AddCardStatus.error,
          errorMessage: e.toString(),
        ),
      );
      return false;
    }
  }

  @override
  Future<void> close() async {
    if (state.status != AddCardStatus.saved) {
      for (final item in state.media) {
        await _mediaStore.delete(item);
      }
    }
    return super.close();
  }
}
