#!/usr/bin/env bash
set -euo pipefail

# Set default values
default_delay=15 # Default delay between 2 service redeploy
payload='{}' # Optional curl payload
portainerWebHookPath="api/stacks/webhooks"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <portainer_host>"
    exit 1
else
    portainerURL="${1}"
    echo "✅ Using Portainer URL: $portainerURL"
fi

if [ -z "$(find "$SCRIPT_DIR" -name '*.json' -print -quit)" ]; then
    echo "❌ *.json not found in $SCRIPT_DIR"
    exit 1
else
    # Find all JSON files in the directory
    find "$SCRIPT_DIR" -name "*.json" | while read -r JsonFile; do
        echo "🗒️ Processing $JsonFile"

        while read -r service; do
            delay=$(echo "$service" | jq -r '.delay')
            name=$(echo "$service" | jq -r '.name')
            containerToStop=$(echo "$service" | jq -r '.containerToStop')
            webhook=$(echo "$service" | jq -r '.webhook')

            if [ -n "$webhook" ]; then
                answers=$(curl --insecure -s -o /dev/null -w "%{http_code}" \
                -X POST -H "Content-Type: application/json" \
                -d "$payload" "$portainerURL/$portainerWebHookPath/$webhook")

                if [ "$answers" -ge 200 ] && [ "$answers" -lt 300 ]; then
                    echo "🛜 Send request for $name ($webhook)"

                    if [ -z "$delay" ] || [ "$delay" = "null" ]; then
                        delay=$default_delay
                    fi

                    if [ -n "$containerToStop" ] && [ "$containerToStop" != "null" ]; then
                        start_time=$(date +%s)
                        readarray -t containers < <(echo "$service" | jq -r '.containerToStop[]')
                        
                        for container in "${containers[@]}"; do
                            echo "⏳ Waiting for $container to be healthy or $delay seconds..."
                            is_healthy=false
                            previous_state=""
                            start_time=$(date +%s)

                            if docker inspect "$container" >/dev/null 2>&1; then

                                while [ "$(($(date +%s) - start_time))" -lt "$delay" ]; do
                                    sleep $default_delay
                                    status=$(docker inspect --format '{{if .State.Health}}{{.State.Health.Status}}{{else}}{{.State.Status}}{{end}}' "$container" 2>/dev/null)

                                    if [ -z "$previous_state" ]; then
                                        previous_state="unknown"
                                    else
                                        previous_state=$status
                                    fi

                                    if [ "$status" != "$previous_state" ]; then
                                        echo "State of $container = $status"
                                    fi

                                    if [ "$status" = "healthy" ]; then
                                        is_healthy=true
                                        break
                                    fi

                                    if [ "$status" = "running" ]; then
                                        is_healthy=true
                                    fi
                                done

                                if [ "$is_healthy" = true ]; then
                                    echo "✅ $container is Started and healthy ($status)"
                                elif [ "$is_healthy" = true && "$status" = "healthy" ]; then
                                    echo "✅ $container is Started but has no health check ($status)"
                                else
                                    echo "⚠️ $container did not become healthy/running after $delay seconds"
                                fi

                                echo "⏳ Stopping $container..."
                                docker ps --filter "name=$container" --format '{{.Names}}' | xargs -r docker stop >/dev/null 2>&1
                            else
                                echo "⚠️  Container $container does not exist."
                            fi
                        done
                    else
                        echo "✅ Waiting $delay seconds before continuing..."
                        sleep "$delay"
                    fi
                else
                    echo "❌ Failed: to $name ($webhook) - HTTP status code: $answers"
                fi
            else
                echo "⚠️  No webhook found for service: $name"
            fi
        done < <(jq -c '.[]' "$JsonFile")
    done
fi

echo "✅ All services from all JSON files have been redeployed."
