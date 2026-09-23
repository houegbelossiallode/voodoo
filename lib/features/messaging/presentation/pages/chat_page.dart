import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vodou/core/constants/app_colors.dart';
import 'package:vodou/core/widgets/custom_app_bar.dart';
import 'package:vodou/features/auth/presentation/providers/auth_provider.dart';
import 'package:vodou/features/messaging/domain/models/conversation_model.dart';
import 'package:vodou/features/messaging/presentation/providers/messaging_provider.dart';
import 'package:vodou/features/messaging/presentation/widgets/message_bubble.dart';

class ChatPage extends ConsumerStatefulWidget {
  final int conversationId;
  final ConversationModel? conversation;

  const ChatPage({super.key, required this.conversationId, this.conversation});

  @override
  ConsumerState<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends ConsumerState<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  File? _selectedFile;
  bool _isUploading = false;

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // Marquer la conversation comme lue
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _markAsRead();
      _setupAutoRefresh();
    });
  }

  void _setupAutoRefresh() {
    // Rafraîchir automatiquement les messages toutes les 3 secondes
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        ref.invalidate(conversationMessagesProvider(widget.conversationId));
        _setupAutoRefresh();
      }
    });
  }

  Future<void> _markAsRead() async {
    final user = ref.read(currentUserProvider).value;
    if (user == null) return;

    final repository = ref.read(messagingRepositoryProvider);
    await repository.markConversationAsRead(widget.conversationId, user.id);
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty && _selectedFile == null) return;

    final user = ref.read(currentUserProvider).value;
    if (user == null) return;

    setState(() => _isUploading = true);

    try {
      String? attachmentUrl;

      // Upload le fichier si présent
      if (_selectedFile != null) {
        final fileService = ref.read(fileUploadServiceProvider);
        attachmentUrl = await fileService.uploadMessageAttachment(
          _selectedFile!,
          widget.conversationId,
        );
      }

      _messageController.clear();
      setState(() {
        _selectedFile = null;
        _isUploading = false;
      });

      await ref
          .read(sendMessageProvider.notifier)
          .sendMessage(
            conversationId: widget.conversationId,
            senderId: user.id,
            message: message.isNotEmpty ? message : null,
            attachment: attachmentUrl,
          );

      // Rafraîchir les messages et la liste des conversations
      ref.invalidate(conversationMessagesProvider(widget.conversationId));
      ref.invalidate(conversationsProvider);

      // Scroller vers le bas
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
      setState(() => _isUploading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'envoi: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _pickAttachment() async {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(
                Icons.photo_library,
                color: AppColors.primary,
              ),
              title: const Text('Galerie'),
              onTap: () async {
                Navigator.pop(context);
                final fileService = ref.read(fileUploadServiceProvider);
                final file = await fileService.pickImageFromGallery();
                if (file != null) {
                  setState(() => _selectedFile = file);
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: AppColors.primary),
              title: const Text('Caméra'),
              onTap: () async {
                Navigator.pop(context);
                final fileService = ref.read(fileUploadServiceProvider);
                final file = await fileService.takePhoto();
                if (file != null) {
                  setState(() => _selectedFile = file);
                }
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.insert_drive_file,
                color: AppColors.primary,
              ),
              title: const Text('Fichier'),
              onTap: () async {
                Navigator.pop(context);
                final fileService = ref.read(fileUploadServiceProvider);
                final file = await fileService.pickFile();
                if (file != null) {
                  setState(() => _selectedFile = file);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider).value;
    final conversationAsync = widget.conversation != null
        ? AsyncValue.data(widget.conversation)
        : ref.watch(conversationProvider(widget.conversationId));
    final messagesAsync = ref.watch(
      conversationMessagesProvider(widget.conversationId),
    );

    return Scaffold(
      appBar: CustomAppBar(
        titleWidget: conversationAsync.when(
          data: (conversation) {
            if (conversation == null || user == null) {
              return const Text('Chat');
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  conversation.getNomParticipant(user.id),
                  style: const TextStyle(fontSize: 16),
                ),
                if (conversation.getTitreLogement() != null)
                  Text(
                    conversation.getTitreLogement()!,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.normal,
                      color: AppColors.textSecondary,
                    ),
                  ),
              ],
            );
          },
          loading: () => const Text('Chat'),
          error: (_, __) => const Text('Chat'),
        ),
      ),
      body: Column(
        children: [
          // Messages
          Expanded(
            child: messagesAsync.when(
              data: (messages) {
                if (messages.isEmpty) {
                  return RefreshIndicator(
                    onRefresh: () async {
                      // Rafraîchir les messages et les infos de la conversation
                      ref.invalidate(
                        conversationMessagesProvider(widget.conversationId),
                      );
                      ref.invalidate(
                        conversationProvider(widget.conversationId),
                      );
                    },
                    child: ListView(
                      children: const [
                        SizedBox(height: 200),
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.chat_bubble_outline,
                                size: 64,
                                color: AppColors.grey,
                              ),
                              SizedBox(height: 16),
                              Text(
                                'Aucun message',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Envoyez votre premier message',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppColors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    // Rafraîchir les messages et les infos de la conversation
                    ref.invalidate(
                      conversationMessagesProvider(widget.conversationId),
                    );
                    ref.invalidate(conversationProvider(widget.conversationId));
                  },
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[index];
                      final isMe = user != null && message.isSentByMe(user.id);

                      return MessageBubble(message: message, isMe: isMe);
                    },
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: AppColors.error,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Erreur de chargement',
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      error.toString(),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Champ de saisie
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  // Bouton pièce jointe
                  IconButton(
                    onPressed: _isUploading ? null : _pickAttachment,
                    icon: const Icon(Icons.attach_file),
                    color: AppColors.grey,
                  ),
                  const SizedBox(width: 8),

                  // Prévisualisation du fichier sélectionné
                  if (_selectedFile != null) ...[
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            ref
                                    .read(fileUploadServiceProvider)
                                    .isImage(_selectedFile!.path)
                                ? Icons.image
                                : Icons.insert_drive_file,
                            size: 20,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _selectedFile!.path.split('/').last.length > 15
                                ? '${_selectedFile!.path.split('/').last.substring(0, 15)}...'
                                : _selectedFile!.path.split('/').last,
                            style: const TextStyle(fontSize: 12),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, size: 16),
                            onPressed: () =>
                                setState(() => _selectedFile = null),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],

                  // Champ de texte
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Votre message...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: const BorderSide(color: AppColors.grey),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(
                            color: AppColors.grey.withValues(alpha: 0.3),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: const BorderSide(
                            color: AppColors.primary,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                      maxLines: null,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Bouton envoyer
                  IconButton(
                    onPressed: _isUploading ? null : _sendMessage,
                    icon: _isUploading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send),
                    color: AppColors.primary,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
