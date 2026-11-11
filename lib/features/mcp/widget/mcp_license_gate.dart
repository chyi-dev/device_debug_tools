import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../license/cubit/license_cubit.dart';
import '../../license/widget/license_support_dialog.dart';

/// 已激活返回 true；否则弹出支持窗并返回 false。
Future<bool> ensureMcpLicensed(BuildContext context) async {
  final license = context.read<LicenseCubit>().state;
  if (license.isActivated) return true;
  await showLicenseSupportDialog(context);
  return false;
}
