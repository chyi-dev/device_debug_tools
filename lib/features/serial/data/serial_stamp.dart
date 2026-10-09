String pad2(int value) => value.toString().padLeft(2, '0');

String clockStamp(DateTime time) =>
    '${pad2(time.hour)}:${pad2(time.minute)}:${pad2(time.second)}.${time.millisecond.toString().padLeft(3, '0')}';

String fullStamp(DateTime time) =>
    '${time.year}-${pad2(time.month)}-${pad2(time.day)} ${clockStamp(time)}';

String fileStamp(DateTime time) =>
    fullStamp(time).replaceAll(RegExp(r'[-: .]'), '');
