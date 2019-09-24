import 'package:sqflite/sqlite_api.dart';

import 'database_helper.dart';
class QueryData{
  final dbHelper = DatabaseHelper.instance ;
  Future<List<Map<String, dynamic>>> listtest()async{
    Database db = await dbHelper.database ;
    return db.rawQuery('select * from test');
  }
  Future<List<Map<String, dynamic>>> querycheck_stocklocation(String id) async{
    Database db = await dbHelper.database ;
    return await db.query("stock_location",where: 'stock_location_id = ?',whereArgs: [id]);
  }
  Future<List<Map<String, dynamic>>> queryAllRows(String data_id) async {
    Database db = await dbHelper.database;
    return await db.query('stock_inventory',where: 'columnId = ?', whereArgs: [data_id]);
  }

  Future<List<Map<String, dynamic>>> query_orderline() async {
    Database db = await dbHelper.database;
    return await db.rawQuery(
        'select * from inventory_line order by create_dateline DESC');
  }

  Future<List<Map<String, dynamic>>> query_product_id(String product_id) async {
    Database db = await dbHelper.database;
    return await db.query("inventory_line",
        where: '$product_id = ?', whereArgs: [product_id]);
  }
  Future<List<Map<String, dynamic>>> qcheckordreline(
      String data_line_id) async {
    Database db = await dbHelper.database;
    return await db.query("inventory_line",
        where: 'line_id = ?', whereArgs: [data_line_id]);
  }

  Future<List<Map<String, dynamic>>> qcheck_product_barcode(
      String data_barcode) async {
    Database db = await dbHelper.database;
    return await db.query('inventory_line',
        where: 'barcode = ?', whereArgs: [data_barcode]);
  }

  Future<List<Map<String, dynamic>>> qcheck_product_referend(
      String referend) async {
    Database db = await dbHelper.database;
    return await db.query("inventory_line",
        where: 'product_code LIKE ?', whereArgs: [referend]);
  }

  Future<List<Map<String, dynamic>>> query_stock_locationdata()async{
    Database db = await dbHelper.database;
    return await db.rawQuery('select * from stock_location');
  }
  Future<List<Map<String, dynamic>>> query_stock_locationto()async{
    Database db = await dbHelper.database ;
    return await db.rawQuery('select *,a.stock_location_name as front_txt,b.stock_location_name as back_txt from stock_location as a JOIN stock_location as b ON(a.stock_location_id = b.stock_location_fk_id) group by a.stock_location_name');
  }
  Future<List<Map<String, dynamic>>> checkdata_stockmove(String stock_move_id) async{
    Database db = await  dbHelper.database ;
    return await db.rawQuery('select * from stock_move where stock_move_id = ${stock_move_id}');
  }
  Future<List<Map<String, dynamic>>> check_datastockmove(String move_id)async{
    Database db = await dbHelper.database ;
    return await db.rawQuery('select * from stock_move_line where stock_move_line_move_id = ${move_id}');
  }
  Future<List<Map<String, dynamic>>> check_stockmoveline_doneqty(String move_id) async{
    Database db = await dbHelper.database ;
    return await db.rawQuery('select *,SUM(stock_move_line_qty_done) as qty_done from stock_move_line where stock_move_line_move_id = ${move_id} group by stock_move_line_move_id');
  }
  Future<List<Map<String, dynamic>>> check_ordersendserver_receipts(String picking_id) async
  {
    Database db = await dbHelper.database;
    return await db.rawQuery('select * from stock_move as a JOIN stock_move_line as b ON (a.stock_move_id = b.stock_move_line_move_id) where a.stock_move_picking_id = ${picking_id}');
  }
  Future<List<Map<String, dynamic>>> getdatanameFrom_stock_location()async{
    Database db = await dbHelper.database ;
    return await db.rawQuery('select * from stock_location');
  }
  Future<List<Map<String, dynamic>>> getdatacompletename_stock_location()async{
    Database db = await dbHelper.database ;
    return await db.rawQuery('select a.stock_location_name as completenameone,b.stock_location_name as completenamesecound  from stock_location as a JOIN stock_location as b ON (a.stock_location_id = b.stock_location_fk_id)');
  }
  Future<List<Map<String, dynamic>>>get_location_makeordernew_check(String move_id)async{
    Database db = await dbHelper.database ;
    return await db.rawQuery('select * from stock_move_line where stock_move_line_move_id = ${move_id}');
  }
  Future<List<Map<String, dynamic>>> q_datastockmovelineinsert(String move_id)async{
    Database db = await dbHelper.database ;
    return await db.rawQuery('select * from stock_move_line where stock_move_line_move_id = ${move_id} and where stock_move_line_order_qty != 0 ');
  }
  Future<List<Map<String, dynamic>>>q_checkidstocklocation(String namelocation)async{
    Database db = await dbHelper.database ;
    return await db.rawQuery('select * from stock_location where stock_location_name = ${namelocation}');
  }
}