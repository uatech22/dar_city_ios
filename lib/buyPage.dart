import 'dart:async';
import 'package:dar_city_app/models/category.dart';
import 'package:dar_city_app/models/product.dart';
import 'package:dar_city_app/product_detail_page.dart';
import 'package:dar_city_app/services/cart_manager.dart';
import 'package:dar_city_app/services/product_service.dart';
import 'package:dar_city_app/cart_screen.dart'; // Import the cart screen
import 'package:flutter/material.dart';

class BuyScreen extends StatefulWidget {
  const BuyScreen({super.key});

  @override
  State<BuyScreen> createState() => _BuyScreenState();
}

class _BuyScreenState extends State<BuyScreen> {
  String? _selectedCategory;
  String _searchQuery = '';
  Timer? _debounce;
  Timer? _refreshTimer;
  int _cartItemCount = 0;

  late Future<List<Category>> _categoriesFuture;
  List<Product>? _products;
  bool _productsLoading = true;
  String? _productsError;

  @override
  void initState() {
    super.initState();
    _categoriesFuture = ProductService.fetchCategories();
    _fetchProducts();
    _updateCartCount();
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (_) => _fetchProducts(showLoading: false));
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _updateCartCount() {
    setState(() {
      _cartItemCount = CartManager().items.length;
    });
  }

  void _fetchProducts({bool showLoading = true}) {
    if (showLoading) {
      setState(() {
        _productsLoading = true;
      });
    }
    ProductService.fetchProducts(
      category: _selectedCategory,
      search: _searchQuery,
    ).then((products) {
      if (mounted) {
        setState(() {
          _products = products;
          _productsLoading = false;
        });
      }
    }).catchError((e) {
      if (mounted) {
        setState(() {
          _productsError = e.toString();
          _productsLoading = false;
        });
      }
    });
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      setState(() {
        _searchQuery = query;
        _fetchProducts();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Buy'),
        centerTitle: true,
        backgroundColor: Colors.black, // Corrected color
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CartScreen()),
                  ).then((_) => _updateCartCount()); // Update count on return
                },
              ),
              if (_cartItemCount > 0)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red, // Corrected color
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '$_cartItemCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              onChanged: _onSearchChanged,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search for products...',
                hintStyle: const TextStyle(color: Colors.white70),
                prefixIcon: const Icon(Icons.search, color: Colors.white70),
                filled: true,
                fillColor: const Color(0xFF1A1A1A),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 20),
            _buildCategoryFilters(),
            const SizedBox(height: 20),
            Expanded(
              child: _buildProductGrid(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductGrid() {
    if (_productsLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_productsError != null) {
      return Center(child: Text('Error: $_productsError'));
    }
    if (_products == null || _products!.isEmpty) {
      return const Center(child: Text('No products found.'));
    }
    return GridView.builder(
      itemCount: _products!.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.62,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemBuilder: (context, index) {
        return ProductCard(
          product: _products![index],
          onAddToCart: _updateCartCount, // Pass callback
        );
      },
    );
  }

  Widget _buildCategoryFilters() {
    return FutureBuilder<List<Category>>(
      future: _categoriesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(height: 45);
        }
        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox(height: 45);
        }

        final categories = [Category(name: 'All'), ...snapshot.data!];
        return SizedBox(
          height: 45,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: categories.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final category = categories[index];
              final isSelected = (_selectedCategory == null && category.name == 'All') ||
                  _selectedCategory == category.name;

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedCategory = category.name == 'All' ? null : category.name;
                    _fetchProducts();
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.red : const Color(0xFF1A1A1A), // Corrected color
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Text(
                    category.name,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.white70,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onAddToCart;

  const ProductCard({super.key, required this.product, required this.onAddToCart});

  @override
  Widget build(BuildContext context) {
    final displayPrice = product.minPrice;
    final discountedDisplayPrice = (product.discount > 0)
        ? displayPrice - (displayPrice * product.discount / 100)
        : displayPrice;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProductDetailPage(product: product),
          ),
        ).then((_) => onAddToCart()); // Update cart on return from details
      },
      child: Card(
        color: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
                child: product.imageUrl != null
                    ? Image.network(
                        product.imageUrl!,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      )
                    : Container(color: Colors.grey.shade800),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8.0,
                    children: [
                      Text(
                        'TZS ${discountedDisplayPrice.toStringAsFixed(0)}',
                        style: const TextStyle(color: Colors.red, fontSize: 14, fontWeight: FontWeight.bold), // Corrected color
                      ),
                      if (product.discount > 0)
                        Text(
                          'TZS ${displayPrice.toStringAsFixed(0)}',
                          style: const TextStyle(
                            color: Colors.white54,
                            decoration: TextDecoration.lineThrough,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        // Always navigate to details page to select variant
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ProductDetailPage(product: product),
                          ),
                        ).then((_) => onAddToCart());
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red), // Corrected color
                      child: Text(product.hasVariants ? 'View Options' : 'View Details'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
