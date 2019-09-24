import 'package:flutter/material.dart';
import 'package:odoo_api/odoo_api.dart';
import 'package:odoo_api/odoo_api_connector.dart';
import 'package:odoo_api/odoo_user_response.dart';
import 'package:odoo_api/odoo_version.dart';
import 'dataModel/stock_picking_type.dart';
import 'dataModel/stock_picking.dart';
import 'checklistreceipts.dart';
import 'dataModel/model_url.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main ()=> runApp(ShowListOrder());
class ShowListOrder extends StatelessWidget{
  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return MaterialApp(
      title: "",
      home: StateFull_ShowListOrder(),
    );
  }
}
class StateFull_ShowListOrder extends StatefulWidget{
  Stock_Picking_Type mlist ;
  StateFull_ShowListOrder({Key key, @required this.mlist}) :super(key :key);
  @override
  State_ShowListOrder createState()=> State_ShowListOrder();
}
class State_ShowListOrder extends State<StateFull_ShowListOrder>{
  List<Stock_Picking> lists = [] ;
  ModelURL_TEST url ;
  SharedPreferences prefs ;
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    setconnectserver();
  }
  setconnectserver()async{
    prefs = await SharedPreferences.getInstance();
    url =  ModelURL_TEST.setData("${prefs.getString("url")}", "${prefs.getString("userlogin")}", "${prefs.getString("password")}", "${prefs.getString("database")}");
    setState(() {
      connectData();
    });
  }
  connectData () async{
    prefs = await SharedPreferences.getInstance();
    var client = new OdooClient("${url.setURL}");
    await client.connect().then((OdooVersion version) async {
      await client.authenticate("${url.username}", "${url.password}", "${url.database}").then((AuthenticateCallback auth) async {
        if(auth.isSuccess) {
          final domain = [["picking_type_id", "=", int.parse("${widget.mlist.id}")]];
          final fields = ["id", "name", "state","picking_type_id","location_id","location_dest_id","origin"];
          await client.searchRead("stock.picking", domain, fields, limit: 10, offset: 0, order: "create_date").then((OdooResponse result) async {
            if (!result.hasError()) {
              final data = result.getResult();
              for(var item in data['records']){
                lists.add(Stock_Picking("${item['id']}","${item['name']}","${item['origin']}"));
              }
              setState(() {
                lists.forEach((data){

                });
              });
            } else {

              print (result.getError());
            }
          });
        } else {
          // login fail
        }
      });
    });
  }
  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Scaffold(
      appBar: AppBar(),
      body: lists.length == 0 ? Center(child: CircularProgressIndicator(),): showdataList(),
    );
  }
  showdataList(){
    return ListView.builder(
        itemCount: lists.length,
        itemBuilder: (_,index){
          return Card(
            child: ListTile(
              leading: Icon(Icons.airplay),
              title: Text("${lists[index].name}"),
              subtitle: Text("${lists[index].origin}"),
              onTap: () async {
                Navigator.push(context, MaterialPageRoute(builder: (context)=> StateFull_CheckListReceipts()));
                prefs.setString('picking_id', "${lists[index].id}");
              },
            ),
          );
      
    });
  }
}