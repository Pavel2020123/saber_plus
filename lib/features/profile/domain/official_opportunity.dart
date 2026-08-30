enum OpportunityCategory {
  all('Todas'),
  merit('Mérito Saber 11'),
  publicTuition('Matrícula pública'),
  international('Becas internacionales'),
  specialFunds('Fondos especiales');

  const OpportunityCategory(this.label);

  final String label;
}

const trustedOfficialOpportunityHosts = <String>{
  'web.icetex.gov.co',
  'www.mineducacion.gov.co',
};

bool isTrustedOfficialOpportunityUri(Uri uri) =>
    uri.scheme == 'https' &&
    uri.userInfo.isEmpty &&
    !uri.hasPort &&
    trustedOfficialOpportunityHosts.contains(uri.host);

class OfficialOpportunity {
  const OfficialOpportunity({
    required this.id,
    required this.title,
    required this.provider,
    required this.category,
    required this.summary,
    required this.eligibility,
    required this.support,
    required this.officialUrl,
    required this.verifiedOn,
  });

  final String id;
  final String title;
  final String provider;
  final OpportunityCategory category;
  final String summary;
  final List<String> eligibility;
  final List<String> support;
  final String officialUrl;
  final String verifiedOn;

  Uri get officialUri => Uri.parse(officialUrl);
}

List<OfficialOpportunity> filterOfficialOpportunities(
  Iterable<OfficialOpportunity> opportunities,
  OpportunityCategory category,
) {
  if (category == OpportunityCategory.all) {
    return List.unmodifiable(opportunities);
  }
  return List.unmodifiable(
    opportunities.where((item) => item.category == category),
  );
}

const officialOpportunityCatalog = <OfficialOpportunity>[
  OfficialOpportunity(
    id: 'best-saber-11-results',
    title: 'Subsidios Mejores Resultados Saber 11',
    provider: 'ICETEX y Ministerio de Educación Nacional',
    category: OpportunityCategory.merit,
    summary:
        'Fondo para bachilleres reconocidos oficialmente con la Distinción Andrés Bello que cursen un pregrado en una institución pública.',
    eligibility: [
      'Aparecer en la resolución oficial de la Distinción Andrés Bello.',
      'Contar con admisión en una institución de educación superior estatal.',
      'Presentar los documentos y compromisos exigidos por la convocatoria.',
    ],
    support: [
      'Subsidio de matrícula según las condiciones oficiales aplicables.',
      'Subsidio de sostenimiento según residencia y requisitos del fondo.',
    ],
    officialUrl:
        'https://web.icetex.gov.co/-/subsidios-mejores-resultados-saber-11',
    verifiedOn: '2026-08-30',
  ),
  OfficialOpportunity(
    id: 'public-tuition-policy',
    title: 'Política de Gratuidad “Puedo Estudiar”',
    provider: 'Ministerio de Educación Nacional',
    category: OpportunityCategory.publicTuition,
    summary:
        'Política que asume la matrícula ordinaria neta de estudiantes elegibles en instituciones públicas vinculadas.',
    eligibility: [
      'Estar matriculado en un pregrado con registro calificado vigente.',
      'Estudiar en una institución pública vinculada a la política.',
      'Cumplir el reglamento operativo vigente y la validación institucional.',
    ],
    support: [
      'Pago de la matrícula ordinaria neta bajo las condiciones de la política.',
      'La institución valida el acceso y la renovación del beneficio.',
    ],
    officialUrl:
        'https://www.mineducacion.gov.co/portal/409830:Politica-de-Gratuidad-en-la-Educacion-Superior',
    verifiedOn: '2026-08-30',
  ),
  OfficialOpportunity(
    id: 'international-scholarships',
    title: 'Becas vigentes para colombianos',
    provider: 'ICETEX',
    category: OpportunityCategory.international,
    summary:
        'Buscador oficial de ofertas de cooperación internacional para distintos niveles y destinos de estudio.',
    eligibility: [
      'Revisar el nivel de estudios, país y perfil de cada convocatoria.',
      'Confirmar idioma, experiencia, documentos y fecha de cierre.',
      'Postularse únicamente por el procedimiento indicado oficialmente.',
    ],
    support: [
      'La cobertura cambia en cada convocatoria y puede ser total o parcial.',
      'El oferente decide la selección final y las condiciones del beneficio.',
    ],
    officialUrl:
        'https://web.icetex.gov.co/becas/becas-para-estudios-en-el-exterior',
    verifiedOn: '2026-08-30',
  ),
  OfficialOpportunity(
    id: 'managed-funds',
    title: 'Fondos en Administración',
    provider: 'ICETEX y entidades constituyentes',
    category: OpportunityCategory.specialFunds,
    summary:
        'Convocatorias para poblaciones, territorios o sectores específicos administradas por ICETEX.',
    eligibility: [
      'Buscar una convocatoria abierta que corresponda con tu situación.',
      'Leer el reglamento y verificar población, territorio y nivel financiado.',
      'Confirmar cronograma y documentos directamente en la convocatoria.',
    ],
    support: [
      'Cada fondo define si entrega subsidio, crédito condonable u otro apoyo.',
      'La entidad constituyente establece requisitos, cupos y selección.',
    ],
    officialUrl: 'https://web.icetex.gov.co/creditos/fondos-en-administracion',
    verifiedOn: '2026-08-30',
  ),
];
