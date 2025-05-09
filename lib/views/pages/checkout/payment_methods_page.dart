import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_ecommerce/controllers/checkout/checkout_cubit.dart';
import 'package:flutter_ecommerce/models/checkout/payment_method.dart';
import 'package:flutter_ecommerce/views/widgets/checkout/add_new_card_bottom_sheet.dart';
import 'package:flutter_ecommerce/views/widgets/main_button.dart';

class PaymentMethodsPage extends StatefulWidget {
  const PaymentMethodsPage({super.key});

  @override
  State<PaymentMethodsPage> createState() => _PaymentMethodsPageState();
}

class _PaymentMethodsPageState extends State<PaymentMethodsPage> {
  late CheckoutCubit _checkoutCubit;
  String? _makingPreferredCardId;
  List<PaymentMethod> _cards = [];

  @override
  void initState() {
    super.initState();
    _checkoutCubit = context.read<CheckoutCubit>();
    _checkoutCubit.fetchCards();
  }

  Future<void> _showCardSheet([PaymentMethod? card]) async {
    if (!mounted) return;
    final result = await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => BlocProvider.value(
        value: _checkoutCubit,
        child: AddNewCardBottomSheet(paymentMethod: card),
      ),
    );
    if (result == true && mounted) _checkoutCubit.fetchCards();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Methods'),
        centerTitle: true,
        leading: BackButton(onPressed: () => Navigator.of(context).pop(false)),
      ),
      body: BlocBuilder<CheckoutCubit, CheckoutState>(
        bloc: _checkoutCubit,
        buildWhen: (prev, curr) => curr is! CheckoutInitial,
        builder: (context, state) {
          if (state is CardsFetched) _cards = state.paymentMethods;

          final selected = (_checkoutCubit.state is CheckoutLoaded)
              ? (_checkoutCubit.state as CheckoutLoaded).selectedPaymentMethod
              : null;

          if (state is FetchingCards && _cards.isEmpty) {
            return const Center(child: CircularProgressIndicator.adaptive());
          }

          if (state is CardsFetchingFailed && _cards.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(state.error),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: _checkoutCubit.fetchCards,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (_cards.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('You have no payment methods.'),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _showCardSheet,
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Add New Card'),
                  ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Your payment cards', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 16),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _cards.length,
                  itemBuilder: (context, index) {
                    final card = _cards[index];
                    final isSelected = selected?.id == card.id || card.isPreferred;
                    final isLoading = _makingPreferredCardId == card.id && _checkoutCubit.state is MakingPreferred;
                    final isDeleting = _checkoutCubit.state is DeletingCards && (_checkoutCubit.state as DeletingCards).paymentId == card.id;

                    return Opacity(
                      opacity: (_makingPreferredCardId != null && _makingPreferredCardId != card.id) || isDeleting ? 0.5 : 1.0,
                      child: AbsorbPointer(
                        absorbing: _makingPreferredCardId != null || isDeleting,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Card(
                            elevation: isSelected ? 4 : 1,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: BorderSide(
                                color: isSelected ? Theme.of(context).primaryColor : Colors.grey.shade300,
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: InkWell(
                              onTap: isLoading ? null : () async {
                                setState(() => _makingPreferredCardId = card.id);
                                final success = await _checkoutCubit.makePreferred(card);
                                if (!mounted) return;
                                setState(() => _makingPreferredCardId = null);
                                if (success && mounted) Navigator.of(context).pop(true);
                                else if (mounted) {
                                  final errorMsg = (_checkoutCubit.state is PreferredMakingFailed)
                                      ? (_checkoutCubit.state as PreferredMakingFailed).error
                                      : 'Failed to set preferred card. Please try again.';
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMsg), backgroundColor: Colors.red));
                                }
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        isLoading || isDeleting
                                            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                                            : Icon(Icons.credit_card, color: isSelected ? Theme.of(context).primaryColor : Colors.grey),
                                        const SizedBox(width: 12),
                                        Text(
                                          '**** **** **** ${card.cardNumber.length >= 4 ? card.cardNumber.substring(card.cardNumber.length - 4) : '????'}',
                                          style: TextStyle(
                                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                            color: Colors.black,
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (!isLoading && !isDeleting)
                                      Row(
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.edit, color: Colors.blueGrey),
                                            onPressed: () => _showCardSheet(card),
                                          ),
                                          BlocBuilder<CheckoutCubit, CheckoutState>(
                                            bloc: _checkoutCubit,
                                            buildWhen: (prev, curr) =>
                                                curr is DeletingCards && curr.paymentId == card.id ||
                                                curr is CardsDeleted ||
                                                curr is CardsDeletingFailed,
                                            builder: (context, state) {
                                              if (state is DeletingCards && state.paymentId == card.id) {
                                                return const SizedBox(
                                                  width: 48,
                                                  height: 48,
                                                  child: Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator.adaptive(strokeWidth: 2))),
                                                );
                                              }
                                              return IconButton(
                                                icon: const Icon(Icons.delete, color: Colors.redAccent),
                                                onPressed: () async {
                                                  final confirm = await showDialog<bool>(
                                                    context: context,
                                                    builder: (context) => AlertDialog(
                                                      title: const Text('Confirm Delete'),
                                                      content: Text('Delete card ending in ${card.cardNumber.substring(card.cardNumber.length - 4)}?'),
                                                      actions: [
                                                        TextButton(
                                                          child: const Text('Cancel'),
                                                          onPressed: () => Navigator.of(context).pop(false),
                                                        ),
                                                        TextButton(
                                                          child: const Text('Delete'),
                                                          onPressed: () => Navigator.of(context).pop(true),
                                                        ),
                                                      ],
                                                    ),
                                                  );
                                                  if (confirm == true) _checkoutCubit.deleteCard(card);
                                                },
                                              );
                                            },
                                          ),
                                        ],
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),
                Center(
                  child: MainButton(
                    onTap: () => _makingPreferredCardId == null ? _showCardSheet() : null,
                    text: 'Add New Card',
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}