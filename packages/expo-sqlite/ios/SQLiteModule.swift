import ExpoModulesCore

public final class SQLiteModule: Module {
  private var cachedDatabases = [String: OpaquePointer]()

  public func definition() -> ModuleDefinition {
    Name("ExpoSQLite")

    AsyncFunction("exec") { (databaseName: String, queries: [[Any]], readOnly: Bool) -> [Any?] in
      guard let db = openDatabase(databaseName: databaseName) else {
        throw DatabaseException()
      }

      let results = try queries.map { query in
        guard let sql = query[0] as? String else {
          throw InvalidSqlException()
        }

        guard let args = query[1] as? [Any] else {
          throw InvalidArgumentsException()
        }

        return executeSql(sql: sql, with: args, for: db, readOnly: readOnly)
      }

      return results
    }

    AsyncFunction("close") { (databaseName: String) in
      cachedDatabases.removeValue(forKey: databaseName)
    }

    Function("closeSync") { (databaseName: String) in
      cachedDatabases.removeValue(forKey: databaseName)
    }

    AsyncFunction("deleteAsync") { (databaseName: String) in
      if cachedDatabases[databaseName] != nil {
        throw DeleteDatabaseException(databaseName)
      }

      guard let path = self.pathForDatabaseName(name: databaseName) else {
        throw Exceptions.FileSystemModuleNotFound()
      }

      if !FileManager.default.fileExists(atPath: path.absoluteString) {
        throw DatabaseNotFoundException(databaseName)
      }

      do {
        try FileManager.default.removeItem(atPath: path.absoluteString)
      } catch {
        throw DeleteDatabaseFileException(databaseName)
      }
    }

    OnDestroy {
      cachedDatabases.values.forEach {
        exsqlite3_close($0)
      }
    }
  }

  private func pathForDatabaseName(name: String) -> URL? {
    guard let path = appContext?.config.documentDirectory?.path else {
      return nil
    }
    let directory = URL(string: path)?.appendingPathComponent("SQLite")
    FileSystemUtilities.ensureDirExists(at: directory)

    return directory?.appendingPathComponent(name)
  }

  private func openDatabase(databaseName: String) -> OpaquePointer? {
    var db: OpaquePointer?
    guard let path = pathForDatabaseName(name: databaseName) else {
      return nil
    }

    let fileExists = FileManager.default.fileExists(atPath: path.absoluteString)

    if fileExists {
      db = cachedDatabases[databaseName]
    }

    if let db {
      return db
    }

    cachedDatabases.removeValue(forKey: databaseName)

    if exsqlite3_open(path.absoluteString, &db) != SQLITE_OK {
      return nil
    }

    cachedDatabases[databaseName] = db
    return db
  }

  private func executeSql(sql: String, with args: [Any], for db: OpaquePointer, readOnly: Bool) -> [Any?] {
    var resultRows = [Any]()
    var statement: OpaquePointer?
    var rowsAffected: Int32 = 0
    var insertId: Int64 = 0
    var error: String?

    if exsqlite3_prepare_v2(db, sql, -1, &statement, nil) != SQLITE_OK {
      return [convertSqlLiteErrorToString(db: db)]
    }

    let queryIsReadOnly = exsqlite3_stmt_readonly(statement) > 0

    if readOnly && !queryIsReadOnly {
      return ["could not prepare \(sql)"]
    }

    for (index, arg) in args.enumerated() {
      guard let obj = arg as? NSObject else { continue }
      bindStatement(statement: statement, with: obj, at: Int32(index + 1))
    }

    var columnCount: Int32 = 0
    var columnNames = [String]()
    var columnType: Int32
    var fetchedColumns = false
    var value: Any?
    var hasMore = true

    while hasMore {
      let result = exsqlite3_step(statement)

      switch result {
      case SQLITE_ROW:
        if !fetchedColumns {
          columnCount = exsqlite3_column_count(statement)

          for i in 0..<Int(columnCount) {
            let columnName = NSString(format: "%s", exsqlite3_column_name(statement, Int32(i))) as String
            columnNames.append(columnName)
          }
          fetchedColumns = true
        }

        var entry = [Any]()

        for i in 0..<Int(columnCount) {
          columnType = exsqlite3_column_type(statement, Int32(i))
          value = getSqlValue(for: columnType, with: statement, index: Int32(i))
          entry.append(value)
        }

        resultRows.append(entry)
      case SQLITE_DONE:
        hasMore = false
      default:
        error = convertSqlLiteErrorToString(db: db)
        hasMore = false
      }
    }

    if !queryIsReadOnly {
      rowsAffected = exsqlite3_changes(db)
      if rowsAffected > 0 {
        insertId = exsqlite3_last_insert_rowid(db)
      }
    }

    exsqlite3_finalize(statement)

    if error != nil {
      return [error]
    }

    return [nil, insertId, rowsAffected, columnNames, resultRows]
  }

  private func bindStatement(statement: OpaquePointer?, with arg: NSObject, at index: Int32) {
    if arg == NSNull() {
      exsqlite3_bind_null(statement, index)
    } else if arg is Double {
      exsqlite3_bind_double(statement, index, arg as? Double ?? 0.0)
    } else {
      var stringArg: NSString

      if arg is NSString {
        stringArg = NSString(format: "%@", arg)
      } else {
        stringArg = arg.description as NSString
      }

      let SQLITE_TRANSIENT = unsafeBitCast(OpaquePointer(bitPattern: -1), to: sqlite3_destructor_type.self)

      let data = stringArg.data(using: NSUTF8StringEncoding)
      exsqlite3_bind_text(statement, index, stringArg.utf8String, Int32(data?.count ?? 0), SQLITE_TRANSIENT)
    }
  }

  private func getSqlValue(for columnType: Int32, with statement: OpaquePointer?, index: Int32) -> Any? {
    switch columnType {
    case SQLITE_INTEGER:
      return exsqlite3_column_int64(statement, index)
    case SQLITE_FLOAT:
      return exsqlite3_column_double(statement, index)
    case SQLITE_BLOB, SQLITE_TEXT:
      return NSString(bytes: exsqlite3_column_text(statement, index), length: Int(exsqlite3_column_bytes(statement, index)), encoding: NSUTF8StringEncoding)
    default:
      return nil
    }
  }

  private func convertSqlLiteErrorToString(db: OpaquePointer?) -> String {
    let code = exsqlite3_errcode(db)
    let message = NSString(utf8String: exsqlite3_errmsg(db)) ?? ""
    return NSString(format: "Error code %i: %@", code, message) as String
  }
}
