import 'dart:collection';
import 'dart:convert';

import 'package:amazic_ads_flutter/call_api/ads_model.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class CallApi {
  CallApi._instance();

  static final CallApi instance = CallApi._instance();

  LinkedHashMap<String, List<String>> listAdsId = LinkedHashMap<String, List<String>>();

  List<AdsModel> parseAdsModel(String response) {
    List<dynamic> list = json.decode(response);
    List<AdsModel> listAds = list.map((e) => AdsModel.fromJson(e)).toList();
    return listAds;
  }

  Future<void> callAds({
    required String? linkServer,
    required String? appId,
    required String? packageName,
    required Function() onResponse,
    required Function(String) onError,
  }) async {
    /// http://language-master.top/api/getidv2/ca-app-pub-4973559944609228~2346710863+com.example.lib
    var url = linkServer != null && appId != null && packageName != null
        ? Uri.parse('$linkServer/api/getidv2/$appId+$packageName')
        : Uri.parse(
        'http://language-master.top/api/getidv2/ca-app-pub-4973559944609228~2346710863');
    try {
      var response = await http.get(url);
      if (response.statusCode == 200) {
        print('body: ${response.body}');
        List<AdsModel> listAds = await compute(parseAdsModel, response.body);

        for (final model in listAds) {
          if (model.name != null) {
            // Khởi tạo danh sách nếu chưa tồn tại
            listAdsId.putIfAbsent(model.name!, () => []);

            if (model.adsId != null) {
              listAdsId[model.name!]!.add(model.adsId!);
            }
          }
        }

        onResponse.call();
      } else if (response.statusCode == 404) {
        onError.call('Not Found');
        throw Exception('Not Found');
      } else {
        onError.call('Can\'t get ads id');
        throw Exception('Can\'t get ads id');
      }
    } catch (e) {
      onError.call(e.toString());
    }
  }
  List<String> getListIDByName(String nameAds) {
    List<String> listId = [];
    if (listAdsId[nameAds] != null) {
      listId.addAll(listAdsId[nameAds]!);
    }
    return listId;
  }
}
