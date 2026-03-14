import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../common/color_extension.dart';
import '../common_widget/round_button.dart';
import 'checkout_view.dart';

class MyOrderView extends StatefulWidget {
  const MyOrderView({super.key});

  @override
  State<MyOrderView> createState() => _MyOrderViewState();
}

class _MyOrderViewState extends State<MyOrderView> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> cartItems = [];
  Map<String, List<Map<String, dynamic>>> storeItems = {};
  bool isLoading = true;
  double totalAmount = 0;
  final Map<String, GlobalKey> _storeKeys = {};

  @override
  void initState() {
    super.initState();
    _fetchCartItems();
  }

  Future<void> _fetchCartItems() async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      setState(() => isLoading = true);

      final response = await supabase
          .from('cart')
          .select('''
            id, 
            item_id,
            quantity, 
            created_at,
            store_name,
            menu_items:item_id(name, price, image_url, rating, category_id)
          ''')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      if (response.isNotEmpty) {
        final Map<String, List<Map<String, dynamic>>> groupedItems = {};
        double total = 0;

        for (final item in response) {
          final store = item['store_name'] as String? ?? 'Unknown Store';
          // final itemId = item['item_id'];
          final menuItem = item['menu_items'] as Map<String, dynamic>;
          final price = (menuItem['price'] as num).toDouble();
          final quantity = (item['quantity'] as num).toInt();
          total += price * quantity;

          if (!groupedItems.containsKey(store)) {
            groupedItems[store] = [];
            _storeKeys[store] = GlobalKey();
          }
          groupedItems[store]!.add(item);
        }

        setState(() {
          storeItems = groupedItems;
          cartItems = List<Map<String, dynamic>>.from(response);
          totalAmount = total;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading cart: ${e.toString()}')),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _deleteItem(String itemId, String storeName) async {
    try {
      // Store the item being deleted for potential undo
      final itemToDelete = cartItems.firstWhere((item) => item['id'] == itemId);
      final storeItemsBefore = List<Map<String, dynamic>>.from(storeItems[storeName]!);

      // Capture values needed for undo
      final menuItem = itemToDelete['menu_items'] as Map<String, dynamic>;
      final price = (menuItem['price'] as num).toDouble();
      final quantity = (itemToDelete['quantity'] as num).toInt();
      final itemTotal = price * quantity;

      // Optimistic UI update
      setState(() {
        storeItems[storeName]!.removeWhere((item) => item['id'] == itemId);
        if (storeItems[storeName]!.isEmpty) {
          storeItems.remove(storeName);
          _storeKeys.remove(storeName);
        }
        cartItems.removeWhere((item) => item['id'] == itemId);
        totalAmount -= itemTotal;
      });

      // Show undo snackbar with captured values
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Item removed from cart'),
          action: SnackBarAction(
            label: 'UNDO',
            textColor: Colors.white,
            onPressed: () async {
              // Undo the deletion using captured values
              setState(() {
                if (!storeItems.containsKey(storeName)) {
                  storeItems[storeName] = storeItemsBefore;
                  _storeKeys[storeName] = GlobalKey();
                } else {
                  storeItems[storeName] = storeItemsBefore;
                }
                cartItems.add(itemToDelete);
                totalAmount += itemTotal;
              });
            },
          ),
          duration: const Duration(seconds: 3),
        ),
      );

      // Actually delete from database
      await supabase.from('cart').delete().eq('id', itemId);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to remove item: ${e.toString()}')),
      );
      _fetchCartItems(); // Refresh if error occurs
    }
  }

  Widget _buildStoreSection(String storeName, List<Map<String, dynamic>> items) {
    double storeSubtotal = 0;

    return Column(
      key: _storeKeys[storeName],
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  "assets/img/family_combo.jpg",
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      storeName,
                      style: TextStyle(
                        color: TColor.primaryText,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.star, color: Colors.amber, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          "4.8",
                          style: TextStyle(
                            color: TColor.primaryText,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "• Western Food",
                          style: TextStyle(
                            color: TColor.secondaryText,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ListView.separated(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            padding: EdgeInsets.zero,
            itemCount: items.length,
            separatorBuilder: (context, index) => Divider(
              height: 1,
              indent: 20,
              endIndent: 20,
              color: Colors.grey.shade200,
            ),
            itemBuilder: (context, index) {
              final item = items[index];
              final menuItem = item['menu_items'] as Map<String, dynamic>;
              final price = (menuItem['price'] as num).toDouble();
              final quantity = (item['quantity'] as num).toInt();
              final itemTotal = price * quantity;
              storeSubtotal += itemTotal;

              return Dismissible(
                key: Key(item['id'].toString()),
                direction: DismissDirection.endToStart,
                background: Container(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.red.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  child: const Icon(Icons.delete, color: Colors.red),
                ),
                confirmDismiss: (direction) async {
                  return await showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text("Remove Item"),
                      content: const Text("Are you sure you want to remove this item from your cart?"),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text("CANCEL"),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text("REMOVE", style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  );
                },
                onDismissed: (direction) {
                  _deleteItem(item['id'].toString(), storeName);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          menuItem['image_url'] as String? ?? '',
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 50,
                            height: 50,
                            color: Colors.grey.shade200,
                            child: const Icon(Icons.fastfood),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              menuItem['name'] as String? ?? 'Unknown Item',
                              style: TextStyle(
                                color: TColor.primaryText,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "\$${price.toStringAsFixed(2)}",
                              style: TextStyle(
                                color: TColor.secondaryText,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        "x$quantity",
                        style: TextStyle(
                          color: TColor.primaryText,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        "\$${itemTotal.toStringAsFixed(2)}",
                        style: TextStyle(
                          color: TColor.primaryText,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 20),
                        color: Colors.grey,
                        onPressed: () async {
                          final shouldDelete = await showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text("Remove Item"),
                              content: const Text("Are you sure you want to remove this item from your cart?"),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context, false),
                                  child: const Text("CANCEL"),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text("REMOVE", style: TextStyle(color: Colors.red)),
                                ),
                              ],
                            ),
                          );
                          if (shouldDelete ?? false) {
                            _deleteItem(item['id'].toString(), storeName);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: TColor.primaryText),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "My Cart (${cartItems.length})",
          style: TextStyle(
            color: TColor.primaryText,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : cartItems.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shopping_cart_outlined,
                size: 60, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              "Your cart is empty",
              style: TextStyle(
                color: TColor.secondaryText,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Browse restaurants and add items to get started",
              style: TextStyle(
                color: TColor.secondaryText,
                fontSize: 14,
              ),
            ),
          ],
        ),
      )
          : SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 8),
            ...storeItems.entries.map((entry) =>
                _buildStoreSection(entry.key, entry.value)
            ).toList(),
            const SizedBox(height: 16),
          ],
        ),
      ),
      bottomNavigationBar: cartItems.isEmpty
          ? null
          : Container(
        padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Delivery Fee",
                  style: TextStyle(
                    color: TColor.secondaryText,
                    fontSize: 14,
                  ),
                ),
                Text(
                  "\$2.00",
                  style: TextStyle(
                    color: TColor.primaryText,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Total",
                  style: TextStyle(
                    color: TColor.primaryText,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  "\$${(totalAmount + 2.0).toStringAsFixed(2)}",
                  style: TextStyle(
                    color: TColor.primary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: RoundButton(
                title: "Proceed to Checkout (${cartItems.length})",
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CheckoutView(
                        cartItems: cartItems,          // Pass the full cart items list
                        totalAmount: totalAmount,  // Subtotal + delivery fee
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}