// tests/run-tests.js
const { execSync } = require('child_process');
const path = require('path');
const fs = require('fs');

// Ustawienie zmiennych środowiskowych
process.env.NODE_ENV = 'test';
process.env.JWT_SECRET = 'test-secret-key';
process.env.JWT_REFRESH_SECRET = 'test-refresh-secret-key';

// Ścieżka do katalogu z testami
const testsDir = path.join(__dirname);
const unitTestsDir = path.join(testsDir, 'unit');
const integrationTestsDir = path.join(testsDir, 'integration');

// Kolory do formatowania wyjścia
const colors = {
    reset: '\x1b[0m',
    bright: '\x1b[1m',
    dim: '\x1b[2m',
    underscore: '\x1b[4m',
    blink: '\x1b[5m',
    reverse: '\x1b[7m',
    hidden: '\x1b[8m',
    
    fg: {
        black: '\x1b[30m',
        red: '\x1b[31m',
        green: '\x1b[32m',
        yellow: '\x1b[33m',
        blue: '\x1b[34m',
        magenta: '\x1b[35m',
        cyan: '\x1b[36m',
        white: '\x1b[37m'
    },
    
    bg: {
        black: '\x1b[40m',
        red: '\x1b[41m',
        green: '\x1b[42m',
        yellow: '\x1b[43m',
        blue: '\x1b[44m',
        magenta: '\x1b[45m',
        cyan: '\x1b[46m',
        white: '\x1b[47m'
    }
};

// Funkcja pomocnicza do uruchamiania testów
const runTests = (testFiles) => {
    for (const file of testFiles) {
        const testFile = path.basename(file);
        try {
            console.log(`${colors.fg.cyan}Uruchamianie testu: ${colors.fg.yellow}${testFile}${colors.reset}`);
            execSync(`npx jest ${file} --verbose`, { stdio: 'inherit' });
            console.log(`${colors.fg.green}✓ Test zakończony pomyślnie: ${testFile}${colors.reset}\n`);
        } catch (error) {
            console.error(`${colors.fg.red}✗ Test zakończony niepowodzeniem: ${testFile}${colors.reset}\n`);
            process.exit(1);
        }
    }
};

// Główna funkcja uruchamiająca testy
const runAllTests = () => {
    try {
        console.log(`${colors.bright}${colors.fg.blue}========================================${colors.reset}`);
        console.log(`${colors.bright}${colors.fg.blue}   Uruchamianie testów jednostkowych   ${colors.reset}`);
        console.log(`${colors.bright}${colors.fg.blue}========================================${colors.reset}\n`);
        
        // Pobierz wszystkie pliki testów jednostkowych
        const unitTests = fs.readdirSync(unitTestsDir)
            .filter(file => file.endsWith('.test.js'))
            .map(file => path.join(unitTestsDir, file));
        
        runTests(unitTests);
        
        console.log(`${colors.bright}${colors.fg.blue}===========================================${colors.reset}`);
        console.log(`${colors.bright}${colors.fg.blue}   Uruchamianie testów integracyjnych   ${colors.reset}`);
        console.log(`${colors.bright}${colors.fg.blue}===========================================${colors.reset}\n`);
        
        // Pobierz wszystkie pliki testów integracyjnych
        const integrationTests = fs.readdirSync(integrationTestsDir)
            .filter(file => file.endsWith('.test.js'))
            .map(file => path.join(integrationTestsDir, file));
        
        runTests(integrationTests);
        
        console.log(`${colors.bright}${colors.fg.green}====================================${colors.reset}`);
        console.log(`${colors.bright}${colors.fg.green}   Wszystkie testy zakończone!   ${colors.reset}`);
        console.log(`${colors.bright}${colors.fg.green}====================================${colors.reset}\n`);
    } catch (error) {
        console.error(`${colors.fg.red}Błąd podczas uruchamiania testów: ${error.message}${colors.reset}`);
        process.exit(1);
    }
};

// Uruchom wszystkie testy
runAllTests();
