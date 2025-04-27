import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_ecommerce/models/product.dart';
import 'package:flutter_ecommerce/services/home_services.dart';
import 'package:flutter_ecommerce/services/recommendation_service.dart';
import 'package:meta/meta.dart';

part 'home_state.dart';

class HomeCubit extends Cubit<HomeState> {
  HomeCubit() : super(HomeInitial()) {
    print('--- HomeCubit Created (Instance: $hashCode) ---');
  }

  final HomeServicesImpl homeServices = HomeServicesImpl();
  final RecommendationServices recommendationServices = RecommendationServices();

  @override
  void emit(HomeState state) {
    print('HomeCubit (Instance: $hashCode) Emitting State: ${state.runtimeType}');
    if (isClosed) {
      print('HomeCubit (Instance: $hashCode) Warning: Emitting on a closed cubit');
      return;
    }
    super.emit(state);
  }

  Future<void> getHomeContent({String? userId}) async {
    print('HomeCubit (Instance: $hashCode): getHomeContent() Called');
    emit(HomeLoading());
    try {
      final results = await Future.wait([
        homeServices.getNewProducts(),
        homeServices.getSalesProducts(),
        homeServices.getAllProducts(),
        recommendationServices.getRecommendations(userId),
      ]);

      final newProducts = results[0] as List<Product>;
      final salesProducts = results[1] as List<Product>;
      final allProducts = results[2] as List<Product>;
      final recommendedProducts = results[3] as List<Product>;

      emit(HomeSuccess(
        salesProducts: salesProducts,
        newProducts: newProducts,
        allProducts: allProducts,
        recommendedProducts: recommendedProducts,
      ));
    } catch (e) {
      print('HomeCubit (Instance: $hashCode): getHomeContent() Failed - $e');
      emit(HomeFailed(e.toString()));
    }
  }

  Future<void> refreshRecommendations({String? userId}) async {
    print('HomeCubit (Instance: $hashCode): refreshRecommendations() Called');
    if (state is HomeSuccess) {
      final currentState = state as HomeSuccess;
      try {
        final newRecommendedProducts = await recommendationServices.getRecommendations(userId);

        emit(HomeSuccess(
          salesProducts: currentState.salesProducts,
          newProducts: currentState.newProducts,
          allProducts: currentState.allProducts,
          recommendedProducts: newRecommendedProducts,
        ));
        print('HomeCubit (Instance: $hashCode): refreshRecommendations() Success');
      } catch (e) {
        print('HomeCubit (Instance: $hashCode): refreshRecommendations() Failed - $e');
      }
    } else {
      print('HomeCubit (Instance: $hashCode): Cannot refresh recommendations because current state is not HomeSuccess. Current state: ${state.runtimeType}');
    }
  }

  @override
  Future<void> close() {
    print('--- HomeCubit Closing (Instance: $hashCode) ---');
    return super.close();
  }
}
