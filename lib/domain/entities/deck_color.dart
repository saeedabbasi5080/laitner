enum DeckColor {
  lavender,
  mint,
  peach,
  sky,
  rose,
  lemon,
  coral,
  teal,
  lilac,
  sand,
  slate,
  berry;

  static DeckColor fromString(String value) {
    return DeckColor.values.firstWhere(
      (c) => c.name == value,
      orElse: () => DeckColor.lavender,
    );
  }
}
