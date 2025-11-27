Put the required Microsoft XNA assemblies here (Windows-only DLLs).

Required DLLs (place into this folder):
- Microsoft.Xna.Framework.dll
- Microsoft.Xna.Framework.Game.dll
- Microsoft.Xna.Framework.Graphics.dll
- Microsoft.Xna.Framework.Xact.dll

Where to get them:
- Install "Microsoft XNA Game Studio 4.0" on a Windows machine; the DLLs are typically under
  `C:\Program Files (x86)\Microsoft XNA\` or in the reference assemblies for .NET Framework.

Notes:
- These DLLs are part of Microsoft's XNA; only copy them here if you have them legally (from a Windows installation).
- After placing the DLLs, build with MSBuild/Mono's msbuild (or Visual Studio on Windows).
- This is a pragmatic short-term solution; a longer-term cross-platform approach is to port to MonoGame or FNA.
