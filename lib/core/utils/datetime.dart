import 'package:intl/intl.dart';

class DT {
  static String formatSlotTime(DateTime dt) =>
      DateFormat('hh:mm a').format(dt);

  static String formatDate(DateTime dt) =>
      DateFormat('dd MMM yyyy').format(dt);
}
