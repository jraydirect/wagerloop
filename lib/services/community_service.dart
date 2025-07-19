// lib/services/community_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/community.dart';
import 'dart:convert';
import 'dart:math' as math;

/// Manages community functionality for WagerLoop.
/// 
/// Handles community creation, searching, joining/leaving, and member management.
/// Integrates with Supabase for real-time community updates.
class CommunityService {
  final SupabaseClient _supabase;

  CommunityService(this._supabase);

  /// Creates a new community
  /// 
  /// Parameters:
  ///   - name: Community name
  ///   - description: Community description
  ///   - isPrivate: Whether the community is private
  ///   - sport: Optional sport association
  ///   - tags: List of tags for the community
  ///   - imageUrl: Optional community image
  /// 
  /// Returns: Created Community object
  /// 
  /// Throws: Exception if creation fails or user not authenticated
  Future<Community> createCommunity({
    required String name,
    required String description,
    bool isPrivate = false,
    String? sport,
    List<String> tags = const [],
    String? imageUrl,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    // Get user profile for creator info
    final profile = await _supabase
        .from('profiles')
        .select('username, avatar_url')
        .eq('id', user.id)
        .single();

    final communityData = {
      'name': name,
      'description': description,
      'creator_id': user.id,
      'creator_username': profile['username'] ?? 'Unknown',
      'creator_avatar_url': profile['avatar_url'],
      'is_private': isPrivate,
      'sport': sport,
      'tags': tags,
      'image_url': imageUrl,
      'member_count': 1,
      'created_at': DateTime.now().toIso8601String(),
    };

    final response = await _supabase
        .from('communities')
        .insert(communityData)
        .select()
        .single();

    // Add creator as first member
    await _supabase.from('community_members').insert({
      'community_id': response['id'],
      'user_id': user.id,
      'joined_at': DateTime.now().toIso8601String(),
      'role': 'owner',
    });

    return Community.fromJson({...response, 'is_joined': true});
  }

  /// Searches communities based on query
  /// 
  /// Parameters:
  ///   - query: Search term for community name or description
  ///   - sport: Optional sport filter
  ///   - limit: Maximum number of results
  ///   - offset: Offset for pagination
  /// 
  /// Returns: List of matching communities with join status
  Future<List<Community>> searchCommunities({
    String? query,
    String? sport,
    int limit = 20,
    int offset = 0,
  }) async {
    final user = _supabase.auth.currentUser;
    
    // Execute different queries based on filters
    List<dynamic> response;
    
    if (query != null && query.isNotEmpty && sport != null && sport.isNotEmpty) {
      // Both name and sport filter
      response = await _supabase
          .from('communities')
          .select('*')
          .eq('is_private', false)
          .ilike('name', '%$query%')
          .eq('sport', sport)
          .order('member_count', ascending: false)
          .limit(limit)
          .range(offset, offset + limit - 1);
    } else if (query != null && query.isNotEmpty) {
      // Name filter only
      response = await _supabase
          .from('communities')
          .select('*')
          .eq('is_private', false)
          .ilike('name', '%$query%')
          .order('member_count', ascending: false)
          .limit(limit)
          .range(offset, offset + limit - 1);
    } else if (sport != null && sport.isNotEmpty) {
      // Sport filter only
      response = await _supabase
          .from('communities')
          .select('*')
          .eq('is_private', false)
          .eq('sport', sport)
          .order('member_count', ascending: false)
          .limit(limit)
          .range(offset, offset + limit - 1);
    } else {
      // No filters
      response = await _supabase
          .from('communities')
          .select('*')
          .eq('is_private', false)
          .order('member_count', ascending: false)
          .limit(limit)
          .range(offset, offset + limit - 1);
    }
    
    // Check which communities the user has joined
    List<String> joinedCommunityIds = [];
    if (user != null) {
      final joinedResponse = await _supabase
          .from('community_members')
          .select('community_id')
          .eq('user_id', user.id);
      
      joinedCommunityIds = joinedResponse
          .map<String>((item) => item['community_id'] as String)
          .toList();
    }

    return response.map<Community>((data) {
      return Community.fromJson({
        ...data,
        'is_joined': joinedCommunityIds.contains(data['id']),
      });
    }).toList();
  }

  /// Gets communities the current user has joined
  /// 
  /// Parameters:
  ///   - limit: Maximum number of communities to return
  ///   - offset: Offset for pagination
  /// 
  /// Returns: List of joined communities
  Future<List<Community>> getJoinedCommunities({
    int limit = 20,
    int offset = 0,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final response = await _supabase
        .from('community_members')
        .select('''
          communities (*)
        ''')
        .eq('user_id', user.id)
        .order('joined_at', ascending: false)
        .limit(limit)
        .range(offset, offset + limit - 1);

    return response
        .where((item) => item['communities'] != null)
        .map<Community>((item) => Community.fromJson({
          ...item['communities'],
          'is_joined': true,
        }))
        .toList();
  }

  /// Gets popular/trending communities
  /// 
  /// Parameters:
  ///   - limit: Maximum number of communities to return
  /// 
  /// Returns: List of popular communities
  Future<List<Community>> getPopularCommunities({int limit = 10}) async {
    final user = _supabase.auth.currentUser;
    
    final response = await _supabase
        .from('communities')
        .select('*')
        .eq('is_private', false)
        .order('member_count', ascending: false)
        .limit(limit);

    // Check which communities the user has joined
    List<String> joinedCommunityIds = [];
    if (user != null) {
      final joinedResponse = await _supabase
          .from('community_members')
          .select('community_id')
          .eq('user_id', user.id);
      
      joinedCommunityIds = joinedResponse
          .map<String>((item) => item['community_id'] as String)
          .toList();
    }

    return response.map<Community>((data) {
      return Community.fromJson({
        ...data,
        'is_joined': joinedCommunityIds.contains(data['id']),
      });
    }).toList();
  }

  /// Joins a community
  /// 
  /// Parameters:
  ///   - communityId: ID of the community to join
  /// 
  /// Returns: Updated Community object
  /// 
  /// Throws: Exception if join fails or user already joined
  Future<Community> joinCommunity(String communityId) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    // Check if already a member
    final existingMember = await _supabase
        .from('community_members')
        .select()
        .eq('community_id', communityId)
        .eq('user_id', user.id)
        .maybeSingle();

    if (existingMember != null) {
      throw Exception('Already a member of this community');
    }

    // Add user to community
    await _supabase.from('community_members').insert({
      'community_id': communityId,
      'user_id': user.id,
      'joined_at': DateTime.now().toIso8601String(),
      'role': 'member',
    });

    // Update member count manually for now
    final currentCommunity = await _supabase
        .from('communities')
        .select('member_count')
        .eq('id', communityId)
        .single();
    
    await _supabase
        .from('communities')
        .update({'member_count': ((currentCommunity['member_count'] as int?) ?? 0) + 1})
        .eq('id', communityId);

    // Return updated community
    final response = await _supabase
        .from('communities')
        .select('*')
        .eq('id', communityId)
        .single();

    return Community.fromJson({...response, 'is_joined': true});
  }

  /// Leaves a community
  /// 
  /// Parameters:
  ///   - communityId: ID of the community to leave
  /// 
  /// Returns: Updated Community object
  /// 
  /// Throws: Exception if leave fails or user not a member
  Future<Community> leaveCommunity(String communityId) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    // Check if user is the owner
    final community = await _supabase
        .from('communities')
        .select('creator_id')
        .eq('id', communityId)
        .single();

    if (community['creator_id'] == user.id) {
      throw Exception('Cannot leave a community you created');
    }

    // Remove user from community
    final deleteResponse = await _supabase
        .from('community_members')
        .delete()
        .eq('community_id', communityId)
        .eq('user_id', user.id);

    // Update member count manually for now
    final currentCommunity = await _supabase
        .from('communities')
        .select('member_count')
        .eq('id', communityId)
        .single();
    
    await _supabase
        .from('communities')
        .update({'member_count': math.max(0, ((currentCommunity['member_count'] as int?) ?? 1) - 1)})
        .eq('id', communityId);

    // Return updated community
    final response = await _supabase
        .from('communities')
        .select('*')
        .eq('id', communityId)
        .single();

    return Community.fromJson({...response, 'is_joined': false});
  }

