/// Physical table metadata (mx.tablex table)
class TableX {
  /// Table metadata ID
  final int i;

  /// Last edit timestamp (epoch ms)
  final int d;

  /// Editor user ID
  final int e;

  /// Active status
  final int a;

  /// Domain ID reference
  final int dxi;

  /// Display name
  final String n;

  /// Provenance: 0=native, >0=copied, <0=imported
  final int f;

  /// Table type (TypeX Group 4 catalog ID)
  /// Default: 100014 (Private · Log Off · Auto Increment · BIGINT)
  final int ttx;

  /// Code (unique within domain)
  final String c;

  /// Partition width for Algorithm 1 sync (0 = unset)
  final int px;

  /// Optional recursive parent identifier; existence is not guaranteed.
  final int fp;

  const TableX({
    required this.i,
    required this.d,
    required this.e,
    required this.a,
    required this.dxi,
    required this.n,
    required this.f,
    this.ttx = 100014,
    required this.c,
    this.px = 0,
    this.fp = 0,
  });

  /// Decode table type into components
  TableTypeDecoded get tableType => TableTypeDecoded.decode(ttx);

  factory TableX.fromJson(Map<String, dynamic> json) {
    return TableX(
      i: json['i'] as int,
      d: json['d'] as int,
      e: json['e'] as int,
      a: json['a'] as int,
      dxi: json['dxi'] as int,
      n: json['n'] as String,
      f: json['f'] as int,
      ttx: json['ttx'] as int? ?? 100014,
      c: json['c'] as String,
      px: json['px'] as int? ?? 0,
      fp: json['fp'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'i': i,
    'd': d,
    'e': e,
    'a': a,
    'dxi': dxi,
    'n': n,
    'f': f,
    'ttx': ttx,
    'c': c,
    'px': px,
    'fp': fp,
  };

  @override
  String toString() => 'TableX(i=$i, n=$n, c=$c, ttx=$ttx)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TableX && runtimeType == other.runtimeType && i == other.i;

  @override
  int get hashCode => i.hashCode;
}

/// Decoded table type components
class TableTypeDecoded {
  final int
  sync; // 0=Private, 1=Protected, 2=Synced-Origin, 3=Synced-Origin-Main
  final int log; // 0=Off, 1=On
  final int algorithm; // 0=Custom, 1=Auto Increment, 2=Epoch Server Serial
  final int format; // 3=INTEGER, 4=BIGINT, 5=UUID

  const TableTypeDecoded({
    required this.sync,
    required this.log,
    required this.algorithm,
    required this.format,
  });

  factory TableTypeDecoded.decode(int tt) {
    final key = tt - 100000;
    return TableTypeDecoded(
      sync: (key ~/ 1000) % 10,
      log: (key ~/ 100) % 10,
      algorithm: (key ~/ 10) % 10,
      format: key % 10,
    );
  }

  int encode() {
    return 100000 + (sync * 1000) + (log * 100) + (algorithm * 10) + format;
  }

  String get syncName {
    switch (sync) {
      case 0:
        return 'Private';
      case 1:
        return 'Protected';
      case 2:
        return 'Synced-Origin';
      case 3:
        return 'Synced-Origin-Main';
      default:
        return 'Unknown';
    }
  }

  String get logName => log == 1 ? 'On' : 'Off';

  String get algorithmName {
    switch (algorithm) {
      case 0:
        return 'Custom';
      case 1:
        return 'Auto Increment';
      case 2:
        return 'Epoch Server Serial';
      default:
        return 'Unknown';
    }
  }

  String get formatName {
    switch (format) {
      case 3:
        return 'INTEGER';
      case 4:
        return 'BIGINT';
      case 5:
        return 'UUID';
      default:
        return 'Unknown';
    }
  }

  @override
  String toString() =>
      'TableType(sync=$syncName, log=$logName, algorithm=$algorithmName, format=$formatName)';
}
