import 'package:flutter/material.dart';
import 'package:modal_progress_hud/modal_progress_hud.dart';
import 'package:odoo_api/odoo_api.dart';
import 'package:odoo_api/odoo_api_connector.dart';
import 'package:odoo_api/odoo_user_response.dart';
import 'package:odoo_api/odoo_version.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../database/querydata.dart';
import '../../dataModel/model_url.dart';
import '../../database/database_helper.dart';
import '../../database/insertdata.dart';
import '../../dataModel/datastock_moveline.dart';
import 'add_receipts.dart';
import 'edit_receipts.dart';

void main() => runApp(ListData_Add());

class ListData_Add extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return MaterialApp(
      title: "",
      home: StateFull_ListData_Add(),
    );
  }
}

class StateFull_ListData_Add extends StatefulWidget {
  @override
  State_ListData_Add createState() => State_ListData_Add();
}

class State_ListData_Add extends State<StateFull_ListData_Add> {
  final querydata = QueryData();
  ModelURL_TEST url ;
  final insertdata = InsertData();
  List<DataStock_Moveline> mlist = [];
  bool _saving = false;
  SharedPreferences pref;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    checkstockline_db();
    _saving = true;
  }

  checkstockline_db() async {
    pref = await SharedPreferences.getInstance();
    url =  ModelURL_TEST.setData("${pref.getString("url")}", "${pref.getString("userlogin")}", "${pref.getString("password")}", "${pref.getString("database")}");
    final rowAll =
        await querydata.check_datastockmove('${pref.getString("move_id")}');
    if (rowAll.length == 0) {
      connect_odoo();
    } else {
      rowAll.forEach((item) {
        mlist.add(DataStock_Moveline(
          '${item['stock_move_line_db_id']}',
            '${item['stock_move_line_id']}',
            '${item['stock_move_line_move_id']}',
            '${item['stock_move_line_product_id']}',
            '${item['stock_move_line_product_uom_id']}',
            '${item['stock_move_line_qty_done']}',
            '${item['stock_move_line_location_id']}',
            '${item['stock_move_line_location_dest_id']}',
            '${item['stock_move_line_state']}',
            '${item['stock_move_line_reference']}',
            '${item['stock_move_line_create_uid']}',
            '${item['stock_move_line_write_uid']}',
            '${item['stock_move_line_location_name']}',
            '${item['stock_move_line_location_complete_name']}',
            '${item['stock_move_line_order_qty']}'));
      });
      setState(() {
        mlist.forEach((data) {});
        _saving = false;
      });
    }
  }

  connect_odoo() async {
    pref = await SharedPreferences.getInstance();
    url =  ModelURL_TEST.setData("${pref.getString("url")}", "${pref.getString("userlogin")}", "${pref.getString("password")}", "${pref.getString("database")}");
    print('${pref.getString("move_id")}');
    var client = new OdooClient("${url.setURL}");

      await client
          .authenticate("${url.username}", "${url.password}", "${url.database}")
          .then((AuthenticateCallback auth) async {
        if (auth.isSuccess) {
          final domain = [
            ["move_id", "=", int.parse("${pref.getString('move_id')}")]
          ];
          final fields = [
            "id",
            "move_id",
            "product_id",
            "product_uom_id",
            "qty_done",
            "location_id",
            "location_dest_id",
            "state",
            "reference",
            "create_uid",
            "write_uid"
          ];
          await client
              .searchRead("stock.move.line", domain, fields,
                  limit: 9999, offset: 0, order: "create_date")
              .then((OdooResponse result) async {
            if (!result.hasError()) {
              final data = result.getResult();
              for (var item in data['records']) {
                print('***********${item}');
                insert_stockmoveline(
                    '${item['id']}',
                    '${item['move_id'][0]}',
                    '${item['product_id'][0]}',
                    '${item['product_uom_id'][0]}',
                    '${item['qty_done']}',
                    '${item['location_id'][0]}',
                    '${item['location_dest_id'][0]}',
                    '${item['state']}',
                    '${item['reference']}',
                    '${item['create_uid'][0]}',
                    '${item['write_uid'][0]}',
                    '${item['location_id'][1]}',
                    '${item['location_dest_id'][1]}');
              }
            } else {
              print(result.getError());
            }
          });
        } else {
          // login fail
        }
      });

  }

  insert_stockmoveline(
      String id,
      String move_id,
      String product_id,
      String product_uom_id,
      String qty_done,
      String location_id,
      String location_dest_id,
      String state,
      String reference,
      String create_uid,
      String write_uid,
      String location_name,
      String location_complete_name) async {
    Map<String, dynamic> rows = {
      DatabaseHelper.stock_move_line_id: int.parse('${id}'),
      DatabaseHelper.stock_move_line_move_id: int.parse('${move_id}'),
      DatabaseHelper.stock_move_line_product_id: int.parse('${product_id}'),
      DatabaseHelper.stock_move_line_product_uom_id: int.parse('${product_uom_id}'),
      DatabaseHelper.stock_move_line_qty_done: int.parse(double.parse('${qty_done}').toStringAsFixed(0)),
      DatabaseHelper.stock_move_line_location_id: int.parse('${location_id}'),
      DatabaseHelper.stock_move_line_location_dest_id: int.parse('${location_dest_id}'),
      DatabaseHelper.stock_move_line_state: '${state}',
      DatabaseHelper.stock_move_line_reference: '${reference}',
      DatabaseHelper.stock_move_line_create_uid: int.parse('${create_uid}'),
      DatabaseHelper.stock_move_line_write_uid: int.parse('${write_uid}'),
      DatabaseHelper.stock_move_line_location_name: '${location_name}',
      DatabaseHelper.stock_move_line_location_complete_name: '${location_complete_name}',
      DatabaseHelper.stock_move_line_lot_name : "",
      DatabaseHelper.stock_move_line_order_qty : int.parse('${pref.getString('stock_move_ordered_qty')}')
    };
    await insertdata.insert_stockmoveline(rows);
    checkstockline_db();
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Scaffold(
      appBar: AppBar(
        actions: <Widget>[
          IconButton(
            onPressed: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => StateFull_Add_Receipts()));
            },
            icon: Icon(Icons.add),
          )
        ],
      ),
      body: ModalProgressHUD(
        child: liststockmoveline(),
        inAsyncCall: _saving,
      ),
    );
  }

  liststockmoveline() {
    return ListView.builder(
        itemCount: mlist.length,
        itemBuilder: (_, index) {
          return Card(
            child: ListTile(
              title: Text("${pref.getString("stock_move_name")}"),
              subtitle: Text('Done : ${mlist[index].stock_move_line_qty_done}'),
              trailing: Icon(Icons.edit),
              onTap: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => StateFull_Edit_Receipts()));
                pref.setString("stock_move_line_db_id",'${mlist[index].stock_move_line_db_id}');
                pref.setString("stock_move_line_id", '${mlist[index].stock_move_line_id}');
                pref.setString("stock_move_name", '${pref.getString("stock_move_name")}');
                pref.setString("stock_move_line_qty_done", '${mlist[index].stock_move_line_qty_done}');
                pref.setString("stock_move_line_location_name", '${mlist[index].stock_move_line_location_name}');
                pref.setString("stock_move_line_location_complete_name", '${mlist[index].stock_move_line_location_complete_name}');
                pref.setString("stock_move_line_location_id", '${mlist[index].stock_move_line_location_id}');
                pref.setString("stock_move_line_location_dest_id", '${mlist[index].stock_move_line_location_dest_id}');

              },
            ),
          );
        });
  }
}
