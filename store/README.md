# Store images for Kept

Screenshots, feature graphic and icons for Google Play and the App Store, in
English (`en`) and Malayalam (`ml`). They are rendered from the real app with
demo data (no real user data), by `tool/store_images/`.

## Which file goes where

### Google Play (Play Console → Store listing)

| Slot | File | Size |
| --- | --- | --- |
| App icon | `google-play/icon/icon-512.png` | 512 × 512 |
| Feature graphic | `google-play/feature-graphic/feature-graphic.png` | 1024 × 500 |
| Phone screenshots (2 to 8) | `google-play/phone-screenshots/*.png` (2 files) | 1080 × 1920 |

For a Malayalam store listing use `more/google-play/feature-graphic-ml.png` and
`more/google-play/phone-screenshots/ml/`. Google Play needs at least 2 phone
screenshots; more (up to 8) can only help, take them from `more/`. Tablet screenshots are optional on Play and are not
included.

### App Store (App Store Connect → your version)

| Slot | File | Size |
| --- | --- | --- |
| App icon | `app-store/icon/icon-1024.png` | 1024 × 1024 |
| iPhone 6.9" screenshots (up to 10) | `app-store/iphone-6.9/*.png` (2 files) | 1320 × 2868 |
| iPad 13" screenshots (up to 10) | `app-store/ipad-13/*.png` (2 files) | 2064 × 2752 |

App Store Connect scales the 6.9" set down for smaller iPhones and the 13" set
for other iPads. The iPad set is required because the app is configured for
iPhone **and** iPad (`TARGETED_DEVICE_FAMILY = 1,2`); if you would rather ship
iPhone only, set it to `1` in Xcode and skip that folder. If the listing has a
Malayalam localization, use the `ml` folders there.

The files are numbered in the order they should appear (01 first). `finalize.py` and the generator write the full set into the old layout (`en/`, `ml/` sub-folders); re-trim afterwards if you only want the minimum.

## The eight screens

| # | Screen | English caption | Malayalam caption |
| --- | --- | --- | --- |
| 01 | Home | Your money, beautifully organised | നിങ്ങളുടെ പണം, ഭംഗിയായി ക്രമീകരിച്ച് |
| 02 | Add expense | Add an expense in seconds | നിമിഷങ്ങൾക്കുള്ളിൽ ചെലവ് ചേർക്കാം |
| 03 | Accounts | Every account and card in one place | എല്ലാ അക്കൗണ്ടും കാർഡും ഒരിടത്ത് |
| 04 | Loan | Loans and EMIs made clear | ലോണുകളും EMI-കളും വ്യക്തമായി |
| 05 | Reminders | Never miss a due date | ഒരു അവസാന തീയതിയും മറക്കരുത് |
| 06 | Reports | See where your money goes | നിങ്ങളുടെ പണം എങ്ങോട്ട് പോകുന്നു എന്നറിയാം |
| 07 | Budgets | Stay on budget | ബജറ്റിനുള്ളിൽ നിൽക്കാം |
| 08 | Dark mode | Private, offline, in your language | സ്വകാര്യം, ഇന്റർനെറ്റ് ഇല്ലാതെയും, നിങ്ങളുടെ ഭാഷയിൽ |

The Malayalam captions were written without a native speaker's review, like
the in-app Malayalam text: please have someone read them before publishing.

## Regenerating

Run this on a Mac (it uses the Flutter SDK's Roboto and Apple's Malayalam
font), from the repository root, whenever the UI changes:

```sh
pip install fonttools pillow                   # once
python3 tool/store_images/extract_malayalam_fonts.py   # once: bold Malayalam
STORE_LANG=en flutter test tool/store_images/store_images_test.dart
STORE_LANG=ml flutter test tool/store_images/store_images_test.dart
python3 tool/store_images/finalize.py          # flat RGB, icons, size check
```

`STORE_ONLY=phone` or `STORE_ONLY=ipad` limits a run to one device family.
`finalize.py` fails if any image has the wrong size or an alpha channel.

## Notes

* **Demo data.** The generator seeds accounts, a month of transactions, a
  card, a loan, budgets and reminders in the current month. Some entries are
  dated later in the month than the day you run it; that is harmless for demo
  images.
* **Fonts.** English uses Roboto, Android's UI font, for both stores; a real
  iPhone shows SF Pro, so its text looks slightly different. Malayalam uses
  Apple's Malayalam Sangam MN. That font has no minus sign or middle dot, so
  the Malayalam set avoids screens with negative amounts and shows a gap where
  a "·" would be (real phones fill both in).
* **Frames.** The status bar, camera cut-out and home indicator are drawn by
  the generator; the frame is generic, not a specific device.
* **Size.** The set is about 60 MB. Consider not committing it (or using Git
  LFS) and regenerating when needed. The patched/extracted Malayalam fonts go
  to `build/` and must not be committed (Apple's font).
