/// تمام متن‌های فارسی برنامه
library;

import 'package:recall/domain/entities/review_settings.dart';

abstract final class AppStrings {
  static const appTitle = 'Atilearn';

  // فضاهای یادگیری
  static const yourSpaces = 'فضاهای یادگیری';
  static const spacesHint =
      'هر فضا محیط مستقل است: دسته‌ها، کارت‌ها، آمار، اکسل و تنظیمات مرور جدا دارند.';
  static const newSpace = 'فضای جدید';
  static const createSpace = 'ساخت فضا';
  static const editSpace = 'ویرایش فضا';
  static const spaceName = 'نام فضا';
  static const spaceNameHint = 'مثلاً زبان ترکی';
  static const deleteSpace = 'حذف فضا';
  static const deleteSpaceConfirm =
      'آیا از حذف این فضا و تمام دسته‌ها، کارت‌ها، آمار و فایل‌های اکسل آن مطمئن هستید؟';
  static const deleteSpaceIntro =
      'اگر این فضا را حذف کنید، دسته‌ها، کارت‌ها، آمار مرور، فایل‌های اکسل و تنظیمات همان فضا از بین می‌روند و قابل بازگردانی نیستند. اگر می‌خواهید کارت‌ها بمانند، اول آن‌ها را به فضای دیگری منتقل کنید.';
  static const deleteSpaceQuestion = 'محتوای این فضا چه شود؟';
  static const deleteSpaceWithContent = 'حذف فضا و همه کارت‌ها';
  static const deleteSpaceWithContentWarning =
      'این کار قابل برگشت نیست. همه دسته‌ها و کارت‌های این فضا، پیشرفت مرور و جایگاه‌شان در خانه‌های لایتنر، آمار و فایل‌های اکسل پاک می‌شود.';
  static const deleteEmptySpaceConfirm =
      'این فضا خالی است. با تأیید، فقط خود فضا حذف می‌شود.';
  static const transferSpaceCards = 'انتقال کارت‌ها به فضای دیگر';
  static const transferSpaceCardsHint =
      'دسته‌ها و کارت‌ها حفظ می‌شوند و به فضای انتخابی می‌روند. خود این فضا حذف می‌شود.';
  static const selectTargetSpace = 'انتخاب فضای مقصد';
  static const noOtherSpacesToTransfer =
      'فضای دیگری نیست. اول یک فضای جدید بسازید یا محتوا را حذف کنید.';
  static const spaceContentTransferred = 'کارت‌ها منتقل شدند و فضا حذف شد';
  static const emptySpaces =
      'هنوز فضایی نساخته‌اید. با دکمه + اولین فضای یادگیری را بسازید.';
  static const dataLoadFailed = 'داده‌ها بارگذاری نشد. دوباره تلاش کنید.';
  static const spaceSaveFailed = 'فضا ذخیره نشد. دوباره تلاش کنید.';
  static const cannotDeleteLastSpace = 'حداقل یک فضا باید باقی بماند.';
  static String spaceLimitReached(int max) =>
      'حداکثر $max فضا می‌توانید بسازید.';
  static String spaceSummary(int decks, int cards, int due) =>
      '$decks دسته · $cards کارت · $due ${AppStrings.due}';

