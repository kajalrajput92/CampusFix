/// Parses API timestamps and treats zone-less MySQL timestamps as UTC.
///
/// The API returns MySQL TIMESTAMP values without a timezone suffix. Parsing
/// those values as local time would leave them offset from the actual instant.
DateTime? parseApiDateTime(String value) {
  final hasTimezone = RegExp(r'(?:[zZ]|[+-]\d{2}:?\d{2})$').hasMatch(value);
  final isSqlTimestamp = RegExp(
    r'^\d{4}-\d{2}-\d{2}[ T]\d{2}:\d{2}:\d{2}(?:\.\d+)?$',
  ).hasMatch(value);
  final normalized = isSqlTimestamp && !hasTimezone
      ? '${value.replaceFirst(' ', 'T')}Z'
      : value;
  return DateTime.tryParse(normalized);
}
