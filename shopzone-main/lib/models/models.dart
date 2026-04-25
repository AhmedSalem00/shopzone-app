class Product {
  final String id;
  final String name;
  final String? description;
  final double price;
  final double? discountPrice;
  final int? categoryId;
  final int stock;
  final double rating;
  final int reviewCount;
  final bool isFeatured;
  final List<ProductImage> images;

  Product({
    required this.id,
    required this.name,
    this.description,
    required this.price,
    this.discountPrice,
    this.categoryId,
    this.stock = 0,
    this.rating = 0,
    this.reviewCount = 0,
    this.isFeatured = false,
    this.images = const [],
  });

  double get effectivePrice => discountPrice ?? price;
  int get discountPercent =>
      discountPrice != null ? ((1 - discountPrice! / price) * 100).round() : 0;
  String get primaryImage =>
      images.firstWhere((i) => i.isPrimary, orElse: () => images.first).url;

  factory Product.fromJson(Map<String, dynamic> json) => Product(
    id: json['id'],
    name: json['name'],
    description: json['description'],
    price: double.parse(json['price'].toString()),
    discountPrice: json['discount_price'] != null
        ? double.parse(json['discount_price'].toString())
        : null,
    categoryId: json['category_id'],
    stock: json['stock'] ?? 0,
    rating: double.parse((json['rating'] ?? 0).toString()),
    reviewCount: json['review_count'] ?? 0,
    isFeatured: json['is_featured'] ?? false,
    images: (json['images'] as List? ?? [])
        .map((i) => ProductImage.fromJson(i))
        .toList(),
  );
}

class ProductImage {
  final String url;
  final bool isPrimary;

  ProductImage({required this.url, this.isPrimary = false});

  factory ProductImage.fromJson(Map<String, dynamic> json) => ProductImage(
    url: json['url'],
    isPrimary: json['is_primary'] ?? false,
  );
}

class CartItem {
  final int id;
  final String productId;
  final String name;
  final double price;
  final double? discountPrice;
  final String? image;
  int quantity;

  CartItem({
    required this.id,
    required this.productId,
    required this.name,
    required this.price,
    this.discountPrice,
    this.image,
    this.quantity = 1,
  });

  double get effectivePrice => discountPrice ?? price;
  double get total => effectivePrice * quantity;

  factory CartItem.fromJson(Map<String, dynamic> json) => CartItem(
    id: json['id'],
    productId: json['product_id'],
    name: json['name'],
    price: double.parse(json['price'].toString()),
    discountPrice: json['discount_price'] != null
        ? double.parse(json['discount_price'].toString())
        : null,
    image: json['image'],
    quantity: json['quantity'] ?? 1,
  );
}

class Category {
  final int id;
  final String name;
  final String? icon;

  Category({required this.id, required this.name, this.icon});

  factory Category.fromJson(Map<String, dynamic> json) => Category(
    id: json['id'],
    name: json['name'],
    icon: json['icon'],
  );
}