  // صفحه اصلی
  static const today = 'امروز';
  static const yourDecks = 'دسته‌های شما';
  static const dueToday = 'مرور امروز';
  static const cards = 'کارت';
  static const due = 'سررسید';
  static const done = 'تمام';
  static const addCard = '+ افزودن کارت';
  static const study = 'مرور ←';
  static const emptyDecks =
      'هنوز دسته‌ای نساخته‌اید. با دکمه + اولین دسته را بسازید.';
  static const newDeck = 'دسته جدید';
  static const deckName = 'نام دسته';
  static const deckNameHint = 'مثلاً واژگان فرانسه';
  static const accentColor = 'رنگ';
  static const createDeck = 'ساخت دسته';
  static const editDeck = 'ویرایش دسته';
  static const saveChanges = 'ذخیره تغییرات';
  static const deleteDeck = 'حذف دسته';
  static const deleteDeckConfirm =
      'آیا از حذف این دسته و تمام کارت‌های آن مطمئن هستید؟';
  static const deleteDeckQuestion =
      'کارت‌های این دسته چه شوند؟';
  static const deleteDeckWithCards = 'حذف دسته و همه کارت‌ها';
  static const deleteDeckWithCardsHint =
      'دسته و تمام کارت‌های داخل آن برای همیشه حذف می‌شوند و قابل بازگردانی نیستند.';
  static const deleteDeckWithCardsWarning =
      'این کار قابل برگشت نیست. همه کارت‌های این دسته، پیشرفت مرور و جایگاه‌شان در خانه‌های لایتنر حذف می‌شود.';
  static const transferDeckCards = 'انتقال کارت‌ها به دسته دیگر';
  static const transferDeckCardsHint =
      'کارت‌ها حفظ می‌شوند و فقط به دسته دیگری در همین فضا منتقل می‌شوند.';
  static const selectTargetDeck = 'انتخاب دسته مقصد';
  static const noOtherDecksToTransfer =
      'دسته دیگری در این فضا نیست. اول یک دسته جدید بسازید یا کارت‌ها را حذف کنید.';
  static const cardsTransferred = 'کارت‌ها منتقل شدند';
  static const transferCards = 'انتقال کارت‌ها';
  static const transferCard = 'انتقال به دسته دیگر';
  static const transferAllCards = 'انتقال همه کارت‌ها';
  static const transferSelectedCards = 'انتقال انتخاب‌شده‌ها';
  static const createNewDeck = 'ساخت دسته جدید';
  static const cancel = 'انصراف';
  static const delete = 'حذف';
  static const importExcel = 'ورود از اکسل';
  static const importExcelHint = 'ستون اول: روی کارت — ستون دوم: پشت کارت';
  static const exportDeckExcel = 'خروجی اکسل';
  static const exportDeckExcelHint =
      'لغات این دسته با قالب کی‌ولیو ذخیره می‌شود: ستون اول روی کارت، ستون دوم پشت کارت.';
  static const deckExcelExported = 'فایل اکسل ذخیره شد';
  static const deckExcelExportEmpty = 'این دسته کارتی برای خروجی ندارد.';
  static const deckExcelExportFailed =
      'خروجی اکسل انجام نشد. دوباره تلاش کنید.';
  static const importSuccess = 'کارت با موفقیت وارد شد';
  static const importFailed = 'خطا در خواندن فایل اکسل';
  static const noFileSelected = 'فایلی انتخاب نشده';
  static const storagePermissionTitle = 'دسترسی به حافظه';
  static const storagePermissionDenied =
      'برای انتخاب فایل اکسل به دسترسی حافظه نیاز است.';
  static const storagePermissionPermanentlyDenied =
      'دسترسی به حافظه رد شده است. از تنظیمات گوشی، دسترسی را برای این برنامه فعال کنید.';
  static const openSettings = 'رفتن به تنظیمات';
  static const excelLibrary = 'کتابخانه اکسل';
  static const excelLibrarySubtitle =
      'فایل‌ها ذخیره می‌مانند؛ هر بار لغات دلخواه را انتخاب کنید';
  static const excelLibraryEmpty =
      'هنوز فایل اکسلی اضافه نکرده‌اید. با دکمه پایین یک یا چند فایل انتخاب کنید.';
  static const excelFormatGuideTitle = 'راهنمای فایل اکسل';
  static const excelFormatGuideIntro =
      'قبل از انتخاب فایل، مطمئن شوید اکسل شما مطابق قالب زیر است. می‌توانید چند فایل را با هم انتخاب کنید.';
  static const excelFormatRuleFormat = 'فرمت فایل: xlsx یا xls';
  static const excelFormatRuleColumnA = 'ستون اول (A): روی کارت';
  static const excelFormatRuleColumnB = 'ستون دوم (B): پشت کارت';
  static const excelFormatRuleSheet = 'فقط برگه اول فایل خوانده می‌شود';
  static const excelFormatRuleRows =
      'هر ردیفی که هر دو ستون پر باشد یک کارت می‌شود؛ ردیف‌های خالی نادیده گرفته می‌شوند';
  static const excelFormatExampleTitle = 'مثال';
  static const excelFormatExampleFront = 'hello';
  static const excelFormatExampleBack = 'سلام';
  static const excelSelectFile = 'انتخاب فایل‌های اکسل';
  static const importExcelFile = 'افزودن فایل اکسل';
  static String excelFilesImported(int count) =>
      count == 1 ? 'فایل ذخیره شد' : '$count فایل اکسل اضافه شد';
  static String excelSomeFilesFailed(int saved, int failed) =>
      '$saved فایل اضافه شد و $failed فایل خوانده نشد.';
  static const excelFileSaved = 'فایل ذخیره شد';
  static const excelNoRows =
      'ردیف معتبری در فایل پیدا نشد. ستون اول و دوم باید پر باشند.';
  static const excelPending = 'باقی‌مانده';
  static const excelAdded = 'اضافه‌شده';
  static const deleteExcelFile = 'حذف فایل اکسل';
  static const deleteExcelFileConfirm =
      'فقط فایل ذخیره‌شده و فهرست لغات همین فایل از کتابخانه اکسل حذف می‌شود. '
      'کارت‌هایی که قبلاً به دسته‌ها اضافه شده‌اند در برنامه می‌مانند و حذف نمی‌شوند.';
  static const excelImportNotFound = 'فایل اکسل پیدا نشد.';
  static const selectAllPending = 'انتخاب همه';
  static const clearSelection = 'پاک کردن انتخاب';
  static const pendingOnlyRows = 'فقط باقی‌مانده';
  static const addSelectedToDeck = 'افزودن به دسته';
  static const excelAllAdded = 'همه لغات این فایل قبلاً اضافه شده‌اند.';
  static const excelAlreadyAdded = 'قبلاً اضافه شده';
  static const editExcelRow = 'ویرایش لغت';
  static const excelDeleteSelected = 'حذف انتخاب‌شده‌ها';
  static const excelDeleteSelectedFiles = 'حذف فایل‌های اکسل';
  static String excelDeleteSelectedFilesConfirm(int count) =>
      '$count فایل اکسل انتخاب‌شده حذف شود؟ کارت‌هایی که قبلاً اضافه شده‌اند باقی می‌مانند.';
  static String excelFilesDeleted(int count) => '$count فایل حذف شد';
  static String excelSelectedFiles(int count) => '$count فایل انتخاب شد';
  static const excelSelectAll = 'همه را انتخاب کن';
  static const excelAllSelected = 'همه فایل‌ها انتخاب شده‌اند';
  static const selectAll = 'انتخاب همه';
  static const ttsSpeechRateSample = 'Atilearn pronunciation sample';
  static const ttsSpeechRatePlaySample = 'شنیدن نمونه';
  static const ttsSpeechRateStopSample = 'توقف';

  // رفتار کارت اشتباه
  static const dontKnowBehaviourTitle = 'کارت اشتباه برود کجا؟';
  static const justLearnedTitle = 'یاد گرفتی!';
  static String justLearnedCard(String front) =>
      '«$front» به کارت‌های یادگرفته‌شده اضافه شد';
  static const dontKnowBehaviourHint =
      'وقتی کارتی را بلد نبودید، به کدام خانه برگردد؟';
  static String dontKnowBehaviourLabel(DontKnowBehaviour behaviour) =>
      switch (behaviour) {
        DontKnowBehaviour.resetToFirst => 'برود به خانه اول',
        DontKnowBehaviour.stepBack => 'برگردد به خانه قبلی',
      };
  static String dontKnowBehaviourHintFor(DontKnowBehaviour behaviour) =>
      switch (behaviour) {
        DontKnowBehaviour.resetToFirst =>
          'هر بار از اول. مرور سنگین‌تر ولی پایه را کاملاً تکرار می‌کند.',
        DontKnowBehaviour.stepBack =>
          'فقط یک خانه عقب. مرور متعادل‌تر، شبیه رفتار Anki.',
      };
  static const excelDeleteSelectedConfirm =
      'لغات انتخاب‌شده فقط از این فایل اکسل حذف می‌شوند و اگر قبلاً به دسته اضافه شده باشند در برنامه می‌مانند.';
  static const deleteExcelRow = 'حذف لغت';
  static const deleteExcelRowConfirm = 'آیا از حذف این لغت از فایل اکسل مطمئن هستید؟';
  static const learnedCards = 'کارت‌های یادگرفته‌شده';
  static const learnedCardsHint =
      'کارت‌هایی که خانه ۵ را با موفقیت پشت سر گذاشته‌اند اینجا بایگانی می‌شوند';
  static const learnedCardsEmpty = 'هنوز کارتی یادگرفته نشده است.';
  static const returnToBox1 = 'بازگشت به خانه ۱';
  static const returnToBox1Confirm =
      'کارت‌های انتخاب‌شده به خانه ۱ برمی‌گردند و دوباره وارد چرخه مرور می‌شوند.';
  static const returnToBox1Done = 'کارت‌ها به خانه ۱ برگشتند';
  static String boxBadge(int box) => 'خانه $box';
  static const learnedBadge = 'یادگرفته';

