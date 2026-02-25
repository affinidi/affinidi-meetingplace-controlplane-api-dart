/// Utility functions for working with DateTime objects.
library;

/// Returns the current date and time in UTC.
///
/// This should be used instead of `DateTime.now()` to ensure all timestamps
/// are timezone-independent and consistent across the application.
DateTime nowUtc() => DateTime.now().toUtc();
