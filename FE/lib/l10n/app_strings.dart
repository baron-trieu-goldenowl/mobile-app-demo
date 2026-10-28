import 'package:flutter/widgets.dart';

/// Simple app-wide string translations (vi/en).
class AppStrings {
  AppStrings(this.locale);

  static AppStrings of(BuildContext context) =>
      AppStrings(Localizations.localeOf(context));

  final Locale locale;

  bool get isVi => locale.languageCode == 'vi';

  String get(String key) {
    final map = isVi ? _vi : _en;
    return map[key] ?? _en[key] ?? key;
  }

  // --- Common / navigation ---
  String get alarm => get('alarm');
  String get alarmSingular => get('alarmSingular');
  String get schedule => get('schedule');
  String get calendar => get('calendar');
  String get tasks => get('tasks');
  String get report => get('report');
  String get settings => get('settings');
  String get notifications => get('notifications');
  String get save => get('save');
  String get saveChanges => get('saveChanges');
  String get cancel => get('cancel');
  String get delete => get('delete');
  String get done => get('done');
  String get retry => get('retry');
  String get loadFailed => get('loadFailed');
  String get today => get('today');
  String get upcoming => get('upcoming');
  String get title => get('title');
  String get note => get('note');
  String get location => get('location');
  String get off => get('off');

  // --- Auth ---
  String get welcomeBack => get('welcomeBack');
  String get loginTagline => get('loginTagline');
  String get signupTagline => get('signupTagline');
  String get email => get('email');
  String get password => get('password');
  String get login => get('login');
  String get loginGoogle => get('loginGoogle');
  String get loginApple => get('loginApple');
  String get legalPrefix => get('legalPrefix');
  String get privacyPolicy => get('privacyPolicy');
  String get helpSupport => get('helpSupport');
  String get signedInWithApple => get('signedInWithApple');
  String get googleCalendarHint => get('googleCalendarHint');
  String get orEmail => get('orEmail');
  String get fillEmailPassword => get('fillEmailPassword');
  String get noAccount => get('noAccount');
  String get createAccount => get('createAccount');
  String get name => get('name');
  String get signup => get('signup');
  String get passwordHelper => get('passwordHelper');
  String get emailRequired => get('emailRequired');
  String get emailInvalid => get('emailInvalid');
  String get passwordRequired => get('passwordRequired');
  String get passwordShort => get('passwordShort');
  String get passwordUpper => get('passwordUpper');
  String get passwordLower => get('passwordLower');
  String get passwordDigit => get('passwordDigit');
  String get nameRequired => get('nameRequired');

  // --- Alarms ---
  String get addAlarm => get('addAlarm');
  String get editAlarm => get('editAlarm');
  String get deleteAlarm => get('deleteAlarm');
  String get noAlarms => get('noAlarms');
  String get noAlarmsHint => get('noAlarmsHint');
  String get nextAlarm => get('nextAlarm');
  String get noActiveAlarm => get('noActiveAlarm');
  String get noActiveAlarmHint => get('noActiveAlarmHint');
  String get quickAlarm => get('quickAlarm');
  String get quickAlarmHint => get('quickAlarmHint');
  String get preview => get('preview');
  String get repeat => get('repeat');
  String get everyday => get('everyday');
  String get weekdays => get('weekdays');
  String get weekends => get('weekends');
  String get once => get('once');
  String get label => get('label');
  String get labelHint => get('labelHint');
  String get mission => get('mission');
  String get missionHint => get('missionHint');
  String get missionNoneHint => get('missionNoneHint');
  String get difficulty => get('difficulty');
  String get tryIt => get('tryIt');
  String get soundAndVibration => get('soundAndVibration');
  String get sound => get('sound');
  String get volume => get('volume');
  String get gradualVolume => get('gradualVolume');
  String get gradualVolumeHint => get('gradualVolumeHint');
  String get vibration => get('vibration');
  String get snooze => get('snooze');
  String get snoozeInterval => get('snoozeInterval');
  String get snoozeLimit => get('snoozeLimit');
  String get unlimited => get('unlimited');
  String get wakeUpCheck => get('wakeUpCheck');
  String get wakeUpCheckHint => get('wakeUpCheckHint');
  String get qrNotRegistered => get('qrNotRegistered');
  String get qrRegistered => get('qrRegistered');
  String get qrRegisterHint => get('qrRegisterHint');
  String get registerQr => get('registerQr');
  String get scan => get('scan');
  String get cameraUnavailable => get('cameraUnavailable');

