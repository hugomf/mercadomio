import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class Product {
  final String id;
  final String name;
  final double price;
  final String imageUrl;

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.imageUrl,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    
    double parsePrice(dynamic price) {
      if (price == null) return 0.0;
      if (price is double) return price;
      if (price is int) return price.toDouble();
      if (price is String) return double.tryParse(price) ?? 0.0;
      return 0.0;
    }

    String parseString(dynamic value, [String defaultValue = '']) {
      if (value == null) return defaultValue;
      if (value is String) return value;
      return value.toString();
    }

    return Product(
      id: parseString(json['id'], 'unknown'),
      name: parseString(json['name'], 'Unnamed Product'),
      price: parsePrice(json['price']),
      imageUrl: parseString(json['imageUrl'], ''),
    );
  }
}

class ProductListingWidget extends StatefulWidget {
  final List<Product>? initialProducts;

  const ProductListingWidget({
    super.key,
    this.initialProducts,
  });

  @override
  ProductListingWidgetState createState() => ProductListingWidgetState();
}

class ProductListingWidgetState extends State<ProductListingWidget> {
  List<Product> products = [];
  bool isLoading = true;
  int currentPage = 1;
  bool hasMore = true;
  final int itemsPerPage = 10;

  @override
  void initState() {
    super.initState();
    if (widget.initialProducts == null) {
      _fetchProducts();
    } else {
      setState(() {
        products = widget.initialProducts!;
        isLoading = false;
      });
    }
  }

  void updateProducts(List<Product> filteredProducts) {
    if (mounted) {
      setState(() {
        products = filteredProducts;
      });
    }
  }

  Future<void> _fetchProducts({bool loadMore = false}) async {
    try {
      await dotenv.load();
      final apiUrl = dotenv.env['API_URL'] ?? 'http://localhost:8080';
      final response = await http.get(
        Uri.parse('$apiUrl/api/products?page=$currentPage&limit=$itemsPerPage')
      );
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        final List<dynamic> productsData = responseData['data'];
        final int totalItems = responseData['meta']['totalItems'];
        
        setState(() {
          if (loadMore) {
            products.addAll(productsData.map((json) => Product.fromJson(json)));
          } else {
            products = productsData.map((json) => Product.fromJson(json)).toList();
          }
          hasMore = products.length < totalItems;
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load products: $e')),
        );
      }
    }
  }

  void _loadMoreProducts() {
    if (hasMore && !isLoading) {
      setState(() {
        currentPage++;
        isLoading = true;
      });
      _fetchProducts(loadMore: true);
    }
  }

  void refreshProducts() {
    setState(() {
      currentPage = 1;
      isLoading = true;
      products = [];
    });
    _fetchProducts();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (ScrollNotification scrollInfo) {
        if (scrollInfo.metrics.pixels == scrollInfo.metrics.maxScrollExtent && hasMore) {
          _loadMoreProducts();
        }
        return false;
      },
      child: ListView.builder(
        itemCount: products.length + (hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == products.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(8.0),
                child: CircularProgressIndicator(),
              ),
            );
          }
        final product = products[index];
        return Card(
          child: ListTile(
            leading: Image.network(product.imageUrl),
            title: Text(product.name),
            subtitle: Text('\$${product.price.toStringAsFixed(2)}'),
            trailing: IconButton(
              icon: const Icon(Icons.add_shopping_cart),
              onPressed: () async {
                final scaffoldMessenger = ScaffoldMessenger.of(context);
                try {
                  final apiUrl = dotenv.env['API_URL'] ?? 'http://localhost:8080';
                  final response = await http.post(
                    Uri.parse('$apiUrl/api/cart'),
                    body: json.encode({
                      'productId': product.id,
                      'quantity': 1,
                      'price': product.price
                    }),
                    headers: {'Content-Type': 'application/json'},
                  );

                  if (response.statusCode == 200) {
                    if (mounted) {
                      scaffoldMessenger.showSnackBar(
                        SnackBar(content: Text('Added ${product.name} to cart')),
                      );
                    }
                  } else {
                    throw Exception('Failed to add to cart');
                  }
                } catch (e) {
                  if (mounted) {
                    scaffoldMessenger.showSnackBar(
                      SnackBar(content: Text('Failed to add to cart: $e')),
                    );
                  }
                }
              },
            ),
          ),
        );
      },
      ),
    );
  }
}
