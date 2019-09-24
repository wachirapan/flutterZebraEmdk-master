import 'package:flutter/material.dart';
import 'package:odoo_api/odoo_api.dart';
import 'package:odoo_api/odoo_api_connector.dart';
import 'package:odoo_api/odoo_user_response.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'show_connectdata.dart';
import 'dataModel/stock_inventory.dart';
import 'database/database_helper.dart';
import 'dataModel/model_url.dart';
import 'database/insertdata.dart';
import 'database/querydata.dart';
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
  final querydata = QueryData();
  InsertData insertdata  = InsertData();
  List<Stock_Inventory> mlist = [];
  ModelURL_TEST url ;
  TextEditingController txt_search = new TextEditingController();
  final dbHelper = DatabaseHelper.instance;
  SharedPreferences prefs ;
  @override
  void initState() {
    // TODO: implement initState
    connect_odoo();

  }
  void connect_odoo() async {
    prefs = await SharedPreferences.getInstance();
    url = ModelURL_TEST.setData("${prefs.getString("url")}", "${prefs.getString("userlogin")}", "${prefs.getString("password")}", "${prefs.getString("database")}");
    var client = OdooClient("${url.setURL}");
    await client.connect().then((version) {
      client
          .authenticate("${url.username}", "${url.password}", "${url.database}")
          .then((AuthenticateCallback auth) {
        if (auth.isSuccess) {
          final ids = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10];
          final fields = ["id", "name", "state", "date"];
          client
              .read("stock.inventory", ids, fields,)
              .then((OdooResponse result) {
            if (!result.hasError()) {
              List records = result.getResult();
              for (var item in records) {
                print("${item['id']}+++++++++++++++++++${item['name']}");
                mlist.add(Stock_Inventory("${item['id']}", "${item['name']}",
                    "${item['date']}", "${item['state']}"));
                _query("${item['id']}", "${item['name']}", "${item['date']}",
                    "${item['state']}");
              }
              setState(() {
                //จำเป็นมาก เมื่อดึงข้อมูลแล้วให้ลูป setstate
                mlist.forEach((data) {
                  print("name : ${data.Stock_name}");
                });
              });
            } else {
              print(result.getError());
            }
          });
        } else {
          // login fail
        }
      });
    });
  }

  void _query(String stock_id, String name, String date, String state) async {
    final allRows = await querydata.queryAllRows("${stock_id}");

    if (allRows.length == 0) {
      _insert(stock_id, name, date, state);
    } else {
      print("not insert");
    }

    allRows.forEach((row) => print(row));
  }

  void _insert(
      String id_inventory, String name, String date, String state) async {
    // row to insert
    Map<String, dynamic> row = {
      DatabaseHelper.columnId: int.parse(id_inventory),
      DatabaseHelper.columnName: name,
      DatabaseHelper.columnDate: date,
      DatabaseHelper.columState: state
    };
    final id = await insertdata.insert(row);
    print('inserted row id: $id');
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Scaffold(
        appBar: AppBar(),
        body: Container(
            child: mlist.length == 0
                ? new Center(
              child: CircularProgressIndicator(),
            )
                : showDataList()));
  }

  showDataList() {
    return ListView.builder(
        itemCount: mlist.length,
        itemBuilder: (_, index) {
          return Card(
            child: ListTile(
              leading: Icon(Icons.print),
              title: Text("${mlist[index].Stock_name}"),
              subtitle: Text("${mlist[index].Stock_date}"),
              onTap: () async {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => StateFull_DataConnect(
                          stock: mlist[index],
                        )));

                SharedPreferences prefs = await SharedPreferences.getInstance();
                prefs.setString('pefStock_id', "${mlist[index].Stock_id}");
                prefs.setString('pefStock_name', "${mlist[index].Stock_name}");
                prefs.setString('pefStock_date', "${mlist[index].Stock_date}");
                prefs.setString('pefStock_state', "${mlist[index].Stock_state}");

              },
            ),
          );
        });
  }
}
