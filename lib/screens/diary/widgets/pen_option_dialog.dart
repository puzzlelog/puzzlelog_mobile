import 'package:flutter/material.dart';

class PenOptionDialog extends StatefulWidget {
  final Color initialColor;
  final double initialWidth;
  final void Function(Color color, double width) onConfirm;

  const PenOptionDialog({
    super.key,
    required this.initialColor,
    required this.initialWidth,
    required this.onConfirm,
  });

  @override
  State<PenOptionDialog> createState() => _PenOptionDialogState();
}

class _PenOptionDialogState extends State<PenOptionDialog> {
  late Color selectedColor;
  late double selectedWidth;

  @override
  void initState() {
    super.initState();
    selectedColor = widget.initialColor;
    selectedWidth = widget.initialWidth;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('펜 설정 및 사용'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('색상 선택'),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children:
                [
                  Colors.black,
                  Colors.red,
                  Colors.green,
                  Colors.blue,
                  Colors.orange,
                ].map((color) {
                  return GestureDetector(
                    onTap: () => setState(() => selectedColor = color),
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: color,
                        border: Border.all(
                          color:
                              selectedColor == color
                                  ? Colors.white
                                  : Colors.transparent,
                          width: 2,
                        ),
                        shape: BoxShape.circle,
                      ),
                    ),
                  );
                }).toList(),
          ),
          const SizedBox(height: 20),
          const Text('굵기 설정'),
          Slider(
            value: selectedWidth,
            min: 1.0,
            max: 15.0,
            divisions: 14,
            label: '${selectedWidth.toStringAsFixed(1)}px',
            onChanged: (val) => setState(() => selectedWidth = val),
          ),
          const SizedBox(height: 12),
          const Text(
            '🎨 적용 시 바로 펜 모드가 시작됩니다',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('취소'),
        ),
        ElevatedButton.icon(
          onPressed: () {
            widget.onConfirm(selectedColor, selectedWidth);
            Navigator.pop(context); // 적용 후 닫기
          },
          icon: const Icon(Icons.brush),
          label: const Text('적용 & 시작'),
        ),
      ],
    );
  }
}
