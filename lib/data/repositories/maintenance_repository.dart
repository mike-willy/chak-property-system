// data/repositories/maintenance_repository.dart
import 'package:dartz/dartz.dart';
import '../datasources/remote_datasource.dart';
import '../models/failure_model.dart';
import '../models/maintenance_model.dart';
import '../models/maintenance_category_model.dart'; // Added import

class MaintenanceRepository {
  final RemoteDataSource _remoteDataSource;

  MaintenanceRepository(this._remoteDataSource);

  /// Fetch maintenance categories
  Future<Either<FailureModel, List<MaintenanceCategoryModel>>> getMaintenanceCategories() async {
    try {
      final categories = await _remoteDataSource.getMaintenanceCategories();
      return Right(categories);
    } catch (e) {
      return Left(
        FailureModel(message: 'Failed to fetch categories: $e'),
      );
    }
  }

  /// Fetch maintenance requests
  Future<Either<FailureModel, List<MaintenanceModel>>> getMaintenanceRequests({
    String? tenantId,
    String? propertyId,
    String? statusFilter,
  }) async {
    try {
      final requests = await _remoteDataSource.getMaintenanceRequests(
        tenantId: tenantId,
        propertyId: propertyId,
        statusFilter: statusFilter,
      );
      return Right(requests);
    } catch (e) {
      return Left(
        FailureModel(message: 'Failed to fetch maintenance requests: $e'),
      );
    }
  }

  /// Fetch maintenance requests stream
  Stream<List<MaintenanceModel>> getMaintenanceRequestsStream({
    String? tenantId,
    String? propertyId,
    String? statusFilter,
  }) {
    return _remoteDataSource.getMaintenanceRequestsStream(
      tenantId: tenantId,
      statusFilter: statusFilter,
    );
  }

  /// Fetch single maintenance request
  Future<Either<FailureModel, MaintenanceModel>> getMaintenanceRequestById(String id) async {
    try {
      final request = await _remoteDataSource.getMaintenanceRequestById(id);
      return Right(request);
    } catch (e) {
      return Left(
        FailureModel(message: 'Failed to fetch maintenance request: $e'),
      );
    }
  }

  /// Create maintenance request
  Future<Either<FailureModel, String>> createMaintenanceRequest(
    MaintenanceModel request,
  ) async {
    try {
      final requestId = await _remoteDataSource.createMaintenanceRequest(request);
      return Right(requestId);
    } catch (e) {
      return Left(
        FailureModel(message: 'Failed to create maintenance request: $e'),
      );
    }
  }

  /// Update maintenance request
  Future<Either<FailureModel, void>> updateMaintenanceRequest(
    MaintenanceModel request,
  ) async {
    try {
      await _remoteDataSource.updateMaintenanceRequest(request);
      return const Right(null);
    } catch (e) {
      return Left(
        FailureModel(message: 'Failed to update maintenance request: $e'),
      );
    }
  }

  /// Update maintenance status
  Future<Either<FailureModel, void>> updateMaintenanceStatus(
    String requestId,
    MaintenanceStatus status,
  ) async {
    try {
      await _remoteDataSource.updateMaintenanceStatus(requestId, status);
      return const Right(null);
    } catch (e) {
      return Left(
        FailureModel(message: 'Failed to update maintenance status: $e'),
      );
    }
  }

  /// Delete maintenance request
  Future<Either<FailureModel, void>> deleteMaintenanceRequest(
    String requestId,
  ) async {
    try {
      await _remoteDataSource.deleteMaintenanceRequest(requestId);
      return const Right(null);
    } catch (e) {
      return Left(
        FailureModel(message: 'Failed to delete maintenance request: $e'),
      );
    }
  }
}

