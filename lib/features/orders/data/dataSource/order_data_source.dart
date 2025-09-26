import 'package:cloud_firestore/cloud_firestore.dart';

import '../model/CompletedGroupModel.dart';
import '../model/orderModel.dart';


abstract class IOrderRemoteDataSource {
  Future<OrderModel> createOrder(OrderModel order);
  Future<List<OrderModel>> getOrdersByStatus(OrderStatus status);
  Future<List<OrderModel>> getOrdersAll();

  Future<PaginatedOrdersResult> getOrdersByStatusPaginated(
      OrderStatus status, {
        required int limit,
        DocumentSnapshot? startAfter,
      });
  Future<void> updateOrderStatus(
      String orderId,
      OrderStatus newStatus, {
        Map<String, dynamic>? extraData,
      });
  Future<void> deleteOrder(String orderId);


  Future<List<OrderModel>> getOrdersInFolder(String folderId);

  Stream<List<OrderModel>> getOrdersByStatusStream(OrderStatus status);
  Stream<List<OrderModel>> getOrdersAllStream();

  Stream<PaginatedOrdersResult> getOrdersByStatusPaginatedStream(
      OrderStatus status, {
        required int limit,
        DocumentSnapshot? startAfter,
      });
}

class OrderRemoteDataSource implements IOrderRemoteDataSource {
  final FirebaseFirestore _firestore;
  static const _ordersCollection = 'orders1';



  OrderRemoteDataSource(this._firestore);

    Future<OrderModel> createOrder(OrderModel order) async {
      try {
        final newOrderId = await _getNextOrderId();

        final orderWithId = order.copyWith(id: newOrderId);

        final docRef = _firestore.collection(_ordersCollection).doc(newOrderId);

        await _firestore.runTransaction((transaction) async {
          final docSnapshot = await transaction.get(docRef);
          if (docSnapshot.exists) {
            throw OrderDataSourceException('Order ID $newOrderId already exists');
          }



          transaction.set(docRef, {
            ...orderWithId.toFirestore(),
            'createdAt': DateTime.now(),
            'createdAtServer': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });

          if (order.cartLinks.isNotEmpty) {
            final batch = _firestore.batch();
            for (final cartLink in order.cartLinks) {
              final linkRef = docRef.collection('cartLinks').doc();
              batch.set(linkRef, {
                ...cartLink.toFirestore(),
                'orderId': newOrderId,
              });
            }
            await batch.commit();
          }
        });

        return orderWithId;
      } on FirebaseException catch (e) {
        throw OrderDataSourceException('Failed to create order: ${e.message}');
      }
    }

