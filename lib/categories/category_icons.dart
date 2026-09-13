import 'package:flutter/material.dart';

class CategoryIconGroup {
  const CategoryIconGroup(this.name, this.icons);

  final String name;
  final List<IconData> icons;
}

const categoryIconGroups = <CategoryIconGroup>[
  CategoryIconGroup('Food', [
    Icons.restaurant_outlined,
    Icons.local_dining_outlined,
    Icons.fastfood_outlined,
    Icons.local_cafe_outlined,
    Icons.lunch_dining_outlined,
  ]),
  CategoryIconGroup('Shopping', [
    Icons.shopping_bag_outlined,
    Icons.shopping_cart_outlined,
    Icons.local_mall_outlined,
    Icons.card_giftcard_outlined,
    Icons.sell_outlined,
  ]),
  CategoryIconGroup('Transport', [
    Icons.directions_car_outlined,
    Icons.directions_bus_outlined,
    Icons.train_outlined,
    Icons.two_wheeler_outlined,
    Icons.local_gas_station_outlined,
  ]),
  CategoryIconGroup('Bills', [
    Icons.receipt_long_outlined,
    Icons.receipt_outlined,
    Icons.bolt_outlined,
    Icons.water_drop_outlined,
    Icons.wifi_outlined,
  ]),
  CategoryIconGroup('Entertainment', [
    Icons.movie_outlined,
    Icons.music_note_outlined,
    Icons.sports_soccer_outlined,
    Icons.gamepad_outlined,
    Icons.theater_comedy_outlined,
  ]),
  CategoryIconGroup('Health', [
    Icons.health_and_safety_outlined,
    Icons.medical_services_outlined,
    Icons.local_pharmacy_outlined,
    Icons.fitness_center_outlined,
    Icons.spa_outlined,
  ]),
  CategoryIconGroup('Travel', [
    Icons.flight_outlined,
    Icons.hotel_outlined,
    Icons.luggage_outlined,
    Icons.beach_access_outlined,
    Icons.map_outlined,
  ]),
  CategoryIconGroup('Education', [
    Icons.school_outlined,
    Icons.menu_book_outlined,
    Icons.book_outlined,
    Icons.edit_outlined,
    Icons.science_outlined,
  ]),
  CategoryIconGroup('Home', [
    Icons.home_outlined,
    Icons.apartment_outlined,
    Icons.chair_outlined,
    Icons.cleaning_services_outlined,
    Icons.build_outlined,
  ]),
  CategoryIconGroup('Work', [
    Icons.work_outline,
    Icons.business_center_outlined,
    Icons.laptop_outlined,
    Icons.phone_android_outlined,
    Icons.meeting_room_outlined,
  ]),
  CategoryIconGroup('Finance', [
    Icons.account_balance_outlined,
    Icons.account_balance_wallet_outlined,
    Icons.savings_outlined,
    Icons.credit_card_outlined,
    Icons.trending_up_outlined,
  ]),
  CategoryIconGroup('Other', [
    Icons.category_outlined,
    Icons.star_outline,
    Icons.favorite_border,
    Icons.pets_outlined,
    Icons.more_horiz,
  ]),
];
