# 📱 دليل بناء الـ APK عبر Termux + GitHub Actions

## الطريقة المثلى: GitHub Actions (مجانية 100%)
GitHub يبني الـ APK تلقائياً في السحابة عند رفع الكود، دون الحاجة لأي جهاز كمبيوتر!

---

## الخطوة 1️⃣ — تثبيت Termux

1. حمّل **Termux** من [F-Droid](https://f-droid.org/packages/com.termux/) (وليس من Play Store)
2. افتح Termux وشغّل:
```bash
pkg update -y && pkg upgrade -y
pkg install git -y
pkg install openssh -y
```

---

## الخطوة 2️⃣ — إنشاء مستودع GitHub

1. افتح **github.com** في متصفحك
2. سجّل دخولاً أو أنشئ حساباً مجانياً
3. اضغط **"New repository"**
4. اسمه: `call-recorder-app`
5. اجعله **Public** (أو Private)
6. **لا تضع README** — اتركه فارغاً
7. اضغط **"Create repository"**

---

## الخطوة 3️⃣ — إعداد Git في Termux

```bash
# تعيين بيانات المستخدم
git config --global user.name "اسمك"
git config --global user.email "بريدك@gmail.com"

# توليد مفتاح SSH (اضغط Enter على كل سؤال)
ssh-keygen -t ed25519 -C "بريدك@gmail.com"

# عرض المفتاح العام لنسخه
cat ~/.ssh/id_ed25519.pub
```

انسخ المفتاح كاملاً ثم:
1. اذهب لـ github.com → Settings → SSH and GPG keys
2. اضغط **New SSH key**
3. الصق المفتاح واضغط **Add SSH key**

---

## الخطوة 4️⃣ — رفع المشروع لـ GitHub

### أولاً: انسخ ملف ZIP للهاتف وفك ضغطه

```bash
# انتقل لمجلد التنزيلات
cd /sdcard/Download/

# إذا وجد الـ ZIP، انسخه لـ Termux
cp call_recorder_flutter_project.zip ~/
cd ~/
```

### ثانياً: فك الضغط (ثبّت unzip أولاً)
```bash
pkg install unzip -y
unzip call_recorder_flutter_project.zip
cd call_recorder_app
```

### ثالثاً: رفع الكود لـ GitHub
```bash
# تهيئة Git
git init
git add .
git commit -m "🎙️ Initial commit - Call Recorder App"

# ربط بـ GitHub (استبدل USERNAME باسم حسابك)
git remote add origin git@github.com:USERNAME/call-recorder-app.git
git branch -M main

# الرفع!
git push -u origin main
```

---

## الخطوة 5️⃣ — مراقبة البناء

1. اذهب لـ `github.com/USERNAME/call-recorder-app`
2. اضغط تبويب **Actions** ⚡
3. ستجد workflow يعمل باسم **"🔨 Build APK"**
4. انتظر ~5-7 دقائق حتى يكتمل ✅

---

## الخطوة 6️⃣ — تحميل الـ APK 🎉

1. في تبويب **Actions** → اضغط على آخر Run
2. انزل للأسفل إلى قسم **Artifacts**
3. اضغط **"call-recorder-apk"** لتحميله
4. ستحصل على ملف ZIP يحتوي `app-release.apk`
5. فك الضغط وثبّت الـ APK على هاتفك!

---

## الخطوة 7️⃣ — تثبيت الـ APK

```
إعدادات الهاتف → الأمان → السماح بمصادر مجهولة ✅
ثم اضغط على الـ APK للتثبيت
```

---

## 🔄 تحديث التطبيق لاحقاً

في أي وقت تعدّل الكود:
```bash
cd ~/call_recorder_app
git add .
git commit -m "✏️ تحديث: وصف التغيير"
git push
```
GitHub Actions سيبني APK جديد تلقائياً!

---

## ⚡ تشغيل البناء يدوياً

في GitHub → Actions → "🔨 Build APK" → اضغط **"Run workflow"**

---

## 🆘 حل المشكلات الشائعة

| المشكلة | الحل |
|---|---|
| `Permission denied (publickey)` | كرّر خطوة SSH key |
| `remote: Repository not found` | تحقق من اسم المستودع |
| Build فشل في Actions | اضغط على الـ step الأحمر لرؤية الخطأ |
| APK لا يُثبّت | فعّل "مصادر مجهولة" في الإعدادات |

