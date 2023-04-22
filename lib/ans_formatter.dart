import 'package:flutter/services.dart';

class ANSFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    var newText = ANSFormatter._replaceAccents(newValue.text);
    newText = newText.replaceAll(
        RegExp(
            r"""[^ 0@P`p!1AQaq“2BRbr#3CScs$4DTdt%5EUeu&6FVfv‘7GWgw(8HXhx)9IYiy*:JZjz+;K[k{,<L\l|\-=M]m}.>N^n~/?O_o]"""),
        '');
    return newValue.copyWith(text: newText);
  }

  static String _replaceAccents(String str) {
    var withDia =
        'ÀÁÂÃÄÅàáâãäåÒÓÔÕÕÖØòóôõöøÈÉÊËèéêëðÇçÐÌÍÎÏìíîïÙÚÛÜùúûüÑñŠšŸÿýŽž';
    var withoutDia =
        'AAAAAAaaaaaaOOOOOOOooooooEEEEeeeeeCcDIIIIiiiiUUUUuuuuNnSsYyyZz';

    for (int i = 0; i < withDia.length; i++) {
      str = str.replaceAll(withDia[i], withoutDia[i]);
    }

    return str;
  }
}
