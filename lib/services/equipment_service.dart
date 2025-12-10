import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/equipment_item.dart';

class EquipmentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'equipment';

  // Add new equipment
  Future<String> addEquipment(EquipmentItem item) async {
    try {
      final docRef = await _firestore.collection(_collection).add(item.toMap());
      await _firestore.collection(_collection).doc(docRef.id).update({
        'id': docRef.id,
      });
      return docRef.id;
    } catch (e) {
      throw 'Error adding equipment: ${e.toString()}';
    }
  }

  // Update equipment
  Future<void> updateEquipment(EquipmentItem item) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(item.id)
          .update(item.copyWith(updatedAt: DateTime.now()).toMap());
    } catch (e) {
      throw 'Error updating equipment: ${e.toString()}';
    }
  }

  // Delete equipment
  Future<void> deleteEquipment(String itemId) async {
    try {
      await _firestore.collection(_collection).doc(itemId).delete();
    } catch (e) {
      throw 'Error deleting equipment: ${e.toString()}';
    }
  }

  // Get equipment by ID
  Future<EquipmentItem?> getEquipmentById(String itemId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(itemId).get();
      if (doc.exists) {
        return EquipmentItem.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      throw 'Error fetching equipment: ${e.toString()}';
    }
  }

  // Get all equipment stream
  Stream<List<EquipmentItem>> getAllEquipmentStream() {
    return _firestore
        .collection(_collection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => EquipmentItem.fromMap(doc.data()))
              .toList(),
        );
  }

  // Get available equipment stream
  Stream<List<EquipmentItem>> getAvailableEquipmentStream() {
    return _firestore
        .collection(_collection)
        .where('status', isEqualTo: ItemStatus.available.name)
        .snapshots()
        .map((snapshot) {
          final items = snapshot.docs
              .map((doc) => EquipmentItem.fromMap(doc.data()))
              .toList();
          items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return items;
        });
  }

  // Get equipment by owner
  Stream<List<EquipmentItem>> getEquipmentByOwner(String ownerId) {
    return _firestore
        .collection(_collection)
        .where('ownerId', isEqualTo: ownerId)
        .snapshots()
        .map((snapshot) {
          final items = snapshot.docs
              .map((doc) => EquipmentItem.fromMap(doc.data()))
              .toList();
          items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return items;
        });
  }

  // Search equipment
  Future<List<EquipmentItem>> searchEquipment(String query) async {
    try {
      final snapshot = await _firestore.collection(_collection).get();
      final allItems = snapshot.docs
          .map((doc) => EquipmentItem.fromMap(doc.data()))
          .toList();

      return allItems.where((item) {
        final searchLower = query.toLowerCase();
        return item.name.toLowerCase().contains(searchLower) ||
            item.description.toLowerCase().contains(searchLower) ||
            item.type.displayName.toLowerCase().contains(searchLower) ||
            item.tags.any((tag) => tag.toLowerCase().contains(searchLower));
      }).toList();
    } catch (e) {
      throw 'Error searching equipment: ${e.toString()}';
    }
  }

  // Filter equipment by type
  Stream<List<EquipmentItem>> filterByType(EquipmentType type) {
    return _firestore
        .collection(_collection)
        .where('type', isEqualTo: type.name)
        .snapshots()
        .map((snapshot) {
          final items = snapshot.docs
              .map((doc) => EquipmentItem.fromMap(doc.data()))
              .toList();
          items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return items;
        });
  }

  // Filter equipment by status
  Stream<List<EquipmentItem>> filterByStatus(ItemStatus status) {
    return _firestore
        .collection(_collection)
        .where('status', isEqualTo: status.name)
        .snapshots()
        .map((snapshot) {
          final items = snapshot.docs
              .map((doc) => EquipmentItem.fromMap(doc.data()))
              .toList();
          items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return items;
        });
  }

  // Get donated items
  Stream<List<EquipmentItem>> getDonatedItems() {
    return _firestore
        .collection(_collection)
        .where('isDonated', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
          final items = snapshot.docs
              .map((doc) => EquipmentItem.fromMap(doc.data()))
              .toList();
          items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return items;
        });
  }

  // Update item status
  Future<void> updateItemStatus(String itemId, ItemStatus status) async {
    try {
      await _firestore.collection(_collection).doc(itemId).update({
        'status': status.name,
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      throw 'Error updating item status: ${e.toString()}';
    }
  }

  // Get equipment count by status
  Future<Map<ItemStatus, int>> getEquipmentCountByStatus() async {
    try {
      final snapshot = await _firestore.collection(_collection).get();
      final counts = <ItemStatus, int>{};

      for (var status in ItemStatus.values) {
        counts[status] = 0;
      }

      for (var doc in snapshot.docs) {
        final item = EquipmentItem.fromMap(doc.data());
        counts[item.status] = (counts[item.status] ?? 0) + 1;
      }

      return counts;
    } catch (e) {
      throw 'Error getting equipment counts: ${e.toString()}';
    }
  }
}
