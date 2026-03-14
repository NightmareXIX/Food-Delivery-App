# Food Delivery App

A Flutter mobile application for food ordering with Supabase-backed authentication, menu browsing, cart and checkout flows, profile management, and a health dashboard that generates personalized tips.

## Overview

This project combines a standard food delivery experience with a lightweight wellness layer. Users can sign up, browse menu categories and items, place orders, manage their profile and delivery address, and review health metrics such as BMI and recent calorie estimates. The backend is powered by Supabase, while health tips are generated with Gemini.

The current codebase mixes production-backed features and demo UI. Core auth, menu, cart, checkout, order history, profile, and health flows are connected to Supabase. Some discovery and utility screens still use static content.

## Core Features

- Email/password authentication with Supabase Auth
- User profile creation and updates stored in Supabase
- Splash, welcome, login, and sign-up flow
- Home tab with greeting and delivery address refresh using device location
- Menu categories and menu items loaded from Supabase
- Item details with quantity selection and add-to-cart support
- Cart grouped by store, checkout flow, and order placement
- Order history with status display and pending-order cancellation
- Profile editing with gallery image selection and location-based address autofill
- My Health dashboard with BMI calculation, recent calorie estimation, and Gemini-generated health tips

## Tech Stack

| Layer | Technology |
| --- | --- |
| App framework | Flutter, Dart |
| Backend | Supabase Auth and database |
| AI integration | `google_generative_ai` (Gemini) |
| Device features | `geolocator`, `geocoding`, `image_picker`, `permission_handler` |
| UI utilities | `flutter_rating_bar`, `intl`, custom reusable widgets |
| Assets | Local images and Metropolis font family |

## Project Structure

```text
lib/
  auth/                Authentication service and auth gate
  common/              Shared helpers and theme extensions
  common_widget/       Reusable UI components
  more/                Cart, checkout, orders, payment, and utility screens
  view/
    home/              Home screen
    login/             Welcome, login, and sign-up screens
    main_tabview/      Bottom-tab navigation shell
    menu/              Menu categories, items, and item details
    my_health/         Health dashboard and health service
    offer/             Offers screen
    on_boarding/       Startup splash screen
    profile/           User profile screen
assets/
  fonts/               Metropolis font files
  img/                 App images and icons
android/               Android platform configuration
test/                  Widget tests
```

## Backend Requirements

The app expects a Supabase project with email/password auth enabled and tables equivalent to the following:

| Table | Purpose | Columns used by the app |
| --- | --- | --- |
| `profiles` | User profile data | `id`, `email`, `name`, `mobile`, `address`, `updated_at` |
| `menu_categories` | Menu category list | `id`, `name`, `image_url`, `items_count` |
| `menu_items` | Items inside each category | `id`, `category_id`, `name`, `price`, `rating`, `image_url`, `store_name` |
| `cart` | Active cart items | `id`, `user_id`, `item_id`, `store_name`, `quantity`, `created_at` |
| `order_history` | Orders per user | `id`, `user_id`, `total_amount`, `status`, `created_at` |
| `order_items` | Line items for each order | `order_id`, `item_id`, `quantity`, `price_at_order`, `item_name`, `store_name` |
| `user_health` | User health profile | `id`, `weight_kg`, `height_cm`, `age`, `last_calorie_intake`, `last_updated` |
| `health_tips` | Saved generated tips | `user_id`, `tip_text`, `bmi`, `generated_at` |

Notes:

- `menu_categories` and `menu_items` must be seeded or the menu screens will appear empty.
- Timestamp fields such as `created_at`, `updated_at`, and `generated_at` should exist because the app sorts and filters by them.
- The current health calorie estimate is derived from order spend, not nutritional data.

## Configuration

Before running the app, update the external service credentials used in source code:

- Replace the hardcoded Supabase URL and anon key in `lib/main.dart`
- Replace the hardcoded Gemini API key in `lib/view/my_health/my_health_view.dart`

For any real deployment, move these values out of source control and load them through a safer configuration approach such as `--dart-define`, environment-based config, or a secrets manager.

## Getting Started

### Prerequisites

- Flutter SDK compatible with `sdk: ^3.7.0`
- Dart SDK included with the matching Flutter installation
- Android Studio or another Android toolchain
- A Supabase project configured with the required auth settings and tables
- An emulator or device with location services available

### Installation

```bash
git clone <your-repository-url>
cd food_delivery_app
flutter pub get
```

### Run the App

```bash
flutter run
```

### Useful Development Commands

```bash
flutter analyze
flutter test
```

## Permissions

The Android project currently declares permissions for:

- Fine and coarse location access for delivery address updates
- Network and Wi-Fi state access to improve location handling

The app also requests:

- Gallery/photo access through `image_picker` for local profile image selection

## Current Status and Known Limitations

- The main food-ordering flow is implemented around Supabase-backed auth, menu, cart, checkout, order history, profile, and health data.
- The home feed, offers, payment details, notifications, inbox, and about screens still contain static or placeholder content.
- Search fields are present in multiple screens but are not connected to real filtering logic.
- "Login with Google" and "Forgot your password?" are visible in the UI but are not implemented.
- Profile image selection only updates the local UI state and is not uploaded or persisted.
- Some screen copy and placeholder descriptions still need product-ready content.
- `test/widget_test.dart` is still the default Flutter counter sample and does not validate the current application flows.
- Android configuration still uses the default template `applicationId` and debug signing for release builds.

## Recommended Next Steps

- Externalize API keys and environment-specific configuration
- Add a Supabase schema or migration scripts to version the backend setup
- Replace placeholder screens and demo text with real product content
- Implement search, password reset, and social login
- Add meaningful widget, integration, and service-level tests
- Replace spend-based calorie estimation with nutrition-based calculations if health accuracy matters

## License

No license file is currently included in this repository. Add a project license before public distribution or reuse.
