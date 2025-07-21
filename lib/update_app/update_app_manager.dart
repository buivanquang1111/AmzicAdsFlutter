import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:in_app_update/in_app_update.dart';

import 'dialog_update_app.dart';

class UpdateAppManager {
  UpdateAppManager._instance();

  static final UpdateAppManager instance = UpdateAppManager._instance();

  checkForFlexibleUpdate({
    required BuildContext context,
    String? title,
    String? content,
    required Function() onNext,
  }) async {
    try {
      AppUpdateInfo updateInfo = await InAppUpdate.checkForUpdate();

      if (updateInfo.updateAvailability == UpdateAvailability.updateAvailable) {
        try {
          if (context.mounted) {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) {
                return WillPopScope(
                  onWillPop: () async => false,
                  child: DialogUpdateApp(
                    title: title,
                    content: content,
                    onUpdateNow: () async {
                      if (context.mounted) Navigator.of(context).pop();
                      try {
                        onNext();
                        await InAppUpdate.startFlexibleUpdate();
                        await InAppUpdate.completeFlexibleUpdate();
                        Fluttertoast.showToast(msg: 'Updated and ready – welcome back!');
                      } catch (e) {
                        print('admob_ads --- update_app: error update failed: $e');
                        onNext();
                      }
                    },
                  ),
                );
              },
            );
          }
        } catch (e) {
          print('admob_ads --- update_app: error update failed (inner try): $e');
          if (context.mounted) onNext();
        }
      } else {
        print('admob_ads --- update_app: new update');
        if (context.mounted) onNext();
      }
    } catch (e) {
      print('admob_ads --- update_app: error checking for update: $e');
      if (context.mounted) onNext();
    }
  }
}
