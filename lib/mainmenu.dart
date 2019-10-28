import 'package:flutter/material.dart';
import 'package:odoo_api/odoo_api.dart';
import 'package:odoo_api/odoo_api_connector.dart';
import 'package:odoo_api/odoo_user_response.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dataModel/stock_picking_type.dart';
import 'showlistorder.dart';
import 'maincountstock.dart';
import 'main.dart';
import 'database/database_helper.dart';
import 'database/insertdata.dart';
import 'database/updatedata.dart';
import 'database/querydata.dart';
import 'stock_onhand/search_stockonhand.dart';
import 'dataModel/model_url.dart';
void main ()=> runApp(MunuMainApp());

class MunuMainApp extends StatelessWidget {
  final appTitle = 'Inventory';

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: appTitle,
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    return StateFull_MyHomePage();
  }
}
class StateFull_MyHomePage extends StatefulWidget{
  @override
  State_MyHomePage createState() => State_MyHomePage();
}
class State_MyHomePage extends State<StateFull_MyHomePage>{
  List<Stock_Picking_Type> mlist = [];
  final dbHelper = DatabaseHelper.instance ;
  ModelURL_TEST test ;
  InsertData insertdata = InsertData();
  UpdateData updatedata = UpdateData();
  QueryData querydata = QueryData();
  SharedPreferences prefs ;
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    set_connect_server();

  }
  set_connect_server() async {
    prefs = await SharedPreferences.getInstance();
    test = ModelURL_TEST.setData("${prefs.getString("url")}", "${prefs.getString("userlogin")}", "${prefs.getString("password")}", "${prefs.getString("database")}");
    setState(() {
      connect_odoo_dashboards();
      getstock_location();
    });
  }
  connect_odoo_dashboards() async{
    print("*****************${test.setURL}***********${test.database}***********${test.username}***********${test.password}**");
    var client = new OdooClient("${prefs.getString("url")}");
      await client.authenticate("${prefs.getString("userlogin")}", "${prefs.getString("password")}", "${prefs.getString("database")}").then((AuthenticateCallback auth) async {
        if(auth.isSuccess) {
          final domain = [["active", "=", 't']];
          final fields = ["id", "name", "code","active"];
          await client.searchRead("stock.picking.type", domain, fields, limit: 10, offset: 0, order: "create_date").then((OdooResponse result) async {
            if (!result.hasError()) {
              final data = result.getResult();
              for(var item in data['records']){
                final domains = [["picking_type_id", "=", int.parse("${item['id']}")],["state", "=", "assigned"]];
                final fieldss = ["id", "name", "state","picking_type_id","location_id","location_dest_id","origin"];
                await client.searchRead("stock.picking", domains, fieldss, limit: 999, offset: 0, order: "create_date").then((OdooResponse result) {
                  if (!result.hasError()) {
                    final listcount = result.getResult();
                    mlist.add(Stock_Picking_Type("${item['id']}","${item['name']}","${item['code']}","${listcount['length']}"));
                    setState(()  {
                      mlist.forEach((item){
//                        print("***********${item.id}*************${item.name}");
                      });
                    });
                  }
                });
              }

            } else {
              print (result.getError());
            }
          });
        } else {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              // return object of type Dialog
              return AlertDialog(
                title: new Text("ไม่สามารถเข้าสู่ระบบได้ ?"),
                content: new Text("ไม่มีข้อมูลนี้ในระบบ"),
                actions: <Widget>[
                  
                  new FlatButton(
                    child: new Text("ปิด"),
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context)=> SettingMain()));
                     
                    },
                  ),
                ],
              );
            },
          );
        }
      });


  }
  getstock_location()async{
    var client = new OdooClient("${test.setURL}");

      await client.authenticate("${test.username}", "${test.password}", "${test.database}").then((AuthenticateCallback auth) async {
        if(auth.isSuccess) {
          final domain = [["parent_left", "!=", '']];
          final fields = ["id", "parent_left", "parent_right","name","complete_name","location_id"];
          await client.searchRead("stock.location", domain, fields, limit: 999, offset: 0, order: "create_date").then((OdooResponse result) async {
            if (!result.hasError()) {
              final data = result.getResult();
              for(var item in data['records']){

                if(item['location_id'] == false){
                  checkstock_location("${item['id']}","${item['parent_left']}","${item['parent_right']}","${item['name']}","${item['complete_name']}","false");
                }else{
                  checkstock_location("${item['id']}","${item['parent_left']}","${item['parent_right']}","${item['name']}","${item['complete_name']}","${item['location_id'][0]}");
                }
              }
            } else {
              print (result.getError());
            }
          });
        } else {
          // login fail
        }
      });


  }
  checkstock_location(String id, String left, String right, String name, String complete_name, String fk_id)async{
//    print("*********${name}");
    final rows = await querydata.querycheck_stocklocation("${id}");
    if(rows.length == 0){
      await insert_stockloacion("${id}","${left}","${right}","${name}","${complete_name}","${fk_id}");
    }else{
      await update_stocklocation("${id}","${left}","${right}","${name}","${complete_name}","${fk_id}");
    }
  }
  insert_stockloacion(String id, String left, String right, String name, String complete_name, String fk_id) async{
//    print("--------------------${name}");
    Map<String, dynamic> rows = {
      DatabaseHelper.stock_location_id : int.parse("${id}"),
      DatabaseHelper.stock_location_parent_left : int.parse("${left}"),
      DatabaseHelper.stock_location_parent_right : int.parse("${right}"),
      DatabaseHelper.stock_location_name :'${name}',
      DatabaseHelper.stock_location_complete_name : '${complete_name}',
      DatabaseHelper.stock_location_fk_id : "${fk_id}"
    };

    await insertdata.insert_stock_location(rows);
  }
  update_stocklocation(String id, String left, String right, String name, String complete_name, String fk_id)async{
    Map<String, dynamic> rows = {
      DatabaseHelper.stock_location_id : int.parse("${id}"),
      DatabaseHelper.stock_location_parent_left : int.parse("${left}"),
      DatabaseHelper.stock_location_parent_right : int.parse("${right}"),
      DatabaseHelper.stock_location_name :'${name}',
      DatabaseHelper.stock_location_complete_name : '${complete_name}',
      DatabaseHelper.stock_location_fk_id : "${fk_id}"
    };
    await updatedata.update_stocklocation(rows);
  }
  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Scaffold(
      appBar: AppBar(title: Text("INVENTORY")),
      body: mlist.length == 0 ? Center(child: CircularProgressIndicator(),) :showlist_dashboard(),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            SizedBox(
              height: 120.0,
              child: DrawerHeader(
                child: Text('INVENTORY MENU'),
                decoration: BoxDecoration(
                  color: Colors.blue,
                ),
              ),
            ),
            ListTile(
              title: Text('สินค้าคงคลัง'),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => StateFull_MyHomePage()));
              },
            ),
            ListTile(
              title: Text('นับสินค้า'),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context)=> StateFull_MainApp()));
              },
            ),
            ListTile(
              title: Text("สินค้าคงเหลือ"),
              onTap: (){
                Navigator.push(context, MaterialPageRoute(builder: (context)=>  StateFull_StockOnHand()));
              },
            )
          ],
        ),
      ),
    );
  }
  showlist_dashboard(){
    return ListView.builder(
        itemCount: mlist.length,
        itemBuilder: (_, index){
          return Card(
            child: ListTile(
              leading: Icon(Icons.airplay),
              title: Text("${mlist[index].name}"),
              subtitle: Text("${mlist[index].code}"),
              trailing: Text("${mlist[index].countorder}"),
              onTap: (){
                Navigator.push(context, MaterialPageRoute(builder: (context)=> StateFull_ShowListOrder(mlist: mlist[index],)));
                prefs.setString("picking_type_id", mlist[index].id);
              },
            ),
          );
        });
  }
}
