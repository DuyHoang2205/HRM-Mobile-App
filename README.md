# HRM-Mobile-App

## Frontend Structure

lib/
├── app
│  ├── app_shell.dart
│  └── app.dart
├── core
│  ├── demo
│  │  └── demo_attendance_store.dart
│  └── widgets
│     └── placeholder_page.dart
├── features
│  ├── attendance
│  │  ├── bloc
│  │  │  ├── attendance_bloc.dart
│  │  │  ├── attendance_event.dart
│  │  │  └── attendance_state.dart
│  │  ├── models
│  │  │  └── attendance_log.dart
│  │  └── view
│  │     └── attendance_page.dart
│  ├── checkin
│  │  ├── bloc
│  │  │  ├── checkin_bloc.dart
│  │  │  ├── checkin_event.dart
│  │  │  └── checkin_state.dart
│  │  ├── models
│  │  │  └── checkin_result.dart
│  │  ├── view
│  │  │  └── checkin_page.dart
│  │  └── widgets
│  │     ├── checkin_map_panel.dart
│  │     ├── checkin_topbar.dart
│  │     ├── confirm_button.dart
│  │     ├── shift_option_tile.dart
│  │     └── wifi_info_card.dart
│  └── home
│     ├── bloc
│     │  ├── home_bloc.dart
│     │  ├── home_event.dart
│     │  └── home_state.dart
│     ├── models
│     │  └── folder_item.dart
│     ├── view
│     │  └── home_page.dart
│     └── widgets
│        ├── folder_section.dart
│        ├── home_header.dart
│        ├── home_tab.dart
│        ├── schedule_section.dart
│        ├── shift_card.dart
│        └── top_chrome.dart
└── main.dart


## Navigation flow:

main.dart
   ↓
AppShell (Scaffold + BottomAppBar + FAB)
   ↓
IndexedStack (Home / My Task / Payment / Profile)


## Entry point:
bash
```
void main() {
  runApp(const MyApp());
}
```
```
home: AppShell(),
```

## Path: features/attendance
Notes:
Attendance logs are currently stored using core/demo/demo_attendance_store.dart.
Replace demo store with API/data layer later without changing UI structure too much.

## Bloc Pattern:
Each feature uses:
bloc/: *_bloc.dart, *_event.dart, *_state.dart
models/: domain models
view/: pages
widgets/: feature UI components
Notes:
Keep business logic inside blocs.
Keep views thin; pass actions into bloc events.
