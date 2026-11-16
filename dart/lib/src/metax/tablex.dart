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

  /// Domain ID
  final int di;

  /// Display name
  final String n;

  /// Table type (TypeX Group 4 catalog ID)
  /// Default: 100014 (Private · Log Off · Auto Increment · BIGINT)
  final int tt;

  /// Code (unique within domain)
  final String c;

  /// Partition width for Algorithm 1 sync (0 = unset)
  final int px;

  /// Origin: 0=native, >0=copied from, <0=imported from
  final int f;

  const TableX({
    required this.i,
    required this.d,
    required this.e,
    required this.a,
    required this.di,
    required this.n,
    this.tt = 100014,
    required this.c,
    this.px = 0,
    this.f = 0,
  });

  /// Decode table type into components
  TableTypeDecoded get tableType => TableTypeDecoded.decode(tt);

  /// Is this table native to this domain?
  bool get isNative => f == 0;

  /// Is this table copied from another domain?
  bool get isCopied => f > 0;

  /// Is this table imported from another domain?
  bool get isImported => f < 0;

  factory TableX.fromJson(Map<String, dynamic> json) {
    return TableX(
      i: json['i'] as int,
      d: json['d'] as int,
      e: json['e'] as int,
      a: json['a'] as int,
      di: json['di'] as int,
      n: json['n'] as String,
      tt: json['tt'] as int? ?? 100014,
      c: json['c'] as String,
      px: json['px'] as int? ?? 0,
      f: json['f'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'i': i,
    'd': d,
    'e': e,
    'a': a,
    'di': di,
    'n': n,
    'tt': tt,
    'c': c,
    'px': px,
    'f': f,
  };

  @override
  String toString() => 'TableX(i=$i, n=$n, c=$c, tt=$tt)';

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
