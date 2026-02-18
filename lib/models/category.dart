class Category {
  final String name;

  Category({required this.name});

  // Updated factory to handle a simple string from the API.
  factory Category.fromJson(String name) {
    return Category(name: name);
  }
}
