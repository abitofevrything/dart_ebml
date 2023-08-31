class PartialConversion<T> {
  final T? value;
  final PartialConversion<T> Function()? continueConversion;

  final bool hasValue;

  PartialConversion.value(this.value)
      : continueConversion = null,
        hasValue = true;

  PartialConversion.continueConversion(this.continueConversion)
      : value = null,
        hasValue = false;

  static PartialConversion<void> nullValue() => PartialConversion.value(null);

  static PartialConversion<List<T>> many<T>(
    PartialConversion<T> Function(List<T>) callback, {
    bool Function(T)? doWhile,
  }) {
    doWhile ??= (value) => value != null;

    PartialConversion<List<T>> helper(List<T> current) {
      return callback(current).map((value) {
        if (doWhile!(value)) {
          // No need for immutability, nobody is going to touch this list after this call
          return helper(current..add(value));
        } else {
          return PartialConversion.value(current);
        }
      });
    }

    return helper([]);
  }

  PartialConversion<T> call() => hasValue ? this : continueConversion!();

  T resolve() {
    PartialConversion<T> current = this;
    while (!current.hasValue) {
      current = current();
    }
    return current.value as T;
  }

  PartialConversion<U> map<U>(PartialConversion<U> Function(T value) callback) => hasValue
      ? callback(value as T)
      : PartialConversion.continueConversion(() => this().map(callback));

  PartialConversion<U> ifThrows<U>(U value, {required U orElse}) {
    return PartialConversion.continueConversion(() {
      try {
        final result = this();

        if (result.hasValue) {
          return PartialConversion.value(orElse);
        } else {
          return result.ifThrows(value, orElse: orElse);
        }
      } catch (_) {
        return PartialConversion.value(value);
      }
    });
  }
}
