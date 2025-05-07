import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_project1/car_detail.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<StatefulWidget> createState() {
    return HomeScreenState();
  }
}

class Attraction {
  final int id;
  final String name;
  final String detail;
  final String coverimage;
  final String brand;
  final String color;
  final int price;

  Attraction({
    required this.id,
    required this.name,
    required this.detail,
    required this.coverimage,
    required this.brand,
    required this.color,
    required this.price,
  });

  factory Attraction.fromJson(Map<String, dynamic> json) {
    return Attraction(
      id: json['_id'],
      name: json['name'],
      detail: json['detail'],
      coverimage: json['coverimage'],
      brand: json['brand'],
      color: json['color'],
      price: int.parse(json['price']),
    );
  }
}

class HomeScreenState extends State<HomeScreen> {
  List<Attraction> attractions = [];
  List<Attraction> filteredAttractions = [];
  String _searchQuery = '';

  Future<void> fetchCarsFromApi() async {
    final response = await http.get(Uri.parse('http://localhost:5000/cars'));

    if (response.statusCode == 200) {
      try {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          attractions =
              List<Attraction>.from(data.map((i) => Attraction.fromJson(i)));
          filteredAttractions = attractions;
        });
      } catch (e) {
        print('Error parsing JSON: $e');
      }
    } else {
      print('Failed to load cars: ${response.statusCode}');
    }
  }

  void _filterAttractions(String query) {
    setState(() {
      _searchQuery = query;
      filteredAttractions = attractions
          .where((car) =>
              car.name.toLowerCase().contains(query.toLowerCase()) ||
              car.brand.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  @override
  void initState() {
    super.initState();
    fetchCarsFromApi(); // เรียกฟังก์ชันเมื่อเริ่มต้น
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F7FA),
        title: SizedBox(
          height: 40,
          child: TextField(
            onChanged: _filterAttractions,
            decoration: InputDecoration(
              hintText: 'Search cars...',
              hintStyle: const TextStyle(
                color: Colors.black54,fontSize: 24,fontWeight: FontWeight.bold,),
              filled: true,
              fillColor: Colors.white,
              prefixIcon: const Icon(Icons.search, color: Colors.black54),
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
  padding: const EdgeInsets.all(10.0),
  child: filteredAttractions.isEmpty
      ? const Center(child: Text('ไม่พบรถที่คุณต้องการ'))
      : GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.8,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemCount: filteredAttractions.length,
          itemBuilder: (context, i) {
            return Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(
                          'https://cors-anywhere.herokuapp.com/' +
                              filteredAttractions[i].coverimage,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const Center(
                            child: Icon(Icons.broken_image,
                                size: 60, color: Colors.grey),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      filteredAttractions[i].name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      filteredAttractions[i].brand,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      "฿${filteredAttractions[i].price} / Day",
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          shape: const CircleBorder(),
                          padding: const EdgeInsets.all(10),
                          backgroundColor: Colors.black,
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => UserDetailPage(
                                id: filteredAttractions[i].id,
                              ),
                            ),
                          );
                        },
                        child: const Icon(Icons.arrow_forward,
                            color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),

      );
    }
  }

  

