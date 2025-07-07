 DzielSie API

## Wprowadzenie
DzielSie API to kompleksowy system backendowy do zarządzania i dzielenia wydatków w grupach. Umożliwia użytkownikom tworzenie grup, dodawanie wydatków, dzielenie kosztów między członkami grupy oraz śledzenie rozliczeń. To RESTowe API udostępnia endpointy do autoryzacji, zarządzania użytkownikami, zarządzania grupami, śledzenia wydatków i rozliczeń.

## URL bazowy
- **Produkcja:** `https://dzielsieapp-aceua3ewcva9dkhw.canadacentral-01.azurewebsites.net`
- **Rozwój:** `http://localhost:5545`

## Autoryzacja
API wykorzystuje JWT (JSON Web Token) do autoryzacji. Wszystkie endpointy wymagające autoryzacji oczekują ważnego tokenu w nagłówku `Authorization`.

### Proces autoryzacji
1. Zarejestruj nowego użytkownika lub zaloguj się, aby otrzymać tokeny.
2. Dołącz token JWT w nagłówku `Authorization` do kolejnych żądań.
3. Użyj tokenu odświeżającego, aby uzyskać nowy JWT po jego wygaśnięciu.

## Endpointy autoryzacji
### Rejestracja nowego użytkownika
```
POST /api/auth/register
```
#### Treść żądania:
```json
{
  "firstName": "Jan",
  "lastName": "Kowalski",
  "email": "jan.kowalski@example.com",
  "password": "StrongPass123",
  "phoneNumber": "+48123456789"
}
```
#### Odpowiedź (201):
```json
{
  "success": true,
  "message": "Rejestracja zakończona pomyślnie",
  "token": "...",
  "refreshToken": "...",
  "user": {
    "id": "60d21b4667d0d8992e610c85",
    "firstName": "Jan",
    "lastName": "Kowalski",
    "email": "jan.kowalski@example.com",
    "defaultCurrency": "PLN",
    "language": "pl"
  }
}
```

### Logowanie
```
POST /api/auth/login
```
#### Treść żądania:
```json
{
  "email": "jan.kowalski@example.com",
  "password": "StrongPass123"
}
```
#### Odpowiedź (200):
```json
{
  "success": true,
  "message": "Logowanie zakończone pomyślnie",
  "token": "...",
  "refreshToken": "...",
  "user": {
    "_id": "60d21b4667d0d8992e610c85",
    "firstName": "Jan",
    "lastName": "Kowalski",
    "email": "jan.kowalski@example.com",
    "defaultCurrency": "PLN",
    "language": "pl"
  }
}
```

### Odświeżanie tokenu
```
POST /api/auth/refresh-token
```
#### Treść żądania:
```json
{
  "refreshToken": "..."
}
```
#### Odpowiedź (200):
```json
{
  "success": true,
  "token": "...",
  "refreshToken": "..."
}
```

### Wylogowanie
```
POST /api/auth/logout
```
#### Nagłówki:
```
Authorization: Bearer ...
```
#### Odpowiedź (200):
```json
{
  "success": true,
  "message": "Wylogowanie zakończone pomyślnie"
}
```

## Zarządzanie użytkownikami

###Pobieranie Ostatnich aktywnosci uzytkownika
```
GET /api/users/activities
```
#### Nagłówki:
```
Authorization: Bearer ...
```
#### Odpowiedź (200):
```json
{
  "success": true,
  "activities": [
    {
      "id": "67f3b37e82ccbd8b0d446d85",
      "type": "newExpense",
      "title": "Dodałeś wydatek: 123",
      "subtitle": "Test Group UI • -1 dni temu",
      "amount": 25,
      "currency": "EUR",
      "date": "2025-04-07T13:13:52.766Z",
      "iconName": "creditcard.fill",
      "groupId": "67f37dd234b62852d17d9f96",
      "expenseId": "67f3b37e82ccbd8b0d446d85"
    },
    {
      "id": "67f38a5a34b62852d17da1e5",
      "type": "newExpense",
      "title": "Dodałeś wydatek: Qhdjd",
      "subtitle": "Grupa testowa • dzisiaj",
      "amount": 1,
      "currency": "PLN",
      "date": "2025-04-07T10:18:12.486Z",
      "iconName": "creditcard.fill",
      "groupId": "67f2ba565115ac82389cb762",
      "expenseId": "67f38a5a34b62852d17da1e5"
    }
  ]
}
```

### Pobieranie profilu
```
GET /api/users/me
```
#### Nagłówki:
```
Authorization: Bearer ...
```
#### Odpowiedź (200):
```json
{
  "success": true,
  "user": {
    "_id": "...",
    "firstName": "Jan",
    "lastName": "Kowalski",
    "email": "jan.kowalski@example.com",
    "defaultCurrency": "PLN",
    "language": "pl",
    "notificationSettings": {
      "newExpense": true,
      "settlementRequest": true,
      "groupInvite": true
    }
  }
}
```