  // مرور
  static const question = 'سؤال';
  static const answer = 'پاسخ';
  static const tapToReveal = 'برای دیدن پاسخ ضربه بزنید';
  static const rateBelow = 'میزان یادآوری خود را مشخص کنید';
  static const know = 'بلدم';
  static const dontKnow = 'بلد نیستم';
  static const allDone = 'تمام شد!';
  static const noDueCards = 'الان کارتی برای مرور وجود ندارد.';
  static const noDueTodayHint =
      'کارت‌ها سرجایشان هستند. امروز نوبت مرور هیچ خانه‌ای نرسیده و طبق فاصله لایتنر فردا یا روزهای بعد برمی‌گردند.';
  static const reviewedCards = 'کارت امروز مرور شد';
  static String sessionResultSummary(int correct, int wrong) =>
      '$correct تا درست گفتی و $wrong تا اشتباه بود.';
  static const sessionCorrect = 'درست';
  static const sessionWrong = 'اشتباه';
  static const sessionAccuracy = 'دقت';
  static const backToSpaces = 'بازگشت به فضاها';
  static const backToDecks = 'بازگشت به دسته‌ها';
  static const reviewSettingsSpaceHint =
      'تنظیمات تلفظ، جهت کارت و مرور فقط برای همین فضا ذخیره می‌شوند و با مرور آزاد قاطی نمی‌شوند.';
  static const allDecksReview = 'مرور تجمیعی';
  static const editCard = 'ویرایش کارت';
  static const deleteCard = 'حذف کارت';
  static const deleteCardConfirm = 'آیا از حذف این کارت مطمئن هستید؟';
  static const front = 'روی کارت';
  static const back = 'پشت کارت';
  static const frontHint = 'چه چیزی را یاد می‌گیرید؟';
  static const backHint = 'پاسخ، تعریف یا ترجمه.';
  static const saveCard = 'ذخیره کارت';
  static const newCard = 'کارت جدید';
  static const tags = 'برچسب‌ها';
  static const difficultyTitle = 'سطح سختی';
  static const houseRoleNew = 'تازه';
  static const houseRoleLearning = 'در حال یادگیری';
  static const houseRoleAlmostLearned = 'تقریباً یادگرفته';
  static const houseRoleFresh = 'تازه';
  static const houseRoleLearned = 'یادگرفته‌شده';
  static String houseLabel(int box) => 'خانه $box';
  static String houseNextUp(int box) => 'خانه بعدی: $box';
  static String houseLearnedBadge = 'یادگرفته‌شده';
  static String reviewMistakes(int count) => 'مرور $count کارتی که بلد نبودم';
  static const retryMistakesHint = 'این کارت‌ها را دوباره مرور کن';
  static const todaysMistakes = 'اشتباه‌های امروز';
  static const todaysMistakesHint = 'کارت‌هایی که امروز اشتباه جواب دادی';
  static const noMistakesToday = 'امروز هیچ اشتباهی نداشتی. عالیه!';
  static const reviewMistakesNow = 'مرور دوباره';
  static String mistakeCount(int count) => '$count کارت';
  static String moreCards(int count) => 'و $count کارت دیگر';

  // Daily Excel feed.
  static const dailyExcelFeed = 'ورود روزانه از اکسل';
  static const dailyExcelFeedHint =
      'هر روز مقداری از فایل‌های اکسل را خودکار به دسته‌ی انتخابی اضافه می‌کند.';
  static const dailyFeedPickDeck = 'دسته‌ی مقصد';
  static const dailyFeedPickDeckHint = 'کارت‌های روزانه به این دسته اضافه می‌شوند';
  static const dailyFeedNoDeck = 'یک دسته انتخاب کن';
  static const dailyFeedPickFiles = 'فایل‌های اکسل';
  static const dailyFeedNoFiles = 'فایلی انتخاب نشده';
  static const dailyFeedPickFilesAction = 'افزودن فایل اکسل';
  static const dailyFeedManageFiles = 'مدیریت فایل‌ها';
  static const dailyFeedManageFilesHint =
      'فایل‌ها را از کتابخانه‌ی اکسل انتخاب کن';
  static const dailyFeedDailyLimit = 'سقف کارت روزانه';
  static const dailyFeedDailyLimitHint =
      'در هر روز حداکثر این تعداد کارت وارد دسته می‌شود';
  static const dailyFeedBacklog = 'در صف';
  static const dailyFeedLastRun = 'آخرین اجرا';
  static const dailyFeedNeverRun = 'هنوز اجرا نشده';
  static String dailyFeedBacklogCount(int backlog) => '$backlog کارت در صف است';
  static String dailyFeedLastRunCount(int count) => 'دیروز $count کارت اضافه شد';
  static String dailyFeedLastRunToday(int count) => 'امروز $count کارت اضافه شد';
  static const dailyFeedRunNow = 'همین حالا اضافه کن';
  static String dailyFeedAddedNow(int count) => '$count کارت اضافه شد';
  static String dailyFeedNothingToAdd = 'کارتی برای اضافه کردن نبود';
  static const dailyFeedCatchUpNote =
      'اگر چند روز باز نکنی، کارت‌ها یک‌جا اضافه نمی‌شوند؛ هر بار فقط سقف روزانه آزاد می‌شود و بقیه در صف می‌ماند.';
  static String dailyFeedSelectedFiles(int count) => '$count فایل انتخاب شده';
  static const dailyFeedNoLibraryFiles =
      'اول در کتابخانه‌ی اکسل فایل اضافه کن';
  static const dailyFeedRunning = 'در حال اضافه کردن…';
  static String dailyFeedFileCounts(int pending, int added) =>
      '$pending در صف • $added اضافه‌شده';
  static const dailyFeedNoDeckYet = 'اول در این فضا یک دسته بساز';

