import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'homepage.dart';

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

  // Mengambil daftar produk
  Future<List<Map<String, dynamic>>> getProducts() async {
    final response = await Supabase.instance.client.from('produk').select().execute();

    // Memeriksa error dari response
    if (response.error != null) {
      throw Exception('Failed to load products: ${response.error?.message}');
    }

    // Kembalikan data produk dalam bentuk List
    return List<Map<String, dynamic>>.from(response.data ?? []);
  }

  // Fungsi untuk menambah produk
  Future<void> _addProduct(String name, double price) async {
    try {
      final response = await Supabase.instance.client.from('produk').insert([
        {'name': name, 'price': price}
      ]).execute();

      if (response.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal menambah produk')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Produk berhasil ditambahkan')));
        setState(() {
          products = getProducts();  // Refresh data produk setelah penambahan
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  // Fungsi untuk mengupdate produk
  Future<void> _updateProduct(String id, String name, double price) async {
    try {
      final response = await Supabase.instance.client.from('produk').update({
        'name': name,
        'price': price,
      }).eq('id', id).execute();

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

  // Fungsi untuk menghapus produk
  Future<void> _deleteProduct(String id) async {
    try {
      final response = await Supabase.instance.client.from('produk').delete().eq('id', id).execute();

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
        title: Text("Manajemen Produk"),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () {
              // Tampilkan form untuk tambah produk
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
                  return ListTile(
                    title: Text(product['name']),
                    subtitle: Text('Harga: \$${product['price']}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.edit),
                          onPressed: () {
                            // Tampilkan form untuk edit produk
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
                          icon: Icon(Icons.delete),
                          onPressed: () {
                            // Konfirmasi penghapusan produk
                            _confirmDeleteProduct(product['id']);
                          },
                        ),
                      ],
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

  // Mengonfirmasi penghapusan produk
  void _confirmDeleteProduct(String productId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Konfirmasi Hapus'),
          content: Text('Apakah Anda yakin ingin menghapus produk ini?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Batal'),
            ),
            TextButton(
              onPressed: () {
                _deleteProduct(productId);
                Navigator.of(context).pop();
              },
              child: Text('Hapus'),
            ),
          ],
        );
      },
    );
  }
}

class AddProductDialog extends StatefulWidget {
  final Function(String, double) onAdd;

  const AddProductDialog({Key? key, required this.onAdd}) : super(key: key);

  @override
  _AddProductDialogState createState() => _AddProductDialogState();
}

class _AddProductDialogState extends State<AddProductDialog> {
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Tambah Produk'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            decoration: InputDecoration(labelText: 'Nama Produk'),
          ),
          TextField(
            controller: _priceController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: 'Harga Produk'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            widget.onAdd(_nameController.text, double.parse(_priceController.text));
            Navigator.of(context).pop();
          },
          child: Text('Simpan'),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text('Batal'),
        ),
      ],
    );
  }
}

class EditProductDialog extends StatefulWidget {
  final Map<String, dynamic> product;
  final Function(String, String, double) onEdit;

  const EditProductDialog({Key? key, required this.product, required this.onEdit}) : super(key: key);

  @override
  _EditProductDialogState createState() => _EditProductDialogState();
}

class _EditProductDialogState extends State<EditProductDialog> {
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.product['name'];
    _priceController.text = widget.product['price'].toString();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Edit Produk'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            decoration: InputDecoration(labelText: 'Nama Produk'),
          ),
          TextField(
            controller: _priceController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: 'Harga Produk'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            widget.onEdit(widget.product['id'], _nameController.text, double.parse(_priceController.text));
            Navigator.of(context).pop();
          },
          child: Text('Simpan'),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text('Batal'),
        ),
      ],
    );
  }
}
