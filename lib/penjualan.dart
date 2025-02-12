import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PenjualanPage extends StatefulWidget {
  @override
  _PenjualanPageState createState() => _PenjualanPageState();
}

class _PenjualanPageState extends State<PenjualanPage> {
  late Future<List<Map<String, dynamic>>> products;
  late Future<List<Map<String, dynamic>>> transactions;
  final _quantityController = TextEditingController();
  final _pelangganIdController = TextEditingController();

  @override
  void initState() {
    super.initState();
    products = getProducts();
    transactions = getTransactions();
  }

  Future<List<Map<String, dynamic>>> getProducts() async {
    final response = await Supabase.instance.client.from('produk').select().execute();
    if (response.error != null) {
      throw Exception('Gagal mengambil produk: ${response.error?.message}');
    }
    return List<Map<String, dynamic>>.from(response.data ?? []);
  }

  Future<List<Map<String, dynamic>>> getTransactions() async {
    final response = await Supabase.instance.client
        .from('detailpenjualan')
        .select('detailid, penjualanid, produkid, jumlahproduk, subtotal')
        .execute();
    if (response.error != null) {
      throw Exception('Gagal mengambil riwayat transaksi: ${response.error?.message}');
    }
    return List<Map<String, dynamic>>.from(response.data ?? []);
  }

  Future<void> _makeSale(String productId, int quantity, double price, String pelangganId) async {
    try {
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
        final updatedStock = stock - quantity;
        await Supabase.instance.client.from('produk').update({'stok': updatedStock}).eq('produkid', productId).execute();
        final saleResponse = await Supabase.instance.client.from('penjualan').insert([{
          'tanggalpenjualan': DateTime.now().toIso8601String(),
          'totalharga': quantity * price,
          'pelangganid': pelangganId,
        }]).execute();
        if (saleResponse.error != null) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal mencatat transaksi')));
          return;
        }
        final penjualanId = saleResponse.data[0]['penjualanid'];
        await Supabase.instance.client.from('detailpenjualan').insert([{
          'penjualanid': penjualanId,
          'produkid': productId,
          'jumlahproduk': quantity,
          'subtotal': quantity * price,
        }]).execute();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Transaksi berhasil')));
        setState(() {
          products = getProducts();
          transactions = getTransactions();
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

   void _showSaleDialog(Map<String, dynamic> product) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Beli ${product['namaproduk']}'),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          content: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Harga: Rp${product['harga']}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                SizedBox(height: 10),
                TextField(
                  controller: _pelangganIdController,
                  decoration: InputDecoration(
                    labelText: 'Pelanggan ID',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                SizedBox(height: 10),
                TextField(
                  controller: _quantityController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Jumlah',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
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
              child: Text('Beli', style: TextStyle(color: Colors.blueAccent)),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Batal', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildProductList() {
    return FutureBuilder<List<Map<String, dynamic>>>( 
      future: products,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(child: Text('Tidak ada produk'));
        } else {
          return ListView.builder(
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              final product = snapshot.data![index];
              return Card(
                margin: EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 5, // Menambahkan bayangan untuk kesan modern
                child: ListTile(
                  contentPadding: EdgeInsets.all(12),
                  title: Text(
                    product['namaproduk'],
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    'Harga: Rp${product['harga']} | Stok: ${product['stok']}',
                    style: TextStyle(fontSize: 14),
                  ),
                  trailing: IconButton(
                    icon: Icon(Icons.add_shopping_cart, color: Colors.blueAccent),
                    onPressed: () => _showSaleDialog(product),
                  ),
                ),
              );
            },
          );
        }
      },
    );
  }

  void _showTransactionBottomSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    builder: (BuildContext context) {
      return FutureBuilder<List<Map<String, dynamic>>>(
        future: transactions, // Your actual future for transactions
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('Tidak ada transaksi'));
          } else {
            return ListView(
              children: snapshot.data!.map((transaction) {
                return ListTile(
                  title: Text('ID: ${transaction['penjualanid']}'),
                  subtitle: Text('Produk ID: ${transaction['produkid']} - Jumlah: ${transaction['jumlahproduk']}'),
                  trailing: Text('Subtotal: Rp${transaction['subtotal']}'),
                );
              }).toList(),
            );
          }
        },
      );
    },
  );
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Halaman Penjualan", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blueAccent,
      ),
      body: Stack(
        children: [
          _buildProductList(),
          Positioned(
            bottom: 20,
            right: 20,
            child: FloatingActionButton(
              onPressed: () => _showTransactionBottomSheet(context),
              backgroundColor: Colors.blueAccent,
              child: Icon(Icons.history, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}