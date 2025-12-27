import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vodou/core/constants/app_colors.dart';
import 'package:vodou/features/auth/presentation/providers/auth_provider.dart';
import 'package:vodou/features/favorites/domain/models/favorite.dart';
import 'package:vodou/features/favorites/presentation/providers/favorite_provider.dart';

/// Dialog pour choisir ou créer une liste de favoris
class FavoriteListDialog extends ConsumerStatefulWidget {
  final int logementId;
  final String logementTitre;

  const FavoriteListDialog({
    super.key,
    required this.logementId,
    required this.logementTitre,
  });

  @override
  ConsumerState<FavoriteListDialog> createState() => _FavoriteListDialogState();
}

class _FavoriteListDialogState extends ConsumerState<FavoriteListDialog> {
  bool _isCreatingNew = false;
  final _formKey = GlobalKey<FormState>();
  final _libelleController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _libelleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final favoriteListsAsync = ref.watch(favoriteListsProvider);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 600),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                const Icon(Icons.favorite, color: AppColors.favorite, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ajouter aux favoris',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.logementTitre,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const Divider(height: 24),

            // Content
            if (_isCreatingNew)
              _buildCreateNewForm()
            else
              Expanded(
                child: favoriteListsAsync.when(
                  data: (lists) => _buildListSelection(lists),
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, stack) => Center(
                    child: Text(
                      'Erreur: ${error.toString()}',
                      style: const TextStyle(color: AppColors.error),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildListSelection(List<Favorite> lists) {
    if (lists.isEmpty) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.folder_outlined,
            size: 64,
            color: AppColors.grey.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          const Text(
            'Aucune liste de favoris',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Créez votre première liste',
            style: TextStyle(color: AppColors.textHint),
          ),
          const SizedBox(height: 24),
          _buildCreateNewButton(),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Choisir une liste',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: lists.length,
            itemBuilder: (context, index) {
              final list = lists[index];
              return _buildListTile(list);
            },
          ),
        ),
        const SizedBox(height: 12),
        _buildCreateNewButton(),
      ],
    );
  }

  Widget _buildListTile(Favorite list) {
    // Charger le nombre de logements depuis le provider
    final logementsAsync = ref.watch(favoriteListLogementsProvider(list.id));

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.favorite.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.folder, color: AppColors.favorite),
        ),
        title: Text(
          list.libelle,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: logementsAsync.when(
          data: (logements) => Text('${logements.length} logement(s)'),
          loading: () => const Text('Chargement...'),
          error: (_, __) => const Text('0 logement(s)'),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: _isLoading ? null : () => _addToList(list.id),
      ),
    );
  }

  Widget _buildCreateNewButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _isLoading
            ? null
            : () {
                setState(() => _isCreatingNew = true);
              },
        icon: const Icon(Icons.add),
        label: const Text('Créer une nouvelle liste'),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12),
          side: const BorderSide(color: AppColors.primary),
        ),
      ),
    );
  }

  Widget _buildCreateNewForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Nouvelle liste',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _libelleController,
            maxLength: 50,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Nom de la liste',
              hintText: 'Ex: Mes logements préférés',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.label_outline),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Veuillez entrer un nom';
              }
              if (value.trim().length > 50) {
                return 'Maximum 50 caractères';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _isLoading
                      ? null
                      : () {
                          setState(() {
                            _isCreatingNew = false;
                            _libelleController.clear();
                          });
                        },
                  child: const Text('Annuler'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _createAndAddToList,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.white,
                            ),
                          ),
                        )
                      : const Text('Créer et ajouter'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _addToList(int favoriteId) async {
    setState(() => _isLoading = true);

    try {
      await ref
          .read(favoriteRepositoryProvider)
          .addLogementToFavorite(favoriteId, widget.logementId);

      // Mettre à jour l'état des favoris immédiatement
      ref.read(favoriteNotifierProvider.notifier).addToState(widget.logementId);

      // Rafraîchir les providers
      ref.invalidate(favoriteListsProvider);
      ref.invalidate(favoriteLogementsProvider);
      ref.invalidate(favoriteListLogementsProvider(favoriteId));

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ajouté aux favoris'),
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _createAndAddToList() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final repository = ref.read(favoriteRepositoryProvider);
      final userAsync = ref.read(currentUserProvider);
      final user = userAsync.value;

      if (user == null) {
        throw Exception('Utilisateur non connecté');
      }

      // Créer la liste
      final newList = await repository.createFavoriteList(
        userId: user.id,
        libelle: _libelleController.text.trim(),
      );

      // Ajouter le logement à la liste
      await repository.addLogementToFavorite(newList.id, widget.logementId);

      // Mettre à jour l'état des favoris immédiatement
      ref.read(favoriteNotifierProvider.notifier).addToState(widget.logementId);

      // Rafraîchir les providers
      ref.invalidate(favoriteListsProvider);
      ref.invalidate(favoriteLogementsProvider);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Liste "${newList.libelle}" créée et logement ajouté',
            ),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
