import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:modal_progress_hud/modal_progress_hud.dart';
import 'package:odoo_api/odoo_api.dart';
import 'package:odoo_api/odoo_api_connector.dart';
import 'package:odoo_api/odoo_user_response.dart';
import 'package:odoo_api/odoo_version.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dataModel/stock_picking_type.dart';

void main ()=> runApp(ShowConnectData());
class ShowConnectData extends StatelessWidget{
  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return MaterialApp(
      title: "",
      home: StateFull_DataConnect(),
    );
  }

}
class StateFull_DataConnect extends StatefulWidget{
  @override
  State_ShowConnectData createState()=> State_ShowConnectData();
}
class State_ShowConnectData extends State<StateFull_DataConnect>{
  final txt_search = TextEditingController();
  bool _saving = false ;
  List<Stock_Picking_Type> mlist = [] ;
  static const EventChannel eventChannel =
  const EventChannel('samples.flutter.io/barcodereceived');
  String _barcodeRead = 'Barcode read: none';
  SharedPreferences prefs ;
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    eventChannel.receiveBroadcastStream().listen(_onEvent, onError: _onError);
    connectdataserver();
    _saving = true ;
  }
  void _onEvent(dynamic event) {
    setState(() {
      _barcodeRead = event;
    });

    checkbarcodeserver(_barcodeRead);
  }
  checkbarcodeserver(String ref) async{
    var client = new OdooClient("${prefs.getString("url")}");

      await client.authenticate("${prefs.getString("userlogin")}", "${prefs.getString("password")}", "${prefs.getString("database")}").then((AuthenticateCallback auth) async {
        if(auth.isSuccess) {
          final domain = [["barcode", "=", '${ref}']];
          final fields = ["id", "default_code", "barcode"];
          await client.searchRead("product.product", domain, fields, limit: 1, offset: 0, order: "create_date").then((OdooResponse result) async {
            if (!result.hasError()) {
              final data = result.getResult();
              for(var item in data['records']){
                final domain_line = [["product_id", "=", int.parse('${item['id']}')],["inventory_id", "=", int.parse('${prefs.getString("inventory_id")}')]];
                final fields_line = ["id", "product_name", "product_code","product_qty"];
                await client.searchRead("stock.inventory.line", domain_line, fields_line, limit: 5, offset: 0, order: "create_date").then((OdooResponse result) async {
                  if (!result.hasError()) {
                    final records = result.getResult();
                    if(records['length'] > 0 ){
                      for(var items in records['records']){
                        var piAsString = double.parse("${items['product_qty']}");
                        var change = piAsString.toStringAsFixed(0);
                        var count = 1 + int.parse("${change}");
                        update_countdata(int.parse('${items['id']}'), '${count}');
                      }
                    }else{
                      checkproduct_code(ref);
                    }
                    setState(() {
                      mlist.forEach((item){});
                      _saving = false ;
                    });
                  } else {
                    print (result.getError());
                  }
                });
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
  checkproduct_code(String ref) async
  {
    var client = new OdooClient("${prefs.getString("url")}");

      await client.authenticate("${prefs.getString("userlogin")}", "${prefs.getString("password")}", "${prefs.getString("database")}").then((AuthenticateCallback auth) async {
        if(auth.isSuccess) {
          final domain = [["default_code", "=", '${ref}']];
          final fields = ["id", "default_code", "barcode"];
          await client.searchRead("product.product", domain, fields, limit: 1, offset: 0, order: "create_date").then((OdooResponse result) async {
            if (!result.hasError()) {
              final data = result.getResult();
              for(var item in data['records']){
                final domain_line = [["product_id", "=", int.parse('${item['id']}')],["inventory_id", "=", int.parse('${prefs.getString("inventory_id")}')]];
                final fields_line = ["id", "product_name", "product_code","product_qty"];
                await client.searchRead("stock.inventory.line", domain_line, fields_line, limit: 5, offset: 0, order: "create_date").then((OdooResponse result) async {
                  if (!result.hasError()) {
                    final records = result.getResult();
                    if(records['length'] > 0 ){
                      for(var items in records['records']){
                        var piAsString = double.parse("${items['product_qty']}");
                        var change = piAsString.toStringAsFixed(0);
                        var count = 1 + int.parse("${change}");
                        update_countdata(int.parse('${items['id']}'), '${count}');
                      }
                    }else{
                      checkproduct_code(ref);
                    }
                    setState(() {
                      mlist.forEach((item){});
                      _saving = false ;
                    });
                  } else {
                    print (result.getError());
                  }
                });
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
  update_countdata(int line_id, String count) async
  {
    var client = new OdooClient("${prefs.getString("url")}");

      await client.authenticate("${prefs.getString("userlogin")}", "${prefs.getString("password")}", "${prefs.getString("database")}").then((AuthenticateCallback auth) async {
        if(auth.isSuccess) {
          final ids = [line_id];
          final valuesToUpdate = {
            "product_qty": "${count}"
          };
          await client.write("stock.inventory.line", ids, valuesToUpdate).then((result) {
            if(!result.hasError() && result.getResult()) {
              print("Updated");
              Navigator.push(context, MaterialPageRoute(builder: (context)=> ShowConnectData()));

            } else {
              print (result.getError());
            }
          });

        } else {

        }
      });

  }
  void _onError(dynamic error) {
    setState(() {
      _barcodeRead = 'Barcode read: unknown.';
    });
  }
  //ดึงข้อมูลมาแสดงผล
  connectdataserver() async {
    prefs = await SharedPreferences.getInstance() ;
    var client = new OdooClient("${prefs.getString("url")}");

      await client.authenticate("${prefs.getString("userlogin")}", "${prefs.getString("password")}", "${prefs.getString("database")}").then((AuthenticateCallback auth) async {
        if(auth.isSuccess) {
          final domain = [["inventory_id", "=", int.parse('${prefs.getString("inventory_id")}')]];
          final fields = ["id", "product_name", "product_code","product_qty"];
          await client.searchRead("stock.inventory.line", domain, fields, limit: 999, offset: 0, order: "create_date").then((OdooResponse result) async {
            if (!result.hasError()) {
              final data = result.getResult();
              for(var item in data['records']){
                mlist.add(Stock_Picking_Type('${item['id']}','${item['product_name']}','${item['product_code']}','${item['product_qty']}'));
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
      appBar: AppBar(
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.search),
            onPressed: (){
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  // return object of type Dialog
                  return AlertDialog(
                    title: new Text("ค้นหาเพิ่มเติม ?"),
                    content: new TextField(
                      controller: txt_search,
                    ),
                    actions: <Widget>[
                      new FlatButton(
                        child: Text("ยืนยัน"),
                        onPressed: (){
                          checkbarcodeserver('${txt_search.text}');
                          Navigator.of(context).pop();
                        },
                      ),
                      new FlatButton(
                        child: new Text("ปิด"),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                    ],
                  );
                },
              );
            },
          )
        ],
      ),
      body: ModalProgressHUD(inAsyncCall: _saving, child: listdatashow()),
    );
  }
  listdatashow(){
    return ListView.builder(
        itemCount: mlist.length,
        itemBuilder: (_, index){
          return Card(
            child: ListTile(
              title: Text("${mlist[index].name}"),
              subtitle: Text("${mlist[index].code}"),
              trailing: Text("${mlist[index].countorder}"),
            ),
          );
    });
  }
}