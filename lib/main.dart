import 'package:flutter/material.dart';
import 'package:modal_progress_hud/modal_progress_hud.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'mainmenu.dart';
import 'database/querydata.dart';
import 'database/insertdata.dart';
import 'database/updatedata.dart';
import 'database/database_helper.dart';
void main ()=> runApp(SettingMain());

class SettingMain extends StatelessWidget{
  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return MaterialApp(
      title: "LOGIN",
      home: StateFull_SettingMain(),
    );
  }
}
class StateFull_SettingMain extends StatefulWidget{
  @override
  _SettingMain createState()=> _SettingMain();
}
class _SettingMain extends State<StateFull_SettingMain>{
  SharedPreferences prefs ;
  final txt_ipserver = TextEditingController();
  final txt_database = TextEditingController();
  final txt_userlogin = TextEditingController();
  final txt_password = TextEditingController();
  final query = QueryData();
  final insert = InsertData();
  final update = UpdateData();
  bool _saving = false ;
  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Scaffold(
      appBar: AppBar(
        actions: <Widget>[],
      ),
      body: ModalProgressHUD(child:  Container(
        margin: EdgeInsets.only(left: 10.0, right: 10.0),
        child: ListView(
          children: <Widget>[
            TextField(
              controller: txt_ipserver,
              decoration: InputDecoration(
                  labelText: "IPServer :", hintText: "http://192.18.1.12:8069"
              ),
            ),
            TextField(
              controller: txt_database,
              decoration: InputDecoration(
                  labelText: "Database Name :", hintText: "Database Name"
              ),
            ),
            TextField(
              controller: txt_userlogin,
              decoration: InputDecoration(
                  labelText: "User Login", hintText: "User Login"
              ),
            ),
            TextField(
              controller: txt_password,
              decoration: InputDecoration(
                  labelText: "Password" , hintText: "Password"
              ),
            ),
            Container(
              margin: EdgeInsets.only(top: 15.0),
              child:  ButtonTheme(
                  height: 40.0,
                child: RaisedButton(
                  onPressed: (){
                    seve_server();
                    _saving = true ;
                  },
                  child: Text("Login"),
                  color: Colors.blue,
                ),
              )

            )

          ],
        ),
      ),inAsyncCall: _saving,)
    );
  }
  seve_server() async
  {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString("url","${txt_ipserver.text}");
    prefs.setString("database", "${txt_database.text}");
    prefs.setString("userlogin", "${txt_userlogin.text}");
    prefs.setString("password", "${txt_password.text}");
    setState(() {
      _saving = false ;
      Navigator.push(context, MaterialPageRoute(builder: (context)=> StateFull_MyHomePage()));
    });
  }
}