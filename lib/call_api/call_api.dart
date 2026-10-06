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

  ///===== Debug / Test Ads (port từ IDRemoteConfigHelper.isUsingIdDebug bên
  ///Android) =====
  ///Khi true, [getFirstIDByName] LUÔN trả về AdMob Test Ad Unit ID chính
  ///thức của Google theo loại quảng cáo (dựa vào tên/prefix của nameAds),
  ///bỏ qua hoàn toàn id thật lấy được từ Firebase Remote Config / server /
  ///json default trong [listAdsId] - để tránh vô tình gọi/hiển thị quảng
  ///cáo thật trên bản test/debug. Mặc định true giống bên Android - nhớ set
  ///`CallApi.instance.isUsingIdDebug = false;` ở bản release trước khi phát
  ///hành để dùng id thật.
  bool isUsingIdDebug = true;

  static const String _nativeIdTest = 'ca-app-pub-3940256099942544/2247696110';
  static const String _interIdTest = 'ca-app-pub-3940256099942544/1033173712';
  static const String _resumeIdTest = 'ca-app-pub-3940256099942544/9257395921';
  static const String _bannerIdTest = 'ca-app-pub-3940256099942544/9214589741';
  static const String _rewardIdTest = 'ca-app-pub-3940256099942544/5224354917';
  static const String _collapseIdTest = 'ca-app-pub-3940256099942544/2014213617';

  ///Trả về Test Ad Unit ID tương ứng loại quảng cáo dựa theo prefix của
  ///[nameAds] (không phân biệt hoa/thường, có hoặc không có tiền tố "id_") -
  ///y hệt logic getID() bên Android IDRemoteConfigHelper (kể cả việc
  ///"id_open"/"open" cũng dùng chung test id với resume). Trả về null nếu
  ///không khớp loại nào.
  String? _getTestIdByName(String nameAds) {
    final key = nameAds.toLowerCase();
    if (key.startsWith('id_native') || key.startsWith('native')) return _nativeIdTest;
    if (key.startsWith('id_inter') || key.startsWith('inter')) return _interIdTest;
    if (key.startsWith('id_resume') || key.startsWith('resume')) return _resumeIdTest;
    if (key.startsWith('id_open') || key.startsWith('open')) return _resumeIdTest;
    if (key.startsWith('id_banner') || key.startsWith('banner')) return _bannerIdTest;
    if (key.startsWith('id_reward') || key.startsWith('reward')) return _rewardIdTest;
    if (key.startsWith('id_collapse') || key.startsWith('collapse')) return _collapseIdTest;
    return null;
  }

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
    if (json.trim().isEmpty) {
      print("admob_ads --- CallApi: convertJsonIdToList nhận json rỗng, bỏ qua (không có id mặc định nào được thêm)");
      return;
    }

    List<AdsModel> listAds;
    try {
      listAds = await compute(parseAdsModel, json);
    } catch (e) {
      print("admob_ads --- CallApi: convertJsonIdToList parse json lỗi, bỏ qua - $e");
      return;
    }

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
    if (isUsingIdDebug) {
      final testId = _getTestIdByName(nameAds);
      print(
        'admob_ads --- CallApi: isUsingIdDebug=true - dùng test id cho "$nameAds" -> ${testId ?? "(không khớp loại nào - trả rỗng)"}',
      );
      return testId ?? '';
    }
    final list = getListIDByName(nameAds);
    print(
      'admob_ads --- CallApi: isUsingIdDebug=false - dùng id real cho "$nameAds" -> ${list.first}',
    );
    if (list.isNotEmpty) {
      return list.first;
    }
    return '';
  }

  /// Ghi id quảng cáo lấy được từ Firebase Remote Config (xem
  /// RemoteConfig._applyAdsIdFromRemoteConfig trong utils/remote_config.dart).
  ///
  /// Không thay thế/xoá luồng lấy id từ server (callAds) ở trên — id từ
  /// Remote Config chỉ được ưu tiên đứng trước (getFirstIDByName trả về
  /// phần tử đầu tiên), còn id lấy được từ server (nếu request sau đó mới
  /// xong) vẫn được thêm vào cuối danh sách như một id dự phòng.
  void setIdFromRemoteConfig(String nameAds, String adsId) {
    if (adsId.isEmpty) return;
    listAdsId[nameAds] = [adsId];
  }
}
