using System;
using System.Runtime.InteropServices;
#if WINDOWS
using System.Windows.Forms;
#endif
namespace Terraria
{
	public class keyBoardInput
	{
		public static event Action<char> newKeyEvent;

#if WINDOWS
		public class inKey : IMessageFilter
		{
			public bool PreFilterMessage(ref Message m)
			{
				if (m.Msg == 258)
				{
					char c = (char)((int)m.WParam);
					Console.WriteLine(c);
					if (keyBoardInput.newKeyEvent != null)
					{
						keyBoardInput.newKeyEvent(c);
					}
				}
				else
				{
					if (m.Msg == 256)
					{
						IntPtr intPtr = Marshal.AllocHGlobal(Marshal.SizeOf(m));
						Marshal.StructureToPtr(m, intPtr, true);
						keyBoardInput.TranslateMessage(intPtr);
					}
				}
				return false;
			}
		}

		[DllImport("user32.dll", CallingConvention = CallingConvention.StdCall, CharSet = CharSet.Auto)]
		public static extern bool TranslateMessage(IntPtr message);

		static keyBoardInput()
		{
			Application.AddMessageFilter(new keyBoardInput.inKey());
		}
#else
		// Non-Windows stub: no message filtering available.
		public static bool TranslateMessage(IntPtr message)
		{
			return false;
		}

		static keyBoardInput()
		{
			// No-op on non-Windows platforms.
		}
#endif
	}
}
