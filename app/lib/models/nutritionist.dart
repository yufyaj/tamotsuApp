class Nutritionist {
  final String nutritionist_id;
  final String name;
  final String imageUrl;
  final String introduction;
  final List<String> specialties;
  final int registeredUsers;
  final Map<String, List<String>> availableHours;

  Nutritionist({
    required this.nutritionist_id,
    required this.name,
    required this.imageUrl,
    required this.introduction,
    required this.specialties,
    required this.registeredUsers,
    required this.availableHours,
  });

  factory Nutritionist.fromJson(Map<String, dynamic> json) {
    return Nutritionist(
      nutritionist_id: json['nutritionistId'],
      name: json['name'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      introduction: json['introduce'] ?? '',
      specialties: (json['specialties'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
      registeredUsers: json['registeredUsers'] ?? 0,
      availableHours: (json['availableHours'] as Map<String, dynamic>?)?.map(
        (key, value) => MapEntry(
          key,
          (value as List<dynamic>).map((e) => e as String).toList(),
        ),
      ) ?? {},
    );
  }
}
