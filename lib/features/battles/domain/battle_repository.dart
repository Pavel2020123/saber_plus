import '../../academic/domain/academic_models.dart';
import 'battle_models.dart';

abstract interface class BattleRepository {
  Future<BattleDashboard> loadDashboard();

  Future<BattleDetail> create({
    required BattleMode mode,
    AcademicArea? area,
    bool privateInvitation = false,
  });

  Future<BattleDetail> joinInvitation(String code);

  Future<BattleDetail> loadDetail(String battleId);

  Future<BattleDetail> start(String battleId);

  Future<BattleDetail> answer({
    required String battleId,
    required String questionId,
    required String answerId,
  });

  Future<BattleDetail> finish(String battleId);

  Future<BattleDetail> cancel(String battleId);

  Future<void> blockRival(String battleId);

  Future<void> report({
    required String battleId,
    required BattleReportReason reason,
    String? details,
  });

  Future<List<BlockedRival>> loadBlocks();

  Future<void> unblock(String blockId);
}
