/// Filtres pour les conversations
enum ConversationFilter {
  all('Tous les messages'),
  hosts('Messages hôtes'),
  visitors('Messages visiteurs'),
  support('Assistance'),
  translators('Messages traducteurs'),
  photographers('Messages photographes');

  final String label;
  const ConversationFilter(this.label);
}