  // Simplified statistics screen.
  static const statsToday = 'امروز';
  static const statsTodayHint = 'فقط کارهای امروز، جدا از بازه‌ی زمانی';
  static String statsAnsweredToday(int count) => '$count پاسخ';
  static const statsCorrect = 'درست';
  static const statsStreak = 'پیوستگی';
  static String statsStreakDays(int days) => '$days روز';
  static const statsNotStudiedToday = 'امروز هنوز مروری نکردی';
  static const statsMastery = 'تسلط';
  static const statsMasteryHint = 'سهم کارت‌هایی که به خانه‌ی آخر رسیده‌اند';

  static const statsCardDistribution = 'کارت‌ها';
  static String statsCardDistributionHint(int total) =>
      'مجموع $total کارت';

  static const statsReviewsOverTime = 'مرور در طول زمان';
  static const statsNoReviewsYet = 'در این بازه هنوز مروری نبوده';

  static const statsForecast = 'کارهای پیش رو';
  static const statsForecastHint = 'روزبه‌روز';
  static const statsIfYouStop = 'اگر دست بکشی';
  static const statsDailyLoad = 'میانگین بلندمدت';
  static String statsCardsPerDay(double load) =>
      '${load.round()} کارت در روز';
  static const statsOverdueHidden = 'کارت‌های عقب‌افتاده در این فهرست نیست';
  static const statsReviews = 'مرور';
  static const statsCardsDeletedNote =
      'اگر کارتی حذف شده باشد، تاریخچه‌ی مرورش حفظ می‌شود ولی در این شمارش نمی‌آید.';

  // Forecast: one plain day-by-day list.
  static const forecastToday = 'امروز';
  static const forecastTomorrow = 'فردا';
  static const forecastAfterTomorrow = 'پس‌فردا';
  static const forecastNothingSoon = 'این چند روز کارتی نیست';
  static const forecastAfterThat = 'روزهای بعد';
  static String forecastCardsPerDayFraction(String value) =>
      'حدود $value کارت در روز';
  static const difficultyHint =
      'اختیاری. اگر انتخاب نکنید، چیزی نمایش داده نمی‌شود.';
  static const tagsHint = 'بنویس و فاصله بزن؛ مثلاً فعل  اسم';
  static const attachMedia = 'پیوست';
  static const attachPhoto = 'عکس از گالری';
  static const attachCamera = 'عکس با دوربین';
  static const attachAudio = 'فایل صوتی';
  static const attachVoice = 'ضبط ویس';
  static const recordingVoice = 'در حال ضبط… برای توقف بزن';
  static const stopRecording = 'توقف ضبط';
  static const playAttachment = 'پخش';
  static const stopPlayback = 'توقف';
  static const mediaPermissionDenied = 'دسترسی لازم برای این پیوست داده نشد.';
  static const mediaAttachFailed = 'پیوست اضافه نشد. دوباره تلاش کنید.';
  static const editorBold = 'ضخیم';
  static const editorItalic = 'کج';
  static const editorUnderline = 'زیرخط';
  static const editorColor = 'رنگ';
  static const editorSize = 'اندازه';
  static String duplicateCardInDeck(String deckName) =>
      'این کلمه قبلاً اضافه شده و در دستهٔ «$deckName» وجود دارد.';
  static String excelImportResultSummary(int added, int duplicates) =>
      duplicates == 0
          ? '$added کلمه اضافه شد.'
          : '$added کلمه اضافه شد؛ از این تعداد $duplicates کلمه تکراری بود '
              'که آگاهانه انتخاب شده بود.';
  static String duplicateExistsInDeck(String deckName) =>
      'از قبل در دستهٔ «$deckName» وجود دارد';
  static const excelDuplicateInFile = 'در همین فایل تکرار شده';
  static const excelDuplicateInSpace = 'از قبل در این فضا وجود دارد';
  static const removeDuplicateWords = 'حذف کلمات تکراری از فایل';
  static String removeDuplicateWordsQuestion(int count) =>
      '$count کلمهٔ تکراری پیدا شد. از نسخهٔ ذخیره‌شدهٔ این فایل در کتابخانهٔ اکسل حذف شوند؟';
  static String duplicateWordsRemoved(int count) =>
      '$count کلمهٔ تکراری حذف شد';
  static const box = 'خانه';
  static const boxOverview = 'کارت‌ها در هر خانه';
  static const leitnerHousesTitle = 'کارت‌ها در خانه‌های لایتنر';
  static const leitnerHousesHint =
      'خانه‌های ۱ تا ۵ با فاصله ۱، ۲، ۴، ۸ و ۱۶ روز مرور می‌شوند';
  static String leitnerHousesHintFor(int maxBox) {
    if (maxBox <= 5) return leitnerHousesHint;
    if (maxBox == 6) {
      return '$leitnerHousesHint. خانهٔ ۶ هم در این فضا فعال است.';
    }
    if (maxBox == 7) {
      return '$leitnerHousesHint. خانه‌های ۶ و ۷ هم در این فضا فعال‌اند.';
    }
    return '$leitnerHousesHint. خانه‌های ۶، ۷ و ۸ هم در این فضا فعال‌اند.';
  }
  static const extraLeitnerHouses = 'خانه‌های اضافی لایتنر';
  static const extraLeitnerHousesHint =
      'خانه‌های ۱ تا ۵ همیشه فعال‌اند (۱، ۲، ۴، ۸ و ۱۶ روز). خانه‌های ۶ تا ۸ را برای همین فضا می‌توانید روشن کنید و فاصله مرورشان را بین ۱۷ تا ۶۰ روز بگذارید.';
  static String extraHouseLabel(int box) => 'خانه $box';
  static String extraHouseDays(int days) => '$days روز';
  static const extraHouseRequiresPrevious =
      'برای فعال‌کردن این خانه، خانه قبلی را روشن کنید.';
  static const ttsSpeechRate = 'سرعت تلفظ';
  static const ttsSpeechRateHint =
      'سرعت خواندن کلمات با موتور تبدیل متن به گفتار دستگاه';
  static const ttsSpeechRateSlow = 'آهسته';
  static const ttsSpeechRateNormal = 'عادی';
  static const ttsSpeechRateFast = 'سریع';
  static const newestCards = 'جدیدترین';
  static const currentlyLearning = 'در حال یادگیری';
  static const stableMastered = 'پایدار و مسلط';
  static const viewAll = 'مشاهده همه';
  static const learnedCardsShortHint = 'کارت‌هایی که به خوبی یاد گرفته‌اید';
  static const boxNCards = 'کارت در خانه';
  static const freeReviewBox1 = 'مرور آزاد (خانه ۱)';
  static const freeReview = 'مرور آزاد';
  static const freeReviewSetup = 'تنظیم مرور آزاد';
  static const selectBox = 'انتخاب خانه';
  static const selectReviewDay = 'انتخاب روز مرور';
  static const allReviewDays = 'همه روزها';
  static const reviewSchedule = 'برنامه مرور این خانه';
  static const reviewScheduleHint =
      'تعداد کارت‌ها بر اساس زمان سررسید بعدی تفکیک شده است';
  static const freeReviewPreviewHint =
      'مرور آزاد فقط برای تمرین است و خانه یا زمان‌بندی کارت را تغییر نمی‌دهد.';
  static const freeReviewStudyBadge =
      'مرور تمرینی؛ پاسخ‌ها خانه را تغییر نمی‌دهند';
  static const normalReview = 'نرمال (رو به پشت)';
  static const reversedReview = 'برعکس (پشت به رو)';
  static const resetToBox1 = 'برگرد به خانه اول';
  static const resetToBox1Confirm =
      'کارت به خانه اول برمی‌گرددآیا اطمینان دارید؟';
  static const resetToBox1Done = 'کارت به خانه ۱ برگشت';
  static const freeReviewEmpty = 'در هیچ خانه‌ای کارتی نیست.';
  static const startReview = 'شروع مرور';
  static const addNew = 'افزودن';
  static const addNewDeck = 'دسته جدید';
  static const addNewCard = 'کارت جدید';
  static const selectDeck = 'انتخاب دسته';
  static const noDecksForCard = 'ابتدا یک دسته بسازید.';
  static const whatToAdd = 'چه چیزی می‌خواهید اضافه کنید؟';

