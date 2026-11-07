<?php

namespace Campusfix\Backend\Services;

use PHPMailer\PHPMailer\PHPMailer;
use RuntimeException;
use Throwable;

class EmailService
{
    public function sendPasswordResetEmail(
        string $recipientEmail,
        string $recipientName,
        string $resetLink
    ): void {
        $mail = new PHPMailer(true);

        try {
            $mail->isSMTP();

            $mail->Host = $_ENV['MAIL_HOST'] ?? 'smtp.gmail.com';
            $mail->SMTPAuth = true;
            $mail->Username = $_ENV['MAIL_USERNAME'] ?? '';
            $mail->Password = $_ENV['MAIL_PASSWORD'] ?? '';
            $mail->Port = (int) ($_ENV['MAIL_PORT'] ?? 587);

            $encryption = strtolower(
                $_ENV['MAIL_ENCRYPTION'] ?? 'tls'
            );

            if ($encryption === 'tls') {
                $mail->SMTPSecure = PHPMailer::ENCRYPTION_STARTTLS;
            } elseif ($encryption === 'ssl') {
                $mail->SMTPSecure = PHPMailer::ENCRYPTION_SMTPS;
            } else {
                throw new RuntimeException('Invalid SMTP encryption configuration.');
            }

            $fromAddress = $_ENV['MAIL_FROM_ADDRESS'] ?? '';
            $fromName = $_ENV['MAIL_FROM_NAME'] ?? 'CampusFix';

            if (
                $mail->Username === '' ||
                $mail->Password === '' ||
                !filter_var($fromAddress, FILTER_VALIDATE_EMAIL)
            ) {
                throw new RuntimeException('SMTP configuration is incomplete.');
            }

            $mail->CharSet = 'UTF-8';

            $mail->setFrom($fromAddress, $fromName);
            $mail->addAddress($recipientEmail, $recipientName);

            $mail->isHTML(true);
            $mail->Subject = 'CampusFix - Password Reset';

            $safeName = htmlspecialchars(
                $recipientName,
                ENT_QUOTES | ENT_SUBSTITUTE,
                'UTF-8'
            );

            $safeLink = htmlspecialchars(
                $resetLink,
                ENT_QUOTES | ENT_SUBSTITUTE,
                'UTF-8'
            );

            $mail->Body = "
                <div style='font-family:Arial,sans-serif;max-width:600px;margin:auto;padding:24px;'>
                    <h2>CampusFix Password Reset</h2>
                    <p>Hello {$safeName},</p>
                    <p>We received a request to reset your CampusFix account password.</p>
                    <p>
                        <a href='{$safeLink}'
                           style='display:inline-block;padding:12px 20px;background:#16865c;color:white;text-decoration:none;border-radius:6px;'>
                            Reset Password
                        </a>
                    </p>
                    <p>This link expires in 30 minutes and can only be used once.</p>
                    <p>If you did not request this, please ignore this email.</p>
                    <p>Regards,<br>CampusFix Team</p>
                </div>
            ";

            $mail->AltBody =
                "Hello {$recipientName},\n\n"
                . "Reset your CampusFix password using this link:\n"
                . "{$resetLink}\n\n"
                . "This link expires in 30 minutes and can only be used once.";

            $mail->send();

        } catch (Throwable $e) {
            error_log('Password reset email failed: ' . $e->getMessage());

            throw new RuntimeException(
                'Unable to send password reset email.',
                0,
                $e
            );
        }
    }
}
