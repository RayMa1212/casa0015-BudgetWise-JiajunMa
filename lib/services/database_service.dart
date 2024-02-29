import 'package:mysql_client/mysql_client.dart';

class DatabaseService {
  Future<void> initializeDb() async {
    try {
      final conn = await MySQLConnection.createConnection(
        host: 'localhost',
        port: 3306,
        userName: 'root',
        password: 'Mjj1212?',
        databaseName: 'BudgetWise',
      );

      await conn.connect();
      final result = await conn.execute('SELECT * FROM users');

      for (final row in result.rows) {
        print(row.assoc());
      }

      await conn.close();
    } catch (e) {
      print('Error: $e');
    }
  }
}
