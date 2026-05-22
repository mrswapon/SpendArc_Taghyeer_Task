import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:spend_arc/core/di/injection_container.dart' as di;
import 'package:spend_arc/core/sync/sync_service.dart';
import 'package:spend_arc/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:spend_arc/features/settings/presentation/bloc/settings_event.dart';
import 'package:spend_arc/features/transactions/presentation/bloc/transaction_bloc.dart';
import 'package:spend_arc/features/transactions/presentation/pages/home_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await di.init();

  // Kick off the background sync after the DI graph is ready.
  di.sl<SyncService>().startMonitoring();

  runApp(const SpendArcApp());
}

class SpendArcApp extends StatelessWidget {
  const SpendArcApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<SettingsBloc>(
          create: (_) => di.sl<SettingsBloc>()
            ..add(const LoadSettingsEvent()),
        ),
        BlocProvider<TransactionBloc>(
          create: (ctx) => di.sl<TransactionBloc>(),
        ),
      ],
      child: MaterialApp(
        title: 'SpendArc',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFFB359C5),
          ).copyWith(
            primary: const Color(0xFFB359C5),
          ),
          cardTheme: const CardThemeData(
            color: Color(0xFFF9E3FC),
            surfaceTintColor: Colors.transparent,
          ),
        ),
        home: const HomePage(),
      ),
    );
  }
}
