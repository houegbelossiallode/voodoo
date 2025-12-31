/// Modèle pour les festivals
class Festival {
  final String id;
  final String nom;
  final String ville;
  final String pays;
  final String description;
  final String imagePath;

  Festival({
    required this.id,
    required this.nom,
    required this.ville,
    required this.pays,
    required this.description,
    required this.imagePath,
  });

  /// Liste des festivals disponibles
  static List<Festival> getFestivals() {
    return [
      Festival(
        id: 'vodun_days',
        nom: 'Vodun Days',
        ville: 'Ouidah',
        pays: 'Bénin',
        description: 'Festival du Vodoun à Ouidah',
        imagePath: 'assets/images/vodoo.jpeg',
      ),
      Festival(
        id: 'evala',
        nom: 'Evala',
        ville: 'Kara',
        pays: 'Togo',
        description: 'Festival Evala à Kara',
        imagePath: 'assets/images/evala.jpeg',
      ),
      Festival(
        id: 'festival_masques',
        nom: 'Festival des Masques',
        ville: 'Porto-Novo',
        pays: 'Bénin',
        description: 'Festival des masques à Porto-Novo',
        imagePath: 'assets/images/masque.jpeg',
      ),
    ];
  }

  /// Récupère un festival par son ID
  static Festival? getById(String id) {
    try {
      return getFestivals().firstWhere((f) => f.id == id);
    } catch (e) {
      return null;
    }
  }
}
