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
    checkoutCubit = BlocProvider.of<CheckoutCubit>(context, listen: false);
    checkoutCubit.getShippingAddresses();
  }

  Future<void> _navigateToAddAddress() async {
    Navigator.of(context).pushNamed(
      AppRoutes.addShippingAddressRoute,
      arguments: AddShippingAddressArgs(checkoutCubit: checkoutCubit),
    );
  }

  Future<void> _refreshAddresses() async {
    await checkoutCubit.getShippingAddresses();
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
          buildWhen: (previous, current) =>
              current is FetchingAddresses ||
              current is AddressesFetched ||
              current is AddressesFetchingFailed,
          builder: (context, state) {
            if (state is FetchingAddresses) {
              return const Center(child: CircularProgressIndicator.adaptive());
            } else if (state is AddressesFetchingFailed) {
              return RefreshIndicator(
                onRefresh: _refreshAddresses,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    SizedBox(height: 200),
                    Center(child: Text(state.error)),
                  ],
                ),
              );
            } else if (state is AddressesFetched) {
              final shippingAddressesList = state.shippingAddresses;

              if (shippingAddressesList.isEmpty) {
                return RefreshIndicator(
                  onRefresh: _refreshAddresses,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: const [
                      SizedBox(height: 200),
                      Center(child: Text('No addresses found. Please add one.')),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: _refreshAddresses,
                child: ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemCount: shippingAddressesList.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final address = shippingAddressesList[index];
                    return ShippingAddressStateItem(
                      shippingAddress: address,
                      onTap: () {
                        context.read<CheckoutCubit>().setSelectedAddress(address);
                        Navigator.maybePop(context);
                      },
                    );
                  },
                ),
              );
            } else {
              return const SizedBox.shrink();
            }
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddAddress,
//         backgroundColor: Colors.black,
        child: const Icon(Icons.add),
      ),
    );
  }
}
