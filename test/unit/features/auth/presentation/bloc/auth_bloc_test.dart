import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'package:metriagro/features/auth/domain/entities/user.dart';
import 'package:metriagro/features/auth/domain/repositories/auth_repository.dart';
import 'package:metriagro/features/auth/presentation/bloc/auth_bloc.dart';

import 'auth_bloc_test.mocks.dart';

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

  group('AuthBloc', () {
    const testUser = User(id: '1', email: 'test@example.com', name: 'Test User');

    test('initial state should be AuthInitial', () {
      expect(authBloc.state, equals(AuthInitial()));
    });

    group('AuthCheckRequested', () {
      blocTest<AuthBloc, AuthState>(
        'emits [AuthLoading, AuthAuthenticated] when user is authenticated',
        build: () {
          when(mockAuthRepository.getCurrentUser()).thenAnswer((_) async => testUser);
          return authBloc;
        },
        act: (bloc) => bloc.add(AuthCheckRequested()),
        expect: () => [AuthLoading(), AuthAuthenticated(user: testUser)],
      );

      blocTest<AuthBloc, AuthState>(
        'emits [AuthLoading, AuthUnauthenticated] when user is not authenticated',
        build: () {
          when(mockAuthRepository.getCurrentUser()).thenAnswer((_) async => null);
          return authBloc;
        },
        act: (bloc) => bloc.add(AuthCheckRequested()),
        expect: () => [AuthLoading(), AuthUnauthenticated()],
      );

      blocTest<AuthBloc, AuthState>(
        'emits [AuthLoading, AuthError] when repository throws exception',
        build: () {
          when(mockAuthRepository.getCurrentUser()).thenThrow(Exception('Test error'));
          return authBloc;
        },
        act: (bloc) => bloc.add(AuthCheckRequested()),
        expect: () => [AuthLoading(), AuthError(message: 'Exception: Test error')],
      );
    });

    group('AuthSignInRequested', () {
      blocTest<AuthBloc, AuthState>(
        'emits [AuthLoading, AuthAuthenticated] when sign in is successful',
        build: () {
          when(mockAuthRepository.signInWithEmailAndPassword(any, any)).thenAnswer((_) async => testUser);
          return authBloc;
        },
        act: (bloc) => bloc.add(AuthSignInRequested(email: 'test@example.com', password: 'password')),
        expect: () => [AuthLoading(), AuthAuthenticated(user: testUser)],
      );
    });

    group('AuthSignOutRequested', () {
      blocTest<AuthBloc, AuthState>(
        'emits [AuthLoading, AuthUnauthenticated] when sign out is successful',
        build: () {
          when(mockAuthRepository.signOut()).thenAnswer((_) async {});
          return authBloc;
        },
        act: (bloc) => bloc.add(AuthSignOutRequested()),
        expect: () => [AuthLoading(), AuthUnauthenticated()],
      );
    });
  });
}
