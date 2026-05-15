import 'dart:collection';
import 'dart:convert';

import 'package:amazic_ads_flutter/admob.dart';
import 'package:amazic_ads_flutter/call_api/ads_model.dart';
import 'package:amazic_ads_flutter/utils/event_log.dart';
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
    required String linkServer,
    required String appId,
    required String packageName,
    required Function() onResponse,
    required Function(String) onError,
  }) async {
    var time = DateTime.now().second;
    print('admob_ads --- call id: time = ${time}');

    var isSetId = false;
    Future.delayed(const Duration(seconds: 4), () {
      print('admob_ads --- timeout call id ads');
      if (!isSetId) {
        isSetId = true;
        EventLog.logEvent('splash_jsonid_ad_default', parameters: {'error': 'time out 4s'});
        print(
          'admob_ads --- splash_jsonid_ad_default - json_id_timeout: ${Admob.instance.jsonIdAdsDefault}',
        );

        convertJsonIdToList(json: Admob.instance.jsonIdAdsDefault);

        onResponse.call();
      }
    });

    /// http://language-master.top/api/getidv2/ca-app-pub-4973559944609228~2346710863+com.example.lib
    var url = linkServer != '' && appId != ''
        ? Uri.parse('$linkServer/api/getidv2/$appId+$packageName')
        : Uri.parse(
            'http://language-master.top/api/getidv2/ca-app-pub-4973559944609228~2346710863',
          );
    try {
      var response = await http.get(url);
      if (response.statusCode == 200) {
        if (!isSetId) {
          isSetId = true;
          EventLog.logEvent('splash_jsonid_ad_normal');
          var seconds = DateTime.now().second - time;
          print('admob_ads --- call id: time2 = ${DateTime.now().second}');
          print(
            'admob_ads --- splash_jsonid_ad_normal - second = $seconds - json_id: ${response.body}',
          );
          convertJsonIdToList(json: response.body);

          onResponse.call();
        }
      } else if (response.statusCode == 404) {
        if (!isSetId) {
          isSetId = true;
          EventLog.logEvent('splash_jsonid_ad_default', parameters: {'error': '404'});
          print(
            'admob_ads --- splash_jsonid_ad_default - json_id1: ${Admob.instance.jsonIdAdsDefault}',
          );

          convertJsonIdToList(json: Admob.instance.jsonIdAdsDefault);

          onResponse.call();
        }
      } else {
        if (!isSetId) {
          isSetId = true;
          EventLog.logEvent('splash_jsonid_ad_default', parameters: {'error': 'not get id'});
          print(
            'admob_ads --- splash_jsonid_ad_default - json_id2: ${Admob.instance.jsonIdAdsDefault}',
          );

          convertJsonIdToList(json: Admob.instance.jsonIdAdsDefault);

          onResponse.call();
        }
      }
    } catch (e) {
      if (!isSetId) {
        isSetId = true;
        EventLog.logEvent('splash_jsonid_ad_default', parameters: {'error': e.toString()});
        print(
          'admob_ads --- splash_jsonid_ad_default - json_id3: ${Admob.instance.jsonIdAdsDefault}',
        );

        convertJsonIdToList(json: Admob.instance.jsonIdAdsDefault);

        onResponse.call();
      }
    }
  }

  Future<void> convertJsonIdToList({required String json}) async {
    List<AdsModel> listAds = await compute(parseAdsModel, json);

    for (final model in listAds) {
      if (model.name != null) {
        // Khởi tạo danh sách nếu chưa tồn tại
        listAdsId.putIfAbsent(model.name!, () => []);

        if (model.adsId != null) {
          listAdsId[model.name!]!.add(model.adsId!);
        }
      }
    }
  }

  List<String> getListIDByName(String nameAds) {
    List<String> listId = [];
    if (listAdsId[nameAds] != null) {
      listId.addAll(listAdsId[nameAds]!);
    }
    return listId;
  }

  String getFirstIDByName(String nameAds) {
    final list = getListIDByName(nameAds);
    if (list.isNotEmpty) {
      return list.first;
    }
    return '';
  }
}
