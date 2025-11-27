#!/bin/bash
cd /workspaces/Terraria-On-Github
echo "Building Terraria.MonoGame.csproj..."
dotnet build Terraria.MonoGame.csproj -c Release
echo "Build completed!"
