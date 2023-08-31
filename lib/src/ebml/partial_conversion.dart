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

  static PartialConversion<Null> nullValue() => PartialConversion.value(null);

  static PartialConversion<List<T>> many<T extends Object>(
    PartialConversion<T?> Function() callback,
  ) {
    PartialConversion<List<T>> helper(List<T> current) {
      return callback().map((value) {
        if (value is T) {
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
}
