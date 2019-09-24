import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:modal_progress_hud/modal_progress_hud.dart';
import 'package:odoo_api/odoo_api.dart';
import 'package:odoo_api/odoo_api_connector.dart';
import 'package:odoo_api/odoo_user_response.dart';
import 'package:odoo_api/odoo_version.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../dataModel/model_url.dart';
void main ()=> runApp(StockOnHand());
class StockOnHand extends StatelessWidget{
  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return MaterialApp(
      title: "",
      home: StateFull_StockOnHand(),
    );
  }
}
class StateFull_StockOnHand extends StatefulWidget{
  @override
  _StockOnHand createState()=> _StockOnHand();
}

class _StockOnHand extends State<StateFull_StockOnHand>{
  ModelURL_TEST url ;
  static const EventChannel eventChannel =
  const EventChannel('samples.flutter.io/barcodereceived');
  String _barcodeRead = 'Not Barcode';
  String product_barcode, product_name, product_price, product_qty ;
  final txt_search = TextEditingController();
  bool _saving = false ;
  SharedPreferences prefs ;
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    eventChannel.receiveBroadcastStream().listen(_onEvent, onError: _onError);
  }
  void _onEvent(dynamic event) {
    setState(() {
      _barcodeRead = event;
      _saving = true ;
      check_qtyserver("${event}");
    });

  }
  check_qtyserver(String _barcodeRead) async
  {
    prefs = await SharedPreferences.getInstance();
    url = ModelURL_TEST.setData("${prefs.getString("url")}", "${prefs.getString("userlogin")}", "${prefs.getString("password")}", "${prefs.getString("database")}");
    product_barcode = "${_barcodeRead}";
    var client = new OdooClient("${url.setURL}");
    await client.connect().then((OdooVersion version) async {
      await client.authenticate("${url.username}", "${url.password}", "${url.database}").then((AuthenticateCallback auth) async {
        if(auth.isSuccess) {
          final domain = [["barcode", "=", '${_barcodeRead}']];
          final fields = ["id", "default_code", "product_tmpl_id"];
            await client.searchRead("product.product", domain, fields, limit: 10, offset: 0, order: "create_date").then((OdooResponse result) async {
            if (!result.hasError()) {
              final data = result.getResult();
              for(var item in data['records']){
                get_datatemplate("${item['product_tmpl_id'][0]}");
              }
            } else {

            }
          });
        } else {
          // login fail
        }
      });
    });
  }
  get_datatemplate(String product_tmpl_id) async{
    prefs = await SharedPreferences.getInstance();
    url =  ModelURL_TEST.setData("${prefs.getString("url")}", "${prefs.getString("userlogin")}", "${prefs.getString("password")}", "${prefs.getString("database")}");
    var client = new OdooClient("${url.setURL}");
    await client.connect().then((OdooVersion version) async {
      await client.authenticate("${url.username}", "${url.password}", "${url.database}").then((AuthenticateCallback auth) async {
        if(auth.isSuccess) {
          final domain = [["id", "=", int.parse("${product_tmpl_id}")]];
          final fields = ["id", "name","list_price","qty_available"];
          await client.searchRead("product.template", domain, fields, limit: 10, offset: 0, order: "create_date").then((OdooResponse result) async {
            if (!result.hasError()) {
              final data = result.getResult();
              for(var item in data['records']){
                product_name = "${item['name']}";
                product_price = "${item['list_price']}";
                product_qty = "${item['qty_available']}";
              }
              setState(() {
                _saving = false ;
              });
            } else {

            }
          });
        } else {
          // login fail
        }
      });
    });
  }
  checkref(String ref) async
  {
    prefs = await SharedPreferences.getInstance();
    url =  ModelURL_TEST.setData("${prefs.getString("url")}", "${prefs.getString("userlogin")}", "${prefs.getString("password")}", "${prefs.getString("database")}");
    product_barcode = "${ref}";
    var client = new OdooClient("${url.setURL}");
    await client.connect().then((OdooVersion version) async {
      await client.authenticate("${url.username}", "${url.password}", "${url.database}").then((AuthenticateCallback auth) async {
        if(auth.isSuccess) {
          final domain = [["default_code", "=", '${ref}']];
          final fields = ["id", "default_code", "product_tmpl_id"];
          await client.searchRead("product.product", domain, fields, limit: 10, offset: 0, order: "create_date").then((OdooResponse result) async {
            if (!result.hasError()) {
              final data = result.getResult();
              for(var item in data['records']){
                get_datatemplate("${item['product_tmpl_id'][0]}");
              }
            } else {

            }
          });
        } else {
          // login fail
        }
      });
    });
  }
  void _onError(dynamic error) {
    setState(() {
      _barcodeRead = 'Barcode read: unknown.';
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
                    title: new Text("ค้นหาเพิ่มเติมเลขอ้างอิง"),
                    content: TextField(
                      controller: txt_search,
                    ),
                    actions: <Widget>[
                      new FlatButton(
                        child: Text("ค้นหา"),
                        onPressed: (){
                          _saving = true;
                          checkref("${txt_search.text}");
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
      body: ModalProgressHUD(child: listproduct_onhand(),inAsyncCall: _saving,),
    );
  }
  listproduct_onhand(){
    return Container(
      margin: EdgeInsets.only(top: 5.0,left: 5.0, right: 5.0),

      child: ListView(
        children: <Widget>[
          Card(
            child: ListTile(
              title: Text("รหัสสินค้า : "),
              subtitle: Text("${product_barcode}"),
            ),
          ),
          Card(
            child: ListTile(
              title: Text("สินค้า : "),
              subtitle: Text("${product_name}"),
            ),
          ),
          Card(
            child: ListTile(
              title: Text("ราคาสินค้า : "),
              subtitle: Text("${product_price}"),
            ),
          ),
          Card(
            child: ListTile(
              title: Text("จำนวนสินค้า : "),
              subtitle: Text("${product_qty}"),
            ),
          ),
        ],
      ),
    );
  }
}