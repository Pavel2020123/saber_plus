import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../auth/presentation/session_controller.dart';
import '../data/demo_historical_simulation_repository.dart';
import '../data/remote_historical_simulation_repository.dart';
import '../domain/historical_simulation_models.dart';
import '../domain/historical_simulation_repository.dart';

final historicalSimulationRepositoryProvider =
    Provider<HistoricalSimulationRepository>((ref) {
      final isDemo = ref.watch(sessionControllerProvider).user?.isDemo ?? false;
      if (isDemo) return DemoHistoricalSimulationRepository();
      return RemoteHistoricalSimulationRepository(ref.watch(dioProvider));
    });

final historicalSimulationCatalogProvider =
    FutureProvider<HistoricalSimulationCatalog>((ref) {
      return ref.watch(historicalSimulationRepositoryProvider).loadCatalog();
    });
