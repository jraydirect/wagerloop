import 'package:flutter/material.dart';
import '../models/pick_post.dart';
import '../utils/team_logo_utils.dart';

class PicksDisplayWidget extends StatelessWidget {
  final List<Pick> picks;
  final bool showParlayBadge;
  final bool compact;

  const PicksDisplayWidget({
    Key? key,
    required this.picks,
    this.showParlayBadge = true,
    this.compact = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (picks.isEmpty) {
      return const SizedBox.shrink();
    }

    final isParlay = picks.length > 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Simple parlay badge (only show if requested and it's a parlay)
        if (showParlayBadge && isParlay) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.grey[700]!,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey[600]!),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.layers, color: Colors.grey[400]!, size: 16),
                const SizedBox(width: 4),
                Text(
                  '${picks.length}-Leg Parlay',
                  style: TextStyle(
                    color: Colors.grey[300],
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
        
        // Combined picks display
        if (compact) ...[
          _buildCompactPicksCard(),
        ] else ...[
          _buildFullPicksCard(),
        ],
      ],
    );
  }

  Widget _buildCompactPicksCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.grey[600]!,
        ),
      ),
      child: _buildCombinedPicksLayout(compact: true),
    );
  }

  Widget _buildFullPicksCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey[600]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Game info header
          Row(
            children: [
              Icon(
                _getSportIcon(picks.first.game.sport),
                color: Colors.grey[400],
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                picks.first.game.sport.toUpperCase(),
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              Text(
                picks.first.game.formattedGameTime,
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Combined picks layout
          _buildCombinedPicksLayout(compact: false),
          
          // Bet slip style parlay odds (only for parlays)
          if (picks.length > 1 && _getParlayOdds(picks) != null) ...[
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${picks.length} leg parlay',
                  style: TextStyle(
                    color: Colors.grey[300],
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  _getParlayOdds(picks)!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
          
          // Reasoning if available (show first pick's reasoning)
          if (picks.first.reasoning != null && picks.first.reasoning!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              picks.first.reasoning!,
              style: TextStyle(
                color: Colors.grey[300],
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCombinedPicksLayout({required bool compact}) {
    return Column(
      children: picks.asMap().entries.map<Widget>((entry) {
        final index = entry.key;
        final pick = entry.value;
        final isLast = index == picks.length - 1;
        
        return Column(
          children: [
            _buildSinglePickRow(pick, compact: compact),
            if (!isLast) ...[
              const SizedBox(height: 8),
              Container(
                height: 1,
                color: Colors.grey[600],
                margin: const EdgeInsets.symmetric(horizontal: 20),
              ),
              const SizedBox(height: 8),
            ],
          ],
        );
      }).toList(),
    );
  }

  Widget _buildSinglePickRow(Pick pick, {required bool compact}) {
    final selectedTeam = _getSelectedTeam(pick);
    final awayTeam = pick.game.awayTeam;
    final homeTeam = pick.game.homeTeam;
    
    return Row(
      children: [
        // Away Team
        Expanded(
          child: _buildTeamSection(
            teamName: awayTeam,
            isSelected: selectedTeam == awayTeam,
            compact: compact,
            pick: selectedTeam == awayTeam ? pick : null,
          ),
        ),
        
        // VS section
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Column(
            children: [
              Text(
                'VS',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: compact ? 10 : 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (!compact) ...[
                const SizedBox(height: 2),
                Text(
                  pick.game.sport.toUpperCase(),
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 8,
                  ),
                ),
              ],
            ],
          ),
        ),
        
        // Home Team
        Expanded(
          child: _buildTeamSection(
            teamName: homeTeam,
            isSelected: selectedTeam == homeTeam,
            compact: compact,
            pick: selectedTeam == homeTeam ? pick : null,
          ),
        ),
      ],
    );
  }

  Widget _buildTeamSection({
    required String teamName,
    required bool isSelected,
    required bool compact,
    Pick? pick,
  }) {
    final logoPath = TeamLogoUtils.getTeamLogo(teamName);
    
    return Container(
      padding: EdgeInsets.all(compact ? 6 : 8),
      decoration: BoxDecoration(
        color: isSelected ? Colors.grey[700] : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: isSelected ? Border.all(color: Colors.grey[600]!) : null,
      ),
      child: Column(
        children: [
          // Team Logo
          Container(
            width: compact ? 32 : 40,
            height: compact ? 32 : 40,
            decoration: BoxDecoration(
              color: Colors.grey[700],
              borderRadius: BorderRadius.circular(6),
            ),
            child: logoPath != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.asset(
                      logoPath,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Center(
                          child: Text(
                            teamName.split(' ').last[0],
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: compact ? 12 : 16,
                              fontWeight: FontWeight.normal,
                            ),
                          ),
                        );
                      },
                    ),
                  )
                : Center(
                    child: Text(
                      teamName.split(' ').last[0],
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: compact ? 12 : 16,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                  ),
          ),
          
          const SizedBox(height: 6),
          
          // Team Name
          Text(
            teamName,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey[300],
              fontSize: compact ? 9 : 11,
              fontWeight: FontWeight.normal,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          
          // Selection indicator with bet type and odds
          if (isSelected && pick != null) ...[
            const SizedBox(height: 4),
            Text(
              '${_getBetTypeText(pick)} ${pick.odds}',
              style: TextStyle(
                color: Colors.white,
                fontSize: compact ? 8 : 10,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _getSelectedTeam(Pick pick) {
    switch (pick.pickType) {
      case PickType.moneyline:
        return pick.pickSide == PickSide.home 
            ? pick.game.homeTeam 
            : pick.game.awayTeam;
      case PickType.spread:
        return pick.pickSide == PickSide.home 
            ? pick.game.homeTeam 
            : pick.game.awayTeam;
      case PickType.total:
        return ''; // No specific team for totals
      case PickType.playerProp:
        return pick.playerName ?? ''; // Player name for props
    }
  }

  String _getBetTypeText(Pick pick) {
    switch (pick.pickType) {
      case PickType.moneyline:
        return 'ML';
      case PickType.spread:
        return 'SPREAD';
      case PickType.total:
        return pick.pickSide == PickSide.over ? 'OVER' : 'UNDER';
      case PickType.playerProp:
        return 'PROP';
    }
  }

  IconData _getSportIcon(String sport) {
    switch (sport.toLowerCase()) {
      case 'nfl':
        return Icons.sports_football;
      case 'nba':
        return Icons.sports_basketball;
      case 'mlb':
        return Icons.sports_baseball;
      case 'nhl':
        return Icons.sports_hockey;
      case 'soccer':
        return Icons.sports_soccer;
      default:
        return Icons.sports;
    }
  }

  String? _getParlayOdds(List<Pick> picks) {
    if (picks.length < 2) return null;
    
    double product = 1.0;
    for (var pick in picks) {
      double decimal = _americanToDecimal(pick.odds);
      product *= decimal;
    }
    return _decimalToAmerican(product);
  }

  double _americanToDecimal(String oddsStr) {
    int odds = int.tryParse(oddsStr) ?? 0;
    if (odds > 0) {
      return (odds / 100) + 1;
    } else {
      return 1 + (100 / -odds);
    }
  }

  String _decimalToAmerican(double dec) {
    if (dec >= 2) {
      return '+${((dec - 1) * 100).round()}';
    } else {
      return '-${(100 / (dec - 1)).round()}';
    }
  }
} 