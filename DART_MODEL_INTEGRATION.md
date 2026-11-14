# Dart Model Integration with JConverter

## Overview

JConverter provides seamless integration between JSONC format and Dart model classes, enabling type-safe conversion between structured Dart objects and AIX data interchange format.

## Basic Model Integration

### 1. Simple Model Example

```dart
import 'package:jcore/jcore.dart';

class User {
  final int id;
  final String name;
  final String email;
  final bool isActive;

  const User({
    required this.id,
    required this.name,
    required this.email,
    required this.isActive,
  });

  // Convert from Map (after JConverter.toMaps())
  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] as int,
      name: map['name'] as String,
      email: map['email'] as String,
      isActive: map['is_active'] as bool,
    );
  }

  // Convert to Map (before JConverter.fromMaps())
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'is_active': isActive,
    };
  }
}
```

### 2. Using with JConverter

```dart
void main() {
  // Define schema
  final schema = JsonC(
    jv: 1737849600,
    jid: 5001,
    jnf: 3,  // JSONC, BigInt as string
    schema: {
      'id': JDataType.int64.id,
      'name': encodeTextType(length: 100),
      'email': encodeTextType(length: 255),
      'is_active': JDataType.boolean.id,
    },
  );

  // Register schema in JBase
  JBase.instance.register(schema);

  // Receive data from API
  final apiResponse = {
    'jv': 1737849600,
    'jid': 5001,
    'jnf': 3,
    'data': [
      [1, 'Alice', 'alice@example.com', true],
      [2, 'Bob', 'bob@example.com', false],
    ]
  };

  // Parse and merge
  final dataOnly = JsonC.fromJson(apiResponse);
  final fullData = JBase.instance.mergeWithSchema(dataOnly);

  // Convert to Dart models
  final users = JConverter.toMaps(fullData)
      .map((map) => User.fromMap(map))
      .toList();

  // Use your models
  for (final user in users) {
    print('${user.name}: ${user.email}');
  }
}
```

## Advanced Model Patterns

### 1. Nested Models

```dart
class Address {
  final String street;
  final String city;
  final String zipCode;

  const Address({
    required this.street,
    required this.city,
    required this.zipCode,
  });

  factory Address.fromMap(Map<String, dynamic> map) {
    return Address(
      street: map['street'] as String,
      city: map['city'] as String,
      zipCode: map['zip_code'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'street': street,
      'city': city,
      'zip_code': zipCode,
    };
  }
}

class Customer {
  final int id;
  final String name;
  final Address address;

  const Customer({
    required this.id,
    required this.name,
    required this.address,
  });

  factory Customer.fromMap(Map<String, dynamic> map) {
    return Customer(
      id: map['id'] as int,
      name: map['name'] as String,
      address: Address.fromMap({
        'street': map['street'],
        'city': map['city'],
        'zip_code': map['zip_code'],
      }),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      ...address.toMap(),
    };
  }
}
```

### 2. Financial Model with Precision

```dart
import 'package:decimal/decimal.dart';

class Transaction {
  final int id;
  final Decimal amount;
  final String currency;
  final DateTime timestamp;

  const Transaction({
    required this.id,
    required this.amount,
    required this.currency,
    required this.timestamp,
  });

  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      id: map['id'] as int,
      amount: Decimal.parse(map['amount'].toString()),
      currency: map['currency'] as String,
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'amount': amount.toString(),  // Always string for precision
      'currency': currency,
      'timestamp': timestamp.millisecondsSinceEpoch,
    };
  }
}

// Usage with mode 5 (both BigInt and Numeric as string)
void processTransactions() {
  final schema = JsonC(
    jv: 1737849600,
    jid: 6001,
    jnf: 5,  // Maximum safety for financial data
    schema: {
      'id': JDataType.int64.id,
      'amount': encodeNumericType(precision: 15, scale: 4),
      'currency': encodeTextType(length: 3),
      'timestamp': JDataType.int64.id,
    },
  );

  JBase.instance.register(schema);

  // Process incoming transactions
  final jsonc = JsonC.fromJson({
    'jv': 1737849600,
    'jid': 6001,
    'jnf': 5,
    'data': [
      ["1", "12345.6789", "USD", "1737849600000"],
      ["2", "99999.9999", "EUR", "1737849700000"],
    ]
  });

  final full = JBase.instance.mergeWithSchema(jsonc);
  final transactions = JConverter.toMaps(full)
      .map((map) => Transaction.fromMap(map))
      .toList();
}
```

### 3. Nullable Fields