  // آمار
  static const statistics = 'آمار یادگیری';
  static const learningOverview = 'نمای کلی روند یادگیری شما';
  static const mastery = 'درصد تسلط';
  static String masteryHint(int box) =>
      'کارت‌هایی که از خانه $box عبور کرده و یادگرفته شده‌اند';
  static const masteredCards = 'کارت مسلط';
  static const boxDistribution = 'ترکیب کارت‌ها';
  static const boxDistributionHint = 'جایگاه فعلی همه کارت‌ها در خانه‌ها';
  static const dailyReviews = 'مرورها';
  static const rangeWeek = '۷ روز اخیر';
  static const rangeMonth = '۳۰ روز اخیر';
  static const rangeQuarter = '۹۰ روز اخیر';
  static const rangeYear = 'یک سال اخیر';
  static const rangeAll = 'کل تاریخچه';
  static const answerRate = 'نرخ پاسخ‌ها';
  static String answerRateHint(String rangeLabel) =>
      'بر اساس مرورهای بازه «$rangeLabel»';
  static const currentStreak = 'تداوم فعلی';
  static const bestStreak = 'بهترین تداوم';
  static const day = 'روز';
  static const futureDue = 'سررسید آینده';
  static const nextSevenDays = '۷ روز آینده؛ معوق‌ها در امروز محاسبه شده‌اند';
  static const todayShort = 'امروز';
  static const tomorrowShort = 'فردا';
  static const noReviewHistory =
      'هنوز مروری ثبت نشده است. از این به بعد نتیجه مرورها در این بخش نمایش داده می‌شود.';
  static const emptyRangeHistory =
      'در این بازه مروری ثبت نشده است. بازه‌ی دیگری را انتخاب کنید.';
  static const reviewHistoryNote =
      'آمار مرور از زمان فعال‌شدن این قابلیت ثبت می‌شود.';
  static const retry = 'تلاش دوباره';

  // اجزای نمودار آمار
  static const stateFresh = 'تازه';
  static const stateLearning = 'در حال یادگیری';
  static const stateLearned = 'یادگرفته‌شده';
  static const activityCalendar = 'تقویم فعالیت';
  static const activityCalendarHint = 'یک سال گذشته؛ هر خانه یک روز';
  static const hourlyBreakdown = 'پراکندگی ساعتی';
  static String hourlyBreakdownHint(String rangeLabel) =>
      'تعداد مرور و درصد موفقیت در هر ساعت — $rangeLabel';
  static const reviewsPerHour = 'مرور در ساعت';
  static const successRate = 'درصد موفقیت';
  static const cumulativeReviews = 'مجموع تا اینجا';
  static const dailyLoad = 'بار روزانه';
  static const dailyLoadHint = 'میانگین تعداد کارت سررسید در هر روز';
  static const overdue = 'معوق';
  static String overdueCount(int count) => '$count کارت معوق از قبل';
  static const ifYouStudyNothing = 'اگر تا آن روز مرور نکنید';
  static String cardsCount(int count) => '$count کارت';
  static const noActivity = 'بدون فعالیت';

