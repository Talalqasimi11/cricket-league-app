import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/widgets/shared/app_header.dart';
import 'package:frontend/widgets/custom_button.dart';
import 'package:frontend/widgets/shared/form_fields.dart';
import 'package:frontend/widgets/shared/status_widgets.dart';

void main() {
  group('AppHeader Tests', () {
    testWidgets('renders with title', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(appBar: AppHeader(title: 'Test Title')),
        ),
      );

      expect(find.text('Test Title'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    });

    testWidgets('back button calls onBackPressed', (WidgetTester tester) async {
      bool pressed = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: AppHeader(
              title: 'Test',
              onBackPressed: () => pressed = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.arrow_back));
      expect(pressed, true);
    });
  });

  group('Button Tests', () {
    testWidgets('PrimaryButton renders correctly', (WidgetTester tester) async {
      bool pressed = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PrimaryButton(
              text: 'Test Button',
              onPressed: () => pressed = true,
            ),
          ),
        ),
      );

      expect(find.text('Test Button'), findsOneWidget);
      await tester.tap(find.byType(ElevatedButton));
      expect(pressed, true);
    });

    testWidgets('SecondaryButton renders correctly', (
      WidgetTester tester,
    ) async {
      bool pressed = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SecondaryButton(
              text: 'Test Button',
              onPressed: () => pressed = true,
            ),
          ),
        ),
      );

      expect(find.text('Test Button'), findsOneWidget);
      await tester.tap(find.byType(OutlinedButton));
      expect(pressed, true);
    });

    testWidgets('buttons show loading state', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                PrimaryButton(text: 'Test', onPressed: () {}, isLoading: true),
                SecondaryButton(
                  text: 'Test',
                  onPressed: () {},
                  isLoading: true,
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsNWidgets(2));
      expect(find.text('Test'), findsNothing);
    });
  });

  group('Form Field Tests', () {
    testWidgets('AppTextField renders correctly', (WidgetTester tester) async {
      final controller = TextEditingController();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppTextField(label: 'Test Field', controller: controller),
          ),
        ),
      );

      expect(find.text('Test Field'), findsOneWidget);
      await tester.enterText(find.byType(TextFormField), 'test input');
      expect(controller.text, 'test input');
    });

    testWidgets('AppDropdownField renders correctly', (
      WidgetTester tester,
    ) async {
      String? selectedValue;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppDropdownField<String>(
              label: 'Test Dropdown',
              value: selectedValue,
              items: const [
                DropdownMenuItem(value: 'item1', child: Text('Item 1')),
                DropdownMenuItem(value: 'item2', child: Text('Item 2')),
              ],
              onChanged: (value) => selectedValue = value,
            ),
          ),
        ),
      );

      expect(find.text('Test Dropdown'), findsOneWidget);
    });
  });

  group('Status Widget Tests', () {
    testWidgets('AppLoadingIndicator renders correctly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: AppLoadingIndicator(message: 'Loading...')),
        ),
      );

      expect(find.text('Loading...'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('AppErrorWidget renders correctly', (
      WidgetTester tester,
    ) async {
      bool retryPressed = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppErrorWidget(
              message: 'Error occurred',
              onRetry: () => retryPressed = true,
            ),
          ),
        ),
      );

      expect(find.text('Error occurred'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      await tester.tap(find.text('Retry'));
      expect(retryPressed, true);
    });

    testWidgets('AppEmptyState renders correctly', (WidgetTester tester) async {
      bool actionPressed = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppEmptyState(
              message: 'No items found',
              actionLabel: 'Add Item',
              onAction: () => actionPressed = true,
            ),
          ),
        ),
      );

      expect(find.text('No items found'), findsOneWidget);
      expect(find.text('Add Item'), findsOneWidget);
      await tester.tap(find.text('Add Item'));
      expect(actionPressed, true);
    });
  });
}
