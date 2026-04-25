import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../utils/constants.dart';

class ReviewsScreen extends StatefulWidget {
  final String productId;
  final String productName;
  const ReviewsScreen({super.key, required this.productId, required this.productName});

  @override
  State<ReviewsScreen> createState() => _ReviewsScreenState();
}

class _ReviewsScreenState extends State<ReviewsScreen> {
  List<dynamic> _reviews = [];
  List<dynamic> _stats = [];
  bool _loading = true;
  String _sort = 'recent';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await ApiService.getReviews(widget.productId, sort: _sort);
      _reviews = data['reviews'];
      _stats = data['stats'];
    } catch (_) {}
    setState(() => _loading = false);
  }

  double get _averageRating {
    if (_reviews.isEmpty) return 0;
    final sum = _reviews.fold<int>(0, (s, r) => s + (r['rating'] as int));
    return sum / _reviews.length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reviews')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddReviewSheet(context),
        backgroundColor: AppColors.accent,
        icon: const Icon(Icons.rate_review, color: Colors.white),
        label: const Text('Write Review', style: TextStyle(color: Colors.white)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
            ),
            child: Row(
              children: [
                Column(
                  children: [
                    Text(_averageRating.toStringAsFixed(1),
                        style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w800)),
                    Row(
                      children: List.generate(5, (i) => Icon(
                        i < _averageRating.round() ? Icons.star : Icons.star_border,
                        color: AppColors.star, size: 20,
                      )),
                    ),
                    const SizedBox(height: 4),
                    Text('${_reviews.length} reviews',
                        style: TextStyle(color: AppColors.textSecondary(context), fontSize: 13)),
                  ],
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: Column(
                    children: List.generate(5, (i) {
                      final star = 5 - i;
                      final count = _stats.firstWhere(
                            (s) => s['rating'] == star,
                        orElse: () => {'count': 0},
                      )['count'] as int;
                      final pct = _reviews.isNotEmpty ? count / _reviews.length : 0.0;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          children: [
                            Text('$star', style: const TextStyle(fontSize: 12)),
                            const Icon(Icons.star, size: 12, color: AppColors.star),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: pct,
                                  backgroundColor: Colors.grey[200],
                                  color: AppColors.star,
                                  minHeight: 8,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(width: 24, child: Text('$count', style: const TextStyle(fontSize: 12))),
                          ],
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              children: [
                const Text('Sort by: ', style: TextStyle(fontWeight: FontWeight.w500)),
                const SizedBox(width: 8),
                ...[
                  ('recent', 'Recent'),
                  ('rating_high', 'Highest'),
                  ('rating_low', 'Lowest'),
                  ('helpful', 'Helpful'),
                ].map((e) => Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: Text(e.$2, style: const TextStyle(fontSize: 12)),
                    selected: _sort == e.$1,
                    onSelected: (_) { _sort = e.$1; _load(); },
                    selectedColor: AppColors.primary,
                    labelStyle: TextStyle(color: _sort == e.$1 ? Colors.white : null),
                    visualDensity: VisualDensity.compact,
                  ),
                )),
              ],
            ),
          ),

          if (_reviews.isEmpty)
            Center(child: Padding(
              padding: EdgeInsets.all(32),
              child: Text('No reviews yet. Be the first!', style: TextStyle(color: AppColors.textSecondary(context))),
            )),
          ..._reviews.map((r) => _ReviewCard(review: r, onHelpful: () async {
            await ApiService.markHelpful(r['id']);
            _load();
          })),
        ],
      ),
    );
  }

  void _showAddReviewSheet(BuildContext context) {
    int rating = 5;
    final titleCtrl = TextEditingController();
    final commentCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Write a Review', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(widget.productName, style: TextStyle(color: AppColors.textSecondary(context))),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) => GestureDetector(
                  onTap: () => setSheetState(() => rating = i + 1),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(i < rating ? Icons.star : Icons.star_border, color: AppColors.star, size: 36),
                  ),
                )),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: titleCtrl,
                decoration: InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: commentCtrl,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: 'Your review',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    try {
                      await ApiService.addReview(widget.productId, rating, titleCtrl.text, commentCtrl.text);
                      if (ctx.mounted) Navigator.pop(ctx);
                      _load();
                    } catch (e) {
                      if (ctx.mounted) {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
                        );
                      }
                    }
                  },
                  child: const Text('Submit Review'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final Map<String, dynamic> review;
  final VoidCallback onHelpful;
  const _ReviewCard({required this.review, required this.onHelpful});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.primary.withOpacity(0.1),
                child: Text((review['full_name'] ?? 'U')[0].toUpperCase(),
                    style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.primary)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(review['full_name'] ?? 'User',
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                        if (review['verified_purchase'] == true) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.success.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text('Verified', style: TextStyle(fontSize: 10, color: AppColors.success, fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ],
                    ),
                    Row(
                      children: [
                        ...List.generate(5, (i) => Icon(
                          i < review['rating'] ? Icons.star : Icons.star_border,
                          size: 14, color: AppColors.star,
                        )),
                        const SizedBox(width: 6),
                        Text(review['created_at']?.toString().substring(0, 10) ?? '',
                            style: TextStyle(fontSize: 11, color: AppColors.textSecondary(context))),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (review['title'] != null) ...[
            const SizedBox(height: 10),
            Text(review['title'], style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
          if (review['comment'] != null) ...[
            const SizedBox(height: 6),
            Text(review['comment'], style: TextStyle(color: AppColors.textSecondary(context), height: 1.5)),
          ],
          const SizedBox(height: 10),
          GestureDetector(
            onTap: onHelpful,
            child: Row(
              children: [
                Icon(Icons.thumb_up_outlined, size: 16, color: AppColors.textSecondary(context)),
                const SizedBox(width: 4),
                Text('Helpful (${review['helpful_count'] ?? 0})',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary(context))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}