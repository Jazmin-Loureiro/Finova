class MoneyMakerType {
  final int id;
  final String name;
  final String? description;
  final bool active;

  MoneyMakerType({
    required this.id,
    required this.name,
    this.description,
    required this.active,
  });

  factory MoneyMakerType.fromJson(Map<String, dynamic> json) {
    return MoneyMakerType(
      id: int.tryParse(json['id'].toString()) ?? 0,
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString(),
      active: json['active'] == true || json['active'] == 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'active': active,
    };
  }

  @override
  String toString() {
    return 'MoneyMakerType{id: $id, name: $name, description: $description, active: $active}';
  }
}
