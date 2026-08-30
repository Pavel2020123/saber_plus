import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../domain/official_opportunity.dart';

typedef OfficialOpportunityLinkOpener = Future<bool> Function(Uri uri);

final officialOpportunitiesProvider = Provider<List<OfficialOpportunity>>(
  (ref) => officialOpportunityCatalog,
);

final officialOpportunityLinkOpenerProvider =
    Provider<OfficialOpportunityLinkOpener>(
      (ref) =>
          (uri) => launchUrl(uri, mode: LaunchMode.externalApplication),
    );
