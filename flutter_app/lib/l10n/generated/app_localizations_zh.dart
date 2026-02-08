// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => '心律洞察';

  @override
  String get home => '首页';

  @override
  String get insights => '洞察';

  @override
  String get import => '导入';

  @override
  String get settings => '设置';

  @override
  String get welcomeBack => '欢迎回来';

  @override
  String get dailyRecords => '每日记录';

  @override
  String get noRecordsFound => '未找到记录。';

  @override
  String get clearSelection => '清除选择';

  @override
  String get avgHr => '平均心率';

  @override
  String get minHr => '最低心率';

  @override
  String get peakHr => '峰值心率';

  @override
  String get userProfile => '用户信息';

  @override
  String get name => '姓名';

  @override
  String get dob => '出生日期';

  @override
  String get activityLevel => '活动等级';

  @override
  String get height => '身高';

  @override
  String get weight => '体重';

  @override
  String get application => '应用程序';

  @override
  String get language => '语言';

  @override
  String get theme => '主题';

  @override
  String get setApiKey => '设置 API 密钥';

  @override
  String get regenerate => '重新生成';

  @override
  String get yourReport => '您的报告';

  @override
  String get save => '保存';

  @override
  String get cancel => '取消';

  @override
  String get editProfile => '编辑个人资料';

  @override
  String get syncHealthData => '同步健康数据';

  @override
  String get connectHealthConnect => '连接 Health Connect';

  @override
  String get importDescription =>
      '从 Health Connect（三星健康、Google Fit 等）导入您的心率数据，以获得个性化见解。';

  @override
  String get syncNow => '立即同步';

  @override
  String get debugLoadSample => '调试：加载样本数据';

  @override
  String get sex => '性别';

  @override
  String get male => '男';

  @override
  String get female => '女';

  @override
  String get other => '其他';

  @override
  String get heartRateTrend => '心率趋势';

  @override
  String get restingHr => '静息心率';

  @override
  String get noDataAvailable => '暂无数据';

  @override
  String get allTime => '所有时间';

  @override
  String get today => '今天';

  @override
  String get yesterday => '昨天';

  @override
  String recordsCount(num count) {
    return '$count 条记录';
  }

  @override
  String get bpm => '次/分';

  @override
  String hrZone(Object number, Object range) {
    return '区间 $number ($range)';
  }
}

/// The translations for Chinese, using the Han script (`zh_Hant`).
class AppLocalizationsZhHant extends AppLocalizationsZh {
  AppLocalizationsZhHant() : super('zh_Hant');

  @override
  String get appTitle => '心律洞察';

  @override
  String get home => '首頁';

  @override
  String get insights => '洞察';

  @override
  String get import => '匯入';

  @override
  String get settings => '設置';

  @override
  String get welcomeBack => '歡迎回來';

  @override
  String get dailyRecords => '每日記錄';

  @override
  String get noRecordsFound => '未找到記錄。';

  @override
  String get clearSelection => '清除選擇';

  @override
  String get avgHr => '平均心率';

  @override
  String get minHr => '最低心率';

  @override
  String get peakHr => '峰值心率';

  @override
  String get userProfile => '使用者信息';

  @override
  String get name => '姓名';

  @override
  String get dob => '出生日期';

  @override
  String get activityLevel => '活動等級';

  @override
  String get height => '身高';

  @override
  String get weight => '體重';

  @override
  String get application => '應用程序';

  @override
  String get language => '語言';

  @override
  String get theme => '主題';

  @override
  String get setApiKey => '設置 API 密鑰';

  @override
  String get regenerate => '重新生成';

  @override
  String get yourReport => '您的報告';

  @override
  String get save => '保存';

  @override
  String get cancel => '取消';

  @override
  String get editProfile => '編輯個人資料';

  @override
  String get syncHealthData => '同步健康數據';

  @override
  String get connectHealthConnect => '連接 Health Connect';

  @override
  String get importDescription =>
      '從 Health Connect（三星健康、Google Fit 等）匯入您的心率數據，以獲得個性化見解。';

  @override
  String get syncNow => '立即同步';

  @override
  String get debugLoadSample => '調試：加載樣本數據';

  @override
  String get sex => '性別';

  @override
  String get male => '男';

  @override
  String get female => '女';

  @override
  String get other => '其他';

  @override
  String get heartRateTrend => '心率趨勢';

  @override
  String get restingHr => '靜息心率';

  @override
  String get noDataAvailable => '暫無數據';

  @override
  String get allTime => '所有時間';

  @override
  String get today => '今天';

  @override
  String get yesterday => '昨天';

  @override
  String recordsCount(num count) {
    return '$count 條記錄';
  }

  @override
  String get bpm => '次/分';

  @override
  String hrZone(Object number, Object range) {
    return '區間 $number ($range)';
  }
}
