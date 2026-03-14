import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../common/color_extension.dart';
import '../common_widget/round_button.dart';
import '../view/main_tabview/main_tabview.dart';
import '../view/my_health/health_service.dart';
import 'checkout_message_view.dart';
import 'my_order_view.dart';

class CheckoutView extends StatefulWidget {
  final List<Map<String, dynamic>> cartItems;
  final double totalAmount;

  const CheckoutView({
    super.key,
    required this.cartItems,
    required this.totalAmount,
  });

  @override
  State<CheckoutView> createState() => _CheckoutViewState();
}

class _CheckoutViewState extends State<CheckoutView> {

  @override
  void initState() {
    super.initState();
    _fetchUserAddress();
  }

  List paymentArr = [
    {"name": "Cash on delivery", "icon": "assets/img/cash.png"},
  ];

  int selectMethod = 0;
  bool isLoading = false;
  final supabase = Supabase.instance.client;
  String deliveryAddress = "653 Nostrand Ave.\nBrooklyn, NY 11216";
  final HealthService _healthService = HealthService();

  double get deliveryFee => 2.0;
  double get subtotal => widget.totalAmount; // Remove delivery fee
  double get discount => 0.0; // You can implement discount logic here

  VoidCallback? _buildOnPressedHandler() {
    return isLoading ? null : () => _handleOrderSubmission();
  }

  void _handleOrderSubmission() {
    _processOrder().catchError((e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    });
  }

  Future<void> _processOrder() async {
    setState(() => isLoading = true);
    try {
      // 1. First validate all cart items
      for (final item in widget.cartItems) {
        if (item['item_id'] == null) {
          debugPrint('Invalid cart item found: $item');
          throw Exception('One or more items are missing item_id');
        }
      }

      final userId = supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not logged in');
      debugPrint('[User] User ID: $userId');

      // Create order in database
      debugPrint('[Order] Creating order record...');
      final orderResponse = await supabase
          .from('order_history')
          .insert({
        'user_id': userId,
        'total_amount': widget.totalAmount,
        'status': 'pending',
      })
          .select('id')
          .single();
      debugPrint('[Order] Created order ID: ${orderResponse['id']}');

      // Add order items
      debugPrint('[Order Items] Processing ${widget.cartItems.length} items...');
      for (final item in widget.cartItems) {
        try {
          debugPrint('[Item] Processing item: ${item['menu_items']?['name']}');
          debugPrint('[Item] item_id value: ${item['item_id']}');

          if (item['item_id'] == null) {
            debugPrint('[ERROR] Item missing item_id: $item');
            throw Exception('Null item_id found in cart item');
          }

          final menuItem = item['menu_items'] as Map<String, dynamic>;
          debugPrint('[Item] Price: ${menuItem['price']}, Name: ${menuItem['name']}');

          final insertResult = await supabase.from('order_items').insert({
            'order_id': orderResponse['id'],
            'item_id': item['item_id'],
            'quantity': item['quantity'],
            'price_at_order': menuItem['price'],
            'item_name': menuItem['name'],
            'store_name': item['store_name'],
          });
          debugPrint('[Item] Successfully added to order_items');
        } catch (e) {
          debugPrint('[ERROR] Failed to process item: $e');
          debugPrint('[ERROR] Problematic item data: $item');
          rethrow;
        }
      }

      // Clear cart
      debugPrint('[Cart] Clearing cart for user $userId');
      await supabase.from('cart').delete().eq('user_id', userId);
      debugPrint('[Cart] Cart cleared successfully');

      // Show success message
      if (!mounted) return;

      await _healthService.updateUserCalorie();

      // pop and push
      Navigator.pop(context);
      Navigator.pop(context);
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => const MyOrderView()));

