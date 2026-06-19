import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class ChatInputBar extends StatefulWidget {
  final bool isGenerating;
  final ValueChanged<String> onSend;

  const ChatInputBar({
    super.key,
    required this.isGenerating,
    required this.onSend,
  });

  @override
  State<ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends State<ChatInputBar> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  bool get _canSend =>
      _controller.text.trim().isNotEmpty && !widget.isGenerating;

  void _handleSend() {
    final text = _controller.text.trim();
    if (text.isEmpty || widget.isGenerating) return;

    widget.onSend(text);
    _controller.clear();
    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 8,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom > 0
            ? 12
            : MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          top: BorderSide(
            color: Colors.grey.shade200,
            width: 1,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              textCapitalization: TextCapitalization.sentences,
              maxLines: 5,
              minLines: 1,
              enabled: !widget.isGenerating,
              onChanged: (_) => setState(() {}),
              onSubmitted: (_) => _handleSend(),
              decoration: InputDecoration(
                hintText: widget.isGenerating
                    ? 'AI is thinking...'
                    : 'Ask me anything...',
                filled: true,
                fillColor: AppColors.surfaceVariant,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide:
                      const BorderSide(color: AppColors.primary, width: 1.5),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            child: IconButton(
              onPressed: _canSend ? _handleSend : null,
              icon: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: widget.isGenerating
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primary,
                        ),
                      )
                    : Icon(
                        Icons.send_rounded,
                        color: _canSend
                            ? AppColors.primary
                            : AppColors.textTertiary,
                      ),
              ),
              style: IconButton.styleFrom(
                backgroundColor:
                    _canSend ? AppColors.primary.withValues(alpha: 0.1) : null,
                shape: const CircleBorder(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
