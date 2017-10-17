public with sharing class UTIL_Log {
	/* Debug Code */
	public static void start() {
		UTIL_Log.debugJson('--START--', 'DEBUG', null);
	}
	public static void end() {
		UTIL_Log.debugJson('--END--', 'DEBUG', null);
	}
	public static void d(String s, Object o) {
		UTIL_Log.debugJson(s, 'DEBUG', o);
	}
	public static void i(String s, Object o) {
		UTIL_Log.debugJson(s, 'INFO', o);
	}
	public static void e(String s, Object o) {
		UTIL_Log.debugJson(s, 'ERROR', o);
	}
	public static void d(String s) {
		UTIL_Log.debugJSON(s,'DEBUG','');
	}
	public static void debugJson(String s, String level, Object o) {
		DebugObject debugObj = new DebugObject(s, level, o);

		System.debug(LoggingLevel.ERROR, JSON.serialize(debugObj));
	}
	public class DebugObject {
		String key;
		DateTime timestamp;
		Object data;
		String level;

		public DebugObject(String key, String level, Object data) {
			this.key = key;
			this.level = level;
			this.timestamp = DateTime.now();
			this.data = data;
		}
	}
}