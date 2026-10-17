# Debugging Session: notification-delivery-failure

## Issue Description
- **Symptoms:** Local notifications are not being delivered at the scheduled time (13:00) despite permissions showing as "Active" in the settings. Other apps' notifications are working fine.
- **Environment:** Android 13+ (Xiaomi 21091116UG), Flutter `flutter_local_notifications` plugin.
- **Impact:** Core functionality (reminders) is failing silently.

## Hypotheses
1.  **Hypothesis A (Timezone/UTC Mismatch):** The scheduled time is being calculated in UTC instead of local timezone (Europe/Madrid), causing the notification to trigger at the wrong time.
2.  **Hypothesis B (Exact Alarm Permission Missing):** On Android 13+, scheduling exact alarms requires the `SCHEDULE_EXACT_ALARM` permission. Even if basic notification permissions are granted, without this, exact time scheduling fails silently.
3.  **Hypothesis C (Scheduling Logic Error):** The ID generation or date calculation logic in `notification_service.dart` is generating invalid payload data that the Android OS rejects.
4.  **Hypothesis D (Battery Optimization / Doze Mode):** Xiaomi's aggressive battery management is killing the background alarm manager because the app is not whitelisted, despite `BOOT_COMPLETED` being present.

## Evidence Collection (Logs)
*(Pending instrumentation...)*

## Status
[OPEN]