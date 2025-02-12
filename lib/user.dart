import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'add_edit_user_page.dart';

class UserManagementPage extends StatefulWidget {
  @override
  _UserManagementPageState createState() => _UserManagementPageState();
}

class _UserManagementPageState extends State<UserManagementPage> {
  final SupabaseClient supabase = Supabase.instance.client;

  List<Map<String, dynamic>> _users = [];

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  // Ambil data pengguna dari Supabase
  Future<void> _fetchUsers() async {
  final response = await supabase.from('users').select().execute();

  if (response.error == null && response.data != null) {
    setState(() {
      _users = List<Map<String, dynamic>>.from(response.data);
    });
  }
}


  // Hapus pengguna dari database
  Future<void> _deleteUser(int id) async {
    await supabase.from('users').delete().eq('id', id);
    _fetchUsers(); // Refresh daftar pengguna setelah dihapus
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Manajemen Pengguna', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blueAccent,
        elevation: 4,
      ),
      body: _users.isEmpty
          ? Center(child: Text('Tidak ada pengguna', style: TextStyle(fontSize: 16, color: Colors.grey)))
          : ListView.builder(
              itemCount: _users.length,
              itemBuilder: (context, index) {
                final user = _users[index];
                return Card(
                  margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 5,
                  child: ListTile(
                    contentPadding: EdgeInsets.all(16),
                    title: Text(
                      user['username'],
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.edit, color: Colors.blue),
                          onPressed: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AddEditUserPage(user: user),
                              ),
                            );
                            if (result == true) _fetchUsers();
                          },
                        ),
                        IconButton(
                          icon: Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            _deleteUser(user['id']);
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddEditUserPage()),
          );
          if (result == true) _fetchUsers();
        },
        child: Icon(Icons.add),
        backgroundColor: Colors.blueAccent,
        tooltip: 'Tambah Pengguna',
      ),
    );
  }
}

class AddEditUserPage extends StatelessWidget {
  final Map<String, dynamic>? user;

  const AddEditUserPage({Key? key, this.user}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final TextEditingController usernameController =
        TextEditingController(text: user?['username'] ?? '');

    return Scaffold(
      appBar: AppBar(
        title: Text(user == null ? 'Tambah Pengguna' : 'Edit Pengguna'),
        backgroundColor: Colors.blueAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: usernameController,
              decoration: InputDecoration(
                labelText: 'Username',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Implementasi penyimpanan atau pembaruan data pengguna
                Navigator.pop(context, true);
              },
              child: Text(user == null ? 'Simpan' : 'Perbarui'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 14), backgroundColor: Colors.blueAccent,
                shape: RoundedRectangleBorder(borderRadius: 
                BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}