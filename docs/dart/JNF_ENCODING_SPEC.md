# JNF Encoding Specification

## Overview

The examples in this document use the existing AIX Group 3 IDs where a schema
ID is shown. The current data type registry is separate; for example, its
INT64 and unlimited NUMERIC IDs are 40000 and 60000. JSONC number-format
behavior applies to both catalogs, and JCore does not translate IDs between
them.

The `jnf` (JSON Number Format) field in JSONC provides backward compatibility with formal JSON arrays and flexible encoding options for different use cases.

## Encoding Modes (0-5)

### Formal JSON Array Format (0-1)

**Mode 0: Web-Safe Input (Both String)**
- **BigInt**: String
- **Numeric**: String
- **Use case**: Incoming data from web APIs, JavaScript clients
- **Safety**: Maximum web compatibility, prevents precision loss
- **Format**: Traditional JSON array with numbers as strings

```json
{
  "jv": 1737849600,
  "jid": 5001,
  "jnf": 0,
  "data": [["9007199254740992", "1234.56789"]]
}
```

**Mode 1: Raw Numbers (Both Plain) — Not Web-Safe**
- **BigInt**: Plain number
- **Numeric**: Plain number
- **Use case**: Internal systems, non-web environments
- **Safety**: NOT web-safe, potential precision loss in JavaScript
- **Format**: Traditional JSON array with raw numbers

```json
{
  "jv": 1737849600,
  "jid": 5001,
  "jnf": 1,
  "data": [[9007199254740992, 1234.56789]]
}
```

### JSONC Format (2-5)

**Mode 2: JSONC Raw (Both Plain) — Default, Not Web-Safe**
- **BigInt**: Plain number
- **Numeric**: Plain number
- **Use case**: High-performance internal processing
- **Safety**: NOT web-safe, best performance
- **Format**: JSONC compressed format

```json
{
  "jv": 1737849600,
  "jid": 5001,
  "jnf": 2,
  "data": [[9007199254740992, 1234.56789]]
}
```

**Mode 3: JSONC BigInt String**
- **BigInt**: String
- **Numeric**: Plain number
- **Use case**: Large integer IDs with decimal calculations
- **Safety**: Web-safe for large integers, numeric precision ok
- **Format**: JSONC compressed format

```json
{
  "jv": 1737849600,
  "jid": 5001,
  "jnf": 3,
  "data": [["9007199254740992", 1234.56789]]
}
```

**Mode 4: JSONC Numeric String — Not Web-Safe for INT64**
- **BigInt**: Plain number
- **Numeric**: String
- **Use case**: Financial/precise decimal calculations with safe integer IDs
- **Safety**: Decimal strings preserve decimal precision; not web-safe for INT64 values outside the JavaScript safe integer range
- **Format**: JSONC compressed format

```json
{
  "jv": 1737849600,
  "jid": 5001,
  "jnf": 4,
  "data": [[123, "1234.56789"]]
}
```

**Mode 5: JSONC Maximum Safety (Both String)**
- **BigInt**: String
- **Numeric**: String
- **Use case**: Financial systems, maximum precision required
- **Safety**: Maximum safety, prevents all precision loss
- **Format**: JSONC compressed format

```json
{
  "jv": 1737849600,
  "jid": 5001,
  "jnf": 5,
  "data": [["9007199254740992", "1234.56789"]]
}
```

## Backward Compatibility

### With Formal JSON (Mode 0-1)

JSONC can accept traditional JSON array format:

```dart
// Traditional formal JSON with string numbers
final formalJson = JsonC.fromJson({
  'jv': 1737849600,
  'jid': 5001,
  'jnf': 0,
  'schema': {'id': 40000, 'amount': 60000},
  'data': [["9007199254740992", "1234.56789"]]
});

// The schema identifies id as INT64, which is read as a Dart BigInt.
// The amount remains a string to preserve its decimal precision.
```

### Default Behavior

When `jnf` is omitted, defaults to mode 2 (JSONC raw, both plain):

```dart
// No jnf specified = mode 2
final jsonc = JsonC(
  jv: 1737849600,
  jid: 5001,
  data: [[123, 1234.56789]],
);

print(jsonc.encoding); // 2
```

## Decision Matrix

