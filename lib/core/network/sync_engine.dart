// // lib/core/network/sync_engine.dart
// import 'package:connectivity_plus/connectivity_plus.dart';
// import '../../core/database/db_helper.dart';

// class SyncEngine {
//   final DBHelper _dbHelper = DBHelper();

//   Future<void> checkAndSync() async {
//     // 1. Check Internet Connection
//     var connectivityResult = await (Connectivity().checkConnectivity());
    
//     if (connectivityResult != ConnectivityResult.none) {
//       print("Online: Starting Sync...");
      
//       // 2. Fetch Unsynced Data from SQLite
//       final db = await _dbHelper.db;
//       List<Map<String, dynamic>> unsyncedScans = await db.query(
//         'history', 
//         where: 'isSynced = ?', 
//         whereArgs: [0]
//       );

//       for (var scan in unsyncedScans) {
//         bool success = await _uploadToServer(scan);
        
//         if (success) {
//           // 3. Mark as Synced locally
//           await db.update(
//             'history', 
//             {'isSynced': 1}, 
//             where: 'id = ?', 
//             whereArgs: [scan['id']]
//           );
//         }
//       }
//     }
//   }

//   Future<bool> _uploadToServer(Map<String, dynamic> data) async {
//     // Placeholder for your REST API call (Laravel/Django)[cite: 1]
//     await Future.delayed(const Duration(seconds: 1));
//     return true; 
//   }
// }