class AdminUser

  class WeakPasswordAuditReporter

    def self.render(findings:, total:)
      lines = ['=== Audit des mots de passe faibles ===', '']

      if findings.empty?
        lines << 'Aucun compte compromis détecté.'
      else
        findings.each do |finding|
          u = finding.admin_user
          last = u.last_sign_in_at&.iso8601 || 'jamais'
          disabled = u.is_disabled ? ' [désactivé]' : ''
          lines << "- #{u.email} (#{u.name}) — rôle=#{u.user_role} — dernière connexion=#{last}#{disabled} — #{finding.category}"
        end
      end

      lines << ''
      lines << "#{findings.size}/#{total} comptes compromis"
      lines.join("\n")
    end
  end
end