  // یادآور مرور
  static const reminders = 'یادآور مرور';
  static const reminderHint = 'در ساعت انتخابی یادآوری می‌شود که چند کارت آماده‌ی مرور است';
  static const reminderTime = 'ساعت یادآوری';
  static const reminderDays = 'روزهای یادآوری';
  static const reminderShowCount = 'نمایش تعداد کارت در یادآوری';
  static const reminderShowCountHint = 'اگر خاموش باشد، یادآوری بدون عدد ارسال می‌شود';
  static const reminderPermissionNeeded = 'برای دریافت یادآوری، اجازه‌ی اعلان بدهید';
  static const reminderUnsupported =
      'زمان‌بندی یادآوری روی این سیستم‌عامل پشتیبانی نمی‌شود.';
  static const reminderBlocked =
      'اعلان‌ها برای این برنامه غیرفعال است. از تنظیمات سیستم آن را روشن کنید.';
  static const reminderEveryDay = 'هر روز';
  static String reminderTitle(String spaceName) => 'یادآور مرور — $spaceName';
  static String reminderBodyCount(int count) => '$count کارت برای مرور آماده است';
  static const reminderBodyEmpty = 'امروز کارتی برای مرور باقی نمانده است';
  static const reminderBodyGeneric = 'وقت مرور کارت‌های این فضا است';
  static String weekdayShort(int weekday) => switch (weekday) {
        DateTime.monday => 'د',
        DateTime.tuesday => 'س',
        DateTime.wednesday => 'چ',
        DateTime.thursday => 'پ',
        DateTime.friday => 'ج',
        DateTime.saturday => 'ش',
        DateTime.sunday => 'ی',
        _ => '',
      };

  // جزئیات دسته
  static const deck = 'دسته';
  static const deckNotFound = 'دسته پیدا نشد.';
  static const studyDeck = 'مرور دسته';
  static const studyNCards = 'مرور';
  static const allCards = 'همه کارت‌ها';

  // تنظیمات
  static const settings = 'تنظیمات';
  static const appearance = 'ظاهر';
  static const darkMode = 'حالت شب';
  static const lightMode = 'حالت روز';
  static const themeMode = 'تم برنامه';
  static const themeAccent = 'رنگ تم این فضا';
  static const themeAccentHint =
      'رنگ ظاهر فقط برای همین فضا ذخیره می‌شود و فضاهای دیگر را تغییر نمی‌دهد';
  static const pronunciation = 'تلفظ';
  static const ttsLanguage = 'زبان تلفظ';
  static const ttsLanguageHint =
      'کلمات با موتور تبدیل متن به گفتار دستگاه و بر اساس زبان انتخابی خوانده می‌شوند';
  static const selectTtsLanguage = 'انتخاب زبان تلفظ';
  static const speak = 'تلفظ کلمه';
  static const ttsUnavailable =
      'این زبان روی دستگاه شما نصب نیست. از تنظیمات گوشی، بستهٔ زبان تبدیل متن به گفتار را نصب کنید.';
  static const reviewSettings = 'تنظیمات مرور';
  static const randomReviewOrder = 'نمایش تصادفی کارت‌ها';
  static const randomReviewOrderHint =
      'کارت‌های مرور امروز و مرور آزاد خانه‌ها با ترتیب تصادفی نمایش داده شوند';
  static const cardFontSize = 'اندازه فونت کارت';
  static const cardFontSizeHint =
      'با اسلایدر اندازه را تنظیم کنید؛ پیش‌نمایش همان لحظه به‌روز می‌شود';
  static const cardFontSizePreview = 'نمونه متن کارت';
  static const cardFontSizePreviewWord = 'Hello';
  static String cardFontSizeValue(int size) => 'اندازه فونت $size';
  static const autoSpeak = 'تلفظ خودکار کارت';
  static const autoSpeakHint =
      'هر سمتی که برای تلفظ خودکار روشن باشد، فقط وقتی همان سمت روی صفحه دیده شود خوانده می‌شود';
  static const autoSpeakSide = 'سمت تلفظ خودکار';
  static const autoSpeakFront = 'روی کارت تلفظ شود';
  static const autoSpeakBack = 'پشت کارت تلفظ شود';
  static const defaultCardDirection = 'جهت پیش‌فرض مرور';
  static const defaultCardDirectionHint =
      'فقط مرور عادی این فضا؛ مرور آزاد جهت جداگانه دارد';
  static const about = 'درباره';
  static const backup = 'پشتیبان‌گیری';
  static const backupHint =
      'یک فایل روی همین گوشی ذخیره می‌شود. اگر برنامه پاک شد یا مشکلی پیش آمد، می‌توانید لغت‌ها، دسته‌ها، فضاها و پیشرفت مرور را از همان فایل برگردانید.';
  static const exportBackup = 'تهیه نسخه پشتیبان';
  static const restoreBackup = 'بازگردانی از نسخه پشتیبان';
  static const restoreBackupWarning =
      'بازگردانی همه فضاها، دسته‌ها، کارت‌ها، آمار مرور و فایل‌های اکسل فعلی را با محتوای فایل پشتیبان عوض می‌کند. این کار قابل برگشت نیست مگر نسخه پشتیبان دیگری داشته باشید.';
  static const backupSaved = 'نسخه پشتیبان ذخیره شد';
  static const backupRestored = 'اطلاعات از نسخه پشتیبان بازگردانده شد';
  static const backupInvalid =
      'این فایل نسخه پشتیبان آتی‌لرن نیست یا آسیب دیده است.';
  static const backupFailed = 'پشتیبان‌گیری انجام نشد. دوباره تلاش کنید.';
  static const aboutApp = 'درباره برنامه';
  static const aboutDeveloper = 'درباره توسعه‌دهنده';
  static const appName = 'Atilearn';
  static const appVersion = 'نسخه ۱.۰.۱';
  static const appBusinessTitle = 'یادگیری ماندگار، با مرور در زمان مناسب';
  static const appDescription =
      'Atilearn یک ابزار فارسی برای مدیریت یادگیری با روش لایتنر و تکرار فاصله‌دار است. هدف برنامه این است که به‌جای مرور پراکنده و فراموش‌شدنی، هر کارت را درست زمانی که نیاز دارد دوباره به شما نشان دهد.';
  static const appValueTitle = 'Atilearn چه کمکی می‌کند؟';
  static const appValueDescription =
      'ساخت و دسته‌بندی فلش‌کارت، ورود گروهی از اکسل، مرور روزانه و آزاد، تلفظ کلمات با موتور گوشی و مشاهده آمار پیشرفت؛ همه در یک تجربه ساده و فارسی.';
  static const appAudienceTitle = 'برای چه کسانی ساخته شده؟';
  static const appAudienceDescription =
      'زبان‌آموزان، دانش‌آموزان، دانشجویان و هر کسی که می‌خواهد واژگان، مفاهیم یا نکات مهم را با یک برنامه مرور منظم به حافظه بلندمدت بسپارد.';
  static const appPrivacyTitle = 'حریم خصوصی و مالکیت داده';
  static const appPrivacyDescription =
      'کارت‌ها، فایل‌های واردشده و تاریخچه مرور روی دستگاه شما نگهداری می‌شوند. Atilearn برای نمایش تبلیغات یا فروش اطلاعات شخصی طراحی نشده است.';
  static const developerName = 'سعید عباسی';
  static const developerTitle = 'طراح و توسعه‌دهنده Atilearn';
  static const developerDescription =
      'Atilearn با تمرکز بر تجربه فارسی، سادگی، حفظ حریم خصوصی و یادگیری مؤثر به‌صورت مستقل طراحی و توسعه داده شده است.';
  static const contactDeveloper = 'راه‌های ارتباطی';
  static const sendEmail = 'ارسال ایمیل';
  static const telegram = 'ارسال پیام در تلگرام';
  static const github = 'مشاهده GitHub';
  static const developerEmail = 'saeed.abasi5080@gmail.com';
  static const developerGithub = 'github.com/saeedabbasi5080';
  static const telegramNotConfigured = 'آیدی تلگرام هنوز ثبت نشده است';
  static const linkOpenFailed = 'امکان بازکردن این لینک وجود ندارد.';

