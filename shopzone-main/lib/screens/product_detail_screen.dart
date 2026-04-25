import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../providers/cart_provider.dart';
import '../utils/constants.dart';
import 'reviews_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  final String productId;
  const ProductDetailScreen({super.key, required this.productId});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  Product? _product;
  bool _loading = true;
  int _currentImage = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      _product = await ApiService.getProduct(widget.productId);
    } catch (_) {}
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_product == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Product not found')),
      );
    }
    final p = _product!;

    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(icon: const Icon(Icons.favorite_border), onPressed: () {}),
          IconButton(icon: const Icon(Icons.share_outlined), onPressed: () {}),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              children: [
                // Image carousel
                SizedBox(
                  height: 320,
                  child: PageView.builder(
                    itemCount: p.images.length,
                    onPageChanged: (i) => setState(() => _currentImage = i),
                    itemBuilder: (_, i) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: CachedNetworkImage(
                        imageUrl: p.images[i].url,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
                if (p.images.length > 1)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      p.images.length,
                          (i) => Container(
                        width: 8,
                        height: 8,
                        margin: const EdgeInsets.symmetric(
                            horizontal: 3, vertical: 12),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _currentImage == i
                              ? AppColors.primary
                              : Colors.grey[300],
                        ),
                      ),
                    ),
                  ),

                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Rating — tap to see reviews
                      GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ReviewsScreen(
                                productId: p.id, productName: p.name),
                          ),
                        ),
                        child: Row(
                          children: [
                            ...List.generate(
                                5,
                                    (i) => Icon(
                                  i < p.rating.floor()
                                      ? Icons.star
                                      : Icons.star_border,
                                  color: AppColors.star,
                                  size: 20,
                                )),
                            const SizedBox(width: 8),
                            Text('${p.rating} (${p.reviewCount} reviews)',
                                style: TextStyle(
                                    color: AppColors.textSecondary(context),
                                    fontSize: 13)),
                            const SizedBox(width: 4),
                            Icon(Icons.chevron_right,
                                size: 16,
                                color: AppColors.textSecondary(context)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Name
                      Text(p.name,
                          style: const TextStyle(
                              fontSize: 22, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 12),

                      // Price
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('\$${p.effectivePrice.toStringAsFixed(2)}',
                              style: const TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.accent)),
                          if (p.discountPrice != null) ...[
                            const SizedBox(width: 10),
                            Text('\$${p.price.toStringAsFixed(2)}',
                                style: TextStyle(
                                    fontSize: 16,
                                    color: AppColors.textSecondary(context),
                                    decoration: TextDecoration.lineThrough)),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.accent.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text('Save ${p.discountPercent}%',
                                  style: const TextStyle(
                                      color: AppColors.accent,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600)),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Stock
                      Row(
                        children: [
                          Icon(Icons.check_circle,
                              size: 16,
                              color: p.stock > 0
                                  ? AppColors.success
                                  : AppColors.accent),
                          const SizedBox(width: 4),
                          Text(
                              p.stock > 0
                                  ? 'In Stock (${p.stock})'
                                  : 'Out of Stock',
                              style: TextStyle(
                                  color: p.stock > 0
                                      ? AppColors.success
                                      : AppColors.accent,
                                  fontSize: 13)),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Description
                      const Text('Description',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      Text(p.description ?? 'No description available.',
                          style: TextStyle(
                              color: AppColors.textSecondary(context),
                              fontSize: 14,
                              height: 1.6)),

                      const SizedBox(height: 20),

                      // Reviews button
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ReviewsScreen(
                                  productId: p.id, productName: p.name),
                            ),
                          ),
                          icon: const Icon(Icons.rate_review_outlined),
                          label: Text('See all ${p.reviewCount} reviews'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Bottom bar
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            decoration: BoxDecoration(
              color: AppColors.cardColor(context),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -4))
              ],
            ),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: p.stock > 0
                    ? () async {
                  await context.read<CartProvider>().addItem(p.id);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Added to cart!'),
                          duration: Duration(seconds: 1)),
                    );
                  }
                }
                    : null,
                icon: const Icon(Icons.shopping_bag_outlined),
                label: const Text('Add to Cart'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}