import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class BookingHistoryScreen extends StatefulWidget {
  const BookingHistoryScreen({super.key});

  @override
  State<BookingHistoryScreen> createState() => _BookingHistoryScreenState();
}

class _BookingHistoryScreenState extends State<BookingHistoryScreen> {
  List<dynamic> bookings = [];

  @override
  void initState() {
    super.initState();
    fetchBookingHistory();
  }

  Future<void> fetchBookingHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) {
      print("No token found");
      return;
    }

    final response = await http.get(
      Uri.parse('http://localhost:5000/booking/my'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      setState(() {
        bookings = json.decode(response.body);
      });
    } else {
      print('Failed to load bookings: ${response.statusCode}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Booking History',
          style: TextStyle(
            fontWeight: FontWeight.bold, // ทำให้ตัวหนา
            fontSize: 20, // จะเพิ่มขนาดก็ได้ถ้าต้องการ
            color: Color.fromARGB(255, 0, 0, 0),
          ),
        ),
        backgroundColor: const Color(0xFFF5F7FA),
      ),
      body: bookings.isEmpty
          ? const Center(child: Text('No bookings yet.'))
          : ListView.builder(
              itemCount: bookings.length,
              itemBuilder: (context, index) {
                final booking = bookings[index];

                final startDate = DateTime.tryParse(booking['startTime'] ?? '');
                final endDate = DateTime.tryParse(booking['endTime'] ?? '');

                final dateRange = (startDate != null && endDate != null)
                    ? '${DateFormat('yyyy-MM-dd').format(startDate)} to ${DateFormat('yyyy-MM-dd').format(endDate)}'
                    : 'Invalid date';

                final totalPrice =
                    double.tryParse(booking['totalPrice'].toString()) ?? 0.0;

                return Card(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    leading: const Icon(Icons.directions_car),
                    title: Text('${booking['brand']} - ${booking['name']}'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Color: ${booking['color']}'),
                        Text('Time: $dateRange'),
                        Text('Total Price: ฿${totalPrice.toStringAsFixed(2)}'),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