      debugPrint('[UI] Showing success modal');
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (context) => CheckoutMessageView(
          orderId: orderResponse['id'],
          totalAmount: widget.totalAmount,
        ),
      );
      debugPrint('[Order Process] Completed successfully');
    } catch (e) {
      debugPrint('[ERROR] Order processing failed: $e');
      // debugPrint('[ERROR] Stack trace: ${e.stackTrace}');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Order failed: ${e.toString()}')),
      );
    } finally {
      debugPrint('[Status] Setting isLoading to false');
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _fetchUserAddress() async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      final response = await supabase
          .from('profiles')
          .select('address')
          .eq('id', userId)
          .single();

      if (response['address'] != null) {
        setState(() {
          deliveryAddress = response['address'];
        });
      } else {
        setState(() {
          deliveryAddress = "No address set";
        });
      }
    } catch (e) {
      debugPrint('Error fetching address: $e');
      setState(() {
        deliveryAddress = "Error loading address";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TColor.white,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 46),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Image.asset(
                        "assets/img/btn_back.png",
                        width: 20,
                        height: 20,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "Checkout",
                        style: TextStyle(
                          color: TColor.primaryText,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 25),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Delivery Address",
                      style: TextStyle(
                        color: TColor.secondaryText,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            deliveryAddress,
                            style: TextStyle(
                              color: TColor.primaryText,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        TextButton(
                          onPressed: () {
                            // Implement address change logic
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                builder: (context) => const MainTabView(initialTab: 3),
                              )
                            );
                          },
                          child: Text(
                            "Change",
                            style: TextStyle(
                              color: TColor.primary,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Container(
                decoration: BoxDecoration(color: TColor.textBox),
                height: 8,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Payment method",
                          style: TextStyle(
                            color: TColor.secondaryText,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () {
                            // Implement add card logic
                          },
                          icon: Icon(Icons.add, color: TColor.primary),
                          label: Text(
                            "Add Card",
                            style: TextStyle(
                              color: TColor.primary,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    ListView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      itemCount: paymentArr.length,
                      itemBuilder: (context, index) {
                        var pObj = paymentArr[index] as Map? ?? {};
                        return Container(
                          margin: const EdgeInsets.symmetric(vertical: 8.0),
                          padding: const EdgeInsets.symmetric(
                            vertical: 8.0,
                            horizontal: 15.0,
                          ),
                          decoration: BoxDecoration(
                            color: TColor.textBox,
                            borderRadius: BorderRadius.circular(5),
                            border: Border.all(
                              color: TColor.secondaryText.withOpacity(0.2),
                            ),
                          ),
                          child: Row(
                            children: [
                              Image.asset(
                                pObj["icon"].toString(),
                                width: 50,
                                height: 20,
                                fit: BoxFit.contain,
                              ),
                              Expanded(
                                child: Text(
                                  pObj["name"],
                                  style: TextStyle(
                                    color: TColor.primaryText,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              InkWell(
                                onTap: () {
                                  setState(() {
                                    selectMethod = index;
                                  });
                                },
                                child: Icon(
                                  selectMethod == index
                                      ? Icons.radio_button_on
                                      : Icons.radio_button_off,
                                  color: TColor.primary,
                                  size: 15,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Container(
                decoration: BoxDecoration(color: TColor.textBox),
                height: 8,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 15),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Sub Total",
                          style: TextStyle(
                            color: TColor.primaryText,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          "\$${subtotal.toStringAsFixed(2)}",
                          style: TextStyle(
                            color: TColor.primaryText,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Delivery Cost",
                          style: TextStyle(
                            color: TColor.primaryText,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          "\$${deliveryFee.toStringAsFixed(2)}",
                          style: TextStyle(
                            color: TColor.primaryText,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Discount",
                          style: TextStyle(
                            color: TColor.primaryText,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          "-\$${discount.toStringAsFixed(2)}",
                          style: TextStyle(
                            color: TColor.primaryText,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    Divider(
                      color: TColor.secondaryText.withOpacity(0.5),
                      height: 1,
                    ),
                    const SizedBox(height: 15),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Total",
                          style: TextStyle(
                            color: TColor.primaryText,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          "\$${(widget.totalAmount + deliveryFee).toStringAsFixed(2)}",
                          style: TextStyle(
                            color: TColor.primaryText,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Container(
                decoration: BoxDecoration(color: TColor.textBox),
                height: 8,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 25),
                child: RoundButton(
                  title: isLoading ? "Processing..." : "Send Order",
                  onPressed: _buildOnPressedHandler(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}