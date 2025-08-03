import 'package:flutter/material.dart';

class PickSlipWidget extends StatefulWidget {
  final List<Map<String, dynamic>> picks;
  final VoidCallback? onClearAll;
  final Function(int)? onRemovePick;
  final VoidCallback? onCreatePost;

  const PickSlipWidget({
    Key? key,
    required this.picks,
    this.onClearAll,
    this.onRemovePick,
    this.onCreatePost,
  }) : super(key: key);

  @override
  State<PickSlipWidget> createState() => _PickSlipWidgetState();
}

class _PickSlipWidgetState extends State<PickSlipWidget> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    if (widget.picks.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[800],
        border: Border(
          top: BorderSide(color: Colors.grey[600]!, width: 1),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          InkWell(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Icon(
                    Icons.sports_basketball,
                    color: Colors.green,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Pick Slip (${widget.picks.length})',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  if (widget.picks.isNotEmpty) ...[
                    TextButton(
                      onPressed: widget.onClearAll,
                      child: const Text(
                        'Clear All',
                        style: TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Icon(
                    _isExpanded ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_up,
                    color: Colors.grey[400],
                  ),
                ],
              ),
            ),
          ),

          // Expandable content
          if (_isExpanded) ...[
            // Picks list
            Container(
              constraints: const BoxConstraints(maxHeight: 300),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: widget.picks.length,
                itemBuilder: (context, index) {
                  return _buildPickItem(widget.picks[index], index);
                },
              ),
            ),
            
            // Actions
            Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Parlay indicator if multiple picks
                  if (widget.picks.length > 1) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.purple.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.purple.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.link, color: Colors.purple, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            '${widget.picks.length}-Leg Parlay',
                            style: const TextStyle(
                              color: Colors.purple,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  
                  // Create post button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: widget.onCreatePost,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'Create ${widget.picks.length > 1 ? 'Parlay' : 'Pick'} Post',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            // Collapsed preview
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _getPicksSummary(),
                      style: TextStyle(
                        color: Colors.grey[300],
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: widget.onCreatePost,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      minimumSize: Size.zero,
                    ),
                    child: const Text(
                      'Post',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPickItem(Map<String, dynamic> pick, int index) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[700],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[600]!),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Game info
                Text(
                  _getGameDisplay(pick),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                
                // Pick details
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: _getMarketTypeColor(pick['marketType']),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _getMarketTypeDisplay(pick['marketType']),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      pick['odds'] ?? 'N/A',
                      style: const TextStyle(
                        color: Colors.green,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Remove button
          IconButton(
            onPressed: () => widget.onRemovePick?.call(index),
            icon: const Icon(Icons.close, color: Colors.red, size: 18),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(maxWidth: 24, maxHeight: 24),
          ),
        ],
      ),
    );
  }

  String _getGameDisplay(Map<String, dynamic> pick) {
    if (pick['team1']?.isNotEmpty == true && pick['team2']?.isNotEmpty == true) {
      return '${pick['team1']} vs ${pick['team2']}';
    }
    return pick['gameText'] ?? pick['oddsText'] ?? 'Unknown Game';
  }

  String _getMarketTypeDisplay(String? marketType) {
    switch (marketType?.toLowerCase()) {
      case 'moneyline':
        return 'ML';
      case 'spread':
        return 'SPREAD';
      case 'total':
        return 'TOTAL';
      default:
        return 'BET';
    }
  }

  Color _getMarketTypeColor(String? marketType) {
    switch (marketType?.toLowerCase()) {
      case 'moneyline':
        return Colors.blue;
      case 'spread':
        return Colors.orange;
      case 'total':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  String _getPicksSummary() {
    if (widget.picks.isEmpty) return '';
    if (widget.picks.length == 1) {
      return _getGameDisplay(widget.picks[0]);
    }
    return '${widget.picks.length} picks selected';
  }
}