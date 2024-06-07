import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' as services;
import 'package:google_mlkit_commons/google_mlkit_commons.dart';

/// Un detector de fețe care detectează fețele într-o imagine dată [InputImage].
class FaceDetector {
  static const services.MethodChannel _channel =
      services.MethodChannel('google_mlkit_face_detector');

  // Opțiunile pentru detectorul de fețe.
  final FaceDetectorOptions options;

  // ID-ul instanței.
  final id = DateTime.now().microsecondsSinceEpoch.toString();

  // Constructor pentru a crea o instanță de [FaceDetector].
  FaceDetector({required this.options});

  // Procesează imaginea dată pentru detectarea fețelor.
  Future<List<Face>> processImage(InputImage inputImage) async {
    final result = await _channel.invokeListMethod<dynamic>(
        'vision#startFaceDetector', <String, dynamic>{
      'options': options.toJson(),
      'id': id,
      'imageData': inputImage.toJson(),
    });

    final List<Face> faces = <Face>[];
    for (final dynamic json in result!) {
      faces.add(Face.fromJson(json));
    }

    return faces;
  }

  // Închide detectorul și eliberează resursele acestuia.
  Future<void> close() =>
      _channel.invokeMethod<void>('vision#closeFaceDetector', {'id': id});
}

/// Opțiuni imutabile pentru configurarea caracteristicilor [FaceDetector].
///
/// Utilizate pentru a configura caracteristici cum ar fi clasificarea, urmărirea fețelor, viteza, etc.
class FaceDetectorOptions {
  /// Constructor pentru [FaceDetectorOptions].
  ///
  /// Parametrul [minFaceSize] trebuie să fie între 0.0 și 1.0, inclusiv.
  FaceDetectorOptions({
    this.enableClassification = false,
    this.enableLandmarks = false,
    this.enableContours = false,
    this.enableTracking = false,
    this.minFaceSize = 0.1,
    this.performanceMode = FaceDetectorMode.fast,
  })  : assert(minFaceSize >= 0.0),
        assert(minFaceSize <= 1.0);

  /// Dacă să ruleze clasificatori suplimentari pentru caracterizarea atributelor.
  ///
  /// De exemplu, "zâmbet" și "ochi deschiși".
  final bool enableClassification;

  /// Dacă să detecteze [FaceLandmark]-uri.
  final bool enableLandmarks;

  /// Dacă să detecteze [FaceContour]-uri.
  final bool enableContours;

  /// Dacă să permită urmărirea fețelor.
  ///
  /// Dacă este activat, detectorul va menține un ID consistent pentru fiecare față atunci când procesează cadre consecutive.
  final bool enableTracking;

  /// Cea mai mică dimensiune dorită a feței.
  ///
  /// Exprimată ca o proporție din lățimea capului față de lățimea imaginii.
  ///
  /// Trebuie să fie o valoare între 0.0 și 1.0.
  final double minFaceSize;

  /// Opțiune pentru controlul compromisurilor suplimentare de precizie / viteză.
  final FaceDetectorMode performanceMode;

  /// Returnează o reprezentare json a unei instanțe de [FaceDetectorOptions].
  Map<String, dynamic> toJson() => {
        'enableClassification': enableClassification,
        'enableLandmarks': enableLandmarks,
        'enableContours': enableContours,
        'enableTracking': enableTracking,
        'minFaceSize': minFaceSize,
        'mode': performanceMode.name,
      };
}

/// O față umană detectată într-o imagine.
class Face {
  /// Dreptunghiul axei aliniate al feței detectate.
  ///
  /// Punctul (0, 0) este definit ca colțul din stânga sus al imaginii.
  final Rect boundingBox;

  /// Rotirea feței în jurul axei orizontale a imaginii.
  ///
  /// Reprezentată în grade.
  ///
  /// O față cu un unghi Euler X pozitiv este întoarsă în sus și în jos față de cameră.
  final double? headEulerAngleX;

  /// Rotirea feței în jurul axei verticale a imaginii.
  ///
  /// Reprezentată în grade.
  ///
  /// O față cu un unghi Euler Y pozitiv este întoarsă spre dreapta și spre stânga camerei.
  ///
  /// Unghiul Euler Y este garantat doar atunci când se utilizează setarea "precis" a detectorului de fețe (spre deosebire de setarea "rapidă", care face unele scurtături pentru a face detectarea mai rapidă).
  final double? headEulerAngleY;

  /// Rotirea feței în jurul axei care iese din imagine.
  ///
  /// Reprezentată în grade.
  ///
  /// O față cu un unghi Euler Z pozitiv este rotită în sens invers acelor de ceasornic față de cameră.
  ///
  /// ML Kit raportează întotdeauna unghiul Euler Z al unei fețe detectate.
  final double? headEulerAngleZ;

  /// Probabilitatea ca ochiul stâng al feței să fie deschis.
  ///
  /// O valoare între 0.0 și 1.0 inclusiv, sau null dacă probabilitatea nu a fost calculată.
  final double? leftEyeOpenProbability;

