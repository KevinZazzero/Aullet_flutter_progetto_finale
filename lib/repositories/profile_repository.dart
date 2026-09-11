import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/profile.dart';

class ProfileRepository {
  final _client = Supabase.instance.client;

  Future<Profile?> fetchProfile(String userId) async {
    final data = await _client
        .from('profiles')
        .select()
        .eq('user_id', userId)
        .maybeSingle();

    if (data == null) return null;
    return Profile.fromMap(data as Map<String, dynamic>);
  }

  Future<void> createProfile(Profile profile) async {
    await _client
        .from('profiles')
        .insert(profile.toMap());
  }

  Future<void> updateProfile(Profile profile) async {
    await _client
        .from('profiles')
        .update(profile.toMap())
        .eq('user_id', profile.userId);
  }
}