  // نوار پایین
  static const navHome = 'خانه';
  static const navSpaces = 'فضاها';
  static const navStats = 'آمار';
  static const navMore = 'بیشتر';
  static const navAddCard = 'کارت‌ها';
  static const pickSpaceForReview = 'کدام فضا را مرور می‌کنی؟';
  static const pickSpaceForStats = 'آمار کدام فضا را می‌بینی؟';
  static const pickSpaceForCards = 'کارت‌های کدام فضا را می‌بینی؟';
  static const reviewedCardsHome = 'کارت‌های بازبینی شده';
  static const spaceCardsEmpty = 'هنوز کارتی در این فضا نیست.';
  static const createSpaceFirst = 'اول یک فضای یادگیری بساز.';

  // ورود با شماره موبایل
  static const account = 'حساب کاربری';
  static const signIn = 'ورود';
  static const signOut = 'خروج از حساب';
  static const signInTitle = 'ورود با شماره موبایل';
  static const signInSubtitle =
      'برای اینکه اگر دستگاهتان را گم کردید کارت‌هایتان را از دست ندهید، شماره‌تان را ثبت کنید. این کار اختیاری است.';
  static const phoneNumber = 'شماره موبایل';
  static const phoneNumberHint = '۰۹۱۲ ۱۲۳ ۴۵۶۷';
  static const phoneNumberInvalid = 'شماره موبایل معتبر نیست.';
  static const sendCode = 'ارسال کد';
  static const resendCode = 'ارسال دوباره کد';
  static const codeSent = 'کد تأیید به شمارهٔ شما فرستاده شد.';
  static const verificationCode = 'کد تأیید';
  static const verificationCodeHint = '۶ رقم';
  static const verificationCodeIncomplete = 'کد باید ۶ رقم باشد.';
  static const confirm = 'تأیید';
  static const changePhoneNumber = 'تغییر شماره';
  static const changePhoneNumberConfirm = 'شماره را عوض می‌کنید؟';
  static const changePhoneNumberWarning =
      'کد فعلی باطل می‌شود و باید شمارهٔ جدید را دوباره تأیید کنید.';
  static const signedInAs = 'وارد شده با';
  static const notSignedIn = 'وارد نشده‌اید';
  static const signOutConfirm = 'از حساب خارج می‌شوید؟';
  static const signOutWarning =
      'کارت‌های شما روی همین دستگاه می‌مانند و چیزی پاک نمی‌شود. برای ورود دوباره به کد تأیید نیاز دارید.';
  static const signOutDone = 'از حساب خارج شدید.';
  static const profileName = 'نام نمایشی';
  static const profileSave = 'ذخیره';
  static const profileSaved = 'نام ذخیره شد.';
  static const profileNameEmpty = 'نام نمی‌تواند خالی باشد.';

  /// The warning for someone who has not signed in.
  ///
  /// Says what is true and stops. Promising a backup that does not exist yet, or
  /// pressing the point, would be the wrong way to earn a sign-in.
  static const notSignedInWarning =
      'وارد نشده‌اید. اگر دستگاهتان را گم کنید یا اطلاعاتش پاک شود، کارت‌هایتان برنمی‌گردد و ما نمی‌توانیم کمکی کنیم. برنامه بدون ورود هم کامل کار می‌کند.';
  static const notSignedInWarningShort =
      'بدون ورود، در صورت گم شدن دستگاه کارت‌هایتان قابل بازیابی نیست.';
  static const backupComingSoon = 'پشتیبان‌گیری خودکار در نسخه‌های بعدی اضافه می‌شود.';

  static String secondsLeft(int seconds) =>
      '${_toPersianDigits(seconds.toString())} ثانیه';
  static String minutesLeft(int seconds) {
    final minutes = (seconds / 60).ceil();
    return '${_toPersianDigits(minutes.toString())} دقیقه';
  }
  static String attemptsLeft(int attempts) =>
      '${_toPersianDigits(attempts.toString())} تلاش باقی مانده';
  static String codeRequestFailed(int seconds) =>
      'ارسال دوبارهٔ کد تا ${_toPersianDigits(seconds.toString())} ثانیه دیگر ممکن نیست.';

