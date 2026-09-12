import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../../../core/errors/error_handler.dart';
import '../../../data/models/app_user.dart';
import '../../../data/models/contact_request.dart';
import '../../../data/repositories/contact_repository.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../home/controllers/home_controller.dart';

class ContactsController extends GetxController {
  final ContactRepository _contactRepository;
  final AuthRepository? _authRepository;

  ContactsController(
    this._contactRepository, [
    this._authRepository,
  ]);

  final RxList<AppUser> contacts = <AppUser>[].obs;
  final RxList<ContactRequest> incomingRequests = <ContactRequest>[].obs;
  final RxList<ContactRequest> sentRequests = <ContactRequest>[].obs;
  final RxList<UserSearchResult> searchResults = <UserSearchResult>[].obs;

  final RxBool isLoading = true.obs;
  final RxBool isSearching = false.obs;
  final RxBool isActionLoading = false.obs;
  final RxString errorMessage = ''.obs;
  final RxString searchQuery = ''.obs;

  String _currentUserId = '';

  @override
  void onInit() {
    super.onInit();
    loadData();
    debounce(
      searchQuery,
      _performSearch,
      time: const Duration(milliseconds: 300),
    );
  }

  Future<String> _getUid() async {
    if (_currentUserId.isNotEmpty && _currentUserId != 'user_current') {
      return _currentUserId;
    }
    if (Get.isRegistered<HomeController>()) {
      final homeUser = Get.find<HomeController>().currentUser.value;
      if (homeUser.id.isNotEmpty && homeUser.id != 'user_current') {
        _currentUserId = homeUser.id;
        return _currentUserId;
      }
    }
    final authRepo = _authRepository ??
        (Get.isRegistered<AuthRepository>()
            ? Get.find<AuthRepository>()
            : null);
    if (authRepo != null) {
      final cur = await authRepo.getCurrentUser();
      if (cur != null && cur.id.isNotEmpty) {
        _currentUserId = cur.id;
        return _currentUserId;
      }
    }
    return 'user_current';
  }

  Future<void> loadUsers() => loadData();

  Future<void> loadData() async {
    isLoading.value = true;
    errorMessage.value = '';

    try {
      final uid = await _getUid();

      final results = await Future.wait([
        _contactRepository.getContacts(uid),
        _contactRepository.getIncomingRequests(uid),
        _contactRepository.getSentRequests(uid),
      ]);

      contacts.value = results[0] as List<AppUser>;
      incomingRequests.value = results[1] as List<ContactRequest>;
      sentRequests.value = results[2] as List<ContactRequest>;
    } catch (e) {
      debugPrint('ContactsController.loadData error: $e');
      errorMessage.value = ErrorHandler.getUserMessage(e);
    } finally {
      isLoading.value = false;
    }
  }

  void onSearchChanged(String query) {
    searchQuery.value = query;
  }

  Future<void> _performSearch(String query) async {
    final q = query.trim();
    if (q.isEmpty) {
      searchResults.clear();
      isSearching.value = false;
      return;
    }

    isSearching.value = true;
    try {
      final uid = await _getUid();
      final results = await _contactRepository.searchUsersByEmail(uid, q);
      searchResults.value = results;
    } catch (e) {
      debugPrint('ContactsController._performSearch error: $e');
      searchResults.clear();
    } finally {
      isSearching.value = false;
    }
  }

  Future<void> sendContactRequest(AppUser targetUser) async {
    isActionLoading.value = true;
    try {
      final uid = await _getUid();
      final req = await _contactRepository.sendRequest(
        senderId: uid,
        receiverId: targetUser.id,
      );

      // Update search result immediately in-place
      final idx = searchResults.indexWhere((r) => r.user.id == targetUser.id);
      if (idx != -1) {
        searchResults[idx] = searchResults[idx].copyWith(
          relationship: UserRelationship.requestSent,
          requestId: req.id,
        );
      }

      sentRequests.add(req.copyWith(receiver: targetUser));

      _showSnackbar(
        'Request Sent',
        'Contact request sent to ${targetUser.name}',
      );
    } catch (e) {
      debugPrint('ContactsController.sendContactRequest error: $e');
      _showSnackbar('Action Failed', 'Could not send request: $e');
    } finally {
      isActionLoading.value = false;
    }
  }

