import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_ecommerce/controllers/auth/auth_cubit.dart';
import 'package:flutter_ecommerce/controllers/cart/cart_cubit.dart';
import 'package:flutter_ecommerce/controllers/checkout/checkout_cubit.dart';
import 'package:flutter_ecommerce/models/checkout/delivery_method.dart';
import 'package:flutter_ecommerce/models/order/order_item_model.dart';
import 'package:flutter_ecommerce/models/order/order_model.dart';
import 'package:flutter_ecommerce/models/checkout/shipping_address.dart';
import 'package:flutter_ecommerce/models/checkout/payment_method.dart';
import 'package:flutter_ecommerce/services/order_services.dart';
import 'package:flutter_ecommerce/utilities/routes.dart';
import 'package:flutter_ecommerce/views/widgets/checkout/checkout_order_details.dart';
import 'package:flutter_ecommerce/views/widgets/checkout/delivery_method_item.dart';
import 'package:flutter_ecommerce/views/widgets/checkout/payment_component.dart';
import 'package:flutter_ecommerce/views/widgets/checkout/shipping_address_component.dart';
import 'package:flutter_ecommerce/views/widgets/main_button.dart';

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final OrderServices _orderServices = OrderServicesImpl();

  @override
  void initState() {
    super.initState();
    final checkoutCubit = BlocProvider.of<CheckoutCubit>(context, listen: false);
    if (checkoutCubit.state is! CheckoutLoaded) {
      checkoutCubit.getCheckoutData();
    }
  }

  Widget _buildDeliveryMethodsComponent(
      List<DeliveryMethod> deliveryMethods, Size screenSize, CheckoutCubit checkoutCubit) {
    if (deliveryMethods.isEmpty) {
      return const Center(
        child: Text('No delivery methods available!'),
      );
    }

    return SizedBox(
      height: screenSize.height * 0.13,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: deliveryMethods.length,
        itemBuilder: (context, index) {
          final method = deliveryMethods[index];
          bool isSelected = false;
          final currentCheckoutState = checkoutCubit.state;
          if (currentCheckoutState is CheckoutLoaded) {
            isSelected = currentCheckoutState.selectedDeliveryMethod?.id == method.id;
          }
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: DeliveryMethodItem(
              deliveryMethod: method,
              isSelected: isSelected,
              onTap: () {
                checkoutCubit.selectDeliveryMethod(method);
              },
            ),
          );
        },
      ),
    );
  }

  // Builds the user interface for the checkout page.
  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final checkoutCubit = context.read<CheckoutCubit>();

    return BlocListener<CartCubit, CartState>(
      listener: (context, cartListenState) {
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'Checkout',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          centerTitle: true,
        ),
        body: BlocBuilder<CheckoutCubit, CheckoutState>(
          buildWhen: (previous, current) =>
              current is CheckoutLoading ||
              current is CheckoutLoaded ||
              current is CheckoutLoadingFailed,
          builder: (context, checkoutState) {
            if (checkoutState is CheckoutLoading) {
              return const Center(child: CircularProgressIndicator.adaptive());
            } else if (checkoutState is CheckoutLoadingFailed) {
              return Center(child: Text(checkoutState.error));
            } else if (checkoutState is CheckoutLoaded) {
              final shippingAddress = checkoutState.shippingAddress;
              final deliveryMethods = checkoutState.deliveryMethods;
              final bool isShippingAddressEmpty = shippingAddress?.isEmpty ?? true;

              final PaymentMethod? selectedPaymentMethod = checkoutState.selectedPaymentMethod;
              final bool isPaymentMethodEmpty = selectedPaymentMethod == null || selectedPaymentMethod.isEmpty;

              return Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16.0, vertical: 32.0),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Shipping address',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8.0),
                      if (isShippingAddressEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                'No Shipping Addresses!',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Colors.grey.shade600
                                ),
                              ),
                              InkWell(
                                onTap: () {
                                  Navigator.of(context).pushNamed(
                                    AppRoutes.shippingAddressesRoute,
                                    arguments: checkoutCubit,
                                  );
                                },
                                child: Text(
                                  'Add new one',
                                  style: Theme.of(context).textTheme.labelSmall!.copyWith(
                                        color: Colors.redAccent,
                                      ),
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        ShippingAddressComponent(
                          shippingAddress: shippingAddress!,
                          checkoutCubit: checkoutCubit,
                        ),
                      const SizedBox(height: 24.0),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Payment method',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          InkWell(
                            onTap: () async {
                              final result = await Navigator.of(context)
                                  .pushNamed(AppRoutes.paymentMethodsRoute);
                              if (result == true) {
                                final currentCheckoutState = context.read<CheckoutCubit>().state;
                                if (currentCheckoutState is CheckoutLoaded) {
                                }
                              }
                            },
                            child: Text(
                              isPaymentMethodEmpty ? '' : 'Change',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall!
                                  .copyWith(
                                    color: Colors.redAccent,
                                  ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8.0),
                      if (isPaymentMethodEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 16.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                'No Payment Method Added!',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Colors.grey.shade600
                                ),
                              ),
                              InkWell(
                                onTap: () {
                                  Navigator.of(context)
                                      .pushNamed(AppRoutes.paymentMethodsRoute);
                                },
                                child: Text(
                                  'Add new one',
                                  style: Theme.of(context).textTheme.labelSmall!.copyWith(
                                        color: Colors.redAccent,
                                      ),
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        const PaymentComponent(),
                      const SizedBox(height: 24.0),
                      Text(
                        'Delivery method',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8.0),
                      _buildDeliveryMethodsComponent(deliveryMethods, screenSize, checkoutCubit),
                      const SizedBox(height: 32.0),
                      const CheckoutOrderDetails(),
                      const SizedBox(height: 64.0),
                      BlocConsumer<CheckoutCubit, CheckoutState>(
                        listenWhen: (previous, current) =>
                            current is PaymentMakingFailed ||
                            current is PaymentMade,
                        listener: (context, paymentListenState) {
                          if (paymentListenState is PaymentMakingFailed) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(paymentListenState.error),
                                backgroundColor: Colors.red,
                              ),
                            );
                          } else if (paymentListenState is PaymentMade) {
                            final currentCartState = context.read<CartCubit>().state;
                            final currentAuth = context.read<AuthCubit>().state;

                            if (currentCartState is CartLoaded &&
                                checkoutState is CheckoutLoaded &&
                                currentAuth is AuthSuccess) {
                              if (currentCartState.cartProducts.isNotEmpty) {
                                final userId = currentAuth.user.uid;
                                final shippingInfo = checkoutState.shippingAddress;
                                final deliveryInfo = checkoutState.selectedDeliveryMethod;
                                final paymentInfo = checkoutState.selectedPaymentMethod;

                                if (shippingInfo != null && !shippingInfo.isEmpty &&
                                    deliveryInfo != null &&
                                    paymentInfo != null && !paymentInfo.isEmpty) {
                                  final orderItems = currentCartState
                                      .cartProducts
                                      .map((cartItem) => OrderItemModel(
                                            productId: cartItem.productId,
                                            title: cartItem.title,
                                            price: cartItem.price,
                                            quantity: cartItem.quantity,
                                            imgUrl: cartItem.imgUrl,
                                            color: cartItem.color,
                                            size: cartItem.size,
                                            brand: cartItem.brand,
                                            category: cartItem.category,
                                          ))
                                      .toList();

                                  final finalTotalAmount = currentCartState.totalAmount + deliveryInfo.price.toDouble();
                                  final shippingAddressFormatted = "${shippingInfo.fullName}, ${shippingInfo.address}, ${shippingInfo.city}, ${shippingInfo.country}";
                                  final paymentMethodFormatted = paymentInfo.cardNumber.isNotEmpty
                                      ? "Card **** ${paymentInfo.cardNumber.substring(paymentInfo.cardNumber.length - 4)}"
                                      : "Not specified";

                                  final newOrder = OrderModel(
                                    id: '',
                                    userId: userId,
                                    items: orderItems,
                                    totalAmount: finalTotalAmount,
                                    deliveryFee: deliveryInfo.price.toDouble(),
                                    shippingAddress: shippingAddressFormatted,
                                    paymentMethodDetails: paymentMethodFormatted,
                                    createdAt: Timestamp.now(),
                                    trackingNumber: 'N/A',
                                    deliveryMethodInfo: "${deliveryInfo.name}, ${deliveryInfo.days}",
                                    discountInfo: null,
                                  );

                                  _orderServices.createOrder(newOrder).then((_) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Order Placed Successfully!'),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                    context.read<CartCubit>().clearCart();
                                    Navigator.of(context).pushNamedAndRemoveUntil(
                                      AppRoutes.orderSuccessRoute,
                                      (route) => route.isFirst);
                                  }).catchError((error) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Failed to save order: $error')),
                                    );
                                  });
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Please select address, delivery, and payment method.')),
                                  );
                                }
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Order Placed (Cart was empty).'),
                                        backgroundColor: Colors.orange,
                                      ),
                                    );
                                context.read<CartCubit>().clearCart();
                                Navigator.of(context).pushNamedAndRemoveUntil(
                                    AppRoutes.orderSuccessRoute,
                                    (route) => route.isFirst);
                              }
                            } else {
                               ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Cannot process order: User not logged in or data missing.')),
                              );
                            }
                          }
                        },
                        buildWhen: (previous, current) =>
                            current is PaymentMade ||
                            current is PaymentMakingFailed ||
                            current is MakingPayment,
                        builder: (context, submitButtonState) {
                          if (submitButtonState is MakingPayment) {
                            return MainButton(
                              hasCircularBorder: true,
                              child: const Center(child: CircularProgressIndicator.adaptive(backgroundColor: Colors.white)),
                            );
                          }
                          return MainButton(
                            text: 'Submit Order',
                            onTap: () async {
                              final cartStateForSubmit = context.read<CartCubit>().state;

                              if (checkoutState is CheckoutLoaded) {
                                if (isShippingAddressEmpty) {
                                   ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Please select a shipping address.')),
                                  );
                                  return;
                                }
                                 if (checkoutState.selectedDeliveryMethod == null) {
                                   ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Please select a delivery method.')),
                                  );
                                  return;
                                }
                                 if (isPaymentMethodEmpty) {
                                   ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Please select a payment method.')),
                                  );
                                  return;
                                }
                              } else {
                                 ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Checkout data not loaded.')),
                                  );
                                  return;
                              }

                              if (cartStateForSubmit is CartLoaded && checkoutState is CheckoutLoaded) {
                                double totalAmount = cartStateForSubmit.totalAmount;
                                double deliveryFee = checkoutState.selectedDeliveryMethod!.price.toDouble();
                                final summaryAmount = totalAmount + deliveryFee;

                                 if (cartStateForSubmit.cartProducts.isEmpty) {
                                   ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Your cart is empty.')),
                                    );
                                    return;
                                }

                                if (summaryAmount <= 0 ) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Cannot checkout with zero or negative amount.')),
                                    );
                                    return;
                                }
                                await checkoutCubit.makePayment(summaryAmount);
                              } else {
                                 ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Cart or Checkout data not properly loaded.')),
                                  );
                              }
                            },
                            hasCircularBorder: true,
                          );
                        },
                      ),
                    ],
                  ),
                ),
              );
            } else {
              return const SizedBox.shrink();
            }
          },
        ),
      ),
    );
  }
}