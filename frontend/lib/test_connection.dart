import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class TestConnectionWidget extends StatefulWidget {
  const TestConnectionWidget({super.key});

  @override
  State<TestConnectionWidget> createState() => _TestConnectionWidgetState();
}

class _TestConnectionWidgetState extends State<TestConnectionWidget> {
  String _status = 'Ready to test';
  bool _isLoading = false;

  Future<void> _testConnection() async {
    setState(() {
      _isLoading = true;
      _status = 'Testing connection...';
    });

    try {
      // Test 1: Health endpoint
      final healthUrl = 'http://192.168.64.73:8080/health';
      print('Testing: $healthUrl');
      
      final healthResponse = await http.get(Uri.parse(healthUrl)).timeout(
        const Duration(seconds: 5),
      );
      
      if (healthResponse.statusCode == 200) {
        setState(() {
          _status = 'Health check: ✅ SUCCESS\nStatus: ${healthResponse.statusCode}\nResponse: ${healthResponse.body}';
        });
        
        // Test 2: Products endpoint
        await Future.delayed(const Duration(seconds: 1));
        final productsUrl = 'http://192.168.64.73:8080/api/products?limit=1';
        print('Testing: $productsUrl');
        
        final productsResponse = await http.get(Uri.parse(productsUrl)).timeout(
          const Duration(seconds: 10),
        );
        
        if (productsResponse.statusCode == 200) {
          final data = json.decode(productsResponse.body);
          setState(() {
            _status = 'Health check: ✅ SUCCESS\nProducts check: ✅ SUCCESS\nStatus: ${productsResponse.statusCode}\nTotal products: ${data['total']}\nFirst product: ${data['data'][0]['name']}';
          });
        } else {
          setState(() {
            _status = 'Health check: ✅ SUCCESS\nProducts check: ❌ FAILED\nStatus: ${productsResponse.statusCode}\nResponse: ${productsResponse.body}';
          });
        }
      } else {
        setState(() {
          _status = 'Health check: ❌ FAILED\nStatus: ${healthResponse.statusCode}\nResponse: ${healthResponse.body}';
        });
      }
    } catch (e) {
      setState(() {
        _status = 'Connection Error: ❌\nError: $e\nError type: ${e.runtimeType}';
      });
      print('Connection error: $e');
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Connection Test'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Backend Connection Test',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text('Testing connection to: http://192.168.64.73:8080'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isLoading ? null : _testConnection,
              child: _isLoading 
                ? const CircularProgressIndicator()
                : const Text('Test Connection'),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    _status,
                    style: const TextStyle(fontFamily: 'monospace'),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
