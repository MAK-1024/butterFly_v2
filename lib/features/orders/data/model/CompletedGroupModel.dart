import 'package:cloud_firestore/cloud_firestore.dart';

class BulkFolder {
  final String id;
  String name;
  String? name2;
  String? trackNumber;
  final String? status;
  String? note;
  double? totalCost;
  int? totalPieces;
  double? totalCost2;
  List<String> orderIds;
  DateTime createdAt;
  final double? shippingCost;

  // Calculated totals
  int calculatedPieces = 0;
  double calculatedTotal = 0.0;

  BulkFolder({
    required this.id,
    required this.name,
    this.name2,
    this.trackNumber,
    this.note,
    this.status,
    this.totalCost,
    this.totalPieces,
    required this.orderIds,
    required this.createdAt,
    this.shippingCost,
    this.totalCost2,
  });

  factory BulkFolder.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data()! as Map<String, dynamic>;
    return BulkFolder(
      id: doc.id,
      name: d['name'] ?? '',
      name2: d['name2'] ?? '',
      trackNumber: d['trackNumber'],
      note: d['note'],
      status: d['status'] ?? 'completed',
      totalCost: parseDouble(d['totalCost']),
      totalCost2: parseDouble(d['totalCost2']),
      shippingCost: parseDouble(d['shippingCost']),
      totalPieces: parseInt(d['totalPieces']),
      orderIds: List<String>.from(d['orderIds'] ?? const []),
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  static double parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  static int parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'name2': name2,
      'trackNumber': trackNumber,
      'note': note,
      'totalCost': totalCost,
      'totalCost2': totalCost2,
      'totalPieces': totalPieces,
      'orderIds': orderIds,
      'createdAt': Timestamp.fromDate(createdAt),
      'shippingCost': shippingCost,
      'status': status,
    };
  }

  /// Calculate totals based on the orders in Firestore and update this object
  Future<void> calculateTotalsAndSave(FirebaseFirestore firestore) async {
    int pieces = 0;
    double total = 0.0;

    if (orderIds.isEmpty) {
      calculatedPieces = 0;
      calculatedTotal = 0.0;
      return;
    }

    try {
      final orders = await Future.wait(
        orderIds.map((id) => firestore.collection('orders1').doc(id).get()),
      );

      for (final doc in orders) {
        if (doc.exists) {
          final data = doc.data() as Map<String, dynamic>? ?? {};

          // This line is important:
          final orderPieces = parseInt(data['pieceCount'] ?? 0); // sum pieceCount
          final orderPrice = parseDouble(data['totalPrice'] ?? 0.0);
          final orderShipping = parseDouble(data['shippingCost'] ?? 0.0);

          pieces += orderPieces;      // sum pieces
          total += orderPrice + orderShipping; // sum total price + shipping
        }
      }

      // Update calculated values
      calculatedPieces = pieces;
      calculatedTotal = total;

      // Update the actual folder fields
      totalPieces = pieces;
      totalCost = total;

      // Update Firestore
      await firestore.collection('bulkFolders').doc(id).update({
        'totalPieces': pieces,
        'totalCost': total,
      });
    } catch (e) {
      print('Error calculating totals: $e');
    }
  }
}

