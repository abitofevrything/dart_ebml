/// An internal helper class for breaking up the decoding of an EBML element
/// over async gaps while still keeping a fully synchronous conversion when
/// necessary.
class PartialConversion<T> {
  final T? value;
  final PartialConversion<T> Function()? continueConversion;

  final bool hasValue;

  /// Create a new [PartialConversion] with a value.
  PartialConversion.value(this.value)
      : continueConversion = null,
        hasValue = true;

  /// Create a new [PartialConversion] with a callback that will provide the
  /// value.
  PartialConversion.continueConversion(this.continueConversion)
      : value = null,
        hasValue = false;

  /// Create a new [PartialConversion] that runs [callback] repeatedly until
  /// [doWhile] returns false.
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

  /// Call the [continueConversion] callback to get the next [PartialConversion]
  /// in the chain if this [PartialConversion] has no value, or return `this`.
  PartialConversion<T> call() => hasValue ? this : continueConversion!();

  /// Resolve this [PartialConversion] to a known value.
  T resolve() {
    PartialConversion<T> current = this;
    while (!current.hasValue) {
      current = current();
    }
    return current.value as T;
  }

  /// Chain this [PartialConversion] with a computation.
  PartialConversion<U> map<U>(
          PartialConversion<U> Function(T value) callback) =>
      hasValue
          ? callback(value as T)
          : PartialConversion.continueConversion(() => this().map(callback));

  /// Create a [PartialConversion] that returns [value] if this
  /// [PartialConversion]'s [continueConversion] callback throws and [orElse]
  /// otherwise.
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
