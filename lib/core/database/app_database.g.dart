// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $OfflineDownloadsTable extends OfflineDownloads
    with TableInfo<$OfflineDownloadsTable, OfflineDownload> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OfflineDownloadsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _themeIdMeta = const VerificationMeta(
    'themeId',
  );
  @override
  late final GeneratedColumn<String> themeId = GeneratedColumn<String>(
    'theme_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _areaMeta = const VerificationMeta('area');
  @override
  late final GeneratedColumn<String> area = GeneratedColumn<String>(
    'area',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _themeNameMeta = const VerificationMeta(
    'themeName',
  );
  @override
  late final GeneratedColumn<String> themeName = GeneratedColumn<String>(
    'theme_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fileNameMeta = const VerificationMeta(
    'fileName',
  );
  @override
  late final GeneratedColumn<String> fileName = GeneratedColumn<String>(
    'file_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _localPathMeta = const VerificationMeta(
    'localPath',
  );
  @override
  late final GeneratedColumn<String> localPath = GeneratedColumn<String>(
    'local_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _byteSizeMeta = const VerificationMeta(
    'byteSize',
  );
  @override
  late final GeneratedColumn<int> byteSize = GeneratedColumn<int>(
    'byte_size',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _downloadedAtMeta = const VerificationMeta(
    'downloadedAt',
  );
  @override
  late final GeneratedColumn<DateTime> downloadedAt = GeneratedColumn<DateTime>(
    'downloaded_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    userId,
    themeId,
    area,
    themeName,
    fileName,
    localPath,
    byteSize,
    downloadedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'offline_downloads';
  @override
  VerificationContext validateIntegrity(
    Insertable<OfflineDownload> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('theme_id')) {
      context.handle(
        _themeIdMeta,
        themeId.isAcceptableOrUnknown(data['theme_id']!, _themeIdMeta),
      );
    } else if (isInserting) {
      context.missing(_themeIdMeta);
    }
    if (data.containsKey('area')) {
      context.handle(
        _areaMeta,
        area.isAcceptableOrUnknown(data['area']!, _areaMeta),
      );
    } else if (isInserting) {
      context.missing(_areaMeta);
    }
    if (data.containsKey('theme_name')) {
      context.handle(
        _themeNameMeta,
        themeName.isAcceptableOrUnknown(data['theme_name']!, _themeNameMeta),
      );
    } else if (isInserting) {
      context.missing(_themeNameMeta);
    }
    if (data.containsKey('file_name')) {
      context.handle(
        _fileNameMeta,
        fileName.isAcceptableOrUnknown(data['file_name']!, _fileNameMeta),
      );
    } else if (isInserting) {
      context.missing(_fileNameMeta);
    }
    if (data.containsKey('local_path')) {
      context.handle(
        _localPathMeta,
        localPath.isAcceptableOrUnknown(data['local_path']!, _localPathMeta),
      );
    } else if (isInserting) {
      context.missing(_localPathMeta);
    }
    if (data.containsKey('byte_size')) {
      context.handle(
        _byteSizeMeta,
        byteSize.isAcceptableOrUnknown(data['byte_size']!, _byteSizeMeta),
      );
    } else if (isInserting) {
      context.missing(_byteSizeMeta);
    }
    if (data.containsKey('downloaded_at')) {
      context.handle(
        _downloadedAtMeta,
        downloadedAt.isAcceptableOrUnknown(
          data['downloaded_at']!,
          _downloadedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_downloadedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {userId, themeId};
  @override
  OfflineDownload map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return OfflineDownload(
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      themeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}theme_id'],
      )!,
      area: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}area'],
      )!,
      themeName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}theme_name'],
      )!,
      fileName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_name'],
      )!,
      localPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}local_path'],
      )!,
      byteSize: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}byte_size'],
      )!,
      downloadedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}downloaded_at'],
      )!,
    );
  }

  @override
  $OfflineDownloadsTable createAlias(String alias) {
    return $OfflineDownloadsTable(attachedDatabase, alias);
  }
}

