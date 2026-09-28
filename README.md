# AI Story Generator

แอปสร้างเรื่องสั้นภาษาอังกฤษด้วย AI จากคลังคำศัพท์ Oxford 3000 ผู้ใช้ล็อกอินผ่าน OIDC (backend เป็น OpenID Connect Provider ของตัวเอง ผ่าน django-oidc-provider) หรือ email/password เลือกจำนวนคำ/ระดับ CEFR ระบบสุ่มคำแล้วให้ AI (Gemini) แต่งเรื่อง พร้อม highlight คำศัพท์ที่ใช้จริง และจัดการเรื่องของตัวเองได้ (ดู/แก้ไข/ลบ)

โปรเจกต์แบ่งเป็น 2 ส่วน:

- **`backend/`**: Django REST API (auth, stories, words)
- **`frontend/`**: Flutter app (Android / iOS / Web)

---

## สิ่งที่ต้องมีก่อนเริ่ม (Prerequisites)

| เครื่องมือ | เวอร์ชัน |
|---|---|
| Python | >= 3.11 (`backend/.python-version` = 3.11, `uv` โหลดให้เองถ้าเครื่องไม่มี) |
| [uv](https://docs.astral.sh/uv/) (ตัวจัดการ dependency ของ backend) | ล่าสุด |
| Flutter SDK | channel `stable`, Dart `^3.13.2` |
| JDK | 17 (Gradle/AGP ของโปรเจกต์ต้องใช้ 17 ขึ้นไป) |
| Android SDK + Emulator | platform 36, build-tools 36.0.0 (ดูหัวข้อ "Toolchain" ด้านล่าง) |
| Gemini API key (ฟรีที่ https://aistudio.google.com/apikey) | - |

---

## Toolchain ที่ใช้พัฒนา (เวอร์ชันที่ทดสอบจริง)

เครื่องพัฒนา: Windows 10 Home 22H2 (ไม่ใช้ Docker — รัน backend และ Flutter ตรงบนเครื่อง)

| ส่วน | เวอร์ชัน / ตำแหน่ง |
|---|---|
| Flutter | 3.47.2 (stable) ติดตั้งที่ `C:\src\flutter` |
| Dart | 3.13.2 (มากับ Flutter) |
| Flutter engine | revision `a804b26164` (มากับ Flutter ไม่ต้องติดตั้งแยก) |
| DevTools | 2.60.0 |
| JDK | 17 (Microsoft OpenJDK 17.0.20 / Oracle JDK 17.0.19) |
| Gradle | 9.3.1 (ผ่าน `gradle-wrapper.properties` ไม่ต้องติดตั้งเอง) |
| Android Gradle Plugin | 9.1.0 (`android/settings.gradle.kts`) |
| Kotlin | 2.4.0 (`android/settings.gradle.kts`) |
| Android SDK | `D:\Android` — platforms 30/34/35/36, build-tools 29.0.2/34.0.0/36.0.0, NDK 28.2.13676358, cmake, cmdline-tools `latest` |
| adb | 37.0.0 (`D:\Android\platform-tools`) |
| Android Emulator | 36.6.11.0, AVD `my_avd` (Pixel, Android 14 / API 34, Google APIs, x86_64) |
| uv | 0.11.x |
| Git | 2.55 |
| Browser (Flutter web) | Chrome / Edge |

`flutter doctor` ผ่านทุกหมวดที่โปรเจกต์ใช้ (Flutter, Android toolchain, Chrome) หมวด **Visual Studio / Windows desktop ไม่ได้ใช้** ถึงจะขึ้น `[!]` ก็ไม่กระทบ

### ติดตั้งบนเครื่องใหม่ (Windows, PowerShell)

```powershell
winget install Git.Git
winget install astral-sh.uv
winget install Microsoft.OpenJDK.17
winget install Google.AndroidStudio        # ใช้ SDK Manager / Device Manager ในนี้ก็ได้ หรือใช้ cmdline-tools ด้านล่าง

git clone https://github.com/flutter/flutter.git -b stable C:\src\flutter
# เพิ่ม C:\src\flutter\bin เข้า PATH แล้วเปิด terminal ใหม่
flutter --version
```

Android SDK ผ่าน command line (ต้องมี `cmdline-tools\latest` อยู่ใน `ANDROID_HOME` แล้ว):

```powershell
sdkmanager --licenses
sdkmanager "platform-tools" "emulator" "platforms;android-36" "build-tools;36.0.0" "system-images;android-34;google_apis;x86_64"

flutter config --android-sdk D:\Android
flutter config --jdk-dir "C:\Program Files\Microsoft\jdk-17.0.20.101-hotspot"   # ปรับ path ตามที่ติดตั้ง
flutter doctor --android-licenses
flutter doctor -v
```

Environment variables ที่ตั้งไว้ (ตั้งเป็น User variable แล้วเปิด terminal ใหม่):

| ตัวแปร | ค่า | หมายเหตุ |
|---|---|---|
| `ANDROID_HOME` | `D:\Android` | ที่อยู่ Android SDK |
| `GRADLE_USER_HOME` | `D:\GradleUserHome` | เก็บ Gradle cache ไว้ใน D: |
| `JAVA_HOME` | path ของ JDK 17 | |

### สร้างและใช้ Android Emulator ผ่าน CLI

```powershell
# สร้าง AVD (ครั้งเดียว)
avdmanager create avd -n my_avd -k "system-images;android-34;google_apis;x86_64" -d pixel

emulator -list-avds                 # ดูรายชื่อ AVD
emulator -avd my_avd                # เปิด emulator (หรือ: flutter emulators --launch my_avd)
adb devices                         # ต้องเห็น emulator-5554
flutter devices                     # ต้องเห็นเป็น device ที่รันได้
```

Emulator ต้องเปิด hardware acceleration ของ CPU (Intel VT-x / AMD-V ใน BIOS) ถ้าไม่เปิดจะบูตช้ามากหรือไม่ขึ้น

### Build

```powershell
cd frontend
flutter pub get
flutter analyze
flutter test
flutter build apk --debug --dart-define=BACKEND_BASE_URL=http://10.0.2.2:8000 --dart-define=OIDC_CLIENT_ID=<client-id>
flutter build web --release --dart-define=BACKEND_BASE_URL=http://localhost:8000 --dart-define=OIDC_CLIENT_ID=<client-id>
```

ถ้าเจอปัญหา build/emulator ดู "Troubleshooting" ท้ายไฟล์

---

## 1. Backend (Django)

### 1.1 ติดตั้ง dependencies

```bash
cd backend
uv sync
```

ถ้าไม่ใช้ `uv` จะใช้ `pip install -r requirements.txt` แทนก็ได้ (ไฟล์นี้คือชุด dependency เดียวกับที่ใช้ตอน deploy จริงบน Render, และตรงกับที่ `pyproject.toml`/`uv.lock` ประกาศไว้แล้ว)

### 1.2 ตั้งค่า environment variables

```bash
cp .env.example .env
```

แล้วแก้ไขค่าใน `.env`:

```env
DJANGO_SECRET_KEY=insecure-dev-key-change-me   # dev ใช้ค่า default ได้ ห้ามใช้ตอน deploy จริง
DJANGO_DEBUG=true
DJANGO_ALLOWED_HOSTS=localhost,127.0.0.1,10.0.2.2

#DATABASE_URL=                                  # comment ทิ้งไว้ = ใช้ SQLite local (ดูหมายเหตุด้านล่าง)

FRONTEND_URL=http://localhost:8080
CORS_ALLOWED_ORIGINS=http://localhost:8080,http://10.0.2.2:8080

LLM_API_KEY=<gemini-api-key>
LLM_MODEL=gemini-3.6-flash
```

หมายเหตุ: `DATABASE_URL` ต้องถูกลบทิ้งหรือ comment ออกไปเลย ห้ามเหลือเป็น `DATABASE_URL=` (ค่าว่าง)
`config/env.py` อ่านค่านี้ด้วย `os.environ.get("DATABASE_URL", <sqlite default>)` ซึ่ง fallback
เป็น SQLite ก็ต่อเมื่อตัวแปรนี้ไม่มีอยู่เลยในสภาพแวดล้อม แต่ `.env` ที่โหลดผ่าน `python-dotenv`
จะ set ตัวแปรนี้เป็น string ว่างถ้าเขียนเป็น `DATABASE_URL=` ทำให้ `dj_database_url.parse('')`
พังตอน `migrate` ทันที ให้ comment บรรทัดนี้ด้วย `#` (หรือลบทิ้งไปเลย) ถ้าต้องการใช้ SQLite local

`.env` อยู่ใน `.gitignore` แล้ว ห้าม commit ไฟล์นี้เข้า git

### 1.3 Migrate ฐานข้อมูล + seed คำศัพท์

```bash
uv run python manage.py migrate
uv run python manage.py seed_words        # โหลดคำจาก backend/data/word.csv เข้า DB
uv run python manage.py createsuperuser   # ถ้าต้องใช้ /admin/
```

### 1.4 รัน dev server

```bash
uv run python manage.py runserver
```

Backend จะรันที่ `http://localhost:8000`

---

## 2. OIDC Client setup (ต้องทำก่อน login ได้)

Backend เป็น OpenID Connect Provider ของตัวเอง (`django-oidc-provider`) ไม่ต้องพึ่ง Google Cloud Console อีกต่อไป — สร้าง Client ผ่าน Django admin ของ backend เอง:

1. `uv run python manage.py createsuperuser` (ถ้ายังไม่มี) แล้วเข้า `http://localhost:8000/admin/`
2. หาเมนู **OpenID Connect Provider → Clients → Add client**
3. ตั้งค่า:
   - **Client Type**: `Public`
   - **Response types**: `code`
   - **Redirect URIs**: `com.example.frontend:/oauth2redirect` (ต้องตรงกับ `AppConfig.oidcRedirectUri` ใน `frontend/lib/core/config/app_config.dart` เป๊ะ — ถ้าเปลี่ยน `applicationId`/`PRODUCT_BUNDLE_IDENTIFIER` ของแอป ต้องแก้ทั้งสามที่ให้ตรงกัน: ที่นี่, `AppConfig.oidcRedirectUri`, และ `appAuthRedirectScheme`/`CFBundleURLSchemes`)
   - **JWT Algorithm**: `RS256`
4. Save แล้วก็อป **Client ID** ที่ auto-gen มาใส่ตอนรันแอป Flutter (ดูข้อ 3.2)
5. รัน `uv run python manage.py creatersakey` **ครั้งเดียว** (สร้าง RSA key ไว้เซ็น id_token — ถ้ายังไม่เคยรันจะเจอ error ตอน login)

Public client + response_type=code จะเจอหน้า **consent** ("Request for Permission") ทุกครั้งที่ login ใหม่ (by design ของ library สำหรับ public client — ไม่ใช่ bug)

---

## 3. Frontend (Flutter)

### 3.1 ติดตั้ง dependencies

```bash
cd frontend
flutter pub get
```

### 3.2 รันแอป (ต้องชี้ไปที่ backend URL เสมอ)

```bash
# Android emulator (10.0.2.2 = localhost ของเครื่อง host จากมุมมอง emulator)
flutter run --dart-define=BACKEND_BASE_URL=http://10.0.2.2:8000 --dart-define=OIDC_CLIENT_ID=<client-id-จากข้อ-2>

# iOS simulator / Web / Desktop (backend อยู่เครื่องเดียวกัน)
flutter run --dart-define=BACKEND_BASE_URL=http://localhost:8000 --dart-define=OIDC_CLIENT_ID=<client-id-จากข้อ-2>
```

`OIDC_CLIENT_ID` คือ `client_id` ของ Client ที่สร้างไว้ในข้อ 2 — ใช้ตัวเดียวกันทั้ง Android/iOS/Web ได้ (public client เดียวกัน) ปุ่ม "Continue via OIDC" บนมือถือจะเปิด system browser ไปที่ `/openid/authorize/` ของ backend แบบ Authorization Code + PKCE (`flutter_appauth`); ฝั่ง Web จะ redirect ตรงไปหน้า `/accounts/login/` ของ backend แทน (ตั้ง session cookie ในตัวเดียว ไม่ต้องผ่าน `/openid/`)

### 3.3 อนุญาต HTTP แบบไม่เข้ารหัสตอน dev (local backend เป็น http)

- **Android**: `android:usesCleartextTraffic="true"` มีอยู่แล้วใน tag `<application>` ของ
  `android/app/src/main/AndroidManifest.xml` ในโปรเจกต์นี้ ไม่ต้องเพิ่มเอง (เช็คให้แน่ใจว่ายังอยู่หลัง `flutter create` ใหม่หรือ merge จาก template อื่น)
- **iOS**: ยังไม่มีการตั้งค่านี้ ต้องเพิ่ม exception `NSAppTransportSecurity` /
  `NSAllowsArbitraryLoads` ใน `ios/Runner/Info.plist` เอง

หมายเหตุ: ทั้งสองข้อนี้ใช้แค่ตอน dev เท่านั้น ตอน build release ต้องเปลี่ยนไปใช้ HTTPS แล้วเอาออก

---

## 4. โครงสร้างโปรเจกต์

```
backend/
  apps/
    accounts/     # auth, session, user preferences
    stories/      # word bank, story generation (LLM), stories CRUD
  config/         # settings, urls, env accessor (config/env.py)
  data/           # word.csv ฯลฯ สำหรับ seed_words

frontend/
  lib/
    core/         # config, api client, auth/session, theme
    features/
      auth/       # login/signup, OIDC (flutter_appauth on mobile, redirect on web)
      home/       # feed, my stories
      stories/    # create story, story detail
      settings/
    router/       # go_router + auth guard
```

---

## 5. Troubleshooting

| อาการ | สาเหตุ / วิธีแก้ |
|---|---|
| `flutter doctor` เตือน `Multiple adb binaries found` | มี Android SDK 2 ที่ (`D:\Android` และ `C:\Users\<user>\AppData\Local\Android\Sdk`) ตั้ง `ANDROID_HOME` กับ `ANDROID_SDK_ROOT` ชี้คนละที่ ให้ลบ `ANDROID_SDK_ROOT` ทิ้ง (deprecated) แล้วใช้ `ANDROID_HOME` ตัวเดียว หรือตั้งสองตัวให้ชี้ที่เดียวกัน แล้วเปิด terminal ใหม่ |
| `adb devices` ไม่เห็น emulator หรือเห็นซ้ำ | รัน `adb kill-server && adb start-server` และเช็กว่าใช้ adb ตัวเดียวกับ Flutter (`where adb`) |
| Build Android พังด้วย `this and base files have different roots` | โปรเจกต์อยู่ D: แต่ pub cache อยู่ C: ใน `android/gradle.properties` ปิด `kotlin.incremental` ไว้แล้ว ถ้ายังเป็นอยู่ให้ตั้ง `PUB_CACHE` ไปไว้ใน D: |
| Gradle ฟ้อง JDK version | ต้องใช้ JDK 17 เช็กด้วย `flutter doctor -v` (บรรทัด `Java binary at`) แล้วสลับด้วย `flutter config --jdk-dir "<path>"` |
| แอปบน emulator ต่อ backend ไม่ได้ | ใช้ `http://10.0.2.2:8000` (ไม่ใช่ `localhost`) และ `DJANGO_ALLOWED_HOSTS` ต้องมี `10.0.2.2` |
| `migrate` พังทันที | `DATABASE_URL=` ใน `.env` เป็นค่าว่าง ให้ comment ทิ้ง (ดูหมายเหตุข้อ 1.2) |
| Login OIDC แล้วเด้งกลับแอปไม่ได้ | Redirect URI ใน admin ต้องตรงกับ `AppConfig.oidcRedirectUri` และ `appAuthRedirectScheme` (ดูข้อ 2) |
| `flutter doctor` ขึ้น `[!] Visual Studio` | ไม่กระทบ โปรเจกต์นี้ใช้ Android / Web ไม่ได้ build Windows desktop จึงไม่ต้องติดตั้ง Visual Studio |

