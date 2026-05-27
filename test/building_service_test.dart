import 'package:flutter_test/flutter_test.dart';
import 'package:study_city/models/building.dart';
import 'package:study_city/models/building_catalog.dart';
import 'package:study_city/services/building_service.dart';

void main() {
  group('BuildingService', () {
    final service = BuildingService();

    // ── Helpers ─────────────────────────────────────────────────────
    Building makeBuilding({
      int level = 1,
      int coinsToNextLevel = 100,
      int purchasePrice = 100,
    }) =>
        Building(
          id: 'b1',
          userId: 'u1',
          name: 'House',
          type: 'house',
          level: level,
          coinsToNextLevel: coinsToNextLevel,
          purchasePrice: purchasePrice,
          gridRow: 0,
          gridCol: 0,
        );

    BuildingDefinition makeDefinition({int price = 100}) => BuildingDefinition(
          type: 'house',
          name: 'House',
          purchasePrice: price,
          description: 'A house',
          tileRows: 1,
          tileCols: 1,
          heightRatio: 1.0,
        );

    // ── canPurchase ──────────────────────────────────────────────────
    group('canPurchase', () {
      test('returns true when user has exact coins needed', () {
        expect(service.canPurchase(makeDefinition(price: 200), 200), isTrue);
      });

      test('returns true when user has more than enough coins', () {
        expect(service.canPurchase(makeDefinition(price: 100), 999), isTrue);
      });

      test('returns false when user has 1 coin fewer than price', () {
        expect(service.canPurchase(makeDefinition(price: 300), 299), isFalse);
      });

      test('returns false with zero coins', () {
        expect(service.canPurchase(makeDefinition(price: 30), 0), isFalse);
      });
    });

    // ── canUpgrade ───────────────────────────────────────────────────
    group('canUpgrade', () {
      test('returns true when user has enough coins and level < 5', () {
        expect(service.canUpgrade(makeBuilding(level: 1, coinsToNextLevel: 100), 100), isTrue);
      });

      test('returns true when user has more than enough coins', () {
        expect(service.canUpgrade(makeBuilding(level: 2, coinsToNextLevel: 200), 9999), isTrue);
      });

      test('returns false when user has 1 coin fewer than needed', () {
        expect(service.canUpgrade(makeBuilding(level: 1, coinsToNextLevel: 100), 99), isFalse);
      });

      test('returns false at max level (5) regardless of coins', () {
        expect(service.canUpgrade(makeBuilding(level: 5, coinsToNextLevel: 500), 9999), isFalse);
      });

      test('returns true at level 4 (one below max)', () {
        expect(service.canUpgrade(makeBuilding(level: 4, coinsToNextLevel: 400), 400), isTrue);
      });
    });

    // ── upgrade ──────────────────────────────────────────────────────
    group('upgrade', () {
      test('increments level by 1', () {
        final upgraded = service.upgrade(makeBuilding(level: 1, purchasePrice: 100));
        expect(upgraded.level, equals(2));
      });

      test('next cost = purchasePrice × newLevel (100-coin building)', () {
        // L1→L2: next cost = 100 × 2 = 200
        final l2 = service.upgrade(makeBuilding(level: 1, purchasePrice: 100));
        expect(l2.coinsToNextLevel, equals(200));
        // L2→L3: next cost = 100 × 3 = 300
        final l3 = service.upgrade(makeBuilding(level: 2, purchasePrice: 100));
        expect(l3.coinsToNextLevel, equals(300));
        // L3→L4: next cost = 100 × 4 = 400
        final l4 = service.upgrade(makeBuilding(level: 3, purchasePrice: 100));
        expect(l4.coinsToNextLevel, equals(400));
        // L4→L5: next cost = 100 × 5 = 500
        final l5 = service.upgrade(makeBuilding(level: 4, purchasePrice: 100));
        expect(l5.coinsToNextLevel, equals(500));
      });

      test('expensive building (500 coins) has proportionally higher costs', () {
        final upgraded = service.upgrade(makeBuilding(level: 1, purchasePrice: 500));
        expect(upgraded.coinsToNextLevel, equals(1000)); // 500 × 2
      });

      test('cheap building (30 coins) has proportionally lower costs', () {
        final upgraded = service.upgrade(makeBuilding(level: 1, purchasePrice: 30));
        expect(upgraded.coinsToNextLevel, equals(60)); // 30 × 2
      });

      test('upgrade cost scales proportionally with purchase price', () {
        final cheapUpgraded = service.upgrade(makeBuilding(level: 1, purchasePrice: 50));
        final expensiveUpgraded = service.upgrade(makeBuilding(level: 1, purchasePrice: 500));
        // Expensive building should cost exactly 10x more
        expect(expensiveUpgraded.coinsToNextLevel, equals(cheapUpgraded.coinsToNextLevel * 10));
      });

      test('legacy building (purchasePrice=0) falls back to old formula', () {
        final upgraded = service.upgrade(makeBuilding(level: 1, purchasePrice: 0));
        expect(upgraded.coinsToNextLevel, equals(2 * 100 + 200)); // 400 fallback
      });

      test('preserves all other building fields after upgrade', () {
        final original = makeBuilding(level: 2, purchasePrice: 100);
        final upgraded = service.upgrade(original);
        expect(upgraded.id, equals(original.id));
        expect(upgraded.userId, equals(original.userId));
        expect(upgraded.type, equals(original.type));
        expect(upgraded.purchasePrice, equals(original.purchasePrice));
        expect(upgraded.gridRow, equals(original.gridRow));
        expect(upgraded.gridCol, equals(original.gridCol));
      });

      test('full 1→5 upgrade sequence for 100-coin building', () {
        var building = makeBuilding(level: 1, purchasePrice: 100);
        // coinsToNextLevel after each upgrade = price × newLevel
        final expected = [200, 300, 400, 500]; // levels 2,3,4,5
        for (final cost in expected) {
          building = service.upgrade(building);
          expect(building.coinsToNextLevel, equals(cost));
        }
        expect(building.level, equals(5));
      });
    });

    // ── createFromDefinition ─────────────────────────────────────────
    group('createFromDefinition', () {
      test('creates a level-1 building with coinsToNextLevel = purchasePrice', () {
        final def = makeDefinition(price: 250);
        final b = service.createFromDefinition(def, 'u1', 3, 5, 'new_id');
        expect(b.level, equals(1));
        expect(b.coinsToNextLevel, equals(250)); // price × 1
        expect(b.purchasePrice, equals(250));
      });

      test('places building at the specified grid position', () {
        final def = makeDefinition();
        final b = service.createFromDefinition(def, 'u1', 7, 2, 'id');
        expect(b.gridRow, equals(7));
        expect(b.gridCol, equals(2));
        expect(b.isPlaced, isTrue);
      });

      test('copies type and name from definition', () {
        final def = BuildingDefinition(
          type: 'college',
          name: 'College',
          purchasePrice: 250,
          description: 'A college',
        );
        final b = service.createFromDefinition(def, 'u1', 0, 0, 'id');
        expect(b.type, equals('college'));
        expect(b.name, equals('College'));
      });
    });
  });

  // ── BuildingDefinition ─────────────────────────────────────────────
  group('BuildingDefinition', () {
    test('footprintFactor is (tileRows + tileCols) / 2', () {
      const d1x1 = BuildingDefinition(type: 't', name: 'T', purchasePrice: 0, description: '', tileRows: 1, tileCols: 1);
      const d1x2 = BuildingDefinition(type: 't', name: 'T', purchasePrice: 0, description: '', tileRows: 1, tileCols: 2);
      const d2x2 = BuildingDefinition(type: 't', name: 'T', purchasePrice: 0, description: '', tileRows: 2, tileCols: 2);
      expect(d1x1.footprintFactor, equals(1.0));
      expect(d1x2.footprintFactor, equals(1.5));
      expect(d2x2.footprintFactor, equals(2.0));
    });

    test('totalTiles is tileRows * tileCols', () {
      const d1x2 = BuildingDefinition(type: 't', name: 'T', purchasePrice: 0, description: '', tileRows: 1, tileCols: 2);
      const d2x2 = BuildingDefinition(type: 't', name: 'T', purchasePrice: 0, description: '', tileRows: 2, tileCols: 2);
      expect(d1x2.totalTiles, equals(2));
      expect(d2x2.totalTiles, equals(4));
    });

    test('sizeLabel formats as "rowsxcols"', () {
      const d = BuildingDefinition(type: 't', name: 'T', purchasePrice: 0, description: '', tileRows: 1, tileCols: 2);
      expect(d.sizeLabel, equals('1×2'));
    });

    test('imagePath returns correct asset path', () {
      const d = BuildingDefinition(type: 'college', name: 'College', purchasePrice: 0, description: '');
      expect(d.imagePath, equals('assets/buildings/college.png'));
    });
  });
}
