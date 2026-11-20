import 'package:jcore/data.dart';
import 'package:jcore/jdata.dart';
import 'package:test/test.dart';

void main() {
  test('data entry point exports the data registry', () {
    expect(DataTypeRegistry.isValid(DataTypeRegistry.encodeNumeric(
      precision: 10,
      scale: 2,
    )),
        isTrue);
  });

  test('jdata compatibility entry point exports the data API', () {
    expect(DataType.fromName('INT16'), DataType.smallint);
  });
}
