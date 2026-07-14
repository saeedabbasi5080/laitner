part of 'excel_library_cubit.dart';

enum ExcelLibraryStatus { initial, loading, loaded, error }

class ExcelLibraryState extends Equatable {
  const ExcelLibraryState({
    this.status = ExcelLibraryStatus.initial,
    this.imports = const [],
    this.errorMessage,
  });

  final ExcelLibraryStatus status;
  final List<ExcelImport> imports;
  final String? errorMessage;

  ExcelLibraryState copyWith({
    ExcelLibraryStatus? status,
    List<ExcelImport>? imports,
    String? errorMessage,
  }) {
    return ExcelLibraryState(
      status: status ?? this.status,
      imports: imports ?? this.imports,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, imports, errorMessage];
}
