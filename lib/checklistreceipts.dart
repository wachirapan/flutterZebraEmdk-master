import 'package:flutter/material.dart';
import 'package:modal_progress_hud/modal_progress_hud.dart';
import 'package:odoo_api/odoo_api.dart';
import 'package:odoo_api/odoo_api_connector.dart';
import 'package:odoo_api/odoo_user_response.dart';
import 'package:odoo_api/odoo_version.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dataModel/model_url.dart';
import 'database/querydata.dart';
import 'database/database_helper.dart';
import 'dataModel/datastock_move.dart';
import 'database/insertdata.dart';
import 'dashboard/receipt/listdata_add.dart';
import 'mainmenu.dart';
import 'database/deletedata.dart';
void main()=> runApp(CheckListReceipts());
class CheckListReceipts extends StatelessWidget{
  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return MaterialApp(
      title: "",
      home: StateFull_CheckListReceipts(),
    );
  }
}
class StateFull_CheckListReceipts extends StatefulWidget{
  @override
  State_CheckListReceipts createState()=> State_CheckListReceipts();
}
class State_CheckListReceipts extends State<StateFull_CheckListReceipts>{
  SharedPreferences prefs ;
  ModelURL_TEST url ;
  final querydata = QueryData();
  List<DataStock_Move> mlist = [];
  bool _saving = false ;
  final insertdata = InsertData();
  final delete = DeleteData();
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getstock_moveodoo();
    _saving = true ;
  }
  getstock_moveodoo()async{
    prefs = await SharedPreferences.getInstance();
    url = ModelURL_TEST.setData("${prefs.getString("url")}", "${prefs.getString("userlogin")}", "${prefs.getString("password")}", "${prefs.getString("database")}");

    var client = new OdooClient("${url.setURL}");

      await client.authenticate("${url.username}", "${url.password}", "${url.database}").then((AuthenticateCallback auth) async {
        if(auth.isSuccess) {
          final domain = [["picking_id", "=", int.parse("${prefs.getString("picking_id")}")]];
          final fields = ["id", "name", "picking_id","ordered_qty","product_qty","product_uom_qty"];
          await client.searchRead("stock.move", domain, fields, limit: 10, offset: 0, order: "create_date").then((OdooResponse result) async {
            if (!result.hasError()) {
              final data = result.getResult();
              for(var item in data['records']){
                check_querymodeldb('${item['id']}','${item['name']}','${item['picking_id'][0]}','${item['ordered_qty']}','${item['product_qty']}','${item['product_uom_qty']}');
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
  check_querymodeldb(String id, String name, String picking_id, String ordered_qty, String product_qty, String product_uom_qty) async
  {

    final rowsAll = await querydata.checkdata_stockmove('${id}');
    if(rowsAll.length == 0){

      insertdata_stockmove('${id}','${name}','${picking_id}','${ordered_qty}','${product_qty}','${product_uom_qty}');
    }else{
      rowsAll.forEach((item) async {
        final rowsmoveline = await querydata.check_stockmoveline_doneqty('${item['stock_move_id']}');
        if(rowsmoveline.length > 0){
          rowsmoveline.forEach((datamoveline){
            mlist.add(DataStock_Move('${item['stock_move_id']}','${item['stock_move_name']}','${item['stock_move_picking_id']}','${item['stock_move_ordered_qty']}','${item['stock_move_product_qty']}','${item['stock_move_product_uom_qty']}','${datamoveline['qty_done']}'));
          });
          setState(() {
            mlist.forEach((data){

            });
            _saving = false ;
          });
        }else{
          mlist.add(DataStock_Move('${item['stock_move_id']}','${item['stock_move_name']}','${item['stock_move_picking_id']}','${item['stock_move_ordered_qty']}','${item['stock_move_product_qty']}','${item['stock_move_product_uom_qty']}','0'));
          setState(() {
            mlist.forEach((data){

            });
            _saving = false ;
          });
        }

      });

    }

  }
  insertdata_stockmove(String id, String name, String picking_id, String ordered_qty, String product_qty, String product_uom_qty)async{
    Map<String, dynamic> rows = {
      DatabaseHelper.stock_move_id : int.parse('${id}'),
      DatabaseHelper.stock_move_name : '${name}',
      DatabaseHelper.stock_move_picking_id : int.parse('${picking_id}'),
      DatabaseHelper.stock_move_ordered_qty : int.parse('${double.parse("${ordered_qty}").toStringAsFixed(0)}'),
      DatabaseHelper.stock_move_product_qty : int.parse('${double.parse("${product_qty}").toStringAsFixed(0)}'),
      DatabaseHelper.stock_move_product_uom_qty : int.parse('${double.parse("${product_uom_qty}").toStringAsFixed(0)}'),
    };
    await insertdata.insert_stockmove(rows);
    check_querymodeldb('${id}','${name}','${picking_id}','${ordered_qty}','${product_qty}','${product_uom_qty}');
  }
  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Scaffold(
      appBar: AppBar(
        actions: <Widget>[
          IconButton(
            onPressed: (){
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  // return object of type Dialog
                  return AlertDialog(
                    title: new Text("ยืนยันการจัดเก็บ?"),
                    content: new Text("คุณต้องการจัดเก็บข้อมูลใหม่หรือไม่ !"),
                    actions: <Widget>[
                      new FlatButton(
                        child: Text("ยืนยัน"),
                        onPressed: (){
                          sendreceipts_toserver();
                            _saving = true;
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
            icon: Icon(Icons.cloud),
          )
        ],
      ),
      body: ModalProgressHUD(child: ListStockMove(),inAsyncCall: _saving,)
    );
  }
  sendreceipts_toserver() async
  {
    prefs = await SharedPreferences.getInstance();
    url =  ModelURL_TEST.setData("${prefs.getString("url")}", "${prefs.getString("userlogin")}", "${prefs.getString("password")}", "${prefs.getString("database")}");
    final receiptsdata = await querydata.check_ordersendserver_receipts('${prefs.getString("picking_id")}');
    if(receiptsdata.length > 0){
      var client = new OdooClient(url.setURL);

        await client.authenticate("${url.username}", "${url.password}", "${url.database}").then((AuthenticateCallback auth) async {
          if(auth.isSuccess) {
            receiptsdata.forEach((item) async {
              final ids = [int.parse('${item['stock_move_line_id']}')];
              final valuesToUpdate = {
                "qty_done": "${item['stock_move_line_qty_done']}",
                "lot_name" : "${item['stock_move_line_lot_name']}"
              };
              await client.write("stock.move.line", ids, valuesToUpdate).then((result) {
                if(!result.hasError() && result.getResult()) {
                  print("Updated");
                } else {
                  print (result.getError());
                }
              });
              await delete.deletedata_stockmove(int.parse('${item['stock_move_line_id']}'));
              await delete.deletedata_stockmoveline(int.parse('${item['stock_move_line_id']}'));
            });
            setState(() {
              _saving = false ;
              Navigator.push(context, MaterialPageRoute(builder: (context)=> MyHomePage()));
            });
          } else {
            // login fail
          }
        });

    }
  }
  ListStockMove(){
    return ListView.builder(
        itemCount: mlist.length,
        itemBuilder: (_, index){
          return Card(
            child: ListTile(
              title: Text("${mlist[index].stock_move_name}"),
              subtitle: Text("Initial Demand : ${mlist[index].stock_move_ordered_qty}"),
              trailing: Text("${mlist[index].stock_move_done_qty}"),
              onTap: (){
                Navigator.push(context, MaterialPageRoute(builder: (context)=> StateFull_ListData_Add()));
                prefs.setString("move_id", '${mlist[index].stock_move_id}');
                prefs.setString("stock_move_name", '${mlist[index].stock_move_name}');
                prefs.setString("stock_move_ordered_qty", '${mlist[index].stock_move_ordered_qty}');
              },
            ),
          );
    });
  }
}