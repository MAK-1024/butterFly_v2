import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class OrderCard extends StatelessWidget {
  final String? orderId;
  final String userName;
  final String emName;

  final String customerPhone;
  final DateTime createdAt;
  final String status;
  final int? pieces;
  final double deposit;
  final double totalPrice;
  final double? shippingCost;

  final String? shippingType;
  final String? paymentMethod;
  final String? folderName;
  final String? folderId;

  final IconData? actionIcon;
  final VoidCallback? onAction;

  final VoidCallback? onTap;

  final Color? statusColor;

  final bool showCheckbox;
  final bool isChecked;
  final ValueChanged<bool?>? onCheckboxChanged;
  final List<String>? linkedOrderIds;
  final ValueChanged<String>? onShippingTypeChanged;

  const OrderCard({
    super.key,
    this.orderId,
    required this.userName,
    required this.emName,
    required this.customerPhone,
    required this.createdAt,
    required this.status,
    this.pieces,
    required this.deposit,
    required this.totalPrice,
    this.shippingType,
    this.paymentMethod,
    this.folderName,
    this.actionIcon,
    this.onAction,
    this.onTap,
    this.statusColor,
    this.showCheckbox = false,
    this.isChecked = false,
    this.onCheckboxChanged,
    this.folderId,
    this.linkedOrderIds,
    this.shippingCost,
    this.onShippingTypeChanged,
  });

  Color _getStatusColor(String status) {
    switch (status) {
      case 'عرابين':
        return Colors.orange;
      case 'حجوزات':
        return Colors.blue;
      case 'تم الشراء':
        return Colors.purple;
      case 'جاهزة':
        return Colors.green;
      case 'مسلمة':
        return Colors.lightBlueAccent;
      case 'توصيل':
        return Colors.deepOrange;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color themeStatusColor = statusColor ?? _getStatusColor(status);
    final String formattedDate = DateFormat('yyyy/MM/dd - hh:mm a')
        .format(createdAt)
        .replaceAll('AM', 'ص')
        .replaceAll('PM', 'م');
    final double remainingAmount = totalPrice - deposit;
    final double remainingAmount2 =
        (totalPrice + (shippingCost ?? 0)) - deposit;

    return Card(
      elevation: 1,
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─── optional check‑box ───

              // ─── card body ───
              Expanded(
                  child: _buildDetails(
                      themeStatusColor, formattedDate, remainingAmount2)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetails(
      Color themeStatusColor, String formattedDate, double remainingAmount) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Row(
                children: [
                  if (showCheckbox)
                    Padding(
                      padding: const EdgeInsets.only(right: 4, top: 4),
                      child: Checkbox(
                        value: isChecked,
                        onChanged: onCheckboxChanged,
                      ),
                    ),
                  Text(
                    'طلب #$orderId',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (actionIcon != null && onAction != null) ...[
              const SizedBox(width: 6),
              IconButton(
                icon: Icon(actionIcon, size: 20),
                splashRadius: 20,
                tooltip: 'إجراء',
                onPressed: onAction,
              ),
            ],
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: themeStatusColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: themeStatusColor.withOpacity(0.30)),
              ),
              child: Text(
                status,
                style: TextStyle(
                    color: themeStatusColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // user + date
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text('مسجّل بواسطة: $emName',
                  style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                      overflow: TextOverflow.ellipsis)),
            ),
            Text(formattedDate,
                style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          ],
        ),
        if ((folderName != null && folderName!.isNotEmpty) ||
            (linkedOrderIds != null && linkedOrderIds!.isNotEmpty))
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Row(
              children: [
                if (folderName != null && folderName!.isNotEmpty) ...[
                  const Icon(Icons.folder, size: 18, color: Colors.blueGrey),
                  const SizedBox(width: 6),
                  Text('الطرد: $folderName',
                      style: const TextStyle(
                          fontSize: 13, color: Colors.blueGrey)),
                  const SizedBox(width: 12),
                ],
                if (linkedOrderIds != null && linkedOrderIds!.isNotEmpty)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.indigo.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.indigo.shade100),
                    ),
                    child: Row(
                      children: const [
                        Icon(Icons.link, size: 14, color: Colors.indigo),
                        SizedBox(width: 4),
                        Text("مرتبط",
                            style:
                                TextStyle(color: Colors.indigo, fontSize: 12)),
                      ],
                    ),
                  ),
              ],
            ),
          ),

        const Divider(height: 24, thickness: 1),
        // customer info
        Row(
          children: [
            const Icon(Icons.person_outline, size: 18),
            const SizedBox(width: 8),
            Expanded(
                child: Text(userName, style: const TextStyle(fontSize: 14))),
            const Icon(Icons.phone_outlined, size: 18),
            const SizedBox(width: 8),
            Text(customerPhone, style: const TextStyle(fontSize: 14)),
          ],
        ),
        const Divider(height: 24, thickness: 1),
        // order numbers
        if (pieces != null)
          _detail(Icons.shopping_bag_outlined, 'عدد القطع:', '$pieces'),
        _detail(Icons.attach_money_outlined, 'الإجمالي:',
            '${totalPrice.toStringAsFixed(2)} د.ل'),
        _detail(Icons.payment_outlined, 'العربون:',
            '${deposit.toStringAsFixed(2)} د.ل'),
        if (shippingCost != null && shippingCost! > 0)
          _detail(Icons.local_shipping, 'تكلفة الشحن:',
              '${shippingCost!.toStringAsFixed(2)} د.ل'),
        if (remainingAmount > 0)
          _detail(Icons.money_off_outlined, 'المتبقي:',
              '${remainingAmount.toStringAsFixed(2)} د.ل',
              bold: true),


        if (shippingType != null && shippingType!.isNotEmpty)
          _detail(
            Icons.local_shipping_outlined,
            'طريقة الشحن:',
            shippingType!.toLowerCase() == 'free'
                ? 'مجاني'
                : shippingType!.toLowerCase() == 'paid'
                ? 'مدفوع'
                : shippingType!,
          ),


        if (paymentMethod != null && paymentMethod!.isNotEmpty)
          _detail(Icons.account_balance_wallet_outlined, 'طريقة الدفع:',
              paymentMethod!),
      ],
    );
  }

  Widget _detail(IconData icon, String label, String value,
      {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}
