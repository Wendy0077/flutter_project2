import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_project1/tab_menu.dart';

/// Proxy สำหรับเลี่ยง CORS เวลาโหลดรูป
const String kCorsProxy = 'https://cors-anywhere.herokuapp.com/';

class UserDetailPage extends StatefulWidget {
  final int id;
  const UserDetailPage({super.key, required this.id});

  @override
  State<UserDetailPage> createState() => _UserDetailPageState();
}

class _UserDetailPageState extends State<UserDetailPage> {
  Map<String, dynamic>? _carDetail;
  bool _loading = true;
  bool _error = false;
  DateTimeRange? _selectedDateRange;

  @override
  void initState() {
    super.initState();
    _fetchCarDetail();
  }

  /* ------------------------ API ------------------------ */
  Future<void> _fetchCarDetail() async {
    try {
      final response =
          await http.get(Uri.parse('http://localhost:5000/cars/${widget.id}'));

      if (response.statusCode == 200) {
        setState(() {
          _carDetail = jsonDecode(response.body);
          _loading = false;
        });
      } else {
        setState(() {
          _error = true;
          _loading = false;
        });
      }
    } catch (_) {
      setState(() {
        _error = true;
        _loading = false;
      });
    }
  }

  /* -------------------- Date Picker -------------------- */
  void _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _selectedDateRange = picked);
    }
  }

  int _calculateTotalPrice() {
    if (_selectedDateRange == null || _carDetail == null) return 0;
    final days =
        _selectedDateRange!.end.difference(_selectedDateRange!.start).inDays + 1;
    final pricePerDay = int.tryParse(_carDetail!['price'].toString()) ?? 0;
    return days * pricePerDay;
  }

  /* --------------------- Rent Now ---------------------- */
  void _rentNow() async {
    if (_selectedDateRange == null) {
      _showSnackBar("Please select a rental date first.");
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) {
      _showSnackBar("You must be logged in to rent.");
      return;
    }

    final totalPrice = _calculateTotalPrice();
    final response = await http.post(
      Uri.parse('http://localhost:5000/booking'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({
        'name': _carDetail!['name'],
        'brand': _carDetail!['brand'],
        'color': _carDetail!['color'],
        'startTime': _selectedDateRange!.start.toIso8601String(),
        'endTime': _selectedDateRange!.end.toIso8601String(),
        'totalPrice': totalPrice.toString(),
      }),
    );

    if (response.statusCode == 201) {
      _showSnackBar("You have successfully rented ${_carDetail!['name']}!");
      Future.delayed(const Duration(seconds: 2), () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const TabMenu()),
        );
      });
    } else {
      _showSnackBar("Booking failed. Please try again.");
    }
  }

  /* -------------------- SnackBar ----------------------- */
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  /* ---------------------- UI --------------------------- */
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail',style: TextStyle(
            fontWeight: FontWeight.bold, // ทำให้ตัวหนา
            fontSize: 20, // จะเพิ่มขนาดก็ได้ถ้าต้องการ
            color: Color.fromARGB(255, 0, 0, 0),
          ),
          ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const TabMenu()),
              (route) => false,
            );
          },
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error
              ? const Center(child: Text("Failed to load car details"))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      /* ---------- Car Image ---------- */
                      Center(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(
                            kCorsProxy + _carDetail!['coverimage'],
                            width: double.infinity,
                            height: 220,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Center(
                              child: Icon(Icons.broken_image,
                                  size: 60, color: Colors.grey),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      /* ---------- Car Details ---------- */
                      Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 5,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _carDetail!['name'],
                                style: const TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              _detailRow(Icons.directions_car, 'Brand',
                                  _carDetail!['brand']),
                              _detailRow(Icons.color_lens, 'Color',
                                  _carDetail!['color']),
                              _detailRow(
                                  Icons.attach_money,
                                  'Price',
                                  "฿${_carDetail!['price']} / day",
                                  valueStyle: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  )),
                              const SizedBox(height: 10),
                              const Text("Details:",
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16)),
                              Text(_carDetail!['detail'],
                                  style: const TextStyle(fontSize: 16)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      /* ---------- Date Range ---------- */
                      ElevatedButton.icon(
                        onPressed: _selectDateRange,
                        icon: const Icon(Icons.date_range),
                        label: Text(_selectedDateRange == null
                            ? 'Select Rental Date'
                            : "${_selectedDateRange!.start.toLocal().toString().split(' ')[0]} "
                                "- ${_selectedDateRange!.end.toLocal().toString().split(' ')[0]}"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              vertical: 14, horizontal: 20),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          textStyle: const TextStyle(fontSize: 16),
                        ),
                      ),
                      if (_selectedDateRange != null) ...[
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.yellow.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text("Total Price:",
                                  style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600)),
                              Text("฿${_calculateTotalPrice()}",
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red,
                                  )),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
      bottomNavigationBar: _carDetail == null
          ? null
          : Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _rentNow,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text("Rent Now",
                      style: TextStyle(fontSize: 18, color: Colors.white)),
                ),
              ),
            ),
    );
  }

  /* ---------- Helper for Icon + Text rows ---------- */
  Widget _detailRow(IconData icon, String label, String value,
      {TextStyle? valueStyle}) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey),
          const SizedBox(width: 8),
          Text("$label: $value",
              style: valueStyle ?? const TextStyle(fontSize: 18)),
        ],
      ),
    );
  }
}