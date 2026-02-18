import 'package:dar_city_app/models/product.dart';
import 'package:dar_city_app/models/product_variant_model.dart';
import 'package:dar_city_app/services/cart_manager.dart';
import 'package:flutter/material.dart';

class ProductDetailPage extends StatefulWidget {
  final Product product;

  const ProductDetailPage({Key? key, required this.product}) : super(key: key);

  @override
  _ProductDetailPageState createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  ProductVariant? _selectedVariant;

  @override
  void initState() {
    super.initState();
    if (widget.product.variants.isNotEmpty) {
      _selectedVariant = widget.product.variants.first;
    }
  }

  double get discountedPrice {
    final price = _selectedVariant?.price ?? 0;
    if (widget.product.discount == 0) {
      return price;
    }
    return price - (price * widget.product.discount / 100);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 90),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ================= IMAGE HEADER =================
                Stack(
                  children: [
                    Hero(
                      tag: 'product_${widget.product.id}',
                      child: Image.network(
                        widget.product.imageUrl ??
                            'https://via.placeholder.com/600x400',
                        height: 320,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),

                    // Gradient overlay
                    Container(
                      height: 320,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.black.withOpacity(0.9),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),

                    // Back button
                    SafeArea(
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),

                    // Discount badge
                    if (widget.product.discount > 0)
                      Positioned(
                        top: 50,
                        right: 16,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '-${widget.product.discount.toInt()}%',
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                  ],
                ),

                // ================= CONTENT =================
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.product.name,
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),

                      const SizedBox(height: 10),

                      // Category + Stock
                      Wrap(
                        spacing: 10,
                        children: [
                          if (widget.product.category != null)
                            Chip(
                              label: Text(widget.product.category!),
                              backgroundColor: Colors.grey[850],
                              labelStyle:
                              const TextStyle(color: Colors.white70),
                            ),
                          if (_selectedVariant != null)
                            Chip(
                              label: Text(
                                _selectedVariant!.isInStock
                                    ? 'In stock (${_selectedVariant!.stock})'
                                    : 'Out of stock',
                              ),
                              backgroundColor: _selectedVariant!.isInStock
                                  ? Colors.green[700]
                                  : Colors.red[700],
                              labelStyle:
                              const TextStyle(color: Colors.white),
                            ),
                        ],
                      ),

                      const SizedBox(height: 20),
                      if (widget.product.hasVariants)
                        _buildVariantSelector(),

                      const SizedBox(height: 20),

                      // ================= PRICE =================
                      Row(
                        children: [
                          Text(
                            'TZS ${discountedPrice.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 24,
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 10),
                          if (widget.product.discount > 0)
                            Text(
                              'TZS ${(_selectedVariant?.price ?? 0).toStringAsFixed(0)}',
                              style: const TextStyle(
                                color: Colors.white54,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // ================= INFO CARDS =================
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _infoCard(
                              'Delivery', 'TZS ${widget.product.deliveryCost}'),
                          _infoCard('Discount', '${widget.product.discount}%'),
                          _infoCard('SKU', widget.product.sku),
                        ],
                      ),

                      const SizedBox(height: 30),

                      // ================= DESCRIPTION =================
                      const Text(
                        'Description',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        widget.product.description ?? 'No description available.',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                          height: 1.6,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ================= ADD TO CART =================
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.8),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: _selectedVariant != null && _selectedVariant!.isInStock
                    ? () {
                        // TODO: Update CartManager to accept a variant
                        // For now, we add the base product, but you should pass the variant details
                        CartManager().addToCart(widget.product, _selectedVariant!);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text('Added ${widget.product.name} (${_selectedVariant!.displayName}) to cart')),
                        );
                      }
                    : null,
                icon: const Icon(Icons.shopping_cart),
                label: const Text('Add to Cart'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding:
                  const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 18),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVariantSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select Variant:',
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          children: widget.product.variants.map((variant) {
            final isSelected = _selectedVariant?.id == variant.id;
            return ChoiceChip(
              label: Text(variant.displayName),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _selectedVariant = variant;
                  });
                }
              },
              backgroundColor: Colors.grey[800],
              selectedColor: Colors.red,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.white70,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _infoCard(String title, String value) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(title,
                style: const TextStyle(
                    color: Colors.white54, fontSize: 12)),
            const SizedBox(height: 6),
            Text(value,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
