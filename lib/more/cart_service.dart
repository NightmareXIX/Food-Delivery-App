import 'package:supabase/supabase.dart';
import 'dart:developer' as developer;

class CartService {
  final SupabaseClient supabase;
  static const String _tag = "CartService";

  CartService(this.supabase);

  Future<void> addToCart({
    required String userId,
    required int itemId,    // changed to int here
    required String storeName,
    required int quantity,
  }) async {
    try {
      developer.log('Adding to cart - userId: $userId, itemId: $itemId, quantity: $quantity', name: _tag);

      final existingItem = await supabase
          .from('cart')
          .select()
          .eq('user_id', userId)
          .eq('item_id', itemId)
          .maybeSingle();

      if (existingItem != null) {
        final currentQty = existingItem['quantity'] as int;
        final newQty = currentQty + quantity;

        await supabase
            .from('cart')
            .update({
          'quantity': newQty,
          'created_at': DateTime.now().toIso8601String(),
        })
            .eq('id', existingItem['id'].toString());
      } else {
        await supabase.from('cart').insert({
          'user_id': userId,
          'item_id': itemId,
          'store_name': storeName,
          'quantity': quantity,
          'created_at': DateTime.now().toIso8601String(),
        });
      }
    } catch (e, stackTrace) {
      developer.log('Add to cart error: $e', name: _tag, error: e, stackTrace: stackTrace);
      throw Exception('Failed to add to cart: ${e.toString()}');
    }
  }


  Future<List<Map<String, dynamic>>> getCartItems(String userId) async {
    try {
      developer.log('Fetching cart items for user: $userId', name: _tag);

      final response = await supabase
          .from('cart')
          .select('''
          id,
          item_id,  // Explicitly selected
          quantity,
          store_name,
          created_at,
          menu_items:item_id(name, price, image_url, category_id)
        ''')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      developer.log('Successfully fetched ${response.length} cart items', name: _tag);

      // Validate structure
      for (final item in response) {
        if (item['item_id'] == null) {
          developer.log('WARNING: Cart item missing item_id: $item', name: _tag);
        }
      }

      return response as List<Map<String, dynamic>>;
    } catch (e, stackTrace) {
      developer.log('Error fetching cart items: ${e.toString()}',
          name: _tag, error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<void> removeFromCart(String cartItemId) async {
    try {
      developer.log('Attempting to remove cart item: $cartItemId', name: _tag);

      final response = await supabase
          .from('cart')
          .delete()
          .eq('id', cartItemId)
          .select();

      developer.log(
          'Successfully removed cart item. Response: $response',
          name: _tag
      );
    } catch (e, stackTrace) {
      developer.log(
          'Error removing cart item: ${e.toString()}',
          name: _tag,
          error: e,
          stackTrace: stackTrace
      );
      rethrow;
    }
  }

  Future<void> updateCartItemQuantity(String cartItemId, int newQuantity) async {
    try {
      developer.log(
          'Updating cart item $cartItemId quantity to $newQuantity',
          name: _tag
      );

      final response = await supabase
          .from('cart')
          .update({'quantity': newQuantity})
          .eq('id', cartItemId)
          .select();

      developer.log(
          'Quantity update successful. Response: $response',
          name: _tag
      );
    } catch (e, stackTrace) {
      developer.log(
          'Error updating quantity: ${e.toString()}',
          name: _tag,
          error: e,
          stackTrace: stackTrace
      );
      rethrow;
    }
  }
}