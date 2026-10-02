# AI Story Generator

แอปสร้างเรื่องสั้นภาษาอังกฤษด้วย AI จากคลังคำศัพท์ Oxford 3000 และเลือกจำนวนคำ/ระดับ CEFR ระบบสุ่มคำแล้วให้ AI (Gemini) แต่งเรื่อง พร้อม highlight คำศัพท์ที่ใช้จริง และจัดการเรื่องของตัวเองได้ (ดู/แก้ไข/ลบ)

โปรเจกต์แบ่งเป็น 2 ส่วน:

- **`backend/`**: Django REST API (auth, stories, words)
- **`frontend/`**: Flutter app (Android / iOS / Web)

---

## สิ่งที่ต้องมีก่อนเริ่ม

- Python >= 3.11 และ [uv](https://docs.astral.sh/uv/) สำหรับ backend
- Flutter SDK channel `stable` (Dart `^3.13.2`) ที่พร้อมรันบน Android / iOS / Web
- Gemini API key (ฟรีที่ https://aistudio.google.com/apikey)

---

## 1. Backend (Django)

### 1.1 ติดตั้ง dependencies

```bash
cd backend
uv sync
```

ถ้าไม่ใช้ `uv` จะใช้ `pip install -r requirements.txt` แทนก็ได้ (ไฟล์นี้คือชุด dependency เดียวกับที่ใช้ตอน deploy จริงบน Render และตรงกับที่ `pyproject.toml`/`uv.lock` ประกาศไว้)

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

> **หมายเหตุ:** `DATABASE_URL` ต้องถูกลบทิ้งหรือ comment ออกไปเลย ห้ามเหลือเป็น `DATABASE_URL=` (ค่าว่าง)
> `config/env.py` อ่านค่านี้ด้วย `os.environ.get("DATABASE_URL", <sqlite default>)` ซึ่ง fallback เป็น SQLite ก็ต่อเมื่อตัวแปรนี้ไม่มีอยู่เลย แต่ `python-dotenv` จะ set เป็น string ว่างถ้าเขียน `DATABASE_URL=` ทำให้ `dj_database_url.parse('')` พังตอน `migrate` ทันที

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

Backend เป็น OpenID Connect Provider ของตัวเอง (`django-oidc-provider`) ไม่ต้องพึ่ง Google Cloud Console สร้าง Client ผ่าน Django admin ของ backend เอง:

1. `uv run python manage.py createsuperuser` (ถ้ายังไม่มี) แล้วเข้า `http://localhost:8000/admin/`
2. ไปที่ **OpenID Connect Provider → Clients → Add client**
3. ตั้งค่า:
   - **Client Type**: `Public`
   - **Response types**: `code`
   - **Redirect URIs**: `com.example.frontend:/oauth2redirect`
     ต้องตรงกับ `AppConfig.oidcRedirectUri` ใน `frontend/lib/core/config/app_config.dart` เป๊ะ ถ้าเปลี่ยน `applicationId`/`PRODUCT_BUNDLE_IDENTIFIER` ของแอป ต้องแก้ทั้งสามที่ให้ตรงกัน: ที่นี่, `AppConfig.oidcRedirectUri` และ `appAuthRedirectScheme`/`CFBundleURLSchemes`
   - **JWT Algorithm**: `RS256`
4. Save แล้วก็อป **Client ID** ที่ auto-gen มาใช้ตอนรันแอป Flutter (ดูข้อ 3.2)
5. รัน `uv run python manage.py creatersakey` **ครั้งเดียว** เพื่อสร้าง RSA key ไว้เซ็น id_token (ถ้ายังไม่เคยรันจะเจอ error ตอน login)

Public client + `response_type=code` จะเจอหน้า **consent** ("Request for Permission") ทุกครั้งที่ login ใหม่ เป็น by design ของ library ไม่ใช่ bug

---

## 3. Frontend (Flutter)

### 3.1 ติดตั้ง dependencies

```bash
cd frontend
flutter pub get
```

### 3.2 รันแอป (ต้องชี้ไปที่ backend URL เสมอ)

```bash
# Web simulator
flutter run -d chrome --web-port 8080 --dart-define=BACKEND_BASE_URL=http://localhost:8000 --dart-define=OIDC_CLIENT_ID=<client-id-จากข้อ-2>

# Android emulator (10.0.2.2 = localhost ของเครื่อง host จากมุมมอง emulator)
flutter run --dart-define=BACKEND_BASE_URL=http://10.0.2.2:8000 --dart-define=OIDC_CLIENT_ID=<client-id-จากข้อ-2>

# iOS simulator 
flutter run --dart-define=BACKEND_BASE_URL=http://localhost:8000 --dart-define=OIDC_CLIENT_ID=<client-id-จากข้อ-2>
```

`OIDC_CLIENT_ID` คือ `client_id` ของ Client ที่สร้างไว้ในข้อ 2 ใช้ตัวเดียวกันทั้ง Android/iOS/Web ได้ (public client เดียวกัน)

- **มือถือ**: ปุ่ม "Continue via OIDC" จะเปิด system browser ไปที่ `/openid/authorize/` ของ backend แบบ Authorization Code + PKCE (`flutter_appauth`)
- **Web**: redirect ตรงไปหน้า `/accounts/login/` ของ backend แทน (ตั้ง session cookie ในตัว ไม่ต้องผ่าน `/openid/`)

### 3.3 อนุญาต HTTP แบบไม่เข้ารหัสตอน dev (local backend เป็น http)

- **Android**: `android:usesCleartextTraffic="true"` มีอยู่แล้วใน tag `<application>` ของ `android/app/src/main/AndroidManifest.xml` ไม่ต้องเพิ่มเอง (เช็คให้แน่ใจว่ายังอยู่หลัง `flutter create` ใหม่หรือ merge จาก template อื่น)
- **iOS**: ยังไม่มีการตั้งค่านี้ ต้องเพิ่ม exception `NSAppTransportSecurity` / `NSAllowsArbitraryLoads` ใน `ios/Runner/Info.plist` เอง

> ทั้งสองข้อนี้ใช้แค่ตอน dev เท่านั้น ตอน build release ต้องเปลี่ยนไปใช้ HTTPS แล้วเอาออก

### 3.4 Analyze / Test / Build

```bash
flutter analyze
flutter test
flutter build apk --debug --dart-define=BACKEND_BASE_URL=http://10.0.2.2:8000 --dart-define=OIDC_CLIENT_ID=<client-id>
flutter build web --release --dart-define=BACKEND_BASE_URL=http://localhost:8000 --dart-define=OIDC_CLIENT_ID=<client-id>
```

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
| `migrate` พังทันที | `DATABASE_URL=` ใน `.env` เป็นค่าว่าง ให้ comment ทิ้ง (ดูหมายเหตุข้อ 1.2) |
| แอปบน emulator ต่อ backend ไม่ได้ | ใช้ `http://10.0.2.2:8000` (ไม่ใช่ `localhost`) และ `DJANGO_ALLOWED_HOSTS` ต้องมี `10.0.2.2` |
| Login OIDC แล้วเด้งกลับแอปไม่ได้ | Redirect URI ใน admin ต้องตรงกับ `AppConfig.oidcRedirectUri` และ `appAuthRedirectScheme` (ดูข้อ 2) |
| Login แล้วเจอ error เรื่อง key / id_token | ยังไม่ได้รัน `uv run python manage.py creatersakey` (ดูข้อ 2 ขั้นที่ 5) |
