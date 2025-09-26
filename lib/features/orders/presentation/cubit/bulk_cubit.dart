import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/model/CompletedGroupModel.dart';
import 'bulk_state.dart';

class BulkCubit extends Cubit<BulkState> {
  final FirebaseFirestore _firestore;
  final String _collectionName = 'completedGroups1';
  final String _ordersCollection = 'orders1';
  StreamSubscription? _subscription;

  BulkCubit({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        super(BulkInitial());

  // Stream<List<BulkFolder>> _getBulkStream() => _firestore
  //     .collection(_collectionName)
  //     .orderBy('createdAt', descending: true)
  //     .snapshots()
  //     .asyncMap((snapshot) async {
  //   final folders = snapshot.docs.map(BulkFolder.fromFirestore).toList();
  //
  //   // Calculate totals for each folder
  //   await Future.wait(folders.map((folder) async {
  //     try {
  //       final summary = await _calculateFolderTotals(folder.orderIds);
  //       folder.totalPieces = summary['pieces'] as int;
  //       folder.totalCost = summary['total'] as double;
  //     } catch (e) {
  //       // Fallback to stored values if calculation fails
  //       folder.totalPieces ??= 0;
  //       folder.totalCost ??= 0.0;
  //     }
  //   }));
  //
  //   return folders;
  // });

  // Future<Map<String, num>> _calculateFolderTotals(List<String> orderIds) async {
  //   if (orderIds.isEmpty) return {'pieces': 0, 'total': 0.0};
  //
  //   final orders = await Future.wait(
  //     orderIds.map((id) => _firestore.collection(_ordersCollection).doc(id).get()),
  //   );
  //
  //   int totalPieces = 0;
  //   double totalPrice = 0.0;
  //
  //   for (final doc in orders) {
  //     final data = doc.data();
  //     if (data != null && doc.exists) {
  //       totalPieces += (data['totalPieces'] as int? ?? 0);
  //       totalPrice += (data['totalPrice'] as num? ?? 0).toDouble();
  //     }
  //   }
  //
  //   return {'pieces': totalPieces, 'total': totalPrice};
  // }

  Future<void> loadBulks() async {
    emit(BulkLoading());
    _subscription?.cancel();
    _subscription = _getBulkStream().listen( // ✅ Use the correct stream
          (folders) => emit(BulkLoaded(folders)),
      onError: (e) => emit(BulkError('Failed to load bulks: ${e.toString()}')),
    );
  }
  Future<void> _performBulkOperation(
      String successMessage,
      Future<void> Function() operation,
      ) async {
    emit(BulkLoading());
    try {
      await operation();
      emit(BulkOperationSuccess(successMessage));
      await loadBulks();
    } catch (e) {
      emit(BulkError('Operation failed: ${e.toString()}'));
    }
  }

  Future<void> deleteBulk(BulkFolder bulk) async {
    await _performBulkOperation(
      'تم حذف الطرد وكل الطلبات بداخله',
          () async {
        for (final orderId in bulk.orderIds) {
          final orderRef = _firestore.collection(_ordersCollection).doc(orderId);

          // Delete subcollections manually
          await _deleteSubcollections(orderRef, ['cartLinks', 'statusHistory']);

          // Delete the order document
          await orderRef.delete();
        }

        // Delete the bulk document itself
        await _firestore.collection(_collectionName).doc(bulk.id).delete();
      },
    );
  }

  Future<void> _deleteSubcollections(
      DocumentReference docRef,
      List<String> subcollectionNames,
      ) async {
    for (final name in subcollectionNames) {
      final subcollectionRef = docRef.collection(name);
      final snapshots = await subcollectionRef.get();

      for (final doc in snapshots.docs) {
        await subcollectionRef.doc(doc.id).delete();
      }
    }
  }

  Future<void> updateBulkStatus(
      BulkFolder bulk,
      String newStatus, {
        bool updateOrders = false,
        String? orderStatus,
      }) async {
    await _performBulkOperation(
      'تم تعديل حالة الطرد والطلبات',
          () async {
        final batch = _firestore.batch();
        batch.update(
          _firestore.collection(_collectionName).doc(bulk.id),
          {'status': newStatus},
        );

        if (updateOrders && orderStatus != null) {
          for (final id in bulk.orderIds) {
            batch.update(
              _firestore.collection(_ordersCollection).doc(id),
              {'status': orderStatus},
            );
          }
        }
        await batch.commit();
      },
    );
  }

  Future<void> markBulkProcessing(BulkFolder bulk) =>
      updateBulkStatus(bulk, 'processing', updateOrders: true, orderStatus: 'processing');

  Future<void> markBulkDelivered(BulkFolder bulk) =>
      updateBulkStatus(bulk, 'Delivered');

  Future<void> markBulkCompleted(BulkFolder bulk) =>
      updateBulkStatus(bulk, 'completed', updateOrders: true, orderStatus: 'completed');

  Future<void> updateBulk(String id, Map<String, dynamic> updates) async {
    await _performBulkOperation(
      'تم تحديث بيانات الطرد',
          () => _firestore.collection(_collectionName).doc(id).update(updates),
    );
  }

  Future<void> removeOrderFromGroup(String groupId, String orderId) async {
    await _performBulkOperation(
      'تم إزالة الطلب من المجموعة',
          () async {
        final groupRef = _firestore.collection(_collectionName).doc(groupId);
        final group = await groupRef.get();

        if (!group.exists) throw Exception('Group not found');

        final orderIds = List<String>.from(group.get('orderIds') ?? []);
        orderIds.remove(orderId);

        await groupRef.update({'orderIds': orderIds});
      },
    );
  }

  Future<BulkFolder?> folderOfOrder(String orderId) async {
    if (state is BulkLoaded) {
      final bulks = (state as BulkLoaded).bulks;
      for (final b in bulks) {
        if (b.orderIds.contains(orderId)) return b;
      }
    }

    final snap = await _firestore
        .collection(_collectionName)
        .where('orderIds', arrayContains: orderId)
        .limit(1)
        .get();

    return snap.docs.isEmpty ? null : BulkFolder.fromFirestore(snap.docs.first);
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }

  Future<void> removeOrderFromCompletedGroup(String groupId, String orderId) async {
    try {
      // Get the group document from Firestore
      final groupRef = _firestore.collection('completedGroups1').doc(groupId);

      // Fetch the group data
      final groupSnapshot = await groupRef.get();
      if (!groupSnapshot.exists) {
        emit(BulkError("Group not found"));
        return;
      }

      // Get the current orderIds list
      List<dynamic> orderIds = groupSnapshot.get('orderIds');

      // Remove the orderId from the list
      orderIds.remove(orderId);

      // Update the group document with the modified orderIds
      await groupRef.update({
        'orderIds': orderIds,
      });



    } catch (e) {
      emit(BulkError("Failed to remove order from completed group: ${e.toString()}"));
    }
  }
  Stream<List<BulkFolder>> _stream() => _firestore
      .collection(_collectionName)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .asyncMap((snap) async {
    final folders = snap.docs.map(BulkFolder.fromFirestore).toList();

    // Calculate totals for each folder (already updates Firestore inside)
    await Future.wait(folders.map((folder) => folder.calculateTotalsAndSave(_firestore)));

    return folders;
  });




  Stream<List<BulkFolder>> _getBulkStream() => _firestore
      .collection(_collectionName)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .asyncMap((snapshot) async {
    final folders = snapshot.docs.map(BulkFolder.fromFirestore).toList();

    await Future.wait(folders.map((folder) async {
      try {
        final summary = await _calculateFolderTotals(folder.orderIds);
        // ✅ Update the local calculated properties on the model, ready for display
        folder.calculatedPieces = summary['pieces'] as int;
        folder.calculatedTotal = summary['total'] as double;
      } catch (e) {
        folder.calculatedPieces = 0;
        folder.calculatedTotal = 0.0;
      }
    }));
    return folders;
  });

  Future<Map<String, num>> _calculateFolderTotals(List<String> orderIds) async {
    if (orderIds.isEmpty) return {'pieces': 0, 'total': 0.0};

    final orders = await Future.wait(
      orderIds.map((id) => _firestore.collection(_ordersCollection).doc(id).get()),
    );

    int totalPieces = 0;
    double totalPrice = 0.0;

    for (final doc in orders) {
      final data = doc.data();
      if (data != null && doc.exists) {
        totalPieces += (data['pieceCount'] as int? ?? 0);
        totalPrice += (data['totalPrice'] as num? ?? 0).toDouble();
      }
    }
    return {'pieces': totalPieces, 'total': totalPrice};
  }

}