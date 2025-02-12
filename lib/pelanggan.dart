import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PelangganPage extends StatefulWidget {
  @override
  _PelangganPageState createState() => _PelangganPageState();
}

class _PelangganPageState extends State<PelangganPage> {
  List<Map<String, dynamic>> _pelangganList = [];
  final _namaController = TextEditingController();
  final _teleponController = TextEditingController();
  final _alamatController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadPelanggan(); // Memuat data pelanggan dari Supabase saat pertama kali dibuka
  }

  // ✅ Fungsi Memuat Data Pelanggan dari Supabase
  Future<void> _loadPelanggan() async {
    final supabase = Supabase.instance.client;

    final response = await supabase.from('pelanggan').select().execute();

    if (response.error == null) {
      setState(() {
        _pelangganList = List<Map<String, dynamic>>.from(response.data);
      });
    } else {
      print('Error fetching data: ${response.error!.message}');
    }
  }

  // ✅ Fungsi Menyimpan Data Pelanggan ke Supabase
  Future<void> _simpanPelanggan(int? id) async {
    final nama = _namaController.text.trim();
    final telepon = _teleponController.text.trim();
    final alamat = _alamatController.text.trim();

    final supabase = Supabase.instance.client;

    // ✅ Hanya cek duplikasi jika id == null (proses create/tambah)
    if (id == null) {
      // Mengecek apakah pelanggan dengan nama atau telepon yang sama sudah ada
      final isDuplicate = _pelangganList.any((p) =>
          p['namapelanggan'] == nama || p['nomortelepon'] == telepon);

      if (isDuplicate) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Pelanggan dengan nama atau telepon yang sama sudah ada!"),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    try {
      if (id == null) {
        // Menambah pelanggan baru ke Supabase
        final response = await supabase.from('pelanggan').insert([{
          'namapelanggan': nama,
          'nomortelepon': telepon,
          'alamat': alamat,
        }]).execute();

        if (response.error == null) {
          setState(() {
            _pelangganList.add({
              'pelangganid': response.data[0]['pelangganid'], // ID tetap integer
              'namapelanggan': nama,
              'nomortelepon': telepon,
              'alamat': alamat,
            });
          });
          print('Pelanggan baru ditambahkan: $nama');
        } else {
          print('Error saat menambah pelanggan: ${response.error!.message}');
        }
      } else {
        // Edit pelanggan di Supabase
        final response = await supabase
            .from('pelanggan')
            .update({
              'namapelanggan': nama,
              'nomortelepon': telepon,
              'alamat': alamat,
            })
            .eq('pelangganid', id) // ID tetap integer
            .execute();

        if (response.error == null) {
          setState(() {
            final index = _pelangganList.indexWhere((p) => p['pelangganid'] == id);
            if (index != -1) {
              _pelangganList[index] = {
                'pelangganid': id,
                'namapelanggan': nama,
                'nomortelepon': telepon,
                'alamat': alamat,
              };
            }
          });
          print('Pelanggan berhasil diperbarui: $nama');
        } else {
          print('Error saat memperbarui pelanggan: ${response.error!.message}');
        }
      }
      await _loadPelanggan(); // Memperbarui daftar pelanggan
    } catch (e) {
      print('Terjadi kesalahan: $e');
    }
  }

  // ✅ Fungsi Menghapus Data Pelanggan dari Supabase
  Future<void> _hapusPelanggan(int id) async {
    final supabase = Supabase.instance.client;

    try {
      final response = await supabase
          .from('pelanggan')
          .delete()
          .eq('pelangganid', id) // ID tetap integer
          .execute();

      if (response.error == null) {
        setState(() {
          _pelangganList.removeWhere((p) => p['pelangganid'] == id);
        });
        print('Pelanggan berhasil dihapus dengan ID: $id');
      } else {
        print('Error saat menghapus pelanggan: ${response.error!.message}');
      }
    } catch (e) {
      print('Terjadi kesalahan saat menghapus pelanggan: $e');
    }
  }

 @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Daftar Pelanggan", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blueAccent,
        centerTitle: true,
        elevation: 4,
      ),
      body: ListView.builder(
        itemCount: _pelangganList.length,
        itemBuilder: (context, index) {
          final pelanggan = _pelangganList[index];

          return Card(
            margin: EdgeInsets.symmetric(horizontal: 15, vertical: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 4, // Bayangan untuk kesan lebih modern
            child: ListTile(
              title: Text(
                pelanggan['namapelanggan']!,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Telepon: ${pelanggan['nomortelepon']}", style: TextStyle(fontSize: 14)),
                  Text("Alamat: ${pelanggan['alamat']}", style: TextStyle(fontSize: 14)),
                ],
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(Icons.edit, color: Colors.blueAccent),
                    onPressed: () {
                      print("Edit button pressed for ID: ${pelanggan['pelangganid']}");
                      _tampilkanDialog(id: int.parse(pelanggan['pelangganid']!));
                    },
                  ),
                  IconButton(
                    icon: Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      print("Delete button pressed for ID: ${pelanggan['pelangganid']}");
                      _hapusPelanggan(int.parse(pelanggan['pelangganid']!));
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _tampilkanDialog(),
        backgroundColor: Colors.blueAccent,
        child: Icon(Icons.add),
        tooltip: "Tambah Pelanggan",
      ),
    );
  }

  // Fungsi untuk menampilkan dialog tambah/edit pelanggan
  void _tampilkanDialog({int? id}) {
    if (id != null) {
      // Jika id ada, mode edit
      final pelanggan = _pelangganList.firstWhere((p) => int.parse(p['pelangganid']!) == id);
      _namaController.text = pelanggan['namapelanggan']!;
      _teleponController.text = pelanggan['nomortelepon']!;
      _alamatController.text = pelanggan['alamat']!;
    } else {
      // Mode tambah
      _namaController.clear();
      _teleponController.clear();
      _alamatController.clear();
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(id == null ? "Tambah Pelanggan" : "Edit Pelanggan"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _namaController,
                  decoration: InputDecoration(
                    labelText: "Nama",
                    labelStyle: TextStyle(color: Colors.blueAccent),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                SizedBox(height: 10),
                TextField(
                  controller: _teleponController,
                  decoration: InputDecoration(
                    labelText: "Nomor Telepon",
                    labelStyle: TextStyle(color: Colors.blueAccent),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  keyboardType: TextInputType.phone,
                ),
                SizedBox(height: 10),
                TextField(
                  controller: _alamatController,
                  decoration: InputDecoration(
                    labelText: "Alamat",
                    labelStyle: TextStyle(color: Colors.blueAccent),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Batal"),
            ),
            ElevatedButton(
              onPressed: () {
                _simpanPelanggan(id); // Pastikan id menggunakan int
                Navigator.pop(context);
              },
              child: Text("Simpan"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        );
      },
    );
  }
}