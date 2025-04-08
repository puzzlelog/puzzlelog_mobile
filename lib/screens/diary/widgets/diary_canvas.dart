import 'package:flutter/material.dart';
import 'dart:math';
import 'package:video_player/video_player.dart';
import 'package:just_audio/just_audio.dart';
import 'package:flutter_svg/flutter_svg.dart';

class SvgResult {
  final String svg;
  final Offset position;
  SvgResult(this.svg, this.position);
}

class DiaryCanvas extends StatefulWidget {
  final List<Map<String, dynamic>> elements;
  final String? backgroundUrl;
  final bool readOnly;

  const DiaryCanvas({
    super.key,
    required this.elements,
    this.backgroundUrl,
    this.readOnly = false,
  });

  @override
  State<DiaryCanvas> createState() => DiaryCanvasState();
}

class DiaryCanvasState extends State<DiaryCanvas> {
  final List<Map<String, dynamic>> _elements = [];
  final Map<String, VideoPlayerController> _videoControllers = {};
  final Map<String, AudioPlayer> _audioPlayers = {};
  final List<Offset> _points = [];

  String? _backgroundUrl;
  String? _backgroundContentId;
  String? _selectedElementId;

  Color _penColor = Colors.black;
  double _penWidth = 3.0;
  bool _isDrawingMode = false;

  Offset _initialFocalPoint = Offset.zero;
  double _initialScale = 1.0;
  double _initialRotation = 0.0;

  @override
  void initState() {
    super.initState();
    _backgroundUrl = widget.backgroundUrl;
    _initElements();
    _addDateElementIfNotExist();
  }

  void _initElements() {
    for (var e in widget.elements) {
      final id = UniqueKey().toString();
      final element = {
        ...e,
        'elementId': id,
        'position': e['position'] ?? [100.0, 100.0],
        'scale': e['scale'] ?? 1.0,
        'rotation': e['rotation'] ?? 0.0,
      };
      _elements.add(element);
      _initMediaController(element, id);
    }
  }

  void _initMediaController(Map<String, dynamic> e, String id) {
    final type = e['elementType'];
    final mediaUrl = e['mediaId'] ?? e['content']?['mediaId'] ?? e['contentId'];
    if (type == 'VIDEO' && mediaUrl != null) {
      final controller = VideoPlayerController.network(mediaUrl)
        ..initialize().then((_) => setState(() {}));
      _videoControllers[id] = controller;
    }
    if (type == 'AUDIO' && mediaUrl != null) {
      final player = AudioPlayer();
      player.setUrl(mediaUrl);
      _audioPlayers[id] = player;
    }
  }

  void _addDateElementIfNotExist() {
    final exists = _elements.any((e) => e['elementType'] == 'DATE');
    if (!exists) addDateElement();
  }

  void addDateElement() {
    final today = DateTime.now();
    final dateText = "${today.year}-${_pad(today.month)}-${_pad(today.day)}";
    setState(() {
      _elements.insert(0, {
        'elementId': UniqueKey().toString(),
        'elementType': 'DATE',
        'date': dateText,
        'position': [20.0, 20.0],
        'scale': 1.0,
        'rotation': 0.0,
      });
    });
  }

  String _pad(int n) => n.toString().padLeft(2, '0');

  @override
  void dispose() {
    for (var c in _videoControllers.values) {
      c.dispose();
    }
    for (var p in _audioPlayers.values) {
      p.dispose();
    }
    super.dispose();
  }

  void addPieces(List<Map<String, dynamic>> newElements) {
    setState(() {
      _isDrawingMode = false;
      for (var e in newElements) {
        final id = UniqueKey().toString();
        e['elementId'] = id;
        e['elementType'] ??= e['type'];
        e['position'] ??= [100.0, 100.0];
        e['scale'] ??= 1.0;
        e['rotation'] ??= 0.0;
        _elements.add(e);
        _initMediaController(e, id);
      }
    });
  }

