import 'package:equatable/equatable.dart';
import '../../data/model/orderModel.dart';

abstract class OrderState extends Equatable {
  const OrderState();

  @override
  List<Object?> get props => [];

  bool get hasMore => true;
}

class OrderInitial extends OrderState {}






class OrderLoaded extends OrderState {
  final OrderModel order;
  OrderLoaded(this.order);
}

class OrderDeleted extends OrderState {}


class OrderLoading extends OrderState {}

class OrderOperationSuccess extends OrderState {
  final String message;
  const OrderOperationSuccess([this.message = '']);

  @override
  List<Object?> get props => [message];
}

class OrderFailure extends OrderState {
  final String message;
  const OrderFailure(this.message);

  @override
  List<Object?> get props => [message];
}

class OrdersLoaded extends OrderState {
  final List<OrderModel> orders;
  final bool hasMore;
  final OrderStatus? currentFilter;

  const OrdersLoaded({
    required this.orders,
    this.hasMore = true,
    this.currentFilter,
  });




  @override
  List<Object?> get props => [orders, hasMore, currentFilter];
}

class OrderUpdated extends OrderState {
  final OrderModel updatedOrder;
  const OrderUpdated(this.updatedOrder);

  @override
  List<Object?> get props => [updatedOrder];
}



