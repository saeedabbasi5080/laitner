/// تمام متن‌های فارسی برنامه
abstract final class AppStrings {
  static const appTitle = 'یادآوری — تکرار فاصله‌دار';

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
  static const importExcelHint =
      'ستون اول: روی کارت — ستون دوم: پشت کارت';
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
  static const backToDecks = 'بازگشت به دسته‌ها';
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
  static const box = 'خانه';
  static const boxOverview = 'کارت‌ها در هر خانه';
  static const boxNCards = 'کارت در خانه';
  static const freeReviewBox1 = 'مرور آزاد (خانه ۱)';
  static const freeReview = 'مرور آزاد';
  static const freeReviewSetup = 'تنظیم مرور آزاد';
  static const selectBox = 'انتخاب خانه';
  static const normalReview = 'نرمال (رو به پشت)';
  static const reversedReview = 'برعکس (پشت به رو)';
  static const resetToBox1 = 'برگرد به خانه ۱';
  static const resetToBox1Done = 'کارت به خانه ۱ برگشت';
  static const freeReviewEmpty = 'در هیچ خانه‌ای کارتی نیست.';
  static const startReview = 'شروع مرور';
  static const addNew = 'افزودن';
  static const addNewDeck = 'دسته جدید';
  static const addNewCard = 'کارت جدید';
  static const selectDeck = 'انتخاب دسته';
  static const noDecksForCard = 'ابتدا یک دسته بسازید.';
  static const whatToAdd = 'چه چیزی می‌خواهید اضافه کنید؟';

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
  static const themeAccent = 'رنگ تم';
  static const themeAccentHint = 'یکی از رنگ‌ها را برای ظاهر برنامه انتخاب کنید';

  // عمومی
  static const error = 'خطایی رخ داد';
  static const yes = 'بله';
  static const no = 'خیر';
  static const close = 'بستن';
}
