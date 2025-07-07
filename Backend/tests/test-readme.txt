# Testy API DzielSie

Ten katalog zawiera testy jednostkowe i integracyjne API aplikacji DzielSie. Testy zostały napisane przy użyciu Jest oraz supertest.

## Struktura katalogów

```
tests/
  ├── config.js             # Konfiguracja testów
  ├── setup.js              # Ustawienia zmiennych środowiskowych dla testów
  ├── run-tests.js          # Skrypt do uruchamiania wszystkich testów
  ├── integration/          # Testy integracyjne
  │   ├── auth.test.js      # Testy API autoryzacji
  │   ├── groups.test.js    # Testy API grup
  │   ├── expenses.test.js  # Testy API wydatków
  │   ├── settlements.test.js # Testy API rozliczeń
  │   └── user.test.js      # Testy API użytkownika
  └── unit/                 # Testy jednostkowe
      └── groupService.test.js # Testy usługi grup
```

## Wymagania

- Node.js (wersja 14+)
- npm lub yarn
- MongoDB (lokalnie lub MongoDB Memory Server)

## Instalacja zależności

Przed uruchomieniem testów należy zainstalować wszystkie zależności:

```bash
npm install
# lub
yarn install
```

## Uruchamianie testów

### Wszystkie testy

Aby uruchomić wszystkie testy, użyj:

```bash
npm test
# lub
yarn test
```

### Testy integracyjne

Aby uruchomić tylko testy integracyjne:

```bash
npx jest tests/integration --runInBand
```

### Testy jednostkowe

Aby uruchomić tylko testy jednostkowe:

```bash
npx jest tests/unit
```

### Uruchamianie pojedynczego pliku testowego

Aby uruchomić tylko jeden plik testowy:

```bash
npx jest tests/integration/auth.test.js
```

### Uruchamianie testów z niestandardowym skryptem

Możesz również użyć niestandardowego skryptu, który uruchomi wszystkie testy w odpowiedniej kolejności:

```bash
node tests/run-tests.js
```

## Konfiguracja

Testy wykorzystują MongoDB Memory Server do przechowywania danych w pamięci podczas testów. Dzięki temu nie jest wymagana osobna baza danych do testów.

Jeśli chcesz zmienić konfigurację, możesz edytować plik `tests/config.js` oraz `tests/setup.js`.

## Dokumentacja testów

### Testy integracyjne

1. **auth.test.js** - Testy API autoryzacji
   - Rejestracja użytkownika
   - Logowanie
   - Odświeżanie tokenów
   - Wylogowanie

2. **groups.test.js** - Testy API grup
   - Tworzenie grup
   - Pobieranie grup użytkownika
   - Pobieranie szczegółów grupy
   - Aktualizacja grupy
   - Dodawanie członków do grupy
   - Usuwanie członków z grupy
   - Zmiana roli członka
   - Archiwizacja grupy
   - Usuwanie grupy

3. **expenses.test.js** - Testy API wydatków
   - Tworzenie wydatków
   - Pobieranie wydatków grupy
   - Pobieranie szczegółów wydatku
   - Aktualizacja wydatku
   - Dodawanie komentarza do wydatku
   - Usuwanie wydatku
   - Sprawdzanie uprawnień dostępu do wydatków

4. **settlements.test.js** - Testy API rozliczeń
   - Pobieranie sald grupy
   - Odświeżanie sald grupy
   - Pobieranie szczegółów rozliczenia
   - Oznaczanie długu jako rozliczony
   - Sprawdzanie uprawnień do oznaczania długów
   - Pobieranie historii rozliczeń

5. **user.test.js** - Testy API użytkownika
   - Pobieranie profilu użytkownika
   - Aktualizacja profilu
   - Zmiana hasła
   - Wyszukiwanie użytkowników
   - Usuwanie konta

### Testy jednostkowe

1. **groupService.test.js** - Testy usługi grup
   - Pobieranie grup użytkownika
   - Tworzenie grupy
   - Pobieranie szczegółów grupy
   - Aktualizacja grupy
   - Usuwanie grupy
   - Sprawdzanie uprawnień administratora
   - Wyszukiwanie grup

## Pisanie nowych testów

Aby dodać nowe testy, należy:

1. Stworzyć nowy plik w odpowiednim katalogu (integration/ lub unit/)
2. Zaimportować potrzebne moduły i funkcje pomocnicze
3. Skonfigurować test przy użyciu funkcji describe() i test()
4. Dodać asercje przy użyciu funkcji expect()

Przykład:

```javascript
// tests/unit/someService.test.js
const someService = require('../../src/api/services/someService');
const { setupDatabase, clearDatabase, closeDatabase } = require('../config');

// Konfiguracja
beforeAll(async () => {
    await setupDatabase();
});

afterAll(async () => {
    await closeDatabase();
});

beforeEach(async () => {
    await clearDatabase();
});

// Testy
describe('Testy someService', () => {
    test('someFunction powinno zwrócić oczekiwany wynik', async () => {
        // Przygotowanie
        const arg = 'test';
        
        // Wykonanie
        const result = await someService.someFunction(arg);
        
        // Sprawdzenie
        expect(result).toBeDefined();
        expect(result.someProperty).toBe('expected value');
    });
});
```

## Rozwiązywanie problemów

### Problemy z połączeniem z bazą danych

Jeśli pojawią się problemy z połączeniem z bazą danych, upewnij się, że MongoDB Memory Server jest poprawnie zainstalowany. Możesz również zmodyfikować plik `tests/config.js`, aby użyć lokalnej instancji MongoDB zamiast pamięciowej.

### Testy są zbyt wolne

Jeśli testy są wykonywane zbyt wolno, możesz spróbować:
1. Uruchamiać tylko potrzebne testy
2. Wyłączyć tryb verbose: `--verbose false`
3. Uruchamiać testy równolegle (nie zalecane dla testów integracyjnych): `--maxWorkers=4`

### Problemy z zależnościami

Jeśli pojawią się problemy z zależnościami, upewnij się, że wszystkie zależności są zainstalowane:

```bash
npm ci
# lub
yarn install --frozen-lockfile
```

## Wskazówki dotyczące testowania

1. **Izolacja** - Każdy test powinien być niezależny od innych.
2. **Czytelność** - Używaj opisowych nazw i komentarzy.
3. **Kompletność** - Testuj zarówno ścieżki pozytywne, jak i negatywne.
4. **Szybkość** - Testy powinny być szybkie. Unikaj niepotrzebnych operacji.
5. **Powtarzalność** - Testy powinny zawsze dawać te same wyniki przy tych samych warunkach.
