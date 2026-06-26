/// V2 feature API — models & services for 17 new screens.
/// See [API_SPEC_V2.md] at project root for backend contract.
library features_api;

export 'shared/json_parse.dart';
export 'shared/api/feature_api_client.dart';

export 'shared/models/chat_contact.dart';
export 'shared/models/chat_conversation.dart';
export 'coach/models/announcement.dart';
export 'coach/models/coach_dashboard.dart';
export 'coach/models/drill.dart';
export 'coach/models/training_session.dart';
export 'coach/services/coach_announcement_service.dart';
export 'coach/services/coach_chat_service.dart';
export 'coach/services/coach_dashboard_service.dart';
export 'coach/services/coach_drill_service.dart';
export 'coach/services/coach_training_session_service.dart';

export 'player/models/assigned_drill.dart';
export 'player/models/chat_message.dart';
export 'player/models/player_feedback.dart';
export 'player/services/player_chat_service.dart';
export 'player/services/player_dashboard_service.dart';
export 'player/services/player_drill_service.dart';
export 'player/services/player_feedback_service.dart';

export 'attendance/models/attendance_models.dart';
export 'attendance/services/attendance_service.dart';

export 'discipline/models/discipline_models.dart';
export 'discipline/services/discipline_service.dart';