  void addSticker(Map<String, dynamic> sticker) {
    setState(() {
      _isDrawingMode = false;
      _elements.add({
        'elementId': UniqueKey().toString(),
        'elementType': 'STICKER',
        'mediaId': sticker['mediaId'],
        'contentId': sticker['id'],
        'position': [100.0, 100.0],
        'scale': 1.0,
        'rotation': 0.0,
      });
    });
  }

  void setBackground(String? url, String? contentId) {
    setState(() {
      _isDrawingMode = false;
      _backgroundUrl = url?.isNotEmpty == true ? url : null;
      _backgroundContentId = contentId?.isNotEmpty == true ? contentId : null;
    });
  }

  String? get backgroundContentId => _backgroundContentId;

  void setPenOptions(Color color, double width) {
    setState(() {
      _penColor = color;
      _penWidth = width;
      _isDrawingMode = true;
    });
  }

  List<Map<String, dynamic>> getCanvasElements() {
    return _elements
        .map(
          (e) => {
            'elementType': e['elementType'],
            'contentId': e['contentId'],
            'mediaId': e['mediaId'],
            'drawingData': e['drawingData'],
            'date': e['date'],
            'text': e['text'],
            'position': e['position'],
            'scale': e['scale'],
            'rotation': e['rotation'],
          },
        )
        .toList();
  }

  void _deleteElement(String id) {
    setState(() {
      final index = _elements.indexWhere((e) => e['elementId'] == id);
      if (index == -1) return;
      final target = _elements[index];
      if (target['elementType'] == 'VIDEO') _videoControllers[id]?.pause();
      if (target['elementType'] == 'AUDIO') _audioPlayers[id]?.pause();
      _elements.removeAt(index);
      _selectedElementId = null;
    });
  }

  SvgResult _convertToSvgPath(List<Offset> points) {
    final minX = points.map((p) => p.dx).reduce(min);
    final maxX = points.map((p) => p.dx).reduce(max);
    final minY = points.map((p) => p.dy).reduce(min);
    final maxY = points.map((p) => p.dy).reduce(max);

    final width = maxX - minX;
    final height = maxY - minY;

    final buffer = StringBuffer();
    buffer.write(
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 $width $height"><path d="',
    );

    for (int i = 0; i < points.length; i++) {
      final x = points[i].dx - minX;
      final y = points[i].dy - minY;
      buffer.write(i == 0 ? 'M $x $y ' : 'L $x $y ');
    }

    final colorHex = _penColor.value
        .toRadixString(16)
        .padLeft(8, '0')
        .substring(2);
    buffer.write(
      '" stroke="#$colorHex" stroke-width="$_penWidth" fill="none"/></svg>',
    );

    return SvgResult(buffer.toString(), Offset(minX, minY));
  }

  Widget _buildDrawingLayer() {
    return GestureDetector(
      onPanUpdate: (details) {
        if (!_isDrawingMode || widget.readOnly) return;
        final RenderBox box = context.findRenderObject() as RenderBox;
        final point = box.globalToLocal(details.globalPosition);
        setState(() => _points.add(point));
      },
      onPanEnd: (_) {
        if (_points.length < 2 || widget.readOnly) return;
        final result = _convertToSvgPath(_points);
        final svg = result.svg;
        final position = result.position;
        final newId = UniqueKey().toString();

        setState(() {
          _elements.add({
            'elementId': newId,
            'elementType': 'DRAWING',
            'drawingData': svg,
            'position': [position.dx, position.dy],
            'scale': 1.0,
            'rotation': 0.0,
          });
          _selectedElementId = newId;
          _isDrawingMode = false;
          _points.clear();
        });
      },
      child: CustomPaint(
        painter: _DrawingPainter(_points, _penColor, _penWidth),
        size: Size.infinite,
      ),
    );
  }

