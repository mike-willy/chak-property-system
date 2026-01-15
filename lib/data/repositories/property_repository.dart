// data/repositories/property_repository.dart
import 'package:dartz/dartz.dart';

import '../datasources/remote_datasource.dart';
import '../models/failure_model.dart';
import '../models/property_model.dart';
import '../models/unit_model.dart';

class PropertyRepository {
  final RemoteDataSource _remoteDataSource;

  PropertyRepository(this._remoteDataSource);

  /// Fetch all properties (optionally scoped to an owner)
  /// ⚠️ NO status filtering here — handled in Provider
  Future<Either<FailureModel, List<PropertyModel>>> getProperties({
    String? ownerId,
    String? statusFilter,
  }) async {
    try {
      final properties = await _remoteDataSource.getProperties(
        ownerId: ownerId,
      );
      // Add logic to filter by statusFilter if provided
      return Right(properties);
    } catch (e) {
      return Left(
        FailureModel(message: 'Failed to fetch properties: $e'),
      );
    }
  }

  /// Fetch single property
  Future<Either<FailureModel, PropertyModel>> getPropertyById(String id) async {
    try {
      final property = await _remoteDataSource.getPropertyById(id);
      return Right(property);
    } catch (e) {
      return Left(
        FailureModel(message: 'Failed to fetch property: $e'),
      );
    }
  }

  /// Fetch property units from subcollection
  Future<Either<FailureModel, List<Map<String, dynamic>>>> getPropertyUnits(
    String propertyId,
  ) async {
    try {
      final units = await _remoteDataSource.getPropertyUnits(propertyId);
      return Right(units);
    } catch (e) {
      return Left(
        FailureModel(message: 'Failed to fetch property units: $e'),
      );
    }
  }

  /// Fetch single property unit
  Future<Either<FailureModel, UnitModel>> getPropertyUnit(
    String propertyId,
    String unitId,
  ) async {
    try {
      final unitData = await _remoteDataSource.getPropertyUnit(propertyId, unitId);
      return Right(UnitModel.fromMap(unitData['id'], unitData));
    } catch (e) {
      return Left(
        FailureModel(message: 'Failed to fetch property unit: $e'),
      );
    }
  }

  /// Add property
  Future<Either<FailureModel, String>> addProperty(
    PropertyModel property,
  ) async {
    try {
      final propertyId = await _remoteDataSource.addProperty(property);
      return Right(propertyId);
    } catch (e) {
      return Left(
        FailureModel(message: 'Failed to add property: $e'),
      );
    }
  }

  /// Update property
  Future<Either<FailureModel, void>> updateProperty(
    PropertyModel property,
  ) async {
    try {
      await _remoteDataSource.updateProperty(property);
      return const Right(null);
    } catch (e) {
      return Left(
        FailureModel(message: 'Failed to update property: $e'),
      );
    }
  }

  /// Delete property
  Future<Either<FailureModel, void>> deleteProperty(
    String propertyId,
  ) async {
    try {
      await _remoteDataSource.deleteProperty(propertyId);
      return const Right(null);
    } catch (e) {
      return Left(
        FailureModel(message: 'Failed to delete property: $e'),
      );
    }
  }

  /// Update property status (occupied / vacant)
  Future<Either<FailureModel, void>> updatePropertyStatus(
    String propertyId,
    PropertyStatus status,
  ) async {
    try {
      await _remoteDataSource.updatePropertyStatus(propertyId, status);
      return const Right(null);
    } catch (e) {
      return Left(
        FailureModel(message: 'Failed to update property status: $e'),
      );
    }
  }

  /// Stats (admin / landlord dashboards)
  Future<Either<FailureModel, Map<String, dynamic>>> getPropertiesStats() async {
    try {
      final stats = await _remoteDataSource.getPropertiesStats();
      return Right(stats);
    } catch (e) {
      return Left(
        FailureModel(message: 'Failed to fetch properties stats: $e'),
      );
    }
  }
}
