import 'package:flutter_test/flutter_test.dart';
import 'package:study_city/models/building.dart';

void main() {
  group('Building model', () {
    // ── Helper ───────────────────────────────────────────────────────
    Building makeBuilding({int? gridRow, int? gridCol, int level = 1}) =>
        Building(
          id: 'b1',
          userId: 'u1',
          name: 'House',
          type: 'house',
          level: level,
          gridRow: gridRow,
          gridCol: gridCol,
        );

    // ── isPlaced ─────────────────────────────────────────────────────
    group('isPlaced', () {
      test('returns true when both gridRow and gridCol are set', () {
        expect(makeBuilding(gridRow: 3, gridCol: 5).isPlaced, isTrue);
      });

      test('returns true at grid position (0, 0)', () {
        expect(makeBuilding(gridRow: 0, gridCol: 0).isPlaced, isTrue);
      });

      test('returns false when gridRow is null', () {
        expect(makeBuilding(gridRow: null, gridCol: 2).isPlaced, isFalse);
      });

      test('returns false when gridCol is null', () {
        expect(makeBuilding(gridRow: 2, gridCol: null).isPlaced, isFalse);
      });

      test('returns false when both are null (building is in stock)', () {
        expect(makeBuilding(gridRow: null, gridCol: null).isPlaced, isFalse);
      });
    });

    // ── imagePath ────────────────────────────────────────────────────
    group('imagePath', () {
      test('returns correct asset path for building type', () {
        expect(makeBuilding().imagePath, equals('assets/buildings/house.png'));
      });

      test('reflects the actual type field', () {
        const b = Building(id: 'x', userId: 'u', name: 'Tower', type: 'clock_tower');
        expect(b.imagePath, equals('assets/buildings/clock_tower.png'));
      });

      test('different types produce different paths', () {
        const b1 = Building(id: '1', userId: 'u', name: 'A', type: 'bank');
        const b2 = Building(id: '2', userId: 'u', name: 'B', type: 'park');
        expect(b1.imagePath, isNot(equals(b2.imagePath)));
      });
    });

    // ── copyWith ─────────────────────────────────────────────────────
    group('copyWith', () {
      test('clearGrid=true sets gridRow and gridCol to null', () {
        final b = makeBuilding(gridRow: 5, gridCol: 3);
        final cleared = b.copyWith(clearGrid: true);
        expect(cleared.gridRow, isNull);
        expect(cleared.gridCol, isNull);
        expect(cleared.isPlaced, isFalse);
      });

      test('can move building to a new grid position', () {
        final b = makeBuilding(gridRow: 0, gridCol: 0);
        final moved = b.copyWith(gridRow: 7, gridCol: 8);
        expect(moved.gridRow, equals(7));
        expect(moved.gridCol, equals(8));
      });

      test('preserves unchanged fields after copyWith', () {
        const b = Building(id: 'id1', userId: 'u1', name: 'Inn', type: 'inn', level: 3);
        final updated = b.copyWith(gridRow: 1, gridCol: 1);
        expect(updated.id, equals('id1'));
        expect(updated.userId, equals('u1'));
        expect(updated.level, equals(3));
        expect(updated.type, equals('inn'));
      });

      test('can upgrade level via copyWith', () {
        final b = makeBuilding(level: 2);
        final upgraded = b.copyWith(level: 3, coinsToNextLevel: 600);
        expect(upgraded.level, equals(3));
        expect(upgraded.coinsToNextLevel, equals(600));
      });
    });

    // ── default values ───────────────────────────────────────────────
    group('default values', () {
      test('new building defaults to level 1', () {
        const b = Building(id: 'x', userId: 'u', name: 'A', type: 'a');
        expect(b.level, equals(1));
      });

      test('new building is not placed by default (in stock)', () {
        const b = Building(id: 'x', userId: 'u', name: 'A', type: 'a');
        expect(b.isPlaced, isFalse);
      });

      test('default coinsToNextLevel is 100', () {
        const b = Building(id: 'x', userId: 'u', name: 'A', type: 'a');
        expect(b.coinsToNextLevel, equals(100));
      });
    });
  });
}
