import 'dart:math';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

import 'coordinates_translator.dart';

class FaceDetectorPainter extends CustomPainter {
  FaceDetectorPainter(
    this.faces,
    this.imageSize,
    this.rotation,
    this.cameraLensDirection,
    this.ids,
    this.names,
    this.roles,
    this.bbox,
  );

  final List<Face> faces;
  final Size imageSize;
  final InputImageRotation rotation;
  final CameraLensDirection cameraLensDirection;
  final List<int> ids;
  final List<String> names;
  final List<String> roles;
  final List<String> bbox;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint1 = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = Colors.transparent;
    final Paint paint2 = Paint()
      ..style = PaintingStyle.fill
      ..strokeWidth = 1.0
      ..color = Colors.transparent;

    // Funcție pentru calcularea distanței dintre două puncte
    double calculateDistance(Point<double> point1, Point<double> point2) {
      return sqrt(pow(point2.x - point1.x, 2) + pow(point2.y - point1.y, 2));
    }

    // Sortează fețele în funcție de distanța dintre ochii lor
    faces.sort((a, b) {
      final aLeftEye = a.landmarks[FaceLandmarkType.leftEye]?.position;
      final aRightEye = a.landmarks[FaceLandmarkType.rightEye]?.position;
      final bLeftEye = b.landmarks[FaceLandmarkType.leftEye]?.position;
      final bRightEye = b.landmarks[FaceLandmarkType.rightEye]?.position;

      if (aLeftEye != null &&
          aRightEye != null &&
          bLeftEye != null &&
          bRightEye != null) {
        final aEyeDistance = calculateDistance(
          Point<double>(aLeftEye.x.toDouble(), aLeftEye.y.toDouble()),
          Point<double>(aRightEye.x.toDouble(), aRightEye.y.toDouble()),
        );
        final bEyeDistance = calculateDistance(
          Point<double>(bLeftEye.x.toDouble(), bLeftEye.y.toDouble()),
          Point<double>(bRightEye.x.toDouble(), bRightEye.y.toDouble()),
        );
        return bEyeDistance.compareTo(aEyeDistance);
      }
      return 0;
    });

    // Funcție pentru a obține dimensiunea textului
    Size getTextSize(String text, TextStyle style) {
      final textPainter = TextPainter(
        text: TextSpan(text: text, style: style),
        textDirection: TextDirection.ltr,
      )..layout();
      return textPainter.size;
    }

    double previousBoxBottom = 0;

