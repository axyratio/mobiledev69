import '../utils/api_client.dart';

class Backend2Service {
  final String _resource = '/data'; // เปลี่ยนเป็น Endpoint ที่ต้องการ

  // Get All
  Future<List<dynamic>> getAllData() async {
    try {
      final response = await ApiClient.get(_resource);
      return response as List<dynamic>;
    } catch (e) {
      throw Exception('Failed to get all data: $e');
    }
  }

  // Get by ID
  Future<dynamic> getDataById(int id) async {
    try {
      final response = await ApiClient.get('$_resource/$id');
      return response;
    } catch (e) {
      throw Exception('Failed to get data $id: $e');
    }
  }

  // Create
  Future<dynamic> createData(Map<String, dynamic> data) async {
    return await ApiClient.post(_resource, data);
  }

  // Update
  Future<dynamic> updateData(int id, Map<String, dynamic> data) async {
    return await ApiClient.put('$_resource/$id', data);
  }

  // Delete
  Future<dynamic> deleteData(int id) async {
    return await ApiClient.delete('$_resource/$id');
  }
}