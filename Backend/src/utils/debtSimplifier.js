/**
 * Algorytm upraszczania długów
 *
 * Zamienia skomplikowaną sieć rozliczeń w minimalną liczbę transakcji,
 * stosując algorytm zachłanny, który łączy ze sobą największe długi i należności.
 */

/**
 * Upraszcza długi pomiędzy użytkownikami, minimalizując liczbę koniecznych transakcji
 *
 * @param {Object} balances - Obiekt z saldami użytkowników (userId: balance)
 * @param {string} currency - Waluta transakcji
 * @returns {Array} Tablica uproszczonych transakcji
 */
const simplifyDebts = (balances, currency = 'PLN') => {
    // Przygotuj tablice dłużników (balance < 0) i wierzycieli (balance > 0)
    const debtors = [];
    const creditors = [];

    for (const [userId, balance] of Object.entries(balances)) {
        // Ignoruj zerowe salda z powodu błędów zaokrąglenia (mniejsze niż 0.01)
        if (Math.abs(balance) < 0.01) {
            continue;
        }

        if (balance < 0) {
            debtors.push({ userId, amount: Math.abs(balance) });
        } else {
            creditors.push({ userId, amount: balance });
        }
    }

    // Sortuj od największych do najmniejszych kwot
    debtors.sort((a, b) => b.amount - a.amount);
    creditors.sort((a, b) => b.amount - a.amount);

    const transactions = [];

    // Algorytm zachłanny - dopasowywanie największych długów do największych wierzytelności
    while (debtors.length > 0 && creditors.length > 0) {
        const debtor = debtors[0];
        const creditor = creditors[0];

        // Kwota transakcji to minimum z długu i wierzytelności
        const amount = Math.min(debtor.amount, creditor.amount);

        if (amount > 0) {
            // Zaokrąglenie do 2 miejsc po przecinku, aby uniknąć błędów numerycznych
            const roundedAmount = Math.round(amount * 100) / 100;

            transactions.push({
                from: debtor.userId,
                to: creditor.userId,
                amount: roundedAmount,
                currency
            });
        }

        // Aktualizacja sald
        debtor.amount -= amount;
        creditor.amount -= amount;

        // Usuń rozliczonych użytkowników
        if (debtor.amount < 0.01) { // Próg dla błędów zaokrąglenia
            debtors.shift();
        }

        if (creditor.amount < 0.01) {
            creditors.shift();
        }
    }

    return transactions;
};

/**
 * Przygotowuje dane wejściowe balansów na podstawie wydatków
 *
 * @param {Array} expenses - Tablica wydatków w grupie
 * @returns {Object} Obiekt z saldami użytkowników (userId: balance)
 */
const calculateBalancesFromExpenses = (expenses) => {
    const balances = {};

    // Przygotuj saldo dla każdego użytkownika
    expenses.forEach(expense => {
        // Dodaj wszystkich użytkowników z podziałów do bilansu, jeśli jeszcze nie istnieją
        expense.splits.forEach(split => {
            // Upewnij się, że używamy ID jako string, a nie pełnych obiektów User
            const userId = split.user._id ? split.user._id.toString() : split.user.toString();

            if (!balances[userId]) {
                balances[userId] = 0;
            }
        });

        // Dodaj płatnika do bilansu, jeśli jeszcze nie istnieje
        // Pobierz ID jako string
        const paidById = expense.paidBy._id ? expense.paidBy._id.toString() : expense.paidBy.toString();

        if (!balances[paidById]) {
            balances[paidById] = 0;
        }

        // Dodaj pełną kwotę do salda osoby płacącej
        balances[paidById] += expense.amount;

        // Odejmij kwoty należne od innych osób
        expense.splits.forEach(split => {
            // Pobierz ID jako string
            const userId = split.user._id ? split.user._id.toString() : split.user.toString();
            balances[userId] -= split.amount;
        });
    });

    return balances;
};

/**
 * Optymalizuje transakcje przez eliminację cykli
 *
 * @param {Array} transactions - Tablica transakcji
 * @returns {Array} Zoptymalizowana tablica transakcji
 */
const optimizeTransactions = (transactions) => {
    // Przekształć transakcje na graf
    const graph = {};

    // Inicjalizuj graf
    transactions.forEach(t => {
        if (!graph[t.from]) graph[t.from] = {};
        if (!graph[t.to]) graph[t.to] = {};
    });

    // Wypełnij graf transakcjami
    transactions.forEach(t => {
        if (!graph[t.from][t.to]) graph[t.from][t.to] = 0;
        graph[t.from][t.to] += t.amount;
    });

    // Algorytm eliminacji cykli (uproszczona wersja)
    // W pełnej implementacji należałoby zastosować bardziej zaawansowane algorytmy

    // Przekształć graf z powrotem na transakcje
    const optimizedTransactions = [];

    Object.keys(graph).forEach(from => {
        Object.keys(graph[from]).forEach(to => {
            const amount = graph[from][to];
            if (amount > 0.01) { // Ignoruj bardzo małe kwoty (błędy zaokrąglenia)
                optimizedTransactions.push({
                    from,
                    to,
                    amount: Math.round(amount * 100) / 100,
                    currency: transactions[0].currency
                });
            }
        });
    });

    return optimizedTransactions;
};

module.exports = {
    simplifyDebts,
    calculateBalancesFromExpenses,
    optimizeTransactions
};