    // Parcurge lista de fețe detectate
    for (int i = 0; i < faces.length; i++) {
      final face = faces[i];
      final left = translateX(
        face.boundingBox.left,
        size,
        imageSize,
        rotation,
        cameraLensDirection,
      );
      final top = translateY(
        face.boundingBox.top,
        size,
        imageSize,
        rotation,
        cameraLensDirection,
      );
      final right = translateX(
        face.boundingBox.right,
        size,
        imageSize,
        rotation,
        cameraLensDirection,
      );
      final bottom = translateY(
        face.boundingBox.bottom,
        size,
        imageSize,
        rotation,
        cameraLensDirection,
      );

      if (names.isNotEmpty) {
        final idText = 'ID: ${i + 1}';
        final nameText = 'NAMES:${names[i]}\nROLES:${roles[i]}';

        final idTextStyle = TextStyle(
          color: Colors.red,
          fontSize: 16.0,
          fontWeight: FontWeight.bold,
        );
        final nameTextStyle = TextStyle(
          color: Colors.red,
          fontSize: 16.0,
          fontWeight: FontWeight.bold,
        );

        final idTextSize = getTextSize(idText, idTextStyle);
        final nameTextSize = getTextSize(nameText, nameTextStyle);
        final maxWidth = idTextSize.width > nameTextSize.width
            ? idTextSize.width
            : nameTextSize.width;
        final boxWidth = maxWidth + 20;
        final boxHeight = idTextSize.height + nameTextSize.height + 20;

        double boxTop = bottom + 10;
        if (boxTop < previousBoxBottom) {
          boxTop = previousBoxBottom + 10;
        }
        final centerX = left + (right - left) / 2;
        final whiteBoxRect = Rect.fromLTWH(
          centerX - boxWidth / 2,
          boxTop,
          boxWidth,
          boxHeight,
        );
        canvas.drawRect(
          whiteBoxRect,
          Paint()..color = Colors.transparent,
        );
        final idTextSpan = TextSpan(
          text: idText,
          style: idTextStyle,
        );
        final idTextPainter = TextPainter(
          text: idTextSpan,
          textDirection: TextDirection.ltr,
        );
        idTextPainter.layout();
        idTextPainter.paint(
            canvas, Offset(centerX - idTextSize.width / 2, boxTop + 5));
        final nameTextSpan = TextSpan(
          text: nameText,
          style: nameTextStyle,
        );
        final nameTextPainter = TextPainter(
          text: nameTextSpan,
          textDirection: TextDirection.ltr,
        );
        nameTextPainter.layout();
        nameTextPainter.paint(
            canvas,
            Offset(centerX - nameTextSize.width / 2,
                boxTop + idTextSize.height + 10));
        previousBoxBottom = boxTop + boxHeight + 10;
        canvas.drawRect(
          Rect.fromLTRB(left, top, right, bottom),
          paint1,
        );
        final double startX = centerX;
        final double startY = bottom;
        final double endX = centerX;
        final double endY = boxTop;

        final arrowPaint = Paint()
          ..color = Colors.red
          ..strokeWidth = 2.0
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;

        final path = Path();
        path.moveTo(startX, startY);

        final controlX = startX + (endX - startX) / 2;
        final controlY = startY + (endY - startY) / 2 - 20;
        path.quadraticBezierTo(controlX, controlY, endX, endY);

        canvas.drawPath(path, arrowPaint);

        
        void paintContour(FaceContourType type) {
          final contour = face.contours[type];
          if (contour?.points != null) {
            for (final Point point in contour!.points) {
              canvas.drawCircle(
                Offset(
                  translateX(
                    point.x.toDouble(),
                    size,
                    imageSize,
                    rotation,
                    cameraLensDirection,
                  ),
                  translateY(
                    point.y.toDouble(),
                    size,
                    imageSize,
                    rotation,
                    cameraLensDirection,
                  ),
                ),
                1,
                paint1,
              );
            }
          }
        }

        void paintLandmark(FaceLandmarkType type) {
          final landmark = face.landmarks[type];
          if (landmark?.position != null) {
            canvas.drawCircle(
              Offset(
                translateX(
                  landmark!.position.x.toDouble(),
                  size,
                  imageSize,
                  rotation,
                  cameraLensDirection,
                ),
                translateY(
                  landmark.position.y.toDouble(),
                  size,
                  imageSize,
                  rotation,
                  cameraLensDirection,
                ),
              ),
              2,
              paint2,
            );
          }
        }

        for (final type in FaceContourType.values) {
          paintContour(type);
        }

        for (final type in FaceLandmarkType.values) {
          paintLandmark(type);
        }
      } else {
        final idText = 'ID: ${i + 1}';
        final nameText = 'NAMES:Loading...\nROLES:Loading...';

        final idTextStyle = TextStyle(
          color: Colors.red,
          fontSize: 16.0,
          fontWeight: FontWeight.bold,
        );
        final nameTextStyle = TextStyle(
          color: Colors.red,
          fontSize: 16.0,
          fontWeight: FontWeight.bold,
        );

        final idTextSize = getTextSize(idText, idTextStyle);
        final nameTextSize = getTextSize(nameText, nameTextStyle);
        final maxWidth = idTextSize.width > nameTextSize.width
            ? idTextSize.width
            : nameTextSize.width;
        final boxWidth = maxWidth + 20;
        final boxHeight = idTextSize.height + nameTextSize.height + 20;

        double boxTop = bottom + 10;
        if (boxTop < previousBoxBottom) {
          boxTop = previousBoxBottom + 10;
        }
        final centerX = left + (right - left) / 2;
        final whiteBoxRect = Rect.fromLTWH(
          centerX - boxWidth / 2,
          boxTop,
          boxWidth,
          boxHeight,
        );
        canvas.drawRect(
          whiteBoxRect,
          Paint()..color = Colors.transparent,
        );

        final idTextSpan = TextSpan(
          text: idText,
          style: idTextStyle,
        );
        final idTextPainter = TextPainter(
          text: idTextSpan,
          textDirection: TextDirection.ltr,
        );
        idTextPainter.layout();
        idTextPainter.paint(
            canvas, Offset(centerX - idTextSize.width / 2, boxTop + 5));

        final nameTextSpan = TextSpan(
          text: nameText,
          style: nameTextStyle,
        );
        final nameTextPainter = TextPainter(
          text: nameTextSpan,
          textDirection: TextDirection.ltr,
        );
        nameTextPainter.layout();
        nameTextPainter.paint(
            canvas,
            Offset(centerX - nameTextSize.width / 2,
                boxTop + idTextSize.height + 10));

        previousBoxBottom = boxTop + boxHeight + 10;

        canvas.drawRect(
          Rect.fromLTRB(left, top, right, bottom),
          paint1,
        );

        final double startX = centerX;
        final double startY = bottom;
        final double endX = centerX;
        final double endY = boxTop;

        final arrowPaint = Paint()
          ..color = Colors.red
          ..strokeWidth = 2.0
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;

        final path = Path();
        path.moveTo(startX, startY);

        final controlX = startX + (endX - startX) / 2;
        final controlY = startY + (endY - startY) / 2 - 20;

        path.quadraticBezierTo(controlX, controlY, endX, endY);

        canvas.drawPath(path, arrowPaint);

        void paintContour(FaceContourType type) {
          final contour = face.contours[type];
          if (contour?.points != null) {
            for (final Point point in contour!.points) {
              canvas.drawCircle(
                Offset(
                  translateX(
                    point.x.toDouble(),
                    size,
                    imageSize,
                    rotation,
                    cameraLensDirection,
                  ),
                  translateY(
                    point.y.toDouble(),
                    size,
                    imageSize,
                    rotation,
                    cameraLensDirection,
                  ),
                ),
                1,
                paint1,
              );
            }
          }
        }

        void paintLandmark(FaceLandmarkType type) {
          final landmark = face.landmarks[type];
          if (landmark?.position != null) {
            canvas.drawCircle(
              Offset(
                translateX(
                  landmark!.position.x.toDouble(),
                  size,
                  imageSize,
                  rotation,
                  cameraLensDirection,
                ),
                translateY(
                  landmark.position.y.toDouble(),
                  size,
                  imageSize,
                  rotation,
                  cameraLensDirection,
                ),
              ),
              2,
              paint2,
            );
          }
        }

        for (final type in FaceContourType.values) {
          paintContour(type);
        }

        for (final type in FaceLandmarkType.values) {
          paintLandmark(type);
        }
      }
    }
  }

  @override
  bool shouldRepaint(FaceDetectorPainter oldDelegate) {
    return oldDelegate.imageSize != imageSize || oldDelegate.faces != faces;
  }
}
