import 'package:flutter_test/flutter_test.dart';
import 'package:ipoedge_app/services/firebase_service.dart';
import 'package:ipoedge_app/models/ipo_model.dart';

// Mock Timestamp class for testing Firebase Timestamp behavior
class MockTimestamp {
  final DateTime _dateTime;

  MockTimestamp(this._dateTime);

  DateTime toDate() => _dateTime;
}

void main() {
  group('Bulk IPO Addition Tests', () {
    test('IpoOption should format display name correctly', () {
      // Test with category
      final optionWithCategory = IpoOption(
        companyId: 'test-company-1',
        companyName: 'Test Company Ltd',
        category: 'upcoming_open',
      );

      expect(optionWithCategory.displayName,
          'Test Company Ltd (test-company-1) - Upcoming');

      // Test without category
      final optionWithoutCategory = IpoOption(
        companyId: 'test-company-2',
        companyName: 'Another Company',
        category: null,
      );

      expect(optionWithoutCategory.displayName,
          'Another Company (test-company-2)');
    });

    test('IpoOption equality should work correctly', () {
      final option1 = IpoOption(
        companyId: 'same-id',
        companyName: 'Company A',
        category: 'draft_issues',
      );

      final option2 = IpoOption(
        companyId: 'same-id',
        companyName: 'Company B', // Different name
        category: 'upcoming_open', // Different category
      );

      final option3 = IpoOption(
        companyId: 'different-id',
        companyName: 'Company A',
        category: 'draft_issues',
      );

      // Should be equal if companyId is the same
      expect(option1, equals(option2));
      expect(option1.hashCode, equals(option2.hashCode));

      // Should not be equal if companyId is different
      expect(option1, isNot(equals(option3)));
    });

    test('IpoOption category formatting should handle all cases', () {
      final testCases = {
        'draft_issues': 'Draft',
        'upcoming_open': 'Upcoming',
        'listing_soon': 'Listing Soon',
        'recently_listed': 'Recently Listed',
        'gain_loss_analysis': 'Gain/Loss',
        'unknown_category': 'unknown_category',
      };

      testCases.forEach((category, expected) {
        final option = IpoOption(
          companyId: 'test-id',
          companyName: 'Test Company',
          category: category,
        );

        expect(option.displayName.contains(expected), isTrue,
            reason: 'Category $category should format to $expected');
      });
    });

    test('IpoModel should handle various JSON structures', () {
      // Test with company headers
      final jsonWithHeaders = {
        'company_headers': {
          'ipo_id': 'header-id',
          'company_name': 'Header Company',
          'company_short_name': 'HC Ltd',
        },
        'additional_field': 'test_value',
      };

      final ipoFromHeaders = IpoModel.fromJson(jsonWithHeaders);
      expect(ipoFromHeaders.companyId, 'header-id');
      expect(ipoFromHeaders.companyName, 'Header Company');

      // Test with direct fields
      final jsonDirect = {
        'companyId': 'direct-id',
        'company_name': 'Direct Company',
        'ipo_id': 'should-not-override',
      };

      final ipoFromDirect = IpoModel.fromJson(jsonDirect);
      expect(ipoFromDirect.companyId, 'direct-id');
      expect(ipoFromDirect.companyName, 'Direct Company');

      // Test with minimal data
      final jsonMinimal = {
        'company_slug_name': 'minimal-company',
      };

      final ipoFromMinimal = IpoModel.fromJson(jsonMinimal);
      expect(ipoFromMinimal.companyId, 'minimal-company');
      expect(ipoFromMinimal.companyName, isNull);
    });

    test('IpoModel toFirestore should exclude specified fields', () {
      final testData = {
        'companyId': 'test-company',
        'companyName': 'Test Company',
        'peerData': {'should': 'be_excluded'},
        'metadata': {'also': 'excluded'},
        'insight': 'excluded_insight',
        'research_reports': ['excluded', 'reports'],
        'post_page_link': 'excluded_link',
        'post_analysis': 'excluded_analysis',
        'valid_field': 'should_be_included',
      };

      final ipo = IpoModel.fromJson(testData);
      final firestoreData = ipo.toFirestore();

      // Should exclude specified fields
      expect(firestoreData.containsKey('peerData'), isFalse);
      expect(firestoreData.containsKey('metadata'), isFalse);
      expect(firestoreData.containsKey('insight'), isFalse);
      expect(firestoreData.containsKey('research_reports'), isFalse);
      expect(firestoreData.containsKey('post_page_link'), isFalse);
      expect(firestoreData.containsKey('post_analysis'), isFalse);

      // Should include valid fields
      expect(firestoreData['valid_field'], 'should_be_included');
      expect(firestoreData['companyId'], 'test-company');
      expect(firestoreData['companyName'], 'Test Company');

      // Should include Firebase metadata
      expect(firestoreData.containsKey('_firebaseCreatedAt'), isTrue);
      expect(firestoreData.containsKey('_firebaseUpdatedAt'), isTrue);
    });

    test('IpoModel displayName should handle various scenarios', () {
      // With company name
      final ipoWithName = IpoModel(
        companyId: 'test-id',
        companyName: 'Test Company Ltd',
      );
      expect(ipoWithName.displayName, 'Test Company Ltd');

      // Without company name but with ID
      final ipoWithoutName = IpoModel(
        companyId: 'test-id',
        companyName: null,
      );
      expect(ipoWithoutName.displayName, 'test-id');

      // With empty company name
      final ipoWithEmptyName = IpoModel(
        companyId: 'test-id',
        companyName: '',
      );
      expect(ipoWithEmptyName.displayName, 'test-id');

      // With empty ID (edge case)
      final ipoWithEmptyId = IpoModel(
        companyId: '',
        companyName: null,
      );
      expect(ipoWithEmptyId.displayName, 'Unknown Company');
    });

    test('IpoModel copyWith should work correctly', () {
      final originalIpo = IpoModel(
        id: 'original-id',
        companyId: 'original-company',
        companyName: 'Original Company',
        additionalData: {'original': 'data'},
        createdAt: DateTime(2023, 1, 1),
        updatedAt: DateTime(2023, 1, 2),
      );

      // Copy with some changes
      final copiedIpo = originalIpo.copyWith(
        companyName: 'Updated Company',
        updatedAt: DateTime(2023, 1, 3),
      );

      // Should keep original values for unchanged fields
      expect(copiedIpo.id, 'original-id');
      expect(copiedIpo.companyId, 'original-company');
      expect(copiedIpo.additionalData, {'original': 'data'});
      expect(copiedIpo.createdAt, DateTime(2023, 1, 1));

      // Should have updated values for changed fields
      expect(copiedIpo.companyName, 'Updated Company');
      expect(copiedIpo.updatedAt, DateTime(2023, 1, 3));
    });

    test('IpoModel fromFirestore should handle Firebase data correctly', () {
      // Create mock Timestamp objects that have toDate() method
      final mockCreatedTimestamp = MockTimestamp(DateTime(2023, 1, 1));
      final mockUpdatedTimestamp = MockTimestamp(DateTime(2023, 1, 2));

      final firestoreData = {
        'companyId': 'firebase-company',
        'companyName': 'Firebase Company',
        'valid_field': 'test_value',
        '_firebaseCreatedAt': mockCreatedTimestamp,
        '_firebaseUpdatedAt': mockUpdatedTimestamp,
      };

      final ipo = IpoModel.fromFirestore(firestoreData, 'doc-id');

      expect(ipo.id, 'doc-id');
      expect(ipo.companyId, 'firebase-company');
      expect(ipo.companyName, 'Firebase Company');
      expect(ipo.createdAt, DateTime(2023, 1, 1));
      expect(ipo.updatedAt, DateTime(2023, 1, 2));

      // Should not include Firebase metadata in additional data
      expect(ipo.additionalData?.containsKey('_firebaseCreatedAt'), isFalse);
      expect(ipo.additionalData?.containsKey('_firebaseUpdatedAt'), isFalse);
      expect(ipo.additionalData?['valid_field'], 'test_value');
    });
  });
}
