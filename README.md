# SpendArc — Personal Finance Tracker

A production-quality Flutter app demonstrating clean architecture, custom animations, BLoC state management, and offline-first data handling.

---

## Setup Instructions

### Prerequisites
- Flutter SDK ≥ 3.0.0 (tested on 3.32.8)
- Dart ≥ 3.0.0

### Install & Run
```bash
flutter pub get
flutter run
```

### Run Tests
```bash
flutter test
```

### Run Analysis
```bash
flutter analyze lib/
# Expected: No issues found!
```

---

## Architecture Diagram

```
lib/
├── core/
│   ├── error/
│   │   └── failures.dart        # Failure sealed class (Server/Cache/Network)
│   ├── usecases/
│   │   └── usecase.dart         # Abstract UseCase<Type, Params>
│   ├── network/
│   │   └── network_info.dart    # NetworkInfo abstraction over connectivity_plus
│   ├── sync/
│   │   ├── diff_logic.dart      # Pure-Dart diff algorithm (runs in isolate)
│   │   ├── write_queue.dart     # Offline mutation queue (Hive-backed)
│   │   └── sync_service.dart    # Background sync + connectivity monitoring
│   └── di/
│       └── injection_container.dart  # get_it DI graph
│
├── features/
│   ├── settings/
│   │   ├── domain/entities/settings.dart
│   │   └── presentation/bloc/   # SettingsBloc (inter-bloc source)
│   │
│   └── transactions/
│       ├── domain/              <- ZERO Flutter/3rd-party imports
│       │   ├── entities/transaction.dart
│       │   ├── repositories/transaction_repository.dart  (abstract)
│       │   └── usecases/
│       │       ├── add_transaction.dart
│       │       ├── get_transactions.dart
│       │       └── delete_transaction.dart
│       │
│       ├── data/
│       │   ├── models/transaction_model.dart  (Hive, hand-written adapter)
│       │   ├── datasources/
│       │   │   ├── transaction_local_datasource.dart   (Hive)
│       │   │   └── transaction_remote_datasource.dart  (http + Mock)
│       │   └── repositories/transaction_repository_impl.dart
│       │
│       └── presentation/
│           ├── bloc/
│           │   ├── transaction_bloc.dart   (optimistic updates + inter-bloc)
│           │   ├── transaction_event.dart
│           │   └── transaction_state.dart
│           ├── pages/
│           │   ├── home_page.dart
│           │   └── add_transaction_page.dart
│           └── widgets/
│               ├── arc_meter_widget.dart        <- CustomPainter animation
│               ├── line_chart_widget.dart        <- CustomPainter animation
│               └── transaction_list_item.dart    <- Spring swipe + particles
│
└── main.dart
```

### Data Flow

```
UI Event
  |
  v
TransactionBloc  <-------- SettingsBloc (StreamSubscription)
  |  optimistic emit
  |
  v
AddTransaction UseCase
  |
  v
TransactionRepositoryImpl
  +-- LocalDataSource (Hive)  <- always written first
  +-- RemoteDataSource (HTTP) <- if online; else -> WriteQueueService
                                                         |
                                           on reconnect  v
                                                   SyncService.replayWriteQueue()
                                                   SyncService.backgroundSync()
                                                        (compute() isolate)
```

---

## Module Checklist

### Module 1 — Clean Architecture
- `get_it` DI with single `injection_container.dart`
- `Failure` sealed class: `ServerFailure`, `CacheFailure`, `NetworkFailure`
- `Either<Failure, T>` return types throughout repositories
- `UseCase<Type, Params>` abstract base class
- Domain layer: ZERO Flutter/third-party imports (verified by `flutter analyze`)

### Module 2 — Custom Animations
| Widget | Technique |
|--------|-----------|
| `ArcMeterWidget` | CustomPainter + AnimationController + CurvedAnimation; shouldRepaint only on value change |
| `LineChartWidget` | CustomPainter with lerp-based left-to-right draw progress; axes, grid, dots |
| `TransactionListItem` | GestureDetector + AnimationController.unbounded + SpringSimulation; particle burst via 12-circle CustomPainter |

### Module 3 — BLoC
- Optimistic updates in `_onAdd` / `_onDelete` with rollback to snapshot on failure
- `StreamSubscription<SettingsState>` inside `TransactionBloc` for inter-bloc communication
- All subscriptions cancelled in `close()`
- Immutable states with `copyWith`

### Module 4 — Offline-First
- Hive cache returns instantly on startup (zero async gap to first render)
- `SyncService.backgroundSync()` runs diff in a `compute()` isolate
- `WriteQueueService` (Hive-backed) enqueues mutations when offline
- `connectivity_plus` triggers `replayWriteQueue` + `backgroundSync` on reconnect

### Module 5 — Tests (all pass with `flutter test`)
| # | Test | File |
|---|------|------|
| 1 | AddTransaction -> Right(transaction) on success | add_transaction_test.dart |
| 2 | AddTransaction -> Left(ServerFailure) on repo failure | add_transaction_test.dart |
| 3 | TransactionBloc emits [Loading, Loaded] | transaction_bloc_test.dart |
| 4 | TransactionBloc rolls back optimistic update | transaction_bloc_test.dart |
| 5 | Diff logic identifies added / updated / deleted | diff_logic_test.dart |
| 6 | ArcMeterWidget has correct Semantics label | arc_meter_widget_test.dart |
| 7 | Swipe-to-delete calls onDelete callback | transaction_list_item_test.dart |

---

## Dependencies

| Package | Version | Purpose |
|---------|---------|---------|
| flutter_bloc | ^8.1.3 | State management |
| get_it | ^7.6.4 | Dependency injection |
| dartz | ^0.10.1 | Either for functional error handling |
| hive_flutter | ^1.1.0 | Local persistence |
| connectivity_plus | ^5.0.2 | Network state |
| http | ^1.1.0 | Remote data source |
| equatable | ^2.0.5 | Value equality in states/events |
| bloc_test | ^9.1.5 | Bloc unit testing helpers |
| mocktail | ^1.0.1 | Mocking in tests |

> No code generation (build_runner, freezed) was used.
> The Hive type adapter in transaction_model.g.dart is hand-written.
> No animation packages (Rive, Lottie, flutter_animate) were used.
> All animations use raw AnimationController.
