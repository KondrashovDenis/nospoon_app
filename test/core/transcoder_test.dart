import 'package:flutter_test/flutter_test.dart';
import 'package:nospoon_app/core/transcoder.dart';

void main() {
  group('SpoonTranscoder', () {
    test('bfToSpoon одиночные команды', () {
      expect(SpoonTranscoder.bfToSpoonBits('+'), equals('1'));
      expect(SpoonTranscoder.bfToSpoonBits('-'), equals('000'));
      expect(SpoonTranscoder.bfToSpoonBits('>'), equals('010'));
      expect(SpoonTranscoder.bfToSpoonBits('<'), equals('0110'));
      expect(SpoonTranscoder.bfToSpoonBits('['), equals('00110'));
      expect(SpoonTranscoder.bfToSpoonBits(']'), equals('0111'));
      expect(SpoonTranscoder.bfToSpoonBits('.'), equals('001110'));
      expect(SpoonTranscoder.bfToSpoonBits(','), equals('0011110'));
    });

    test('roundtrip BF → Spoon → BF', () {
      const original = '+++++[>++++<-]>.';
      final bits = SpoonTranscoder.bfToSpoonBits(original);
      final restored = SpoonTranscoder.spoonBitsToBf(bits);
      expect(restored, equals(original));
    });

    test('roundtrip BF → .bin → BF', () {
      const original = '+++++[>++++<-]>.';
      final binary = SpoonTranscoder.encodeToBin(original);
      final restored = SpoonTranscoder.decodeFromBin(binary);
      expect(restored, equals(original));
    });
  });
}
