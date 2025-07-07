# DzielSieApp

Do zaimplementowania 
1. Rozliczenia i płatności
Widzę, że istnieje struktura dla rozliczeń (Settlement), ale funkcjonalność jest niepełna:

Brakuje widoku do zarządzania rozliczeniami (wyświetlanie kto komu jest winien pieniądze)
Nie ma zaimplementowanego procesu oznaczania długów jako zapłaconych
Nie ma systemu powiadomień o nowych rozliczeniach lub przypomnieniach o płatnościach

2. Raportowanie i statystyki
Aplikacja nie zawiera:

Widoku statystyk wydatków (wykresy, podsumowania)
Możliwości filtrowania wydatków po kategoriach, datach, użytkownikach
Raportów miesięcznych/rocznych
Eksportu danych (np. do CSV)

3. Zarządzanie profilem użytkownika
Brakuje pełnej funkcjonalności zarządzania profilem:

Możliwości zmiany danych profilowych (zdjęcie profilowe, hasło)
Ustawień preferencji (domyślna waluta, język, powiadomienia)
Historii aktywności użytkownika

4. Zaawansowane zarządzanie wydatkami
Nie ma:

Wydatków cyklicznych (powtarzających się)
Możliwości dodawania etykiet/tagów do wydatków
Załączników (np. zdjęć paragonów) - część kodu istnieje, ale brak implementacji w UI
Komentowania wydatków przez członków grupy

5. Zarządzanie powiadomieniami
Brakuje:

Systemu powiadomień push
Powiadomień e-mail
Ustawień pozwalających określić, o jakich wydarzeniach użytkownik chce być informowany

6. Internacjonalizacja i lokalizacja

Brak wsparcia dla wielu języków
Brak obsługi różnych formatów walut i dat

7. Integracje z zewnętrznymi serwisami

Brak możliwości integracji z systemami płatności (PayPal, BLIK)
Brak możliwości importowania danych z zewnętrznych źródeł (np. z konta bankowego)

8. Funkcje społecznościowe

Brak listy "znajomych" z którymi użytkownik często dzieli wydatki
Brak możliwości wysłania zaproszenia przez link lub kod

9. Bezpieczeństwo i prywatność

Brak dwustopniowej weryfikacji (2FA)
Brak zarządzania sesjami (wylogowanie ze wszystkich urządzeń)
Brak opcji eksportu lub usunięcia danych użytkownika (RODO/GDPR)

10. Funkcjonalność offline

Brak synchronizacji offline (możliwość dodawania wydatków bez dostępu do internetu)
Brak przechowywania lokalnego cache danych

11. Pełnego zarządzania kategoriami wydatków

Brak możliwości tworzenia własnych kategorii wydatków
Brak hierarchii kategorii