  /// Reasons a sign-in attempt can fail, when the server has not explained.
  ///
  /// Each one says what to do, not only what happened. "Something went wrong"
  /// leaves the user with nothing to act on.
  static const authServerUnreachable =
      'سرور در دسترس نیست. اینترنت خود را بررسی کنید و دوباره تلاش کنید.';
  static const authServerNotConfigured =
      'سرور ورود هنوز تنظیم نشده است. بدون ورود هم می‌توانید از برنامه استفاده کنید.';
  static const authRequestFailed = 'ارسال کد ممکن نشد. دوباره تلاش کنید.';
  static const authVerifyFailed = 'کد تأیید نشد. دوباره تلاش کنید.';
  static const authProfileFailed = 'ذخیرهٔ نام ممکن نشد.';
  static const authUnexpectedResponse =
      'پاسخ سرور قابل خواندن نبود. لطفاً بعداً تلاش کنید.';
  static const authSomethingWentWrong = 'ورود ممکن نشد. دوباره تلاش کنید.';

  // دستگاه‌های فعال
  static const activeDevices = 'دستگاه‌های فعال';
  static const activeDevicesHint =
      'اگر روی دستگاه دیگری هم وارد شده‌اید، از همین‌جا می‌توانید خارجش کنید.';
  static const thisDevice = 'همین دستگاه';
  static const noOtherDevices = 'دستگاه دیگری وارد نشده است.';
  static const signOutDevice = 'خروج از این دستگاه';
  static const signOutDeviceConfirm = 'از این دستگاه خارج می‌شود؟';
  static const signOutDeviceWarning =
      'این دستگاه از حساب خارج می‌شود. دفعه بعد که به اینترنت وصل شود، دیگر نمی‌تواند همگام‌سازی کند و خودش هم متوجه می‌شود.';
  static const deviceSignedOut = 'دستگاه خارج شد.';
  static const deviceNeverSeen = 'هنوز استفاده نشده';
  static const devicesLoadFailed = 'فهرست دستگاه‌ها بارگذاری نشد.';
  static const deviceSignOutFailed = 'خروج از دستگاه ممکن نشد.';

  /// Shown when another device has been used since this one.
  ///
  /// Says what is actually at risk and no more. Study progress cannot be lost —
  /// reviews merge — so claiming otherwise would be a scare the user learns to
  /// ignore, which is worse than saying nothing.
  static const otherDeviceInUse = 'دستگاه دیگری هم فعال است';
  static const otherDeviceInUseHint =
      'حساب شما روی دستگاه دیگری هم باز شده است. اگر همزمان کارت‌ها را ویرایش کنید، ممکن است ویرایش قدیمی‌تر از دست برود. پیشرفت مطالعه گم نمی‌شود.';

  static String deviceLastUsedMinutes(int minutes) =>
      'آخرین استفاده: ${_toPersianDigits(minutes.toString())} دقیقه پیش';
  static String deviceLastUsedHours(int hours) =>
      'آخرین استفاده: ${_toPersianDigits(hours.toString())} ساعت پیش';
  static String deviceLastUsedDays(int days) =>
      'آخرین استفاده: ${_toPersianDigits(days.toString())} روز پیش';
  static const deviceLastUsedJustNow = 'آخرین استفاده: همین حالا';

  // همگام‌سازی
  static const syncTitle = 'همگام‌سازی';
  static const syncHint =
      'کارت‌ها و پیشرفت مطالعه‌تان روی سرور ذخیره می‌شود تا اگر دستگاهتان را گم کردید از دست نرود.';
  static const syncNotSignedIn = 'برای همگام‌سازی باید وارد حساب خود شوید.';
  static const syncDeviceRemoved =
      'این دستگاه از حساب خارج شده است، چون روی دستگاه دیگری وارد شده بودید. برای ادامه دوباره وارد شوید.';
  static const syncUploadFailed = 'فرستادن داده‌ها به سرور ممکن نشد.';
  static const syncDownloadFailed = 'گرفتن داده‌ها از سرور ممکن نشد.';
  static const syncNeverRun = 'هنوز همگام‌سازی نشده';
  static const syncRunning = 'در حال همگام‌سازی…';
  static const syncUpToDate = 'همه‌چیز به‌روز است.';
  static const syncDone = 'همگام‌سازی انجام شد.';
  static const syncFailed = 'همگام‌سازی ممکن نشد.';
  static const syncNow = 'همگام‌سازی کن';
  static const syncPendingReviews = 'مرور ذخیره‌نشده';
  static String syncPendingSave(int count) =>
      '${_toPersianDigits(count.toString())} مرور هنوز روی سرور ذخیره نشده است.';
  static const syncLastJustNow = 'آخرین همگام‌سازی: همین حالا';
  static String syncLastMinutes(int minutes) =>
      'آخرین همگام‌سازی: ${_toPersianDigits(minutes.toString())} دقیقه پیش';
  static String syncLastHours(int hours) =>
      'آخرین همگام‌سازی: ${_toPersianDigits(hours.toString())} ساعت پیش';
  static String syncLastDays(int days) =>
      'آخرین همگام‌سازی: ${_toPersianDigits(days.toString())} روز پیش';
  static String syncSentReviews(int count) =>
      '${_toPersianDigits(count.toString())} مرور فرستاده شد.';
  static String syncReceivedReviews(int count) =>
      '${_toPersianDigits(count.toString())} مرور از سرور گرفته شد.';

  // عمومی
  static const error = 'خطایی رخ داد';
  static const yes = 'بله';
  static const no = 'خیر';
  static const close = 'بستن';
}

/// Rewrites Latin digits as Persian ones.
///
/// Used for any number shown inside a Persian sentence. A countdown reading
/// `120 ثانیه` next to text that is otherwise entirely Persian looks like a
/// bug, even to a reader who cannot articulate why.
///
/// Deliberately not applied to phone numbers or codes the user types: those are
/// read digit by digit and must match what the SMS said.
String _toPersianDigits(String input) {
  const persian = '۰۱۲۳۴۵۶۷۸۹';
  final buffer = StringBuffer();
  for (final rune in input.runes) {
    if (rune >= 0x30 && rune <= 0x39) {
      buffer.write(persian[rune - 0x30]);
    } else {
      buffer.writeCharCode(rune);
    }
  }
  return buffer.toString();
}
