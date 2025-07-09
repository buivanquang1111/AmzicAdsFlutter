import 'package:amazic_ads_flutter/dialog/loading_dialog.dart';
import 'package:flutter/material.dart';

bool _isDialogShow = false;

showLoadingDialog({required BuildContext context}) {
  _isDialogShow = true;
  showDialog(
    context: context,
    builder: (context) {
      return LoadingDialog();
    },
  );
}

closeLoadingDialog({required BuildContext context}) {
  if (_isDialogShow && Navigator.canPop(context)) {
    Navigator.of(context, rootNavigator: true).pop();
    _isDialogShow = false;
  }
}
