/// Keeps [text] left-to-right inside a right-to-left line.
///
/// A phone number grouped as `0919 520 0872` is three runs of digits separated
/// by spaces. In a Persian line the bidi algorithm lays those runs out right to
/// left, and the number reads `0872 520 0919`. Wrapping it in a left-to-right
/// isolate (U+2066 … U+2069) keeps its own order without changing the alignment
/// of the line around it.
String ltrIsolate(String text) => '⁦$text⁩';
