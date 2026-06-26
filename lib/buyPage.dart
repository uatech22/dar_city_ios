import 'dart:async';
import 'package:dar_city_app/config/api_config.dart';
import 'package:dar_city_app/core/widgets/responsive_scaffold.dart';
import 'package:dar_city_app/core/layout/dar_layout_metrics.dart';
import 'package:dar_city_app/core/theme/dar_theme.dart';
import 'package:dar_city_app/fan_premium.dart';
import 'package:dar_city_app/models/category.dart';
import 'package:dar_city_app/models/product.dart';
import 'package:dar_city_app/product_detail_page.dart';
import 'package:dar_city_app/services/cart_manager.dart';
import 'package:dar_city_app/services/product_service.dart';
import 'package:dar_city_app/cart_screen.dart';
import 'package:flutter/material.dart';

class BuyScreen extends StatefulWidget {
  const BuyScreen({super.key});

  @override
  State<BuyScreen> createState() => _BuyScreenState();
}

class _BuyScreenState extends State<BuyScreen> with TickerProviderStateMixin {
  String? _selectedCategory;
  String _searchQuery = '';
  Timer? _debounce;
  Timer? _refreshTimer;
  int _cartItemCount = 0;
  late FanMotion _motion;

  late Future<List<Category>> _categoriesFuture;
  List<Product>? _products;
  bool _productsLoading = true;
  String? _productsError;

  @override
  void initState() {
    super.initState();
    _motion = FanMotion(this);
    _categoriesFuture = ProductService.fetchCategories();
    _fetchProducts();
    _updateCartCount();
    _refreshTimer = Timer.periodic(ApiConfig.refreshIntervalSlow, (_) => _fetchProducts(showLoading: false));
  }

  @override
  void dispose() {
    _motion.dispose();
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
    final layout = DarLayoutMetrics.of(context);
    return Scaffold(
      backgroundColor: DarColors.background,
      appBar: AppBar(
        title: const Text(
          'Official Shop',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
        ),
        centerTitle: true,
        backgroundColor: Colors.black,
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_bag_outlined),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CartScreen()),
                  ).then((_) => _updateCartCount());
                },
              ),
              if (_cartItemCount > 0)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: DarColors.accentRed,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text(
                      '$_cartItemCount',
                      style: const TextStyle(color: Colors.white, fontSize: 10),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: darResponsiveBody(
        Padding(
        padding: EdgeInsets.fromLTRB(
          layout.horizontalPadding,
          12,
          layout.horizontalPadding,
          layout.useNavigationRail ? 16 : 16,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FanAccentPanel(
              motion: _motion,
              compact: true,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Rep Dar City — official merch',
                      style: TextStyle(
                        color: DarColors.muted.withValues(alpha: 0.95),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Icon(Icons.storefront_rounded, color: DarColors.accentRed, size: 22),
                ],
              ),
            ),
            const SizedBox(height: 12),
            FanSearchField(
              hint: 'Search for products...',
              onChanged: _onSearchChanged,
            ),
            const SizedBox(height: 16),
            _buildCategoryFilters(),
            const SizedBox(height: 16),
            Expanded(child: _buildProductGrid()),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildProductGrid() {
    if (_productsLoading) {
      return const Center(child: CircularProgressIndicator(color: DarColors.accentRed));
    }
    if (_productsError != null) {
      return FanEmptyState(
        icon: Icons.error_outline_rounded,
        message: 'Could not load products',
      );
    }
    if (_products == null || _products!.isEmpty) {
      return const FanEmptyState(
        icon: Icons.inventory_2_outlined,
        message: 'No products found',
      );
    }
    final layout = DarLayoutMetrics.of(context);
    return GridView.builder(
      itemCount: _products!.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: layout.shopGridColumns,
        childAspectRatio: layout.shopGridAspectRatio,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemBuilder: (context, index) {
        return ProductCard(
          product: _products![index],
          onAddToCart: _updateCartCount,
        );
      },
    );
  }

  Widget _buildCategoryFilters() {
    return FutureBuilder<List<Category>>(
      future: _categoriesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(height: 40);
        }
        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox(height: 40);
        }

        final categories = [Category(name: 'All'), ...snapshot.data!];
        return SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: categories.length,
            separatorBuilder: (_, __) => const SizedBox(width: 2),
            itemBuilder: (context, index) {
              final category = categories[index];
              final isSelected = (_selectedCategory == null && category.name == 'All') ||
                  _selectedCategory == category.name;

              return FanFilterChip(
                label: category.name,
                selected: isSelected,
                onTap: () {
                  setState(() {
                    _selectedCategory = category.name == 'All' ? null : category.name;
                    _fetchProducts();
                  });
                },
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
        ).then((_) => onAddToCart());
      },
      child: Container(
        decoration: BoxDecoration(
          color: DarColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  product.imageUrl != null
                      ? Image.network(
                          product.imageUrl!,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        )
                      : Container(color: DarColors.cardDark),
                  if (product.discount > 0)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: DarColors.accentRed,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '-${product.discount.toInt()}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                ],
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
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 6,
                    children: [
                      Text(
                        'TZS ${discountedDisplayPrice.toStringAsFixed(0)}',
                        style: const TextStyle(
                          color: DarColors.accentRed,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (product.discount > 0)
                        Text(
                          'TZS ${displayPrice.toStringAsFixed(0)}',
                          style: TextStyle(
                            color: DarColors.muted.withValues(alpha: 0.7),
                            decoration: TextDecoration.lineThrough,
                            fontSize: 11,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ProductDetailPage(product: product),
                          ),
                        ).then((_) => onAddToCart());
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: DarColors.accentRed,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        product.hasVariants ? 'View Options' : 'View Details',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                      ),
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
