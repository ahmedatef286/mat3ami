import 'package:mat3ami/business_logic/models/table_in_restaurant.dart';
import 'package:mat3ami/business_logic/services/backend_services.dart';
import 'package:mysql1/mysql1.dart';

class TableServices {
  // add new Table
  static Future<void> addNewTableToDatabase() async {
    const query = "insert into dinningTable values(null, 'available');";
    await DatabaseServices.queryDatabase(query);
  }

  static Future<void> changeTableState(int num, bool occupied) async {
    String query =
        "UPDATE dinningTable SET tableStatus = '${(occupied) ? 'occupied' : 'available'}'where tableNumber= $num;";

    await DatabaseServices.queryDatabase(query);
  }

  //fetch Table by number
  static Future<TableInRestaurant> fetchTableFromDatabase(int num) async {
    final query = "select * from dinningTable where tableNumber = '$num';";
    final result = await DatabaseServices.queryDatabase(query);
    return TableInRestaurant.fromDatabase(result.first);
  }

  // delete table
  static Future<void> deleteTableFromDatabase(int num) async {
    final query =
        "DELETE FROM `dinningTable` WHERE `dinningTable`.`tableNumber` = $num;";
    await DatabaseServices.queryDatabase(query);
  }

  //fetch all Tables
  static Future<List<TableInRestaurant>> fetchAllTablesFromDatabase() async {
    const query = "select * from dinningTable;";
    final result = await DatabaseServices.queryDatabase(query);
    List<TableInRestaurant> tableList = [];
    for (ResultRow tbl in result) {
      tableList.add(TableInRestaurant.fromDatabase(tbl));
    }

    return tableList;
  }
}
