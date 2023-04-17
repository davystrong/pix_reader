import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:pix_reader/pix_code.dart';
import 'package:qr_flutter/qr_flutter.dart';

class ScannerHomePage extends StatefulWidget {
  const ScannerHomePage({super.key});

  @override
  State<ScannerHomePage> createState() => _ScannerHomePageState();
}

class ListItemPair {
  final PixCode pixCode;
  bool accepted = false;

  ListItemPair(this.pixCode);
}

class _ScannerHomePageState extends State<ScannerHomePage> {
  List<ListItemPair> pixCodes = [];
  bool scanning = true;
  var listKey = GlobalKey<AnimatedListState>();
  String? qrCodeData;
  bool active = false;

  Widget buildListItem(
    BuildContext context,
    ListItemPair pair,
    Animation<double> animation, [
    int? index,
  ]) {
    return SizeTransition(
      sizeFactor: animation,
      child: PixCodeItem(
        pixCode: pair.pixCode,
        accepted: pair.accepted,
        callback: index != null && scanning
            ? () {
                if (!pair.accepted) {
                  pair.accepted = true;
                } else {
                  AnimatedList.of(context).removeItem(
                      index,
                      (context, animation) =>
                          buildListItem(context, pair, animation));
                  pixCodes.removeAt(index);
                }
                setState(() {});
              }
            : null,
      ),
    );
  }

  // Offset getQRPosition(Widget) {
  //   var box = floatingActionButtonKey.currentContext?.findRenderObject() as RenderBox;
  //   box.localto
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Pix Checkout'),
      ),
      body: Column(
        children: [
          ConstrainedBox(
            constraints: BoxConstraints.loose(const Size.square(400)),
            child: AspectRatio(
              aspectRatio: 1,
              child: Stack(
                children: [
                  MobileScanner(
                    // fit: BoxFit.contain,
                    onDetect: (capture) {
                      if (scanning) {
                        final List<Barcode> barcodes = capture.barcodes;
                        try {
                          var pixCode = barcodes.reversed
                              .map((e) => e.rawValue)
                              .nonNulls
                              .map(PixCode.tryDeserialise)
                              .nonNulls
                              .firstOrNull;
                          if (pixCode != null) {
                            if (!(pixCodes.firstOrNull?.accepted ?? true)) {
                              if (pixCode != pixCodes.first.pixCode) {
                                var toRemove = pixCodes.removeAt(0);
                                listKey.currentState?.removeItem(
                                    0,
                                    (context, animation) => buildListItem(
                                        context, toRemove, animation));
                                pixCodes.insert(0, ListItemPair(pixCode));
                                listKey.currentState?.insertItem(0);
                              }
                            } else {
                              pixCodes.insert(0, ListItemPair(pixCode));
                              listKey.currentState?.insertItem(0);
                            }
                            setState(() {});
                          }
                        } on InvalidPixCode {
                          // Ignore errors
                        }
                      }
                    },
                  ),
                  AnimatedScale(
                    scale: scanning ? 0 : 1,
                    duration: const Duration(milliseconds: 200),
                    onEnd: () {
                      if (scanning) {
                        qrCodeData = null;
                      }
                    },
                    child: qrCodeData == null
                        ? Container()
                        : Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Material(
                              borderRadius: BorderRadius.circular(5),
                              elevation: 5,
                              child: QrImage(
                                data: qrCodeData!,
                              ),
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: Material(
              child: AnimatedList(
                clipBehavior: Clip.none,
                key: listKey,
                initialItemCount: 0,
                itemBuilder: (context, index, animation) =>
                    buildListItem(context, pixCodes[index], animation, index),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: pixCodes.where((e) => e.accepted).isNotEmpty
          ? FloatingActionButton(
              onPressed: () {
                if (scanning) {
                  scanning = false;
                  qrCodeData = pixCodes
                      .map((e) => e.accepted ? e.pixCode : null)
                      .nonNulls
                      .reduce((value, element) => value + element)
                      .serialise();

                  if (!(pixCodes.firstOrNull?.accepted ?? true)) {
                    var toRemove = pixCodes.removeAt(0);
                    listKey.currentState?.removeItem(
                        0,
                        (context, animation) =>
                            buildListItem(context, toRemove, animation));
                  }
                } else {
                  scanning = true;
                  while (pixCodes.isNotEmpty) {
                    var toRemove = pixCodes.removeAt(0);
                    listKey.currentState?.removeItem(
                        0,
                        (context, animation) =>
                            buildListItem(context, toRemove, animation));
                  }
                }
                setState(() {});
              },
              tooltip: 'Done',
              child:
                  Icon(scanning ? Icons.shopping_cart_checkout : Icons.close),
            )
          : null,
    );
  }
}

class PixCodeItem extends StatelessWidget {
  final PixCode pixCode;
  final bool accepted;
  final VoidCallback? callback;

  const PixCodeItem({
    required this.pixCode,
    required this.accepted,
    required this.callback,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedPadding(
      duration: const Duration(milliseconds: 200),
      padding: accepted
          ? const EdgeInsets.only(bottom: 0)
          : const EdgeInsets.only(bottom: 8),
      child: Card(
        elevation: accepted ? 0.5 : 6,
        child: ListTile(
          title: Text('R\$ ${pixCode.value.toStringAsFixed(2)}'),
          trailing: IconButton(
            icon: Icon(accepted
                ? Icons.remove_shopping_cart
                : Icons.add_shopping_cart),
            onPressed: callback,
          ),
        ),
      ),
    );
  }
}
