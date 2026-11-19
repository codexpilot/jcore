/// Domain hierarchy and scope configuration (cox.domainx table)
class DomainX {
  /// Domain ID
  /// - Framework: -1000 to -1
  /// - Template: ≤ -1001
  /// - Solution: ≥ 1
  final int i;

  /// Last edit timestamp (epoch milliseconds)
  final int d;

  /// Editor user ID
  final int e;

  /// Active status (0=inactive, 1=active)
  final int a;

  /// Display name
  final String n;

  /// Code (unique identifier)
  final String c;

  /// Parent domain ID (framework root for templates/solutions)
  final int p;

  /// Import source domain IDs (template domains only)
  final List<int> iDxis;

  /// Copy source domain IDs (solution domains only)
  final List<int> cDxis;

  /// Server digit count (Algorithm 2 configuration)
  /// Default: 3 (max 999 servers)
  final int sc;

  /// Terminal digit count (Algorithm 2 configuration)
  /// Default: 3 (max 999 terminals)
  final int tc;

  /// Relative year for epoch
  /// -1 = current year, 0 = 1970, n = 1970+n
  final int ry;

  /// Concurrent serial digit count (Algorithm 2 configuration)
  /// Default: 3 (max 999 IDs per millisecond)
  final int cc;

  const DomainX({
    required this.i,
    required this.d,
    required this.e,
    required this.a,
    required this.n,
    required this.c,
    required this.p,
    this.iDxis = const [],
    this.cDxis = const [],
    this.sc = 3,
    this.tc = 3,
    this.ry = -1,
    this.cc = 3,
  });

  /// Domain type based on ID range
  DomainType get type {
    if (i >= 1) return DomainType.solution;
    if (i <= -1001) return DomainType.template;
    if (i >= -1000 && i <= -1) return DomainType.framework;
    throw StateError('Invalid domain ID: $i');
  }

  /// Is this a root domain (self-parent)?
  bool get isRoot => i == p;

  /// Is this domain active?
  bool get isActive => a == 1;

  /// Maximum servers based on sc
  int get maxServers {
    if (sc <= 0) return 0;
    int max = 1;
    for (int i = 0; i < sc; i++) {
      max *= 10;
    }
    return max - 1;
  }

  /// Maximum terminals based on tc
  int get maxTerminals {
    if (tc <= 0) return 0;
    int max = 1;
    for (int i = 0; i < tc; i++) {
      max *= 10;
    }
    return max - 1;
  }

  /// Maximum serial IDs per millisecond based on cc
  int get maxSerialPerMs {
    if (cc <= 0) return 0;
    int max = 1;
    for (int i = 0; i < cc; i++) {
      max *= 10;
    }
    return max - 1;
  }

  /// Human-readable epoch description
  String get epochDescription {
    if (ry == -1) return 'Current year at generation';
    if (ry == 0) return 'Unix epoch (1970)';
    return 'Year ${1970 + ry}';
  }

  factory DomainX.fromJson(Map<String, dynamic> json) {
    return DomainX(
      i: json['i'] as int,
      d: json['d'] as int,
      e: json['e'] as int,
      a: json['a'] as int,
      n: json['n'] as String,
      c: json['c'] as String,
      p: json['p'] as int,
      iDxis: (json['i_dxis'] as List<dynamic>?)?.cast<int>() ?? const [],
      cDxis: (json['c_dxis'] as List<dynamic>?)?.cast<int>() ?? const [],
      sc: json['sc'] as int? ?? 3,
      tc: json['tc'] as int? ?? 3,
      ry: json['ry'] as int? ?? -1,
      cc: json['cc'] as int? ?? 3,
    );
  }

  Map<String, dynamic> toJson() => {
    'i': i,
    'd': d,
    'e': e,
    'a': a,
    'n': n,
    'c': c,
    'p': p,
    'i_dxis': iDxis,
    'c_dxis': cDxis,
    'sc': sc,
    'tc': tc,
    'ry': ry,
    'cc': cc,
  };

  @override
  String toString() => 'DomainX(i=$i, n=$n, c=$c, type=$type)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DomainX && runtimeType == other.runtimeType && i == other.i;

  @override
  int get hashCode => i.hashCode;
}

enum DomainType { framework, template, solution }
