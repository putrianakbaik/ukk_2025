import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'homepage.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  final supabase = Supabase.instance.client;

  Future<void> signIn() async {
    if (_formKey.currentState!.validate()) {
      // Jika form valid, lanjutkan proses sign in
      setState(() {
        _isLoading = true;
      });

      try {
        // Mengambil data pengguna berdasarkan username dan password dari Supabase
        final response = await Supabase.instance.client
            .from('users')
            .select()
            .eq('username', _usernameController.text)  // Pencarian berdasarkan username
            .eq('password', _passwordController.text)  // Pencarian berdasarkan password
            .execute();

        // Memeriksa apakah response.data berisi data pengguna
        if (response.data != null && response.data.isNotEmpty) {
          final user = response.data[0];  // Ambil data pengguna pertama dari response.data
          final userId = user['id'];  // Ambil id pengguna
          final username = user['username'];  // Ambil username pengguna
          final password = user['password'];  // Ambil password pengguna

          // Menyimpan data pengguna untuk digunakan di halaman berikutnya
          print('User ID: $userId');
          print('Username: $username');
          print('Password: $password');
          
          // Navigasi ke halaman utama atau halaman lain
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => HomePage(username: username, id: userId, password: password)),
          );
        } else {
          // Menampilkan pesan jika username atau password salah
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Username atau Password salah')),
          );
        }
      } catch (e) {
        // Menangani kesalahan lain (misalnya, masalah jaringan atau server)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Terjadi kesalahan: $e')),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    } else {
      // Jika form tidak valid, tampilkan notifikasi
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Harap diisi terlebih dahulu')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Login")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(labelText: 'Username'),
                validator: (value) => value!.isEmpty ? 'Masukkan username' : null,
              ),
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Password',
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),
                obscureText: _obscurePassword,
                validator: (value) => value!.isEmpty ? 'Masukkan password' : null,
              ),
              const SizedBox(height: 20),
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: signIn,
                      child: const Text('Login'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
