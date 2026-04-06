// Copyright (c) 2026 Jacken Xu (lightant@gmail.com)
// All rights reserved.
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
  String get clearSelection => '清除';

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

  @override
  String lastSync(Object time) {
    return '上次同步: $time';
  }

  @override
  String recordsImported(Object count) {
    return '已导入 $count 条记录';
  }

  @override
  String get chat => '聊天';

  @override
  String get typeMessage => '输入消息...';

  @override
  String get aiThinking => 'AI 正在思考...';

  @override
  String get clear => '清除';

  @override
  String get aboutAndLicenses => '关于与许可证';

  @override
  String get aboutApp => '关于心律洞察';

  @override
  String get appVersion => '心律洞察 v1.0.0 (Flutter)';

  @override
  String get aiProvider => 'AI 由 Gemma (Google) 提供支持';

  @override
  String get gemmaTerms =>
      '本应用程序分发并使用 Gemma 2B 模型。\n\nGemma 模型的使用受 Gemma 使用条款约束，详见：https://ai.google.dev/gemma/terms\n\n通过使用此应用中的 AI 功能，您同意不将模型用于任何受限用途，详见 Gemma 禁止使用政策，包括但不限于生成非法内容、恶意软件或提供可操作的医疗建议。';

  @override
  String get close => '关闭';

  @override
  String get system => '系统';

  @override
  String get light => '浅色';

  @override
  String get dark => '深色';

  @override
  String get english => '英文 (English)';

  @override
  String get simplifiedChinese => '简体中文';

  @override
  String get traditionalChinese => '繁体中文';

  @override
  String get geminiApiKey => 'Gemini API 密钥';

  @override
  String get usesCloudApi => '使用云端 API (需要密钥)';

  @override
  String get onDeviceAi => '离线 AI (AICore)';

  @override
  String get inAppAi => '应用内 AI (Gemma)';

  @override
  String get modelName => '模型: Gemma 4 E2B';

  @override
  String get openSourceLibraries => '开源库';

  @override
  String get enterApiKey => '输入 Gemini API 密钥';

  @override
  String get keyRequiredMessage => '请在设置中设置您的 Gemini API 密钥，或点击下方。';

  @override
  String get tapToGenerate => '点击刷新按钮生成您的 AI 健康洞察。';

  @override
  String get aiSource => 'AI 来源';

  @override
  String debugRecordsLoaded(Object count) {
    return '已加载 $count 条调试记录';
  }

  @override
  String get readyToExport => '准备导出。';

  @override
  String get exportFailed => '导出失败或无数据';
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
  String get clearSelection => '清除';

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

  @override
  String lastSync(Object time) {
    return '上次同步: $time';
  }

  @override
  String recordsImported(Object count) {
    return '已匯入 $count 條記錄';
  }

  @override
  String get chat => '聊天';

  @override
  String get typeMessage => '輸入消息...';

  @override
  String get aiThinking => 'AI 正在思考...';

  @override
  String get clear => '清除';

  @override
  String get aboutAndLicenses => '關於與許可證';

  @override
  String get aboutApp => '關於心律洞察';

  @override
  String get appVersion => '心律洞察 v1.0.0 (Flutter)';

  @override
  String get aiProvider => 'AI 由 Gemma (Google) 提供支持';

  @override
  String get gemmaTerms =>
      '本應用程序分發並使用 Gemma 2B 模型。\n\nGemma 模型的使用受 Gemma 使用條款約束，詳見：https://ai.google.dev/gemma/terms\n\n通過使用此應用中的 AI 功能，您同意不將模型用於任何受限用途，詳見 Gemma 禁止使用政策，包括但不限于生成非法內容、惡意軟體或提供可操作的醫療建議。';

  @override
  String get close => '關閉';

  @override
  String get system => '系統';

  @override
  String get light => '淺色';

  @override
  String get dark => '深色';

  @override
  String get english => '英文 (English)';

  @override
  String get simplifiedChinese => '簡體中文';

  @override
  String get traditionalChinese => '繁體中文';

  @override
  String get geminiApiKey => 'Gemini API 密鑰';

  @override
  String get usesCloudApi => '使用雲端 API (需要密鑰)';

  @override
  String get onDeviceAi => '離線 AI (AICore)';

  @override
  String get inAppAi => '應用內 AI (Gemma)';

  @override
  String get modelName => '模型: Gemma 4 E2B';

  @override
  String get openSourceLibraries => '開源庫';

  @override
  String get enterApiKey => '輸入 Gemini API 密鑰';

  @override
  String get keyRequiredMessage => '請在設置中設置您的 Gemini API 密鑰，或點擊下方。';

  @override
  String get tapToGenerate => '點擊刷新按鈕生成您的 AI 健康洞察。';

  @override
  String get aiSource => 'AI 來源';

  @override
  String debugRecordsLoaded(Object count) {
    return '已匯入 $count 條調試記錄';
  }

  @override
  String get readyToExport => '準備導出。';

  @override
  String get exportFailed => '導出失敗或無數據';
}

