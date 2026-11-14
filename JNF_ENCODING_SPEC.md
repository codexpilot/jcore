# JNF Encoding Specification

## Overview

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

**Mode 1: Raw Numbers (Both Plain)**
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

**Mode 2: JSONC Raw (Both Plain) - DEFAULT**
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

**Mode 4: JSONC Numeric String**
- **BigInt**: Plain number
- **Numeric**: String
- **Use case**: Financial/precise decimal calculations with safe integer IDs
- **Safety**: Maximum decimal precision, BigInt within JS range
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
  'data': [["9007199254740992", "1234.56789"]]
});

// Automatically handles string to number conversion
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
| Internal non-web | 1 | Plain | Plain | Formal JSON |
| High performance | 2 | Plain | Plain | JSONC (default) |
| Large integer IDs | 3 | String | Plain | JSONC |
| Financial decimals | 4 | Plain | String | JSONC |
| Maximum safety | 5 | String | String | JSONC |

## JavaScript Safety Guide

### Safe Integer Range
JavaScript can safely represent integers up to `2^53 - 1` (9,007,199,254,740,991).

**Examples:**
- ✅ Safe: `123`, `1000000`, `9007199254740991`
- ❌ Unsafe: `9007199254740992`, `1234567890123456789`

**Recommendation:**
- Use mode 0 or 3 for BigInt values that may exceed JS safe range
- Use mode 4 or 5 for high-precision decimal values

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
  'data': [["9007199254740992", "1234.56789"]]
});

// Process internally
final users = JConverter.toMaps(incoming);

// Send back as JSONC mode 3 (efficient, web-safe BigInt)
final outgoing = JsonC(
  jv: 1737849600,
  jid: 5001,
  jnf: 3,
  data: [[9007199254740992, 1234.56789]],
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
    'transaction_id': 300003,
    'amount': 310020,
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
    'user_id': 300003,
    'score': 310020,
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
