import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_project1/car_detail.dart';
import 'login_screen.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<StatefulWidget> createState() {
    return HomeScreenState();
  }
}
const String kCorsProxy = 'https://cors-anywhere.herokuapp.com/';

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

class HomeScreenState extends State<AdminScreen> {
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

  Future<void> deleteCar(int id) async {
    final response =
        await http.delete(Uri.parse('http://localhost:5000/cars/$id'));

    if (response.statusCode == 200) {
      fetchCarsFromApi();
    } else {
      print('Failed to delete car');
    }
  }

  Future<void> confirmDeleteCar(int id) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ยืนยันการลบ'),
        content: const Text('คุณแน่ใจหรือไม่ว่าต้องการลบรถคันนี้?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('ลบ'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      deleteCar(id);
    }
  }

  Future<void> addCarDialog() async {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController detailController = TextEditingController();
    final TextEditingController brandController = TextEditingController();
    final TextEditingController colorController = TextEditingController();
    final TextEditingController priceController = TextEditingController();
    final TextEditingController imageController = TextEditingController();

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('เพิ่มรถใหม่'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'ชื่อรถ')),
              TextField(
                  controller: brandController,
                  decoration: const InputDecoration(labelText: 'ยี่ห้อ')),
              TextField(
                  controller: colorController,
                  decoration: const InputDecoration(labelText: 'สี')),
              TextField(
                  controller: priceController,
                  decoration: const InputDecoration(labelText: 'ราคา')),
              TextField(
                  controller: imageController,
                  decoration: const InputDecoration(labelText: 'ลิงก์รูปภาพ')),
              TextField(
                  controller: detailController,
                  decoration: const InputDecoration(labelText: 'รายละเอียด')),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () async {
              // แสดง Dialog ยืนยันการเพิ่ม
              bool? confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('ยืนยันการเพิ่ม'),
                  content:
                      const Text('คุณแน่ใจหรือไม่ว่าต้องการเพิ่มรถคันนี้?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('ยกเลิก'),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green),
                      child: const Text('ยืนยัน'),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                // หากยืนยันแล้วให้ส่งคำขอ POST
                final response = await http.post(
                  Uri.parse('http://localhost:5000/cars'),
                  headers: {'Content-Type': 'application/json'},
                  body: jsonEncode({
                    'name': nameController.text,
                    'brand': brandController.text,
                    'color': colorController.text,
                    'price': priceController.text,
                    'coverimage': imageController.text,
                    'detail': detailController.text,
                  }),
                );
                if (response.statusCode == 201) {
                  fetchCarsFromApi();
                  Navigator.pop(context);
                } else {
                  print('Failed to add car');
                }
              }
            },
            child: const Text('เพิ่ม'),
          ),
        ],
      ),
    );
  }

  Future<void> editCarDialog(Attraction car) async {
    final nameController = TextEditingController(text: car.name);
    final brandController = TextEditingController(text: car.brand);
    final colorController = TextEditingController(text: car.color);
    final priceController = TextEditingController(text: car.price.toString());
    final imageController = TextEditingController(text: car.coverimage);
    final detailController = TextEditingController(text: car.detail);

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('แก้ไขข้อมูลรถ'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'ชื่อรถ')),
              TextField(
                  controller: brandController,
                  decoration: const InputDecoration(labelText: 'ยี่ห้อ')),
              TextField(
                  controller: colorController,
                  decoration: const InputDecoration(labelText: 'สี')),
              TextField(
                  controller: priceController,
                  decoration: const InputDecoration(labelText: 'ราคา')),
              TextField(
                  controller: imageController,
                  decoration: const InputDecoration(labelText: 'ลิงก์รูปภาพ')),
              TextField(
                  controller: detailController,
                  decoration: const InputDecoration(labelText: 'รายละเอียด')),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () async {
              final response = await http.put(
                Uri.parse('http://localhost:5000/cars/${car.id}'),
                headers: {'Content-Type': 'application/json'},
                body: jsonEncode({
                  'name': nameController.text,
                  'brand': brandController.text,
                  'color': colorController.text,
                  'price': priceController.text,
                  'coverimage': imageController.text,
                  'detail': detailController.text,
                }),
              );

              if (response.statusCode == 200) {
                fetchCarsFromApi();
                Navigator.pop(context);
              } else {
                print('Failed to update car');
              }
            },
            child: const Text('บันทึก'),
          ),
        ],
      ),
    );
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
    fetchCarsFromApi();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF132B94),
        title: SizedBox(
          height: 40,
          child: TextField(
            onChanged: _filterAttractions,
            decoration: InputDecoration(
              hintText: 'Search cars...',
              hintStyle: const TextStyle(color: Colors.black54),
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

        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.black),
            tooltip: 'Logout',
            onPressed: () {
              _showLogoutDialog(context);
            },
          ),
        ],
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
                                kCorsProxy +
                                    filteredAttractions[i]
                                        .coverimage, // ★ เพิ่ม proxy
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
                          Text(
                            "฿${filteredAttractions[i].price} / วัน",
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit,
                                    color: Colors.orange),
                                onPressed: () {
                                  editCarDialog(filteredAttractions[i]);
                                },
                              ),
                              IconButton(
                                icon:
                                    const Icon(Icons.delete, color: Colors.red),
                                onPressed: () {
                                  confirmDeleteCar(filteredAttractions[i].id);
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: addCarDialog,
        backgroundColor: const Color(0xFF132B94),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

// ย้ายออกมานอก build()
  void _showLogoutDialog(BuildContext context) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ออกจากระบบ'),
        content: const Text('คุณต้องการออกจากระบบใช่หรือไม่?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context, true); // ปิด Dialog
              // ลบข้อมูล session/token ที่ใช้ในการเก็บสถานะการล็อกอิน
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (context) =>
                        const LoginScreen()), // ไปที่หน้า LoginScreen
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text(
              'ออกจากระบบ',
              style: TextStyle(
                color: Color.fromARGB(255, 255, 255, 255),
              ),
            ),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      // ล้างข้อมูลการเข้าสู่ระบบที่จำเป็น เช่น token หรือ session ออกไปจากแอป
      // ในกรณีนี้จะทำการไปหน้า LoginScreen
    }
  }
}
