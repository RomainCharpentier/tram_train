# Tests d'intégration manuels avec curl pour l'API SNCF (PowerShell)
# Remplacez YOUR_API_KEY par votre vraie clé API SNCF

$API_KEY = "YOUR_API_KEY"
$BASE_URL = "https://api.sncf.com/v1/coverage/sncf"
$AUTH_HEADER = "Authorization: Basic $([Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes("${API_KEY}:")))"

Write-Host "🚀 Tests d'intégration API SNCF" -ForegroundColor Green
Write-Host "================================" -ForegroundColor Green

# Test 1: Recherche de gares
Write-Host ""
Write-Host "1️⃣ Test de recherche de gares" -ForegroundColor Yellow
Write-Host "curl -H `"$AUTH_HEADER`" `"$BASE_URL/places?q=Nantes&type[]=stop_area`""
try {
    $response = Invoke-RestMethod -Uri "$BASE_URL/places?q=Nantes&type[]=stop_area" -Headers @{"Authorization" = "Basic $([Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes("${API_KEY}:")))"}
    $response.places[0..2] | ConvertTo-Json -Depth 3
} catch {
    Write-Host "Erreur: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""
Write-Host "2️⃣ Test de recherche de gares (Paris)" -ForegroundColor Yellow
Write-Host "curl -H `"$AUTH_HEADER`" `"$BASE_URL/places?q=Paris&type[]=stop_area`""
try {
    $response = Invoke-RestMethod -Uri "$BASE_URL/places?q=Paris&type[]=stop_area" -Headers @{"Authorization" = "Basic $([Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes("${API_KEY}:")))"}
    $response.places[0..2] | ConvertTo-Json -Depth 3
} catch {
    Write-Host "Erreur: $($_.Exception.Message)" -ForegroundColor Red
}

# Test 2: Départs d'une gare
Write-Host ""
Write-Host "3️⃣ Test des départs de Nantes" -ForegroundColor Yellow
Write-Host "curl -H `"$AUTH_HEADER`" `"$BASE_URL/stop_areas/stop_area:SNCF:87590349/departures`""
try {
    $response = Invoke-RestMethod -Uri "$BASE_URL/stop_areas/stop_area:SNCF:87590349/departures" -Headers @{"Authorization" = "Basic $([Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes("${API_KEY}:")))"}
    $response.departures[0..2] | ConvertTo-Json -Depth 3
} catch {
    Write-Host "Erreur: $($_.Exception.Message)" -ForegroundColor Red
}

# Test 3: Horaires de route
Write-Host ""
Write-Host "4️⃣ Test des horaires de route" -ForegroundColor Yellow
Write-Host "curl -H `"$AUTH_HEADER`" `"$BASE_URL/stop_areas/stop_area:SNCF:87590349/route_schedules`""
try {
    $response = Invoke-RestMethod -Uri "$BASE_URL/stop_areas/stop_area:SNCF:87590349/route_schedules" -Headers @{"Authorization" = "Basic $([Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes("${API_KEY}:")))"}
    $response.route_schedules[0..1] | ConvertTo-Json -Depth 3
} catch {
    Write-Host "Erreur: $($_.Exception.Message)" -ForegroundColor Red
}

# Test 4: Trajets entre deux gares
Write-Host ""
Write-Host "5️⃣ Test de trajets Nantes -> Paris" -ForegroundColor Yellow
Write-Host "curl -H `"$AUTH_HEADER`" `"$BASE_URL/journeys?from=stop_area:SNCF:87590349&to=stop_area:SNCF:87384008`""
try {
    $response = Invoke-RestMethod -Uri "$BASE_URL/journeys?from=stop_area:SNCF:87590349&to=stop_area:SNCF:87384008" -Headers @{"Authorization" = "Basic $([Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes("${API_KEY}:")))"}
    $response.journeys[0..1] | ConvertTo-Json -Depth 3
} catch {
    Write-Host "Erreur: $($_.Exception.Message)" -ForegroundColor Red
}

# Test 5: Trajets avec horaire de départ
Write-Host ""
Write-Host "6️⃣ Test de trajets avec horaire de départ" -ForegroundColor Yellow
$tomorrow = (Get-Date).AddDays(1).ToString("yyyyMMdd")
$departureTime = "${tomorrow}T09:00:00"
Write-Host "curl -H `"$AUTH_HEADER`" `"$BASE_URL/journeys?from=stop_area:SNCF:87590349&to=stop_area:SNCF:87384008&datetime=$departureTime`""
try {
    $response = Invoke-RestMethod -Uri "$BASE_URL/journeys?from=stop_area:SNCF:87590349&to=stop_area:SNCF:87384008&datetime=$departureTime" -Headers @{"Authorization" = "Basic $([Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes("${API_KEY}:")))"}
    $response.journeys[0..1] | ConvertTo-Json -Depth 3
} catch {
    Write-Host "Erreur: $($_.Exception.Message)" -ForegroundColor Red
}

# Test 6: Trajets avec horaire d'arrivée
Write-Host ""
Write-Host "7️⃣ Test de trajets avec horaire d'arrivée" -ForegroundColor Yellow
$arrivalTime = "${tomorrow}T18:00:00"
Write-Host "curl -H `"$AUTH_HEADER`" `"$BASE_URL/journeys?from=stop_area:SNCF:87590349&to=stop_area:SNCF:87384008&datetime_represents=arrival&datetime=$arrivalTime`""
try {
    $response = Invoke-RestMethod -Uri "$BASE_URL/journeys?from=stop_area:SNCF:87590349&to=stop_area:SNCF:87384008&datetime_represents=arrival&datetime=$arrivalTime" -Headers @{"Authorization" = "Basic $([Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes("${API_KEY}:")))"}
    $response.journeys[0..1] | ConvertTo-Json -Depth 3
} catch {
    Write-Host "Erreur: $($_.Exception.Message)" -ForegroundColor Red
}

# Test 7: Informations de gare
Write-Host ""
Write-Host "8️⃣ Test des informations de gare" -ForegroundColor Yellow
Write-Host "curl -H `"$AUTH_HEADER`" `"$BASE_URL/stop_areas/stop_area:SNCF:87590349/stop_schedules`""
try {
    $response = Invoke-RestMethod -Uri "$BASE_URL/stop_areas/stop_area:SNCF:87590349/stop_schedules" -Headers @{"Authorization" = "Basic $([Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes("${API_KEY}:")))"}
    $response.stop_schedules[0..1] | ConvertTo-Json -Depth 3
} catch {
    Write-Host "Erreur: $($_.Exception.Message)" -ForegroundColor Red
}

# Test 8: Perturbations
Write-Host ""
Write-Host "9️⃣ Test des perturbations" -ForegroundColor Yellow
Write-Host "curl -H `"$AUTH_HEADER`" `"$BASE_URL/disruptions`""
try {
    $response = Invoke-RestMethod -Uri "$BASE_URL/disruptions" -Headers @{"Authorization" = "Basic $([Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes("${API_KEY}:")))"}
    $response.disruptions[0..2] | ConvertTo-Json -Depth 3
} catch {
    Write-Host "Erreur: $($_.Exception.Message)" -ForegroundColor Red
}

# Test 9: Gestion d'erreurs
Write-Host ""
Write-Host "🔟 Test de gestion d'erreurs (ID de gare invalide)" -ForegroundColor Yellow
Write-Host "curl -H `"$AUTH_HEADER`" `"$BASE_URL/stop_areas/stop_area:INVALID:123456/departures`""
try {
    $response = Invoke-RestMethod -Uri "$BASE_URL/stop_areas/stop_area:INVALID:123456/departures" -Headers @{"Authorization" = "Basic $([Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes("${API_KEY}:")))"}
    $response | ConvertTo-Json -Depth 3
} catch {
    Write-Host "Erreur attendue: $($_.Exception.Message)" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "✅ Tests terminés !" -ForegroundColor Green
Write-Host ""
Write-Host "📝 Notes:" -ForegroundColor Cyan
Write-Host "- Remplacez YOUR_API_KEY par votre vraie clé API SNCF" -ForegroundColor White
Write-Host "- Ces tests nécessitent une connexion internet" -ForegroundColor White
Write-Host "- Certains endpoints peuvent retourner des erreurs 404 si les gares n'existent pas" -ForegroundColor White