  // --- Ringing / missions ---
  String get dismiss => get('dismiss');
  String get startMission => get('startMission');
  String get wakeCheckRing => get('wakeCheckRing');
  String get wrongTryAgain => get('wrongTryAgain');
  String get memorize => get('memorize');
  String get repeatSequence => get('repeatSequence');
  String get typePhrase => get('typePhrase');
  String get typeHere => get('typeHere');
  String get shakeToDismiss => get('shakeToDismiss');
  String get shakesLeft => get('shakesLeft');
  String get walkToDismiss => get('walkToDismiss');
  String get stepsLeft => get('stepsLeft');
  String get arrangeNumbers => get('arrangeNumbers');
  String get scanRegisteredCode => get('scanRegisteredCode');
  String get wrongCode => get('wrongCode');
  String get qrFallback => get('qrFallback');

  // --- Morning briefing ---
  String get todaySchedule => get('todaySchedule');
  String get todayTasks => get('todayTasks');
  String get noEventsToday => get('noEventsToday');
  String get noTasksToday => get('noTasksToday');
  String get startDay => get('startDay');
  String get areYouAwake => get('areYouAwake');
  String get imAwake => get('imAwake');

  // --- Schedule / calendar ---
  String get syncGoogle => get('syncGoogle');
  String get syncDone => get('syncDone');
  String get syncedEvents => get('syncedEvents');
  String get noEvents => get('noEvents');
  String get monthView => get('monthView');
  String get weekView => get('weekView');
  String get allDay => get('allDay');
  String get personalEvent => get('personalEvent');
  String get newEvent => get('newEvent');
  String get nothingScheduled => get('nothingScheduled');
  String get nothingScheduledHint => get('nothingScheduledHint');
  String get googleEventReadOnly => get('googleEventReadOnly');
  String get googleCalendar => get('googleCalendar');
  String get connectGoogleTitle => get('connectGoogleTitle');
  String get connectGoogleHint => get('connectGoogleHint');
  String get googleSyncHint => get('googleSyncHint');
  String get connect => get('connect');
  String get connected => get('connected');
  String get notConnected => get('notConnected');
  String get googleConnected => get('googleConnected');
  String get disconnect => get('disconnect');
  String get disconnectGoogle => get('disconnectGoogle');
  String get disconnectGoogleConfirm => get('disconnectGoogleConfirm');

  // --- Tasks ---
  String get addTask => get('addTask');
  String get editTask => get('editTask');
  String get taskTitleHint => get('taskTitleHint');
  String get noTasks => get('noTasks');
  String get noTasksHint => get('noTasksHint');
  String get noCompletedTasks => get('noCompletedTasks');
  String get allOpen => get('allOpen');
  String get completed => get('completed');
  String get priority => get('priority');
  String get addDueDate => get('addDueDate');
  String get reminder => get('reminder');

  // --- Report ---
  String get last30Days => get('last30Days');
  String get noReportYet => get('noReportYet');
  String get noReportYetHint => get('noReportYetHint');
  String get streakHint => get('streakHint');
  String get avgWakeTime => get('avgWakeTime');
  String get totalSnoozes => get('totalSnoozes');
  String get alarmsDismissed => get('alarmsDismissed');
  String get avgMissionTime => get('avgMissionTime');
  String get wakeTimeLast7 => get('wakeTimeLast7');
  String get history => get('history');

  // --- Settings ---
  String get noName => get('noName');
  String get editProfile => get('editProfile');
  String get profileUpdated => get('profileUpdated');
  String get signedInWithGoogle => get('signedInWithGoogle');
  String get appearance => get('appearance');
  String get theme => get('theme');
  String get themeSystem => get('themeSystem');
  String get themeLight => get('themeLight');
  String get themeDark => get('themeDark');
  String get language => get('language');
  String get general => get('general');
  String get notificationPermission => get('notificationPermission');
  String get notificationPermissionHint => get('notificationPermissionHint');
  String get permissionGranted => get('permissionGranted');
  String get permissionDenied => get('permissionDenied');
  String get logout => get('logout');
  String get logoutConfirm => get('logoutConfirm');
  String get deleteAccount => get('deleteAccount');
  String get deleteAccountConfirm => get('deleteAccountConfirm');

  // --- Notifications ---
  String get markAllRead => get('markAllRead');
  String get noNotifications => get('noNotifications');

  // --- Formatted strings ---
  String ringsIn(Duration d) {
    if (d.inSeconds < 60) {
      return isVi ? 'Reo trong chưa đầy 1 phút' : 'Rings in less than a minute';
    }
    // Round up so an alarm 7h31m20s away reads "7 h 32 min".
    final total = d.inMinutes + (d.inSeconds % 60 > 0 ? 1 : 0);
    final days = total ~/ 1440,
        hours = (total % 1440) ~/ 60,
        minutes = total % 60;
    final parts = <String>[
      if (days > 0) isVi ? '$days ngày' : '$days d',
      if (hours > 0) isVi ? '$hours giờ' : '$hours h',
      if (minutes > 0 && days == 0) isVi ? '$minutes phút' : '$minutes min',
    ];
    return isVi ? 'Reo sau ${parts.join(' ')}' : 'Rings in ${parts.join(' ')}';
  }

