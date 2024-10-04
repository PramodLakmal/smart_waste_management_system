bool isValidEmail(String email) {
  return RegExp(r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,4}$").hasMatch(email);
}

bool isValidPassword(String password) {
  return password.length >= 6;
}
