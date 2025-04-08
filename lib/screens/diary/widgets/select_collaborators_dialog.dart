import 'package:flutter/material.dart';

class SelectCollaboratorsDialog extends StatefulWidget {
  final List<Map<String, dynamic>> friends;
  final List<String> initiallySelected;

  const SelectCollaboratorsDialog({
    super.key,
    required this.friends,
    required this.initiallySelected,
  });

  @override
  State<SelectCollaboratorsDialog> createState() =>
      _SelectCollaboratorsDialogState();
}

class _SelectCollaboratorsDialogState extends State<SelectCollaboratorsDialog> {
  late List<String> selected;

  @override
  void initState() {
    super.initState();
    selected = List<String>.from(widget.initiallySelected);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("참여자 선택"),
      content: SizedBox(
        width: 300,
        child: ListView(
          shrinkWrap: true,
          children:
              widget.friends.map((f) {
                final uid = f['userId'];
                return CheckboxListTile(
                  value: selected.contains(uid),
                  title: Text(f['nickname'] ?? uid),
                  onChanged: (checked) {
                    setState(() {
                      if (checked == true) {
                        selected.add(uid);
                      } else {
                        selected.remove(uid);
                      }
                    });
                  },
                );
              }).toList(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, selected),
          child: const Text("확인"),
        ),
      ],
    );
  }
}
