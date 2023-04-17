import 'dart:collection';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

class IncompatiblePixCodes implements Exception {}

class InvalidPixCode implements Exception {}

class PixCode {
  final String pixId;
  final double value;
  final String name;
  final String referenceLabel;
  final String? message;
  final String city;
  final String cep;

  static String _generateRandomString(int len) {
    var r = Random();
    return String.fromCharCodes(List.generate(len, (_) {
      var index = r.nextInt(2 * 26);
      return index + (index < 26 ? 65 : (97 - 26));
    }));
  }

  PixCode({
    required this.pixId,
    required this.value,
    required this.name,
    required this.city,
    required this.cep,
    String? referenceLabel,
    this.message,
  }) : referenceLabel = referenceLabel ?? _generateRandomString(20);

  // Note: Should be printed in hex
  static int _crc16(String data) {
    Uint8List bytes = Uint8List.fromList(utf8.encode(data));
    const POLYNOMIAL = 0x1021;
    const INIT_VALUE = 0xFFFF;

    final bitRange = Iterable.generate(8);

    var crc = INIT_VALUE;
    for (var byte in bytes) {
      crc ^= (byte << 8);
      for (var i in bitRange) {
        crc = (crc & 0x8000) != 0 ? (crc << 1) ^ POLYNOMIAL : crc << 1;
      }
    }
    return crc &= 0xffff;
  }

  static HashMap<int, String> _getFields(String data) {
    int i = 0;
    var result = HashMap<int, String>();
    while (i < data.length) {
      int key = int.parse(data.substring(i, i + 2));
      int length = int.parse(data.substring(i + 2, i + 4));
      String value = data.substring(i + 4, i + 4 + length);
      result[key] = value;
      i += length + 4;
    }
    return result;
  }

  static String _stdLength(String value) => '${value.length}'.padLeft(2, '0');

  String serialise() {
    String nestedAccountInfo = '0014BR.GOV.BCB.PIX'
        '01${_stdLength(pixId)}$pixId';
    if (message != null) {
      nestedAccountInfo += '02${_stdLength(message!)}$message';
    }
    String nestedUID = '05${_stdLength(referenceLabel)}$referenceLabel';
    String valueStr = value.toStringAsFixed(2);
    String output = '000201'
        '26${_stdLength(nestedAccountInfo)}$nestedAccountInfo'
        '52040000'
        '5303986'
        '54${_stdLength(valueStr)}$valueStr'
        '5802BR'
        '59${_stdLength(name)}$name'
        '60${_stdLength(city)}$city'
        '61${_stdLength(cep)}$cep'
        '62${_stdLength(nestedUID)}$nestedUID'
        '6304';
    output += _crc16(output).toRadixString(16).padLeft(4, '0');
    return output;
  }

  static PixCode? tryDeserialise(String data) {
    try {
      return PixCode.deserialise(data);
    } on InvalidPixCode {
      return null;
    }
  }

  factory PixCode.deserialise(String data) {
    var fields = _getFields(data);
    if (!fields.containsKey(26) ||
        !fields.containsKey(62) ||
        !fields.containsKey(54) ||
        !fields.containsKey(59) ||
        !fields.containsKey(60) ||
        !fields.containsKey(61)) {
      throw InvalidPixCode();
    }
    var nestedAccountInfo = _getFields(fields[26]!);
    var nestedUID = _getFields(fields[62]!);
    if (!nestedAccountInfo.containsKey(1) ||
        !nestedAccountInfo.containsKey(2) ||
        !nestedUID.containsKey(5)) {
      throw InvalidPixCode();
    }
    return PixCode(
      pixId: nestedAccountInfo[1]!,
      value: double.parse(fields[54]!),
      name: fields[59]!,
      city: fields[60]!,
      cep: fields[61]!,
      referenceLabel: nestedUID[5]!,
      message: nestedAccountInfo[2],
    );
  }

  @override
  PixCode operator +(PixCode rhs) {
    if (name != rhs.name ||
        pixId != rhs.pixId ||
        city != rhs.city ||
        cep != rhs.cep) {
      throw IncompatiblePixCodes();
    }
    return PixCode(
        pixId: pixId,
        value: value + rhs.value,
        name: name,
        city: city,
        cep: cep);
  }

  @override
  bool operator ==(Object other) =>
      other is PixCode &&
      other.runtimeType == runtimeType &&
      other.value == value &&
      other.pixId == pixId &&
      other.value == value &&
      other.name == name &&
      other.referenceLabel == referenceLabel &&
      other.message == message &&
      other.city == city &&
      other.cep == cep;

  @override
  int get hashCode =>
      1 * value.hashCode +
      2 * pixId.hashCode +
      3 * value.hashCode +
      4 * name.hashCode +
      5 * referenceLabel.hashCode +
      6 * message.hashCode +
      7 * city.hashCode +
      8 * cep.hashCode;
}
