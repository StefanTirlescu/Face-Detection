import 'package:flutter/material.dart';
import 'vision_detector_views/face_detector_view.dart';
import 'package:wakelock/wakelock.dart';
import 'vision_detector_views/settings_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_appauth/flutter_appauth.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Asigură-te că wakelock este activat pentru a menține ecranul pornit
  await Wakelock.enable();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, // Dezactivează banner-ul de debug
      home: Home(),
    );
  }
}

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  int _timerValue = 3; // Valoarea implicită a timer-ului
  late SharedPreferences _prefs;
  late String _serverUrl =
      'https://powerful-porpoise-certainly.ngrok-free.app'; // URL-ul implicit al serverului
  late String _accessToken = '';

  @override
  void initState() {
    super.initState();
    _loadPreferences(); // Încarcă preferințele salvate
  }

  // Încarcă preferințele din SharedPreferences
  Future<void> _loadPreferences() async {
    _prefs = await SharedPreferences.getInstance();
    setState(() {
      _serverUrl = _prefs.getString('serverUrl') ??
          'https://powerful-porpoise-certainly.ngrok-free.app';
    });
  }

  // Salvează preferințele în SharedPreferences
  Future<void> _savePreferences() async {
    await _prefs.setString('serverUrl', _serverUrl);
  }

  // Obține token-ul de autentificare folosind OAuth2
  Future<String?> getAuthToken() async {
    const String clientId =
        "studetapp-test-3bac3c96-27a5-43a4-8961-f2c9947633d6";
    const String redirectUrl = 'com.unitbv.studentapp:/';
    const String discoveryUrl =
        'https://auth.unitbv.ro/realms/unitbv/.well-known/openid-configuration';
    FlutterAppAuth appAuth = const FlutterAppAuth();

    // Solicită autorizare și schimbare de cod pentru a obține token-ul de acces
    AuthorizationTokenResponse? result = await appAuth.authorizeAndExchangeCode(
      AuthorizationTokenRequest(
        clientId,
        redirectUrl,
        discoveryUrl: discoveryUrl,
        scopes: ['openid', 'profile', 'offline_access'],
      ),
    );

    final String accessToken = result?.accessToken ?? "";

    if (accessToken.isNotEmpty) {
      return accessToken;
    } else {
      return null;
    }
  }

  // Obține informațiile utilizatorului folosind token-ul de acces
  void _getUserInfo(String accessToken) async {
    var urlInfo = Uri.parse(
        'https://auth.unitbv.ro/realms/unitbv/protocol/openid-connect/userinfo');
    var headersInfo = {'Authorization': 'Bearer $accessToken'};
    var responseInfo = await http.get(urlInfo, headers: headersInfo);

    if (responseInfo.statusCode == 200) {
      print(jsonDecode(responseInfo.body)['preferred_username']);
    } else {
      print('Eroare: ${responseInfo.statusCode}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('Login'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SettingsPage(
                    onNumberChanged: (timerValue) {
                      setState(() {
                        _timerValue = timerValue; // Actualizează valoarea timer-ului
                      });
                      print('Received value: $timerValue');
                    },
                    onTextChanged: (serverUrl) {
                      setState(() {
                        _serverUrl = serverUrl; // Actualizează URL-ul serverului
                      });
                      _savePreferences(); // Salvează URL-ul serverului actualizat
                      print('Received value: $serverUrl');
                    },
                    initialSliderValue: _timerValue,
                    initialTextFieldValue: _serverUrl,
                  ),
                ),
              );
            },
            icon: Icon(Icons.settings),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Fundalul ecranului
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/image-1.jpg'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          // Conținutul ecranului principal
          Container(
            margin: EdgeInsets.only(top: AppBar().preferredSize.height),
            child: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        SizedBox(height: 20),
                        // Butonul de login
                        Material(
                          color: Color(0xFFF1FADA),
                          child: InkWell(
                            onTap: () async {
                              String? accessToken = await getAuthToken();
                              if (accessToken != null) {
                                _getUserInfo(accessToken); // Obține informațiile utilizatorului
                                setState(() {
                                  _accessToken = accessToken; // Setează starea token-ului de acces
                                });
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => FaceDetectorView(
                                      timerValue: _timerValue,
                                      serverUrl: _serverUrl,
                                      accessToken: _accessToken,
                                    ),
                                  ),
                                );
                              } else {
                                print('Access token is null');
                              }
                            },
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                vertical: 15,
                              ),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: Colors.black,
                                  width: 2,
                                ),
                              ),
                              child: Text(
                                'Login into FaceDetection',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                  fontFamily: 'Open Sans',
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
