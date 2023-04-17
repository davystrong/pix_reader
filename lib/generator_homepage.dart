import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_masked_text2/flutter_masked_text2.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:pix_reader/pix_code.dart';
import 'package:qr_flutter/qr_flutter.dart';

class GeneratorHomePage extends StatefulWidget {
  const GeneratorHomePage({super.key});

  @override
  State<GeneratorHomePage> createState() => _GeneratorHomePageState();
}

class _GeneratorHomePageState extends State<GeneratorHomePage> {
  PixCode? pixCode;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Pix Checkout'),
      ),
      body: ListView(
        children: [
          Center(
            child: ConstrainedBox(
              constraints: BoxConstraints.loose(const Size.square(300)),
              child: AspectRatio(
                  aspectRatio: 1,
                  child: pixCode != null
                      ? QrImage(
                          data: pixCode!.serialise(),
                        )
                      : const Center(
                          child: Text('Not enough information for Pix code'),
                        )),
            ),
          ),
          PixEditor(
            onChanged: (newCode) {
              pixCode = newCode;
              setState(() {});
            },
          ),
        ],
      ),
      floatingActionButton: pixCode != null
          ? FloatingActionButton(
              onPressed: () {},
              tooltip: 'Save',
              child: const Icon(Icons.save),
            )
          : null,
    );
  }
}

class PixEditor extends StatefulWidget {
  final void Function(PixCode?) onChanged;
  const PixEditor({
    Key? key,
    required this.onChanged,
  }) : super(key: key);

  @override
  State<PixEditor> createState() => _PixEditorState();
}

class _PixEditorState extends State<PixEditor> {
  var formKey = GlobalKey<FormState>();
  PixCode? pixCode;

  var pixIdController = TextEditingController();
  var valueController = MoneyMaskedTextController(leftSymbol: 'R\$ ');
  var nameController = TextEditingController();
  var referenceLabelController = TextEditingController();
  var messageController = TextEditingController();
  var cityController = TextEditingController();
  var cepController = TextEditingController();

  static String removeAccents(String str) {
    var withDia =
        'ÀÁÂÃÄÅàáâãäåÒÓÔÕÕÖØòóôõöøÈÉÊËèéêëðÇçÐÌÍÎÏìíîïÙÚÛÜùúûüÑñŠšŸÿýŽž';
    var withoutDia =
        'AAAAAAaaaaaaOOOOOOOooooooEEEEeeeeeCcDIIIIiiiiUUUUuuuuNnSsYyyZz';

    for (int i = 0; i < withDia.length; i++) {
      str = str.replaceAll(withDia[i], withoutDia[i]);
    }

    return str;
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      onChanged: () {
        // formKey.currentState!.validate()
        var value = double.parse(valueController.text
            .replaceAll('.', '')
            .replaceFirst(',', '.')
            .replaceAll(RegExp(r'[^.0-9]'), ''));

        var city = removeAccents(cityController.text)
            .toUpperCase()
            .replaceAll(RegExp(r'[^A-Z ]'), '');

        var cep = cepController.text.replaceAll(RegExp(r'[^0-9]'), '');

        if (pixIdController.text.isNotEmpty &&
            value > 0 &&
            nameController.text.isNotEmpty &&
            city.isNotEmpty &&
            cep.isNotEmpty) {
          var newCode = PixCode(
            pixId: pixIdController.text,
            value: value,
            name: nameController.text,
            city: city,
            cep: cep,
            message: messageController.text,
            referenceLabel: referenceLabelController.text,
          );
          if (pixCode != newCode) {
            pixCode = newCode;
            widget.onChanged(pixCode);
          }
        } else if (pixCode != null) {
          pixCode = null;
          widget.onChanged(null);
        }
      },
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            TextFormField(
              controller: pixIdController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                label: Text('Pix Id (Exact)'),
                hintText: 'e.g. 123.456.789-09',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a value';
                }
                return null;
              },
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: valueController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                label: Text('Value'),
                hintText: 'e.g. R\$ 4.99',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a value';
                }
                return null;
              },
            ),
            const SizedBox(height: 8),
            TextFormField(
              maxLength: 25,
              controller: nameController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                label: Text('Name'),
                hintText: 'e.g. John Doe',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a value';
                }
                return null;
              },
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: cityController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                label: Text('City'),
                hintText: 'e.g. SAO PAULO',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a value';
                }
                return null;
              },
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: cepController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                label: Text('CEP'),
                hintText: 'e.g. 05409000',
              ),
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.digitsOnly
              ],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a value';
                }
                return null;
              },
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: referenceLabelController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                label: Text('Reference Label (optional)'),
                hintText: 'e.g. RX583jf82jdos96hr930',
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: messageController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                label: Text('Message (optional)'),
                hintText: 'e.g. Chocolate',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FormRow extends StatelessWidget {
  final String title;
  final String tip;
  final void Function(String data) onChanged;
  const FormRow(
      {Key? key,
      required this.title,
      required this.tip,
      required this.onChanged})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(title),
        TextFormField(
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            hintText: tip,
          ),
          onChanged: onChanged,
        )
      ],
    );
  }
}
