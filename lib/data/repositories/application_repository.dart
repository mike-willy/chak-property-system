import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import '../models/application_model.dart';
import '../models/failure_model.dart';

class ApplicationRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<Either<FailureModel, void>> submitApplication(
    ApplicationModel application,
  ) async {
    try {
      await _firestore
          .collection('tenantApplications')
          .doc(application.id)
          .set(application.toMap());

      return const Right(null);
    } catch (e) {
      return Left(FailureModel(message: 'Failed to submit application'));
    }
  }
}
