String toBanglaNumber(dynamic number) {
  const english = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "."];
  const bangla = ["০", "১", "২", "৩", "৪", "৫", "৬", "৭", "৮", "৯", "."];

  String str = number.toString();

  for (int i = 0; i < english.length; i++) {
    str = str.replaceAll(english[i], bangla[i]);
  }

  return str;
}
