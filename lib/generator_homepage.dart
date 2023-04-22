import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_masked_text2/flutter_masked_text2.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:pasteboard/pasteboard.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pix_reader/ans_formatter.dart';
import 'package:pix_reader/pix_code.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:screenshot/screenshot.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'main.dart';
import 'download.dart' if (dart.library.html) 'download_web.dart';

final pixCodeProvider = StateProvider<PixCode?>((ref) => null);

class GeneratorHomePage extends ConsumerStatefulWidget {
  const GeneratorHomePage({super.key});

  @override
  ConsumerState<GeneratorHomePage> createState() => _GeneratorHomePageState();
}

class _GeneratorHomePageState extends ConsumerState<GeneratorHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Pix Checkout'),
        actions: [
          IconButton(
            onPressed: () {
              ref.read(appModeProvider.notifier).state = AppMode.scanner;
            },
            icon: const Icon(Icons.camera_alt),
          ),
        ],
      ),
      body: ListView(
        children: const [
          Center(
            child: QrSticker(),
          ),
          PixEditor(),
        ],
      ),
    );
  }
}

class PixEditor extends ConsumerStatefulWidget {
  const PixEditor({Key? key}) : super(key: key);

  @override
  ConsumerState<PixEditor> createState() => _PixEditorState();
}

class _PixEditorState extends ConsumerState<PixEditor> {
  final formKey = GlobalKey<FormState>();

  final pixCodeController = TextEditingController();
  final pixIdController = TextEditingController();
  final valueController = MoneyMaskedTextController(leftSymbol: 'R\$ ');
  final nameController = TextEditingController();
  final referenceLabelController = TextEditingController();
  final messageController = TextEditingController();
  final cityController = TextEditingController();
  final cepController = TextEditingController();
  final Future<SharedPreferences> prefs = SharedPreferences.getInstance();

  void restoreValues() async {
    final prefs = await this.prefs;
    pixIdController.text = prefs.getString('pixId') ?? '';
    nameController.text = prefs.getString('name') ?? '';
    cityController.text = prefs.getString('city') ?? '';
    cepController.text = prefs.getString('cep') ?? '';
  }

  @override
  void initState() {
    super.initState();
    restoreValues();
    ref.read(pixCodeProvider.notifier).addListener((pixCode) {
      if (pixCode != null && pixCodeController.text != pixCode.serialise()) {
        pixCodeController.text = pixCode.serialise();
      }
      if (pixCode != null) {
        // Had to check for each one because of a bug on web: any letter that was
        // typed caused all text in the field to be selected
        if (pixIdController.text != pixCode.pixId) {
          pixIdController.text = pixCode.pixId;
        }
        final newValueText = 'R\$ ${(pixCode.value ?? 0).toStringAsFixed(2)}';
        if (valueController.text != newValueText) {
          valueController.text = newValueText;
        }
        if (nameController.text != pixCode.name) {
          nameController.text = pixCode.name;
        }
        if (referenceLabelController.text != pixCode.referenceLabel) {
          referenceLabelController.text = pixCode.referenceLabel;
        }
        if (messageController.text != pixCode.message) {
          messageController.text = pixCode.message ?? '';
        }
        if (cityController.text != pixCode.city) {
          cityController.text = pixCode.city;
        }
        if (cepController.text != pixCode.cep) {
          cepController.text = pixCode.cep ?? '';
        }
      }
    });

    pixIdController.addListener(() async {
      final prefs = await this.prefs;
      prefs.setString('pixId', pixIdController.text);
    });
    nameController.addListener(() async {
      final prefs = await this.prefs;
      prefs.setString('name', nameController.text);
    });
    cityController.addListener(() async {
      final prefs = await this.prefs;
      prefs.setString('city', cityController.text);
    });
    cepController.addListener(() async {
      final prefs = await this.prefs;
      prefs.setString('cep', cepController.text);
    });
  }

