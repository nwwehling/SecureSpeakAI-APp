import 'dart:math';
import 'dart:io';

class Complex {
  final double re;
  final double im;

  Complex(this.re, this.im);

  Complex operator +(Complex other) {
    return Complex(re + other.re, im + other.im);
  }

  Complex operator -(Complex other) {
    return Complex(re - other.re, im - other.im);
  }

  Complex operator *(Complex other) {
    return Complex(re * other.re - im * other.im, re * other.im + im * other.re);
  }

  Complex operator /(double scalar) {
    return Complex(re / scalar, im / scalar);
  }

  double abs() {
    return sqrt(re * re + im * im);
  }

  Complex pow(int exponent) {
    double r = abs();
    double theta = atan2(im, re);
    double newRe = r * cos(exponent * theta);
    double newIm = r * sin(exponent * theta);
    return Complex(newRe, newIm);
  }

  Complex exp() {
    return Complex(cos(im), sin(im));
  }
}

double log10(num x) {
  return log(x) / ln10;
}

Future<List<List<double>>> extractMFCC(String audioPath) async {
  final audioFile = File(audioPath);
  final audioBytes = await audioFile.readAsBytes();

  List<double> audioData = audioBytes.buffer.asInt16List().map((e) => e.toDouble()).toList();

  int sampleRate = 16000;
  int frameSize = 1024;
  int frameStep = 256;
  int numCoefficients = 13;
  int maxSequenceLength = 1071;

  List<double> emphasizedSignal = List<double>.generate(audioData.length, (i) {
    return i == 0 ? audioData[i] : audioData[i] - 0.97 * audioData[i - 1];
  });

  List<List<double>> frames = [];
  for (int i = 0; i + frameSize < emphasizedSignal.length; i += frameStep) {
    frames.add(emphasizedSignal.sublist(i, i + frameSize));
  }

  print('Number of frames: ${frames.length}');

  List<List<double>> windowedFrames = frames.map((frame) {
    List<double> window = List<double>.generate(frameSize, (i) => 0.54 - 0.46 * cos(2 * pi * i / (frameSize - 1)));
    return List<double>.generate(frameSize, (i) => frame[i] * window[i]);
  }).toList();

  List<List<double>> powerSpectrum = windowedFrames.map((frame) {
    var fftFrame = _fft(frame);
    return fftFrame.map((c) => c.abs() * c.abs()).toList();
  }).toList();

  int numFilters = 26;
  List<List<double>> filterBank = getMelFilterBank(sampleRate, frameSize, numFilters);

  List<List<double>> filterBankEnergies = powerSpectrum.map((spectrum) {
    return filterBank.map((filter) {
      double energy = 0.0;
      for (int i = 0; i < filter.length; i++) {
        energy += spectrum[i] * filter[i];
      }
      return energy;
    }).toList();
  }).toList();

  List<List<double>> logEnergies = filterBankEnergies.map((energies) {
    return energies.map((energy) => log(energy + 1e-10)).toList();
  }).toList();

  List<List<double>> mfcc = logEnergies.map((energies) {
    var dctFrame = _dct(energies);
    return dctFrame.sublist(0, numCoefficients);
  }).toList();

  print('MFCC before padding: ${mfcc.length} frames');

  if (mfcc.length > maxSequenceLength) {
    mfcc = mfcc.sublist(0, maxSequenceLength);
  } else if (mfcc.length < maxSequenceLength) {
    int missingFrames = maxSequenceLength - mfcc.length;
    List<double> zeroFrame = List<double>.filled(numCoefficients, 0.0);
    mfcc.addAll(List.generate(missingFrames, (_) => zeroFrame));
  }

  print('MFCC shape: ${mfcc.length} x ${mfcc[0].length}');
  return mfcc;
}

List<Complex> _fft(List<double> input) {
  int n = input.length;
  if (n == 1) return [Complex(input[0], 0)];

  List<Complex> even = _fft(List.generate(n ~/ 2, (i) => input[2 * i]));
  List<Complex> odd = _fft(List.generate(n ~/ 2, (i) => input[2 * i + 1]));

  List<Complex> output = List<Complex>.filled(n, Complex(0, 0));
  for (int k = 0; k < n ~/ 2; k++) {
    Complex t = odd[k] * Complex(cos(2 * pi * k / n), sin(2 * pi * k / n));
    output[k] = even[k] + t;
    output[k + n ~/ 2] = even[k] - t;
  }
  return output;
}

List<double> _dct(List<double> input) {
  int n = input.length;
  List<double> result = List<double>.filled(n, 0.0);

  for (int k = 0; k < n; k++) {
    double sum = 0.0;
    for (int i = 0; i < n; i++) {
      sum += input[i] * cos(pi * k * (i + 0.5) / n);
    }
    result[k] = sum * sqrt(2 / n);
  }
  return result;
}

List<List<double>> getMelFilterBank(int sampleRate, int frameSize, int numFilters) {
  double lowFreq = 0;
  double highFreq = sampleRate / 2;
  double lowMel = 2595 * log10(1 + lowFreq / 700);
  double highMel = 2595 * log10(1 + highFreq / 700);

  List<double> melPoints = List<double>.generate(numFilters + 2, (i) {
    return lowMel + (highMel - lowMel) * i / (numFilters + 1);
  });

  List<double> hzPoints = melPoints.map((mel) {
    return 700 * (pow(10, mel / 2595) - 1).toDouble();
  }).toList();

  List<int> bin = hzPoints.map((hz) {
    return (hz * (frameSize + 1) / sampleRate).floor();
  }).toList();

  List<List<double>> filterBank = List.generate(numFilters, (i) {
    return List<double>.generate(frameSize ~/ 2 + 1, (j) {
      if (j < bin[i]) {
        return 0.0;
      } else if (j <= bin[i + 1]) {
        return (j - bin[i]) / (bin[i + 1] - bin[i]);
      } else if (j <= bin[i + 2]) {
        return (bin[i + 2] - j) / (bin[i + 2] - bin[i + 1]);
      } else {
        return 0.0;
      }
    });
  });

  return filterBank;
}