  String weekdayShort(int weekday) => isVi
      ? const ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'][weekday - 1]
      : const ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su'][weekday - 1];

  String weekdayLong(int weekday) => isVi
      ? const [
          'Thứ Hai',
          'Thứ Ba',
          'Thứ Tư',
          'Thứ Năm',
          'Thứ Sáu',
          'Thứ Bảy',
          'Chủ Nhật',
        ][weekday - 1]
      : const [
          'Monday',
          'Tuesday',
          'Wednesday',
          'Thursday',
          'Friday',
          'Saturday',
          'Sunday',
        ][weekday - 1];

  String minutesShort(int m) {
    if (m >= 60 && m % 60 == 0) return isVi ? '${m ~/ 60} giờ' : '${m ~/ 60} h';
    if (m > 60) return isVi ? '${m ~/ 60}g${m % 60}p' : '${m ~/ 60}h${m % 60}m';
    return isVi ? '$m phút' : '$m min';
  }

  String secondsShort(int sec) =>
      sec >= 60 ? '${sec ~/ 60}m${sec % 60}s' : '${sec}s';

  String timesCount(int n) => isVi ? '$n lần' : '$n×';

  String snoozeFor(int minutes) =>
      isVi ? 'Báo lại sau $minutes phút' : 'Snooze $minutes min';

  String snoozesLeft(int n) => isVi ? 'còn $n lần' : '$n left';

  String snoozedTimes(int n) => isVi ? 'báo lại $n lần' : 'snoozed $n×';

  String missionToDismiss(String mission) =>
      isVi ? 'Hoàn thành "$mission" để tắt' : 'Complete "$mission" to dismiss';

  String movesCount(int n) => isVi ? '$n bước' : '$n moves';

  String greeting(DateTime t) {
    final h = t.hour;
    if (h < 11) return isVi ? 'Chào buổi sáng!' : 'Good morning!';
    if (h < 14) return isVi ? 'Chào buổi trưa!' : 'Good afternoon!';
    if (h < 18) return isVi ? 'Chào buổi chiều!' : 'Good afternoon!';
    return isVi ? 'Chào buổi tối!' : 'Good evening!';
  }

  String wokeUpAt(String time) =>
      isVi ? 'Bạn đã thức dậy lúc $time' : 'You woke up at $time';

  String confirmWithin(String time) => isVi
      ? 'Xác nhận trong $time, nếu không báo thức sẽ reo lại'
      : 'Confirm within $time or the alarm rings again';

  String streakDays(int n) => isVi ? 'Chuỗi $n ngày' : '$n-day streak';

  String tasksSummary(int open, int doneToday) => isVi
      ? '$open việc cần làm · $doneToday đã xong hôm nay'
      : '$open to do · $doneToday done today';

  String reminderOption(int? minutesBefore) => switch (minutesBefore) {
    null => isVi ? 'Không nhắc' : 'No reminder',
    0 => isVi ? 'Đúng giờ' : 'At due time',
    1440 => isVi ? 'Trước 1 ngày' : '1 day before',
    _ =>
      isVi
          ? 'Trước ${minutesShort(minutesBefore)}'
          : '${minutesShort(minutesBefore)} before',
  };

  String priorityName(String p) => get('priority_$p');

  String difficultyName(String d) => get('difficulty_$d');

  String soundName(String sound) => get('sound_$sound');

  String missionName(String type) => get('mission_$type');

  String missionDesc(String type) => get('missionDesc_$type');

  String missionGoal(String type, String difficulty) {
    int pick(int e, int m, int h) => difficulty == 'hard'
        ? h
        : difficulty == 'medium'
        ? m
        : e;
    return switch (type) {
      'math' =>
        isVi
            ? 'Giải ${pick(3, 4, 5)} phép tính'
            : 'Solve ${pick(3, 4, 5)} problems',
      'memory' =>
        isVi
            ? 'Nhớ chuỗi ${pick(4, 6, 8)} ô'
            : 'Remember ${pick(4, 6, 8)} tiles',
      'typing' =>
        isVi
            ? 'Gõ lại một câu ${difficultyName(difficulty).toLowerCase()}'
            : 'Type a ${difficultyName(difficulty).toLowerCase()} phrase',
      'shake' =>
        isVi
            ? 'Lắc ${pick(20, 35, 50)} lần'
            : 'Shake ${pick(20, 35, 50)} times',
      'walk' =>
        isVi ? 'Đi ${pick(20, 40, 70)} bước' : 'Walk ${pick(20, 40, 70)} steps',
      'puzzle' => isVi ? 'Xếp lại ô số 3×3' : 'Solve a 3×3 sliding puzzle',
      _ => '',
    };
  }

