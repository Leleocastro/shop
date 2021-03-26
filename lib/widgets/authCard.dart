import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shop/providers/auth.dart';
import 'package:shop/exceptions/authException.dart';

enum AuthMode { Signup, Login }

class AuthCard extends StatefulWidget {
  @override
  _AuthCardState createState() => _AuthCardState();
}

class _AuthCardState extends State<AuthCard>
    with SingleTickerProviderStateMixin {
  GlobalKey<FormState> _form = GlobalKey();
  bool _isLoading = false;
  AuthMode _authMode = AuthMode.Login;
  final _passwordController = TextEditingController();

  AnimationController _controller;
  Animation<double> _opacityAnimation;
  Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(
        milliseconds: 300,
      ),
    );

    _opacityAnimation = Tween(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.linear,
      ),
    );

    _slideAnimation = Tween(
      begin: Offset(0.0, -1.0),
      end: Offset(0.0, 0.0),
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.linear,
      ),
    );
  }

  void dispose() {
    super.dispose();
    _controller.dispose();
  }

  final Map<String, String> _authData = {
    'email': '',
    'password': '',
  };

  void _showErrorDialog(String msg) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Ocorreu um erro!'),
        content: Text(msg),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text('Fechar'),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    if (!_form.currentState.validate()) {
      return;
    }
    setState(() {
      _isLoading = true;
    });

    _form.currentState.save();

    Auth auth = Provider.of(context, listen: false);
    try {
      if (_authMode == AuthMode.Login) {
        await auth.loginSignup(
          _authData['email'],
          _authData['password'],
          true,
        );
      } else {
        await auth.loginSignup(
          _authData['email'],
          _authData['password'],
          false,
        );
      }
    } on AuthException catch (error) {
      _showErrorDialog(error.toString());
    } catch (error) {
      _showErrorDialog('Ocorreu um erro inesperado!');
    }

    setState(() {
      _isLoading = false;
    });
  }

  void _switchAuthMode() {
    if (_authMode == AuthMode.Login) {
      setState(() {
        _authMode = AuthMode.Signup;
      });
      _controller.forward();
    } else {
      setState(() {
        _authMode = AuthMode.Login;
      });
      _controller.reverse();
    }
  }

  bool _hidePassword = true;

  @override
  Widget build(BuildContext context) {
    final deviceSize = MediaQuery.of(context).size;

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0),
      ),
      elevation: 8.0,
      child: AnimatedContainer(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeIn,
        height: _authMode == AuthMode.Login ? 280 : 340,
        // height: _heightAnimation.value.height,
        width: deviceSize.width * 0.75,
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _form,
          child: Column(
            children: [
              TextFormField(
                decoration: InputDecoration(labelText: 'E-mail'),
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                validator: (value) {
                  if (value.isEmpty || !value.contains('@')) {
                    return "Informe um e-mail válido!";
                  }
                  return null;
                },
                onSaved: (value) => _authData['email'] = value,
              ),
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Senha',
                  suffixIcon: IconButton(
                    icon: Icon(_hidePassword
                        ? Icons.visibility
                        : Icons.visibility_off),
                    onPressed: () {
                      setState(() {
                        _hidePassword = !_hidePassword;
                      });
                    },
                  ),
                ),
                textInputAction: TextInputAction.go,
                controller: _passwordController,
                obscureText: _hidePassword,
                validator: (value) {
                  if (value.isEmpty || value.length < 6) {
                    return "Informe uma senha válida!";
                  }
                  return null;
                },
                onSaved: (value) => _authData['password'] = value,
              ),
              AnimatedContainer(
                constraints: BoxConstraints(
                  minHeight: _authMode == AuthMode.Signup ? 80 : 0,
                  maxHeight: _authMode == AuthMode.Signup ? 140 : 0,
                ),
                duration: Duration(milliseconds: 300),
                curve: Curves.linear,
                child: FadeTransition(
                  opacity: _opacityAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: TextFormField(
                      decoration: InputDecoration(
                        labelText: 'Confirmar Senha',
                        suffixIcon: IconButton(
                          icon: Icon(_hidePassword
                              ? Icons.visibility
                              : Icons.visibility_off),
                          onPressed: () {
                            setState(() {
                              _hidePassword = !_hidePassword;
                            });
                          },
                        ),
                      ),
                      obscureText: _hidePassword,
                      validator: _authMode == AuthMode.Signup
                          ? (value) {
                              if (value != _passwordController.text ||
                                  value.isEmpty ||
                                  value.length < 6) {
                                return "Senhas são diferentes!";
                              }
                              return null;
                            }
                          : null,
                    ),
                  ),
                ),
              ),
              Spacer(),
              if (_isLoading)
                CircularProgressIndicator()
              else
                ElevatedButton(
                  style: ButtonStyle(
                    shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30.0),
                      ),
                    ),
                    padding: MaterialStateProperty.all<EdgeInsets>(
                      EdgeInsets.symmetric(
                        horizontal: 30,
                        vertical: 15,
                      ),
                    ),
                  ),
                  child: Text(
                    _authMode == AuthMode.Login ? 'ENTRAR' : 'REGISTRAR',
                  ),
                  onPressed: _submit,
                ),
              TextButton(
                onPressed: _switchAuthMode,
                child: Text(
                  'ALTERNAR PARA ${_authMode == AuthMode.Login ? 'REGISTRAR' : 'LOGIN'}',
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
