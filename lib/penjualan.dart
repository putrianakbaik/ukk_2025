import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PenjualanPage extends StatefulWidget {
  @override
  _PenjualanPageState createState() => _PenjualanPageState();
}

class _PenjualanPageState extends State<PenjualanPage> {
  late Future<List<Map<String, dynamic>>> products;
  final _quantityController = TextEditingController();
  final _pelangganIdController = TextEditingController();

  @override
  void initState() {
    super.initState();
    products = getProducts(); // Mengambil daftar produk dari Supabase
  }

  // Mengambil daftar produk
  Future<List<Map<String, dynamic>>> getProducts() async {
    final response = await Supabase.instance.client.from('produk').select().execute();

    if (response.error != null) {
      throw Exception('Gagal mengambil produk: ${response.error?.message}');
    }

    return List<Map<String, dynamic>>.from(response.data ?? []);
  }

  // Melakukan transaksi penjualan
  Future<void> _makeSale(String productId, int quantity, double price, String pelangganId) async {
    try {
      // Mengecek stok produk
      final response = await Supabase.instance.client.from('produk').select('stok').eq('produkid', productId).execute();

      if (response.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal mengecek stok produk')));
        return;
      }

      if (response.data != null && response.data.isNotEmpty) {
        final stock = response.data[0]['stok'];

        if (stock < quantity) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Stok tidak mencukupi')));
          return;
        }

        // Update stok produk setelah transaksi
        final updatedStock = stock - quantity;
        final updateResponse = await Supabase.instance.client.from('produk').update({'stok': updatedStock}).eq('produkid', productId).execute();

        if (updateResponse.error != null) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal memperbarui stok')));
        } else {
          // Menambahkan transaksi penjualan ke tabel penjualan
          final saleResponse = await Supabase.instance.client.from('penjualan').insert([{
            'tanggalpenjualan': DateTime.now().toIso8601String(),
            'totalharga': quantity * price,
            'pelangganid': pelangganId,  // Menambahkan pelangganid
          }]).execute();

          if (saleResponse.error != null) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal mencatat transaksi')));
          } else {
            final penjualanId = saleResponse.data[0]['penjualanid'];

            // Menambahkan detail transaksi penjualan ke tabel detailpenjualan
            final subtotal = price * quantity;
            final detailResponse = await Supabase.instance.client.from('detailpenjualan').insert([{
              'penjualanid': penjualanId,
              'produkid': productId,
              'jumlahproduk': quantity,
              'subtotal': subtotal,
            }]).execute();

            if (detailResponse.error != null) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal mencatat detail penjualan')));
            } else {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Transaksi berhasil')));
              setState(() {
                products = getProducts(); // Refresh data produk setelah penjualan
              });
            }
          }
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Halaman Penjualan"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: products,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(child: Text('Tidak ada produk'));
            } else {
              final productList = snapshot.data!;
              return ListView.builder(
                itemCount: productList.length,
                itemBuilder: (context, index) {
                  final product = productList[index];
                  return Card(
                    margin: EdgeInsets.symmetric(vertical: 8),
                    child: ListTile(
                      title: Text(product['namaproduk']),
                      subtitle: Text('Harga: Rp${product['harga']} | Stok: ${product['stok']}'),
                      trailing: IconButton(
                        icon: Icon(Icons.add_shopping_cart),
                        onPressed: () {
                          // Menampilkan dialog untuk memilih jumlah produk yang ingin dibeli
                          _showSaleDialog(product);
                        },
                      ),
                    ),
                  );
                },
              );
            }
          },
        ),
      ),
    );
  }

  // Dialog untuk memilih jumlah produk yang ingin dibeli
  void _showSaleDialog(Map<String, dynamic> product) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Beli ${product['namaproduk']}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Harga: Rp${product['harga']}'),
              TextField(
                controller: _pelangganIdController,
                decoration: InputDecoration(labelText: 'Pelanggan ID'),
              ),
              TextField(
                controller: _quantityController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: 'Jumlah'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                final quantity = int.tryParse(_quantityController.text) ?? 0;
                final pelangganId = _pelangganIdController.text;

                if (quantity > 0 && pelangganId.isNotEmpty) {
                  _makeSale(product['produkid'].toString(), quantity, product['harga'], pelangganId);
                  Navigator.of(context).pop();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Jumlah dan Pelanggan ID tidak valid')));
                }
              },
              child: Text('Beli'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Batal'),
            ),
          ],
        );
      },
    );
  }
}