  List<String> typingPhrases(String difficulty) {
    final vi = {
      'easy': [
        'Hôm nay là một ngày tuyệt vời',
        'Tôi đã thức dậy',
        'Dậy sớm để thành công',
      ],
      'medium': [
        'Mỗi buổi sáng là một khởi đầu mới',
        'Tôi sẽ không quay lại giường nữa',
        'Thành công bắt đầu từ việc dậy đúng giờ',
      ],
      'hard': [
        'Kỷ luật là cầu nối giữa mục tiêu và thành tựu của tôi',
        'Hôm nay tôi chọn thức dậy và làm điều tốt nhất có thể',
        'Người dậy sớm có thêm thời gian để theo đuổi ước mơ',
      ],
    };
    final en = {
      'easy': ['Today is a great day', 'I am awake now', 'Rise and shine'],
      'medium': [
        'Every morning is a fresh start',
        'I will not go back to bed',
        'Success starts with getting up on time',
      ],
      'hard': [
        'Discipline is the bridge between my goals and accomplishment',
        'Today I choose to wake up and do my very best',
        'The early riser has more time to chase their dreams',
      ],
    };
    return (isVi ? vi : en)[difficulty] ?? (isVi ? vi : en)['easy']!;
  }

  static const _en = {
    // common
    'alarm': 'Alarms',
    'alarmSingular': 'Alarm',
    'schedule': 'Schedule',
    'calendar': 'Calendar',
    'tasks': 'Tasks',
    'report': 'Report',
    'settings': 'Settings',
    'notifications': 'Notifications',
    'save': 'Save',
    'saveChanges': 'Save changes',
    'cancel': 'Cancel',
    'delete': 'Delete',
    'done': 'Done',
    'retry': 'Retry',
    'loadFailed': "Couldn't load data",
    'today': 'Today',
    'upcoming': 'Upcoming',
    'title': 'Title',
    'note': 'Note',
    'location': 'Location',
    'off': 'Off',
    // auth
    'welcomeBack': 'Wake up better',
    'loginTagline': 'Alarms that get you out of bed, and a schedule that keeps your day on track.',
    'signupTagline': 'Start building a better morning routine.',
    'email': 'Email',
    'password': 'Password',
    'login': 'Log in',
    'loginGoogle': 'Continue with Google',
    'loginApple': 'Continue with Apple',
    'legalPrefix': 'By continuing you agree to our',
    'privacyPolicy': 'Privacy Policy',
    'helpSupport': 'Help & support',
    'signedInWithApple': 'Signed in with Apple',
    'googleCalendarHint':
        'Google sign-in can also sync your Google Calendar (read-only).',
    'orEmail': 'or with email',
    'fillEmailPassword': 'Please enter your email and password',
    'noAccount': "Don't have an account? Sign up",
    'createAccount': 'Create account',
    'name': 'Name',
    'signup': 'Sign up',
    'passwordHelper': 'At least 8 chars, with upper, lower and digit',
    'emailRequired': 'Please enter email',
    'emailInvalid': 'Invalid email format',
    'passwordRequired': 'Please enter password',
    'passwordShort': 'Password must be at least 8 characters',
    'passwordUpper': 'Password must contain at least 1 uppercase letter',
    'passwordLower': 'Password must contain at least 1 lowercase letter',
    'passwordDigit': 'Password must contain at least 1 digit',
    'nameRequired': 'Please enter name',
    // alarms
    'addAlarm': 'New alarm',
    'editAlarm': 'Edit alarm',
    'deleteAlarm': 'Delete alarm',
    'noAlarms': 'No alarms yet',
    'noAlarmsHint': 'Tap “New alarm” to set your first wake-up.',
    'nextAlarm': 'Next alarm',
    'noActiveAlarm': 'No active alarm',
    'noActiveAlarmHint': 'Sleep in, or turn an alarm on',
    'quickAlarm': 'Quick alarm',
    'quickAlarmHint': 'Power nap or a short reminder — rings after:',
    'preview': 'Preview',
    'repeat': 'Repeat',
    'everyday': 'Every day',
    'weekdays': 'Weekdays',
    'weekends': 'Weekends',
    'once': 'Once',
    'label': 'Label',
    'labelHint': 'e.g. Wake up, Gym, Meeting',
    'mission': 'Wake-up mission',
    'missionHint':
        'Complete the mission to turn off the alarm — no more oversleeping.',
    'missionNoneHint': 'Turn off with one tap',
    'difficulty': 'Difficulty',
    'tryIt': 'Try it',
    'soundAndVibration': 'Sound & vibration',
    'sound': 'Ringtone',
    'volume': 'Volume',
    'gradualVolume': 'Gradually louder',
    'gradualVolumeHint': 'Start quiet and get louder over 30 seconds',
    'vibration': 'Vibration',
    'snooze': 'Snooze',
    'snoozeInterval': 'Snooze interval',
    'snoozeLimit': 'Max snoozes',
    'unlimited': 'Unlimited',
    'wakeUpCheck': 'Wake-up check',
    'wakeUpCheckHint': 'Confirm you are awake 3 minutes after dismissing, or the alarm rings again',
    'qrNotRegistered': 'No code registered',
    'qrRegistered': 'Code registered',
    'qrRegisterHint': 'Scan a QR code or barcode far from your bed (e.g. toothpaste in the bathroom).',
    'registerQr': 'Register code',
    'scan': 'Scan',
    'cameraUnavailable':
        'Camera is unavailable. Please allow camera access in Settings.',
    // ringing / missions
    'dismiss': 'Dismiss',
    'startMission': 'Start mission',
    'wakeCheckRing': 'Are you awake? You did not confirm.',
    'wrongTryAgain': 'Wrong, try again',
    'memorize': 'Memorize the pattern',
    'repeatSequence': 'Tap the tiles in the same order',
    'typePhrase': 'Type the phrase below',
    'typeHere': 'Type here…',
    'shakeToDismiss': 'Shake your phone',
    'shakesLeft': 'shakes left',
    'walkToDismiss': 'Get up and walk',
    'stepsLeft': 'steps left',
    'arrangeNumbers': 'Put the numbers 1–8 in order',
    'scanRegisteredCode': 'Go scan your registered code',
    'wrongCode': 'That is not the registered code',
    'qrFallback': "Can't scan? Solve hard math instead",
    // morning
    'todaySchedule': "Today's schedule",
    'todayTasks': 'To do today',
    'noEventsToday': 'No events today',
    'noTasksToday': 'Nothing due today',
    'startDay': 'Start my day',
    'areYouAwake': 'Are you awake?',
    'imAwake': "I'm awake",
    // schedule
    'syncGoogle': 'Sync Google Calendar',
    'syncDone': 'Google Calendar synced',
    'syncedEvents': 'events synced',
    'noEvents': 'No events for this date',
    'monthView': 'Month view',
    'weekView': 'Week view',
    'allDay': 'All day',
    'personalEvent': 'Personal event',
    'newEvent': 'New event',
    'nothingScheduled': 'Nothing scheduled',
    'nothingScheduledHint': 'Enjoy your free time, or add an event with +',
    'googleEventReadOnly':
        'This event comes from Google Calendar. Edit it in Google Calendar.',
    'googleCalendar': 'Google Calendar',
    'connectGoogleTitle': 'Connect Google Calendar',
    'connectGoogleHint':
        'See your Google events next to your alarms and tasks.',
    'googleSyncHint': 'Your events are imported (read-only).',
    'connect': 'Connect',
    'connected': 'Connected',
    'notConnected': 'Not connected',
    'googleConnected': 'Google Calendar connected',
    'disconnect': 'Disconnect',
    'disconnectGoogle': 'Disconnect Google Calendar',
    'disconnectGoogleConfirm':
        'Imported Google events will be removed from the app.',
    // tasks
    'addTask': 'New task',
    'editTask': 'Edit task',
    'taskTitleHint': 'What do you need to do?',
    'noTasks': 'All clear!',
    'noTasksHint': 'Add a task to plan your day.',
    'noCompletedTasks': 'No completed tasks yet',
    'allOpen': 'All',
    'completed': 'Completed',
    'priority': 'Priority',
    'addDueDate': 'Add due date',
    'reminder': 'Reminder',
    'priority_low': 'Low',
    'priority_medium': 'Medium',
    'priority_high': 'High',
    'priority_urgent': 'Urgent',
    // report
    'last30Days': 'Your last 30 days',
    'noReportYet': 'No wake-ups recorded yet',
    'noReportYetHint':
        'Dismiss an alarm and your wake-up stats will appear here.',
    'streakHint': 'Days in a row you got up with an alarm',
    'avgWakeTime': 'Average wake-up',
    'totalSnoozes': 'Snoozes',
    'alarmsDismissed': 'Alarms dismissed',
    'avgMissionTime': 'Average mission time',
    'wakeTimeLast7': 'Wake-up time · last 7 days',
    'history': 'History',
    // settings
    'noName': 'Add your name',
    'editProfile': 'Edit profile',
    'profileUpdated': 'Profile updated',
    'signedInWithGoogle': 'Signed in with Google',
    'appearance': 'Appearance',
    'theme': 'Theme',
    'themeSystem': 'System',
    'themeLight': 'Light',
    'themeDark': 'Dark',
    'language': 'Language',
    'general': 'General',
    'notificationPermission': 'Alarm permissions',
    'notificationPermissionHint':
        'Allow notifications and exact alarms so alarms ring on time',
    'permissionGranted': 'Permission granted',
    'permissionDenied': 'Permission denied — enable it in system Settings',
    'logout': 'Log out',
    'logoutConfirm': 'Alarms on this device will stop until you log in again.',
    'deleteAccount': 'Delete account',
    'deleteAccountConfirm':
        'This will permanently delete your account and all data. Continue?',
    // notifications
    'markAllRead': 'Mark all read',
    'noNotifications': 'No notifications',
    // enums
    'difficulty_easy': 'Easy',
    'difficulty_medium': 'Medium',
    'difficulty_hard': 'Hard',
    'sound_classic': 'Classic',
    'sound_digital': 'Digital',
    'sound_chime': 'Chime',
    'sound_rising': 'Rising',
    'sound_birds': 'Birds',
    'mission_none': 'No mission',
    'mission_math': 'Math',
    'mission_memory': 'Memory',
    'mission_typing': 'Typing',
    'mission_shake': 'Shake',
    'mission_walk': 'Walk',
    'mission_puzzle': 'Puzzle',
    'mission_qr': 'QR / Barcode',
    'missionDesc_none': 'Just tap to dismiss',
    'missionDesc_math': 'Solve problems to wake your brain',
    'missionDesc_memory': 'Repeat a pattern of tiles',
    'missionDesc_typing': 'Type a motivational phrase',
    'missionDesc_shake': 'Shake the phone hard',
    'missionDesc_walk': 'Get up and take some steps',
    'missionDesc_puzzle': 'Slide the tiles into order',
    'missionDesc_qr': 'Scan a code in another room',
  };

