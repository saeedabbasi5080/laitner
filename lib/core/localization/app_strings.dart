/// تمام متن‌های فارسی برنامه
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
  static const emptySpaces =
      'هنوز فضایی نساخته‌اید. با دکمه + اولین فضای یادگیری را بسازید.';
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
  static const cancel = 'انصراف';
  static const delete = 'حذف';
  static const importExcel = 'ورود از اکسل';
  static const importExcelHint = 'ستون اول: روی کارت — ستون دوم: پشت کارت';
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
      'هنوز فایل اکسلی اضافه نکرده‌اید. با دکمه پایین یک فایل انتخاب کنید.';
  static const excelFormatGuideTitle = 'راهنمای فایل اکسل';
  static const excelFormatGuideIntro =
      'قبل از انتخاب فایل، مطمئن شوید اکسل شما مطابق قالب زیر است:';
  static const excelFormatRuleFormat = 'فرمت فایل: xlsx یا xls';
  static const excelFormatRuleColumnA = 'ستون اول (A): روی کارت';
  static const excelFormatRuleColumnB = 'ستون دوم (B): پشت کارت';
  static const excelFormatRuleSheet = 'فقط برگه اول فایل خوانده می‌شود';
  static const excelFormatRuleRows =
      'هر ردیفی که هر دو ستون پر باشد یک کارت می‌شود؛ ردیف‌های خالی نادیده گرفته می‌شوند';
  static const excelFormatExampleTitle = 'مثال';
  static const excelFormatExampleFront = 'hello';
  static const excelFormatExampleBack = 'سلام';
  static const excelSelectFile = 'انتخاب فایل اکسل';
  static const importExcelFile = 'افزودن فایل اکسل';
  static const excelFileSaved = 'فایل ذخیره شد';
  static const excelNoRows =
      'ردیف معتبری در فایل پیدا نشد. ستون اول و دوم باید پر باشند.';
  static const excelPending = 'باقی‌مانده';
  static const excelAdded = 'اضافه‌شده';
  static const deleteExcelFile = 'حذف فایل اکسل';
  static const deleteExcelFileConfirm =
      'آیا از حذف این فایل و تمام لغات ذخیره‌شده آن مطمئن هستید؟';
  static const excelImportNotFound = 'فایل اکسل پیدا نشد.';
  static const selectAllPending = 'انتخاب همه';
  static const clearSelection = 'پاک کردن انتخاب';
  static const pendingOnlyRows = 'فقط باقی‌مانده';
  static const addSelectedToDeck = 'افزودن به دسته';
  static const excelAllAdded = 'همه لغات این فایل قبلاً اضافه شده‌اند.';
  static const excelAlreadyAdded = 'قبلاً اضافه شده';
  static const editExcelRow = 'ویرایش لغت';
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
  static const reviewedCards = 'کارت امروز مرور شد';
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
  static String duplicateCardInDeck(String deckName) =>
      'این کلمه قبلاً اضافه شده و در دستهٔ «$deckName» وجود دارد.';
  static const excelDuplicatesSkipped =
      'کلمهٔ تکراری رد شد و به دسته اضافه نشد.';
  static const excelImportResult = 'نتیجه افزودن کلمات';
  static String excelImportResultSummary(int total, int added, int duplicate) =>
      'از $total کلمهٔ انتخاب‌شده، $added کلمه اضافه شد و '
      '$duplicate کلمه به دلیل تکراری بودن اضافه نشد.';
  static const duplicateWords = 'کلمات تکراری';
  static String duplicateExistsInDeck(String deckName) =>
      'از قبل در دستهٔ «$deckName» وجود دارد';
  static const removeDuplicateWords = 'حذف کلمات تکراری از فایل';
  static const removeDuplicateWordsQuestion =
      'آیا می‌خواهید کلمات تکراری از نسخهٔ ذخیره‌شدهٔ این فایل در کتابخانه اکسل حذف شوند؟';
  static const removeDuplicateWordsConfirm =
      'کلمات تکراری حذف شدند و دیگر در این فایل نمایش داده نمی‌شوند.';
  static const box = 'خانه';
  static const boxOverview = 'کارت‌ها در هر خانه';
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
  static const masteryHint = 'کارت‌هایی که پس از خانه ۵ یادگرفته شده‌اند';
  static const masteredCards = 'کارت مسلط';
  static const boxDistribution = 'توزیع خانه‌ها';
  static const boxDistributionHint = 'جایگاه فعلی همه کارت‌ها';
  static const dailyReviews = 'مرورهای روزانه';
  static const lastSevenDays = '۷ روز اخیر';
  static const answerRate = 'نرخ پاسخ‌ها';
  static const answerRateHint = 'بر اساس تمام مرورهای ثبت‌شده';
  static const currentStreak = 'تداوم فعلی';
  static const bestStreak = 'بهترین تداوم';
  static const day = 'روز';
  static const futureDue = 'سررسید آینده';
  static const nextSevenDays = '۷ روز آینده؛ معوق‌ها در امروز محاسبه شده‌اند';
  static const todayShort = 'امروز';
  static const tomorrowShort = 'فردا';
  static const noReviewHistory =
      'هنوز مروری ثبت نشده است. از این به بعد نتیجه مرورها در این بخش نمایش داده می‌شود.';
  static const reviewHistoryNote =
      'آمار مرور از زمان فعال‌شدن این قابلیت ثبت می‌شود.';
  static const retry = 'تلاش دوباره';

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

  // عمومی
  static const error = 'خطایی رخ داد';
  static const yes = 'بله';
  static const no = 'خیر';
  static const close = 'بستن';
}
