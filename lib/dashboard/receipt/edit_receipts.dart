import 'package:flutter/material.dart';
import 'package:modal_progress_hud/modal_progress_hud.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../database/updatedata.dart';
import '../../database/database_helper.dart';
import '../../checklistreceipts.dart';
void main ()=> runApp(Edit_Receipts());
class Edit_Receipts extends StatelessWidget{
  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return MaterialApp(
      title: '',
      home: StateFull_Edit_Receipts(),
    );
  }
}
class StateFull_Edit_Receipts extends StatefulWidget{
  @override
  State_Edit_Receipts createState()=> State_Edit_Receipts();
}
class State_Edit_Receipts extends State<StateFull_Edit_Receipts>{
  SharedPreferences pref ;
  String stock_move_name, stock_move_line_location_name,  stock_move_line_location_complete_name, stock_move_ordered_qty;
  bool _saving = false;
  TextEditingController qty_done = TextEditingController();
  TextEditingController lot_name = TextEditingController();
  final updatedata = UpdateData();
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getDataset();

    _saving = true ;
  }
  getDataset()async{
    pref = await SharedPreferences.getInstance();
    stock_move_name = await pref.getString("stock_move_name");
    stock_move_line_location_name = await pref.getString("stock_move_line_location_name");
    stock_move_line_location_complete_name = await pref.getString("stock_move_line_location_complete_name");
    stock_move_ordered_qty = await pref.getString("stock_move_ordered_qty");
    qty_done.text = await pref.getString("stock_move_line_qty_done");
    setState(() {
      _saving = false ;
    });
  }
  updatestockmoveline()async{
    Map<String, dynamic> row = {
      DatabaseHelper.stock_move_line_db_id : int.parse('${pref.getString("stock_move_line_db_id")}'),
      DatabaseHelper.stock_move_line_qty_done : int.parse('${qty_done.text}'),
      DatabaseHelper.stock_move_line_lot_name : "${lot_name.text}"
    };
    final update = await updatedata.update_receipts_stockmoveline(row);
    setState(() {
      _saving = false ;
      Navigator.push(context, MaterialPageRoute(builder: (context)=> StateFull_CheckListReceipts()));
    });
  }
  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Scaffold(
      appBar: AppBar(
        actions: <Widget>[
          IconButton(
            onPressed: (){
              _saving = true ;
              updatestockmoveline();
            },
            icon: Icon(Icons.save),
          )
        ],
      ),
      body: ModalProgressHUD(child: ListDataModel(),inAsyncCall: _saving,)
    );
  }
  ListDataModel(){
    return Container(
      margin: EdgeInsets.only(top: 10.0,left: 10.0, right: 10.0),
      child: ListView(
        children: <Widget>[
          Text("Product : ${stock_move_name}"),
          Text("Initial : ${stock_move_line_location_name}"),
          Text("From : ${stock_move_line_location_complete_name}"),
          Text("To : ${stock_move_ordered_qty}"),
          TextField(
            controller: qty_done,
            decoration: InputDecoration(
                labelText: "จำนวนที่รับเข้า",
                hintText: "จำนวนที่รับเข้า"
            ),
          ),
          TextField(
            controller: lot_name,
            decoration: InputDecoration(
              labelText: "รหัสล็อต",
              hintText: "#000000000"
            ),
          )
        ],
      ),
    );

  }
}