# HRM-Mobile-App

Monorepo workspace for the Flutter mobile client and related backend resources.

## Workspace Layout

```text
HRM-Mobile-App/
├── hrm_mobile_app/          # Flutter app
└── README.md                # This file
```

## Flutter App (`hrm_mobile_app`)

### Current Frontend Structure

```text
lib/
├── app/
│   ├── app_shell.dart
│   └── theme/
│       └── app_theme.dart
├── core/
│   ├── auth/
│   ├── helpers/
│   ├── network/
│   ├── utils/
│   └── widgets/
├── features/
│   ├── attendance/
│   ├── auth/
│   │   ├── bloc/
│   │   ├── data/
│   │   ├── models/
│   │   ├── view/
│   │   └── widgets/
│   ├── checkin/
│   ├── home/
│   ├── leave/
│   └── overtime/
└── main.dart
```

### Architecture Notes

- Feature-first organization with layer split inside each feature (`bloc`, `data`, `models`, `view`, `widgets`).
- API calls are handled in repository/data layer; UI consumes typed state/models.
- Global network client is in `lib/core/network/dio_client.dart`.
- App theme is centralized at `lib/app/theme/app_theme.dart`.

### Key Flows (recently updated)

- **Permission-based Overtime UI**
  - `frmOvertime/Add` is resolved via backend endpoint `POST userRole/getRoleByUser`.
  - Permission cache now keys by `formName + username + site` to avoid stale cross-account/site results.
- **Overtime Status Derivation**
  - Leave records now parse both lowercase/uppercase backend fields (`status/Status`, `fromDate/FromDate`, etc.).
  - HR/Admin overtime view now loads leave data per employee in overtime list, so "Nghỉ phép" is shown consistently.

## Run the App

From `HRM-Mobile-App/hrm_mobile_app`:

```bash
flutter pub get
flutter run
```

## Quality Checks

From `HRM-Mobile-App/hrm_mobile_app`:

```bash
dart format lib
dart analyze
```

## Frontend Clean Guide

Project guideline and prompt templates:

- `hrm_mobile_app/docs/frontend_clean_guide.md`

Includes:

- target folder structure
- UI refactor prompt
- logic/state cleanup prompt
- form/validation cleanup prompt
- clean frontend checklist for HRM
