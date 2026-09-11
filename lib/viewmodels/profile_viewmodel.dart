import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/profile.dart';
import '../repositories/profile_repository.dart';
import 'package:image_picker/image_picker.dart';

class ProfileViewModel extends ChangeNotifier {
  final _repo = ProfileRepository();
  Profile? _profile;
  bool _isLoading = false;
  String? _error;

  Profile? get profile => _profile;
  bool get isLoading => _isLoading;
  String? get errorMessage => _error;

  Future<void> updateDisplayName(String newName) async {
    _setLoading(true);
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        String? currentAvatar = _profile?.avatarUrl;
        
        final updatedProfile = Profile(
          id: user.id,
          userId: user.id,
          displayName: newName,
          avatarUrl: currentAvatar,
        );

        await Supabase.instance.client.from('profiles').upsert(updatedProfile.toMap());
        
        _profile = await _repo.fetchProfile(user.id);
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> pickAndUploadAvatar() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    
    if (image == null) return; 

    _setLoading(true);
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        final String path = '${user.id}.jpg';
        final bytes = await image.readAsBytes();

        await Supabase.instance.client.storage.from('avatars').uploadBinary(
          path,
          bytes,
          fileOptions: const FileOptions(upsert: true),
        );

        final String imageUrl = Supabase.instance.client.storage
            .from('avatars')
            .getPublicUrl(path);

        String currentName = _profile?.displayName ?? user.email!.split('@')[0];

        final updatedProfile = Profile(
          id: user.id,
          userId: user.id,
          displayName: currentName,
          avatarUrl: imageUrl,
        );

        await Supabase.instance.client.from('profiles').upsert(updatedProfile.toMap());
        
        _profile = await _repo.fetchProfile(user.id);
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadProfile() async {
    _setLoading(true);
    try {
      final user = Supabase.instance.client.auth.currentUser!;
      _profile = await _repo.fetchProfile(user.id);
      
      if (_profile == null) {
        final user = Supabase.instance.client.auth.currentUser;
        if (user != null) {
          _profile = Profile(
            id: user.id,
            userId: user.id,
            displayName: user.email!.split('@')[0],
          );
          await _repo.createProfile(_profile!);
          _profile = await _repo.fetchProfile(user.id);
        }
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}