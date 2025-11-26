using System;
using System.Runtime.InteropServices;
namespace Terraria
{
	public class Steam
	{
		public static bool SteamInit;

#if WINDOWS
		[DllImport("steam_api.dll")]
		private static extern bool SteamAPI_Init();
		[DllImport("steam_api.dll")]
		private static extern bool SteamAPI_Shutdown();
		
		public static void Init()
		{
			Steam.SteamInit = Steam.SteamAPI_Init();
		}
		public static void Kill()
		{
			Steam.SteamAPI_Shutdown();
		}
#else
		// Non-Windows stub: Steam is not available on this platform.
		public static void Init()
		{
			Steam.SteamInit = true;  // Allow game to run without Steam on non-Windows.
		}
		public static void Kill()
		{
			// No-op on non-Windows.
		}
#endif
	}
}
