import 'package:flutter/material.dart';
import 'package:odoo_api/odoo_api.dart';
import 'package:odoo_api/odoo_api_connector.dart';
import 'package:odoo_api/odoo_user_response.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dataModel/stock_inventory.dart';
import 'database/database_helper.dart';
import 'package:intl/intl.dart';
import 'countofstock.dart';
import 'dataModel/model_url.dart';
import 'database/insertdata.dart';
import 'database/querydata.dart';
void main() => runApp(DataConnect());

class DataConnect extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return MaterialApp(
      title: "",
      home: StateFull_DataConnect(),
    );
  }
}

class StateFull_DataConnect extends StatefulWidget {
  Stock_Inventory stock;

  StateFull_DataConnect({Key key, @required this.stock}) : super(key: key);

  @override
  State_DataConnect createState() => State_DataConnect();
}

class State_DataConnect extends State<StateFull_DataConnect> {
  final dbHelper = DatabaseHelper.instance;
  ModelURL_TEST url ;
  QueryData querydata = QueryData();
  InsertData insertdata = InsertData();
  SharedPreferences prefs ;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    connect_odoogetData();
  }

  Future<bool> connect_odoogetData() async {
    prefs = await SharedPreferences.getInstance();
    url = ModelURL_TEST.setData("${prefs.getString("url")}", "${prefs.getString("userlogin")}", "${prefs.getString("password")}", "${prefs.getString("database")}");
    var client = OdooClient("${url.setURL}");
    await client.connect().then((version) async {
      await client
          .authenticate("${url.username}", "${url.password}", "${url.database}")
          .then((AuthenticateCallback auth) async {
        if (auth.isSuccess) {
          //แถวหนึ่ง stock.inventory.line
          final domain = [
            [
              "inventory_id",
              "=",
              [widget.stock.Stock_id, widget.stock.Stock_name]
            ]
          ];
          final fields = [
            "id",
            "product_name",
            "product_qty",
            "theoretical_qty",
            "product_code",
            "product_id"
          ];
          await client.searchRead("stock.inventory.line", domain, fields,
                  limit: 99, offset: 0, order: "create_date")
              .then((OdooResponse result) async {
            if (!result.hasError()) {
              final records = result.getResult();

              for (var item in records['records']) {
                print("*****************${item['product_id'][0]}");
                //แถวสองหา product.product
                final domains = [["id", "=", item['product_id'][0]]];
                final fields_product = ["id", "barcode", "name"];
                await client.searchRead("product.product", domains, fields_product, limit: 99, offset: 0, order: "create_date").then((OdooResponse result) {
                  if (!result.hasError()) {
                    final listproduct = result.getResult();
                    for (var data in listproduct['records']) {
                      _checkdb(
                          "${item['id']}",
                          "${data['id']}",
                          "${data['name']}",
                          "${data['barcode']}",
                          "${item['product_code']}",
                          "${item['theoretical_qty']}",
                          "${item['product_qty']}");
                      print(
                          "++++${item['product_name']}++++++++${data['barcode']}++++++++${item['product_code']}");
                    }

                  } else {
                    print(result.getError());
                  }
                });
              }
            } else {
              print(result.getError());
            }
          });
        }
      });
    });
    return true ;
  }

  void _checkdb(
      String line_id,
      String product_id,
      String name_product,
      String barcode,
      String product_code,
      String theoretical_qty,
      String product_qty) async {
    final rows = await querydata.qcheckordreline(line_id);
    print("*******************${rows}");
    if (rows.length > 0) {
      print("มีข้อมูลแล้ว");
    } else {
      _insert(line_id, product_id, name_product, barcode, product_code,
          theoretical_qty, product_qty);
    }
  }

  _insert(
      String line_id,
      String product_id,
      String name_product,
      String barcode,
      String product_code,
      String theoretical_qty,
      String product_qty) async {
    // row to insert
    DateTime now = DateTime.now();
    String formattedDate = DateFormat("dd-MM-yyyy hh:mm:ss").format(now);
    Map<String, dynamic> row = {
      DatabaseHelper.line_id: int.parse(line_id),
      DatabaseHelper.product_id: product_id,
      DatabaseHelper.name_product: name_product,
      DatabaseHelper.barcode: barcode,
      DatabaseHelper.product_code: product_code,
      DatabaseHelper.theoretical_qty: theoretical_qty,
      DatabaseHelper.product_qty: product_qty,
      DatabaseHelper.create_dateline: formattedDate,
    };
    final id = await insertdata.insert_proudctdetail(row);
    print('inserted row id: $id');

  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Scaffold(
      appBar: AppBar(),
      body: FutureBuilder(
          future: connect_odoogetData(),
          builder: (BuildContext context, AsyncSnapshot snapshot){
            if(snapshot.hasData){
              return Container(
                margin: EdgeInsets.only(left: 10.0, right: 10.0, top: 10.0),
                child: ListView(
                  children: <Widget>[
                    Text("หมายเลขเอกสาร : ${widget.stock.Stock_name}"),
                    Text("วันที่สร้างเอกสาร : ${widget.stock.Stock_date}"),
                    Text("สถานะเอกสาร : ${widget.stock.Stock_state}"),
                    RaisedButton(
                      onPressed: () {
                        Navigator.push(context,
                            MaterialPageRoute(builder: (context) => MyApp()));
                      },
                      child: Text(
                        "Next Step",
                      ),
                      color: Colors.blue,
                    )
                  ],
                ),
              );
            }else{
              return Center(
                child: CircularProgressIndicator(),
              );
            }

      })
    );
  }
}
