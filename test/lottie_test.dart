import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:lottie/lottie.dart';

void main() {
  test('Lottie parses JSON successfully', () async {
    final file = File('assets/images/pembayaran_berhasil.json');
    final jsonString = await file.readAsString();
    expect(jsonString.isNotEmpty, isTrue);

    // Attempt parsing
    final composition = await LottieComposition.fromBytes(
      await file.readAsBytes(),
    );
    expect(composition, isNotNull);
  });
}
