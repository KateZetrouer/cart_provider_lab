// main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CartModel()),
        // You could add more models here later (e.g., UserModel, ThemeModel).
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mini Cart — Provider (3 layers)',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const HomeScreen(),
    );
  }
}

/* ---------------------- Shared State (Business Logic) ---------------------- */

class CartModel extends ChangeNotifier {
  final Map<String, double> _productPrices = {
    'Apples': 1.50,
    'Bananas': 0.99,
    'Cookies': 3.25,
    'Milk': 2.25,
    'Bread': 2.00,
  };

  final List<String> _items = [];
  List<String> get items => List.unmodifiable(_items);
  
  // Used for details page
  double getPrice(String name) => _productPrices[name] ?? 0.0;

  double get totalPrice => _items.fold(
    0.0,
    (sum, item) => sum + (_productPrices[item] ?? 0),
  );

  int get count => _items.length;

  void add(String item) {
    _items.add(item);
    notifyListeners(); // 🔔 rebuilds listeners
  }

  void remove(String item) {
    _items.remove(item);
    notifyListeners();
  }
}

/* --------------------------------- UI ------------------------------------- */

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final products = const ['Apples', 'Bananas', 'Cookies', 'Milk', 'Bread'];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Shop — Provider (3 layers)'),
        actions: [
          // Only this badge needs to react to changes ⇒ watch()
          InkWell(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CartScreen()),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const Icon(Icons.shopping_cart, size: 28),
                  Positioned(
                    right: 0,
                    child: CircleAvatar(
                      radius: 10,
                      backgroundColor: Colors.red,
                      child: Text(
                        context.watch<CartModel>().count.toString(), // 👈 watch
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),

      // ⬇️ No callbacks passed. ProductList can access CartModel via context.
      body: ProductList(products: products),
    );
  }
}

// Middle layer — doesn’t need cart or callbacks anymore
class ProductList extends StatelessWidget {
  const ProductList({super.key, required this.products});
  final List<String> products;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: products.map((p) => ProductTile(name: p)).toList(),
    );
  }
}

// Leaf widget — directly updates shared state
class ProductTile extends StatelessWidget {
  const ProductTile({super.key, required this.name});
  final String name;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(name),
      // navigate to details page
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_)=> ProductDetailScreen(name: name),
        ),
      ),
      trailing: ElevatedButton(
        // Action only; button itself doesn’t need to rebuild ⇒ read()
        onPressed: () => context.read<CartModel>().add(name), // 👈 read
        child: const Text('Add'),
      ),
    );
  }
}

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Whole screen should update when the cart changes ⇒ watch()
    final cart = context.watch<CartModel>(); // 👈 watch

    return Scaffold(
      appBar: AppBar(title: const Text('Your Cart')),
      body: Column(
        children: [
          Expanded (
            child: ListView.builder(
              itemCount: cart.items.length,
              itemBuilder: (context, index) {
                final item = cart.items[index];
                return ListTile(
                  title: Text(item),
                  trailing: IconButton(
                    icon: const Icon(Icons.remove_circle_outline),
                    // Action only ⇒ read()
                    onPressed: () =>
                    context.read<CartModel>().remove(item), // 👈 read
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Total: \$${cart.totalPrice.toStringAsFixed(2)}',
            ),
          ),
        ],
      ),
    );
  }
}

// 4th Layer page

class ProductDetailScreen extends StatelessWidget {
    const ProductDetailScreen({super.key, required this.name});
    final String name;

    @override
    Widget build(BuildContext context) {
      // build details page with add to cart functions
      final cart = context.read<CartModel>();
      final price = context.watch<CartModel>().getPrice(name);

      return Scaffold(
        appBar: AppBar(title: const Text('Product Details')),
        body: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
              ),
              const SizedBox(height: 8),
              Text(
                '\$${price.toStringAsFixed(2)}',
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  cart.add(name);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('$name added to cart')),
                  );
                  Navigator.pop(context);
                },
                child: const Text('Add to Cart'),
              ),
            ],
          ),
        ),
      );
    }

}
