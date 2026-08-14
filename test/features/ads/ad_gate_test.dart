import 'package:flutter_test/flutter_test.dart';
import 'package:poney_au_chaud/features/ads/ad_gate.dart';

void main() {
  group('AdGate.shouldAttempt', () {
    test('refuse pendant le cooldown même si le tirage passe', () {
      expect(
        AdGate.shouldAttempt(
          nowMs: 60 * 1000,
          lastMs: 0,
          roll: 0,
          placement: AdPlacement.feedback,
        ),
        isFalse,
      );
    });

    test(
      'accepte après 8 min si le tirage est sous le seuil feedback (35 %)',
      () {
        const afterCooldown = 8 * 60 * 1000;
        expect(
          AdGate.shouldAttempt(
            nowMs: afterCooldown,
            lastMs: 0,
            roll: 34,
            placement: AdPlacement.feedback,
          ),
          isTrue,
        );
        expect(
          AdGate.shouldAttempt(
            nowMs: afterCooldown,
            lastMs: 0,
            roll: 35,
            placement: AdPlacement.feedback,
          ),
          isFalse,
        );
      },
    );

    test('seuil timeline plus bas (20 %)', () {
      const afterCooldown = 8 * 60 * 1000;
      expect(
        AdGate.shouldAttempt(
          nowMs: afterCooldown,
          lastMs: 0,
          roll: 19,
          placement: AdPlacement.timeline,
        ),
        isTrue,
      );
      expect(
        AdGate.shouldAttempt(
          nowMs: afterCooldown,
          lastMs: 0,
          roll: 20,
          placement: AdPlacement.timeline,
        ),
        isFalse,
      );
    });
  });
}
