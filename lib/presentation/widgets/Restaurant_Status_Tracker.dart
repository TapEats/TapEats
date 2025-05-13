import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class OrderStatusWidget extends StatefulWidget {
  final String orderId;
  final String currentStatus;
  final Function(String) onStatusUpdated;

  const OrderStatusWidget({
    super.key,
    required this.orderId,
    required this.currentStatus,
    required this.onStatusUpdated,
  });

  @override
  State<OrderStatusWidget> createState() => _OrderStatusWidgetState();
}

class _OrderStatusWidgetState extends State<OrderStatusWidget> {
  late String orderStatus;
  final supabase = Supabase.instance.client;
  final List<String> statusList = ['Received', 'Accepted', 'Cooking', 'Ready'];

  @override
  void initState() {
    super.initState();
    orderStatus = widget.currentStatus;
  }

  void updateOrderStatus(String newStatus) async {
    try {
      await supabase
          .from('orders')
          .update({'status': newStatus}).eq('id', widget.orderId);

      setState(() {
        orderStatus = newStatus;
      });

      widget.onStatusUpdated(newStatus);
    } catch (e) {
      print('Error updating order status: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: statusList.map((status) {
        bool isActive = orderStatus == status;
        return GestureDetector(
          onTap: () {
            if (statusList.indexOf(status) > statusList.indexOf(orderStatus)) {
              updateOrderStatus(status);
            }
          },
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isActive
                      ? const Color(0xFFD0F0C0)
                      : const Color(0xFF151611),
                ),
                child: SvgPicture.asset(
                  'assets/icons/${status.toLowerCase()}.svg',
                  color: isActive
                      ? const Color(0xFF151611)
                      : const Color(0xFFD0F0C0),
                  height: 30,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                status,
                style: TextStyle(
                  color: isActive ? const Color(0xFFD0F0C0) : Colors.white70,
                  fontSize: 14,
                ),
              )
            ],
          ),
        );
      }).toList(),
    );
  }
}
