import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:modal_progress_hud/modal_progress_hud.dart';
import 'package:odoo_api/odoo_api.dart';
import 'package:odoo_api/odoo_api_connector.dart';
import 'package:odoo_api/odoo_user_response.dart';
import 'dataModel/inventory_line.dart';
import 'database/database_helper.dart';
import 'dataModel/model_url.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'syncdataserver.dart';
import 'database/querydata.dart';
import 'database/insertdata.dart';
import 'database/updatedata.dart';
void main() => runApp(new MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      title: 'Flutter Demo with Zebra EMDK',
      theme: new ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: new MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => new _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  QueryData querydata = QueryData();
  InsertData insertdata = InsertData();
  UpdateData updatedata = UpdateData();
  int prefstock_id ;
  String prefname ;
  final dbHelper = DatabaseHelper.instance;
  ModelURL_TEST url ;
  TextEditingController txt_search = new TextEditingController();
  static const EventChannel eventChannel =
      const EventChannel('samples.flutter.io/barcodereceived');
  String _barcodeRead = 'Barcode read: none';
  List<InventoryLine> mlist = [];
  bool _saving = false;
  SharedPreferences prefs ;
  @override
  Future initState()  {
    super.initState();
    eventChannel.receiveBroadcastStream().listen(_onEvent, onError: _onError);
    _query();
  }
  void _onEvent(dynamic event) {
    setState(() {
      _barcodeRead = event;
    });
    _checkbarcode(_barcodeRead);
  }
  void _onError(dynamic error) {
    setState(() {
      _barcodeRead = 'Barcode read: unknown.';
    });
  }
  void _checkbarcode(String barcode) async {

    final rows = await querydata.qcheck_product_barcode(barcode);
    if (rows.length == 0) {
      final referend_rows = await querydata.qcheck_product_referend(barcode);
      if (referend_rows.length == 0) {
        print("ไม่มีข้อมูล+++++++++++${barcode}");
//        connect_odoo_checknewlist(barcode);
      } else {
        referend_rows.forEach((item) {
          final count = item['product_qty'] + 1;
          _updatecount_data("${item['line_id']}", "${count}");
        });
        Navigator.push(
            context, MaterialPageRoute(builder: (context) => MyApp()));
      }
    } else {
      rows.forEach((item) {
        final count = item['product_qty'] + 1;
        print("******${count}*******");
        _updatecount_data("${item['line_id']}", "${count}");
      });
      Navigator.push(context, MaterialPageRoute(builder: (context) => MyApp()));
    }
  }

  connect_odoo_checknewlist(String barcode) async {
    prefs = await SharedPreferences.getInstance();
    url =  ModelURL_TEST.setData("${prefs.getString("url")}", "${prefs.getString("userlogin")}", "${prefs.getString("password")}", "${prefs.getString("database")}");
    var client = OdooClient("${url.setURL}");
    await client.connect().then((version) {
      client
          .authenticate("${url.username}", "${url.password}", "${url.database}")
          .then((AuthenticateCallback auth) {
        if (auth.isSuccess) {
          final domain = [
            ["barcode", "=", barcode]
          ];
          final fields = ["id", "default_code", "barcode"];
          client.searchRead("product.product", domain, fields,
                  limit: 10, offset: 0, order: "create_date")
              .then((OdooResponse result) async {
            if (!result.hasError()) {
              final records = result.getResult();
              print("${records['length']}");
              if (records['length'] == 0) {
                final domain = [
                  ["default_code", "=", barcode]
                ];
                final fields = ["id", "default_code", "barcode"];
                client
                    .searchRead("product.product", domain, fields,
                        limit: 10, offset: 0, order: "create_date")
                    .then((OdooResponse result) {
                  if (!result.hasError()) {
                    final records = result.getResult();
                    if (records['length'] == 0) {
                      print("ไม่มีบนserver");
                    } else {
                      for (var item in records['records']) {
                        _update_row_productbarcode("${item['id']}",
                            "${item['barcode']}", "${item['default_code']}");
                      }
                    }
                  } else {
                    print(result.getError());
                  }
                });
              } else {
                for (var item in records['records']) {
                  _update_row_productbarcode("${item['id']}",
                      "${item['barcode']}", "${item['default_code']}");
                }
              }
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

  _update_row_productbarcode(String id, String barcode, String ref) async {
    Map<String, dynamic> row = {
      DatabaseHelper.product_id: int.parse(id),
      DatabaseHelper.barcode: barcode,
      DatabaseHelper.product_code: ref
    };
    final rowsAffected = await updatedata.update_barcode(row);
//    print('updated $rowsAffected row(s)');
  }

  _updatecount_data(String line_id, String count) async {
    DateTime now = DateTime.now();
    String formattedDate = DateFormat("dd-MM-yyyy hh:mm:ss").format(now);
    Map<String, dynamic> row = {
      DatabaseHelper.line_id: int.parse(line_id),
      DatabaseHelper.product_qty: int.parse(count),
      DatabaseHelper.create_dateline: formattedDate,
    };
    final rowaffected = await updatedata.update_countdata(row);
  }

  _query() async {
    final allRows = await querydata.query_orderline();
    allRows.forEach((row) => mlist.add(InventoryLine(
        "${row['line_id']}",
        "${row['product_id']}",
        "${row['barcode']}",
        "${row['name_product']}",
        "${row['product_code']}",
        "${row['theoretical_qty']}",
        "${row['product_qty']}",
        "${row['create_dateline']}")));
    setState(() {
      mlist.forEach((item){
//        print("**************${item.product_code}*************${item.barcode}");
      });
    });
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefstock_id = int.parse(prefs.getString("pefStock_id"));
    prefname = prefs.getString("pefStock_name");
    print("++++++++++++++++++++${prefstock_id}-----------${prefname}");
  }



  @override
  Widget build(BuildContext context) {
    return new Scaffold(
        appBar: new AppBar(
          leading: IconButton(icon: Icon(Icons.cached), onPressed: (){
            showDialog(
              context: context,
              builder: (BuildContext context) {
                // return object of type Dialog
                return AlertDialog(
                  title: new Text("อัพเดทข้อมูลใหม่?"),
                  content: new Text("คุณต้องการอัพเดทข้อมูลใหม่หรือไม่ ใหม่หรือไม!"),
                  actions: <Widget>[
                    new FlatButton(
                      child: Text("ยืนยัน"),
                      onPressed: (){
                        connect_odoogetData();
                        setState(() {
                          _saving = true;
                        });

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
          }),
          actions: <Widget>[
            IconButton(
                icon: Icon(Icons.add),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      // return object of type Dialog
                      return AlertDialog(
                        title: new Text("ค้นหาเพิ่มเติม"),
                        content: new TextField(
                          controller: txt_search,
                          decoration: InputDecoration(
                            labelText: "ค้นหาจากบาร์โค้ด หรือ เอกสารอ้างอิง"
                          ),
                        ),
                        actions: <Widget>[
                          new FlatButton(
                            child: Text("ค้นหา"),
                            onPressed: (){
                              _checkbarcode("${txt_search.text}");
                              txt_search.text = "";
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
                }),
            IconButton(
              icon: Icon(Icons.wb_cloudy),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    // return object of type Dialog
                    return AlertDialog(
                      title: new Text("ยืนยันการจัดเก็บ"),
                      content: new Text("คุณต้องการจัดเก็บข้อมูลบน server ไหม ?"),
                      actions: <Widget>[
                        // usually buttons at the bottom of the dialog
                        new FlatButton(
                          child: new Text("ยืนยัน"),
                          onPressed: () {
                            Navigator.push(context, MaterialPageRoute(builder: (context)=> StateFull_ConectServer()));
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
          title: Text(""),
        ),
        body: ModalProgressHUD(child: showListView(), inAsyncCall: _saving),
    );
  }

  showListView() {
    return ListView.builder(
        itemCount: mlist.length,
        itemBuilder: (_, index) {
          return Card(
            child: ListTile(
              leading: Icon(Icons.airplay),
              title: Text("${mlist[index].name_product}"),
              subtitle: Text("ON HAND : ${mlist[index].theoretical_qty}"),
              trailing: Text("${mlist[index].product_qty}"),
            ),
          );
        });
  }

  connect_odoogetData() async {
    prefs = await SharedPreferences.getInstance();
    url =  ModelURL_TEST.setData("${prefs.getString("url")}", "${prefs.getString("userlogin")}", "${prefs.getString("password")}", "${prefs.getString("database")}");
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

              ["${prefstock_id}", "${prefname}"]
            ]
          ];
          final fields = [
            "id",
            "product_name",
            "product_qty",
            "theoretical_qty",
            "product_code"
          ];
          await client.searchRead("stock.inventory.line", domain, fields,
              limit: 99, offset: 0, order: "create_date")
              .then((OdooResponse result) async {
            if (!result.hasError()) {
              final records = result.getResult();
              for (var item in records['records']) {
                //แถวสองหา product.product
                final domain = [
                  ["name", "=", item['product_name']]
                ];
                final fields = ["id", "barcode"];
                await client.searchRead("product.product", domain, fields,
                    limit: 99, offset: 0, order: "create_date")
                    .then((OdooResponse result) {
                  if (!result.hasError()) {
                    final records = result.getResult();
                    for (var data in records['records']) {
                      _checkdb(
                          "${item['id']}",
                          "${data['id']}",
                          "${item['product_name']}",
                          "${data['barcode']}",
                          "${item['product_code']}",
                          "${item['theoretical_qty']}",
                          "${item['product_qty']}");
//                      print(
//                          "++++${item['product_name']}++++++++${data['barcode']}++++++++${item['product_code']}");
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
    setState(() {
      _saving = false;
    });
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
}
