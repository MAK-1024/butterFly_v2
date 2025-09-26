import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/dataSource/order_data_source.dart';
import '../../data/model/orderModel.dart';
import 'orders_state.dart';

class OrderCubit extends Cubit<OrderState> {
  final IOrderRemoteDataSource remoteDataSource;
  final List<OrderModel> _orders = [];
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final String _ordersCollection = 'orders1';

  DocumentSnapshot? _lastDocument;
  bool _hasMore = true;
  bool _isFetching = false;
  OrderStatus? _currentFilter;
  StreamSubscription<List<OrderModel>>? _ordersSubscription;

  OrderCubit(this.remoteDataSource) : super(OrderInitial());

  List<OrderModel> get orders => List.unmodifiable(_orders);

  bool get hasMoreOrders => _hasMore;

  OrderStatus? get currentFilter => _currentFilter;
  StreamSubscription<DocumentSnapshot>? _singleOrderSubscription;

  void resetState() {
    _singleOrderSubscription?.cancel();
    emit(OrderInitial());
  }

  void stopListening() {
    _singleOrderSubscription?.cancel();
  }

  @override
  Future<void> close() {
    _singleOrderSubscription?.cancel();
    return super.close();
  }

  void listenToOrder(String orderId) {
    // Always reset state before starting new subscription
    _singleOrderSubscription?.cancel();
    emit(OrderLoading());

    _singleOrderSubscription = _firestore
        .collection(_ordersCollection)
        .doc(orderId)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        final order = OrderModel.fromFirestore(snapshot);
        emit(OrderLoaded(order));
      } else {
        emit(OrderDeleted());
      }
    }, onError: (e) {
      emit(OrderFailure("خطأ في الاتصال بالطلب: $e"));
    });
  }


  Future<void> deleteOrder(String orderId) async {
    try {
      final orderRef = _firestore.collection(_ordersCollection).doc(orderId);

      // 1. جيب بيانات الطلب عشان تعرف إذا عنده folderId
      final orderSnapshot = await orderRef.get();
      final folderId = orderSnapshot.data()?['folderId'];

      // 2. امسح كل الـ subcollections
      await _deleteSubcollections(orderRef, ['cartLinks', 'statusHistory']);

      // 3. لو الطلب موجود في طرد، نشيله من الـ array
      if (folderId != null && folderId.toString().isNotEmpty) {
        final folderRef =
        _firestore.collection('completedGroups1').doc(folderId);

        await folderRef.update({
          'orderIds': FieldValue.arrayRemove([orderId]),
        });
      }

      // 4. امسح الطلب نفسه
      await orderRef.delete();

      // 5. Emit success
      emit(OrderOperationSuccess());
    } catch (e) {
      emit(OrderFailure('❌ فشل في حذف الطلب: ${e.toString()}'));
    }
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

  Future<void> loadOrdersByStatus(OrderStatus status) async {
    if (_isFetching) return;
    await _ordersSubscription?.cancel();
    _isFetching = true;
    emit(OrderLoading());

    try {
      _currentFilter = status;
      _orders.clear();

      _ordersSubscription =
          remoteDataSource.getOrdersByStatusStream(status).listen((newOrders) {
        _orders
          ..clear()
          ..addAll(newOrders);
        emit(OrdersLoaded(
          orders: _orders,
          hasMore: _hasMore,
          currentFilter: _currentFilter,
        ));
      }, onError: (e) => emit(OrderFailure(e.toString())));
    } catch (_) {
      emit(OrderFailure('فشل في تحميل الطلبات'));
    } finally {
      _isFetching = false;
    }
  }

  Future<void> loadOrdersAll() async {
    if (_isFetching) return;
    await _ordersSubscription?.cancel();
    _isFetching = true;
    emit(OrderLoading());

    try {
      _orders.clear();
      _ordersSubscription = remoteDataSource.getOrdersAllStream().listen(
        (newOrders) {
          _orders
            ..clear()
            ..addAll(newOrders);
          emit(OrdersLoaded(
            orders: _orders,
            hasMore: _hasMore,
            currentFilter: _currentFilter,
          ));
        },
        onError: (e) => emit(OrderFailure(e.toString())),
      );
    } catch (_) {
      emit(OrderFailure('فشل في تحميل الطلبات'));
    } finally {
      _isFetching = false;
    }
  }

  Future<void> updateOrderStatus(
      String orderId,
      OrderStatus newStatus, {
        bool force = false,
        Map<String, dynamic>? extraData,
      }) async {
    var index = _orders.indexWhere((o) => o.id == orderId);

    if (index == -1) {
      try {
        final doc = await _firestore.collection(_ordersCollection).doc(orderId).get();
        if (!doc.exists) {
          emit(OrderFailure('الطلب غير موجود'));
          return;
        }
        final fetchedOrder = OrderModel.fromFirestore(doc);
        // Remove this line to avoid manual list changes
        // _orders.insert(0, fetchedOrder);
        index = 0;
      } catch (e) {
        emit(OrderFailure('خطأ أثناء جلب الطلب: $e'));
        return;
      }
    }

    final currentStatus = _orders[index].status;
    final allowed = (currentStatus == OrderStatus.pending &&
        newStatus == OrderStatus.reserved) ||
        (currentStatus == OrderStatus.reserved &&
            newStatus == OrderStatus.processing) ||
        (currentStatus == OrderStatus.processing &&
            newStatus == OrderStatus.delivered) ||
        newStatus == OrderStatus.fordelivered;

    if (!allowed && !force) {
      emit(OrderFailure(
          'لا يمكن تغيير الحالة من ${_getStatusName(currentStatus)} '
              'إلى ${_getStatusName(newStatus)}'));
      return;
    }
    try {
      await remoteDataSource.updateOrderStatus(
        orderId,
        newStatus,
        extraData: extraData,
      );

      // Remove from list if it no longer matches current filter
      _orders.removeWhere((o) => o.id == orderId);

      emit(OrderOperationSuccess('تم تحديث حالة الطلب إلى ${_getStatusName(newStatus)}'));
      emit(OrdersLoaded( orders: _orders)); // refresh the UI
    } catch (e) {
      emit(OrderFailure('فشل في تحديث حالة الطلب: $e'));
    }

  }


  Future<void> updateOrderDetails(
      String orderId, Map<String, dynamic> updatedFields) async {
    try {
      final docRef = _firestore.collection(_ordersCollection).doc(orderId);
      await docRef.update(updatedFields);


      emit(OrderOperationSuccess('تم تعديل بيانات الطلب'));

    } catch (e) {
      emit(OrderFailure('فشل في تعديل الطلب: $e'));
    }
  }

  Future<OrderModel> createOrder(OrderModel order) async {
    emit(OrderLoading());
    try {
      final createdOrder = await remoteDataSource.createOrder(order);

      _orders.insert(0, createdOrder);

      emit(
          OrderOperationSuccess());

      emit(OrdersLoaded(
        orders: _orders,
        hasMore: _hasMore,
        currentFilter: _currentFilter,
      ));

      return createdOrder;
    } on OrderDataSourceException catch (e) {
      emit(OrderFailure(e.message));
      rethrow;
    } catch (e) {
      emit(OrderFailure('فشل في إنشاء الطلب'));
      rethrow;
    }
  }

  void clearFilter() {
    _currentFilter = null;
    _orders.clear();
    _hasMore = true;
    _lastDocument = null;
    emit(OrderInitial());
  }

  String _getStatusName(OrderStatus s) {
    switch (s) {
      case OrderStatus.pending:
        return 'عرابين';
      case OrderStatus.reserved:
        return 'حجوزات';
      case OrderStatus.processing:
        return 'جاهزة للتسليم';
      case OrderStatus.delivered:
        return 'مسلمة';
      case OrderStatus.completed:
        return 'تم الشراء';
      case OrderStatus.fordelivered:
        return 'التوصيل';
    }
  }


  Color getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return Colors.orange;
      case OrderStatus.reserved:
        return Colors.blueGrey;
      case OrderStatus.processing:
        return Colors.blue;
      case OrderStatus.delivered:
        return Colors.green;
      case OrderStatus.completed:
        return Colors.purple;
      case OrderStatus.fordelivered:
        return Colors.teal;
    }
  }



  Future<void> linkOrders({
    required String sourceOrderId,
    required List<String> targetOrderIds,
  }) async {
    try {
      final batch = FirebaseFirestore.instance.batch();
      final sourceRef =
          _firestore.collection(_ordersCollection).doc(sourceOrderId);

      // 1. Get current links or initialize empty list if null
      final sourceSnap = await sourceRef.get();
      final existingSourceLinks = List<String>.from(
        sourceSnap['linkedOrderIds'] ?? [], // Handle null case
      );

      // 2. Merge with new links and remove duplicates
      final updatedSourceLinks =
          {...existingSourceLinks, ...targetOrderIds}.toList();

      // Update source order
      batch.update(sourceRef, {'linkedOrderIds': updatedSourceLinks});

      // 3. Update all target orders
      for (final targetId in targetOrderIds) {
        final targetRef =
            _firestore.collection(_ordersCollection).doc(targetId);
        final targetSnap = await targetRef.get();

        final existingTargetLinks = List<String>.from(
          targetSnap['linkedOrderIds'] ?? [], // Handle null case
        );

        final updatedTargetLinks =
            {...existingTargetLinks, sourceOrderId}.toList();
        batch.update(targetRef, {'linkedOrderIds': updatedTargetLinks});
      }

      await batch.commit();
      emit(OrderOperationSuccess("✅ تم ربط الطلبات بنجاح"));
    } catch (e) {
      emit(OrderFailure("❌ فشل ربط الطلبات: $e"));
    }
  }

  void copyOrderInfo(OrderModel order) {
    final shippingCost = order.shippingCost ?? 0;
    final finalPrice = order.totalPrice - order.deposit + shippingCost;
    final hasShippingCost = shippingCost > 0;

    final textToCopy = StringBuffer();

    // Common info for all orders
    textToCopy
      ..writeln('طلب رقم: ${order.id}')
      ..writeln('الاسم: ${order.customerName}')
      ..writeln('الرقم: ${order.customerNumber}')
      ..writeln('العنوان: ${order.address}')
      ..writeln('العربون: ${order.deposit}');

    if (order.status != OrderStatus.pending) {
      // Include full info for orders that are not pending
      final cartLinks = order.cartLinks.map((c) => c.link).join("\n---\n");

      textToCopy
        ..writeln('السلة:')
        ..writeln(cartLinks)
        ..writeln('القطع: ${order.pieceCount}')
        ..writeln('الإجمالي: ${order.totalPrice}')
        ..writeln('تكلفة الشحن: ${hasShippingCost ? shippingCost : "00"}')
        ..writeln('المبلغ النهائي: $finalPrice')
        ..write(hasShippingCost ? '' : '\nملاحظة: السعر لا يشمل تكلفة الشحن');
    }

    Clipboard.setData(ClipboardData(text: textToCopy.toString()));
  }

  Future<void> updateOrderDetails2(OrderModel updatedOrder) async {
    // Emit a loading state to show progress, but don't clear the list
    emit(OrderLoading());
    try {
      // 1. Prepare data for Firestore
      final cartLinksData = updatedOrder.cartLinks
          .map((link) => {
        'link': link.link,
        'pieces': link.pieces,
        'note': link.note ?? '',
      })
          .toList();

      final totalPieces =
      updatedOrder.cartLinks.fold(0, (sum, link) => sum + link.pieces);

      await _firestore.collection('orders1').doc(updatedOrder.id).update({
        'customerName': updatedOrder.customerName,
        'customerNumber': updatedOrder.customerNumber,
        'address': updatedOrder.address,
        'pieceCount': totalPieces,
        'deposit': updatedOrder.deposit,
        'shippingCost': updatedOrder.shippingCost,
        'note': updatedOrder.note,
        'paymentMethod': updatedOrder.paymentMethod,
        'shippingType': updatedOrder.shippingType,
        'status': updatedOrder.status.name,
        'cartLinks': cartLinksData,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      emit(OrderOperationSuccess());

    } catch (e) {
      emit(OrderFailure('❌ فشل في تحديث الطلب: ${e.toString()}'));
    }
  }

  Future<void> getOrders({OrderStatus? status}) async {
    if (_isFetching) return;
    _isFetching = true;
    emit(OrderLoading());

    try {
      List<OrderModel> fetchedOrders;
      if (status != null) {
        fetchedOrders = await remoteDataSource.getOrdersByStatus(status);
        _currentFilter = status;
      } else {
        fetchedOrders = await remoteDataSource.getOrdersAll();
        _currentFilter = null;
      }

      _orders
        ..clear()
        ..addAll(fetchedOrders);

      emit(OrdersLoaded(
        orders: _orders,
        hasMore: _hasMore,
        currentFilter: _currentFilter,
      ));
    } catch (e) {
      emit(OrderFailure('فشل في تحميل الطلبات: $e'));
    } finally {
      _isFetching = false;
    }
  }
}
