// data/repositories/auth_repository.dart
import 'package:dartz/dartz.dart';
import '../models/failure_model.dart';
import '../models/user_model.dart';
import '../datasources/remote_datasource.dart';

class AuthRepository {
  final RemoteDataSource _remoteDataSource;

  AuthRepository(this._remoteDataSource);

  Future<Either<FailureModel, UserModel>> getUserProfile(String userId, {UserRole? role}) async {
    try {
      if (role == UserRole.landlord) {
        // Strict: Only check landlords collection
        final landlord = await _remoteDataSource.getLandlordProfile(userId);
        return Right(landlord);
      } else if (role == UserRole.tenant) {
        // Strict: Only check users collection (or tenants if moved there, but keeping users for now)
        final user = await _remoteDataSource.getUserProfile(userId);
        return Right(user);
      } else {
        // Unknown role (e.g. auto–login):
        // Prioritize Landlords collection to satisfy "use landlords collection" request
        try {
          final landlord = await _remoteDataSource.getLandlordProfile(userId);
          return Right(landlord);
        } catch (_) {
          // Fallback to users collection
          final user = await _remoteDataSource.getUserProfile(userId);
          return Right(user);
        }
      }
    } catch (e) {
      return Left(FailureModel(message: 'User profile not found: $e'));
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

  Future<Either<FailureModel, bool>> checkTenantExists(String userId) async {
    try {
      final exists = await _remoteDataSource.checkTenantExists(userId);
      return Right(exists);
    } catch (e) {
      return Left(FailureModel(message: 'Failed to check tenant existence: $e'));
    }
  }

  Future<Either<FailureModel, bool>> checkLandlordExists(String userId) async {
    try {
      final exists = await _remoteDataSource.checkLandlordExists(userId);
      return Right(exists);
    } catch (e) {
      return Left(FailureModel(message: 'Failed to check landlord existence: $e'));
    }
  }
}
