import 'package:flutter/material.dart';

class AppIcons {
  //  Mapa global disponible en toda la app
  static const Map<String, IconData> iconMap = {
    //  Hogar
    'home': Icons.home_outlined,
    'house': Icons.house_outlined,
    'home_work': Icons.home_work_outlined,
    'apartment': Icons.apartment_outlined,
    'lightbulb': Icons.lightbulb_outline,
    'tv': Icons.tv_outlined,
    'bed': Icons.bed_outlined,
    'chair': Icons.chair_outlined,

    //  Finanzas
    'account_balance': Icons.account_balance_outlined,
    'attach_money': Icons.attach_money_outlined,
    'savings': Icons.savings_outlined,
    'wallet': Icons.wallet_outlined,
    'credit_card': Icons.credit_card_outlined,
    'trending_up': Icons.trending_up_outlined,
    'shopping_bag': Icons.shopping_bag_outlined,
    'shopping_cart': Icons.shopping_cart_outlined,
    'receipt_long': Icons.receipt_long_outlined,

    //  Transporte
    'directions_car': Icons.directions_car_outlined,
    'local_gas_station': Icons.local_gas_station_outlined,
    'electric_car': Icons.electric_car_outlined,
    'motorcycle': Icons.motorcycle_outlined,
    'airport_shuttle': Icons.airport_shuttle_outlined,
    'map': Icons.map_outlined,
    'directions_bus': Icons.directions_bus_outlined,
    'flight': Icons.flight_outlined,
    'train': Icons.train_outlined,
    'commute': Icons.commute_outlined,

    //  Comida
    'fastfood': Icons.fastfood_outlined,
    'restaurant': Icons.restaurant_outlined,
    'local_pizza': Icons.local_pizza_outlined,
    'coffee': Icons.coffee_outlined,
    'icecream': Icons.icecream_outlined,
    'local_bar': Icons.local_bar_outlined,
    'local_dining': Icons.local_dining_outlined,
    'cake': Icons.cake_outlined,

    //  Salud
    'health_and_safety': Icons.health_and_safety_outlined,
    'medical_services': Icons.medical_services_outlined,
    'local_hospital': Icons.local_hospital_outlined,
    'spa': Icons.spa_outlined,
    'fitness_center': Icons.fitness_center_outlined,
    'monitor_heart': Icons.monitor_heart_outlined,
    'psychology': Icons.psychology_outlined,
    'vaccines': Icons.vaccines_outlined,

    //  Trabajo / Educación
    'work': Icons.work_outline,
    'computer': Icons.computer_outlined,
    'handyman': Icons.handyman_outlined,
    'design_services': Icons.design_services_outlined,
    'engineering': Icons.engineering_outlined,
    'school': Icons.school_outlined,
    'menu_book': Icons.menu_book_outlined,
    'science': Icons.science_outlined,
    'library_books': Icons.library_books_outlined,
    'business': Icons.business_outlined,
    'store': Icons.store_outlined,

    //  Entretenimiento
    'theater_comedy': Icons.theater_comedy_outlined,
    'movie': Icons.movie_outlined,
    'music_note': Icons.music_note_outlined,
    'gamepad': Icons.gamepad_outlined,
    'sports_esports': Icons.sports_esports_outlined,

    //  Tecnología / Comunicación
    'devices': Icons.devices_outlined,
    'phone': Icons.phone_iphone_outlined,
    'email': Icons.email_outlined,
    'wifi': Icons.wifi_outlined,
    'smartphone': Icons.smartphone_outlined,

    //  Varios
    'card_giftcard': Icons.card_giftcard_outlined,
    'redeem': Icons.redeem_outlined,
    'checkroom': Icons.checkroom_outlined,
    'more_horiz': Icons.more_horiz_outlined,
    'category': Icons.category_outlined,
  };

  /// Convierte el nombre guardado en BD (String) a IconData real
  static IconData fromName(String? name) {
    if (name == null || name.isEmpty) return Icons.category_outlined;
    return iconMap[name] ?? Icons.category_outlined;
  }

  /// Lista rápida para usar en pickers
  static List<IconData> get all => iconMap.values.toList();
}
