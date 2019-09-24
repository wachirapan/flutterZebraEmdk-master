import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:modal_progress_hud/modal_progress_hud.dart';
import 'package:odoo_api/odoo_api.dart';
import 'package:odoo_api/odoo_api_connector.dart';
import 'package:odoo_api/odoo_user_response.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dataModel/model_url.dart';
import 'database/database_helper.dart';

import 'database/querydata.dart';
import 'database/updatedata.dart';
import 'database/deletedata.dart';
void main() => runApp(ConectServer());

class ConectServer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return MaterialApp(
      title: "",
      home: StateFull_ConectServer(),
    );
  }
}

class StateFull_ConectServer extends StatefulWidget {
  @override
  State_ConectServer createState() => State_ConectServer();
}

class State_ConectServer extends State<StateFull_ConectServer> {
  ModelURL_TEST url ;
  int prefstock_id;
  String prefname;
  bool _saving = false;
  final dbHelper = DatabaseHelper.instance;
  SharedPreferences prefs ;
  QueryData querydata = QueryData();
  UpdateData updatedata = UpdateData();
  DeleteData deletedata = DeleteData();
  @override
  Future initState() {
    super.initState();
    _saving = true;
    getSetSESSIOn();
    mergedata();
  }

  getSetSESSIOn() async {
    prefs = await SharedPreferences.getInstance();
    prefstock_id = int.parse(prefs.getString("pefStock_id"));
    prefname = prefs.getString("pefStock_name");
    print("++++++++++++++++++++${prefstock_id}-----------${prefname}");
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Scaffold(
      appBar: AppBar(),
      body: ModalProgressHUD(
          child: Container(
            child: Text("wait"),
          ),
          inAsyncCall: _saving),
    );
  }

  mergedata() async {
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
          await client
              .searchRead("stock.inventory.line", domain, fields,
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
                await client
                    .searchRead("product.product", domain, fields,
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
//      _saving = false;
      upload_toserver();
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
      rows.forEach((item) {
        var piAsString = double.parse("${product_qty}");
        var change = piAsString.toStringAsFixed(0);
        var count = item['product_qty'] + int.parse("${change}");
//        print("***********${count}***************");
        _updatecount_data(int.parse("${line_id}"), "${count}");
      });
    }
  }

  _updatecount_data(int line_id, String count) async {
    DateTime now = DateTime.now();
    String formattedDate = DateFormat("dd-MM-yyyy hh:mm:ss").format(now);
    Map<String, dynamic> row = {
      DatabaseHelper.line_id: line_id,
      DatabaseHelper.product_qty: count,
      DatabaseHelper.create_dateline: formattedDate,
    };
    await updatedata.update_countdata(row);
  }

  upload_toserver() async {
    prefs = await SharedPreferences.getInstance();
    url =  ModelURL_TEST.setData("${prefs.getString("url")}", "${prefs.getString("userlogin")}", "${prefs.getString("password")}", "${prefs.getString("database")}");
    final datarows = await querydata.query_orderline();
    var client = OdooClient("${url.setURL}");
    await client.connect().then((version) {
      client
          .authenticate("${url.username}", "${url.password}", "${url.database}")
          .then((AuthenticateCallback auth) {
        if (auth.isSuccess) {
          datarows.forEach((item) async {
            final ids = [int.parse("${item['line_id']}")];
            final valuesToUpdate = {
              "product_qty": "${item['product_qty']}"
            };
            await client.write("stock.inventory.line", ids, valuesToUpdate).then((result) {
              if(!result.hasError() && result.getResult()) {
                print("Updated");
              } else {
                print (result.getError());
              }
            });
          });
        } else {
          // login fail
        }
      });
    });
    setState(() {
      dropdata();
    });
  }
  dropdata() async{
    await deletedata.deletestock();
    await deletedata.deletestockline();
    prefs = await SharedPreferences.getInstance();
    await prefs.remove('pefStock_id');
    await prefs.remove('pefStock_name');
    await prefs.remove('pefStock_date');
    await prefs.remove('pefStock_state');
    setState(() {
      _saving = false;
//      Navigator.push(context, MaterialPageRoute(builder: (context) => MyHomePage()));
    });
  }
}
