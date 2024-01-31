import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:hashtagable/widgets/hashtag_text.dart';

import 'detector/detector.dart';

/// Check if the text has hashTags
bool hasHashTags(String value) {
  final decoratedTextColor = Colors.blue;
  final detector = Detector(
      textStyle: TextStyle(),
      decoratedStyle: TextStyle(color: decoratedTextColor));
  final result = detector.getDetections(value);
  final detections = result
      .where((detection) => detection.style!.color == decoratedTextColor)
      .toList();
  return detections.isNotEmpty;
}

/// Extract hashTags from the text
List<String> extractHashTags(String value) {
  final decoratedTextColor = Colors.blue;
  final detector = Detector(
      textStyle: TextStyle(),
      decoratedStyle: TextStyle(color: decoratedTextColor));
  final detections = detector.getDetections(value);
  final taggedDetections = detections
      .where((detection) => detection.style!.color == decoratedTextColor)
      .toList();
  final result = taggedDetections.map((decoration) {
    final text = decoration.range.textInside(value);
    return text.trim();
  }).toList();
  return result;
}

/// Returns textSpan with decorated tagged text
///
/// Used in [HashTagText]
TextSpan getHashTagTextSpan({
  required TextStyle decoratedStyle,
  required TextStyle basicStyle,
  required String source,
  Function(String)? onTap,
  bool decorateAtSign = false,
}) {
  final decorations = Detector(
          decoratedStyle: decoratedStyle,
          textStyle: basicStyle,
          decorateAtSign: decorateAtSign)
      .getDetections(source);
  if (decorations.isEmpty) {
    return TextSpan(text: source, style: basicStyle);
  } else {
    decorations.sort();
    final span = decorations
        .asMap()
        .map(
          (index, item) {
            final recognizer = TapGestureRecognizer()
              ..onTap = () {
                final decoration = decorations[index];
                if (decoration.style == decoratedStyle) {
                  onTap!(decoration.range.textInside(source).trim());
                }
              };
            return MapEntry(
              index,
              TextSpan(
                style: item.style,
                text: item.range.textInside(source),
                recognizer: (onTap == null) ? null : recognizer,
              ),
            );
          },
        )
        .values
        .toList();

    return TextSpan(children: span);
  }
}

TextSpan getHashtagAndLinks({
  required TextStyle decoratedStyle,
  required TextStyle basicStyle,
  required String source,
  Function(String)? onTap,
  Function(String?)? linkCallback,
  bool decorateAtSign = false,
}) {
  final tagsResult = getHashTagTextSpan(
    basicStyle: basicStyle,
    decoratedStyle: decoratedStyle,
    source: source,
    decorateAtSign: decorateAtSign,
    onTap: onTap,
  );

  final linksResult = replaceLinks(
    tagsResult,
    linkCallback,
  );

  return linksResult;
}

TextSpan replaceLinks(
  TextSpan textSpan,
  Function(String?)? linkCallback,
) {
  // Regular expression to match URLs
  final RegExp regex = RegExp(
      r'http[s]?://(?:[a-zA-Z]|[0-9]|[$-_@.&+]|[!*\\(\\),]|(?:%[0-9a-fA-F][0-9a-fA-F]))+');

  // Recursive function to replace links within TextSpan
  TextSpan processTextSpan(
    TextSpan span,
  ) {
    List<TextSpan> textSpans = [];

    if (span.text != null) {
      List<Match> matches = regex.allMatches(span.text ?? '').toList();
      int currentIndex = 0;

      for (Match match in matches) {
        // Add the non-link text
        if (match.start > currentIndex) {
          textSpans.add(TextSpan(
            text: span.text?.substring(currentIndex, match.start),
            style: span.style,
            recognizer: span.recognizer,
          ));
        }

        // Add the link with a custom style
        textSpans.add(TextSpan(
          text: match.group(0),
          style: span.style,
          recognizer: TapGestureRecognizer()
            ..onTap = () {
              if (linkCallback != null) {
                linkCallback(match.group(0));
              }
            },
        ));

        currentIndex = match.end;
      }

      // Add any remaining non-link text
      if (currentIndex < (span.text?.length ?? 0)) {
        textSpans.add(TextSpan(
          text: span.text?.substring(currentIndex),
          style: span.style,
          recognizer: span.recognizer,
        ));
      }
    }

    // Recursively process children
    if (span.children != null) {
      for (TextSpan childSpan in span.children as List<TextSpan>) {
        textSpans.add(processTextSpan(childSpan));
      }
    }

    return TextSpan(children: textSpans);
  }

  return processTextSpan(textSpan);
}
