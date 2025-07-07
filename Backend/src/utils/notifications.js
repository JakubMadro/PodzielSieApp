const nodemailer = require('nodemailer');
const User = require('../models/User');

// Inicjalizacja nodemailer
let transporter;

// Tworzenie transportera na podstawie konfiguracji ze zmiennych środowiskowych
if (
    process.env.SMTP_HOST &&
    process.env.SMTP_PORT &&
    process.env.SMTP_USER &&
    process.env.SMTP_PASS
) {
    transporter = nodemailer.createTransport({
        host: process.env.SMTP_HOST,
        port: process.env.SMTP_PORT,
        secure: process.env.SMTP_PORT === '465',
        auth: {
            user: process.env.SMTP_USER,
            pass: process.env.SMTP_PASS
        }
    });
} else {
    console.warn('Konfiguracja SMTP niepełna. Powiadomienia email nie będą wysyłane.');
}

/**
 * Wysyła powiadomienie do użytkownika
 * @param {string} userId - ID użytkownika
 * @param {string} title - Tytuł powiadomienia
 * @param {string} message - Treść powiadomienia
 * @param {Object} data - Dodatkowe dane do przechowania z powiadomieniem
 * @returns {Promise<Object>} Utworzone powiadomienie
 */
const sendNotification = async (userId, title, message, data = {}) => {
    try {
        const user = await User.findById(userId);
        if (!user) {
            throw new Error(`Użytkownik o ID ${userId} nie istnieje`);
        }

        // Dodaj powiadomienie do tablicy powiadomień użytkownika
        // W rzeczywistej implementacji powinniśmy mieć osobny model do powiadomień
        if (!user.notifications) {
            user.notifications = [];
        }

        const notification = {
            title,
            message,
            data,
            read: false,
            createdAt: new Date()
        };

        user.notifications.unshift(notification);

        // Ogranicz liczbę przechowywanych powiadomień do np. 100
        if (user.notifications.length > 100) {
            user.notifications = user.notifications.slice(0, 100);
        }

        await user.save();

        // Wysyłanie powiadomienia email (jeśli skonfigurowano)
        if (user.email && transporter) {
            await sendEmailNotification(user.email, title, message, data);
        }

        // W rzeczywistej aplikacji powinniśmy wysyłać powiadomienia push
        // np. przy użyciu Firebase Cloud Messaging

        return notification;
    } catch (error) {
        console.error('Błąd podczas wysyłania powiadomienia:', error);
        throw error;
    }
};

/**
 * Wysyła powiadomienie email do użytkownika
 * @param {string} email - Email użytkownika
 * @param {string} subject - Temat wiadomości
 * @param {string} text - Treść wiadomości
 * @param {Object} data - Dodatkowe dane do umieszczenia w wiadomości HTML
 * @returns {Promise<Object>} Informacja o wysłanej wiadomości
 */
const sendEmailNotification = async (email, subject, text, data = {}) => {
    try {
        if (!transporter) {
            console.warn('Transporter email nie jest skonfigurowany. Email nie zostanie wysłany.');
            return null;
        }

        // Przygotuj treść HTML
        const htmlContent = `
      <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
        <div style="background-color: #f8f9fa; padding: 20px; text-align: center;">
          <h1 style="color: #007bff;">${subject}</h1>
        </div>
        <div style="padding: 20px;">
          <p>${text}</p>
          ${getActionButtonHtml(data)}
        </div>
        <div style="background-color: #f8f9fa; padding: 15px; text-align: center; font-size: 12px; color: #6c757d;">
          <p>To jest automatyczne powiadomienie. Prosimy nie odpowiadać na tę wiadomość.</p>
          <p>© ${new Date().getFullYear()} DzielSie App</p>
        </div>
      </div>
    `;

        // Wyślij email
        const info = await transporter.sendMail({
            from: process.env.SMTP_FROM || '"DzielSie App" <no-reply@dziel-sie.pl>',
            to: email,
            subject,
            text,
            html: htmlContent
        });

        return info;
    } catch (error) {
        console.error('Błąd podczas wysyłania emaila:', error);
        return null;
    }
};

/**
 * Generuje przycisk akcji w zależności od typu powiadomienia
 * @param {Object} data - Dane powiadomienia
 * @returns {string} Kod HTML z przyciskiem
 */