class OfflineDownload extends DataClass implements Insertable<OfflineDownload> {
  final String userId;
  final String themeId;
  final String area;
  final String themeName;
  final String fileName;
  final String localPath;
  final int byteSize;
  final DateTime downloadedAt;
  const OfflineDownload({
    required this.userId,
    required this.themeId,
    required this.area,
    required this.themeName,
    required this.fileName,
    required this.localPath,
    required this.byteSize,
    required this.downloadedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['user_id'] = Variable<String>(userId);
    map['theme_id'] = Variable<String>(themeId);
    map['area'] = Variable<String>(area);
    map['theme_name'] = Variable<String>(themeName);
    map['file_name'] = Variable<String>(fileName);
    map['local_path'] = Variable<String>(localPath);
    map['byte_size'] = Variable<int>(byteSize);
    map['downloaded_at'] = Variable<DateTime>(downloadedAt);
    return map;
  }

  OfflineDownloadsCompanion toCompanion(bool nullToAbsent) {
    return OfflineDownloadsCompanion(
      userId: Value(userId),
      themeId: Value(themeId),
      area: Value(area),
      themeName: Value(themeName),
      fileName: Value(fileName),
      localPath: Value(localPath),
      byteSize: Value(byteSize),
      downloadedAt: Value(downloadedAt),
    );
  }

  factory OfflineDownload.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return OfflineDownload(
      userId: serializer.fromJson<String>(json['userId']),
      themeId: serializer.fromJson<String>(json['themeId']),
      area: serializer.fromJson<String>(json['area']),
      themeName: serializer.fromJson<String>(json['themeName']),
      fileName: serializer.fromJson<String>(json['fileName']),
      localPath: serializer.fromJson<String>(json['localPath']),
      byteSize: serializer.fromJson<int>(json['byteSize']),
      downloadedAt: serializer.fromJson<DateTime>(json['downloadedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'userId': serializer.toJson<String>(userId),
      'themeId': serializer.toJson<String>(themeId),
      'area': serializer.toJson<String>(area),
      'themeName': serializer.toJson<String>(themeName),
      'fileName': serializer.toJson<String>(fileName),
      'localPath': serializer.toJson<String>(localPath),
      'byteSize': serializer.toJson<int>(byteSize),
      'downloadedAt': serializer.toJson<DateTime>(downloadedAt),
    };
  }

  OfflineDownload copyWith({
    String? userId,
    String? themeId,
    String? area,
    String? themeName,
    String? fileName,
    String? localPath,
    int? byteSize,
    DateTime? downloadedAt,
  }) => OfflineDownload(
    userId: userId ?? this.userId,
    themeId: themeId ?? this.themeId,
    area: area ?? this.area,
    themeName: themeName ?? this.themeName,
    fileName: fileName ?? this.fileName,
    localPath: localPath ?? this.localPath,
    byteSize: byteSize ?? this.byteSize,
    downloadedAt: downloadedAt ?? this.downloadedAt,
  );
  OfflineDownload copyWithCompanion(OfflineDownloadsCompanion data) {
    return OfflineDownload(
      userId: data.userId.present ? data.userId.value : this.userId,
      themeId: data.themeId.present ? data.themeId.value : this.themeId,
      area: data.area.present ? data.area.value : this.area,
      themeName: data.themeName.present ? data.themeName.value : this.themeName,
      fileName: data.fileName.present ? data.fileName.value : this.fileName,
      localPath: data.localPath.present ? data.localPath.value : this.localPath,
      byteSize: data.byteSize.present ? data.byteSize.value : this.byteSize,
      downloadedAt: data.downloadedAt.present
          ? data.downloadedAt.value
          : this.downloadedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('OfflineDownload(')
          ..write('userId: $userId, ')
          ..write('themeId: $themeId, ')
          ..write('area: $area, ')
          ..write('themeName: $themeName, ')
          ..write('fileName: $fileName, ')
          ..write('localPath: $localPath, ')
          ..write('byteSize: $byteSize, ')
          ..write('downloadedAt: $downloadedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    userId,
    themeId,
    area,
    themeName,
    fileName,
    localPath,
    byteSize,
    downloadedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OfflineDownload &&
          other.userId == this.userId &&
          other.themeId == this.themeId &&
          other.area == this.area &&
          other.themeName == this.themeName &&
          other.fileName == this.fileName &&
          other.localPath == this.localPath &&
          other.byteSize == this.byteSize &&
          other.downloadedAt == this.downloadedAt);
}

class OfflineDownloadsCompanion extends UpdateCompanion<OfflineDownload> {
  final Value<String> userId;
  final Value<String> themeId;
  final Value<String> area;
  final Value<String> themeName;
  final Value<String> fileName;
  final Value<String> localPath;
  final Value<int> byteSize;
  final Value<DateTime> downloadedAt;
  final Value<int> rowid;
  const OfflineDownloadsCompanion({
    this.userId = const Value.absent(),
    this.themeId = const Value.absent(),
    this.area = const Value.absent(),
    this.themeName = const Value.absent(),
    this.fileName = const Value.absent(),
    this.localPath = const Value.absent(),
    this.byteSize = const Value.absent(),
    this.downloadedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  OfflineDownloadsCompanion.insert({
    required String userId,
    required String themeId,
    required String area,
    required String themeName,
    required String fileName,
    required String localPath,
    required int byteSize,
    required DateTime downloadedAt,
    this.rowid = const Value.absent(),
  }) : userId = Value(userId),
       themeId = Value(themeId),
       area = Value(area),
       themeName = Value(themeName),
       fileName = Value(fileName),
       localPath = Value(localPath),
       byteSize = Value(byteSize),
       downloadedAt = Value(downloadedAt);
  static Insertable<OfflineDownload> custom({
    Expression<String>? userId,
    Expression<String>? themeId,
    Expression<String>? area,
    Expression<String>? themeName,
    Expression<String>? fileName,
    Expression<String>? localPath,
    Expression<int>? byteSize,
    Expression<DateTime>? downloadedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (userId != null) 'user_id': userId,
      if (themeId != null) 'theme_id': themeId,
      if (area != null) 'area': area,
      if (themeName != null) 'theme_name': themeName,
      if (fileName != null) 'file_name': fileName,
      if (localPath != null) 'local_path': localPath,
      if (byteSize != null) 'byte_size': byteSize,
      if (downloadedAt != null) 'downloaded_at': downloadedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  OfflineDownloadsCompanion copyWith({
    Value<String>? userId,
    Value<String>? themeId,
    Value<String>? area,
    Value<String>? themeName,
    Value<String>? fileName,
    Value<String>? localPath,
    Value<int>? byteSize,
    Value<DateTime>? downloadedAt,
    Value<int>? rowid,
  }) {
    return OfflineDownloadsCompanion(
      userId: userId ?? this.userId,
      themeId: themeId ?? this.themeId,
      area: area ?? this.area,
      themeName: themeName ?? this.themeName,
      fileName: fileName ?? this.fileName,
      localPath: localPath ?? this.localPath,
      byteSize: byteSize ?? this.byteSize,
      downloadedAt: downloadedAt ?? this.downloadedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (themeId.present) {
      map['theme_id'] = Variable<String>(themeId.value);
    }
    if (area.present) {
      map['area'] = Variable<String>(area.value);
    }
    if (themeName.present) {
      map['theme_name'] = Variable<String>(themeName.value);
    }
    if (fileName.present) {
      map['file_name'] = Variable<String>(fileName.value);
    }
    if (localPath.present) {
      map['local_path'] = Variable<String>(localPath.value);
    }
    if (byteSize.present) {
      map['byte_size'] = Variable<int>(byteSize.value);
    }
    if (downloadedAt.present) {
      map['downloaded_at'] = Variable<DateTime>(downloadedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OfflineDownloadsCompanion(')
          ..write('userId: $userId, ')
          ..write('themeId: $themeId, ')
          ..write('area: $area, ')
          ..write('themeName: $themeName, ')
          ..write('fileName: $fileName, ')
          ..write('localPath: $localPath, ')
          ..write('byteSize: $byteSize, ')
          ..write('downloadedAt: $downloadedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $OfflineDownloadsTable offlineDownloads = $OfflineDownloadsTable(
    this,
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [offlineDownloads];
}

typedef $$OfflineDownloadsTableCreateCompanionBuilder =
    OfflineDownloadsCompanion Function({
      required String userId,
      required String themeId,
      required String area,
      required String themeName,
      required String fileName,
      required String localPath,
      required int byteSize,
      required DateTime downloadedAt,
      Value<int> rowid,
    });
typedef $$OfflineDownloadsTableUpdateCompanionBuilder =
    OfflineDownloadsCompanion Function({
      Value<String> userId,
      Value<String> themeId,
      Value<String> area,
      Value<String> themeName,
      Value<String> fileName,
      Value<String> localPath,
      Value<int> byteSize,
      Value<DateTime> downloadedAt,
      Value<int> rowid,
    });

class $$OfflineDownloadsTableFilterComposer
    extends Composer<_$AppDatabase, $OfflineDownloadsTable> {
  $$OfflineDownloadsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get themeId => $composableBuilder(
    column: $table.themeId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get area => $composableBuilder(
    column: $table.area,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get themeName => $composableBuilder(
    column: $table.themeName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fileName => $composableBuilder(
    column: $table.fileName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get localPath => $composableBuilder(
    column: $table.localPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get byteSize => $composableBuilder(
    column: $table.byteSize,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get downloadedAt => $composableBuilder(
    column: $table.downloadedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$OfflineDownloadsTableOrderingComposer
    extends Composer<_$AppDatabase, $OfflineDownloadsTable> {
  $$OfflineDownloadsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get themeId => $composableBuilder(
    column: $table.themeId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get area => $composableBuilder(
    column: $table.area,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get themeName => $composableBuilder(
    column: $table.themeName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fileName => $composableBuilder(
    column: $table.fileName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get localPath => $composableBuilder(
    column: $table.localPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get byteSize => $composableBuilder(
    column: $table.byteSize,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get downloadedAt => $composableBuilder(
    column: $table.downloadedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$OfflineDownloadsTableAnnotationComposer
    extends Composer<_$AppDatabase, $OfflineDownloadsTable> {
  $$OfflineDownloadsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get themeId =>
      $composableBuilder(column: $table.themeId, builder: (column) => column);

  GeneratedColumn<String> get area =>
      $composableBuilder(column: $table.area, builder: (column) => column);

  GeneratedColumn<String> get themeName =>
      $composableBuilder(column: $table.themeName, builder: (column) => column);

  GeneratedColumn<String> get fileName =>
      $composableBuilder(column: $table.fileName, builder: (column) => column);

  GeneratedColumn<String> get localPath =>
      $composableBuilder(column: $table.localPath, builder: (column) => column);

  GeneratedColumn<int> get byteSize =>
      $composableBuilder(column: $table.byteSize, builder: (column) => column);

  GeneratedColumn<DateTime> get downloadedAt => $composableBuilder(
    column: $table.downloadedAt,
    builder: (column) => column,
  );
}

class $$OfflineDownloadsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $OfflineDownloadsTable,
          OfflineDownload,
          $$OfflineDownloadsTableFilterComposer,
          $$OfflineDownloadsTableOrderingComposer,
          $$OfflineDownloadsTableAnnotationComposer,
          $$OfflineDownloadsTableCreateCompanionBuilder,
          $$OfflineDownloadsTableUpdateCompanionBuilder,
          (
            OfflineDownload,
            BaseReferences<
              _$AppDatabase,
              $OfflineDownloadsTable,
              OfflineDownload
            >,
          ),
          OfflineDownload,
          PrefetchHooks Function()
        > {
  $$OfflineDownloadsTableTableManager(
    _$AppDatabase db,
    $OfflineDownloadsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$OfflineDownloadsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$OfflineDownloadsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$OfflineDownloadsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> userId = const Value.absent(),
                Value<String> themeId = const Value.absent(),
                Value<String> area = const Value.absent(),
                Value<String> themeName = const Value.absent(),
                Value<String> fileName = const Value.absent(),
                Value<String> localPath = const Value.absent(),
                Value<int> byteSize = const Value.absent(),
                Value<DateTime> downloadedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => OfflineDownloadsCompanion(
                userId: userId,
                themeId: themeId,
                area: area,
                themeName: themeName,
                fileName: fileName,
                localPath: localPath,
                byteSize: byteSize,
                downloadedAt: downloadedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String userId,
                required String themeId,
                required String area,
                required String themeName,
                required String fileName,
                required String localPath,
                required int byteSize,
                required DateTime downloadedAt,
                Value<int> rowid = const Value.absent(),
              }) => OfflineDownloadsCompanion.insert(
                userId: userId,
                themeId: themeId,
                area: area,
                themeName: themeName,
                fileName: fileName,
                localPath: localPath,
                byteSize: byteSize,
                downloadedAt: downloadedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$OfflineDownloadsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $OfflineDownloadsTable,
      OfflineDownload,
      $$OfflineDownloadsTableFilterComposer,
      $$OfflineDownloadsTableOrderingComposer,
      $$OfflineDownloadsTableAnnotationComposer,
      $$OfflineDownloadsTableCreateCompanionBuilder,
      $$OfflineDownloadsTableUpdateCompanionBuilder,
      (
        OfflineDownload,
        BaseReferences<_$AppDatabase, $OfflineDownloadsTable, OfflineDownload>,
      ),
      OfflineDownload,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$OfflineDownloadsTableTableManager get offlineDownloads =>
      $$OfflineDownloadsTableTableManager(_db, _db.offlineDownloads);
}