  static const _vi = {
    // common
    'alarm': 'Báo thức',
    'alarmSingular': 'Báo thức',
    'schedule': 'Lịch trình',
    'calendar': 'Lịch',
    'tasks': 'Công việc',
    'report': 'Báo cáo',
    'settings': 'Cài đặt',
    'notifications': 'Thông báo',
    'save': 'Lưu',
    'saveChanges': 'Lưu thay đổi',
    'cancel': 'Huỷ',
    'delete': 'Xoá',
    'done': 'Xong',
    'retry': 'Thử lại',
    'loadFailed': 'Không tải được dữ liệu',
    'today': 'Hôm nay',
    'upcoming': 'Sắp tới',
    'title': 'Tiêu đề',
    'note': 'Ghi chú',
    'location': 'Địa điểm',
    'off': 'Tắt',
    // auth
    'welcomeBack': 'Thức dậy tốt hơn',
    'loginTagline':
        'Báo thức giúp bạn rời giường, lịch trình giúp ngày của bạn đúng nhịp.',
    'signupTagline': 'Bắt đầu xây dựng thói quen buổi sáng tốt hơn.',
    'email': 'Email',
    'password': 'Mật khẩu',
    'login': 'Đăng nhập',
    'loginGoogle': 'Tiếp tục với Google',
    'loginApple': 'Tiếp tục với Apple',
    'legalPrefix': 'Khi tiếp tục, bạn đồng ý với',
    'privacyPolicy': 'Chính sách quyền riêng tư',
    'helpSupport': 'Trợ giúp & hỗ trợ',
    'signedInWithApple': 'Đăng nhập bằng Apple',
    'googleCalendarHint':
        'Đăng nhập Google có thể đồng bộ Google Calendar (chỉ đọc).',
    'orEmail': 'hoặc dùng email',
    'fillEmailPassword': 'Vui lòng nhập email và mật khẩu',
    'noAccount': 'Chưa có tài khoản? Đăng ký',
    'createAccount': 'Tạo tài khoản',
    'name': 'Tên',
    'signup': 'Đăng ký',
    'passwordHelper': 'Ít nhất 8 ký tự, gồm chữ hoa, chữ thường và số',
    'emailRequired': 'Vui lòng nhập email',
    'emailInvalid': 'Email không đúng định dạng',
    'passwordRequired': 'Vui lòng nhập mật khẩu',
    'passwordShort': 'Mật khẩu phải có ít nhất 8 ký tự',
    'passwordUpper': 'Mật khẩu phải chứa ít nhất 1 chữ in hoa',
    'passwordLower': 'Mật khẩu phải chứa ít nhất 1 chữ thường',
    'passwordDigit': 'Mật khẩu phải chứa ít nhất 1 chữ số',
    'nameRequired': 'Vui lòng nhập tên',
    // alarms
    'addAlarm': 'Thêm báo thức',
    'editAlarm': 'Sửa báo thức',
    'deleteAlarm': 'Xoá báo thức',
    'noAlarms': 'Chưa có báo thức',
    'noAlarmsHint': 'Nhấn “Thêm báo thức” để đặt giờ thức dậy đầu tiên.',
    'nextAlarm': 'Báo thức tiếp theo',
    'noActiveAlarm': 'Không có báo thức nào bật',
    'noActiveAlarmHint': 'Ngủ nướng, hoặc bật một báo thức',
    'quickAlarm': 'Báo thức nhanh',
    'quickAlarmHint': 'Ngủ trưa hay nhắc việc ngắn — reo sau:',
    'preview': 'Xem thử',
    'repeat': 'Lặp lại',
    'everyday': 'Hằng ngày',
    'weekdays': 'Ngày thường',
    'weekends': 'Cuối tuần',
    'once': 'Một lần',
    'label': 'Nhãn',
    'labelHint': 'VD: Thức dậy, Tập gym, Họp',
    'mission': 'Nhiệm vụ tắt báo thức',
    'missionHint': 'Hoàn thành nhiệm vụ mới tắt được báo thức — hết ngủ quên.',
    'missionNoneHint': 'Tắt bằng một chạm',
    'difficulty': 'Độ khó',
    'tryIt': 'Thử ngay',
    'soundAndVibration': 'Âm thanh & rung',
    'sound': 'Nhạc chuông',
    'volume': 'Âm lượng',
    'gradualVolume': 'Tăng dần âm lượng',
    'gradualVolumeHint': 'Bắt đầu nhỏ và to dần trong 30 giây',
    'vibration': 'Rung',
    'snooze': 'Báo lại (Snooze)',
    'snoozeInterval': 'Khoảng thời gian báo lại',
    'snoozeLimit': 'Số lần báo lại tối đa',
    'unlimited': 'Không giới hạn',
    'wakeUpCheck': 'Kiểm tra thức dậy',
    'wakeUpCheckHint': 'Xác nhận bạn đã tỉnh 3 phút sau khi tắt, nếu không báo thức sẽ reo lại',
    'qrNotRegistered': 'Chưa đăng ký mã',
    'qrRegistered': 'Đã đăng ký mã',
    'qrRegisterHint': 'Quét một mã QR hoặc mã vạch đặt xa giường (VD: tuýp kem đánh răng trong nhà tắm).',
    'registerQr': 'Đăng ký mã',
    'scan': 'Quét',
    'cameraUnavailable':
        'Không dùng được camera. Hãy cấp quyền camera trong Cài đặt.',
    // ringing / missions
    'dismiss': 'Tắt báo thức',
    'startMission': 'Làm nhiệm vụ',
    'wakeCheckRing': 'Bạn đã tỉnh chưa? Bạn chưa xác nhận.',
    'wrongTryAgain': 'Sai rồi, thử lại',
    'memorize': 'Ghi nhớ thứ tự sáng',
    'repeatSequence': 'Chạm các ô theo đúng thứ tự',
    'typePhrase': 'Gõ lại câu bên dưới',
    'typeHere': 'Gõ tại đây…',
    'shakeToDismiss': 'Lắc điện thoại',
    'shakesLeft': 'lần lắc còn lại',
    'walkToDismiss': 'Đứng dậy và đi bộ',
    'stepsLeft': 'bước còn lại',
    'arrangeNumbers': 'Xếp các số 1–8 theo thứ tự',
    'scanRegisteredCode': 'Hãy đi quét mã đã đăng ký',
    'wrongCode': 'Không phải mã đã đăng ký',
    'qrFallback': 'Không quét được? Giải toán khó thay thế',
    // morning
    'todaySchedule': 'Lịch hôm nay',
    'todayTasks': 'Việc cần làm hôm nay',
    'noEventsToday': 'Hôm nay không có sự kiện',
    'noTasksToday': 'Không có việc đến hạn hôm nay',
    'startDay': 'Bắt đầu ngày mới',
    'areYouAwake': 'Bạn đã tỉnh chưa?',
    'imAwake': 'Tôi đã tỉnh',
    // schedule
    'syncGoogle': 'Đồng bộ Google Calendar',
    'syncDone': 'Đã đồng bộ Google Calendar',
    'syncedEvents': 'sự kiện đã đồng bộ',
    'noEvents': 'Không có sự kiện cho ngày này',
    'monthView': 'Xem theo tháng',
    'weekView': 'Xem theo tuần',
    'allDay': 'Cả ngày',
    'personalEvent': 'Sự kiện cá nhân',
    'newEvent': 'Sự kiện mới',
    'nothingScheduled': 'Không có gì trong lịch',
    'nothingScheduledHint':
        'Tận hưởng thời gian rảnh, hoặc thêm sự kiện bằng nút +',
    'googleEventReadOnly':
        'Sự kiện từ Google Calendar. Hãy chỉnh sửa trong Google Calendar.',
    'googleCalendar': 'Google Calendar',
    'connectGoogleTitle': 'Kết nối Google Calendar',
    'connectGoogleHint': 'Xem sự kiện Google cùng với báo thức và công việc.',
    'googleSyncHint': 'Sự kiện được nhập về (chỉ đọc).',
    'connect': 'Kết nối',
    'connected': 'Đã kết nối',
    'notConnected': 'Chưa kết nối',
    'googleConnected': 'Đã kết nối Google Calendar',
    'disconnect': 'Ngắt kết nối',
    'disconnectGoogle': 'Ngắt kết nối Google Calendar',
    'disconnectGoogleConfirm':
        'Các sự kiện đã nhập từ Google sẽ bị xoá khỏi ứng dụng.',
    // tasks
    'addTask': 'Thêm việc',
    'editTask': 'Sửa công việc',
    'taskTitleHint': 'Bạn cần làm gì?',
    'noTasks': 'Không còn việc nào!',
    'noTasksHint': 'Thêm công việc để lên kế hoạch cho ngày của bạn.',
    'noCompletedTasks': 'Chưa có việc nào hoàn thành',
    'allOpen': 'Tất cả',
    'completed': 'Đã xong',
    'priority': 'Mức ưu tiên',
    'addDueDate': 'Thêm hạn chót',
    'reminder': 'Nhắc nhở',
    'priority_low': 'Thấp',
    'priority_medium': 'Trung bình',
    'priority_high': 'Cao',
    'priority_urgent': 'Khẩn cấp',
    // report
    'last30Days': '30 ngày gần nhất',
    'noReportYet': 'Chưa có dữ liệu thức dậy',
    'noReportYetHint': 'Tắt một báo thức và thống kê thức dậy sẽ hiện ở đây.',
    'streakHint': 'Số ngày liên tiếp bạn dậy bằng báo thức',
    'avgWakeTime': 'Giờ dậy trung bình',
    'totalSnoozes': 'Lần báo lại',
    'alarmsDismissed': 'Báo thức đã tắt',
    'avgMissionTime': 'Thời gian làm nhiệm vụ',
    'wakeTimeLast7': 'Giờ thức dậy · 7 ngày qua',
    'history': 'Lịch sử',
    // settings
    'noName': 'Thêm tên của bạn',
    'editProfile': 'Sửa hồ sơ',
    'profileUpdated': 'Đã cập nhật hồ sơ',
    'signedInWithGoogle': 'Đăng nhập bằng Google',
    'appearance': 'Giao diện',
    'theme': 'Chủ đề',
    'themeSystem': 'Hệ thống',
    'themeLight': 'Sáng',
    'themeDark': 'Tối',
    'language': 'Ngôn ngữ',
    'general': 'Chung',
    'notificationPermission': 'Quyền báo thức',
    'notificationPermissionHint':
        'Cho phép thông báo và báo thức chính xác để báo thức reo đúng giờ',
    'permissionGranted': 'Đã cấp quyền',
    'permissionDenied': 'Chưa được cấp quyền — hãy bật trong Cài đặt hệ thống',
    'logout': 'Đăng xuất',
    'logoutConfirm':
        'Báo thức trên thiết bị này sẽ ngừng cho đến khi bạn đăng nhập lại.',
    'deleteAccount': 'Xoá tài khoản',
    'deleteAccountConfirm':
        'Tài khoản và toàn bộ dữ liệu sẽ bị xoá vĩnh viễn. Tiếp tục?',
    // notifications
    'markAllRead': 'Đọc tất cả',
    'noNotifications': 'Không có thông báo',
    // enums
    'difficulty_easy': 'Dễ',
    'difficulty_medium': 'Vừa',
    'difficulty_hard': 'Khó',
    'sound_classic': 'Cổ điển',
    'sound_digital': 'Điện tử',
    'sound_chime': 'Chuông gió',
    'sound_rising': 'Tăng dần',
    'sound_birds': 'Chim hót',
    'mission_none': 'Không nhiệm vụ',
    'mission_math': 'Giải toán',
    'mission_memory': 'Trí nhớ',
    'mission_typing': 'Gõ chữ',
    'mission_shake': 'Lắc máy',
    'mission_walk': 'Đi bộ',
    'mission_puzzle': 'Xếp hình',
    'mission_qr': 'Quét QR / mã vạch',
    'missionDesc_none': 'Chạm để tắt',
    'missionDesc_math': 'Giải toán để đánh thức não bộ',
    'missionDesc_memory': 'Lặp lại thứ tự các ô sáng',
    'missionDesc_typing': 'Gõ lại một câu truyền cảm hứng',
    'missionDesc_shake': 'Lắc mạnh điện thoại',
    'missionDesc_walk': 'Đứng dậy và đi vài bước',
    'missionDesc_puzzle': 'Trượt các ô về đúng thứ tự',
    'missionDesc_qr': 'Quét mã đặt ở phòng khác',
  };
}
