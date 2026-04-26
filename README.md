# Flutter High-Performance Feed — README

## Project Structure

```
lib/
├── main.dart                   ← App entry, Supabase init
├── models/
│   └── post.dart               ← Post data class
├── providers/
│   └── feed_provider.dart      ← All state logic (Riverpod)
├── screens/
│   ├── feed_screen.dart        ← Infinite scroll list
│   └── detail_screen.dart      ← Hero + tiered image loading
└── widgets/
    └── post_card.dart          ← Card with RepaintBoundary
```

---

## Riverpod State Management Approach

- **`FeedState`** is a plain immutable class holding the post list, loading flags, and error.
- **`FeedNotifier`** extends `StateNotifier<FeedState>` and is the only place that mutates state.
- The UI calls methods on the notifier (`loadMore`, `toggleLike`, etc.) and watches `feedProvider` to rebuild automatically.
- **Optimistic Like**: When the user taps Like, the count updates in the local state instantly. A debounced timer (300 ms) fires the Supabase RPC afterward. If the RPC fails (offline), the count is reverted and a SnackBar is shown.
- **Spam-click protection**: `Timer` debouncing means no matter how many times the user taps in 300 ms, only one network call is made reflecting the final intent.

---

## How RepaintBoundary Works Here

Each `PostCard` is wrapped in `RepaintBoundary`. Flutter places the card in its own GPU compositing layer. The heavy `BoxShadow` with `blurRadius: 30` is rasterized once into a bitmap. During fast scrolling, the GPU reuses that bitmap — it does NOT recalculate shadow math every frame. You can verify in Flutter DevTools → Performance → "Highlight Repaints": the card should NOT flash during scroll.

## How memCacheWidth Works Here

`CachedNetworkImage` accepts a `memCacheWidth` parameter. We set it to:

```
(screenWidth * devicePixelRatio).toInt()
```

This means the decoded JPEG/WebP bitmap is resized in memory to match the actual display pixels. A 1080-wide image shown at 400 logical pixels (800 physical on a 2× device) will be decoded at 800px wide instead of 1080px, saving roughly 40% RAM. You can verify in Flutter DevTools → Memory → Image Size analysis.

---

## Full Implementation Steps

### Step 1 — Create the Flutter project

Open Android Studio → New Flutter Project → Flutter Application.
- Project name: `flutter_feed`
- Language: Dart
- Minimum SDK: API 21

### Step 2 — Replace pubspec.yaml

Delete the default content of `pubspec.yaml` and paste the content from the provided `pubspec.yaml` file. Then run:

```
flutter pub get
```

### Step 3 — Create the folder structure

Inside `lib/`, create these folders:
- `models`
- `providers`
- `screens`
- `widgets`

### Step 4 — Copy all the Dart files

Copy each file into the matching path shown in the project structure above.

### Step 5 — Add your Supabase credentials

Open `lib/main.dart` and replace:

```dart
const String supabaseUrl = 'YOUR_SUPABASE_URL';
const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';
```

You find these in your Supabase project → Settings → API.

### Step 6 — Set up Supabase backend

1. Go to supabase.com → create a free project.
2. Open the SQL Editor and run the SQL from the assignment (creates `posts`, `user_likes` tables and `toggle_like` RPC).
3. Go to Storage → create a public bucket named `media`.

### Step 7 — Seed the database

1. Install Python deps: `pip install supabase Pillow`
2. Create a folder named `input_images` and drop in a few JPG/PNG images.
3. Fill in `SUPABASE_URL` and `SUPABASE_SERVICE_ROLE_KEY` in the Python script.
4. Run: `python seed.py`

### Step 8 — Android network permission

Open `android/app/src/main/AndroidManifest.xml` and add inside `<manifest>`:

```xml
<uses-permission android:name="android.permission.INTERNET"/>
```

### Step 9 — Run the app

Connect a device or start an emulator, then:

```
flutter run
```

---

## Edge Cases Handled

| Test | How it is handled |
|---|---|
| Spam-click Like 15× | 300 ms debounce — one RPC call per burst |
| Rapid scrolling | `RepaintBoundary` → GPU layer reuse, no shadow recalc |
| Offline Like | Optimistic update → RPC fails → UI reverted → SnackBar shown |
| OOM prevention | `memCacheWidth` keeps decoded images at display size |
| Pagination | Loads 10 at a time; triggers on scroll within 200px of bottom |
