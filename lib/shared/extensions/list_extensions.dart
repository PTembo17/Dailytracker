extension ListExtensions<T> on List<T> {
  Map<K, List<T>> groupBy<K>(K Function(T element) keyFunction) {
    final map = <K, List<T>>{};
    for (var element in this) {
      final key = keyFunction(element);
      map.putIfAbsent(key, () => []).add(element);
    }
    return map;
  }
}
