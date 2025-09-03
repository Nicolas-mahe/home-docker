#!/bin/sh
set -e

echo "🔧 Configuration de skeletondirectory via OCC..."
php occ config:system:set skeletondirectory --value=''
echo "✅ skeletondirectory configuré."
