import 'package:sqflite/sqlite_api.dart';

import'database_helper.dart';
class UpdateData {
  final dbHelper = DatabaseHelper.instance ;
  Future<int> update_stocklocation(Map<String, dynamic> row)async{
    Database db = await dbHelper.database ;
    int id = row['stock_location_id'];
    return await db.update("stock_location", row, where: 'stock_location_id = ?', whereArgs: [id]);
  }

  Future<int> update(Map<String, dynamic> row) async {
    Database db = await dbHelper.database;
    int id = row['columnId'];
    return await db.update('stock_inventory', row, where: 'columnId = ?', whereArgs: [id]);
  }

  Future<int> update_barcode(Map<String, dynamic> row) async {
    Database db = await dbHelper.database;
    int id = row['product_id'];
    return await db.update("inventory_line", row,
        where: 'product_id = ?', whereArgs: [id]);
  }

  Future<int> update_countdata(Map<String, dynamic> row) async {
    Database db = await dbHelper.database;
    int id = row['line_id'];
    return await db
        .update("inventory_line", row, where: 'line_id = ?', whereArgs: [id]);
  }
  Future<int> update_receipts_stockmoveline(Map<String, dynamic> row) async{
    Database db = await dbHelper.database ;
    int id = row['stock_move_line_db_id'];
    return await db.update('stock_move_line', row, where: 'stock_move_line_db_id = ?', whereArgs: [id]);
  }

}