
import 'dart:io';

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';

class DatabaseHelper {
  static final _databaseName = "odoo.db";
  static final _databaseVersion = 1;

  static final table = 'stock_inventory';

  static final columnId = '_id_inventory';
  static final columnName = '_name_inventory';
  static final columnDate = '_date_inventory';
  static final columState = '_state_incentory';


  //Stock_line
  static final line_id = 'line_id';
  static final product_id = 'product_id';
  static final barcode = 'barcode';
  static final name_product = 'name_product';
  static final product_code = 'product_code';
  static final theoretical_qty = 'theoretical_qty';
  static final product_qty = 'product_qty';
  static final create_dateline = 'create_dateline';

  //stock.location
  static final stock_location_id = "stock_location_id";
  static final stock_location_parent_left = "stock_location_parent_left";
  static final stock_location_parent_right = "stock_location_parent_right";
  static final stock_location_name = "stock_location_name";
  static final stock_location_complete_name = "stock_location_complete_name";
  static final stock_location_fk_id = "stock_location_fk_id";

  //stock.move
  static final stock_move_id = "stock_move_id" ;
  static final stock_move_name = "stock_move_name" ;
  static final stock_move_picking_id = "stock_move_picking_id" ;
  static final stock_move_ordered_qty = "stock_move_ordered_qty";
  static final stock_move_product_qty = "stock_move_product_qty";
  static final stock_move_product_uom_qty = "stock_move_product_uom_qty";

  //stock.move.line
  static final stock_move_line_db_id = "stock_move_line_db_id";
  static final stock_move_line_id = "stock_move_line_id";
  static final stock_move_line_move_id = "stock_move_line_move_id";
  static final stock_move_line_product_id = "stock_move_line_product_id";
  static final stock_move_line_product_uom_id = "stock_move_line_product_uom_id";
  static final stock_move_line_qty_done = "stock_move_line_qty_done";
  static final stock_move_line_location_id = "stock_move_line_locaion_id";
  static final stock_move_line_location_dest_id = "stock_move_line_location_dest_id";
  static final stock_move_line_state = "stock_move_line_state";
  static final stock_move_line_reference = "stock_move_line_reference";
  static final stock_move_line_create_uid = "stock_move_line_create_uid";
  static final stock_move_line_write_uid = "stock_move_line_write_uid";
  static final stock_move_line_location_name = "stock_move_line_location_name";
  static final stock_move_line_location_complete_name = "stock_move_line_location_complete_name";
  static final stock_move_line_lot_name = "stock_move_line_lot_name";
  static final stock_move_line_order_qty = "stock_move_line_order_qty";

  // make this a singleton class
  DatabaseHelper._privateConstructor();

  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  // only have a single app-wide reference to the database
  static Database _database;

  Future<Database> get database async {
    if (_database != null) return _database;
    // lazily instantiate the db the first time it is accessed
    _database = await _initDatabase();
    return _database;
  }

  // this opens the database (and creates it if it doesn't exist)
  _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, _databaseName);
    return await openDatabase(path,
        version: _databaseVersion, onCreate: _onCreate);
  }

  // SQL code to create the database table
  Future _onCreate(Database db, int version) async {

    await db.execute('''
          CREATE TABLE $table (
            $columnId INTEGER NOT NULL,
            $columnName TEXT NOT NULL,
            $columnDate Text NOT NULL,
            $columState Text NOT NULL
          )
          ''');


    await db.execute('''
    CREATE TABLE inventory_line (
      $line_id INTEGER NOT NULL,
      $product_id INTEGER NOT NULL,
      $name_product TEXT NOT NULL,
      $barcode TEXT NOT NULL,
      $product_code TEXT NOT NULL,
      $theoretical_qty TEXT NOT NULL,
      $product_qty INTEGER NOT NULL,
      $create_dateline DATETIME NOT NULL
    )
     ''');

    await db.execute('''
    CREATE TABLE stock_location (
        $stock_location_id INTEGER NOT NULL,
        $stock_location_parent_left INTEGER NOT NULL,
        $stock_location_parent_right INTEGER NOT NULL,
        $stock_location_name TEXT NOT NULL,
        $stock_location_complete_name TEXT NOT NULL,
        $stock_location_fk_id TEXT NOT NULL
    )
     ''');

    await db.execute(''' 
    CREATE TABLE stock_move (
    $stock_move_id INTEGER NOT NULL,
    $stock_move_name TEXT NOT NULL,
    $stock_move_picking_id INTEGER NOT NULL,
    $stock_move_ordered_qty INTEGER NOT NULL,
    $stock_move_product_qty INTEGER NOT NULL,
    $stock_move_product_uom_qty INTEGER NOT NULL
    )
    ''');

    await db.execute(''' 
    CREATE TABLE stock_move_line(
    $stock_move_line_db_id INTEGER PRIMARY KEY,
    $stock_move_line_id INTEGER NOT NULL,
    $stock_move_line_move_id INTEGER NOT NULL,
    $stock_move_line_product_id INTEGER NOT NULL,
    $stock_move_line_product_uom_id INTEGER NOT NULL,
    $stock_move_line_qty_done INTEGER NOT NULL,
    $stock_move_line_location_id INTEGER NOT NULL,
    $stock_move_line_location_dest_id INTEGER NOT NULL,
    $stock_move_line_state TEXT NOT NULL,
    $stock_move_line_reference TEXT NOT NULL,
    $stock_move_line_create_uid INTEGER NOT NULL,
    $stock_move_line_write_uid INTEGER NOT NULL,
    $stock_move_line_location_name TEXT NOT NULL,
    $stock_move_line_location_complete_name TEXT NOT NULL,
    $stock_move_line_lot_name TEXT NOT NULL,
    $stock_move_line_order_qty INTEGER NOT NULL
    )
    ''');
  }

}
