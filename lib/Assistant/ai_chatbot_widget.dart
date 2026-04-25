import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'ai_chat_service.dart';

class AiChatbotWidget extends StatefulWidget {
  const AiChatbotWidget({super.key});

  @override
  State<AiChatbotWidget> createState() => _AiChatbotWidgetState();
}

class _AiChatMessage {
  final String text;
  final bool fromUser;

  const _AiChatMessage({required this.text, required this.fromUser});
}

class _AiChatbotWidgetState extends State<AiChatbotWidget> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isOpen = false;
  bool _isSending = false;

  final List<_AiChatMessage> _messages = const [
    _AiChatMessage(
      text: 'Ask me about your schedule, classes, attendance, or portal work.',
      fromUser: false,
    ),
  ].toList();

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _send([String? quickPrompt]) async {
    final text = (quickPrompt ?? _controller.text).trim();
    if (text.isEmpty || _isSending) return;

    setState(() {
      _messages.add(_AiChatMessage(text: text, fromUser: true));
      _controller.clear();
      _isSending = true;
    });
    _scrollToBottom();

    final response = await AiChatService.ask(text);
    if (!mounted) return;

    setState(() {
      _messages.add(_AiChatMessage(text: response.answer, fromUser: false));
      _isSending = false;
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Positioned(
      right: 16,
      bottom: 86,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: _isOpen ? _buildChatPanel(isDarkMode) : const SizedBox(),
          ),
          const SizedBox(height: 12),
          _buildLauncher(isDarkMode),
        ],
      ),
    );
  }

  Widget _buildLauncher(bool isDarkMode) {
    return GestureDetector(
      onTap: () => setState(() => _isOpen = true),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!_isOpen)
            Container(
              constraints: const BoxConstraints(maxWidth: 190),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.surface(isDarkMode),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: AppColors.border(isDarkMode)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.16),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Text(
                'Ask me...',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppColors.textSecondary(isDarkMode),
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          if (!_isOpen) const SizedBox(width: 10),
          Container(
            height: 62,
            width: 62,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.info],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.34),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Icon(
              _isOpen ? Icons.close_rounded : Icons.smart_toy_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatPanel(bool isDarkMode) {
    final width = MediaQuery.of(context).size.width;
    final panelWidth = width < 380 ? width - 32 : 360.0;

    return Material(
      color: Colors.transparent,
      child: Container(
        key: const ValueKey('chat-panel'),
        width: panelWidth,
        constraints: const BoxConstraints(maxHeight: 520),
        decoration: BoxDecoration(
          color: AppColors.surface(isDarkMode),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border(isDarkMode)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.22),
              blurRadius: 28,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(isDarkMode),
              Flexible(child: _buildMessages(isDarkMode)),
              _buildQuickPrompts(isDarkMode),
              _buildComposer(isDarkMode),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.info],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      child: Row(
        children: [
          Container(
            height: 38,
            width: 38,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.smart_toy_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'KUET CSE Assistant',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Teacher and admin support',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => setState(() => _isOpen = false),
            icon: const Icon(Icons.close_rounded, color: Colors.white),
            tooltip: 'Close assistant',
          ),
        ],
      ),
    );
  }

  Widget _buildMessages(bool isDarkMode) {
    return Container(
      color: AppColors.background(isDarkMode),
      child: ListView.builder(
        controller: _scrollController,
        shrinkWrap: true,
        padding: const EdgeInsets.all(14),
        itemCount: _messages.length + (_isSending ? 1 : 0),
        itemBuilder: (context, index) {
          if (_isSending && index == _messages.length) {
            return _buildTypingBubble(isDarkMode);
          }

          final message = _messages[index];
          return Align(
            alignment: message.fromUser
                ? Alignment.centerRight
                : Alignment.centerLeft,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 280),
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
              decoration: BoxDecoration(
                color: message.fromUser
                    ? AppColors.primary
                    : AppColors.surface(isDarkMode),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(message.fromUser ? 16 : 5),
                  bottomRight: Radius.circular(message.fromUser ? 5 : 16),
                ),
                border: message.fromUser
                    ? null
                    : Border.all(color: AppColors.border(isDarkMode)),
              ),
              child: Text(
                message.text,
                style: TextStyle(
                  color: message.fromUser
                      ? Colors.white
                      : AppColors.textPrimary(isDarkMode),
                  fontSize: 13,
                  height: 1.45,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTypingBubble(bool isDarkMode) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surface(isDarkMode),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border(isDarkMode)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 14,
              width: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Thinking',
              style: TextStyle(
                color: AppColors.textSecondary(isDarkMode),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickPrompts(bool isDarkMode) {
    return Container(
      color: AppColors.surface(isDarkMode),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _quickChip('Today schedule', Icons.calendar_today_rounded),
            _quickChip('Next class', Icons.schedule_rounded),
            _quickChip('Attendance help', Icons.fact_check_rounded),
          ],
        ),
      ),
    );
  }

  Widget _quickChip(String text, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ActionChip(
        avatar: Icon(icon, size: 16, color: AppColors.primary),
        label: Text(text),
        labelStyle: TextStyle(
          color: AppColors.primary,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
        onPressed: () => _send(
          text == 'Today schedule' ? "What is my today's schedule?" : text,
        ),
        visualDensity: VisualDensity.compact,
        side: BorderSide(color: AppColors.primary.withValues(alpha: 0.22)),
      ),
    );
  }

  Widget _buildComposer(bool isDarkMode) {
    return Container(
      color: AppColors.surface(isDarkMode),
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              minLines: 1,
              maxLines: 3,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _send(),
              decoration: InputDecoration(
                hintText: 'Ask me anything...',
                hintStyle: TextStyle(
                  color: AppColors.textSecondary(isDarkMode),
                ),
                filled: true,
                fillColor: AppColors.background(isDarkMode),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: AppColors.border(isDarkMode)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: AppColors.border(isDarkMode)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: AppColors.primary),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filled(
            onPressed: _isSending ? null : () => _send(),
            style: IconButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              disabledBackgroundColor: AppColors.primary.withValues(
                alpha: 0.35,
              ),
            ),
            icon: const Icon(Icons.send_rounded),
            tooltip: 'Send message',
          ),
        ],
      ),
    );
  }
}
