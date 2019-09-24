import 'package:sqflite/sqlite_api.dart';

import 'database_helper.dart';
class DeleteData{
  final dbHelper = DatabaseHelper.instance ;

  Future<int> deletestock() async {
    Database db = await dbHelper.database;
    return await db.rawDelete("DELETE FROM inventory_line");
  }

  Future<int> deletestockline() async {
    Database db = await dbHelper.database;
    return await db.rawDelete("DELETE FROM stock_inventory");
  }
  Future<int> deletedata_stockmove(int id) async
  {
    Database db = await dbHelper.database ;
    return await db.delete('stock_move',where: 'stock_move_id = ?', whereArgs: [id]);
  }
  Future<int> deletedata_stockmoveline(int id)async{
    Database db = await dbHelper.database ;
    return await db.delete('stock_move_line',where: 'stock_move_line_move_id = ?', whereArgs: [id]);
  }
}