### Aktualizacja profilu
```
PUT /api/users/me
```
#### Treść żądania:
```json
{
  "firstName": "Jan",
  "lastName": "Nowak",
  "defaultCurrency": "EUR",
  "language": "en",
  "notificationSettings": {
    "newExpense": true,
    "settlementRequest": false,
    "groupInvite": true
  }
}
```

#### Odpowiedź (200):
```json
{
  "success": true,
  "message": "Profil zaktualizowany pomyślnie",
  "user": {
    "_id": "60d21b4667d0d8992e610c85",
    "firstName": "Jan",
    "lastName": "Kowalski",
    "email": "jan.kowalski@example.com",
    "avatar": "https://dziel-sie.pl/avatars/default.png",
    "defaultCurrency": "PLN",
    "language": "pl",
    "notificationSettings": {
      "newExpense": true,
      "settlementRequest": true,
      "groupInvite": true
    }
  }
}
```

### Zmiana hasła
```
PUT /api/users/me/password
```
#### Treść żądania:
```json
{
  "currentPassword": "StrongPass123",
  "newPassword": "NewStrongPass456"
}
```
#### Odpowiedź (200):
```json
{
  "success": true,
  "message": "Hasło zostało zmienione pomyślnie"
}
```

### Wyszukiwanie użytkowników
```
GET /api/users/search?query=kowalski
```

#### Odpowiedź (200):
```json
{
  "success": true,
  "users": [
    {
      "_id": "60d21b4667d0d8992e610c85",
      "firstName": "Jan",
      "lastName": "Kowalski",
      "email": "jan.kowalski@example.com",
      "avatar": "/uploads/avatars/default.png"
    }
  ]
}
```

## Zarządzanie grupami
### Tworzenie grupy
```
POST /api/groups
```
#### Treść żądania:
```json
{
  "name": "Wyjazd w góry",
  "description": "Wspólne wydatki z wyjazdu w Tatry",
  "defaultCurrency": "PLN"
}
```

### Pobieranie grup użytkownika
```
GET /api/groups
```

### Pobieranie szczegółów grupy
```
GET /api/groups/{id}
```

### Dodawanie członka do grupy
```
POST /api/groups/{id}/members
```
#### Treść żądania:
```json
{
  "email": "anna.nowak@example.com",
  "role": "member"
}
```

## Zarządzanie wydatkami
### Tworzenie wydatku
```
POST /api/expenses
```
#### Treść żądania:
```json
{
  "group": "...",
  "description": "Zakupy spożywcze",
  "amount": 157.80,
  "currency": "PLN",
  "paidBy": "...",
  "date": "2023-08-15T14:30:00Z",
  "category": "food",
  "splitType": "equal",
  "splits": [
    { "user": "...", "amount": 78.90 },
    { "user": "...", "amount": 78.90 }
  ]
}
```

### Pobieranie wydatków grupy
```
GET /api/groups/{groupId}/expenses
```

## Rozliczenia
### Pobieranie sald grupy
```
GET /api/groups/{groupId}/balances
```
#### Nagłówki:
```
Authorization: Bearer ...
```
#### Odpowiedź (200):
```json
{
  "success": true,
  "balances": [
    {
      "from": {
        "id": "user1_id",
        "firstName": "Jan",
        "lastName": "Kowalski"
      },
      "to": {
        "id": "user2_id",
        "firstName": "Anna",
        "lastName": "Nowak"
      },
      "amount": 78.90,
      "currency": "PLN"
    }
  ]
}
```

### Propozycja spłaty
```
POST /api/groups/{groupId}/settlements/propose
```
#### Treść żądania:
```json
{
  "toUserId": "user2_id",
  "amount": 50.00,
  "currency": "PLN",
  "note": "Częściowa spłata za zakupy"
}
```
#### Odpowiedź (201):
```json
{
  "success": true,
  "message": "Propozycja spłaty została wysłana"
}
```

### Akceptacja lub odrzucenie spłaty
```
POST /api/settlements/{settlementId}/respond
```
#### Treść żądania:
```json
{
  "status": "accepted"
}
```
#### Odpowiedź (200):
```json
{
  "success": true,
  "message": "Spłata została zaakceptowana"
}
```

### Historia rozliczeń grupy
```
GET /api/groups/{groupId}/settlements
```
#### Odpowiedź:
```json
{
  "success": true,
  "settlements": [
    {
      "id": "settlement123",
      "from": {
        "id": "user1_id",
        "firstName": "Jan",
        "lastName": "Kowalski"
      },
      "to": {
        "id": "user2_id",
        "firstName": "Anna",
        "lastName": "Nowak"
      },
      "amount": 50.00,
      "currency": "PLN",
      "status": "accepted",
      "date": "2024-03-12T10:15:00Z",
      "note": "Częściowa spłata za zakupy"
    }
  ]
}
```

---

> **Uwaga:** Powyższy plik zawiera wszystkie przesłane dane. Jeśli chcesz, mogę podzielić go na sekcje i dodać spis treści z linkami do nagłówków, albo wygenerować wersję HTML lub PDF.

