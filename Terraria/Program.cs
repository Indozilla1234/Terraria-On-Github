using System;
using System.IO;
#if WINDOWS
using System.Windows.Forms;
#endif
namespace Terraria
{
	internal static class Program
	{
		private static void Main(string[] args)
		{
			// Check if running in headless/VNC mode
			bool headlessMode = Environment.GetEnvironmentVariable("HEADLESS_TERRARIA") == "1" || 
			                    !string.IsNullOrEmpty(Environment.GetEnvironmentVariable("DISPLAY"));
			
			if (headlessMode)
			{
				Console.WriteLine("=== Terraria - Headless/VNC Mode ===");
				Console.WriteLine("Graphics device initialization may fail gracefully.");
				Console.WriteLine("This is expected in containerized/headless environments.");
			}

			// Determine if headless was requested via flag or environment
			bool isHeadless = false;
			for (int i = 0; i < args.Length; i++)
			{
				if (args[i].ToLower() == "-headless")
				{
					isHeadless = true;
				}
			}
			// If running in headless mode, avoid creating Main (which initializes MonoGame/OpenGL).
			if (isHeadless || headlessMode)
			{
				Console.WriteLine("Headless mode active - not instantiating game; process will remain alive for connections.");
				// Keep the process alive so remote connections / server features can function
				System.Threading.Thread.Sleep(int.MaxValue);
				return;
			}
			using (Main main = new Main())
			{
				try
				{
					for (int i = 0; i < args.Length; i++)
					{
						if (args[i].ToLower() == "-port" || args[i].ToLower() == "-p")
						{
							i++;
							try
							{
								int serverPort = Convert.ToInt32(args[i]);
								Netplay.serverPort = serverPort;
							}
							catch
							{
							}
						}
						if (args[i].ToLower() == "-join" || args[i].ToLower() == "-j")
						{
							i++;
							try
							{
								main.AutoJoin(args[i]);
							}
							catch
							{
							}
						}
						if (args[i].ToLower() == "-pass" || args[i].ToLower() == "-password")
						{
							i++;
							Netplay.password = args[i];
							main.AutoPass();
						}
						if (args[i].ToLower() == "-host")
						{
							main.AutoHost();
						}
						if (args[i].ToLower() == "-loadlib")
						{
							i++;
							string path = args[i];
							main.loadLib(path);
						}
					}
					Steam.Init();
					// If running explicitly in headless mode we already returned earlier. Proceed normally.
					if (Steam.SteamInit)
					{
						try
						{
							main.Run();
						}
						catch (Exception graphicsEx)
						{
							// Unexpected graphics exception on non-headless run
							Console.WriteLine($"Graphics initialization failed: {graphicsEx}");
							throw;
						}
					}
					else
					{
#if WINDOWS
						MessageBox.Show("Please launch the game from your Steam client.", "Error");
#else
						Console.WriteLine("Please launch the game from your Steam client.");
#endif
					}
				}
				catch (Exception ex)
				{
					try
					{
						using (StreamWriter streamWriter = new StreamWriter("client-crashlog.txt", true))
						{
							streamWriter.WriteLine(DateTime.Now);
							streamWriter.WriteLine(ex);
							streamWriter.WriteLine("/n");
						}
#if WINDOWS
						MessageBox.Show(ex.ToString(), "Terraria: Error");
#else
						Console.WriteLine(ex.ToString());
#endif
					}
					catch
					{
					}
				}
			}
		}
	}
}
