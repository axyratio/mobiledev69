# AI Story Generator

แอปสร้างเรื่องสั้นภาษาอังกฤษด้วย AI จากคลังคำศัพท์ Oxford 3000 ผู้ใช้ล็อกอินผ่าน Google OIDC เลือกจำนวนคำ/ระดับ CEFR ระบบสุ่มคำแล้วให้ AI (Gemini) แต่งเรื่อง พร้อม highlight คำศัพท์ที่ใช้จริง และจัดการเรื่องของตัวเองได้ (ดู/แก้ไข/ลบ)

โปรเจกต์แบ่งเป็น 2 ส่วน:

- **`backend/`**: Django REST API (auth, stories, words)
- **`frontend/`**: Flutter app (Android / iOS / Web)

---

## สิ่งที่ต้องมีก่อนเริ่ม (Prerequisites)

| เครื่องมือ | เวอร์ชัน |
|---|---|
| Python | >= 3.11 |
| [uv](https://docs.astral.sh/uv/) (ตัวจัดการ dependency ของ backend) | ล่าสุด |
| Flutter SDK | channel `stable`, Dart `^3.13.2` |
| Google Cloud project ที่มี OAuth Client ID (ประเภท **Web**) | - |
| Gemini API key (ฟรีที่ https://aistudio.google.com/apikey) | - |

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

GOOGLE_OIDC_CLIENT_ID=<web-client-id>.apps.googleusercontent.com
GOOGLE_OIDC_CLIENT_SECRET=<web-client-secret>

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

## 2. Google OAuth setup (ต้องทำก่อน login ได้)

1. ไปที่ Google Cloud Console, เมนู Credentials (https://console.cloud.google.com/apis/credentials) สร้าง **OAuth 2.0 Client ID** ประเภท **Web application**
2. เพิ่ม **Authorized redirect URI**:
   `http://localhost:8000/accounts/google/login/callback/`
3. เอา Client ID/Secret มาใส่ `GOOGLE_OIDC_CLIENT_ID` / `GOOGLE_OIDC_CLIENT_SECRET` ใน `backend/.env`
4. ถ้าจะ login จากแอปมือถือ (native Google Sign-In) ต้องเพิ่ม **SHA-1 fingerprint** ของ Android debug/release keystore เข้าไปใน OAuth consent / Android client ที่ผูกกับ Client ID เดียวกันด้วย

   ดูวิธีเอา SHA-1: `frontend/android/gradlew` และ `gradlew.bat` เป็นไฟล์ที่ถูก `.gitignore` ไว้
   (ไม่มีมาให้ตั้งแต่ clone) ต้อง build/run แอป Android ครั้งหนึ่งก่อน เพื่อให้ Flutter สร้าง
   Gradle wrapper ขึ้นมาให้ ถึงจะรัน `signingReport` ได้:

   ```bash
   cd frontend
   flutter build apk --debug        # สร้าง gradlew/gradlew.bat ให้ครั้งแรก (ใช้เวลาสักพัก)
   cd android
   ./gradlew signingReport          # Windows cmd.exe ใช้ gradlew.bat signingReport
   ```

---

## 3. Frontend (Flutter)

### 3.1 ติดตั้ง dependencies

```bash
cd frontend
flutter pub get
```

### 3.2 รันแอป (ต้องชี้ไปที่ backend URL เสมอ)

Android emulator ใช้ `adb reverse` ผูกพอร์ตเข้ากับ `localhost` ของเครื่อง host แทนการใช้ `10.0.2.2` (Google OAuth ไม่รองรับ private IP เป็น redirect/callback origin):

```bash
adb reverse tcp:8000 tcp:8000
```

```bash
# Android emulator (หลังรัน adb reverse แล้ว)
flutter run --dart-define=BACKEND_BASE_URL=http://localhost:8000 --dart-define=GOOGLE_WEB_CLIENT_ID=<web-client-id>.apps.googleusercontent.com

# iOS simulator / Web / Desktop (backend อยู่เครื่องเดียวกัน)
flutter run --dart-define=BACKEND_BASE_URL=http://localhost:8000 --dart-define=GOOGLE_WEB_CLIENT_ID=<web-client-id>.apps.googleusercontent.com
```

`GOOGLE_WEB_CLIENT_ID` ต้องเป็น **Web client ID เดียวกัน** กับ `GOOGLE_OIDC_CLIENT_ID` ฝั่ง backend (native Google Sign-In ใช้มันเป็น `serverClientId` เพื่อให้ backend เชื่อ ID token ที่ส่งมา)

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
      auth/       # login/signup, Google OIDC
      home/       # feed, my stories
      stories/    # create story, story detail
      settings/
    router/       # go_router + auth guard
```

