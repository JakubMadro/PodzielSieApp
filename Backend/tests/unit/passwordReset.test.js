// tests/unit/passwordReset.test.js
const { generateResetToken, hashToken, isTokenValid, generateExpirationDate } = require('../../src/utils/tokenGenerator');
const ForgotPasswordDto = require('../../src/api/dto/request/user/ForgotPasswordDto');
const ResetPasswordDto = require('../../src/api/dto/request/user/ResetPasswordDto');

describe('Testy jednostkowe resetowania hasła', () => {
    
    describe('tokenGenerator', () => {
        test('generateResetToken powinno generować 6-cyfrowy kod', () => {
            const code = generateResetToken();
            expect(code).toBeDefined();
            expect(typeof code).toBe('string');
            expect(code.length).toBe(6);
            expect(/^\d{6}$/.test(code)).toBeTruthy();
        });

        test('hashToken powinno generować hash tokenu', () => {
            const token = 'test-token';
            const hash = hashToken(token);
            expect(hash).toBeDefined();
            expect(typeof hash).toBe('string');
            expect(hash.length).toBe(64); // SHA256 = 64 hex chars
            expect(hash).not.toBe(token);
        });

        test('hashToken powinno być deterministyczne', () => {
            const token = 'test-token';
            const hash1 = hashToken(token);
            const hash2 = hashToken(token);
            expect(hash1).toBe(hash2);
        });

        test('isTokenValid powinno sprawdzać czy token nie wygasł', () => {
            const futureDate = new Date(Date.now() + 3600000); // 1 hour from now
            const pastDate = new Date(Date.now() - 3600000); // 1 hour ago

            expect(isTokenValid(futureDate)).toBeTruthy();
            expect(isTokenValid(pastDate)).toBeFalsy();
        });

        test('generateExpirationDate powinno generować datę wygaśnięcia', () => {
            const expiration = generateExpirationDate(30); // 30 minutes
            const now = new Date();
            const expected = new Date(now.getTime() + 30 * 60 * 1000);

            // Allow for small time differences (few seconds)
            const diff = Math.abs(expiration.getTime() - expected.getTime());
            expect(diff).toBeLessThan(5000); // Less than 5 seconds difference
        });
    });

    describe('ForgotPasswordDto', () => {
        test('powinno walidować poprawny email', () => {
            const dto = new ForgotPasswordDto({ email: 'test@example.com' });
            const validation = dto.validate();
            
            expect(validation.isValid).toBeTruthy();
            expect(validation.errors).toHaveLength(0);
        });

        test('powinno odrzucać brak email', () => {
            const dto = new ForgotPasswordDto({});
            const validation = dto.validate();
            
            expect(validation.isValid).toBeFalsy();
            expect(validation.errors).toContain('Email jest wymagany');
        });

        test('powinno odrzucać nieprawidłowy format email', () => {
            const dto = new ForgotPasswordDto({ email: 'invalid-email' });
            const validation = dto.validate();
            
            expect(validation.isValid).toBeFalsy();
            expect(validation.errors).toContain('Podaj prawidłowy adres email');
        });

        test('powinno walidować różne formaty email', () => {
            const validEmails = [
                'test@example.com',
                'user.name@domain.co.uk',
                'user+tag@domain.com',
                'user123@sub.domain.org'
            ];

            validEmails.forEach(email => {
                const dto = new ForgotPasswordDto({ email });
                const validation = dto.validate();
                expect(validation.isValid).toBeTruthy();
            });

            const invalidEmails = [
                'plainaddress',
                '@missingdomain.com',
                'missing@.com',
                'missing@domain',
                'spaces @domain.com'
            ];

            invalidEmails.forEach(email => {
                const dto = new ForgotPasswordDto({ email });
                const validation = dto.validate();
                expect(validation.isValid).toBeFalsy();
            });
        });
    });

    describe('ResetPasswordDto', () => {
        const validData = {
            token: '123456', // 6-digit code
            newPassword: 'Password123',
            confirmPassword: 'Password123'
        };

        test('powinno walidować poprawne dane', () => {
            const dto = new ResetPasswordDto(validData);
            const validation = dto.validate();
            
            expect(validation.isValid).toBeTruthy();
            expect(validation.errors).toHaveLength(0);
        });

        test('powinno odrzucać brak kodu', () => {
            const dto = new ResetPasswordDto({ ...validData, token: undefined });
            const validation = dto.validate();
            
            expect(validation.isValid).toBeFalsy();
            expect(validation.errors).toContain('Kod weryfikacyjny jest wymagany');
        });

        test('powinno odrzucać nieprawidłowy kod', () => {
            const invalidCodes = ['12345', '1234567', 'abcdef', '12a456'];
            
            invalidCodes.forEach(code => {
                const dto = new ResetPasswordDto({ ...validData, token: code });
                const validation = dto.validate();
                
                expect(validation.isValid).toBeFalsy();
                expect(validation.errors).toContain('Kod weryfikacyjny musi być 6-cyfrowy');
            });
        });

        test('powinno odrzucać brak hasła', () => {
            const dto = new ResetPasswordDto({ ...validData, newPassword: undefined });
            const validation = dto.validate();
            
            expect(validation.isValid).toBeFalsy();
            expect(validation.errors).toContain('Nowe hasło jest wymagane');
        });

        test('powinno walidować siłę hasła', () => {
            const weakPasswords = [
                'short',
                'nouppercase123',
                'NOLOWERCASE123',
                'NoNumbers',
                'NoSpecial'
            ];

            weakPasswords.forEach(password => {
                const dto = new ResetPasswordDto({ ...validData, newPassword: password, confirmPassword: password });
                const validation = dto.validate();
                expect(validation.isValid).toBeFalsy();
                expect(validation.errors).toContain('Hasło musi mieć co najmniej 8 znaków, zawierać wielką literę, małą literę i cyfrę');
            });
        });

        test('powinno odrzucać różne hasła', () => {
            const dto = new ResetPasswordDto({
                ...validData,
                newPassword: 'Password123',
                confirmPassword: 'Different123'
            });
            const validation = dto.validate();
            
            expect(validation.isValid).toBeFalsy();
            expect(validation.errors).toContain('Hasła nie są identyczne');
        });

        test('powinno odrzucać brak potwierdzenia hasła', () => {
            const dto = new ResetPasswordDto({ ...validData, confirmPassword: undefined });
            const validation = dto.validate();
            
            expect(validation.isValid).toBeFalsy();
            expect(validation.errors).toContain('Potwierdzenie hasła jest wymagane');
        });

        test('powinno akceptować silne hasła', () => {
            const strongPasswords = [
                'Password123',
                'MyStr0ngP@ss',
                'C0mpl3xPassword!',
                'Secure123Pass'
            ];

            strongPasswords.forEach(password => {
                const dto = new ResetPasswordDto({ ...validData, newPassword: password, confirmPassword: password });
                const validation = dto.validate();
                expect(validation.isValid).toBeTruthy();
            });
        });
    });
});