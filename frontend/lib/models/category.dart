class Category {
  final int id;
  final int user_id;
  final String name;
  final String type; // 'income' o 'expense'
  final String color;
  final String? icon;
  final bool isDefault; 
  final DateTime createdAt;
  final DateTime updatedAt;

  Category({
    required this.id,
    required this.user_id,
    required this.name,
    required this.type,
    required this.color,
    this.icon,
    this.isDefault = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      user_id: json['user_id'] is int ? json['user_id'] : int.tryParse(json['user_id'].toString()) ?? 0,
      name: json['name'] ?? '',
      type: json['type'] ?? 'expense',
      color: json['color'] ?? '#000000',
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      icon: json['icon'],
      isDefault: json['is_default'] == true || json['is_default'] == 1, // 👈 robusto
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': user_id,
        'name': name,
        'type': type,
        'color': color,
        'icon': icon,
        'is_default': isDefault,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };
}
