if Rails.env.production?
  ENV['SMTP_ADDRESS'] || raise('Error: No SMTP_ADDRESS provided')
  ENV['SMTP_PORT'] || raise('Error: No SMTP_PORT provided')
  ENV['SMTP_USERNAME'] || raise('Error: No SMTP_USERNAME provided')
  ENV['SMTP_PASSWORD'] || raise('Error: No SMTP_PASSWORD provided')
  ENV['MAIL_SENDER'] || raise('Error: No MAIL_SENDER provided')
  ENV['DEFAULT_HOSTNAME'] || raise('Error: No DEFAULT_HOSTNAME provided')
end
