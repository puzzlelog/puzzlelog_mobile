// import 'package:flutter/material.dart';
// import 'package:flutter_painter/flutter_painter.dart';
// import 'package:flutter_colorpicker/flutter_colorpicker.dart';
// import 'package:dio/dio.dart';
// import 'dart:async';
// import '../../widgets/common_scaffold.dart';

// class DiaryCanvasEditor extends StatefulWidget {
//   final List<dynamic> selectedPieces;
//   const DiaryCanvasEditor({super.key, required this.selectedPieces});

//   @override
//   State<DiaryCanvasEditor> createState() => DiaryCanvasEditorState();
// }

// class DiaryCanvasEditorState extends State<DiaryCanvasEditor> {
//   final PainterController _controller = PainterController();
//   List<dynamic> backgroundImages = [];
//   List<dynamic> stickers = [];
//   String currentMode = 'pen';
//   Color penColor = Colors.black;
//   double penWidth = 3.0;

//   @override
//   void initState() {
//     super.initState();
//     _initPainter();
//     _fetchStickers();
//   }

//   void _initPainter() {
//     _controller.freeStyleSettings = FreeStyleSettings(
//       color: penColor,
//       strokeWidth: penWidth,
//       mode: FreeStyleMode.draw,
//     );
//   }

//   Future<void> _fetchStickers() async {
//     final dio = Dio();
//     final res = await dio.get("https://api.puzzlelog.me/admin/assets");

//     if (res.statusCode == 200 && res.data['success']) {
//       final data = res.data['data'];
//       setState(() {
//         stickers = data.where((s) => s['type'] != 'AD' && s['type'] != 'background').toList();
//         backgroundImages = data.where((s) => s['type'] == 'background').toList();
//       });
//     }
//   }

//   void _setBackground(String imageUrl) async {
//     final imageProvider = NetworkImage(imageUrl);
//     final imageInfo = await _getImageInfo(imageProvider);
//     setState(() {
//       _controller.background = ImageBackgroundDrawable(image: imageInfo.image);
//     });
//   }

//   void _addSticker(String imageUrl) async {
//     final imageProvider = NetworkImage(imageUrl);
//     final imageInfo = await _getImageInfo(imageProvider);
//     final drawable = ImageDrawable(
//       image: imageInfo.image,
//       position: const Offset(150, 150),
//       scale: 0.3,
//     );
//     setState(() {
//       _controller.addDrawables([drawable]);
//     });
//   }

//   Future<ImageInfo> _getImageInfo(ImageProvider provider) async {
//     final completer = Completer<ImageInfo>();
//     final stream = provider.resolve(const ImageConfiguration());
//     final listener = ImageStreamListener((info, _) => completer.complete(info));
//     stream.addListener(listener);
//     final imageInfo = await completer.future;
//     stream.removeListener(listener);
//     return imageInfo;
//   }

//   void _toggleEraser() {
//     setState(() {
//       final isEraser = _controller.freeStyleSettings.mode == FreeStyleMode.erase;
//       _controller.freeStyleSettings = _controller.freeStyleSettings.copyWith(
//         mode: isEraser ? FreeStyleMode.draw : FreeStyleMode.erase,
//       );
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return CommonScaffold(
//       body: Column(
//         children: [
//           _buildTopToolbar(),
//           Expanded(child: FlutterPainter(controller: _controller)),
//           _buildBottomToolbar(),
//         ],
//       ),
//     );
//   }

//   Widget _buildTopToolbar() {
//     return Row(
//       mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//       children: [
//         IconButton(icon: const Icon(Icons.brush), onPressed: () => setState(() => currentMode = 'pen')),
//         IconButton(icon: const Icon(Icons.image), onPressed: _showStickerSelector),
//         IconButton(icon: const Icon(Icons.wallpaper), onPressed: _showBackgroundSelector),
//         IconButton(icon: const Icon(Icons.cleaning_services), onPressed: _toggleEraser),
//         IconButton(icon: const Icon(Icons.delete), onPressed: () => setState(() => _controller.clearDrawables())),
//       ],
//     );
//   }

//   Widget _buildBottomToolbar() {
//     if (currentMode == 'pen') {
//       return Row(
//         children: [
//           Expanded(
//             child: Slider(
//               min: 1,
//               max: 15,
//               value: penWidth,
//               onChanged: (value) {
//                 setState(() {
//                   penWidth = value;
//                   _controller.freeStyleSettings = _controller.freeStyleSettings.copyWith(strokeWidth: penWidth);
//                 });
//               },
//             ),
//           ),
//           IconButton(
//             icon: const Icon(Icons.color_lens),
//             onPressed: () async {
//               final color = await showDialog<Color>(
//                 context: context,
//                 builder: (context) => AlertDialog(
//                   content: SingleChildScrollView(
//                     child: BlockPicker(
//                       pickerColor: penColor,
//                       onColorChanged: (color) => Navigator.pop(context, color),
//                     ),
//                   ),
//                 ),
//               );
//               if (color != null) {
//                 setState(() {
//                   penColor = color;
//                   _controller.freeStyleSettings = _controller.freeStyleSettings.copyWith(color: penColor);
//                 });
//               }
//             },
//           ),
//         ],
//       );
//     }
//     return const SizedBox.shrink();
//   }

//   void _showStickerSelector() {
//     showModalBottomSheet(
//       context: context,
//       builder: (_) => GridView.builder(
//         padding: const EdgeInsets.all(10),
//         gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//             crossAxisCount: 4, crossAxisSpacing: 5, mainAxisSpacing: 5),
//         itemCount: stickers.length,
//         itemBuilder: (_, idx) {
//           final sticker = stickers[idx];
//           return GestureDetector(
//             onTap: () {
//               _addSticker(sticker['imageUrl']);
//               Navigator.pop(context);
//             },
//             child: Image.network(sticker['imageUrl']),
//           );
//         },
//       ),
//     );
//   }

//   void _showBackgroundSelector() {
//     showModalBottomSheet(
//       context: context,
//       builder: (_) => GridView.builder(
//         padding: const EdgeInsets.all(10),
//         gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//             crossAxisCount: 4, crossAxisSpacing: 5, mainAxisSpacing: 5),
//         itemCount: backgroundImages.length,
//         itemBuilder: (_, idx) {
//           final bg = backgroundImages[idx];
//           return GestureDetector(
//             onTap: () {
//               _setBackground(bg['imageUrl']);
//               Navigator.pop(context);
//             },
//             child: Image.network(bg['imageUrl']),
//           );
//         },
//       ),
//     );
//   }
// }