| Use Case | Mode | BigInt | Numeric | Format |
|----------|------|--------|---------|--------|
| Web API input | 0 | String | String | Formal JSON |
| Internal non-web; not web-safe | 1 | Plain | Plain | Formal JSON |
| High performance; not web-safe | 2 | Plain | Plain | JSONC (default) |
| Large integer IDs | 3 | String | Plain | JSONC |
| Financial decimals; not web-safe for INT64 | 4 | Plain | String | JSONC |
| Maximum safety | 5 | String | String | JSONC |

## JavaScript Safety Guide

### Safe Integer Range
JavaScript can safely represent integers up to `2^53 - 1` (9,007,199,254,740,991).

**Examples:**
- ✅ Safe: `123`, `1000000`, `9007199254740991`
- ❌ Unsafe: `9007199254740992`, `1234567890123456789`

**Recommendation:**
- Use mode 0 or 3 for BigInt values that may exceed JS safe range
- Use mode 4 or 5 for high-precision decimal values; choose mode 5 if INT64 values may exceed the JavaScript safe integer range

## PostgreSQL responses through a pass-through API

PostgreSQL can generate the JSON or JSONC response and the Web API can forward
the HTTP body without converting it to an application model. This preserves
integer and decimal values when the API and any intermediaries do not parse
and reserialize the numbers through floating point. The same condition applies
to request bodies on their way to PostgreSQL.

Choose the representation for the **client that will parse the response**:

| Client | INT64 wire form | Suitable modes | Dart representation |
|--------|-----------------|----------------|---------------------|
| Native Dart | JSON number | 1, 2, 4 | `int` |
| Flutter web, full INT64 range | Decimal string | 0, 3, 5 | `BigInt` |

PostgreSQL `bigint` and native Dart `int` have the same signed 64-bit range.
Arithmetic on a native Dart `int` can still overflow that range.
PostgreSQL `jsonb` represents JSON numbers as `numeric` and can preserve that
entire range. JavaScript number parsing can lose integer precision above
`2^53 - 1`, so a web client must receive INT64 as a string when the full range
is needed. The API forwarding the body does not make raw numbers web-safe.

For a schema containing INT64 and NUMERIC, the producer must independently
apply each string-mode rule. The following example emits a full JSONC response;
change `jnf` to the requested mode to select the wire representation:

```sql
WITH example AS (
  SELECT 5 AS jnf,
         9223372036854775807::bigint AS id,
         1234.50::numeric AS amount
)
SELECT jsonb_build_object(
  'jv', 1,
  'jid', 1,
  'jnf', jnf,
  'schema', jsonb_build_object('id', 40000, 'amount', 61002),
  'data', jsonb_build_array(jsonb_build_array(
    CASE WHEN jnf IN (0, 3, 5)
      THEN to_jsonb(id::text) ELSE to_jsonb(id) END,
    CASE WHEN jnf IN (0, 4, 5)
      THEN to_jsonb(amount::text) ELSE to_jsonb(amount) END
  ))
)
FROM example;
```

Here mode 5 emits both values as strings. Mode 3 emits INT64 as a string but
NUMERIC as a number; mode 4 does the reverse. Raw NUMERIC values can lose
decimal precision when decoded into a `double`, including on native Dart.
With a schema, `JsonC.parse` converts string-mode INT64 to `BigInt`; NUMERIC
strings remain strings. Dart callers can pass a `Numeric` instance to `JsonC`:
it is emitted as a decimal string in modes 0, 4, and 5, and as a JSON number in
other modes. Parsing a JSON NUMERIC string does not automatically construct a
`Numeric` instance. Data-only responses must be joined with their schema before
INT64 strings can be identified and converted. In a plain JSON response
without `jnf`, the producer and consumer must agree on the representation.

The current Dart registry uses INT64 ID `40000` and NUMERIC base ID `60000`.
The SQL example above uses the existing AIX Group 3 IDs for compatibility with
that schema; JCore does not translate IDs between the catalogs.

The row order in this example matches the serialized schema order. JSON object
key order is not a portable contract, and PostgreSQL `jsonb` can reorder keys;
producers and consumers must ensure that schema order and row positions agree.

## Implementation in JsonC

