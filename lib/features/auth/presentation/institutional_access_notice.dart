import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'session_controller.dart';
import 'institutional_access_card.dart';
import '../../institutions/presentation/personal_return_page.dart';

class InstitutionalAccessNotice extends ConsumerStatefulWidget {
  const InstitutionalAccessNotice({super.key});

  @override
  ConsumerState<InstitutionalAccessNotice> createState() =>
      _InstitutionalAccessNoticeState();
}

class _InstitutionalAccessNoticeState
    extends ConsumerState<InstitutionalAccessNotice> {
  bool _refreshing = false;

  Future<void> _refresh() async {
    if (_refreshing) return;
    setState(() => _refreshing = true);
    try {
      final refreshed = await ref
          .read(sessionControllerProvider.notifier)
          .revalidateInstitutionalAccess();
      if (!refreshed && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No pudimos revalidar el acceso. Se conserva la última información, sin ampliar el permiso offline. Intenta nuevamente con conexión.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(sessionControllerProvider).user;
    final access = user?.institutionalAccess;
    if (user == null || user.isDemo || access == null) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InstitutionalAccessCard(
          access: access,
          username: user.institutionalUsername,
          onRefresh: _refresh,
          refreshing: _refreshing,
        ),
        OutlinedButton(
          onPressed: () => Navigator.of(context).push<void>(
            MaterialPageRoute(builder: (_) => const PersonalReturnPage()),
          ),
          child: const Text('Consultar retorno a modalidad personal'),
        ),
      ],
    );
  }
}
