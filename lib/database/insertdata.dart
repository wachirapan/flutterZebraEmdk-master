
import 'package:sqflite/sqlite_api.dart';
import 'database_helper.dart';

class InsertData {
  final dbHelper  = DatabaseHelper.instance ;
  Future<int> insert(Map<String, dynamic> row) async {
    Database db = await dbHelper.database;
    return await db.insert('stock_inventory', row);
  }

  Future<int> insert_proudctdetail(Map<String, dynamic> row) async {
    Database db = await dbHelper.database;
    return await db.insert("inventory_line", row);
  }

    Future<int> insert_stock_location(Map<String, dynamic> row) async{
        Database db = await dbHelper.database ;
        return await db.insert("stock_location", row);
  }
  Future<int> insert_stockmove(Map<String, dynamic> rows) async{
      Database db = await dbHelper.database ;
      return await db.insert('stock_move',rows);
  }
  Future<int> insert_stockmoveline(Map<String, dynamic> rows) async
  {
    Database db = await dbHelper.database ;
    return await db.insert('stock_move_line', rows);
  }

}