/// Leitner box review intervals in days, indexed by box number.
/// Index 0 is unused; boxes 1..5 are always present.
const List<int> boxIntervalsDays = [0, 1, 2, 4, 7, 14];

const int classicMaxBox = 5;
const int absoluteMaxBox = 8;

/// Default max learning box when a space has not enabled extra houses.
const int maxBox = classicMaxBox;

/// Archive box after a successful review in the last enabled learning house.
/// With the classic 5 houses this stays at 6 for backward-compatible data.
const int learnedBox = classicMaxBox + 1;

const int extraBoxMinDays = 16;
const int extraBoxMaxDays = 60;
const int defaultBox6Days = 21;
const int defaultBox7Days = 30;
const int defaultBox8Days = 45;

const List<String> pastelColors = [
  'lavender',
  'mint',
  'peach',
  'sky',
  'rose',
  'lemon',
  'coral',
  'teal',
  'lilac',
  'sand',
  'slate',
  'berry',
];
