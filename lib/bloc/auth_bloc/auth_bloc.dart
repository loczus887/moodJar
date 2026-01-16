// lib/logic/auth_bloc/auth_bloc.dart
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../data/repositories/auth_repository.dart';

part 'auth_event.dart';

part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository authRepository;

  AuthBloc({required this.authRepository}) : super(AuthInitial()) {
    // Check Auth Status on Start
    on<AuthCheckRequested>((event, emit) async {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        emit(Authenticated(user));
      } else {
        emit(Unauthenticated());
      }

      await emit.forEach(
        authRepository.user,
        onData: (User? user) {
          if (user != null) return Authenticated(user);
          return Unauthenticated();
        },
      );
    });

    // Login requested
    on<AuthLoginRequested>((event, emit) async {
      emit(AuthLoading());
      try {
        await authRepository.signIn(
          email: event.email,
          password: event.password,
        );
      } catch (e) {
        emit(AuthError(e.toString()));
        emit(Unauthenticated());
      }
    });

    // Sign Up
    on<AuthSignUpRequested>((event, emit) async {
      emit(AuthLoading());
      try {
        await authRepository.signUp(
          email: event.email,
          password: event.password,
        );
      } catch (e) {
        emit(AuthError(e.toString()));
        emit(Unauthenticated());
      }
    });

    // Google Sign In
    on<AuthGoogleSignInRequested>((event, emit) async {
      emit(AuthLoading());
      try {
        await authRepository.signInWithGoogle();
      } catch (e) {
        emit(AuthError(e.toString()));
        emit(Unauthenticated());
      }
    });

    // Logout
    on<AuthLogoutRequested>((event, emit) async {
      emit(AuthLoading());
      await authRepository.signOut();
      emit(Unauthenticated());
    });
  }
}
