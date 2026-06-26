import 'package:flutter/material.dart';

import 'package:dar_city_app/features/coach/widgets/coach_drills_premium.dart';

/// Attendance screens reuse the same premium motion + widgets as drills.
typedef CoachAttendanceMotion = CoachDrillsMotion;
typedef CoachAttendanceHero = CoachDrillsHero;
typedef CoachAttendanceStaticHeader = CoachDrillsStaticHeader;
typedef CoachAttendanceActionTile = CoachDrillsActionTile;
typedef CoachAttendanceSubmitButton = CoachDrillsSubmitButton;
typedef CoachAttendanceSectionCard = CoachDrillsSectionCard;

PageRouteBuilder<T> coachAttendancePageRoute<T>(Widget page) => coachDrillsPageRoute(page);
