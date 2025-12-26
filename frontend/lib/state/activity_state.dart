import 'package:flutter/material.dart';

import '../services/activity_service.dart';

class ActivityState extends ChangeNotifier {
  List<RecentActivity> activities = [];
  bool isLoading = false;

  Future<void> load() async {
    isLoading = true;
    notifyListeners();

    // ✅ Correct method name
    // ✅ Static call
    // ✅ Correct RecentActivity type
    activities = await ActivityService.fetchRecent();

    isLoading = false;
    notifyListeners();
  }

  RecentActivity? get latestRepoChat {
    for (final activity in activities) {
      if (activity.type == 'repo_chat') {
        return activity;
      }
    }
    return null;
  }
}
