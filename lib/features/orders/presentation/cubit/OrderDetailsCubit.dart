import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/model/orderModel.dart';
import '../cubit/orders_state.dart';

class OrderDetailsCubit extends Cubit<OrderState> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _ordersCollection = 'orders1';
  StreamSubscription<DocumentSnapshot>? _orderSubscription;

  // ✅ Store the orderId as a private field
  String? _currentOrderId;

  OrderDetailsCubit() : super(OrderInitial());

  void listenToOrder(String orderId) {
    _orderSubscription?.cancel();
    emit(OrderLoading());

    // ✅ Save the orderId
    _currentOrderId = orderId;

    _orderSubscription = _firestore
        .collection(_ordersCollection)
        .doc(_currentOrderId)
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

  @override
  Future<void> close() {
    _orderSubscription?.cancel();
    return super.close();
  }

  Future<void> deleteOrder() async {
    try {
      // ✅ Use the stored order ID to reference the document
      if (_currentOrderId == null) {
        emit(OrderFailure("لا يمكن حذف طلب غير محدد."));
        return;
      }

      final docRef = _firestore.collection(_ordersCollection).doc(_currentOrderId);

      // Cancel the listener first to prevent errors on deletion
      _orderSubscription?.cancel();

      // Delete the document from Firestore
      await docRef.delete();

      // The stream's cancellation is handled by the close method,
      // and the listener's onDone will handle the final state.
      // We can directly emit the final state.
      emit(OrderDeleted());

    } catch (e) {
      emit(OrderFailure("فشل في حذف الطلب: $e"));
    }
  }
}