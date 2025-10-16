T asType<T>(dynamic value, T fallback) {
  if (value is T) return value;
  if (value == null) return fallback;
  try {
    if (T == String) return value.toString() as T;
    if (T == int) {
      return (int.tryParse(value.toString()) ?? fallback as int) as T;
    }
    if (T == double) {
      return (double.tryParse(value.toString()) ?? fallback as double) as T;
    }
    if (T == bool) {
      final s = value.toString().toLowerCase();
      if (s == 'true' || s == '1') return true as T;
      if (s == 'false' || s == '0') return false as T;
      return fallback;
    }
  } catch (_) {
    return fallback;
  }
  return fallback;
}

DateTime? asDateTime(dynamic value) {
  if (value == null) return null;
  try {
    return DateTime.parse(value.toString());
  } catch (_) {
    return null;
  }
}