  @override
  Future<List<OrderModel>> getOrdersAll() async {
    try {
      final snapshot = await _firestore
          .collection(_ordersCollection)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => OrderModel.fromFirestore(doc))
          .toList();
    } on FirebaseException catch (e) {
      throw OrderDataSourceException('Failed to fetch all orders: ${e.message}');
    }
  }




  Future<String> _getNextOrderId() async {
    final querySnapshot = await _firestore
        .collection(_ordersCollection)
        .orderBy('createdAt', descending: true)
        .limit(1)
        .get();

    int nextId = 1;
    if (querySnapshot.docs.isNotEmpty) {
      final lastId = querySnapshot.docs.first.id;
      final numberPart = int.tryParse(lastId.replaceAll(RegExp(r'\D'), '')) ?? 0;
      nextId = numberPart + 1;
    }

    return 'SH${nextId.toString().padLeft(4, '0')}';
  }


  @override
  Future<List<OrderModel>> getOrdersByStatus(OrderStatus status) async {
    try {
      final snapshot = await _firestore
          .collection(_ordersCollection)
          .where('status', isEqualTo: status.name)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => OrderModel.fromFirestore(doc))
          .toList();
    } on FirebaseException catch (e) {
      throw OrderDataSourceException('Failed to fetch orders: ${e.message}');
    }
  }

  @override
  @override
  Stream<List<OrderModel>> getOrdersAllStream() {
    try {
      return _firestore
          .collection(_ordersCollection)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) =>
          snapshot.docs.map((doc) => OrderModel.fromFirestore(doc)).toList());
    } on FirebaseException catch (e) {
      throw OrderDataSourceException('Failed to stream orders: ${e.message}');
    }
  }

  @override
  Future<PaginatedOrdersResult> getOrdersByStatusPaginated(
      OrderStatus status, {
        required int limit,
        DocumentSnapshot? startAfter,
      }) async {
    try {
      Query query = _firestore
          .collection(_ordersCollection)
          .where('status', isEqualTo: status.name)
          .orderBy('createdAt', descending: true)
          .limit(limit);

      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      final snapshot = await query.get();
      final orders = snapshot.docs.map(OrderModel.fromFirestore).toList();

      return PaginatedOrdersResult(
        orders: orders,
        lastDocument: snapshot.docs.isEmpty ? null : snapshot.docs.last,
      );
    } on FirebaseException catch (e) {
      throw OrderDataSourceException('Failed to fetch paginated orders: ${e.message}');
    }
  }

  @override
  Future<void> updateOrderStatus(
      String orderId,
      OrderStatus newStatus, {
        Map<String, dynamic>? extraData,
      }) async {
    final orderRef = _firestore.collection(_ordersCollection).doc(orderId);
    final historyRef = orderRef.collection('statusHistory').doc();

    try {
      await _firestore.runTransaction((tx) async {
        final Map<String, dynamic> updateFields = {
          'status': newStatus.name,
          'updatedAt': FieldValue.serverTimestamp(),
        };

        if (extraData != null) {
          updateFields.addAll(extraData);
        }

        tx.update(orderRef, updateFields);

        tx.set(historyRef, {
          'status': newStatus.name,
          'changedAt': FieldValue.serverTimestamp(),
        });
      });
    } on FirebaseException catch (e) {
      throw OrderDataSourceException('فشل في تحديث حالة الطلب: ${e.message}');
    }
  }
  @override
  Future<void> deleteOrder(String orderId) async {
    try {
      await _firestore.collection(_ordersCollection).doc(orderId).delete();
    } on FirebaseException catch (e) {
      throw OrderDataSourceException('Failed to delete order: ${e.message}');
    }
  }


  @override
  Future<List<OrderModel>> getOrdersInFolder(String folderId) async {
    try {
      final snapshot = await _firestore
          .collection(_ordersCollection)
          .where('folderId', isEqualTo: folderId)
          .get();

      return snapshot.docs
          .map((doc) => OrderModel.fromFirestore(doc))
          .toList();
    } on FirebaseException catch (e) {
      throw OrderDataSourceException('Failed to fetch folder orders: ${e.message}');
    }
  }


  @override
  Stream<List<OrderModel>> getOrdersByStatusStream(OrderStatus status) {
    return _firestore
        .collection(_ordersCollection)
        .where('status', isEqualTo: status.name)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => OrderModel.fromFirestore(doc))
        .toList());
  }

  @override
  Stream<PaginatedOrdersResult> getOrdersByStatusPaginatedStream(
      OrderStatus status, {
        required int limit,
        DocumentSnapshot? startAfter,
      }) {
    Query query = _firestore
        .collection(_ordersCollection)
        .where('status', isEqualTo: status.name)
        .orderBy('createdAt', descending: true)
        .limit(limit);

    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }

    return query.snapshots().map((snapshot) {
      final orders = snapshot.docs.map(OrderModel.fromFirestore).toList();
      return PaginatedOrdersResult(
        orders: orders,
        lastDocument: snapshot.docs.isEmpty ? null : snapshot.docs.last,
      );
    });
  }
}

class PaginatedOrdersResult {
  final List<OrderModel> orders;
  final DocumentSnapshot? lastDocument;

  PaginatedOrdersResult({
    required this.orders,
    this.lastDocument,
  });
}

class OrderDataSourceException implements Exception {
  final String message;
  OrderDataSourceException(this.message);

  @override
  String toString() => 'OrderDataSourceException: $message';
}