import 'package:flutter/material.dart';
import 'login.dart';
import 'produk.dart'; 
import 'penjualan.dart'; 
import 'pelanggan.dart';
import 'user.dart'; // Pastikan import yang benar untuk UserManagementPage

class HomePage extends StatefulWidget {
  final String username;
  final int id;
  final String password;

  const HomePage({Key? key, required this.username, required this.id, required this.password}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 1;

  // Mengupdate halaman yang ada di _pages dengan parameter yang benar
  final List<Widget> _pages = [
    PenjualanPage(),        // Halaman Penjualan
    ProdukManagementPage(), // Halaman Produk
    PelangganPage(),        // Halaman Pelanggan
    UserManagementPage(     // Pastikan parameter dikirim dengan benar
      
    ),
  ];

  void _onItemTapped(int index) {
    setState(() {
      if (index >= 0 && index < _pages.length) {
        _selectedIndex = index;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Welcome to Aplikasir, ${widget.username}"),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => LoginPage()),
              );
            },
          ),
        ],
      ),
      body: _pages[_selectedIndex], // Tampilkan halaman sesuai index yang dipilih
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        backgroundColor: Colors.blue, // Menambahkan warna latar belakang untuk BottomNavigationBar
        selectedItemColor: const Color.fromARGB(255, 6, 90, 237), // Warna item yang dipilih
        unselectedItemColor: const Color.fromARGB(255, 6, 90, 237), // Warna item yang tidak dipilih
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart),
            label: 'Penjualan',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.production_quantity_limits),
            label: 'Produk',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Pelanggan',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_circle),
            label: 'User Management',
          ),
        ],
      ),
    );
  }
}
