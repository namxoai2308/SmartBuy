import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_ecommerce/controllers/checkout/checkout_cubit.dart';
import 'package:flutter_ecommerce/utilities/args_models/add_shipping_address_args.dart';
import 'package:flutter_ecommerce/utilities/routes.dart';
import 'package:flutter_ecommerce/views/widgets/checkout/shipping_address_state_item.dart';

class ShippingAddressesPage extends StatefulWidget {
  const ShippingAddressesPage({super.key});

  @override
  State<ShippingAddressesPage> createState() => _ShippingAddressesPageState();
}

class _ShippingAddressesPageState extends State<ShippingAddressesPage> {
  late CheckoutCubit checkoutCubit;

  @override
  void initState() {
    super.initState();
    // It's generally safer to get the Cubit in build or didChangeDependencies
    // if context is needed reliably, but this can work if provided above.
    // Consider using context.read<CheckoutCubit>() later if issues arise.
    checkoutCubit = BlocProvider.of<CheckoutCubit>(context, listen: false);
    checkoutCubit.getShippingAddresses();
  }

  Future<void> _navigateToAddAddress() async {
    // No need to await if you don't use the result immediately for refresh
    // Refresh logic should ideally be handled by the Cubit after saving.
    Navigator.of(context).pushNamed(
      AppRoutes.addShippingAddressRoute,
      arguments: AddShippingAddressArgs(checkoutCubit: checkoutCubit),
    );
     // Consider removing the refresh logic here if the Cubit handles it
     // after saveAddress is called successfully from the AddAddressPage.
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Shipping Addresses',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 16.0),
        child: BlocBuilder<CheckoutCubit, CheckoutState>(
          // No need to provide bloc here if it's provided higher up the tree
          // bloc: checkoutCubit,
          buildWhen: (previous, current) =>
              current is FetchingAddresses ||
              current is AddressesFetched ||
              current is AddressesFetchingFailed,
          builder: (context, state) {
            if (state is FetchingAddresses) {
              return const Center(child: CircularProgressIndicator.adaptive());
            } else if (state is AddressesFetchingFailed) {
              return Center(child: Text(state.error));
            } else if (state is AddressesFetched) {
              final shippingAddressesList = state.shippingAddresses;

              if (shippingAddressesList.isEmpty) {
                return const Center(
                  child: Text('No addresses found. Please add one.'),
                );
              }

              return ListView.separated(
                itemCount: shippingAddressesList.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final address = shippingAddressesList[index];
                  // Read the cubit here to ensure it's the correct instance available in the context
                  final currentCheckoutCubit = context.read<CheckoutCubit>();
                  return ShippingAddressStateItem(
                    shippingAddress: address,
                    onTap: () {
                      print('ShippingAddressesPage: Tapping on address item, calling setSelectedAddress.');
                      currentCheckoutCubit.setSelectedAddress(address); // Use the correct 'address' variable
                      print('ShippingAddressesPage: Calling Navigator.pop');
                      Navigator.maybePop(context);
                    },
                  );
                },
              );
            } else {
              return const SizedBox.shrink();
            }
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddAddress,
        backgroundColor: Colors.black,
        child: const Icon(Icons.add),
      ),
    );
  }
}