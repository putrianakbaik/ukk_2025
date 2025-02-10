import 'package:flutter/material.dart';
import 'login.dart';
import 'produk.dart';   

class HomePage extends StatefulWidget {
  final String username;
  final int id;
  final String password;

  const HomePage({Key? key, required this.username, required this.id, required this.password}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0; // Menyimpan index yang aktif di navbar

  // Daftar halaman yang akan ditampilkan
  final List<Widget> _pages = [
    ProdukManagementPage(),    // Halaman Produk
 
  ];

  // Fungsi untuk mengubah halaman berdasarkan index
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
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
              // Navigasi ke halaman login (logout)
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => LoginPage()),
              );
            },
          ),
        ],
      ),
      body: _pages[_selectedIndex], // Menampilkan halaman berdasarkan index yang dipilih
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex, // Menandakan halaman yang aktif
        onTap: _onItemTapped, // Fungsi yang dipanggil saat item navbar ditekan
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
        ],
      ),
    );
  }
}
