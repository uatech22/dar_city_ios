class Team {
  final int id;
  final String name;
  final String? shortName;
  final String? city;
  final String? region;
  final String? country;
  final String? logo;

  Team({
    required this.id,
    required this.name,
    this.shortName,
    this.city,
    this.region,
    this.country,
    this.logo,
  });

  factory Team.fromJson(Map<String, dynamic> json) {
    return Team(
      id: json['id'],
      name: json['name'],
      shortName: json['short_name'],
      city: json['city'],
      region: json['region'],
      country: json['country'],
      logo: json['logo'],
    );
  }
}
