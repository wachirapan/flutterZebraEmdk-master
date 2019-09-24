import 'package:flutter/material.dart';
import 'package:modal_progress_hud/modal_progress_hud.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../database/querydata.dart';
import '../../database/database_helper.dart';
void main() => runApp(Add_Receipts());

class Add_Receipts extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return MaterialApp(
      title: '',
      home: StateFull_Add_Receipts(),
    );
  }
}

class StateFull_Add_Receipts extends StatefulWidget {
  @override
  State_Add_Receipts createState() => State_Add_Receipts();
}

class State_Add_Receipts extends State<StateFull_Add_Receipts> {
  SharedPreferences pref;

  String stock_move_line_location_name,
      stock_move_line_location_complete_name,
      stock_move_name,
      move_id;
  String dropdownValuename, dropdownValuecomplete;
  List<String> itemname = [];
  List<String> itemcomplete = [];
  TextEditingController txt_total = TextEditingController();
  final query = QueryData();
  bool _saving = false;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    setdataSharedPreferences();
    _saving = true;
  }

  setdataSharedPreferences() async {
    pref = await SharedPreferences.getInstance();
    move_id = pref.getString("move_id");
    stock_move_line_location_name =
        pref.getString('stock_move_line_location_name');
    stock_move_line_location_complete_name =
        pref.getString('stock_move_line_location_complete_name');
    stock_move_name = pref.getString("stock_move_name");
    final rowcheck = await query.get_location_makeordernew_check(move_id);
    rowcheck.forEach((item) {
      dropdownValuename = "${item['stock_move_line_location_name']}";
      dropdownValuecomplete =
          "${item['stock_move_line_location_complete_name']}";
      itemname.add('${item['stock_move_line_location_name']}');
      itemcomplete.add("${item['stock_move_line_location_complete_name']}");
    });

    final q_name = await query.getdatanameFrom_stock_location();
    q_name.forEach((data1) {
      itemname.add('${data1['stock_location_name']}');
    });
    final completename = await query.getdatacompletename_stock_location();
    completename.forEach((data2) {
      itemcomplete.add("${data2['completenameone']} / ${data2['completenamesecound']}");
    });
    setState(() {
      _saving = false;
    });
    print("*****${dropdownValuecomplete}*******${dropdownValuecomplete.split("/")[0]}++++++++++++++");
  }
  insertdata_db()async{
    final rowall = await query.q_datastockmovelineinsert(move_id);
    rowall.forEach((item) async {
      final checkname_id = await query.q_checkidstocklocation(dropdownValuename);
      checkname_id.forEach((data1)async{
        final checkcomplete = await query.q_checkidstocklocation(dropdownValuecomplete);
        checkcomplete.forEach((data2){
          //      Map<String, dynamic> rows = {
//        DatabaseHelper.stock_move_line_id: int.parse('${item['stock_move_line_id']}'),
//        DatabaseHelper.stock_move_line_move_id: int.parse('${item['stock_move_line_move_id']}'),
//        DatabaseHelper.stock_move_line_product_id: int.parse('${item['stock_move_line_product_id']}'),
//        DatabaseHelper.stock_move_line_product_uom_id: int.parse('${item['stock_move_line_product_uom_id']}'),
//        DatabaseHelper.stock_move_line_qty_done: int.parse(txt_total.text),
//        DatabaseHelper.stock_move_line_location_id: int.parse('${location_id}'),
//        DatabaseHelper.stock_move_line_location_dest_id: int.parse('${location_dest_id}'),
//        DatabaseHelper.stock_move_line_state: '${state}',
//        DatabaseHelper.stock_move_line_reference: '${reference}',
//        DatabaseHelper.stock_move_line_create_uid: int.parse('${create_uid}'),
//        DatabaseHelper.stock_move_line_write_uid: int.parse('${write_uid}'),
//        DatabaseHelper.stock_move_line_location_name: '${location_name}',
//        DatabaseHelper.stock_move_line_location_complete_name: '${location_complete_name}',
//        DatabaseHelper.stock_move_line_order_qty : int.parse('${pref.getString('stock_move_ordered_qty')}')
//      };
        });
      });

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

              },
              icon: Icon(Icons.add),
            )
          ],
        ),
        body: ModalProgressHUD(
          child: listdatanewOrder(),
          inAsyncCall: _saving,
        ));
  }

  listdatanewOrder() {
    return Container(
      margin: EdgeInsets.only(top: 10.0,left: 10.0, right: 10.0),
      child: ListView(
        children: <Widget>[
          Text("${stock_move_name}"),
          Container(
            margin: EdgeInsets.only(top: 10.0),
            child:  DropdownButton<String>(
              value: dropdownValuename,
//            icon: Icon(Icons.arrow_downward),
//            iconSize: 24,
//            elevation: 16,
              style: TextStyle(color: Colors.black),
              underline: Container(
                height: 1,
                color: Colors.grey,
              ),
              onChanged: (String newValue) {
                setState(() {
                  dropdownValuename = newValue;
                });
              },
              items: itemname.map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),

          ),
         Container(
             margin: EdgeInsets.only(top: 10.0),
           child:  DropdownButton<String>(
             isExpanded: true,
             value: dropdownValuecomplete,
//            icon: Icon(Icons.arrow_downward),
//            iconSize: 24,
//            elevation: 16,
             style: TextStyle(
                 color: Colors.black
             ),
             underline: Container(
               height: 1,
               color: Colors.grey,
             ),
             onChanged: (String newValue) {
               setState(() {
                 dropdownValuecomplete = newValue;
               });
             },
             items: itemcomplete
                 .map<DropdownMenuItem<String>>((String value) {
               return DropdownMenuItem<String>(
                 value: value,
                 child: Text(value,overflow: TextOverflow.ellipsis,),
               );
             })
                 .toList(),
           ),
         ),
          TextField(
            controller: txt_total,
            decoration: InputDecoration(
              labelText: "จำนวนโอนย้าย",
              hintText: "จำนวนโอนย้าย"
            ),
          )
        ],
      ),
    );
  }
}