  /// Probabilitatea ca ochiul drept al feței să fie deschis.
  ///
  /// O valoare între 0.0 și 1.0 inclusiv, sau null dacă probabilitatea nu a fost calculată.
  final double? rightEyeOpenProbability;

  /// Probabilitatea ca fața să zâmbească.
  ///
  /// O valoare între 0.0 și 1.0 inclusiv, sau null dacă probabilitatea nu a fost calculată.
  final double? smilingProbability;

  /// ID-ul de urmărire dacă urmărirea este activată.
  ///
  /// Null dacă urmărirea nu a fost activată.
  final int? trackingId;

  /// Obține reperul bazat pe tipul [FaceLandmarkType] furnizat.
  ///
  /// Null dacă reperul nu a fost detectat.
  final Map<FaceLandmarkType, FaceLandmark?> landmarks;

  /// Obține conturul bazat pe tipul [FaceContourType] furnizat.
  ///
  /// Null dacă conturul nu a fost detectat.
  final Map<FaceContourType, FaceContour?> contours;

  Face({
    required this.boundingBox,
    required this.landmarks,
    required this.contours,
    this.headEulerAngleX,
    this.headEulerAngleY,
    this.headEulerAngleZ,
    this.leftEyeOpenProbability,
    this.rightEyeOpenProbability,
    this.smilingProbability,
    this.trackingId,
  });

  /// Returnează o instanță de [Face] dintr-un [json] dat.
  factory Face.fromJson(Map<dynamic, dynamic> json) => Face(
        boundingBox: RectJson.fromJson(json['rect']),
        headEulerAngleX: json['headEulerAngleX'],
        headEulerAngleY: json['headEulerAngleY'],
        headEulerAngleZ: json['headEulerAngleZ'],
        leftEyeOpenProbability: json['leftEyeOpenProbability'],
        rightEyeOpenProbability: json['rightEyeOpenProbability'],
        smilingProbability: json['smilingProbability'],
        trackingId: json['trackingId'],
        landmarks: Map<FaceLandmarkType, FaceLandmark?>.fromIterables(
            FaceLandmarkType.values,
            FaceLandmarkType.values.map((FaceLandmarkType type) {
          final List<dynamic>? pos = json['landmarks'][type.name];
          return (pos == null)
              ? null
              : FaceLandmark(
                  type: type,
                  position: Point<int>(pos[0].toInt(), pos[1].toInt()),
                );
        })),
        contours: Map<FaceContourType, FaceContour?>.fromIterables(
            FaceContourType.values,
            FaceContourType.values.map((FaceContourType type) {
          /// adăugat mapă goală pentru a trece testele
          final List<dynamic>? arr =
              (json['contours'] ?? <String, dynamic>{})[type.name];
          return (arr == null)
              ? null
              : FaceContour(
                  type: type,
                  points: arr
                      .map<Point<int>>((dynamic pos) =>
                          Point<int>(pos[0].toInt(), pos[1].toInt()))
                      .toList(),
                );
        })),
      );
}

/// Un reper pe o față umană detectată într-o imagine.
///
/// Un reper este un punct pe o față detectată, cum ar fi un ochi, nas sau gură.
class FaceLandmark {
  /// Tipul [FaceLandmarkType] al acestui reper.
  final FaceLandmarkType type;

  /// Obține un punct 2D pentru poziția reperului.
  ///
  /// Punctul (0, 0) este definit ca colțul din stânga sus al imaginii.
  final Point<int> position;

  FaceLandmark({required this.type, required this.position});
}

/// Un contur pe o față umană detectată într-o imagine.
///
/// Contururi ale trăsăturilor faciale.
class FaceContour {
  /// Tipul [FaceContourType] al acestui contur.
  final FaceContourType type;

  /// Obține o listă de puncte 2D pentru pozițiile conturului.
  ///
  /// Punctul (0, 0) este definit ca colțul din stânga sus al imaginii.
  final List<Point<int>> points;

  FaceContour({required this.type, required this.points});
}

/// Opțiune pentru controlul compromisurilor suplimentare în realizarea detectării fețelor.
///
/// Modul precis tinde să detecteze mai multe fețe și poate fi mai precis în determinarea valorilor cum ar fi poziția, în detrimentul vitezei.
enum FaceDetectorMode {
  accurate,
  fast,
}

/// Repere disponibile ale fețelor detectate de [FaceDetector].
enum FaceLandmarkType {
  bottomMouth,
  rightMouth,
  leftMouth,
  rightEye,
  leftEye,
  rightEar,
  leftEar,
  rightCheek,
  leftCheek,
  noseBase,
}

/// Tipuri de contururi disponibile ale fețelor detectate de [FaceDetector].
enum FaceContourType {
  face,
  leftEyebrowTop,
  leftEyebrowBottom,
  rightEyebrowTop,
  rightEyebrowBottom,
  leftEye,
  rightEye,
  upperLipTop,
  upperLipBottom,
  lowerLipTop,
  lowerLipBottom,
  noseBridge,
  noseBottom,
  leftCheek,
  rightCheek
}
