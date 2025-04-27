import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_ecommerce/controllers/auth/auth_cubit.dart';
import 'package:flutter_ecommerce/controllers/cart/cart_cubit.dart';
import 'package:flutter_ecommerce/controllers/checkout/checkout_cubit.dart';
import 'package:flutter_ecommerce/models/delivery_method.dart';
import 'package:flutter_ecommerce/models/order_item_model.dart';
import 'package:flutter_ecommerce/models/order_model.dart';
import 'package:flutter_ecommerce/models/shipping_address.dart';
import 'package:flutter_ecommerce/services/order_services.dart';
import 'package:flutter_ecommerce/utilities/args_models/add_shipping_address_args.dart';
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
  final String _pageInstanceId = DateTime.now().millisecondsSinceEpoch.toString();

  @override
  void initState() {
    super.initState();
     print('--- CheckoutPage ($_pageInstanceId) initState ---');
    final checkoutCubit = BlocProvider.of<CheckoutCubit>(context, listen: false);
    print('CheckoutPage ($_pageInstanceId) initState: Current state is ${checkoutCubit.state.runtimeType}');
    if (checkoutCubit.state is! CheckoutLoaded) {
          print('CheckoutPage ($_pageInstanceId) initState: State is NOT CheckoutLoaded. Calling getCheckoutData().');
          checkoutCubit.getCheckoutData();
        } else {
          print('CheckoutPage ($_pageInstanceId) initState: State IS CheckoutLoaded. Skipping getCheckoutData().');
        }
  }
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    print('--- CheckoutPage ($_pageInstanceId) didChangeDependencies ---');
    // Kiểm tra xem có logic nào ở đây vô tình gọi getCheckoutData không
  }

  @override
  void dispose() {
    print('--- CheckoutPage ($_pageInstanceId) dispose ---'); // Xem trang có bị dispose không
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    Widget buildShippingAddressComponent(ShippingAddress? shippingAddress) {
       final checkoutCubit = context.read<CheckoutCubit>();
      if (shippingAddress == null) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('No Shipping Addresses!'),
              const SizedBox(height: 6.0),
              InkWell(
                onTap: () async {
                  Navigator.of(context).pushNamed(
                    AppRoutes.shippingAddressesRoute,
                    arguments: context.read<CheckoutCubit>(),
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
        );
      } else {
        return ShippingAddressComponent(
          shippingAddress: shippingAddress,
          checkoutCubit: checkoutCubit,
        );
      }
    }

    Widget buildDeliveryMethodsComponent(List<DeliveryMethod> deliveryMethods) {
      final checkoutCubit = context.read<CheckoutCubit>();
      if (deliveryMethods.isEmpty) {
        return const Center(
          child: Text('No delivery methods available!'),
        );
      }

      return SizedBox(
        height: size.height * 0.13,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: deliveryMethods.length,
          itemBuilder: (context, index) {
            final method = deliveryMethods[index];
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: DeliveryMethodItem(
                deliveryMethod: method,
                isSelected: checkoutCubit.state is CheckoutLoaded &&
                    (checkoutCubit.state as CheckoutLoaded)
                            .selectedDeliveryMethod
                            ?.id ==
                        method.id,
                onTap: () {
                  checkoutCubit.selectDeliveryMethod(method);
                },
              ),
            );
          },
        ),
      );
    }

    return BlocListener<CartCubit, CartState>(
      listener: (context, cartListenState) {
        if (cartListenState is CartLoaded) {
          // Optional: Update total amount if needed, potentially via a dedicated Cubit method
        }
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

              return Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16.0, vertical: 32.0),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Shipping address',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8.0),
                      buildShippingAddressComponent(shippingAddress),
                      const SizedBox(height: 24.0),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Payment',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          InkWell(
                            onTap: () async {
                              await Navigator.of(context)
                                  .pushNamed(AppRoutes.paymentMethodsRoute);
                            },
                            child: Text(
                              'Change',
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
                      const PaymentComponent(),
                      const SizedBox(height: 24.0),
                      Text(
                        'Delivery method',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8.0),
                      buildDeliveryMethodsComponent(deliveryMethods),
                      const SizedBox(height: 32.0),
                      const CheckoutOrderDetails(),
                      const SizedBox(height: 64.0),
                      BlocConsumer<CheckoutCubit, CheckoutState>(
                        listenWhen: (previous, current) =>
                            current is PaymentMakingFailed ||
                            current is PaymentMade,
                        listener: (context, checkoutListenState) {
                          if (checkoutListenState is PaymentMakingFailed) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(checkoutListenState.error),
                                backgroundColor: Colors.red,
                              ),
                            );
                          } else if (checkoutListenState is PaymentMade) {
                            final currentCartState = context.read<CartCubit>().state;
                            final currentAuth = context.read<AuthCubit>().state;

                            if (currentCartState is CartLoaded &&
                                checkoutState is CheckoutLoaded &&
                                currentAuth is AuthSuccess) {
                              if (currentCartState.cartProducts.isNotEmpty) {
                                final userId = currentAuth.user.uid;
                                final shippingInfo = checkoutState.shippingAddress;
                                final deliveryInfo = checkoutState.selectedDeliveryMethod;

                                if (shippingInfo != null && deliveryInfo != null) {
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

                                  final newOrder = OrderModel(
                                    id: '',
                                    userId: userId,
                                    items: orderItems,
                                    totalAmount: finalTotalAmount,
                                    deliveryFee: deliveryInfo.price.toDouble(),
                                    shippingAddress: shippingAddressFormatted,
                                    paymentMethodDetails: "Stripe Card",
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
                                    print("Failed to create order: $error");
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Failed to save order: $error')),
                                    );
                                  });
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Please select shipping address and delivery method.')),
                                  );
                                }
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Order Placed (Cart was empty).'),
                                        backgroundColor: Colors.green,
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
                        builder: (context, submitState) {
                           final checkoutCubit = context.read<CheckoutCubit>();
                          if (submitState is MakingPayment) {
                            return MainButton(
                              hasCircularBorder: true,
                              child: const Center(child: CircularProgressIndicator.adaptive(backgroundColor: Colors.white)),
                            );
                          }
                          return MainButton(
                            text: 'Submit Order',
                            onTap: () async {
                              final cartStateForSubmit = context.read<CartCubit>().state;
                              final checkoutStateForSubmit = context.read<CheckoutCubit>().state;

                              if (checkoutStateForSubmit is CheckoutLoaded) {
                                if (checkoutStateForSubmit.shippingAddress == null) {
                                   ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Please select a shipping address.')),
                                  );
                                  return;
                                }
                                 if (checkoutStateForSubmit.selectedDeliveryMethod == null) {
                                   ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Please select a delivery method.')),
                                  );
                                  return;
                                }
                              } else {
                                 ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Checkout data not loaded.')),
                                  );
                                  return;
                              }

                              if (cartStateForSubmit is CartLoaded && checkoutStateForSubmit is CheckoutLoaded) {
                                double totalAmount = cartStateForSubmit.totalAmount;
                                double delivery = checkoutStateForSubmit.selectedDeliveryMethod!.price.toDouble();
                                final summary = totalAmount + delivery;

                                 if (cartStateForSubmit.cartProducts.isEmpty) {
                                   ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Your cart is empty.')),
                                    );
                                    return;
                                }

                                if (summary <= 0 ) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Cannot checkout with zero or negative amount.')),
                                    );
                                    return;
                                }

                                await checkoutCubit.makePayment(summary);
                              } else {
                                 ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Cart not loaded.')),
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