  /// Gets community details by ID
  /// 
  /// Parameters:
  ///   - communityId: ID of the community
  /// 
  /// Returns: Community object with join status
  Future<Community> getCommunityById(String communityId) async {
    final user = _supabase.auth.currentUser;
    
    final response = await _supabase
        .from('communities')
        .select('*')
        .eq('id', communityId)
        .single();

    bool isJoined = false;
    if (user != null) {
      final member = await _supabase
          .from('community_members')
          .select()
          .eq('community_id', communityId)
          .eq('user_id', user.id)
          .maybeSingle();
      
      isJoined = member != null;
    }

    return Community.fromJson({...response, 'is_joined': isJoined});
  }

  /// Gets community members
  /// 
  /// Parameters:
  ///   - communityId: ID of the community
  ///   - limit: Maximum number of members to return
  ///   - offset: Offset for pagination
  /// 
  /// Returns: List of member profiles
  Future<List<Map<String, dynamic>>> getCommunityMembers({
    required String communityId,
    int limit = 20,
    int offset = 0,
  }) async {
    final response = await _supabase
        .from('community_members')
        .select('''
          role,
          joined_at,
          profiles (
            id,
            username,
            avatar_url
          )
        ''')
        .eq('community_id', communityId)
        .order('joined_at', ascending: false)
        .limit(limit)
        .range(offset, offset + limit - 1);

    return response.map<Map<String, dynamic>>((item) => {
      'role': item['role'],
      'joined_at': item['joined_at'],
      'user': item['profiles'],
    }).toList();
  }

  /// Gets communities by sport
  /// 
  /// Parameters:
  ///   - sport: Sport to filter by (NFL, NBA, MLB, NHL, etc.)
  ///   - limit: Maximum number of communities
  /// 
  /// Returns: List of communities for the specified sport
  Future<List<Community>> getCommunitiesBySport({
    required String sport,
    int limit = 20,
  }) async {
    final user = _supabase.auth.currentUser;
    
    final response = await _supabase
        .from('communities')
        .select('*')
        .eq('sport', sport)
        .eq('is_private', false)
        .order('member_count', ascending: false)
        .limit(limit);

    // Check which communities the user has joined
    List<String> joinedCommunityIds = [];
    if (user != null) {
      final joinedResponse = await _supabase
          .from('community_members')
          .select('community_id')
          .eq('user_id', user.id);
      
      joinedCommunityIds = joinedResponse
          .map<String>((item) => item['community_id'] as String)
          .toList();
    }

    return response.map<Community>((data) {
      return Community.fromJson({
        ...data,
        'is_joined': joinedCommunityIds.contains(data['id']),
      });
    }).toList();
  }
} 