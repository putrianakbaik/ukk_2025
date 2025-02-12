import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProdukManagementPage extends StatefulWidget {
  @override
  _ProdukManagementPageState createState() => _ProdukManagementPageState();
}

class _ProdukManagementPageState extends State<ProdukManagementPage> {
  late Future<List<Map<String, dynamic>>> products;

  @override
  void initState() {
    super.initState();
    products = getProducts(); // Mengambil daftar produk dari Supabase
  }

  // ✅ Mengambil daftar produk
  Future<List<Map<String, dynamic>>> getProducts() async {
    final response = await Supabase.instance.client.from('produk').select().execute();

    if (response.error != null) {
      throw Exception('Gagal mengambil produk: ${response.error?.message}');
    }

    return List<Map<String, dynamic>>.from(response.data ?? []);
  }

  // ✅ Menambah produk
  Future<void> _addProduct(String name, double price, int stock) async {
    // Cek apakah produk dengan nama yang sama sudah ada
    final existingProducts = await Supabase.instance.client
        .from('produk')
        .select()
        .eq('namaproduk', name)
        .execute();

    if (existingProducts.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal mengecek produk')));
      return;
    }

    if (existingProducts.data != null && existingProducts.data.isNotEmpty) {
      // Jika produk sudah ada
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Produk dengan nama $name sudah ada!')));
      return;
    }

    try {
      final response = await Supabase.instance.client.from('produk').insert([{
        'namaproduk': name,
        'harga': price,
        'stok': stock,
      }]).execute();

      // Logging response error
      if (response.error != null) {
        print("Error: ${response.error?.message}");
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal menambah produk: ${response.error?.message}')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Produk berhasil ditambahkan')));
        setState(() {
          products = getProducts();  // Refresh data produk setelah penambahan
        });
      }
    } catch (e) {
      print("Error caught: $e");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  // ✅ Mengupdate produk
  Future<void> _updateProduct(String id, String name, double price, int stock) async {
    try {
      final response = await Supabase.instance.client.from('produk').update({
        'namaproduk': name,
        'harga': price,
        'stok': stock,
      }).eq('produkid', id).execute();

      if (response.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal memperbarui produk')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Produk berhasil diperbarui')));
        setState(() {
          products = getProducts();  // Refresh data produk setelah update
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  // ✅ Menghapus produk
  Future<void> _deleteProduct(String id) async {
    try {
      final response = await Supabase.instance.client.from('produk').delete().eq('produkid', id).execute();

      if (response.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal menghapus produk')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Produk berhasil dihapus')));
        setState(() {
          products = getProducts();  // Refresh data produk setelah hapus
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Manajemen Produk", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blueAccent,
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AddProductDialog(onAdd: _addProduct);
                },
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: FutureBuilder<List<Map<String, dynamic>>>( // Menunggu data produk
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
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 4, // Menambahkan bayangan
                    child: ListTile(
                      title: Text(
                        product['namaproduk'],
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        'Harga: Rp${product['harga']} | Stok: ${product['stok']}',
                        style: TextStyle(fontSize: 14),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(Icons.edit, color: Colors.blueAccent),
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return EditProductDialog(
                                    product: product,
                                    onEdit: _updateProduct,
                                  );
                                },
                              );
                            },
                          ),
                          IconButton(
                            icon: Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              _deleteProduct(product['produkid'].toString());
                            },
                          ),
                        ],
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
}

// ✅ Dialog Tambah Produk
class AddProductDialog extends StatefulWidget {
  final Function(String, double, int) onAdd;

  const AddProductDialog({Key? key, required this.onAdd}) : super(key: key);

  @override
  _AddProductDialogState createState() => _AddProductDialogState();
}

class _AddProductDialogState extends State<AddProductDialog> {
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Tambah Produk', style: TextStyle(fontWeight: FontWeight.bold)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: 'Nama Produk',
              labelStyle: TextStyle(color: Colors.blueAccent),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          SizedBox(height: 10),
          TextField(
            controller: _priceController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Harga Produk',
              labelStyle: TextStyle(color: Colors.blueAccent),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          SizedBox(height: 10),
          TextField(
            controller: _stockController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Jumlah Stok',
              labelStyle: TextStyle(color: Colors.blueAccent),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            final name = _nameController.text;
            final price = double.tryParse(_priceController.text) ?? 0.0;
            final stock = int.tryParse(_stockController.text) ?? 0;

            widget.onAdd(name, price, stock);
            Navigator.of(context).pop();
          },
          child: Text('Simpan', style: TextStyle(color: Colors.blueAccent)),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text('Batal', style: TextStyle(color: Colors.red)),
        ),
      ],
    );
  }
}

// ✅ Dialog Edit Produk
class EditProductDialog extends StatefulWidget {
  final Map<String, dynamic> product;
  final Function(String, String, double, int) onEdit;

  const EditProductDialog({Key? key, required this.product, required this.onEdit}) : super(key: key);

  @override
  _EditProductDialogState createState() => _EditProductDialogState();
}

class _EditProductDialogState extends State<EditProductDialog> {
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.product['namaproduk'];
    _priceController.text = widget.product['harga'].toString();
    _stockController.text = widget.product['stok'].toString();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Edit Produk', style: TextStyle(fontWeight: FontWeight.bold)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: 'Nama Produk',
              labelStyle: TextStyle(color: Colors.blueAccent),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          SizedBox(height: 10),
          TextField(
            controller: _priceController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Harga Produk',
              labelStyle: TextStyle(color: Colors.blueAccent),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          SizedBox(height: 10),
          TextField(
            controller: _stockController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Jumlah Stok',
              labelStyle: TextStyle(color: Colors.blueAccent),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            final name = _nameController.text;
            final price = double.tryParse(_priceController.text) ?? 0.0;
            final stock = int.tryParse(_stockController.text) ?? 0;

            widget.onEdit(
              widget.product['produkid'].toString(),
              name,
              price,
              stock,
            );
            Navigator.of(context).pop();
          },
          child: Text('Simpan', style: TextStyle(color: Colors.blueAccent)),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text('Batal', style: TextStyle(color: Colors.red)),
        ),
      ],
    );
  }
}