  @override
  Widget build(BuildContext context) {
    final pixCode = ref.watch(pixCodeProvider);
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          TextField(
            controller: pixCodeController,
            onChanged: (value) {
              ref.read(pixCodeProvider.notifier).state =
                  PixCode.tryDeserialise(value);
              if (value.isEmpty) {
                pixIdController.text = '';
                valueController.text = 'R\$ 0.00';
                nameController.text = '';
                referenceLabelController.text = '';
                messageController.text = '';
                cityController.text = '';
                cepController.text = '';
              }
            },
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              label: const Text('Pix Code (Generated)'),
              suffixIcon: IconButton(
                icon: const CopyTextIcon(size: 24),
                onPressed: pixCode == null
                    ? null
                    : () {
                        Clipboard.setData(
                            ClipboardData(text: pixCode.serialise()));
                      },
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Divider(),
          const SizedBox(height: 8),
          Form(
            key: formKey,
            onChanged: () {
              // formKey.currentState!.validate()
              var value = double.parse(valueController.text
                  .replaceAll('.', '')
                  .replaceFirst(',', '.')
                  .replaceAll(RegExp(r'[^.0-9]'), ''));

              // var city = removeAccents(cityController.text)
              //     .replaceAll(RegExp(r'[^A-Z ]'), '');
              // cityController.

              var cep = cepController.text.replaceAll(RegExp(r'[^0-9]'), '');

              if (pixIdController.text.isNotEmpty &&
                  nameController.text.isNotEmpty &&
                  cityController.text.isNotEmpty) {
                ref.read(pixCodeProvider.notifier).state = PixCode(
                  pixId: pixIdController.text,
                  value: value,
                  name: nameController.text,
                  city: cityController.text,
                  cep: cep,
                  message: messageController.text,
                  referenceLabel: referenceLabelController.text,
                );
              } else {
                ref.read(pixCodeProvider.notifier).state = null;
              }
            },
            child: Column(
              children: [
                TextFormField(
                  controller: pixIdController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    label: Text('Pix Id'),
                    hintText:
                        'e.g. (CPF) 12345678909, (Phone) +5551999999999, ...',
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
                  inputFormatters: [ANSFormatter()],
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
                  inputFormatters: [ANSFormatter()],
                  maxLength: 15,
                  controller: cityController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    label: Text('City'),
                    hintText: 'e.g. Sao Paulo',
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
                  maxLength: 99,
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
                  inputFormatters: [ANSFormatter()],
                  controller: referenceLabelController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    label: Text('Reference Label (optional)'),
                    hintText: 'e.g. RX583jf82jdos96hr930',
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  inputFormatters: [ANSFormatter()],
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
        ],
      ),
    );
  }
}

class FadeBackground extends StatefulWidget {
  final double borderWidth;
  final Widget? child;
  const FadeBackground({Key? key, required this.borderWidth, this.child})
      : super(key: key);

  @override
  State<FadeBackground> createState() => _FadeBackgroundState();
}

class _FadeBackgroundState extends State<FadeBackground> {
  FragmentShader? shader;

  void loadShader() async {
    var program = await FragmentProgram.fromAsset('assets/shaders/shader.frag');
    shader = program.fragmentShader();
    setState(() {});
  }

  @override
  void initState() {
    loadShader();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return shader == null
        ? widget.child ?? Container()
        : CustomPaint(
            painter: FadePainter(
              widget.borderWidth,
              shader!,
            ),
            child: widget.child,
          );
  }
}

class FadePainter extends CustomPainter {
  final double borderWidth;
  final FragmentShader shader;

  FadePainter(this.borderWidth, this.shader);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    shader.setFloat(0, size.width);
    shader.setFloat(1, size.height);
    shader.setFloat(2, borderWidth);
    paint.blendMode = BlendMode.srcOver;
    paint.shader = shader;
    final rect = Offset.zero & size;
    canvas.drawRect(rect, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}

class QrSticker extends ConsumerStatefulWidget {
  const QrSticker({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _QrStickerState();
}

class _QrStickerState extends ConsumerState<QrSticker> {
  ScreenshotController screenshotController = ScreenshotController();
  bool showSave = false;
  bool hovering = false;
  int visibleIndex = 0;

  @override
  Widget build(BuildContext context) {
    final pixCode = ref.watch(pixCodeProvider);
    if (pixCode != null) {
      visibleIndex = 0;
    } else if (visibleIndex == 0) {
      visibleIndex = 1;
    }
    return MouseRegion(
      onEnter: (event) {
        hovering = true;
        setState(() {});
      },
      onExit: (event) {
        hovering = false;
        setState(() {});
      },
      child: GestureDetector(
        onTap: () {
          showSave = true;
          setState(() {});
          Timer(const Duration(seconds: 2), () {
            showSave = false;
            setState(() {});
          });
        },
        child: ConstrainedBox(
          constraints: BoxConstraints.loose(const Size.fromWidth(300)),
          child: IndexedStack(
            alignment: Alignment.center,
            index: visibleIndex,
            children: [
              Card(
                clipBehavior: Clip.antiAlias,
                surfaceTintColor: Colors.white,
                elevation: 5,
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    ConstrainedBox(
                      constraints:
                          BoxConstraints.loose(const Size.fromWidth(300)),
                      child: Screenshot(
                        controller: screenshotController,
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
                                  size: 300,
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
                      ),
                    ),
                    Align(
                      alignment: Alignment.bottomRight,
                      child: AnimatedOpacity(
                        opacity: showSave || hovering ? 1 : 0,
                        duration: const Duration(milliseconds: 500),
                        child: QrOverlay(screenshotController),
                      ),
                    ),
                  ],
                ),
              ),
              Center(
                child: RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    children: [
                      const TextSpan(
                        text: 'Not enough information for Pix code.\n',
                        style: TextStyle(color: Colors.black),
                      ),
                      TextSpan(
                        text: 'Scan a QR code',
                        style: const TextStyle(
                            color: Colors.blue,
                            decoration: TextDecoration.underline),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () {
                            visibleIndex = 2;
                            setState(() {});
                          },
                      )
                    ],
                  ),
                ),
              ),
              if (visibleIndex == 2)
                AspectRatio(
                  aspectRatio: 1,
                  child: Transform.flip(
                    flipX: defaultTargetPlatform == TargetPlatform.linux ||
                        defaultTargetPlatform == TargetPlatform.macOS ||
                        defaultTargetPlatform == TargetPlatform.windows,
                    child: MobileScanner(
                      onDetect: (capture) {
                        final List<Barcode> barcodes = capture.barcodes;
                        try {
                          final scannedCode = barcodes.reversed
                              .map((e) => e.rawValue)
                              .nonNulls
                              .map(PixCode.tryDeserialise)
                              .nonNulls
                              .firstOrNull;
                          if (scannedCode != null) {
                            ref.read(pixCodeProvider.notifier).state =
                                scannedCode;
                          }
                        } on InvalidPixCode {
                          // Ignore errors
                        }
                      },
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class QrOverlay extends ConsumerWidget {
  final ScreenshotController screenshotController;
  const QrOverlay(this.screenshotController, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pixCode = ref.watch(pixCodeProvider);
    return FadeBackground(
      borderWidth: 24,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 8, 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const CopyImageIcon(size: 32),
              onPressed: pixCode == null
                  ? null
                  : () async {
                      final image = await screenshotController.capture();
                      if (image != null) {
                        if (!kIsWeb &&
                            (defaultTargetPlatform == TargetPlatform.linux ||
                                defaultTargetPlatform == TargetPlatform.macOS ||
                                defaultTargetPlatform ==
                                    TargetPlatform.windows)) {
                          final Directory tmpDir =
                              await getTemporaryDirectory();
                          final File tmpFile =
                              File('${tmpDir.path}/qr_code.png');
                          await tmpFile.writeAsBytes(image);
                          Pasteboard.writeFiles([tmpFile.path]);
                        } else {
                          Pasteboard.writeImage(image);
                        }
                      }
                    },
            ),
            IconButton(
              icon: const Icon(kIsWeb ? Icons.download : Icons.save, size: 32),
              onPressed: pixCode == null
                  ? null
                  : () async {
                      String initials = pixCode.name
                          .splitMapJoin(' ',
                              onMatch: (part) => '',
                              onNonMatch: (part) =>
                                  part.isEmpty ? '' : part.substring(0, 1))
                          .toLowerCase();
                      String filename =
                          'pix_${initials}_${(pixCode.value ?? 0).toStringAsFixed(2).replaceAll('.', '_')}.png';

                      final image = await screenshotController.capture();
                      if (image != null) {
                        download(image, filename);
                      }
                    },
            ),
          ],
        ),
      ),
    );
  }
}

class CopyTextIcon extends StatelessWidget {
  final double size;
  const CopyTextIcon({super.key, required this.size});

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: FittedBox(
        child: SizedBox.square(
          dimension: 100,
          child: Stack(
            children: [
              const Icon(Icons.copy, size: 100),
              Transform(
                transform:
                    Matrix4.translationValues(36, 18, 0).scaled(0.4, 0.8),
                child: const Icon(Icons.menu, size: 100),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CopyImageIcon extends StatelessWidget {
  final double size;
  const CopyImageIcon({super.key, required this.size});

  @override
  Widget build(BuildContext context) {
    return SizedBox.fromSize(
      size: Size.square(size),
      child: FittedBox(
        child: Stack(
          children: [
            const Icon(Icons.copy, size: 100),
            Transform(
              transform: Matrix4.translationValues(16, 8, 0).scaled(0.8, 1.0),
              child: const Icon(Icons.image_outlined, size: 100),
            ),
          ],
        ),
      ),
    );
  }
}
