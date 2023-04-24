import 'package:flutter/material.dart';
import 'package:pix_reader/pix_code.dart';
import 'package:qr_flutter/qr_flutter.dart';

class QrSticker extends StatelessWidget {
  final PixCode? pixCode;
  const QrSticker({super.key, this.pixCode});

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints.loose(const Size.fromWidth(400)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: FittedBox(
              child: QrImage(
                data: pixCode?.serialise() ?? 'none',
                padding: EdgeInsets.zero,
                size: 400,
              ),
            ),
          ),
          Text(
            'R\$ ${(pixCode?.value ?? 0).toStringAsFixed(2)}',
            style: const TextStyle(
              color: Colors.black,
              fontSize: 48,
            ),
          ),
        ],
      ),
    );
  }
}