const getActionButtonHtml = (data) => {
    const baseUrl = process.env.FRONTEND_URL || 'https://dziel-sie.pl';

    if (!data || !data.type) return '';

    let buttonUrl = '';
    let buttonText = '';

    switch (data.type) {
        case 'NEW_EXPENSE':
            buttonUrl = `${baseUrl}/expenses/${data.expenseId}`;
            buttonText = 'Zobacz wydatek';
            break;
        case 'GROUP_INVITE':
            buttonUrl = `${baseUrl}/groups/${data.groupId}`;
            buttonText = 'Zobacz grupę';
            break;
        case 'DEBT_SETTLED':
            buttonUrl = `${baseUrl}/settlements/${data.settlementId}`;
            buttonText = 'Zobacz rozliczenie';
            break;
        case 'NEW_COMMENT':
            buttonUrl = `${baseUrl}/expenses/${data.expenseId}`;
            buttonText = 'Zobacz komentarz';
            break;
        case 'PASSWORD_RESET':
            return `
            <div style="margin-top: 20px; text-align: center; background-color: #f8f9fa; padding: 20px; border-radius: 8px;">
              <h2 style="color: #007bff; margin: 0 0 15px 0;">Twój kod weryfikacyjny:</h2>
              <div style="font-size: 32px; font-weight: bold; color: #343a40; letter-spacing: 3px; background-color: white; padding: 15px; border-radius: 5px; border: 2px solid #007bff;">${data.resetCode}</div>
              <p style="margin: 15px 0 0 0; color: #6c757d; font-size: 14px;">Kod jest ważny przez 15 minut</p>
            </div>
            `;
            break;
        case 'PASSWORD_CHANGED':
            buttonUrl = `${baseUrl}/login`;
            buttonText = 'Zaloguj się';
            break;
        default:
            return '';
    }

    return `
    <div style="margin-top: 20px; text-align: center;">
      <a href="${buttonUrl}" style="background-color: #007bff; color: white; padding: 10px 20px; text-decoration: none; border-radius: 4px; display: inline-block;">
        ${buttonText}
      </a>
    </div>
  `;
};

/**
 * Oznacza powiadomienie jako przeczytane
 * @param {string} userId - ID użytkownika
 * @param {string} notificationId - ID powiadomienia
 * @returns {Promise<boolean>} Informacja czy operacja się powiodła
 */
const markNotificationAsRead = async (userId, notificationId) => {
    try {
        const user = await User.findById(userId);
        if (!user || !user.notifications) {
            return false;
        }

        // Znajdź powiadomienie po ID i oznacz jako przeczytane
        const notification = user.notifications.id(notificationId);
        if (!notification) {
            return false;
        }

        notification.read = true;
        await user.save();
        return true;
    } catch (error) {
        console.error('Błąd podczas oznaczania powiadomienia jako przeczytane:', error);
        return false;
    }
};

/**
 * Pobiera wszystkie powiadomienia użytkownika
 * @param {string} userId - ID użytkownika
 * @param {Object} options - Opcje filtrowania i sortowania
 * @returns {Promise<Array>} Tablica powiadomień
 */
const getUserNotifications = async (userId, options = {}) => {
    try {
        const { limit = 50, onlyUnread = false } = options;

        const user = await User.findById(userId);
        if (!user || !user.notifications) {
            return [];
        }

        let notifications = user.notifications;

        // Filtruj tylko nieprzeczytane, jeśli potrzeba
        if (onlyUnread) {
            notifications = notifications.filter(n => !n.read);
        }

        // Ogranicz liczbę zwracanych powiadomień
        notifications = notifications.slice(0, limit);

        return notifications;
    } catch (error) {
        console.error('Błąd podczas pobierania powiadomień użytkownika:', error);
        return [];
    }
};

/**
 * Usuwa wszystkie powiadomienia użytkownika
 * @param {string} userId - ID użytkownika
 * @returns {Promise<boolean>} Informacja czy operacja się powiodła
 */
const clearUserNotifications = async (userId) => {
    try {
        const user = await User.findById(userId);
        if (!user) {
            return false;
        }

        user.notifications = [];
        await user.save();
        return true;
    } catch (error) {
        console.error('Błąd podczas czyszczenia powiadomień użytkownika:', error);
        return false;
    }
};

module.exports = {
    sendNotification,
    sendEmailNotification,
    markNotificationAsRead,
    getUserNotifications,
    clearUserNotifications
};