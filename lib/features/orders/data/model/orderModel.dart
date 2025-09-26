import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'CartLinkModel.dart';

class OrderModel {
  final String id;
  final String customerName;
  final String userName;
  final String customerNumber;
  final String address;
  final double totalPrice;
  final double deposit;
  final int pieceCount;
  final String note;
  final String? note2;

  final OrderStatus status;
  final DateTime createdAt;
  final List<CartLink> cartLinks;
  List<String>? linkedOrderIds;
  final double? shippingCost;
  final double? finalPrice;
  final String? paymentMethod;
  bool isSelected;
  final String? shippingType;
  int? totalPieces;
  double? totalPriceB;
  final bool isHidden;

  OrderModel(
      {required this.id,
      required this.customerName,
      required this.userName,
      required this.customerNumber,
      required this.address,
      required this.totalPrice,
      required this.deposit,
      required this.pieceCount,
      required this.note,
      required this.status,
      required this.createdAt,
      required this.cartLinks,
      this.shippingCost,
      this.finalPrice,
      this.paymentMethod,
      this.isSelected = false,
      this.shippingType,
      this.linkedOrderIds = const [],
      this.totalPieces,
      this.totalPriceB,
      this.isHidden = false,
        this.note2,
      });

  // Convert status to Arabic
  String get statusArabic {
    switch (status) {
      case OrderStatus.pending:
        return 'عرابين';
      case OrderStatus.reserved:
        return 'حجوزات';
      case OrderStatus.completed:
        return 'تم الشراء';
      case OrderStatus.processing:
        return 'جاهزة';
      case OrderStatus.delivered:
        return 'مسلمة';
      case OrderStatus.fordelivered:
        return 'توصيل';
    }
  }

  // Status color coding
  Color get statusColor {
    switch (status) {
      case OrderStatus.pending:
        return Colors.orange;
      case OrderStatus.reserved:
        return Colors.blue;
      case OrderStatus.completed:
        return Colors.purple;
      case OrderStatus.processing:
        return Colors.green;
      case OrderStatus.delivered:
        return Colors.lightBlueAccent;
      case OrderStatus.fordelivered:
        return Colors.deepOrange;
    }
  }

  factory OrderModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return OrderModel(
      id: doc.id,
      customerName: data['customerName'] ?? '',
      userName: data['userName'] ?? '',
      isHidden: data['isHidden'] ?? '',
      customerNumber: data['customerNumber'] ?? '',
      address: data['address'] ?? '',
      totalPrice: (data['totalPrice'] ?? 0).toDouble(),
      deposit: (data['deposit'] ?? 0).toDouble(),
      pieceCount: data['pieceCount'] ?? 0,
      note: data['note'] ?? '',
      note2: data['note2'] ?? '',

      totalPriceB: data['totalPriceB'] ?? 0,
      totalPieces: data['totalPieces'] ?? 0,
      status: OrderStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => OrderStatus.pending,
      ),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      cartLinks: (data['cartLinks'] as List<dynamic>? ?? [])
          .map((e) => CartLink.fromJson(e))
          .toList(),
      shippingCost: (data['shippingCost'] ?? 0).toDouble(),
      finalPrice: (data['finalPrice'] ?? 0).toDouble(),
      paymentMethod: data['paymentMethod'],
      shippingType: data['shippingType'],
      isSelected: data['isSelected'] ?? false,
      linkedOrderIds: (data['linkedOrderIds'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'customerName': customerName,
      'userName': userName,
      'customerNumber': customerNumber,
      'address': address,
      'totalPrice': totalPrice,
      'deposit': deposit,
      'pieceCount': pieceCount,
      'note': note,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'shippingCost': shippingCost,
      'finalPrice': finalPrice,
      'paymentMethod': paymentMethod,
      'isSelected': isSelected,
      'cartLinks': cartLinks.map((e) => e.toJson()).toList(),
      'shippingType': shippingType,
      'linkedOrderIds': linkedOrderIds,
      'totalPriceB': totalPriceB,
      'totalPieces': totalPieces,
      'isHidden': isHidden,
      'note2': note2,



    };
  }

  OrderModel copyWith({
    String? id,
    String? customerName,
    String? userName,
    String? customerNumber,
    String? address,
    double? totalPrice,
    double? deposit,
    int? pieceCount,
    String? note,
    OrderStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<CartLink>? cartLinks,
    double? shippingCost,
    double? finalPrice,
    String? paymentMethod,
    bool? isSelected,
    String? shippingType,
    List<String>? linkedOrderIds,
    double? totalPriceB,
    int? totalPieces,
    bool? isHidden,
    String? note2,
  }) {
    return OrderModel(
      id: id ?? this.id,
      customerName: customerName ?? this.customerName,
      userName: userName ?? this.userName,
      customerNumber: customerNumber ?? this.customerNumber,
      address: address ?? this.address,
      totalPrice: totalPrice ?? this.totalPrice,
      deposit: deposit ?? this.deposit,
      pieceCount: pieceCount ?? this.pieceCount,
      note: note ?? this.note,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      cartLinks: cartLinks ?? this.cartLinks,
      shippingCost: shippingCost ?? this.shippingCost,
      finalPrice: finalPrice ?? this.finalPrice,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      isSelected: isSelected ?? this.isSelected,
      shippingType: shippingType ?? this.shippingType,
      linkedOrderIds: linkedOrderIds ?? this.linkedOrderIds,
      totalPriceB: totalPriceB ?? this.totalPriceB,
      totalPieces: totalPieces ?? this.totalPieces,
      isHidden: isHidden ?? this.isHidden,
      note2: note2 ?? this.note2,

    );
  }
}

enum OrderStatus {
  pending,
  reserved,
  completed,
  processing,
  delivered,
  fordelivered
}

extension OrderModelCopyWithMap on OrderModel {
  OrderModel copyWithFromMap(Map<String, dynamic> fields) {
    return copyWith(
      customerName: fields['customerName'],
      userName: fields['userName'],
      isHidden: fields['isHidden'],
      customerNumber: fields['customerNumber'],
      address: fields['address'],
      totalPrice: fields['totalPrice']?.toDouble(),
      deposit: fields['deposit']?.toDouble(),
      pieceCount: fields['pieceCount'],
      note: fields['note'],
      note2: fields['note2'],
      cartLinks: fields['cartLinks'] != null
          ? (fields['cartLinks'] as List<dynamic>)
              .map((e) => CartLink.fromJson(e))
              .toList()
          : null,
      finalPrice: fields['finalPrice']?.toDouble(),
        shippingCost: fields['shippingCost']?.toDouble(),
      paymentMethod: fields['paymentMethod'],
      shippingType: fields['shippingType'],
      linkedOrderIds: (fields['linkedOrderIds'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
    );
  }
}
