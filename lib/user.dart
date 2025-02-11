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
      appBar: AppBar(title: Text('Manajemen Pengguna')),
      body: _users.isEmpty
          ? Center(child: Text('Tidak ada pengguna'))
          : ListView.builder(
              itemCount: _users.length,
              itemBuilder: (context, index) {
                final user = _users[index];
                return ListTile(
                  title: Text(user['username']),
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
        backgroundColor: Colors.blue,
      ),
    );
  }
}
