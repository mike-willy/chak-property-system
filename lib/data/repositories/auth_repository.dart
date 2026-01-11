// data/repositories/auth_repository.dart
import 'package:dartz/dartz.dart';
import '../models/failure_model.dart';
import '../models/user_model.dart';
import '../datasources/remote_datasource.dart';

class AuthRepository {
  final RemoteDataSource _remoteDataSource;

  AuthRepository(this._remoteDataSource);

  Future<Either<FailureModel, UserModel>> getUserProfile(String userId) async {
    try {
      final userProfile = await _remoteDataSource.getUserProfile(userId);
      return Right(userProfile);
    } catch (e) {
      return Left(FailureModel(message: 'Failed to fetch user profile: $e'));
    }
  }

  Future<Either<FailureModel, void>> createUserProfile(UserModel user) async {
    try {
      await _remoteDataSource.createUserProfile(user);
      return const Right(null);
    } catch (e) {
      return Left(FailureModel(message: 'Failed to create user profile: $e'));
    }
  }

  Future<Either<FailureModel, void>> updateUserProfile(UserModel user) async {
    try {
      await _remoteDataSource.updateUserProfile(user);
      return const Right(null);
    } catch (e) {
      return Left(FailureModel(message: 'Failed to update user profile: $e'));
    }
  }
}
