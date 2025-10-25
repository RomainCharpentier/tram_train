#!/bin/bash

# Tests d'intégration manuels avec curl pour l'API SNCF
# Remplacez YOUR_API_KEY par votre vraie clé API SNCF

API_KEY="YOUR_API_KEY"
BASE_URL="https://api.sncf.com/v1/coverage/sncf"
AUTH_HEADER="Authorization: Basic $(echo -n "${API_KEY}:" | base64)"

echo "🚀 Tests d'intégration API SNCF"
echo "================================"

# Test 1: Recherche de gares
echo ""
echo "1️⃣ Test de recherche de gares"
echo "curl -H \"$AUTH_HEADER\" \"$BASE_URL/places?q=Nantes&type[]=stop_area\""
curl -H "$AUTH_HEADER" "$BASE_URL/places?q=Nantes&type[]=stop_area" | jq '.places[0:3]'

echo ""
echo "2️⃣ Test de recherche de gares (Paris)"
echo "curl -H \"$AUTH_HEADER\" \"$BASE_URL/places?q=Paris&type[]=stop_area\""
curl -H "$AUTH_HEADER" "$BASE_URL/places?q=Paris&type[]=stop_area" | jq '.places[0:3]'

# Test 2: Départs d'une gare
echo ""
echo "3️⃣ Test des départs de Nantes"
echo "curl -H \"$AUTH_HEADER\" \"$BASE_URL/stop_areas/stop_area:SNCF:87590349/departures\""
curl -H "$AUTH_HEADER" "$BASE_URL/stop_areas/stop_area:SNCF:87590349/departures" | jq '.departures[0:3]'

# Test 3: Horaires de route (trains passant par la gare)
echo ""
echo "4️⃣ Test des horaires de route"
echo "curl -H \"$AUTH_HEADER\" \"$BASE_URL/stop_areas/stop_area:SNCF:87590349/route_schedules\""
curl -H "$AUTH_HEADER" "$BASE_URL/stop_areas/stop_area:SNCF:87590349/route_schedules" | jq '.route_schedules[0:2]'

# Test 4: Trajets entre deux gares
echo ""
echo "5️⃣ Test de trajets Nantes -> Paris"
echo "curl -H \"$AUTH_HEADER\" \"$BASE_URL/journeys?from=stop_area:SNCF:87590349&to=stop_area:SNCF:87384008\""
curl -H "$AUTH_HEADER" "$BASE_URL/journeys?from=stop_area:SNCF:87590349&to=stop_area:SNCF:87384008" | jq '.journeys[0:2]'

# Test 5: Trajets avec horaire de départ
echo ""
echo "6️⃣ Test de trajets avec horaire de départ"
TOMORROW=$(date -d "+1 day" +%Y%m%d)
DEPARTURE_TIME="${TOMORROW}T09:00:00"
echo "curl -H \"$AUTH_HEADER\" \"$BASE_URL/journeys?from=stop_area:SNCF:87590349&to=stop_area:SNCF:87384008&datetime=$DEPARTURE_TIME\""
curl -H "$AUTH_HEADER" "$BASE_URL/journeys?from=stop_area:SNCF:87590349&to=stop_area:SNCF:87384008&datetime=$DEPARTURE_TIME" | jq '.journeys[0:2]'

# Test 6: Trajets avec horaire d'arrivée
echo ""
echo "7️⃣ Test de trajets avec horaire d'arrivée"
ARRIVAL_TIME="${TOMORROW}T18:00:00"
echo "curl -H \"$AUTH_HEADER\" \"$BASE_URL/journeys?from=stop_area:SNCF:87590349&to=stop_area:SNCF:87384008&datetime_represents=arrival&datetime=$ARRIVAL_TIME\""
curl -H "$AUTH_HEADER" "$BASE_URL/journeys?from=stop_area:SNCF:87590349&to=stop_area:SNCF:87384008&datetime_represents=arrival&datetime=$ARRIVAL_TIME" | jq '.journeys[0:2]'

# Test 7: Informations de gare
echo ""
echo "8️⃣ Test des informations de gare"
echo "curl -H \"$AUTH_HEADER\" \"$BASE_URL/stop_areas/stop_area:SNCF:87590349/stop_schedules\""
curl -H "$AUTH_HEADER" "$BASE_URL/stop_areas/stop_area:SNCF:87590349/stop_schedules" | jq '.stop_schedules[0:2]'

# Test 8: Perturbations
echo ""
echo "9️⃣ Test des perturbations"
echo "curl -H \"$AUTH_HEADER\" \"$BASE_URL/disruptions\""
curl -H "$AUTH_HEADER" "$BASE_URL/disruptions" | jq '.disruptions[0:3]'

# Test 9: Gestion d'erreurs
echo ""
echo "🔟 Test de gestion d'erreurs (ID de gare invalide)"
echo "curl -H \"$AUTH_HEADER\" \"$BASE_URL/stop_areas/stop_area:INVALID:123456/departures\""
curl -H "$AUTH_HEADER" "$BASE_URL/stop_areas/stop_area:INVALID:123456/departures" | jq '.'

echo ""
echo "✅ Tests terminés !"
echo ""
echo "📝 Notes:"
echo "- Remplacez YOUR_API_KEY par votre vraie clé API SNCF"
echo "- Installez jq pour un meilleur formatage JSON: sudo apt install jq"
echo "- Ces tests nécessitent une connexion internet"
echo "- Certains endpoints peuvent retourner des erreurs 404 si les gares n'existent pas"
