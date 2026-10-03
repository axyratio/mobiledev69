import '../utils/api_client.dart';

class Backend1Service {
  final String _resource = '/items'; // ตั้งค่า Endpoint หลัก

  // Get All
  Future<List<dynamic>> getAllItems() async {
    try {
      final response = await ApiClient.get(_resource);
      return response as List<dynamic>;
    } catch (e) {
      throw Exception('Failed to get all items: $e');
    }
  }

  // Get by ID
  Future<dynamic> getItemById(int id) async {
    try {
      final response = await ApiClient.get('$_resource/$id');
      return response;
    } catch (e) {
      throw Exception('Failed to get item $id: $e');
    }
  }

  // Create
  Future<dynamic> createItem(Map<String, dynamic> data) async {
    return await ApiClient.post(_resource, data);
  }

  // Update
  Future<dynamic> updateItem(int id, Map<String, dynamic> data) async {
    return await ApiClient.put('$_resource/$id', data);
  }

  // Delete
  Future<dynamic> deleteItem(int id) async {
    return await ApiClient.delete('$_resource/$id');
  }
}