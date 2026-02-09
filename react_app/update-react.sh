#!/bin/bash

echo "🔍 Checking for React library updates..."
# Check specific React-related packages
npm outdated react react-dom @types/react @types/react-dom @vitejs/plugin-react react-i18next

# npm outdated returns 1 if updates are found
if [ $? -eq 0 ]; then
  echo "✅ All React libraries are up to date!"
  exit 0
fi

echo ""
echo "---------------------------------------------------"
read -p "Do you want to update these packages to the latest version? (y/n) " -n 1 -r
echo
echo "---------------------------------------------------"

if [[ $REPLY =~ ^[Yy]$ ]]; then
  echo "🚀 Updating React libraries..."
  # Added i18next because react-i18next requires a newer version of it
  npm install react@latest react-dom@latest @types/react@latest @types/react-dom@latest @vitejs/plugin-react@latest react-i18next@latest i18next@latest
  
  echo "✅ Update complete!"
  echo "⚠️  Don't forget to run 'npm run build' to verify compatibility."
else
  echo "❌ Update cancelled."
fi
