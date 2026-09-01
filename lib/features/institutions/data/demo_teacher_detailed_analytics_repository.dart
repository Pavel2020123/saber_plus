import 'dart:convert';
import 'dart:io';

import '../domain/teacher_detailed_analytics_models.dart';
import '../domain/teacher_detailed_analytics_repository.dart';

class DemoTeacherDetailedAnalyticsRepository
    implements TeacherDetailedAnalyticsRepository {
  @override
  Future<TeacherDetailedDashboard> load() async {
    final now = DateTime.now();
    const students = [
      DetailedStudentAnalytics(
        id: 'demo-student-1',
        name: 'Andrea Gómez',
        email: 'andrea@demo.saberplus.co',
        groups: ['Once A'],
        xp: 1840,
        totalSimulations: 3,
        averageScore: 46.7,
        progress: 38,
        areas: [
          DetailedStudentArea(area: 'MATEMATICAS', average: 39, attempts: 3),
          DetailedStudentArea(
            area: 'LECTURA_CRITICA',
            average: 62,
            attempts: 3,
          ),
        ],
        academicStatus: 'REFUERZO',
        priorityArea: 'MATEMATICAS',
      ),
      DetailedStudentAnalytics(
        id: 'demo-student-2',
        name: 'Carlos Ruiz',
        email: 'carlos@demo.saberplus.co',
        groups: ['Once A'],
        xp: 2350,
        totalSimulations: 4,
        averageScore: 68.5,
        progress: 54,
        areas: [
          DetailedStudentArea(
            area: 'CIENCIAS_NATURALES',
            average: 58,
            attempts: 4,
          ),
        ],
        academicStatus: 'ESTABLE',
        priorityArea: 'CIENCIAS_NATURALES',
      ),
    ];
    return TeacherDetailedDashboard(
      analytics: TeacherDetailedAnalytics(
        scope: 'INSTITUCION',
        generatedAt: now,
        planName: 'SIN_ANUNCIOS',
        groupLimit: 5,
        studentLimit: 200,
        expiresAt: now.add(const Duration(days: 180)),
        summary: const DetailedAnalyticsSummary(
          totalStudents: 2,
          averageScore: 57.6,
          totalSimulations: 7,
          studentsNeedingSupport: 1,
        ),
        priorities: const [
          InstitutionAcademicPriority(
            area: 'MATEMATICAS',
            students: 1,
            average: 39,
          ),
          InstitutionAcademicPriority(
            area: 'CIENCIAS_NATURALES',
            students: 1,
            average: 58,
          ),
        ],
        students: students,
      ),
      risks: TeacherRiskReport(
        scope: 'INSTITUCION',
        generatedAt: now,
        summary: const RiskSummary(
          totalStudents: 2,
          atRisk: 1,
          critical: 0,
          high: 1,
          attention: 0,
        ),
        alerts: const [
          StudentRiskAlert(
            studentId: 'demo-student-1',
            name: 'Andrea Gómez',
            email: 'andrea@demo.saberplus.co',
            groups: ['Once A'],
            level: 'ALTA',
            reasons: [
              RiskReason(
                code: 'RENDIMIENTO_RECIENTE',
                level: 'ALTA',
                title: 'Bajo rendimiento reciente',
                detail: '39% de aciertos recientes en Matemáticas.',
              ),
            ],
            daysInactive: 2,
            priorityArea: 'MATEMATICAS',
          ),
        ],
      ),
    );
  }

  @override
  Future<DownloadedInstitutionReport> downloadReport(
    InstitutionReportFormat format,
  ) async {
    final directory = await Directory.systemTemp.createTemp(
      'saberplus_report_',
    );
    final fileName = 'saberplus-demo.${format.extension}';
    final file = File('${directory.path}${Platform.pathSeparator}$fileName');
    final bytes = format == InstitutionReportFormat.csv
        ? utf8.encode(
            '\uFEFFNombre,Correo,Promedio\r\nAndrea Gómez,andrea@demo.saberplus.co,46.7',
          )
        : latin1.encode(_demoPdf());
    await file.writeAsBytes(bytes, flush: true);
    return DownloadedInstitutionReport(
      path: file.path,
      fileName: fileName,
      format: format,
    );
  }
}

String _demoPdf() {
  const header = '%PDF-1.4\n';
  const pageContent =
      'BT /F1 16 Tf 72 720 Td (SaberPlus - Reporte demostrativo) Tj ET\n';
  final objects = [
    '1 0 obj\n<< /Type /Catalog /Pages 2 0 R >>\nendobj\n',
    '2 0 obj\n<< /Type /Pages /Kids [3 0 R] /Count 1 >>\nendobj\n',
    '3 0 obj\n<< /Type /Page /Parent 2 0 R /MediaBox [0 0 612 792] /Resources << /Font << /F1 5 0 R >> >> /Contents 4 0 R >>\nendobj\n',
    '4 0 obj\n<< /Length ${latin1.encode(pageContent).length} >>\nstream\n${pageContent}endstream\nendobj\n',
    '5 0 obj\n<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>\nendobj\n',
  ];
  final buffer = StringBuffer(header);
  final offsets = <int>[];
  for (final object in objects) {
    offsets.add(latin1.encode(buffer.toString()).length);
    buffer.write(object);
  }
  final xref = latin1.encode(buffer.toString()).length;
  buffer
    ..writeln('xref')
    ..writeln('0 ${objects.length + 1}')
    ..writeln('0000000000 65535 f ');
  for (final offset in offsets) {
    buffer.writeln('${offset.toString().padLeft(10, '0')} 00000 n ');
  }
  buffer
    ..writeln('trailer')
    ..writeln('<< /Size ${objects.length + 1} /Root 1 0 R >>')
    ..writeln('startxref')
    ..writeln(xref)
    ..writeln('%%EOF');
  return buffer.toString();
}
