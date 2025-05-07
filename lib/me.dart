import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_screen.dart'; // 

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  bool isEditableName = false;
  bool isEditableEmail = false;
  bool isEditablePhone = false;

  @override
  void initState() {
    super.initState();
    fetchUserData();
  }

  Future<void> fetchUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        print('No token found');
        return;
      }

      final response = await http.get(
        Uri.parse('http://localhost:5000/user/me'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final user = json.decode(response.body);

        setState(() {
          _nameController.text = user['name'] ?? '';
          _emailController.text = user['email'] ?? '';
          _phoneController.text = user['phone'] ?? '';
        });
      } else {
        print('Failed to load user data. Status: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching user data: $e');
    }
  }
 Future<void> updateUserData({String? name, String? email, String? phone}) async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token');

  if (token == null) {
    print('No token found');
    return;
  }

  final Map<String, dynamic> updatedFields = {};
  if (name != null) updatedFields['name'] = name;
  if (email != null) updatedFields['email'] = email;
  if (phone != null) updatedFields['phone'] = phone;

  final response = await http.put(
    Uri.parse('http://localhost:5000/user/me'), // ✅ URL ควรอัปเดตใน backend ด้วย (ดูด้านล่าง)
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
    body: json.encode(updatedFields),
  );

  if (response.statusCode == 200) {
    print('อัปเดตข้อมูลสำเร็จ');
    // fetch ข้อมูลใหม่หลังอัปเดต
    fetchUserData();
  } else {
    print('อัปเดตไม่สำเร็จ: ${response.body}');
  }
}



  void _showLogoutConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ยืนยันการออกจากระบบ'),
        content: const Text('คุณแน่ใจหรือไม่ว่าต้องการออกจากระบบ?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // ปิด dialog
            },
            child: const Text('ยกเลิก'),
          ),
          TextButton(
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.remove('token');

              if (!mounted) return;

              Navigator.of(context).pop(); // ปิด dialog ก่อน
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            },
            child: const Text('ใช่'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Profile',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Color.fromARGB(255, 0, 0, 0),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const CircleAvatar(
                    radius: 50,
                    backgroundImage: AssetImage('assets/IMG_0687.jpg'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _buildEditableField(
              title: 'Name',
              controller: _nameController,
              isEditable: isEditableName,
              onEdit: () {
                setState(() {
                  isEditableName = !isEditableName;
                });
              },
            ),
            _buildEditableField(
              title: 'Email',
              controller: _emailController,
              isEditable: isEditableEmail,
              onEdit: () {
                setState(() {
                  isEditableEmail = !isEditableEmail;
                });
              },
              keyboardType: TextInputType.emailAddress,
            ),
            _buildEditableField(
              title: 'Phone Number',
              controller: _phoneController,
              isEditable: isEditablePhone,
              onEdit: () {
                setState(() {
                  isEditablePhone = !isEditablePhone;
                });
              },
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                _showLogoutConfirmationDialog(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF132B94),
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              ),
              child: const Text('Logout',
                  style: TextStyle(
                      fontSize: 16, color: Color.fromARGB(255, 255, 255, 255))),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditableField({
    required String title,
    required TextEditingController controller,
    required bool isEditable,
    required VoidCallback onEdit,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return ListTile(
      title: Text(title),
      subtitle: Row(
        children: [
          Expanded(
            child: TextFormField(
              controller: controller,
              decoration: const InputDecoration(),
              keyboardType: keyboardType,
              enabled: isEditable,
            ),
          ),
         TextButton(
  onPressed: () async {
    if (isEditable) {
      // กำลังจะ Save
      if (title == 'Name') {
        await updateUserData(name: controller.text);
      } else if (title == 'Email') {
        await updateUserData(email: controller.text);
      } else if (title == 'Phone Number') {
        await updateUserData(phone: controller.text);
      }

      // แสดง SnackBar ว่าบันทึกสำเร็จ
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('บันทึกข้อมูลสำเร็จ'),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.green,
          ),
        );
      }
    }

    onEdit(); // toggle editable
  },
  child: Text(isEditable ? 'Save' : 'Edit'),
),

        ],
      ),
    );
  }
}