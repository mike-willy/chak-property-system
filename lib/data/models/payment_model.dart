import 'package:cloud_firestore/cloud_firestore.dart';

enum PaymentMethod {
  card,
  bank,
  mobile,
}

enum PaymentStatus {
  pending,
  completed,
  failed,
}

extension PaymentMethodExtension on PaymentMethod {
  String get value {
    switch (this) {
      case PaymentMethod.card:
        return 'card';
      case PaymentMethod.bank:
        return 'bank';
      case PaymentMethod.mobile:
        return 'mobile';
    }
  }

  static PaymentMethod fromString(String value) {
    switch (value) {
      case 'card':
        return PaymentMethod.card;
      case 'bank':
        return PaymentMethod.bank;
      case 'mobile':
        return PaymentMethod.mobile;
      default:
        return PaymentMethod.card;
    }
  }
}

extension PaymentStatusExtension on PaymentStatus {
  String get value {
    switch (this) {
      case PaymentStatus.pending:
        return 'pending';
      case PaymentStatus.completed:
        return 'completed';
      case PaymentStatus.failed:
        return 'failed';
    }
  }

  static PaymentStatus fromString(String value) {
    switch (value) {
      case 'pending':
        return PaymentStatus.pending;
      case 'completed':
        return PaymentStatus.completed;
      case 'failed':
        return PaymentStatus.failed;
      default:
        return PaymentStatus.pending;
    }
  }
}

class PaymentModel {
  final String id;
  final String leaseId;
  final String tenantId;
  final double amount;
  final PaymentMethod method;
  final PaymentStatus status;
  final String? transactionId;
  final DateTime dueDate;
  final DateTime? paidDate;
  final String? receiptUrl;

  PaymentModel({
    required this.id,
    required this.leaseId,
    required this.tenantId,
    required this.amount,
    required this.method,
    required this.status,
    this.transactionId,
    required this.dueDate,
    this.paidDate,
    this.receiptUrl,
  });

  // Convert to Firestore document
  Map<String, dynamic> toMap() {
    return {
      'leaseId': leaseId,
      'tenantId': tenantId,
      'amount': amount,
      'method': method.value,
      'status': status.value,
      if (transactionId != null) 'transactionId': transactionId,
      'dueDate': Timestamp.fromDate(dueDate),
      if (paidDate != null) 'paidDate': Timestamp.fromDate(paidDate!),
      if (receiptUrl != null) 'receiptUrl': receiptUrl,
    };
  }

  // Create from Firestore document
  factory PaymentModel.fromMap(String id, Map<String, dynamic> map) {
    return PaymentModel(
      id: id,
      leaseId: map['leaseId'] as String? ?? '',
      tenantId: map['tenantId'] as String? ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      method: PaymentMethodExtension.fromString(
        map['method'] as String? ?? 'card',
      ),
      status: PaymentStatusExtension.fromString(
        map['status'] as String? ?? 'pending',
      ),
      transactionId: map['transactionId'] as String?,
      dueDate: (map['dueDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      paidDate: (map['paidDate'] as Timestamp?)?.toDate(),
      receiptUrl: map['receiptUrl'] as String?,
    );
  }

  // Create from Firestore document snapshot
  factory PaymentModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PaymentModel.fromMap(doc.id, data);
  }

  // Check if payment is overdue
  bool get isOverdue {
    return status == PaymentStatus.pending &&
        DateTime.now().isAfter(dueDate);
  }

  // Copy with method
  PaymentModel copyWith({
    String? id,
    String? leaseId,
    String? tenantId,
    double? amount,
    PaymentMethod? method,
    PaymentStatus? status,
    String? transactionId,
    DateTime? dueDate,
    DateTime? paidDate,
    String? receiptUrl,
  }) {
    return PaymentModel(
      id: id ?? this.id,
      leaseId: leaseId ?? this.leaseId,
      tenantId: tenantId ?? this.tenantId,
      amount: amount ?? this.amount,
      method: method ?? this.method,
      status: status ?? this.status,
      transactionId: transactionId ?? this.transactionId,
      dueDate: dueDate ?? this.dueDate,
      paidDate: paidDate ?? this.paidDate,
      receiptUrl: receiptUrl ?? this.receiptUrl,
    );
  }
}

