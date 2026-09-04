import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class Formatters {
  static final NumberFormat currencyFormatter = NumberFormat("#,##,##0", "en_IN");

  static String formatCurrency(double amount) {
    return '৳${currencyFormatter.format(amount)}';
  }

  static String formatDate(DateTime date) {
    return DateFormat('dd MMM yyyy').format(date);
  }

  /// Parses and highlights numerical amounts inside strings (e.g. "৳1,200")
  static Widget buildHighlightedSubtitle(String text) {
    final RegExp regExp = RegExp(r'([৳\d,]+)');
    final matches = regExp.allMatches(text);

    if (matches.isEmpty) {
      return Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }

    List<InlineSpan> spans = [];
    int lastMatchEnd = 0;

    for (final match in matches) {
      if (match.start > lastMatchEnd) {
        spans.add(TextSpan(
          text: text.substring(lastMatchEnd, match.start),
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.normal,
            color: Colors.black54,
          ),
        ));
      }

      spans.add(TextSpan(
        text: match.group(0),
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w800,
          color: Colors.black87,
        ),
      ));

      lastMatchEnd = match.end;
    }

    if (lastMatchEnd < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastMatchEnd),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.normal,
          color: Colors.black54,
        ),
      ));
    }

    return RichText(
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(children: spans),
    );
  }
}