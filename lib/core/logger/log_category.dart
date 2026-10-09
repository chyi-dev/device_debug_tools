enum LogCategory {
  app,
  database,
  device,
  ui,
}

extension LogCategoryX on LogCategory {
  String get label => name.toUpperCase();
}
