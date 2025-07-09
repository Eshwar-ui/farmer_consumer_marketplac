enum TransactionStatus {
  pending,
  processing,
  completed,
  refunded,
  failed,
  cancelled
}

enum PaymentMethod {
  cashOnDelivery,
  onlinePayment,
  bankTransfer,
  wallet
}

class TransactionModel {
  final String id;
  final String orderId;
  final String userId;
  final String farmerId;
  final double amount;
  final DateTime timestamp;
  final TransactionStatus status;
  final PaymentMethod paymentMethod;
  final String? paymentId;
  final String? transactionReference;
  final Map<String, dynamic>? metadata;

  TransactionModel({
    required this.id,
    required this.orderId,
    required this.userId,
    required this.farmerId,
    required this.amount,
    required this.timestamp,
    required this.status,
    required this.paymentMethod,
    this.paymentId,
    this.transactionReference,
    this.metadata,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'],
      orderId: json['orderId'],
      userId: json['userId'],
      farmerId: json['farmerId'],
      amount: json['amount'].toDouble(),
      timestamp: DateTime.parse(json['timestamp']),
      status: _getStatusFromString(json['status']),
      paymentMethod: _getPaymentMethodFromString(json['paymentMethod']),
      paymentId: json['paymentId'],
      transactionReference: json['transactionReference'],
      metadata: json['metadata'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'orderId': orderId,
      'userId': userId,
      'farmerId': farmerId,
      'amount': amount,
      'timestamp': timestamp.toIso8601String(),
      'status': status.toString().split('.').last,
      'paymentMethod': paymentMethod.toString().split('.').last,
      'paymentId': paymentId,
      'transactionReference': transactionReference,
      'metadata': metadata,
    };
  }

  static TransactionStatus _getStatusFromString(String status) {
    switch (status) {
      case 'pending':
        return TransactionStatus.pending;
      case 'processing':
        return TransactionStatus.processing;
      case 'completed':
        return TransactionStatus.completed;
      case 'refunded':
        return TransactionStatus.refunded;
      case 'failed':
        return TransactionStatus.failed;
      case 'cancelled':
        return TransactionStatus.cancelled;
      default:
        return TransactionStatus.pending;
    }
  }

  static PaymentMethod _getPaymentMethodFromString(String method) {
    switch (method) {
      case 'cashOnDelivery':
        return PaymentMethod.cashOnDelivery;
      case 'onlinePayment':
        return PaymentMethod.onlinePayment;
      case 'bankTransfer':
        return PaymentMethod.bankTransfer;
      case 'wallet':
        return PaymentMethod.wallet;
      default:
        return PaymentMethod.cashOnDelivery;
    }
  }

  String getReadableStatus() {
    switch (status) {
      case TransactionStatus.pending:
        return 'Pending';
      case TransactionStatus.processing:
        return 'Processing';
      case TransactionStatus.completed:
        return 'Completed';
      case TransactionStatus.refunded:
        return 'Refunded';
      case TransactionStatus.failed:
        return 'Failed';
      case TransactionStatus.cancelled:
        return 'Cancelled';
      default:
        return 'Unknown';
    }
  }

  String getReadablePaymentMethod() {
    switch (paymentMethod) {
      case PaymentMethod.cashOnDelivery:
        return 'Cash on Delivery';
      case PaymentMethod.onlinePayment:
        return 'Online Payment';
      case PaymentMethod.bankTransfer:
        return 'Bank Transfer';
      case PaymentMethod.wallet:
        return 'Wallet';
      default:
        return 'Unknown';
    }
  }

  TransactionModel copyWith({
    String? id,
    String? orderId,
    String? userId,
    String? farmerId,
    double? amount,
    DateTime? timestamp,
    TransactionStatus? status,
    PaymentMethod? paymentMethod,
    String? paymentId,
    String? transactionReference,
    Map<String, dynamic>? metadata,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      userId: userId ?? this.userId,
      farmerId: farmerId ?? this.farmerId,
      amount: amount ?? this.amount,
      timestamp: timestamp ?? this.timestamp,
      status: status ?? this.status,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentId: paymentId ?? this.paymentId,
      transactionReference: transactionReference ?? this.transactionReference,
      metadata: metadata ?? this.metadata,
    );
  }
}