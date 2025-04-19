part of 'order_cubit.dart';


@immutable
abstract class OrderState extends Equatable {
  const OrderState();

  @override
  List<Object> get props => [];
}

final class OrderInitial extends OrderState {
  const OrderInitial();
}

final class OrderLoading extends OrderState {
  const OrderLoading();
}

final class OrderLoaded extends OrderState {
  final List<OrderModel> orders;

  const OrderLoaded(this.orders);

  @override
  List<Object> get props => [orders];
}

final class OrderError extends OrderState {
  final String message;

  const OrderError(this.message);

   @override
  List<Object> get props => [message];
}