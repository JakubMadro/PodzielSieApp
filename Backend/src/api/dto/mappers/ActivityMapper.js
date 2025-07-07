/**
 * Mapper do konwersji wydatków na aktywności
 */
class ActivityMapper {
    /**
     * Formatuje datę względną (np. "dzisiaj", "wczoraj", "3 dni temu")
     * @param {Date} date - Data do sformatowania
     * @returns {string} Sformatowana data
     */
    static formatRelativeDate(date) {
        const now = new Date();
        const diffInDays = Math.floor((now - date) / (1000 * 60 * 60 * 24));

        if (diffInDays === 0) return 'dzisiaj';
        if (diffInDays === 1) return 'wczoraj';
        if (diffInDays < 7) return `${diffInDays} dni temu`;

        return date.toLocaleDateString();
    }

    /**
     * Konwertuje wydatki na aktywności
     * @param {Array} expenses - Lista wydatków
     * @param {string} currentUserId - ID aktualnego użytkownika
     * @returns {Array} Lista aktywności
     */
    static fromExpenses(expenses, currentUserId) {
        return expenses.map(expense => {
            const isCurrentUserPayer = expense.paidBy._id.toString() === currentUserId.toString();

            return {
                id: expense._id,
                type: 'newExpense',
                title: isCurrentUserPayer
                    ? `Dodałeś wydatek: ${expense.description}`
                    : `${expense.paidBy.firstName} dodał: ${expense.description}`,
                subtitle: `${expense.group.name} • ${this.formatRelativeDate(expense.date)}`,
                amount: expense.amount,
                currency: expense.currency,
                date: expense.date,
                iconName: isCurrentUserPayer ? "creditcard.fill" : "bag.fill",
                groupId: expense.group._id,
                expenseId: expense._id
            };
        });
    }
}

module.exports = ActivityMapper;