```dart
class Product {
  final int id;
  final String name;
  final double? price;  // Nullable
  final String? description;  // Nullable
  final int? categoryId;  // Nullable

  const Product({
    required this.id,
    required this.name,
    this.price,
    this.description,
    this.categoryId,
  });

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'] as int,
      name: map['name'] as String,
      price: map['price'] as double?,
      description: map['description'] as String?,
      categoryId: map['category_id'] as int?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'description': description,
      'category_id': categoryId,
    };
  }
}
```

### 4. Enum Support

```dart
enum UserRole {
  admin,
  user,
  guest;

  static UserRole fromString(String value) {
    return UserRole.values.firstWhere(
      (role) => role.name == value,
      orElse: () => UserRole.guest,
    );
  }
}

class Employee {
  final int id;
  final String name;
  final UserRole role;

  const Employee({
    required this.id,
    required this.name,
    required this.role,
  });

  factory Employee.fromMap(Map<String, dynamic> map) {
    return Employee(
      id: map['id'] as int,
      name: map['name'] as String,
      role: UserRole.fromString(map['role'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'role': role.name,
    };
  }
}
```

## JConverter API Reference

### Core Conversion Methods

```dart
class JConverter {
  /// Convert JSONC data to List<Map<String, dynamic>>
  static List<Map<String, dynamic>> toMaps(JsonC jsonc);

  /// Convert List<Map<String, dynamic>> to JSONC
  static JsonC fromMaps(
    List<Map<String, dynamic>> maps,
    int jid,
    int jv, {
    int? jnf,
  });

  /// Validate JSONC structure and data types
  static List<String> validate(JsonC jsonc);

  /// Generate PostgreSQL CREATE TABLE DDL
  static String toCreateTableDDL(JsonC jsonc, String tableName);
}
```

### Validation

```dart
// Validate before conversion
final errors = JConverter.validate(jsonc);
if (errors.isEmpty) {
  final models = JConverter.toMaps(jsonc)
      .map((map) => MyModel.fromMap(map))
      .toList();
} else {
  print('Validation errors: ${errors.join(", ")}');
}
```

### Type-Safe Conversion

```dart
extension JsonCModelExtension<T> on JsonC {
  /// Convert JSONC to typed list of models
  List<T> toModels<T>(T Function(Map<String, dynamic>) fromMap) {
    return JConverter.toMaps(this).map(fromMap).toList();
  }
}

// Usage
final users = jsonc.toModels<User>(User.fromMap);
```

## Best Practices

### 1. Schema Definition with Models

```dart
class UserSchema {
  static JsonC get schema => JsonC(
    jv: 1737849600,
    jid: 5001,
    jnf: 3,
    schema: {
      'id': JDataType.int64.id,
      'name': encodeTextType(length: 100),
      'email': encodeTextType(length: 255),
      'is_active': JDataType.boolean.id,
      'created_at': JDataType.int64.id,
    },
  );

  static void register() {
    JBase.instance.register(schema);
  }
}

// Initialize at app startup
void initSchemas() {
  UserSchema.register();
  ProductSchema.register();
  OrderSchema.register();
}
```

### 2. Batch Conversion

```dart
class UserRepository {
  Future<List<User>> fetchUsers() async {
    final response = await api.get('/users');
    
    final jsonc = JsonC.fromJson(response);
    final full = JBase.instance.mergeWithSchema(jsonc);
    
    return JConverter.toMaps(full)
        .map((map) => User.fromMap(map))
        .toList();
  }

  Future<void> saveUsers(List<User> users) async {
    final maps = users.map((u) => u.toMap()).toList();
    
    final jsonc = JConverter.fromMaps(
      maps,
      5001,  // User schema JID
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      jnf: 3,
    );
    
    await api.post('/users', jsonc.toJson());
  }
}
```

### 3. Error Handling

```dart
class ModelConverter<T> {
  final T Function(Map<String, dynamic>) fromMap;
  final int jid;

  const ModelConverter(this.fromMap, this.jid);

  List<T> convert(JsonC jsonc) {
    // Validate structure
    final errors = JConverter.validate(jsonc);
    if (errors.isNotEmpty) {
      throw ValidationException('JSONC validation failed: ${errors.join(", ")}');
    }

    // Merge with schema if needed
    final full = jsonc.hasSchema 
        ? jsonc 
        : JBase.instance.mergeWithSchema(jsonc);

    // Convert to models
    try {
      return JConverter.toMaps(full)
          .map(fromMap)
          .toList();
    } catch (e) {
      throw ConversionException('Failed to convert to model: $e');
    }
  }
}

// Usage
final userConverter = ModelConverter<User>(User.fromMap, 5001);
final users = userConverter.convert(jsonc);
```

### 4. Stream Processing

