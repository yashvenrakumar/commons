import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/constants/app_constants.dart';
import '../../../core/network/retry.dart';

class ReqresApi {
  ReqresApi(this._client);
  final http.Client _client;

  static const _base = 'https://reqres.in/api/collections/demo/records';

  Map<String, String> get _headers => <String, String>{
        'x-api-key': AppConstants.reqresApiKey,
        'X-Reqres-Env': AppConstants.reqresEnv,
        'Content-Type': 'application/json',
      };

  Future<ReqresUsersPage> fetchUsers({
    required int page,
    void Function(int attempt, Duration nextDelay)? onRetry,
  }) async {
    final uri = Uri.parse(_base).replace(
      queryParameters: <String, String>{
        'project_id': '${AppConstants.reqresProjectId}',
        'page': '$page',
        'limit': '10',
      },
    );
    final resp =
        await getWithRetry(_client, uri, headers: _headers, onRetry: onRetry);
    if (resp.statusCode != 200) {
      throw http.ClientException('Failed to fetch users', uri);
    }
    final jsonMap = json.decode(resp.body) as Map<String, dynamic>;
    return ReqresUsersPage.fromJson(jsonMap);
  }

  Future<int> createUser({required String name, required String job}) async {
    final firstName = name.trim().isEmpty ? 'Unknown' : name.trim();
    final lastName = job.trim().isEmpty ? 'N/A' : job.trim();
    final uri = Uri.parse(_base).replace(
      queryParameters: <String, String>{
        'project_id': '${AppConstants.reqresProjectId}',
      },
    );
    final resp = await _client
        .post(
          uri,
          headers: _headers,
          body: json.encode(
            <String, dynamic>{
              'data': <String, dynamic>{
                'avatar': 'https://i.pravatar.cc/150?img=4',
                'firstName': firstName,
                'lastName': lastName,
              },
            },
          ),
        )
        .timeout(const Duration(seconds: 12));
    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      throw http.ClientException('Failed to create user', uri);
    }
    final jsonMap = json.decode(resp.body) as Map<String, dynamic>;
    final rec =
        (jsonMap['data'] as Map<String, dynamic>? ?? const <String, dynamic>{});
    final idStr = (rec['id'] ?? '').toString();
    return idStr.hashCode.abs();
  }
}

class ReqresUsersPage {
  final int page;
  final int totalPages;
  final List<ReqresUser> data;

  ReqresUsersPage({required this.page, required this.totalPages, required this.data});

  factory ReqresUsersPage.fromJson(Map<String, dynamic> json) {
    final list = (json['data'] as List<dynamic>? ?? const [])
        .map((e) => ReqresUser.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
    final meta = json['meta'] as Map<String, dynamic>? ?? const <String, dynamic>{};
    final currentPage = (meta['page'] as num?)?.toInt() ?? 1;
    final pages = (meta['pages'] as num?)?.toInt() ?? 1;
    return ReqresUsersPage(
      page: currentPage,
      totalPages: pages,
      data: list,
    );
  }
}

class ReqresUser {
  final String recordId;
  final int id;
  final String firstName;
  final String lastName;
  final String avatar;

  ReqresUser({
    required this.recordId,
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.avatar,
  });

  String get fullName => '$firstName $lastName';

  factory ReqresUser.fromJson(Map<String, dynamic> json) {
    final nested = json['data'] as Map<String, dynamic>? ?? const <String, dynamic>{};
    final idStr = (json['id'] ?? '').toString();
    return ReqresUser(
      recordId: idStr,
      id: idStr.hashCode.abs(),
      firstName: (nested['firstName'] ?? '').toString(),
      lastName: (nested['lastName'] ?? '').toString(),
      avatar: (nested['avatar'] ?? '').toString(),
    );
  }
}

