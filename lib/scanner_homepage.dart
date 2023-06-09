import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:pix_reader/pix_code.dart';
import 'package:pix_reader/qr_sticker.dart';

import 'main.dart';

class ScannerHomePage extends ConsumerStatefulWidget {
  const ScannerHomePage({super.key});

  @override
  ConsumerState<ScannerHomePage> createState() => _ScannerHomePageState();
}

class ListItemPair {
  final PixCode pixCode;
  bool accepted = false;

  ListItemPair(this.pixCode);
}

class _ScannerHomePageState extends ConsumerState<ScannerHomePage> {
  List<ListItemPair> pixCodes = [];
  bool scanning = true;
  var listKey = GlobalKey<AnimatedListState>();
  PixCode? qrPixCode;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Pix Checkout'),
        actions: [
          IconButton(
            onPressed: () {
              ref.read(appModeProvider.notifier).state = AppMode.generator;
            },
            icon: const Icon(Icons.qr_code_2),
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              ConstrainedBox(
                constraints: BoxConstraints.loose(const Size.square(400)),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: Transform.flip(
                    flipX: defaultTargetPlatform == TargetPlatform.linux ||
                        defaultTargetPlatform == TargetPlatform.macOS ||
                        defaultTargetPlatform == TargetPlatform.windows,
                    child: MobileScanner(
                      onDetect: (capture) {
                        if (scanning) {
                          final List<Barcode> barcodes = capture.barcodes;
                          try {
                            final pixCode = barcodes.reversed
                                .map((e) => e.rawValue)
                                .nonNulls
                                .map(PixCode.tryDeserialise)
                                .nonNulls
                                .firstOrNull;
                            if (pixCode != null) {
                              if (!(pixCodes.firstOrNull?.accepted ?? true)) {
                                if (pixCode != pixCodes.first.pixCode) {
                                  final toRemove = pixCodes.removeAt(0);
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
                  ),
                ),
              ),
              Expanded(
                child: Material(
                  child: AnimatedList(
                    key: listKey,
                    initialItemCount: 0,
                    itemBuilder: (context, index, animation) => buildListItem(
                        context, pixCodes[index], animation, index),
                  ),
                ),
              ),
            ],
          ),
          Align(
            alignment: Alignment.topCenter,
            child: AnimatedScale(
              scale: scanning ? 0 : 1,
              duration: const Duration(milliseconds: 200),
              onEnd: () {
                if (scanning) {
                  qrPixCode = null;
                }
              },
              child: Card(
                surfaceTintColor: Colors.white,
                elevation: 5,
                child: QrSticker(
                  pixCode: qrPixCode,
                ),
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
                  qrPixCode = pixCodes
                      .map((e) => e.accepted ? e.pixCode : null)
                      .nonNulls
                      .reduce((value, element) => value + element);

                  if (!(pixCodes.firstOrNull?.accepted ?? true)) {
                    listKey.currentState?.removeItem(
                        0,
                        (context, animation) =>
                            buildListItem(context, pixCodes[0], animation));
                    pixCodes.removeAt(0);
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
          title: Text('R\$ ${(pixCode.value ?? 0).toStringAsFixed(2)}'),
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
