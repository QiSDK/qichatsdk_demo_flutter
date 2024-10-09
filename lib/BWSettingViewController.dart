import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

typedef DismissedCallback = void Function();

class BWSettingViewController extends StatefulWidget {
  final DismissedCallback? callBack;

  const BWSettingViewController({Key? key, this.callBack}) : super(key: key);

  @override
  _BWSettingViewControllerState createState() =>
      _BWSettingViewControllerState();
}

class _BWSettingViewControllerState extends State<BWSettingViewController> {
  final TextEditingController linesController = TextEditingController();
  final TextEditingController certController = TextEditingController();
  final TextEditingController merchantIdController = TextEditingController();
  final TextEditingController userIdController = TextEditingController();
  final TextEditingController userNameController = TextEditingController();
  final TextEditingController imgBaseUrlController = TextEditingController();
  final TextEditingController maxSessionMinsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    setupUI();
  }

  @override
  void dispose() {
    linesController.dispose();
    certController.dispose();
    merchantIdController.dispose();
    userIdController.dispose();
    userNameController.dispose();
    imgBaseUrlController.dispose();
    maxSessionMinsController.dispose();
    super.dispose();
  }

  void setupUI() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    linesController.text = prefs.getString('PARAM_LINES') ?? '';
    certController.text = prefs.getString('PARAM_CERT') ?? '';
    merchantIdController.text = (prefs.getInt('PARAM_MERCHANT_ID') ?? 0).toString();
    userIdController.text = (prefs.getInt('PARAM_USER_ID') ?? 0).toString();
    imgBaseUrlController.text = prefs.getString('PARAM_ImageBaseURL') ?? '';
    userNameController.text = prefs.getString('PARAM_USERNAME') ?? '';
    maxSessionMinsController.text = (prefs.getInt('PARAM_MAXSESSIONMINS') ?? 0).toString();
  }

  void dismissKeyboard() {
    FocusScope.of(context).unfocus();
  }

  Future<void> submitButtonTapped() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    String lines = linesController.text.trim();
    String cert = certController.text.trim();
    int merchantId = int.tryParse(merchantIdController.text.trim()) ?? 0;
    int userId = int.tryParse(userIdController.text.trim()) ?? 0;
    String baseUrlImage = imgBaseUrlController.text.trim();
    String userName = userNameController.text.trim();
    int maxSessionMins = int.tryParse(maxSessionMinsController.text.trim()) ?? 0;

    await prefs.setString('PARAM_LINES', lines);
    await prefs.setString('PARAM_CERT', cert);
    await prefs.setInt('PARAM_MERCHANT_ID', merchantId);
    await prefs.setInt('PARAM_USER_ID', userId);
    await prefs.setString('PARAM_ImageBaseURL', baseUrlImage);
    await prefs.setString('PARAM_USERNAME', userName);
    await prefs.setInt('PARAM_MAXSESSIONMINS', maxSessionMins);

    if (widget.callBack != null) {
      widget.callBack!();
    }

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: dismissKeyboard,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Settings'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTextField('Lines', linesController),
              _buildTextField('Cert', certController),
              _buildTextField('Merchant Id', merchantIdController),
              _buildTextField('User Id', userIdController),
              _buildTextField('User Name', userNameController),
              _buildTextField('Image Base URL', imgBaseUrlController),
              _buildTextField('Max Session Mins', maxSessionMinsController),
              SizedBox(height: 20),
              Center(
                child: ElevatedButton(
                  onPressed: submitButtonTapped,
                  child: Text('Submit'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label),
          SizedBox(height: 5),
          TextField(
            controller: controller,
            decoration: InputDecoration(
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
    );
  }
}