```dart
class JsonC {
  final int? jnf;  // Encoding mode (0-5), defaults to 2

  /// Get encoding mode (0-5, defaults to 2)
  int get encoding => jnf ?? 2;

  /// Check if this is formal JSON array format (modes 0-1)
  bool get isFormalJsonArray => encoding == 0 || encoding == 1;

  /// Check if this is JSONC format (modes 2-5)
  bool get isJsonCFormat => encoding >= 2 && encoding <= 5;

  /// Check if BigInt should be encoded as string
  bool get useBigIntStrings {
    switch (encoding) {
      case 0: // Formal JSON: both string
      case 3: // JSONC: BigInt string
      case 5: // JSONC: both string
        return true;
      default:
        return false;
    }
  }

  /// Check if Numeric should be encoded as string
  bool get useNumericStrings {
    switch (encoding) {
      case 0: // Formal JSON: both string
      case 4: // JSONC: Numeric string
      case 5: // JSONC: both string
        return true;
      default:
        return false;
    }
  }
}
```

## Usage Examples

### Web API Integration (Mode 0)

```dart
// Accept formal JSON from web client
final incoming = JsonC.fromJson({
  'jv': 1737849600,
  'jid': 5001,
  'jnf': 0,
  'schema': {'id': 40000, 'amount': 60000},
  'data': [["9007199254740992", "1234.56789"]]
});

// Process internally
final users = JConverter.toMaps(incoming);

// Send back as JSONC mode 3 (efficient, web-safe BigInt)
final outgoing = JsonC(
  jv: 1737849600,
  jid: 5001,
  jnf: 3,
  schema: {'id': 40000, 'amount': 60000},
  data: [[BigInt.parse('9007199254740992'), 1234.56789]],
);
```

### Financial Application (Mode 5)

```dart
// Maximum precision for financial data
final transactions = JsonC(
  jv: 1737849600,
  jid: 6001,
  jnf: 5,  // Both as string
  schema: {
    'transaction_id': 40000,
    'amount': 61002,
  },
  data: [
    ["9007199254740992", "12345.67"],
    ["9007199254740993", "99999.99"],
  ],
);
```

### High-Performance Internal (Mode 2)

```dart
// Default mode for internal processing
final analytics = JsonC(
  jv: 1737849600,
  jid: 7001,
  // jnf omitted = mode 2 (default)
  schema: {
    'user_id': 40000,
    'score': 61002,
  },
  data: [[1, 95.5], [2, 87.3]],
);
```

## Migration Guide

### From Old jnf (0-2) to New (0-5)

**Old encoding:**
- 0 = All numbers
- 1 = BigInt string
- 2 = All strings

**Migration:**
- Old 0 → New 2 (JSONC raw, default)
- Old 1 → New 3 (JSONC BigInt string)
- Old 2 → New 5 (JSONC both string)

**New capabilities:**
- Mode 0: Formal JSON web-safe input
- Mode 1: Formal JSON raw numbers
- Mode 4: JSONC Numeric string only

## Testing

```dart
test('encoding mode 0: formal JSON both string', () {
  final jsonc = JsonC(jv: 1, jid: 1, jnf: 0);
  
  expect(jsonc.encoding, equals(0));
  expect(jsonc.isFormalJsonArray, isTrue);
  expect(jsonc.useBigIntStrings, isTrue);
  expect(jsonc.useNumericStrings, isTrue);
});

test('encoding mode 3: JSONC BigInt string', () {
  final jsonc = JsonC(jv: 1, jid: 1, jnf: 3);
  
  expect(jsonc.encoding, equals(3));
  expect(jsonc.isJsonCFormat, isTrue);
  expect(jsonc.useBigIntStrings, isTrue);
  expect(jsonc.useNumericStrings, isFalse);
});

test('default encoding is 2', () {
  final jsonc = JsonC(jv: 1, jid: 1);
  
  expect(jsonc.encoding, equals(2));
  expect(jsonc.isJsonCFormat, isTrue);
});
```

## Summary

The 6-mode encoding system provides:

✅ **Backward compatibility** with formal JSON arrays (modes 0-1)  
✅ **High performance** with JSONC raw format (mode 2, default)  
✅ **Flexible safety** for BigInt, Numeric, or both (modes 3-5)  
✅ **Web-safe** options for JavaScript clients (modes 0, 3, 5)  
✅ **Precision control** for financial applications (modes 4-5)

**Default mode 2** balances performance and compatibility for internal AIX systems while supporting all other modes for specific requirements.
