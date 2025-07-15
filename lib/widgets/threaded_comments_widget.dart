import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../models/comment.dart';
import '../services/social_feed_service.dart';
import '../services/supabase_config.dart';
import 'profile_avatar.dart';

class ThreadedCommentsWidget extends StatefulWidget {
  final String postId;
  final List<Comment> comments;
  final Function() onCommentAdded;

  const ThreadedCommentsWidget({
    Key? key,
    required this.postId,
    required this.comments,
    required this.onCommentAdded,
  }) : super(key: key);

  @override
  State<ThreadedCommentsWidget> createState() => _ThreadedCommentsWidgetState();
}

class _ThreadedCommentsWidgetState extends State<ThreadedCommentsWidget> {
  final TextEditingController _commentController = TextEditingController();
  final TextEditingController _replyController = TextEditingController();
  final SocialFeedService _socialFeedService = SupabaseConfig.socialFeedService;
  
  String? _replyingToCommentId;
  String? _replyingToUsername;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    _replyController.dispose();
    super.dispose();
  }

  void _startReply(Comment comment) {
    setState(() {
      _replyingToCommentId = comment.id;
      _replyingToUsername = comment.username;
    });
  }

  void _cancelReply() {
    setState(() {
      _replyingToCommentId = null;
      _replyingToUsername = null;
      _replyController.clear();
    });
  }

  Future<void> _submitComment() async {
    if (_commentController.text.isEmpty) return;

    setState(() => _isSubmitting = true);

    try {
      await _socialFeedService.addComment(
        widget.postId,
        _commentController.text,
      );
      _commentController.clear();
      widget.onCommentAdded();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to add comment. Please try again.'),
          ),
        );
      }
      print('Error adding comment: $e');
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  Future<void> _submitReply() async {
    if (_replyController.text.isEmpty || _replyingToCommentId == null) return;

    setState(() => _isSubmitting = true);

    try {
      await _socialFeedService.addComment(
        widget.postId,
        _replyController.text,
        parentCommentId: _replyingToCommentId,
        replyToUsername: _replyingToUsername,
      );
      _replyController.clear();
      _cancelReply();
      widget.onCommentAdded();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to add reply. Please try again.'),
          ),
        );
      }
      print('Error adding reply: $e');
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  Widget _buildCommentTile(Comment comment, {int depth = 0}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: EdgeInsets.only(left: depth * 20.0),
          child: Card(
            color: Colors.grey[800],
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ProfileAvatar(
                        avatarUrl: comment.avatarUrl,
                        username: comment.username,
                        radius: 16,
                        backgroundColor: Colors.blue,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  comment.username,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                if (comment.replyToUsername != null) ...[
                                  const SizedBox(width: 4),
                                  const Icon(
                                    Icons.reply,
                                    color: Colors.grey,
                                    size: 12,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    comment.replyToUsername!,
                                    style: const TextStyle(
                                      color: Colors.green,
                                      fontWeight: FontWeight.w500,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              comment.content,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Text(
                                  timeago.format(comment.timestamp),
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                GestureDetector(
                                  onTap: () => _startReply(comment),
                                  child: const Text(
                                    'Reply',
                                    style: TextStyle(
                                      color: Colors.green,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                if (comment.hasReplies) ...[
                                  const SizedBox(width: 16),
                                  Text(
                                    '${comment.replyCount} replies',
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  // Reply input field
                  if (_replyingToCommentId == comment.id) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey[700],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Text(
                                'Replying to ${comment.username}',
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                              const Spacer(),
                              GestureDetector(
                                onTap: _cancelReply,
                                child: const Icon(
                                  Icons.close,
                                  color: Colors.grey,
                                  size: 16,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _replyController,
                                  style: const TextStyle(color: Colors.white),
                                  decoration: const InputDecoration(
                                    hintText: 'Write a reply...',
                                    hintStyle: TextStyle(color: Colors.grey),
                                    border: InputBorder.none,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: _isSubmitting
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.green,
                                        ),
                                      )
                                    : const Icon(
                                        Icons.send,
                                        color: Colors.green,
                                        size: 20,
                                      ),
                                onPressed: _isSubmitting ? null : _submitReply,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        // Display replies
        if (comment.replies.isNotEmpty)
          ...comment.replies.map((reply) => _buildCommentTile(reply, depth: depth + 1)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Comments list
        Expanded(
          child: widget.comments.isEmpty
              ? const Center(
                  child: Text(
                    'No comments yet',
                    style: TextStyle(color: Colors.grey),
                  ),
                )
              : ListView.builder(
                  itemCount: widget.comments.length,
                  itemBuilder: (context, index) {
                    return _buildCommentTile(widget.comments[index]);
                  },
                ),
        ),
        // Add comment input
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey[800],
            border: Border(
              top: BorderSide(color: Colors.grey[600]!),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _commentController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: 'Add a comment...',
                    hintStyle: TextStyle(color: Colors.grey),
                    border: InputBorder.none,
                  ),
                ),
              ),
              IconButton(
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.green,
                        ),
                      )
                    : const Icon(
                        Icons.send,
                        color: Colors.green,
                      ),
                onPressed: _isSubmitting ? null : _submitComment,
              ),
            ],
          ),
        ),
      ],
    );
  }
} 