```dart
class RealtimeUserStream {
  Stream<List<User>> get users => _controller.stream;
  final _controller = StreamController<List<User>>();

  void handleIncomingData(Map<String, dynamic> json) {
    final jsonc = JsonC.fromJson(json);
    final full = JBase.instance.mergeWithSchema(jsonc);
    
    final users = JConverter.toMaps(full)
        .map((map) => User.fromMap(map))
        .toList();
    
    _controller.add(users);
  }

  void dispose() {
    _controller.close();
  }
}
```

## Testing Models with JConverter

```dart
import 'package:test/test.dart';
import 'package:jcore/jcore.dart';

void main() {
  setUp(() {
    JBase.instance.clear();
    UserSchema.register();
  });

  test('User.fromMap converts correctly', () {
    final jsonc = JsonC(
      jv: 1737849600,
      jid: 5001,
      jnf: 3,
      schema: UserSchema.schema.schema,
      data: [[1, 'Alice', 'alice@example.com', true, 1737849600000]],
    );

    final users = JConverter.toMaps(jsonc)
        .map((map) => User.fromMap(map))
        .toList();

    expect(users, hasLength(1));
    expect(users[0].id, equals(1));
    expect(users[0].name, equals('Alice'));
    expect(users[0].email, equals('alice@example.com'));
    expect(users[0].isActive, isTrue);
  });

  test('User.toMap converts correctly', () {
    final user = User(
      id: 1,
      name: 'Alice',
      email: 'alice@example.com',
      isActive: true,
    );

    final map = user.toMap();

    expect(map['id'], equals(1));
    expect(map['name'], equals('Alice'));
    expect(map['email'], equals('alice@example.com'));
    expect(map['is_active'], isTrue);
  });

  test('round-trip conversion preserves data', () {
    final original = User(
      id: 1,
      name: 'Alice',
      email: 'alice@example.com',
      isActive: true,
    );

    // Convert to JSONC
    final jsonc = JConverter.fromMaps(
      [original.toMap()],
      5001,
      1737849600,
      jnf: 3,
    );

    // Merge with schema
    final full = JBase.instance.mergeWithSchema(jsonc);

    // Convert back to model
    final converted = JConverter.toMaps(full)
        .map((map) => User.fromMap(map))
        .first;

    expect(converted.id, equals(original.id));
    expect(converted.name, equals(original.name));
    expect(converted.email, equals(original.email));
    expect(converted.isActive, equals(original.isActive));
  });
}
```

## Code Generation Integration

### Using json_serializable

```dart
import 'package:json_annotation/json_annotation.dart';

part 'user.g.dart';

@JsonSerializable()
class User {
  final int id;
  final String name;
  @JsonKey(name: 'is_active')
  final bool isActive;

  const User({
    required this.id,
    required this.name,
    required this.isActive,
  });

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
  Map<String, dynamic> toJson() => _$UserToJson(this);
}

// Usage with JConverter
final users = JConverter.toMaps(jsonc)
    .map((map) => User.fromJson(map))
    .toList();
```

### Using freezed

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'user.freezed.dart';
part 'user.g.dart';

@freezed
class User with _$User {
  const factory User({
    required int id,
    required String name,
    @JsonKey(name: 'is_active') required bool isActive,
  }) = _User;

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
}

// Usage with JConverter
final users = JConverter.toMaps(jsonc)
    .map((map) => User.fromJson(map))
    .toList();
```

## Performance Considerations

### 1. Lazy Conversion

```dart
class LazyModelList<T> {
  final JsonC _jsonc;
  final T Function(Map<String, dynamic>) _fromMap;
  List<T>? _cache;

  LazyModelList(this._jsonc, this._fromMap);

  List<T> get models {
    _cache ??= JConverter.toMaps(_jsonc)
        .map(_fromMap)
        .toList();
    return _cache!;
  }
}
```

### 2. Streaming Large Datasets

```dart
Stream<T> streamModels<T>(
  JsonC jsonc,
  T Function(Map<String, dynamic>) fromMap,
) async* {
  final maps = JConverter.toMaps(jsonc);
  for (final map in maps) {
    yield fromMap(map);
  }
}

// Usage
await for (final user in streamModels(jsonc, User.fromMap)) {
  await processUser(user);
}
```

## Summary

JConverter provides:

✅ **Type-safe conversion** between JSONC and Dart models  
✅ **Flexible encoding** with 6 jnf modes for different use cases  
✅ **Validation** before conversion  
✅ **Schema caching** via JBase for efficiency  
✅ **Code generation** support (json_serializable, freezed)  
✅ **Batch and stream** processing  
✅ **Nullable and enum** support  
✅ **Financial precision** with proper string encoding

**Ready for production use in AIX Flutter applications!** 🚀
