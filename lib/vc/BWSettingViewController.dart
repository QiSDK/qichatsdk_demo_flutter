import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../Constant.dart';

typedef DismissedCallback = void Function();

class BWSettingViewController extends StatefulWidget {
  final DismissedCallback? callBack;

  const BWSettingViewController({Key? key, this.callBack}) : super(key: key);

  @override
  _BWSettingViewControllerState createState() =>
      _BWSettingViewControllerState();
}

class _BWSettingViewControllerState extends State<BWSettingViewController> {

  final List<String> labels = [
    'Lines',
    'Cert',
    'Merchant Id',
    'User Id',
    'User Name',
    'Image Base URL',
    'Max Session Mins',
    'User Type'
  ];
  final List<TextEditingController> controllers = List.generate(7, (index) => TextEditingController());
  
  int selectedUserType = 0;
  final Map<int, String> userTypeMap = {
    0: '官方会员',
    1: '邀请好友',
    2: '合营会员'
  };


  @override
  void initState() {
    super.initState();
    setupUI();
  }

  @override
  void dispose() {
    for (var controller in controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void setupUI() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    controllers[0].text = prefs.getString(PARAM_LINES) ?? lines;
    controllers[1].text = prefs.getString('PARAM_CERT') ?? cert;
    controllers[2].text = (prefs.getInt('PARAM_MERCHANT_ID') ?? merchantId).toString();
    controllers[3].text = (prefs.getInt('PARAM_USER_ID') ?? userId).toString();
    controllers[4].text = prefs.getString('PARAM_USERNAME') ?? userName;
    controllers[5].text = prefs.getString('PARAM_ImageBaseURL') ?? baseUrlImage;
    controllers[6].text = (prefs.getInt('PARAM_MAXSESSIONMINS') ?? maxSessionMins).toString();
    
    setState(() {
      int savedUserType = prefs.getInt(PARAM_USERTYPE) ?? usertype - 1;
      // 确保 selectedUserType 在有效范围内 (0, 1, 2)
      selectedUserType = savedUserType >= 0 && savedUserType <= 2 ? savedUserType : 0;
    });
  }

  void dismissKeyboard() {
    FocusScope.of(context).unfocus();
  }

  Future<void> submitButtonTapped() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

     lines = controllers[0].text.trim();
     cert = controllers[1].text.trim();
     merchantId = int.tryParse(controllers[2].text.trim()) ?? 0;
     userId = int.tryParse(controllers[3].text.trim()) ?? 0;
     baseUrlImage = controllers[5].text.trim();
     userName = controllers[4].text.trim();
     maxSessionMins = int.tryParse(controllers[6].text.trim()) ?? 0;
     xToken = "";

    await prefs.setString(PARAM_LINES, lines);
    await prefs.setString('PARAM_CERT', cert);
    await prefs.setString(PARAM_XTOKEN, "");
    await prefs.setInt('PARAM_MERCHANT_ID', merchantId);
    await prefs.setInt('PARAM_USER_ID', userId);
    await prefs.setString('PARAM_ImageBaseURL', baseUrlImage);
    await prefs.setString('PARAM_USERNAME', userName);
    await prefs.setInt('PARAM_MAXSESSIONMINS', maxSessionMins);
    await prefs.setInt(PARAM_USERTYPE, selectedUserType);
    usertype = selectedUserType + 1;

    if (widget.callBack != null) {
      widget.callBack!();
    }

    debugPrint("选择的usertype是$usertype");

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
              Expanded(
                  child: ListView.builder(
                    itemCount: labels.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            index == labels.length - 1
                                ? _buildUserTypeDropdown()
                                : _buildTextField(labels[index], controllers[index])
                          ],
                        ),
                      );
                      },
          )),

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
      padding: const EdgeInsets.symmetric(vertical: 2.0),
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

  Widget _buildUserTypeDropdown() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('User Type'),
          SizedBox(height: 5),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.0),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(4.0),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: userTypeMap.containsKey(selectedUserType) ? selectedUserType : 0,
                isExpanded: true,
                items: userTypeMap.entries.map((entry) {
                  return DropdownMenuItem<int>(
                    value: entry.key,
                    child: Text('${entry.key + 1}-${entry.value}'),
                  );
                }).toList(),
                onChanged: (int? newValue) {
                  if (newValue != null) {
                    setState(() {
                      selectedUserType = newValue;
                    });
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
