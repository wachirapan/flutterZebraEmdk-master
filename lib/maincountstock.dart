import 'package:flutter/material.dart';
import 'package:modal_progress_hud/modal_progress_hud.dart';
import 'package:odoo_api/odoo_api.dart';
import 'package:odoo_api/odoo_api_connector.dart';
import 'package:odoo_api/odoo_user_response.dart';
import 'package:odoo_api/odoo_version.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dataModel/stock_inventory.dart';
import 'show_connectdata.dart';

void main() => runApp(MainApp());

class MainApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return MaterialApp(
      title: "",
      home: StateFull_MainApp(),
    );
  }
}

class StateFull_MainApp extends StatefulWidget {
  @override
  State_MainApp createState() => State_MainApp();
}

class State_MainApp extends State<StateFull_MainApp> {
  List<Stock_Inventory> mlist = [] ;
  bool _saving = false ;
  SharedPreferences prefs ;
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _saving = true ;
    connect_odoo();
  }
  connect_odoo() async {
    prefs = await SharedPreferences.getInstance() ;
    var client = new OdooClient("${prefs.getString("url")}");

      await client.authenticate("${prefs.getString("userlogin")}", "${prefs.getString("password")}", "${prefs.getString("database")}").then((AuthenticateCallback auth) async {
        if(auth.isSuccess) {
          final domain = [["state", "=", 'confirm']];
          final fields = ["id", "name", "state","date"];
          await client.searchRead("stock.inventory", domain, fields, limit: 10, offset: 0, order: "create_date").then((OdooResponse result) async {
            if (!result.hasError()) {
              final data = result.getResult();
              for(var item in data['records']){
                mlist.add(Stock_Inventory('${item['id']}','${item['name']}','${item['date']}','${item['state']}'));
              }
              setState(() {
                mlist.forEach((item){});
                _saving = false ;
              });
            } else {
              print (result.getError());
            }
          });
        } else {
          // login fail
        }
      });

  }
  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Scaffold(
      appBar: AppBar(),
      body: ModalProgressHUD(inAsyncCall: _saving, child: listinventoty())
    );
  }
 listinventoty()
 {
   return ListView.builder(
       itemCount: mlist.length,
       itemBuilder: (_, index){
     return Card(
       child: ListTile(
         title: Text('${mlist[index].Stock_name}'),
         subtitle: Text('${mlist[index].Stock_date}'),
        onTap: (){
          Navigator.push(context, MaterialPageRoute(builder: (context)=> StateFull_DataConnect()));
          prefs.setString("inventory_id","${mlist[index].Stock_id}");
        }
       ),
     );
   });
 }
}