import 'package:flutter/material.dart';

class SettingsPage extends StatefulWidget {
  final ValueChanged<int> onNumberChanged;
  final ValueChanged<String> onTextChanged;
  final int initialSliderValue;
  final String initialTextFieldValue;

  const SettingsPage({
    Key? key,
    required this.onNumberChanged,
    required this.onTextChanged,
    required this.initialSliderValue,
    required this.initialTextFieldValue,
  }) : super(key: key);

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late TextEditingController _textFieldController;
  late double _sliderValue;
  late String _textFieldValue;

  @override
  void initState() {
    super.initState();
    // Inițializare valoarea slider-ului si a campului pentru URL
    _sliderValue = widget.initialSliderValue.toDouble();
    _textFieldValue = widget.initialTextFieldValue;
    _textFieldController = TextEditingController(text: _textFieldValue);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Imaginea de fundal
        Image.asset(
          'assets/images/image-1.jpg',
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
        ),
        Scaffold(
          appBar: AppBar(
            title: Text('Settings'),
            backgroundColor: Colors.transparent, 
            elevation: 0, 
          ),
          backgroundColor: Colors.transparent, 
          body: Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Select a number for the timer:',
                    style: TextStyle(color: Colors.white)),
                Slider(
                  value: _sliderValue,
                  onChanged: (newValue) {
                    setState(() {
                      _sliderValue = newValue;
                    });
                  },
                  min: 1,
                  max: 10,
                  divisions: 9,
                  label: _sliderValue.round().toString(),
                ),
                SizedBox(height: 20),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white), 
                    borderRadius:
                        BorderRadius.circular(8.0), 
                  ),
                  child: TextField(
                    controller: _textFieldController,
                    style: TextStyle(
                        color: Colors.white), 
                    onChanged: (value) {
                      setState(() {
                        _textFieldValue = value; // Actualizează valoarea câmpului de text
                      });
                      widget.onTextChanged(value); // Notifică schimbarea textului
                    },
                    decoration: InputDecoration(
                      hintText: 'Enter a string', 
                      hintStyle: TextStyle(
                          color: Colors.white
                              .withOpacity(0.5)), 
                      border: InputBorder.none, 
                    ),
                  ),
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    widget.onNumberChanged(_sliderValue.round()); // Notifică schimbarea valorii slider-ului
                    Navigator.pop(context); // Închide pagina de setări
                  },
                  child: Text('Save'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _textFieldController.dispose();
    super.dispose();
  }
}
