class ValidationUtils {
  static String? validateRequired(String? value) {
    if (value == null || value.isEmpty) {
      return 'This field is required';
    }
    return null;
  }

  static String? validatePhoneNumber(String? value) {
    if (value == null || value.isEmpty) return 'Phone number is required';
    if (!RegExp(r'^[+]*[(]{0,1}[0-9]{1,4}[)]{0,1}[-\s\./0-9]*$').hasMatch(value)) {
      return 'Enter a valid phone number';
    }
    return null;
  }

  static String? validatePrice(String? value) {
    if (value == null || value.isEmpty) return 'Price is required';
    if (double.tryParse(value) == null) return 'Enter a valid number';
    return null;
  }

  static String? validateQuantity(String? value) {
    if (value == null || value.isEmpty) return 'Quantity is required';
    if (int.tryParse(value) == null) return 'Enter a whole number';
    if (int.parse(value) <= 0) return 'Must be at least 1';
    return null;
  }
}