  Future<void> acceptContactRequest(ContactRequest request) async {
    isActionLoading.value = true;
    try {
      await _contactRepository.acceptRequest(request.id);

      incomingRequests.removeWhere((r) => r.id == request.id);

      // Add sender to contacts list
      if (request.sender != null) {
        contacts.removeWhere((c) => c.id == request.sender!.id);
        contacts.insert(0, request.sender!);
      }

      // Update search result if active
      final idx =
          searchResults.indexWhere((r) => r.user.id == request.senderId);
      if (idx != -1) {
        searchResults[idx] = searchResults[idx].copyWith(
          relationship: UserRelationship.connected,
        );
      }

      // Sync with HomeController favorites
      if (Get.isRegistered<HomeController>()) {
        Get.find<HomeController>().loadData();
      }

      _showSnackbar(
        'Contact Added',
        '${request.sender?.name ?? 'User'} is now your contact. You can now call each other securely.',
        duration: const Duration(seconds: 3),
      );
    } catch (e) {
      debugPrint('ContactsController.acceptContactRequest error: $e');
      _showSnackbar('Action Failed', 'Could not accept request: $e');
    } finally {
      isActionLoading.value = false;
    }
  }

  Future<void> declineContactRequest(String requestId) async {
    isActionLoading.value = true;
    try {
      await _contactRepository.declineOrCancelRequest(requestId);
      incomingRequests.removeWhere((r) => r.id == requestId);

      _showSnackbar(
        'Request Declined',
        'Contact request has been removed',
      );
    } catch (e) {
      debugPrint('ContactsController.declineContactRequest error: $e');
    } finally {
      isActionLoading.value = false;
    }
  }

  Future<void> cancelSentRequest(String requestId, String targetUserId) async {
    isActionLoading.value = true;
    try {
      await _contactRepository.declineOrCancelRequest(requestId);
      sentRequests.removeWhere((r) => r.id == requestId);

      final idx = searchResults.indexWhere((r) => r.user.id == targetUserId);
      if (idx != -1) {
        searchResults[idx] = searchResults[idx].copyWith(
          relationship: UserRelationship.none,
          requestId: null,
        );
      }

      _showSnackbar(
        'Request Cancelled',
        'Contact request cancelled',
      );
    } catch (e) {
      debugPrint('ContactsController.cancelSentRequest error: $e');
    } finally {
      isActionLoading.value = false;
    }
  }

  Future<void> removeContact(AppUser user) async {
    isActionLoading.value = true;
    try {
      final uid = await _getUid();
      await _contactRepository.removeContact(
        currentUserId: uid,
        contactUserId: user.id,
      );

      contacts.removeWhere((c) => c.id == user.id);

      final idx = searchResults.indexWhere((r) => r.user.id == user.id);
      if (idx != -1) {
        searchResults[idx] = searchResults[idx].copyWith(
          relationship: UserRelationship.none,
        );
      }

      if (Get.isRegistered<HomeController>()) {
        Get.find<HomeController>().loadData();
      }

      _showSnackbar(
        'Contact Removed',
        '${user.name} removed from your contacts',
      );
    } catch (e) {
      debugPrint('ContactsController.removeContact error: $e');
    } finally {
      isActionLoading.value = false;
    }
  }

  void _showSnackbar(String title, String message, {Duration? duration}) {
    try {
      if (Get.context != null) {
        Get.snackbar(
          title,
          message,
          snackPosition: SnackPosition.BOTTOM,
          duration: duration ?? const Duration(seconds: 2),
        );
      }
    } catch (_) {}
  }
}
