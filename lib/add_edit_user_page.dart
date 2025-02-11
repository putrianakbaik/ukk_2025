import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AddEditUserPage extends StatefulWidget {
  final Map<String, dynamic>? user;

  const AddEditUserPage({Key? key, this.user}) : super(key: key);

  @override
  _AddEditUserPageState createState() => _AddEditUserPageState();
}

class _AddEditUserPageState extends State<AddEditUserPage> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final SupabaseClient supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    if (widget.user != null) {
      _usernameController.text = widget.user!['username'];
      _passwordController.text = widget.user!['password'];
    }
  }

  // Fungsi untuk menyimpan pengguna (tambah atau update)
  Future<void> _saveUser() async {
    if (_usernameController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Username dan password harus diisi'),
      ));
      return;
    }

    try {
      if (widget.user == null) {
        // Menambahkan pengguna baru
        final response = await supabase.from('users').insert({
          'username': _usernameController.text.trim(),
          'password': _passwordController.text.trim(),
        }).execute();

        if (response.error == null) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Pengguna berhasil ditambahkan'),
          ));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Gagal menambahkan pengguna: ${response.error!.message}'),
          ));
        }
      } else {
        // Mengupdate pengguna yang sudah ada
        final response = await supabase.from('users').update({
          'username': _usernameController.text.trim(),
          'password': _passwordController.text.trim(),
        }).eq('id', widget.user!['id']).execute();

        if (response.error == null) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Pengguna berhasil diupdate'),
          ));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Gagal mengupdate pengguna: ${response.error!.message}'),
          ));
        }
      }

      // Menutup halaman dan menyegarkan halaman sebelumnya
      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.user == null ? 'Tambah Pengguna' : 'Edit Pengguna')),
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
              onPressed: _saveUser,
              child: Text(widget.user == null ? 'Tambah' : 'Update'),
            ),
          ],
        ),
      ),
    );
  }
}
