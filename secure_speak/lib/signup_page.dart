import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';

class SignUpPage extends StatefulWidget {
  @override
  _SignUpPageState createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final Color mainColor = Color(0xFF22223B); // Your company color
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  final TextEditingController smsController = TextEditingController();
  String errorMessage = '';
  bool isSMSsent = false;
  String verificationId = '';
  PhoneNumber phoneNumber = PhoneNumber(isoCode: 'US');
  bool _passwordVisible = false;
  bool _confirmPasswordVisible = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 30.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              CircleAvatar(
                radius: 50.0,
                backgroundColor: Colors.grey.shade300,
                child: Icon(
                  Icons.person,
                  size: 50.0,
                  color: Colors.grey.shade600,
                ),
              ),
              SizedBox(height: 30.0),
              Text(
                'SIGN UP',
                style: TextStyle(
                  color: mainColor,
                  fontSize: 30.0,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 10.0),
              Text(
                'Sign up to get started!',
                style: TextStyle(
                  color: Colors.black54,
                  fontSize: 16.0,
                ),
                textAlign: TextAlign.center,
              ),
              if (errorMessage.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 10.0),
                  child: Text(
                    errorMessage,
                    style: TextStyle(color: Colors.red, fontSize: 14.0),
                    textAlign: TextAlign.center,
                  ),
                ),
              SizedBox(height: 30.0),
              TextField(
                controller: emailController,
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.email, color: Colors.black),
                  hintText: 'EMAIL ADDRESS',
                  hintStyle: TextStyle(color: Colors.black54),
                  filled: true,
                  fillColor: Colors.grey.shade200,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                    borderSide: BorderSide.none,
                  ),
                ),
                style: TextStyle(color: Colors.black),
              ),
              SizedBox(height: 20.0),
              TextField(
                controller: passwordController,
                obscureText: !_passwordVisible,
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.lock, color: Colors.black),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _passwordVisible ? Icons.visibility : Icons.visibility_off,
                      color: Colors.black,
                    ),
                    onPressed: () {
                      setState(() {
                        _passwordVisible = !_passwordVisible;
                      });
                    },
                  ),
                  hintText: 'PASSWORD',
                  hintStyle: TextStyle(color: Colors.black54),
                  filled: true,
                  fillColor: Colors.grey.shade200,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                    borderSide: BorderSide.none,
                  ),
                ),
                style: TextStyle(color: Colors.black),
              ),
              SizedBox(height: 20.0),
              TextField(
                controller: confirmPasswordController,
                obscureText: !_confirmPasswordVisible,
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.lock, color: Colors.black),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _confirmPasswordVisible ? Icons.visibility : Icons.visibility_off,
                      color: Colors.black),
                    onPressed: () {
                      setState(() {
                        _confirmPasswordVisible = !_confirmPasswordVisible;
                      });
                    },
                  ),
                  hintText: 'CONFIRM PASSWORD',
                  hintStyle: TextStyle(color: Colors.black54),
                  filled: true,
                  fillColor: Colors.grey.shade200,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                    borderSide: BorderSide.none,
                  ),
                ),
                style: TextStyle(color: Colors.black),
              ),
              SizedBox(height: 20.0),
              InternationalPhoneNumberInput(
                onInputChanged: (PhoneNumber number) {
                  phoneNumber = number;
                },
                selectorConfig: SelectorConfig(
                  selectorType: PhoneInputSelectorType.DROPDOWN,
                ),
                ignoreBlank: false,
                autoValidateMode: AutovalidateMode.disabled,
                selectorTextStyle: TextStyle(color: Colors.black),
                initialValue: phoneNumber,
                textFieldController: TextEditingController(),
                formatInput: false,
                inputDecoration: InputDecoration(
                  hintText: 'PHONE NUMBER',
                  hintStyle: TextStyle(color: Colors.black54),
                  filled: true,
                  fillColor: Colors.grey.shade200,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                    borderSide: BorderSide.none,
                  ),
                ),
                inputBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                  borderSide: BorderSide.none,
                ),
                onSaved: (PhoneNumber number) {},
              ),
              SizedBox(height: 20.0),
              if (isSMSsent)
                TextField(
                  controller: smsController,
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.sms, color: Colors.black),
                    hintText: 'SMS CODE',
                    hintStyle: TextStyle(color: Colors.black54),
                    filled: true,
                    fillColor: Colors.grey.shade200,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  style: TextStyle(color: Colors.black),
                ),
              SizedBox(height: 30.0),
              ElevatedButton(
                onPressed: () async {
                  if (passwordController.text == confirmPasswordController.text) {
                    if (isSMSsent) {
                      try {
                        PhoneAuthCredential credential = PhoneAuthProvider.credential(
                          verificationId: verificationId,
                          smsCode: smsController.text,
                        );
                        await FirebaseAuth.instance.signInWithCredential(credential);
                        UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
                          email: emailController.text,
                          password: passwordController.text,
                        );
                        Navigator.pushReplacementNamed(context, '/instagram-login');
                      } catch (e) {
                        setState(() {
                          errorMessage = 'Failed to sign up. Please try again.';
                        });
                      }
                    } else {
                      try {
                        await FirebaseAuth.instance.verifyPhoneNumber(
                          phoneNumber: phoneNumber.phoneNumber!,
                          verificationCompleted: (PhoneAuthCredential credential) async {
                            await FirebaseAuth.instance.signInWithCredential(credential);
                          },
                          verificationFailed: (FirebaseAuthException e) {
                            setState(() {
                              errorMessage = e.message!;
                            });
                          },
                          codeSent: (String verificationId, int? resendToken) {
                            setState(() {
                              this.verificationId = verificationId;
                              isSMSsent = true;
                            });
                          },
                          codeAutoRetrievalTimeout: (String verificationId) {},
                        );
                      } catch (e) {
                        setState(() {
                          errorMessage = 'Failed to verify phone number. Please try again.';
                        });
                      }
                    }
                  } else {
                    setState(() {
                      errorMessage = 'Passwords do not match.';
                    });
                  }
                },
                child: Text(
                  isSMSsent ? 'VERIFY AND SIGN UP' : 'SEND SMS CODE',
                  style: TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 15.0),
                  backgroundColor: mainColor,
                  textStyle: TextStyle(fontSize: 18.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                ),
              ),
              SizedBox(height: 30.0),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(
                    "Already have an account?",
                    style: TextStyle(color: Colors.black54),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/login');
                    },
                    child: Text(
                      'Sign in',
                      style: TextStyle(color: mainColor),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
