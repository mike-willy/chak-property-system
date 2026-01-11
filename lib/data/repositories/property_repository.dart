// data/repositories/property_repository.dart
import 'package:dartz/dartz.dart';
import '../models/failure_model.dart';
import '../models/property_model.dart';
import '../datasources/remote_datasource.dart';

class PropertyRepository {
  final RemoteDataSource _remoteDataSource;

  PropertyRepository(this._remoteDataSource);

  Future<Either<FailureModel, List<PropertyModel>>> getProperties({
    String? statusFilter,
    String? searchTerm,
    String? ownerId,
  }) async {
    try {
      final properties = await _remoteDataSource.getProperties(
        statusFilter: statusFilter,
        searchTerm: searchTerm,
        ownerId: ownerId,
      );
      return Right(properties);
    } catch (e) {
      return Left(FailureModel(message: 'Failed to fetch properties: $e'));
    }
  }

  Future<Either<FailureModel, PropertyModel>> getPropertyById(String id) async {
    try {
      final property = await _remoteDataSource.getPropertyById(id);
      return Right(property);
    } catch (e) {
      return Left(FailureModel(message: 'Failed to fetch property: $e'));
    }
  }

  Future<Either<FailureModel, String>> addProperty(PropertyModel property) async {
    try {
      final propertyId = await _remoteDataSource.addProperty(property);
      return Right(propertyId);
    } catch (e) {
      return Left(FailureModel(message: 'Failed to add property: $e'));
    }
  }

  Future<Either<FailureModel, void>> updateProperty(PropertyModel property) async {
    try {
      await _remoteDataSource.updateProperty(property);
      return const Right(null);
    } catch (e) {
      return Left(FailureModel(message: 'Failed to update property: $e'));
    }
  }

  Future<Either<FailureModel, void>> deleteProperty(String propertyId) async {
    try {
      await _remoteDataSource.deleteProperty(propertyId);
      return const Right(null);
    } catch (e) {
      return Left(FailureModel(message: 'Failed to delete property: $e'));
    }
  }

  Future<Either<FailureModel, void>> updatePropertyStatus(
    String propertyId,
    PropertyStatus status,
  ) async {
    try {
      await _remoteDataSource.updatePropertyStatus(propertyId, status);
      return const Right(null);
    } catch (e) {
      return Left(FailureModel(message: 'Failed to update property status: $e'));
    }
  }

  Future<Either<FailureModel, Map<String, dynamic>>> getPropertiesStats() async {
    try {
      final stats = await _remoteDataSource.getPropertiesStats();
      return Right(stats);
    } catch (e) {
      return Left(FailureModel(message: 'Failed to fetch properties stats: $e'));
    }
  }
}