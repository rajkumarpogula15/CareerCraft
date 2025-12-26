extension FirstOrNullExtension<T> on Iterable<T> {
  T? firstOrNull() {
    return isEmpty ? null : first;
  }
}