  Widget _buildElement(Map<String, dynamic> e) {
    final id = e['elementId'];
    final type = e['elementType'];
    final pos = List<double>.from(e['position']);
    final scale = (e['scale'] ?? 1.0).toDouble();
    final rotation = (e['rotation'] ?? 0.0).toDouble();
    final mediaUrl = e['mediaId'] ?? e['content']?['mediaId'] ?? e['contentId'];
    final drawingData = e['drawingData'];
    final date = e['date'];
    final isSelected = _selectedElementId == id;

    Widget content;
    switch (type) {
      case 'TEXT':
        final text = e['text'] ?? e['content']?['text'] ?? e['contentId'];
        content = Text(text ?? '내용 없음', style: const TextStyle(fontSize: 16));
        break;
      case 'IMAGE':
      case 'STICKER':
        content = Image.network(mediaUrl ?? '', width: 100, height: 100);
        break;
      case 'VIDEO':
        final controller = _videoControllers[id];
        content =
            controller != null && controller.value.isInitialized
                ? GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedElementId = id;
                      controller.value.isPlaying
                          ? controller.pause()
                          : controller.play();
                    });
                  },
                  child: SizedBox(
                    width: 240,
                    child: AspectRatio(
                      aspectRatio: controller.value.aspectRatio,
                      child: VideoPlayer(controller),
                    ),
                  ),
                )
                : const SizedBox(
                  width: 240,
                  height: 135,
                  child: Center(child: CircularProgressIndicator()),
                );
        break;
      case 'AUDIO':
        final player = _audioPlayers[id];
        final playing = player?.playing ?? false;
        content = GestureDetector(
          onTap: () {
            setState(() {
              _selectedElementId = id;
              playing ? player?.pause() : player?.play();
            });
          },
          child: Icon(
            playing ? Icons.pause_circle : Icons.play_circle,
            size: 40,
          ),
        );
        break;
      case 'DRAWING':
        content =
            drawingData != null
                ? SvgPicture.string(drawingData)
                : const Text('No drawing');
        break;
      case 'DATE':
        content = Text(
          date ?? '',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        );
        break;
      default:
        content = const SizedBox();
    }

    return Positioned(
      left: pos[0],
      top: pos[1],
      child: GestureDetector(
        onTap: () {
          if (!widget.readOnly) {
            setState(() => _selectedElementId = id);
          }
        },
        onScaleStart: (details) {
          if (widget.readOnly) return;
          _initialFocalPoint = details.focalPoint;
          _initialScale = e['scale'];
          _initialRotation = e['rotation'];
        },
        onScaleUpdate: (details) {
          if (widget.readOnly) return;
          setState(() {
            e['position'][0] += details.focalPointDelta.dx;
            e['position'][1] += details.focalPointDelta.dy;
            e['scale'] = _initialScale * details.scale;
            e['rotation'] = _initialRotation + details.rotation * 180 / pi;
          });
        },
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              decoration:
                  isSelected
                      ? BoxDecoration(
                        border: Border.all(color: Colors.deepPurple, width: 2),
                        borderRadius: BorderRadius.circular(4),
                      )
                      : null,
              child: Transform.rotate(
                angle: rotation * pi / 180,
                child: Transform.scale(scale: scale, child: content),
              ),
            ),
            if (!widget.readOnly && isSelected)
              Positioned(
                right: -10,
                top: -10,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _deleteElement(id),
                    customBorder: const CircleBorder(),
                    child: Container(
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.red,
                      ),
                      padding: const EdgeInsets.all(6),
                      child: const Icon(
                        Icons.close,
                        size: 18,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => setState(() => _selectedElementId = null),
      child: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: () => setState(() => _selectedElementId = null),
              child: Container(color: Colors.transparent),
            ),
          ),
          if (_backgroundUrl != null)
            Positioned.fill(
              child: IgnorePointer(
                child: Image.network(_backgroundUrl!, fit: BoxFit.cover),
              ),
            ),
          ..._elements.map(_buildElement),
          if (_isDrawingMode) _buildDrawingLayer(),
        ],
      ),
    );
  }
}

class _DrawingPainter extends CustomPainter {
  final List<Offset> points;
  final Color color;
  final double width;

  _DrawingPainter(this.points, this.color, this.width);

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = color
          ..strokeWidth = width
          ..strokeCap = StrokeCap.round;
    for (int i = 0; i < points.length - 1; i++) {
      canvas.drawLine(points[i], points[i + 1], paint);
    }
  }

  @override
  bool shouldRepaint(_DrawingPainter oldDelegate) => true;
}
