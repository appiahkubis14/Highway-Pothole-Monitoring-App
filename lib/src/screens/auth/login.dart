import 'package:flutter/material.dart';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:pothole/src/screens/components/home/ui/splashScreen.dart';
import 'signup.dart';

class Login extends StatefulWidget {
  const Login({
    super.key,
  });

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final GlobalKey<FormState> _formKey = GlobalKey();

  final FocusNode _focusNodePassword = FocusNode();
  final TextEditingController _controllerUsername = TextEditingController();
  final TextEditingController _controllerPassword = TextEditingController();

  bool _obscurePassword = true;
  final Box _boxLogin = Hive.box("login");
  final Box _boxAccounts = Hive.box("accounts");

  @override
  Widget build(BuildContext context) {
    if (_boxLogin.get("loginStatus") ?? false) {
      return SplashScreen();
    }

    return Scaffold(
      // backgroundColor: Theme.of(context).colorScheme.onTertiary,
      body: Container(
        height: MediaQuery.of(context).size.height,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            tileMode: TileMode.mirror,
            transform: GradientRotation(10),
            colors: [Colors.blue, Colors.purple], // Define your gradient colors
            begin: Alignment.topLeft, // Start of the gradient
            end: Alignment.bottomRight, // End of the gradient
          ),
        ),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(30.0),
            child: Column(
              children: [
                const SizedBox(height: 150),
                Text(
                  "Welcome back",
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
                const SizedBox(height: 10),
                Text(
                  "Login to your account",
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 60),
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
                    //   borderRadius: BorderRadius.circular(20),
                    // ),
                  ),
                  onEditingComplete: () => _focusNodePassword.requestFocus(),
                  validator: (String? value) {
                    if (value == null || value.isEmpty) {
                      return "Please enter username.";
                    } else if (!_boxAccounts.containsKey(value)) {
                      return "Username is not registered.";
                    }

                    return null;
                  },
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _controllerPassword,
                  focusNode: _focusNodePassword,
                  obscureText: _obscurePassword,
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
                      // borderRadius: BorderRadius.circular(10),
                    ),
                    // enabledBorder: OutlineInputBorder(
                    //   borderRadius: BorderRadius.circular(10),
                    // ),
                  ),
                  validator: (String? value) {
                    if (value == null || value.isEmpty) {
                      return "Please enter password.";
                    } else if (value !=
                        _boxAccounts.get(_controllerUsername.text)) {
                      return "Wrong password.";
                    }

                    return null;
                  },
                ),
                const SizedBox(height: 60),
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
                            _boxLogin.put("loginStatus", true);
                            _boxLogin.put("userName", _controllerUsername.text);

                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) {
                                  return SplashScreen();
                                },
                              ),
                            );
                          }
                        },
                        child: const Text("Login"),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("Don't have an account?",
                            style: TextStyle(color: Colors.white)),
                        TextButton(
                          onPressed: () {
                            _formKey.currentState?.reset();

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) {
                                  return const Signup();
                                },
                              ),
                            );
                          },
                          child: const Text("Signup",
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
    _focusNodePassword.dispose();
    _controllerUsername.dispose();
    _controllerPassword.dispose();
    super.dispose();
  }
}
