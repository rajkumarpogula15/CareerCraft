class FavouriteRepo {
  final int repoId;
  final String name;
  final String description;
  final bool isPrivate;
  final String htmlUrl;
  final String owner;

  FavouriteRepo({
    required this.repoId,
    required this.name,
    required this.description,
    required this.isPrivate,
    required this.htmlUrl,
    required this.owner,
  });

  factory FavouriteRepo.fromJson(Map<String, dynamic> json) {
    final fullName = json['fullName'] as String? ?? '';
    final owner = fullName.contains('/') ? fullName.split('/').first : '';

    return FavouriteRepo(
      repoId: json['repoId'],
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      isPrivate: json['private'] ?? false,
      htmlUrl: json['htmlUrl'] ?? '',
      owner: owner,
    );
  }
}
