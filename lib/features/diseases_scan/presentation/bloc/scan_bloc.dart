import 'package:flutter_bloc/flutter_bloc.dart';

abstract class ScanEvent {}
class StartScan extends ScanEvent {}

abstract class ScanState {}
class ScanInitial extends ScanState {}
class ScanLoading extends ScanState {}
class ScanSuccess extends ScanState {
  final String result;
  ScanSuccess(this.result);
}

class ScanBloc extends Bloc<ScanEvent, ScanState> {
  ScanBloc() : super(ScanInitial()) {
    on<StartScan>((event, emit) async {
      emit(ScanLoading());
      // Logic to run tflite_flutter inference goes here[cite: 1]
      await Future.delayed(const Duration(seconds: 2)); 
      emit(ScanSuccess("Rice Bacterial Blight - 98% Confidence"));
    });
  }
}