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
  /// SXB format: 100000 + 100×S + 10×X + B
  /// S = Sync policy (0-3), X = 3×algorithm+(format-3), B = 2×logging+recursion
  /// Default: 100040 (Private · Auto-increment BIGINT · Flat with log off)
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
    this.ttx = 100040,
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
      ttx: json['ttx'] as int? ?? 100040,
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

/// Decoded table type components (SXB format)
class TableTypeDecoded {
  final int sync; // 0=Private, 1=Protected, 2=Synced, 3=Main
  final int algorithm; // 0=Custom/supplied, 1=Auto-increment, 2=Epoch Server Serial
  final int format; // 3=INTEGER, 4=BIGINT, 5=UUID
  final int recursion; // 0=flat, 1=recursive
  final int logging; // 0=off, 1=on

  const TableTypeDecoded({
    required this.sync,
    required this.algorithm,
    required this.format,
    required this.recursion,
    required this.logging,
  });

  /// Decode from SXB format: 100000 + 100×S + 10×X + B
  /// where X = 3×algorithm + (format-3), B = 2×logging + recursion
  factory TableTypeDecoded.decode(int tt) {
    final key = tt - 100000;
    final s = (key ~/ 100) % 10;
    final x = (key ~/ 10) % 10;
    final b = key % 10;

    // Decode X: X = 3×algorithm + (format-3)
    final algorithm = x ~/ 3;
    final format = 3 + (x % 3);

    // Decode B: B = 2×logging + recursion
    final logging = b ~/ 2;
    final recursion = b % 2;

    return TableTypeDecoded(
      sync: s,
      algorithm: algorithm,
      format: format,
      recursion: recursion,
      logging: logging,
    );
  }

  /// Encode to SXB format
  int encode() {
    final x = 3 * algorithm + (format - 3);
    final b = 2 * logging + recursion;
    return 100000 + (sync * 100) + (x * 10) + b;
  }

  String get syncName {
    switch (sync) {
      case 0:
        return 'Private';
      case 1:
        return 'Protected';
      case 2:
        return 'Synced';
      case 3:
        return 'Main';
      default:
        return 'Unknown';
    }
  }

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

  /// Get DataTypeX ID from format code
  /// Format 3=INTEGER maps to DataTypeX 2 (INT32)
  /// Format 4=BIGINT maps to DataTypeX 3 (INT64)
  /// Format 5=UUID maps to DataTypeX 6 (UUID)
  int get dataTypeId {
    switch (format) {
      case 3:
        return 2; // INT32
      case 4:
        return 3; // INT64
      case 5:
        return 6; // UUID
      default:
        return format;
    }
  }

  @override
  String toString() =>
      'TableType(sync=$syncName, algorithm=$algorithmName, format=$formatName, logging=${logging == 1 ? "On" : "Off"}, recursion=${recursion == 1 ? "Yes" : "No"})';
}
