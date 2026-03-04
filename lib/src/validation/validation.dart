import '../core/exceptions.dart';

/// Base class for validation constraints.
abstract class Constraint {
  const Constraint();

  /// Checks if the value is valid.
  /// Returns `null` if valid, or an error message if invalid.
  String? validate(String fieldName, dynamic value);
}

/// Validates that a field is not null.
class NotNull extends Constraint {
  const NotNull();

  @override
  String? validate(String fieldName, dynamic value) {
    if (value == null) {
      return '$fieldName cannot be null';
    }
    return null;
  }
}

/// Validates that a string is not empty.
class NotEmpty extends Constraint {
  const NotEmpty();

  @override
  String? validate(String fieldName, dynamic value) {
    if (value == null) return null; // Let NotNull handle nulls
    if (value is String && value.isEmpty) {
      return '$fieldName cannot be empty';
    }
    if (value is List && value.isEmpty) {
      return '$fieldName cannot be empty';
    }
    if (value is Map && value.isEmpty) {
      return '$fieldName cannot be empty';
    }
    return null;
  }
}

/// Validates that a number is greater than or equal to a minimum value.
class Min extends Constraint {
  final num value;
  const Min(this.value);

  @override
  String? validate(String fieldName, dynamic input) {
    if (input == null) return null;
    if (input is num) {
      if (input < value) {
        return '$fieldName must be at least $value';
      }
    }
    return null;
  }
}

/// Validates that a number is less than or equal to a maximum value.
class Max extends Constraint {
  final num value;
  const Max(this.value);

  @override
  String? validate(String fieldName, dynamic input) {
    if (input == null) return null;
    if (input is num) {
      if (input > value) {
        return '$fieldName must be at most $value';
      }
    }
    return null;
  }
}

/// Validates that a string is a valid email address.
class Email extends Constraint {
  const Email();

  @override
  String? validate(String fieldName, dynamic value) {
    if (value == null) return null;
    if (value is String) {
      // Simple regex for email validation
      final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
      if (!emailRegex.hasMatch(value)) {
        return '$fieldName must be a valid email address';
      }
    }
    return null;
  }
}

/// Exception thrown when validation fails.
class ValidationException extends BadRequestException {
  final List<String> errors;

  ValidationException(this.errors)
    : super('Validation failed', body: {'errors': errors});

  @override
  String toString() => 'ValidationException: ${errors.join(', ')}';
}

/// Helper class for performing validations.
class Validator {
  /// Validates a single value against a list of constraints.
  /// Throws [ValidationException] if any constraint fails.
  static void validate(
    String fieldName,
    dynamic value,
    List<Constraint> constraints,
  ) {
    final errors = <String>[];
    for (final constraint in constraints) {
      final error = constraint.validate(fieldName, value);
      if (error != null) {
        errors.add(error);
      }
    }
    if (errors.isNotEmpty) {
      throw ValidationException(errors);
    }
  }

  /// Validates a single value against a list of constraints.
  /// Returns a list of error messages (empty if valid).
  static List<String> check(
    String fieldName,
    dynamic value,
    List<Constraint> constraints,
  ) {
    final errors = <String>[];
    for (final constraint in constraints) {
      final error = constraint.validate(fieldName, value);
      if (error != null) {
        errors.add(error);
      }
    }
    return errors;
  }
}
