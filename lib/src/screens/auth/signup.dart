import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
// import 'package:map_camera_flutter_2/map_camera_flutter_2.dart';

class Signup extends StatefulWidget {
  const Signup({super.key});

  @override
  State<Signup> createState() => _SignupState();
}

class _SignupState extends State<Signup> {
  final GlobalKey<FormState> _formKey = GlobalKey();

  final FocusNode _focusNodeEmail = FocusNode();
  final FocusNode _focusNodePassword = FocusNode();
  final FocusNode _focusNodeConfirmPassword = FocusNode();
  final TextEditingController _controllerUsername = TextEditingController();
  final TextEditingController _controllerEmail = TextEditingController();
  final TextEditingController _controllerPassword = TextEditingController();
  final TextEditingController _controllerConFirmPassword =
      TextEditingController();

  final Box _boxAccounts = Hive.box("accounts");
  bool _obscurePassword = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // backgroundColor: Theme.of(context).colorScheme.onInverseSurface,
      body: Container(
        height: MediaQuery.of(context).size.height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color.fromARGB(255, 161, 36, 192),
              Color.fromARGB(255, 25, 118, 194)
            ], // Define your gradient colors
            begin: Alignment.topLeft, // Start of the gradient
            end: Alignment.bottomRight, // End of the gradient
          ),
        ),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 30.0),
            child: Column(
              children: [
                const SizedBox(height: 100),
                Text(
                  "Register",
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
                const SizedBox(height: 10),
                Text(
                  "Create your account",
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 35),
                TextFormField(
                  controller: _controllerUsername,
                  keyboardType: TextInputType.name,
                  decoration: InputDecoration(
                    filled: true,
                    labelText: "Username",
                    prefixIcon: const Icon(Icons.person_outline),
                    border: OutlineInputBorder(
                      borderSide: BorderSide.none,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    // enabledBorder: OutlineInputBorder(
                    //   borderRadius: BorderRadius.circular(10),
                    // ),
                  ),
                  validator: (String? value) {
                    if (value == null || value.isEmpty) {
                      return "Please enter username.";
                    } else if (_boxAccounts.containsKey(value)) {
                      return "Username is already registered.";
                    }

                    return null;
                  },
                  onEditingComplete: () => _focusNodeEmail.requestFocus(),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _controllerEmail,
                  focusNode: _focusNodeEmail,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    filled: true,
                    labelText: "Email",
                    prefixIcon: const Icon(Icons.email_outlined),
                    border: OutlineInputBorder(
                      borderSide: BorderSide.none,
                      borderRadius: BorderRadius.circular(20),
                      // borderRadius: BorderRadius.circular(10),
                    ),
                    // enabledBorder: OutlineInputBorder(
                    //   borderRadius: BorderRadius.circular(10),
                    // ),
                  ),
                  validator: (String? value) {
                    if (value == null || value.isEmpty) {
                      return "Please enter email.";
                    } else if (!(value.contains('@') && value.contains('.'))) {
                      return "Invalid email";
                    }
                    return null;
                  },
                  onEditingComplete: () => _focusNodePassword.requestFocus(),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _controllerPassword,
                  obscureText: _obscurePassword,
                  focusNode: _focusNodePassword,
                  keyboardType: TextInputType.visiblePassword,
                  decoration: InputDecoration(
                    filled: true,
                    labelText: "Password",
                    prefixIcon: const Icon(Icons.password_outlined),
                    suffixIcon: IconButton(
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                        icon: _obscurePassword
                            ? const Icon(Icons.visibility_outlined)
                            : const Icon(Icons.visibility_off_outlined)),
                    border: OutlineInputBorder(
                      borderSide: BorderSide.none,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    // enabledBorder: OutlineInputBorder(
                    //   borderRadius: BorderRadius.circular(10),
                    // ),
                  ),
                  validator: (String? value) {
                    if (value == null || value.isEmpty) {
                      return "Please enter password.";
                    } else if (value.length < 8) {
                      return "Password must be at least 8 character.";
                    }
                    return null;
                  },
                  onEditingComplete: () =>
                      _focusNodeConfirmPassword.requestFocus(),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _controllerConFirmPassword,
                  obscureText: _obscurePassword,
                  focusNode: _focusNodeConfirmPassword,
                  keyboardType: TextInputType.visiblePassword,
                  decoration: InputDecoration(
                    filled: true,
                    labelText: "Confirm Password",
                    prefixIcon: const Icon(Icons.password_outlined),
                    suffixIcon: IconButton(
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                        icon: _obscurePassword
                            ? const Icon(Icons.visibility_outlined)
                            : const Icon(Icons.visibility_off_outlined)),
                    border: OutlineInputBorder(
                      borderSide: BorderSide.none,
                      borderRadius: BorderRadius.circular(20),
                      // borderRadius: BorderRadius.circular(10),
                    ),
                    // enabledBorder: OutlineInputBorder(
                    //   borderRadius: BorderRadius.circular(10),
                    // ),
                  ),
                  validator: (String? value) {
                    if (value == null || value.isEmpty) {
                      return "Please enter password.";
                    } else if (value != _controllerPassword.text) {
                      return "Password doesn't match.";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 50),
                Column(
                  children: [
                    Container(
                      height: 63,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        onPressed: () {
                          if (_formKey.currentState?.validate() ?? false) {
                            _boxAccounts.put(
                              _controllerUsername.text,
                              _controllerConFirmPassword.text,
                            );

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                width: 200,
                                backgroundColor:
                                    Theme.of(context).colorScheme.secondary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                behavior: SnackBarBehavior.floating,
                                content: const Text("Registered Successfully"),
                              ),
                            );

                            _formKey.currentState?.reset();

                            Navigator.pop(context);
                          }
                        },
                        child: const Text("Register"),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          "Already have an account?",
                          style: TextStyle(color: Colors.white),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text("Login",
                              style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _focusNodeEmail.dispose();
    _focusNodePassword.dispose();
    _focusNodeConfirmPassword.dispose();
    _controllerUsername.dispose();
    _controllerEmail.dispose();
    _controllerPassword.dispose();
    _controllerConFirmPassword.dispose();
    super.dispose();
  }
}
