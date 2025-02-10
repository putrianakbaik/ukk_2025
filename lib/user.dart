import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'homepage.dart';
class UserManagementPage extends StatefulWidget {
  @override
  _UserManagementPageState createState() => _UserManagementPageState();
}

class _UserManagementPageState extends State<UserManagementPage> {
  late Future<List<Map<String, dynamic>>> users;

  @override
  void initState() {
    super.initState();
    users = getUsers(); // Ambil data pengguna dari Supabase
  }

  // Mengambil daftar pengguna
  Future<List<Map<String, dynamic>>> getUsers() async {
    final response = await Supabase.instance.client.from('users').select().execute();
    if (response.error != null) {
      throw Exception('Failed to load users: ${response.error!.message}');
    }
    return List<Map<String, dynamic>>.from(response.data);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Manajemen Pengguna"),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AddEditUserPage()),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: users,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(child: Text('Tidak ada pengguna'));
            } else {
              final userList = snapshot.data!;
              return ListView.builder(
                itemCount: userList.length,
                itemBuilder: (context, index) {
                  final user = userList[index];
                  return ListTile(
                    title: Text(user['username']),
                    subtitle: Text('ID: ${user['id']}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.edit),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AddEditUserPage(user: user),
                              ),
                            );
                          },
                        ),
                        IconButton(
                          icon: Icon(Icons.delete),
                          onPressed: () {
                            _confirmDeleteUser(user['id']);
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

  // Mengonfirmasi penghapusan pengguna
  void _confirmDeleteUser(String userId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Konfirmasi Hapus'),
          content: Text('Apakah Anda yakin ingin menghapus pengguna ini?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Batal'),
            ),
            TextButton(
              onPressed: () {
                _deleteUser(userId);
                Navigator.of(context).pop();
              },
              child: Text('Hapus'),
            ),
          ],
        );
      },
    );
  }

  // Fungsi menghapus pengguna dari Supabase
  Future<void> _deleteUser(String userId) async {
  try {
    final response = await Supabase.instance.client
        .from('users')
        .delete()
        .eq('id', userId)
        .single(); // Mengambil 1 data setelah delete

    // Memeriksa apakah ada error di response
    if (response.error != null) {
      // Jika ada error, tampilkan pesan kesalahan
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menghapus pengguna: ${response.error!.message}')),
      );
    } else {
      // Jika tidak ada error, tampilkan pesan sukses dan perbarui daftar pengguna
      setState(() {
        users = getUsers();  // Memperbarui data pengguna setelah penghapusan
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Pengguna berhasil dihapus')),
      );
    }
  } catch (e) {
    // Menangani error lain, misalnya masalah jaringan
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Terjadi kesalahan: $e')),
    );
  }
}

}

class AddEditUserPage extends StatefulWidget {
  final Map<String, dynamic>? user;

  const AddEditUserPage({Key? key, this.user}) : super(key: key);

  @override
  _AddEditUserPageState createState() => _AddEditUserPageState();
}

class _AddEditUserPageState extends State<AddEditUserPage> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.user != null) {
      _usernameController.text = widget.user!['username'];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.user != null ? 'Edit Pengguna' : 'Tambah Pengguna'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _usernameController,
              decoration: InputDecoration(labelText: 'Username'),
            ),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(labelText: 'Password'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                if (widget.user != null) {
                  _showConfirmationDialog('update');
                } else {
                  _showConfirmationDialog('add');
                }
              },
              child: Text(widget.user != null ? 'Update' : 'Tambah'),
            ),
          ],
        ),
      ),
    );
  }

  // Menampilkan dialog konfirmasi
  void _showConfirmationDialog(String action) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(action == 'add' ? 'Tambah Pengguna' : 'Update Pengguna'),
          content: Text('Apakah Anda yakin ingin ${action == 'add' ? 'menambah' : 'mengupdate'} pengguna ini?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Menutup dialog
              },
              child: Text('Batal'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Menutup dialog
                if (action == 'add') {
                  _createUser(); // Menambahkan pengguna baru
                } else {
                  _updateUser(); // Mengupdate pengguna yang sudah ada
                }
              },
              child: Text(action == 'add' ? 'Tambah' : 'Update'),
            ),
          ],
        );
      },
    );
  }

  // Fungsi untuk menambah pengguna
  Future<void> _createUser() async {
    try {
      final response = await Supabase.instance.client.from('users').insert({
        'username': _usernameController.text,
        'password': _passwordController.text,
      }).execute();

      if (response.error == null) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Pengguna berhasil ditambahkan')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal menambahkan pengguna')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  // Fungsi untuk mengupdate pengguna
  Future<void> _updateUser() async {
    try {
      final response = await Supabase.instance.client.from('users').update({
        'username': _usernameController.text,
        'password': _passwordController.text,
      }).eq('id', widget.user!['id']).execute();

      if (response.error == null) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Pengguna berhasil diupdate')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal mengupdate pengguna')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }
}


