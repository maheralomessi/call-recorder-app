# 🎙️ مسجّل المكالمات - Call Recorder Pro

تطبيق Flutter احترافي لتسجيل المكالمات الهاتفية على أندرويد.

## المميزات
- ✅ تسجيل تلقائي للمكالمات الواردة والصادرة
- ✅ واجهة عربية احترافية بنظام داكن
- ✅ عرض قائمة التسجيلات مع التشغيل المباشر
- ✅ مشاركة التسجيلات
- ✅ إعدادات جودة الصوت (منخفضة / متوسطة / عالية)
- ✅ حذف تسجيلات بالسحب أو بشكل جماعي
- ✅ دعم أندرويد 8.0 (API 26) وما فوق

## متطلبات البناء
- Flutter SDK 3.0+
- Android SDK 34
- JDK 11+

## خطوات بناء الـ APK

### 1. تثبيت التبعيات
```bash
flutter pub get
```

### 2. بناء نسخة Debug (للاختبار)
```bash
flutter build apk --debug
```
ستجد الملف في: `build/app/outputs/flutter-apk/app-debug.apk`

### 3. بناء نسخة Release (للنشر)
```bash
flutter build apk --release --split-per-abi
```
ستجد الملفات في: `build/app/outputs/flutter-apk/`

### 4. تثبيت مباشرة على الجهاز
```bash
flutter install
```

## الصلاحيات المطلوبة
| الصلاحية | الغرض |
|---|---|
| RECORD_AUDIO | تسجيل الصوت |
| READ_PHONE_STATE | كشف حالة المكالمة |
| READ_CALL_LOG | قراءة سجل المكالمات |
| FOREGROUND_SERVICE | العمل في الخلفية |
| POST_NOTIFICATIONS | إشعار التسجيل النشط |

## ملاحظات هامة
- **أندرويد 10+**: قد لا تُسجَّل المكالمة من الطرفين بسبب قيود Google.
  يُسجَّل الصوت من الميكروفون فقط على هذه الإصدارات.
- **Samsung/Xiaomi/Oppo**: بعض هذه الأجهزة تدعم تسجيل طرفي المكالمة.
- يجب السماح للتطبيق بالعمل في الخلفية من إعدادات الجهاز.

## هيكل المشروع
```
call_recorder/
├── lib/
│   ├── main.dart                    # نقطة البدء
│   ├── models/recording_model.dart  # نموذج البيانات
│   ├── screens/
│   │   ├── home_screen.dart         # الشاشة الرئيسية
│   │   └── settings_screen.dart     # الإعدادات
│   └── services/
│       └── storage_service.dart     # إدارة التخزين
└── android/
    └── app/src/main/kotlin/com/callrecorder/app/
        ├── MainActivity.kt          # جسر Flutter-Android
        ├── CallReceiver.kt          # كاشف المكالمات
        ├── RecordingService.kt      # خدمة التسجيل
        └── BootReceiver.kt          # الإعادة بعد التشغيل
```
