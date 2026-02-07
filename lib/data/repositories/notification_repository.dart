// data/repositories/notification_repository.dart
import 'package:dartz/dartz.dart';
import '../models/failure_model.dart';
import '../models/notification_model.dart';
import '../datasources/remote_datasource.dart';

class NotificationRepository {
  final RemoteDataSource _remoteDataSource;

  NotificationRepository(this._remoteDataSource);

  Future<Either<FailureModel, List<NotificationModel>>> getNotifications(String userId) async {
    try {
      final notifications = await _remoteDataSource.getNotifications(userId);
      return Right(notifications);
    } catch (e) {
      return Left(FailureModel(message: 'Failed to fetch notifications: $e'));
    }
  }

  Future<Either<FailureModel, void>> markAsRead(String notificationId) async {
    try {
      await _remoteDataSource.markNotificationAsRead(notificationId);
      return const Right(null);
    } catch (e) {
      return Left(FailureModel(message: 'Failed to mark notification as read: $e'));
    }
  }

  Future<Either<FailureModel, void>> markAllAsRead(String userId) async {
    try {
      await _remoteDataSource.markAllNotificationsAsRead(userId);
      return const Right(null);
    } catch (e) {
      return Left(FailureModel(message: 'Failed to mark all notifications as read: $e'));
    }
  }
}
