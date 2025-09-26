import '../../data/model/CompletedGroupModel.dart';

abstract class BulkState {}

class BulkInitial extends BulkState {}

class BulkLoading extends BulkState {}

class BulkLoaded extends BulkState {
  final List<BulkFolder> bulks;

  BulkLoaded(this.bulks);
}

class BulkError extends BulkState {
  final String message;

  BulkError(this.message);
}

class BulkOperationSuccess extends BulkState {
  final String message;

  BulkOperationSuccess(this.message);
}
