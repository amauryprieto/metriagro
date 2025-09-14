import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'package:metriagro/features/auth/domain/entities/user.dart';
import 'package:metriagro/features/auth/domain/repositories/auth_repository.dart';
import 'package:metriagro/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:metriagro/features/auth/presentation/pages/login_page.dart';

import 'login_page_test.mocks.dart';

@GenerateMocks([AuthRepository])
void main() {
  late MockAuthRepository mockAuthRepository;
  late AuthBloc authBloc;

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    authBloc = AuthBloc(authRepository: mockAuthRepository);
  });

  tearDown(() {
    authBloc.close();
  });

  Widget createTestWidget() {
    return MaterialApp(
      home: BlocProvider<AuthBloc>(create: (context) => authBloc, child: const LoginPage()),
    );
  }

  group('LoginPage', () {
    testWidgets('should display login form', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.text('Metriagro'), findsOneWidget);
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Contraseña'), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);
    });

    testWidgets('should show validation errors for empty fields', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      expect(find.text('Por favor ingresa tu email'), findsOneWidget);
      expect(find.text('Por favor ingresa tu contraseña'), findsOneWidget);
    });

    testWidgets('should show validation error for invalid email', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      await tester.enterText(find.byType(TextFormField).first, 'invalid-email');
      await tester.enterText(find.byType(TextFormField).last, 'password');
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      expect(find.text('Por favor ingresa un email válido'), findsOneWidget);
    });

    testWidgets('should show validation error for short password', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      await tester.enterText(find.byType(TextFormField).first, 'test@example.com');
      await tester.enterText(find.byType(TextFormField).last, '123');
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      expect(find.text('La contraseña debe tener al menos 6 caracteres'), findsOneWidget);
    });

    testWidgets('should toggle password visibility', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      final toggleButton = find.byIcon(Icons.visibility);

      expect(toggleButton, findsOneWidget);

      await tester.tap(toggleButton);
      await tester.pump();

      expect(find.byIcon(Icons.visibility_off), findsOneWidget);
    });

    testWidgets('should show loading indicator when signing in', (WidgetTester tester) async {
      when(
        mockAuthRepository.signInWithEmailAndPassword(any, any),
      ).thenAnswer((_) async => const User(id: '1', email: 'test@example.com'));

      await tester.pumpWidget(createTestWidget());

      await tester.enterText(find.byType(TextFormField).first, 'test@example.com');
      await tester.enterText(find.byType(TextFormField).last, 'password');
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });
}
